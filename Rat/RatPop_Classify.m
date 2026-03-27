%% ==========================================
ccc;
cd(fileparts(mfilename('fullpath')));

%% -------- load data --------
DataSetName = "RawPop";
protStr = "LocalGlobal_4_5_Temp";

MatName = 'chSpkRes_V1.mat';
run('RatPop_loadData.m');

SavePATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal", protStr);
mkdir(SavePATH);

%% params
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(arrayfun(@(str) ~isempty(regexp(str, 'N\d{3}', 'once')), trialTypes));
GroupIdx = {1:8, 9:16};

%% -------- select cell --------
sigtestRes = arrayfun(@(x) arrayfun(@(y) ttest(y.devCount, y.baseCount, "Alpha",  0.01), x.spkRes), chResAll, 'UniformOutput', false);
sigIdx = find(cellfun(@(x) any(x(ControlIdx) == 1), sigtestRes));
chResAll_sig = chResAll(sigIdx);
psthMatrixAll = arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                        neuron.spkRes(DevIdx).PSTH', num2cell(1:numel(chResAll_sig(1).spkRes)), ...
                                    'UniformOutput', false)', ...
                        chResAll_sig, ...
                'UniformOutput', false);
psthMatrixAll = cellfun(@cell2mat, changeCellRowNum(psthMatrixAll), 'UniformOutput', false);
trialSpkAll = changeCellRowNum(arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                                        neuron.spkRes(DevIdx).trialSpk, num2cell(1:numel(chResAll_sig(1).spkRes)), ...
                                                    'UniformOutput', false)', ...
                                        chResAll_sig, ...
                                'UniformOutput', false));

%% PCA
ClassificationWin = [-100, 300];
ClassificationtIdx = tPSTH > ClassificationWin(1) & tPSTH < ClassificationWin(2);
psthMatrixTemp = cellfun(@(x) x(:, ClassificationtIdx), psthMatrixAll(ControlIdx), 'UniformOutput', false);
featuresMatrix = cell2mat(psthMatrixTemp');
featuresMatrix_zscore = zscore(featuresMatrix, 0, 2); % 每个神经元内部标准化
[coeff, score, latent, ~, explained] = pca(featuresMatrix_zscore);

% 选解释方差 >80%
cumvar = cumsum(explained);
dim = find(cumvar > 80, 1);
reduced = score(:,1:dim);

%% k-means
k = 3; % 可以尝试3~6
initReplication = 50;
[idx0, C] = kmeans(reduced, k, 'Replicates', initReplication);

figure;
for c = 1:k
    subplot(k,1,c); hold on;
    neurons = find(idx0 == c);

    mean1 = mean(featuresMatrix(neurons,1:size(featuresMatrix, 2)/2),1);
    mean2 = mean(featuresMatrix(neurons,size(featuresMatrix, 2)/2+1:end),1);
    
    plot(tPSTH(ClassificationtIdx), mean1, 'k', 'LineWidth',2);
    plot(tPSTH(ClassificationtIdx), mean2, 'k--', 'LineWidth',2);
    
    title(['Cluster ' num2str(c)]);
end

%% k-means 检验可靠性
bootNum = 1000;
subFrac = 0.8;
[Pco, clusterStability, neuronReliability, results] = ...
    bootstrapClusterStability_Subsample(reduced, idx0, k, initReplication, bootNum, subFrac);
%
FigRes_kmeans = figure('Color','w');
histogram(neuronReliability, 20);
xlabel('Neuron reliability');
ylabel('Count');
title('Neuron reliability distribution');
xlim([0 1]);
hold on;
% methond1: mean - std
reliabilityThreshold = mean(neuronReliability, 'omitnan') - std(neuronReliability, 'omitnan');
keepIdx = neuronReliability >= reliabilityThreshold;
removeIdx = neuronReliability < reliabilityThreshold;
% methond2: define
% reliabilityThreshold = 0.6;
xline(reliabilityThreshold, 'r--', 'LineWidth', 2);

%% 
idx0tmp = idx0;
idx0tmp(removeIdx) = 0; 
[a, b] = sort(idx0tmp);
ClassifyPSTHMatrix = cellfun(@(psth) cellfun(@(classIdx) psth(b(a == classIdx), :), ...
                                        num2cell(unique(idx0)), 'UniformOutput', false), ...
                        psthMatrixTemp, 'UniformOutput', false);
ClassifyIdx = cellfun(@(classIdx) b(a == classIdx), num2cell(unique(idx0)), 'UniformOutput', false);

RowNum = 2;
ColNum = 2;
ylineValues = cellfun(@(x) numel(x), ClassifyIdx);
legendStr = cellfun(@(x) strcat("Class", string(x)), num2cell(unique(idx0)));

set(0, ...
    'DefaultFigureUnits', 'pixels', ...
    'DefaultFigurePosition', get(0,'ScreenSize'));
FigRes_Classify = figure('Color','w');
for tIdx = 1 : size(ClassifyPSTHMatrix, 1)
        mSubplot(RowNum, ColNum, tIdx, [1, 1], "margins", [0.03, 0.03, 0.06, 0.05]);
        % -------- PSTH processing --------
        % smoothing
        % sortedPSTH = smoothdata(sortedPSTH,2,'gaussian',5);
        PSTHDataTemp = ClassifyPSTHMatrix{tIdx};
        normFactor = max(cell2mat(PSTHDataTemp),[],2);
        normFactor(normFactor==0) = 1;
        normPSTH{tIdx} = cell2mat(PSTHDataTemp) ./ normFactor;
        % -------- PSTH heatmap --------
        imagesc(tPSTH(ClassificationtIdx),1:size(cell2mat(PSTHDataTemp), 1),normPSTH{tIdx});
        axis tight;
        colormap(jet);
        colorbar
        hold on
        h = arrayfun(@(y, num) yline(y, '-', ['n = ', num2str(numel(cell2mat(num)))]), cumsum(ylineValues), ClassifyIdx);
        set(h, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 4);
        xline(0,'--w','LineWidth',2);
        xlabel('Time (ms)');
        ylabel('Neuron (sorted by category)');
        title([char(strrep(string(regexpi(strrep(trialTypes(ControlIdx(tIdx)), '.', 'o'), '(\w+ms)', 'tokens')), '_', '-')) ...
            ' (n = ' num2str(size(cell2mat(PSTHDataTemp), 1)) ')']);        
        set(gca,'fontsize',8,'linewidth',1.2);
        % -------- PSTH wave --------
        mSubplot(RowNum, ColNum, tIdx+2, [1, 1], "margins", [0.03, 0.03, 0.05, 0.12]);
        MeanPSTH = cell2mat(cellfun(@(x) mean(x, 1), PSTHDataTemp, 'UniformOutput', false));
        plot(tPSTH(ClassificationtIdx)', MeanPSTH, 'LineWidth', 2);hold on;
        title(strrep(string(regexpi(strrep(trialTypes(ControlIdx(tIdx)), '.', 'o'), '(\w+ms)', 'tokens')), '_', '-'));
        legend(legendStr, "Location", "best");
end
 
%% print
exportgraphics(FigRes_Classify, fullfile(SavePATH, strcat(MonkeyName, "_ClassifyRes.jpg")));
exportgraphics(FigRes_kmeans, fullfile(SavePATH, strcat(MonkeyName, "_Classify_kmeansRes.jpg")));