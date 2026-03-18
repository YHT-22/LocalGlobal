%% -------------------- 完整群体神经元模拟脚本 --------------------
clear; clc; close all;

%% -------------------- 参数设置 --------------------
N_insert = [1 2 4 8 16 32 500];  % 插入数量
conditions = {'Fast2Slow','Slow2Fast'}; % 条件 A: 3ms->3.75ms, 条件 B: 3.75ms->3ms
T = 0:1:300;     % 时间(ms)
Rmax = 2.5;      % 对照组峰值
T0 = 50;         % 基础延迟(ms)
kappa = 0.5;     % 条件A延迟缩短因子
F_pre_B = 0.6;   % 条件B预激活因子
eta = 0.05;      % 条件B插入数量影响延迟

%% -------------------- 计算峰值幅度和延迟 --------------------
R_peak = zeros(length(N_insert),2); % 峰值
T_latency = zeros(length(N_insert),2); % 延迟

for i = 1:length(N_insert)
    N = N_insert(i);
    
    % -------- 条件A（快->慢） --------
    if N == 500
        R_peak(i,1) = Rmax; % 对照组最大值
    else
        % 1、2、4 无显著反应，8、16、32局部非单调：16>32>8
        if N == 8
            baseA = 1.0;
        elseif N == 16
            baseA = 1.3;
        elseif N == 32
            baseA = 1.2;
        else
            baseA = 0; 
        end
        R_peak(i,1) = baseA * Rmax * 0.5; % 缩放，保证小于对照
    end
    T_latency(i,1) = T0 / (1 + kappa); % 延迟几乎恒定
    
    % -------- 条件B（慢->快） --------
    if N == 500
        R_peak(i,2) = Rmax * F_pre_B; % 对照组
    else
        % 1、2、4 无显著反应，8<16<32
        if N == 8
            baseB = 0.6;
        elseif N == 16
            baseB = 0.8;
        elseif N == 32
            baseB = 0.9;
        else
            baseB = 0; 
        end
        R_peak(i,2) = baseB * Rmax * F_pre_B; 
    end
    T_latency(i,2) = T0 / (1 + kappa*F_pre_B + eta*N); % 插入少延迟大，多延迟小
end

%% -------------------- 模拟 PSTH --------------------
figure('Name','Simulated PSTH','Color','w');
for c = 1:2
    subplot(1,2,c); hold on;
    for i = 1:length(N_insert)
        latency = T_latency(i,c);
        sigma = 15; % 峰宽
        PSTH = R_peak(i,c) * exp(-(T - 50 - latency).^2 / (2*sigma^2));
        plot(T, PSTH,'LineWidth',1.5);
    end
    xlabel('Time (ms)'); ylabel('Firing Rate (a.u.)');
    title(['Condition: ' conditions{c}]);
    legend(arrayfun(@(x) sprintf('Insert%d',x), N_insert,'UniformOutput',false));
end

%% -------------------- 峰值-插入数量曲线 --------------------
figure('Name','Peak vs Insert','Color','w'); hold on;
for c = 1:2
    plot(N_insert, R_peak(:,c),'o-','LineWidth',2,'MarkerSize',8);
end
xlabel('Number of Insert Pulses'); ylabel('Peak Response (a.u.)');
title('Peak Response vs Insert Number');
legend(conditions);
set(gca,'XScale','log'); grid on;

%% -------------------- 延迟-插入数量曲线 --------------------
figure('Name','Latency vs Insert','Color','w'); hold on;
for c = 1:2
    plot(N_insert, T_latency(:,c),'o-','LineWidth',2,'MarkerSize',8);
end
xlabel('Number of Insert Pulses'); ylabel('Latency (ms)');
title('Response Latency vs Insert Number');
legend(conditions);
set(gca,'XScale','log'); grid on;
