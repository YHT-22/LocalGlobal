%% ------------------------------
% 参数设置
%% ------------------------------
[nNeuron,nCond,nTime] = size(PSTH_bs);
nPairs = 7;      % 7 插入条件
nPC = 3;         % PCA 维度
insertNames = {'1','2','4','8','16','32','500'};  % 插入数量标签
windowPlot = [-100, 500];
% 颜色渐变（蓝->红）
colors = [0 0 1; 0.1667 0 0.8333; 0.3333 0 0.6667; 0.5 0 0.5; 0.6667 0 0.3333; 0.8333 0 0.1667; 1 0 0];
timeIdx = tPSTH > windowPlot(1) & tPSTH < windowPlot(2);
timeVectemp = timeVec(timeIdx);
%% ------------------------------
% 数据 reshape + PCA
%% ------------------------------
X = reshape(PSTH_bs, [], nNeuron);
Xz = zscore(X,0,1);
[~, score] = pca(Xz);

% reshape 回 condition × time × PC
score_ctp = zeros(nCond,nTime,nPC);
rowIdx = 1;
for c=1:nCond
    for t=1:nTime
        score_ctp(c,t,:) = score(rowIdx,1:nPC);
        rowIdx = rowIdx+1;
    end
end

%% ------------------------------
% 提取 Condition A/B 轨迹 (PC1)
%% ------------------------------
trajA = squeeze(score_ctp(1:nPairs,:,1));   % 7×nTime
trajB = squeeze(score_ctp(8:14,:,1));      % 7×nTime

%% ------------------------------
% 计算每条轨迹峰值和延迟
%% ------------------------------
% 峰值幅度和峰值时间
[peakAmpA,idxPeakA] = max(trajA(:, timeIdx),[],2);
latencyA = timeVectemp(idxPeakA);

[peakAmpB,idxPeakB] = max(trajB(:, timeIdx),[],2);
latencyB = timeVectemp(idxPeakA);

%% ------------------------------
% 绘制 PCA 轨迹
%% ------------------------------
set(gcf,'WindowState','maximized');
for k=1:nPairs
    mSubplot(2, nPairs, k, [1, 1]);
    plot(tPSTH(timeIdx), smoothdata(trajA(k,timeIdx), 2, "gaussian", 10), 'r', 'LineWidth',2);hold on;
    plot(tPSTH(timeIdx), smoothdata(trajB(k,timeIdx), 2, "gaussian", 10), 'b--', 'LineWidth',2);hold on;
    xlim(windowPlot);
end
xlabel('Time (ms)'); ylabel('PC1 Projection');
title('Condition A (solid) vs B (dashed) PCA trajectories');
legendLabels = cell(1,nPairs*2);
for k=1:nPairs
    legendLabels{k} = ['A Insert' insertNames{k}];
    legendLabels{k+nPairs} = ['B Insert' insertNames{k}];
end
legend(legendLabels,'Location','eastoutside'); grid on;

%% ------------------------------
% 绘制峰值幅度随插入数量变化
%% ------------------------------
figure('Color','w'); hold on;
plot(1:nPairs, peakAmpA, '-o','LineWidth',2,'Color',[0.85 0.2 0.2]);
plot(1:nPairs, peakAmpB, '--s','LineWidth',2,'Color',[0.2 0.2 0.85]);
xlabel('Insert number'); ylabel('Peak amplitude (PC1)');
xticks(1:nPairs); xticklabels(insertNames);
title('Peak amplitude vs Insert number');
legend({'Condition A','Condition B'},'Location','northwest'); grid on;

%% ------------------------------
% 绘制延迟随插入数量变化
%% ------------------------------
figure('Color','w'); hold on;
plot(1:nPairs, latencyA, '-o','LineWidth',2,'Color',[0.85 0.2 0.2]);
plot(1:nPairs, latencyB, '--s','LineWidth',2,'Color',[0.2 0.2 0.85]);
xlabel('Insert number'); ylabel('Latency (ms)');
xticks(1:nPairs); xticklabels(insertNames);
title('Peak latency vs Insert number');
legend({'Condition A','Condition B'},'Location','northwest'); grid on;
