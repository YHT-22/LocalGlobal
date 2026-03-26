%% ==========================================
% MATLAB示例：神经元群体无监督聚类（HDBSCAN）
% 输入:
%   data: n_neurons x n_features
%   regions: n_neurons x 1 cell array，标记脑区 ('AC','MGB','IC','CN')
% 输出:
%   cluster_labels: 聚类标签
%   cluster_probs: 聚类置信度
%% ==========================================
ccc;
cd(fileparts(mfilename('fullpath')));

%% -------- load data --------
DataSetName = "ProcessPop1";
protStr = "LocalGlobal_4_5_Temp";

MatName = 'res.mat';
run('RatPop_loadData.m');

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

% --- 示例数据（替换为你的神经元数据） ---
n_neurons = 500;
n_features = 100;
data = randn(n_neurons, n_features);  
regions = repmat({'AC','MGB','IC','CN'},1, ceil(n_neurons/4));
regions = regions(1:n_neurons)';

%% 1. 数据标准化
data_norm = zscore(data, 0, 2);  % 每个神经元标准化

%% 2. PCA降维（自动选择累积方差 >= 90%）
[coeff, score, ~, ~, explained] = pca(data_norm);
cumVar = cumsum(explained);
numPC = find(cumVar >= 90, 1); 
data_pca = score(:, 1:numPC);
fprintf('PCA降维：保留 %d 个主成分，累积方差 %.2f%%\n', numPC, cumVar(numPC));

%% 3. HDBSCAN 聚类
addpath('HDBSCAN');  % 添加 HDBSCAN 路径

% 设置 minPts 为神经元总数 1%，最小 5
minPts = max(5, round(n_neurons*0.01));

% 调用 HDBSCAN
% cluster_labels: 聚类标签 (-1 表示噪声)
% lambda: 每个点的稳定性，用作置信度
[cluster_labels, lambda] = hdbscan(data_pca, minPts);

fprintf('聚类完成，共 %d 个簇 (噪声点 label=-1)\n', numel(unique(cluster_labels(cluster_labels>0))));

%% 4. 可视化聚类结果（PCA前两维）
figure; hold on;
unique_clusters = unique(cluster_labels);
colors = lines(numel(unique_clusters));
for i = 1:numel(unique_clusters)
    idx = cluster_labels == unique_clusters(i);
    scatter(data_pca(idx,1), data_pca(idx,2), 36, colors(i,:), 'filled');
end
xlabel('PCA 1'); ylabel('PCA 2');
title('HDBSCAN聚类结果（前2 PCA维）');
grid on;

%% 5. 各脑区簇分布统计
brain_areas = unique(regions);
fprintf('\n各脑区簇分布:\n');
for b = 1:numel(brain_areas)
    area = brain_areas{b};
    idx_area = strcmp(regions, area);
    area_labels = cluster_labels(idx_area);
    tab = tabulate(area_labels);
    fprintf('%s:\n', area);
    disp(tab);
end

%% 6. 可选：保存结果
% save('neuron_clusters.mat','cluster_labels','lambda','data_pca','regions');