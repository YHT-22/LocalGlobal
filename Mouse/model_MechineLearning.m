%% -------------------- 群体响应模型参数拟合脚本 --------------------
clear; clc; close all;

%% -------------------- 数据加载 --------------------
ccc;
DataSetName = "ProcessPop1";
run('load_popData.m');

%% -------- params --------
trialTypes = arrayfun(@(x) string(x.stimStr), [tmp.chRes(1).Data(1).spkRes]);
ControlIdx = find(contains(trialTypes, "Control"));
GroupIdx = {1:7, 8:14};
N_insert = [1, 2, 4, 8, 16, 32, 500];
conditions = {'Fast2Slow','Slow2Fast'};
windowAnalysis = [0, 300];

%% -------- select cell --------
DataTemp = tmp.chRes(1).Data;
psthMatrixAll = arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                        neuron.spkRes(DevIdx).PSTH', num2cell(1:numel(trialTypes)), ...
                                    'UniformOutput', false)', ...
                        DataTemp, ...
                'UniformOutput', false);
psthMatrixAll = cellfun(@cell2mat, changeCellRowNum(psthMatrixAll), 'UniformOutput', false);

%% -------------------- 计算PSTH、峰值和延迟 --------------------
num_conditions = length(conditions);
num_insert = length(N_insert);
num_neurons = size(DataTemp,1);

R_peak_data = zeros(num_insert,num_conditions);
T_latency_data = zeros(num_insert,num_conditions);
tPSTHIdx = find(tPSTH > windowAnalysis(1) & tPSTH < windowAnalysis(2));

for c = 1:num_conditions
    mSubplot(1, 2, c, [1, 1]);
    for i = 1:num_insert
        MeanPSTH = mean(psthMatrixAll{(c - 1)*num_insert + i}, 1); % neuron x time
        smoothPSTH = smoothdata(MeanPSTH,2,'gaussian',5);

        plot(tPSTH(tPSTHIdx)', smoothPSTH(:, tPSTHIdx), 'LineWidth', 2);hold on;

        [peak_val, peak_idx] = max(smoothPSTH(tPSTHIdx),[],2); % neuron x 1
        Temp = tPSTH(tPSTHIdx);
        latency_ms = Temp(peak_idx);    

        R_peak_data(i,c) = peak_val;
        T_latency_data(i,c) = latency_ms;
    end
end

%% -------------------- 定义模型函数 --------------------
% theta = [Rmax, F_pre_A, F_pre_B, gamma, N_opt, delta, eta, T0, kappa]
model_fun = @(theta, N, cond) deal_array(theta,N,cond);

%% -------------------- 定义损失函数 --------------------
loss_fun = @(theta) compute_loss(theta, N_insert, R_peak_data, T_latency_data, conditions);

%% -------------------- 参数优化 --------------------
theta0 = [max(R_peak_data(:)),1.0,0.6,0.05,16,0.1,0.05,50,0.5]; % 初始值
lb = [0,0,0,0,1,0,0,1,0]; % 下界
ub = [10,2,2,1,100,1,1,200,2]; % 上界

options = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIterations',1000);
theta_opt = fmincon(loss_fun, theta0, [], [], [], [], lb, ub, [], options);

disp('最优模型参数：');
disp(theta_opt);

%% -------------------- 绘图：模型 vs 数据 --------------------
figure('Name','Peak Response vs Insert','Color','w'); hold on;
xFit = linspace(min(N_insert),max(N_insert),200);
colors = lines(num_conditions);
for c = 1:num_conditions
    plot(N_insert,R_peak_data(:,c),'o','MarkerSize',8,'LineWidth',2,'Color',colors(c,:));
    [R_fit,~] = deal_array(theta_opt,xFit,conditions{c});
    plot(xFit,R_fit,'--','LineWidth',2,'Color',colors(c,:));
end
xlabel('Number of Insert Pulses'); ylabel('Peak Response (a.u.)');
title('Peak Response vs Insert Number');
legend([strcat(conditions,' data'), strcat(conditions,' fit')]);
set(gca,'XScale','log'); grid on;

figure('Name','Latency vs Insert','Color','w'); hold on;
for c = 1:num_conditions
    plot(N_insert,T_latency_data(:,c),'o-','LineWidth',2,'MarkerSize',8,'Color',colors(c,:));
    [~,T_fit] = deal_array(theta_opt,xFit,conditions{c});
    plot(xFit,T_fit,'--','LineWidth',2,'Color',colors(c,:));
end
xlabel('Number of Insert Pulses'); ylabel('Latency (ms)');
title('Response Latency vs Insert Number');
legend(conditions);
set(gca,'XScale','log'); grid on;

%% -------------------- 计算拟合误差和相关性 --------------------
for c = 1:num_conditions
    [R_model,T_model] = deal_array(theta_opt,N_insert,conditions{c});
    MSE_R = mean((R_model - R_peak_data(:,c)').^2);
    MSE_T = mean((T_model - T_latency_data(:,c)').^2);
    r_R = corr(R_model',R_peak_data(:,c));
    r_T = corr(T_model',T_latency_data(:,c));
    fprintf('Condition %s: Peak MSE=%.4f, r=%.4f; Latency MSE=%.4f, r=%.4f\n',...
        conditions{c}, MSE_R,r_R,MSE_T,r_T);
end

%%
function [R,T] = deal_array(theta,N,cond)
    Rmax = theta(1); F_pre_A = theta(2); F_pre_B = theta(3);
    gamma = theta(4); N_opt = theta(5); delta = theta(6);
    eta = theta(7); T0 = theta(8); kappa = theta(9);
    
    R = zeros(size(N)); T = zeros(size(N));
    for i = 1:length(N)
        n = N(i);
        if cond=='A'
            if n>=N_opt
                R(i) = Rmax * F_pre_A * exp(-gamma*(n-N_opt));
            else
                R(i) = Rmax * F_pre_A * n/N_opt;
            end
            T(i) = T0/(1+kappa);
        else % B
            R(i) = Rmax * F_pre_B * (1 - exp(-delta*n));
            T(i) = T0/(1+kappa*F_pre_B + eta*n);
        end
    end
end

%%
function L = compute_loss(theta,N_insert,R_data,T_data,conditions)
    L = 0;
    for c = 1:length(conditions)
        [R_model,T_model] = deal_array(theta,N_insert,conditions{c});
        L = L + mean((R_model - R_data(:,c)').^2) + mean((T_model - T_data(:,c)').^2);
    end
end