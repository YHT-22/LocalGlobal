%% =========================
%  Population PSTH Classification
%  =========================
ccc;
cd(fileparts(mfilename('fullpath')));

%% -------- load data --------
DataSetName = "RawPop";
% MonkeyName = "CC";
% protStr = "LocalGlobal_3_3o75_TempSpec";

MonkeyName = "CM";
% MonkeyName = "Joker";
protStr = "LocalGlobal_4_4o06_Temp";

MatName = 'chSpkRes_V1.mat';
run('MonkeyPop_loadData.m');
SavePATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal", protStr);
mkdir(SavePATH);

%% Delete the cells with inconsistent trial type
trialTypeNumberAll = rowFcn(@(x) numel(x.spkRes), chResAll);
DeleteCellIdx = find(trialTypeNumberAll ~= max(trialTypeNumberAll));
chResAll(DeleteCellIdx) = [];

%% params
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
if strcmp(protStr, "LocalGlobal_3_3o75_TempSpec")
    GroupIdx = {1:7, 8:14};
    ControlIdx = find(contains(trialTypes, "Control"));
elseif strcmp(protStr, "LocalGlobal_4_4o06_Temp")
    ControlIdx = find(arrayfun(@(str) ~isempty(regexp(str, 'N\d{3}', 'once')), trialTypes));
    GroupIdx = {1:8, 9:16};
end


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
k = 4; % 可以尝试3~6
initReplication = 15;
[idx0, C] = kmeans(reduced, k, 'Replicates', initReplication);

figure;
for c = 1:k
    subplot(k,1,c); hold on;
    neurons = find(idx0 == c);
    
    % for n = neurons'
    %     plot(featuresMatrix(n,1:size(featuresMatrix, 2)/2), 'r', 'LineStyle','-');   % 条件1
    %     plot(featuresMatrix(n,size(featuresMatrix, 2)/2+1:end), 'b', 'LineStyle','--');  % 条件2
    % end

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
figure;
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


