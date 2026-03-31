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

%%
% 假设X是Spike计数矩阵（R x S x B），Y是每个试次的刺激标签（刺激类型）
templates = zeros(S, B);  % 每个刺激的模板
for s = 1:S
    for b = 1:B
        templates(s, b) = mean(X(:, s, b));  % 计算每个刺激类型的模板
    end
end

% 计算每个试次与模板之间的欧几里得距离
distances = zeros(R, S);  % 存储欧几里得距离
for r = 1:R
    for s = 1:S
        distances(r, s) = sqrt(sum((X(r, s, :) - templates(s, :)).^2));  % 欧几里得距离
    end
end

% 基于最小距离进行分类
[~, predicted_labels] = min(distances, [], 2);  % 找到最小的距离并分类

% 计算准确率
accuracy = sum(predicted_labels == Y) / length(Y);
disp(['准确率: ', num2str(accuracy)]);