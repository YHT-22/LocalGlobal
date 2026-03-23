ccc;

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

% 1. 导入数据
data = load('your_data.mat'); % 假设数据已经保存为MAT文件
matrix = data.matrix; % 100×671×14矩阵，维度：时间×样本×条件

% 2. 预处理：Z-score 每神经元
% 对每个神经元做跨时间与条件的Z-score标准化
matrix_zscore = zscore(matrix, 0, [1 2]);

% 可选：高斯平滑
sigma = 15; % 高斯核的标准差，可调
smoothed_matrix = gaussian_smooth(matrix_zscore, sigma);

% 3. 降维：PCA
% 数据降维：先全局PCA
reshaped_matrix = reshape(smoothed_matrix, [], size(smoothed_matrix, 3)); % 将数据reshape成2D矩阵
[coeff, score, latent] = pca(reshaped_matrix); % 进行PCA
explained_variance = cumsum(latent) / sum(latent); % 累积解释方差
num_components = find(explained_variance > 0.8, 1); % 选择解释方差大于80%的成分

% 降维到前8维
reduced_data = score(:, 1:8);

% 4. 分组：按条件1与8，2与9，3与10...进行分组
grouped_data = zeros(size(matrix, 1), size(matrix, 2), 7); % 7对条件需要进行比较
for i = 1:7
    grouped_data(:, :, i) = mean(matrix(:, :, [i, i+7]), 3); % 计算每一对条件的平均值
end

% 5. 可视化：3D轨迹动画
% 假设每个点为一个神经元，数据可投影到前2D或3D空间
figure;
hold on;
for i = 1:7
    % 选择不同线型来表示两组
    if mod(i, 2) == 1
        % 组1：实线
        plot3(grouped_data(:, 1, i), grouped_data(:, 2, i), grouped_data(:, 3, i), ...
            'Color', get_color_for_stimulus(i), 'LineStyle', '-'); % 实线
    else
        % 组2：虚线
        plot3(grouped_data(:, 1, i), grouped_data(:, 2, i), grouped_data(:, 3, i), ...
            'Color', get_color_for_stimulus(i), 'LineStyle', '--'); % 虚线
    end
end

% 绘制速度矢量场
velocity_field = compute_velocity_field(grouped_data); % 计算速度矢量场
quiver3(grouped_data(:, 1, 1), grouped_data(:, 2, 1), grouped_data(:, 3, 1), ...
        velocity_field(:, 1), velocity_field(:, 2), velocity_field(:, 3), 'AutoScale', 'on');

% 6. 输出指标表：计算每个刺激的各项指标
output_table = [];
for i = 1:7
    dimension = size(grouped_data(:, :, i), 2);
    avg_speed = mean(velocity_field(:, i)); % 计算平均速度
    curvature = compute_curvature(grouped_data(:, :, i)); % 计算曲率
    attractor_type = classify_attractor(grouped_data(:, :, i)); % 分类吸引子类型
    pairwise_distances = pdist(grouped_data(:, :, i)); % 计算两两距离矩阵
    
    output_table = [output_table; dimension, avg_speed, curvature, attractor_type, pairwise_distances];
end

% 7. 显示结果
disp(output_table);

% 辅助函数：高斯平滑
function smoothed = gaussian_smooth(data, sigma)
    kernel = fspecial('gaussian', [1, round(sigma*6)], sigma); % 生成高斯核
    smoothed = convn(data, kernel, 'same'); % 卷积操作
end

% 辅助函数：计算速度矢量场
function velocity = compute_velocity_field(data)
    [rows, cols, conditions] = size(data);
    velocity = zeros(rows, cols, conditions);
    for i = 1:conditions
        % 计算相邻时间点的差值作为速度估算
        velocity(:, :, i) = diff(data(:, :, i), 1, 1);
    end
end

% 辅助函数：计算曲率
function curvature = compute_curvature(data)
    % 曲率计算逻辑，根据具体需求定义
    curvature = zeros(size(data, 1), size(data, 2));
    % 示例曲率计算方法，需根据实际数据进行调整
end

% 辅助函数：分类吸引子类型
function attractor = classify_attractor(data)
    % 吸引子类型分类逻辑
    attractor = 'TypeA'; % 示例
end

% 辅助函数：根据条件获得颜色
function color = get_color_for_stimulus(stimulus_type)
    % 根据刺激类型选择颜色
    colors = ['r', 'g', 'b', 'c', 'm', 'y', 'k']; % 示例颜色
    color = colors(mod(stimulus_type - 1, length(colors)) + 1);
end
