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
ControlIdx = find(arrayfun(@(str)contains(str, 'Inf'), trialTypes));
GroupIdx = {1:8, 9:16};
Regions = ["AC" , "MGB", "IC", "CN"];

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
[coeff, score, latent, ~, explained] = pca(featuresMatrix_zscore, 'Algorithm', 'svd');
% 选解释方差 >80%
cumvar = cumsum(explained);
dim = find(cumvar > 80, 1);
reduced = score(:,1:dim);

%% 层级聚类
clusterNum = 6;
% 计算样本间的距离（可以使用欧几里得距离）
distances = pdist(reduced);

% 使用 'linkage' 进行层级聚类（'average' 是合并方式，可以换成 'single', 'complete' 等）
Z = linkage(distances, 'ward');

% 绘制树状图
set(0, ...
    'DefaultFigureUnits', 'pixels', ...
    'DefaultFigurePosition', get(0,'ScreenSize'));
Fig_dendrogram = figure;
subplot(1,2,1);hold on;
dendrogram(Z);
xlabel('Sample Index');
ylabel('Distance');
title('Hierarchical Clustering Dendrogram');

% 选择簇
idx0 = cluster(Z, 'maxclust', clusterNum); 
s = silhouette(reduced, idx0);
mean_s = mean(s);

k=unique(idx0);
for c = 1:clusterNum
    subplot(numel(k),2,2*c); hold on;
    neurons = find(idx0 == k(c));

    mean1 = mean(featuresMatrix(neurons,1:size(featuresMatrix, 2)/2),1);
    mean2 = mean(featuresMatrix(neurons,size(featuresMatrix, 2)/2+1:end),1);
    
    plot(tPSTH(ClassificationtIdx), mean1, 'k', 'LineWidth',2);
    plot(tPSTH(ClassificationtIdx), mean2, 'k--', 'LineWidth',2);
    
    title(['Cluster ' num2str(k(c))]);
end
% print
exportgraphics(Fig_dendrogram, fullfile(SavePATH, strcat("Rat_Classify_dendrogramRes_c", num2str(clusterNum), ".jpg")));

%% 检验可靠性
% bootNum = 1000;
% subFrac = 0.8;
% clusterParams.classifyMethond = "linkage";
% clusterParams.k = clusterNum;
% [Pco, clusterStability, neuronReliability, results] = ...
%     bootstrapClusterStability_Subsample(reduced, idx0, bootNum, subFrac, clusterParams);
% % neuronReliability distribution
% FigRes_kmeans = figure('Color','w');
% histogram(neuronReliability, 20);
% xlabel('Neuron reliability');
% ylabel('Count');
% title('Neuron reliability distribution');
% xlim([0 1]);
% hold on;
% % methond1: mean - std
% reliabilityThreshold = mean(neuronReliability, 'omitnan') - std(neuronReliability, 'omitnan');
% keepIdx = neuronReliability >= reliabilityThreshold;
% removeIdx = neuronReliability < reliabilityThreshold;
% % methond2: define
% % reliabilityThreshold = 0.6;
% xline(reliabilityThreshold, 'r--', 'LineWidth', 2);
% 
%% select cell after reliability test
idx0tmp = idx0;
% idx0tmp(removeIdx) = 0; 
cellclusterInfo = [arrayfun(@(x) string(x.CH), chResAll_sig), idx0tmp];
run("RatPop_Classify_RegionInfo.m");

%%
RowNum = 4;
ColNum = numel(unique(idx0)) + 2;
AC_ylineValues = cellfun(@(x) numel(x), AC_ClassifyIdx);
MGB_ylineValues = cellfun(@(x) numel(x), MGB_ClassifyIdx);
IC_ylineValues = cellfun(@(x) numel(x), IC_ClassifyIdx);
CN_ylineValues = cellfun(@(x) numel(x), CN_ClassifyIdx);
legendStr = cellfun(@(x) strcat("Class", string(x)), num2cell(unique(idx0)));

set(0, ...
    'DefaultFigureUnits', 'pixels', ...
    'DefaultFigurePosition', get(0,'ScreenSize'));
FigRes_Classify = figure('Color','w');
for regionIdx = 1 : numel(Regions)
    RegionStr = Regions(regionIdx);
    switch RegionStr
        case "AC"
            ClassifyPSTHMatrix = AC_ClassifyPSTHMatrix;
            ylineValues = AC_ylineValues;
            ClassifyIdx = AC_ClassifyIdx;
        case "MGB"
            ClassifyPSTHMatrix = MGB_ClassifyPSTHMatrix;
            ylineValues = MGB_ylineValues;
            ClassifyIdx = MGB_ClassifyIdx;
        case "IC"
            ClassifyPSTHMatrix = IC_ClassifyPSTHMatrix;
            ylineValues = IC_ylineValues;
            ClassifyIdx = IC_ClassifyIdx;
        case "CN"
            ClassifyPSTHMatrix = CN_ClassifyPSTHMatrix;
            ylineValues = CN_ylineValues;
            ClassifyIdx = CN_ClassifyIdx;
    end
    for cIdx = 1:size(ClassifyPSTHMatrix{1}, 1)
        % -------- PSTH processing --------
        % smoothing
        % sortedPSTH = smoothdata(sortedPSTH,2,'gaussian',5);
        PSTHDataTemp = cellfun(@(x) mean(x{cIdx}, 1), ClassifyPSTHMatrix, 'UniformOutput', false);  
        % -------- PSTH wave --------
        mSubplot(RowNum, ColNum, (regionIdx-1)*ColNum + cIdx, [1, 1], "margins", [0.08, 0.08, 0.1, 0.05]); hold on;
        plot(tPSTH(ClassificationtIdx), PSTHDataTemp{1}, 'r', 'LineWidth',2);hold on;
        plot(tPSTH(ClassificationtIdx), PSTHDataTemp{2}, 'b', 'LineWidth',2);
        title(['Cluster ' num2str(k(cIdx)), ' (n=', num2str(numel(ClassifyIdx{cIdx})), ')']);

    end
    PSTHDataTemp = [];normPSTH = [];
    for tIdx = 1 : size(ClassifyPSTHMatrix, 1)
        % -------- PSTH processing --------     
        PSTHDataTemp = ClassifyPSTHMatrix{tIdx};
        normFactor = cellfun(@(x) max(x, [], 2), PSTHDataTemp, 'UniformOutput', false);
        for c = 1 : size(normFactor, 1)
            tmp = normFactor{c};
            tmp(tmp == 0) = 1;
            normFactor{c} = tmp;
        end
        normPSTH{tIdx} = cellfun(@(poppsth, normfac) poppsth ./ normfac, PSTHDataTemp, normFactor, 'uni',false);  
        % -------- PSTH heatmap --------
        mSubplot(RowNum, ColNum, (regionIdx - 1) * ColNum + numel(unique(idx0)) + tIdx, [1, 1], "margins", [0.06, 0.06, 0.06, 0.05]);
        imagesc(tPSTH(ClassificationtIdx),1:size(cell2mat(PSTHDataTemp), 1),cell2mat(normPSTH{tIdx}));
        axis tight;
        colormap(jet);colorbar;hold on;
        h = arrayfun(@(y) yline(y, '-'), cumsum(ylineValues));
        set(h, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2);
        xline(0,'--w','LineWidth',2);
        xlabel('Time (ms)');
        ylabel('Neuron (sorted by category)');
        title([char(trialTypes(ControlIdx(tIdx))),' (n = ', num2str(size(cell2mat(PSTHDataTemp), 1)) ')']);        
        set(gca,'fontsize',8,'linewidth',1.2);
    end
end
annotation(FigRes_Classify, "textbox", [.01, .8, .1, .1], "String", "AC", "BackgroundColor", "none", "EdgeColor", "none", "FitBoxToText", "on", "FontSize", 14);
annotation(FigRes_Classify, "textbox", [.01, .55, .1, .1], "String", "MGB", "BackgroundColor", "none", "EdgeColor", "none", "FitBoxToText", "on", "FontSize", 14);
annotation(FigRes_Classify, "textbox", [.01, .33, .1, .1], "String", "IC", "BackgroundColor", "none", "EdgeColor", "none", "FitBoxToText", "on", "FontSize", 14);
annotation(FigRes_Classify, "textbox", [.01, .12, .1, .1], "String", "CN", "BackgroundColor", "none", "EdgeColor", "none", "FitBoxToText", "on", "FontSize", 14);

%% print
exportgraphics(FigRes_Classify, fullfile(SavePATH, "Rat_ClassifyRes.jpg"));
