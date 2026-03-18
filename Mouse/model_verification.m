%% -------------------- 神经元数据模型验证脚本 --------------------
clear; clc; close all;

%% -------------------- 数据加载 --------------------
% 假设数据已经加载为 spike_data (neuron x trial x time)
% 以及 time_vector (1 x time)
% 以及 N_insert 和 conditions
% 示例：
% load('spike_data.mat'); % spike_data, time_vector
% N_insert = [1 2 4 8 16 32 500];
% conditions = {'Fast2Slow','Slow2Fast'};
ccc;
run('load_popData.m');
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(contains(trialTypes, "Control"));
GroupIdx = {1:7, 8:14};
N_insert = [1, 2, 4, 8, 16, 32, 500];
conditions = {'Fast2Slow','Slow2Fast'};

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

%% -------------------- 计算PSTH、峰值和延迟 --------------------
num_conditions = length(conditions);
num_insert = length(N_insert);
num_neurons = size(chResAll_sig,1);

R_peak_data = zeros(num_insert,num_conditions);
T_latency_data = zeros(num_insert,num_conditions);

for c = 1:num_conditions
    for i = 1:num_insert

        PSTH = mean(psthMatrixAll{(c - 1)*num_insert + i}, 1); % neuron x time

        [peak_val, peak_idx] = max(PSTH,[],2); % neuron x 1
        latency_ms = tPSTH(peak_idx);     % neuron x 1

        R_peak_data(i,c) = peak_val;
        T_latency_data(i,c) = latency_ms;
    end
end

%% -------------------- 拟合非线性累积模型 --------------------
% 模型：R(N) = Rmax * (N^n / (N^n + N50^n)) * exp(-gamma*(N-Nopt)_+)
R_model_fun = @(b,N) b(1) .* (N(:).^b(2) ./ (N(:).^b(2) + b(3).^b(2))) .* exp(-b(4)*max(0,N(:)-b(5)));

bFit = zeros(5,num_conditions);
for c = 1:num_conditions
    y = R_peak_data(:,c);
    b0 = [max(y), 2, 10, 0.05, 16]; % 初始参数 [Rmax, n, N50, gamma, Nopt]
    opts = statset('nlinfit');
    opts.RobustWgtFun = 'bisquare';
    bFit(:,c) = nlinfit(N_insert(:), y(:), R_model_fun, b0, opts);
end

%% -------------------- 绘图：峰值 vs 插入数量 --------------------
figure('Name','Peak Response vs Insert','Color','w'); hold on;
xFit = linspace(1,max(N_insert),200);
colors = lines(num_conditions);
for c = 1:num_conditions
    plot(N_insert, R_peak_data(:,c),'o','MarkerSize',8,'LineWidth',2,'Color',colors(c,:));
    plot(xFit, R_model_fun(bFit(:,c),xFit),'--','LineWidth',2,'Color',colors(c,:));
end
xlabel('Number of Insert Pulses'); ylabel('Peak Response (a.u.)');
title('Peak Response vs Insert Number');
legend([strcat(conditions,' data'), strcat(conditions,' fit')]);
set(gca,'XScale','log'); grid on;

%% -------------------- 绘图：延迟 vs 插入数量 --------------------
figure('Name','Latency vs Insert','Color','w'); hold on;
for c = 1:num_conditions
    plot(N_insert, T_latency_data(:,c),'o-','LineWidth',2,'MarkerSize',8,'Color',colors(c,:));
end
xlabel('Number of Insert Pulses'); ylabel('Latency (ms)');
title('Response Latency vs Insert Number');
legend(conditions);
set(gca,'XScale','log'); grid on;

%% -------------------- 模型误差与相关性 --------------------
for c = 1:num_conditions
    R_pred = R_model_fun(bFit(:,c),N_insert);
    MSE = mean((R_peak_data(:,c) - R_pred).^2);
    [r,p] = corr(R_peak_data(:,c),R_pred);
    fprintf('Condition %s: MSE=%.4f, r=%.4f, p=%.4f\n',conditions{c},MSE,r,p);
end

%% -------------------- 可选：绘制PSTH示意 --------------------
figure('Name','Simulated PSTH Example','Color','w');
for c = 1:num_conditions
    subplot(1,2,c); hold on;
    for i = 1:num_insert
        % 使用拟合峰值和延迟生成高斯PSTH示意
        latency = T_latency_data(i,c);
        sigma = 15;
        PSTH_sim = R_model_fun(bFit(:,c),N_insert(i)) * exp(-(T - 50 - latency).^2/(2*sigma^2));
        plot(T,PSTH_sim,'LineWidth',1.5);
    end
    xlabel('Time (ms)'); ylabel('Firing Rate (a.u.)');
    title(['Condition: ' conditions{c}]);
    legend(arrayfun(@(x) sprintf('Insert%d',x),N_insert,'UniformOutput',false));
end
