ccc;
cd(fileparts(mfilename('fullpath')));

%% -------- load data --------
DataSetName = "RawPop";
MonkeyName = "CC";
protStr = "LocalGlobal_3_3o75_TempSpec";

% MonkeyName = "CM";
% MonkeyName = "Joker";
% protStr = "LocalGlobal_4_4o06_Temp";

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
cumVar = cumsum(explained);
numPC = find(cumVar >= 80, 1); 
data_pca = score(:, 1:numPC);
fprintf('PCA降维：保留 %d 个主成分，累积方差 %.2f%%\n', numPC, cumVar(numPC));

%% 层级聚类
clusterNum = 6;
% 计算样本间的距离（可以使用欧几里得距离）
distances = pdist(reduced);

% 使用 'linkage' 进行层级聚类（'average' 是合并方式，可以换成 'single', 'complete' 等）
Z = linkage(distances, 'ward');

% 绘制树状图
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
for c = 1:numel(k)
    subplot(numel(k),2,2*c); hold on;
    neurons = find(idx0 == k(c));

    mean1 = mean(featuresMatrix(neurons,1:size(featuresMatrix, 2)/2),1);
    mean2 = mean(featuresMatrix(neurons,size(featuresMatrix, 2)/2+1:end),1);
    
    plot(tPSTH(ClassificationtIdx), mean1, 'k', 'LineWidth',2);
    plot(tPSTH(ClassificationtIdx), mean2, 'k--', 'LineWidth',2);
    
    title(['Cluster ' num2str(k(c))]);
end

exportgraphics(Fig_dendrogram, fullfile(SavePATH, strcat(MonkeyName, "_Classify_dendrogramRes_c", num2str(clusterNum), ".jpg")));

%%