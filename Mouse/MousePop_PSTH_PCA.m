%% =========================
% PCA analysis for population PSTH
% Data size: neuron x condition x time
% Example: 100 x 14 x 1671

%% ---------- Load or assign your data ----------
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
windowBase = [-200, 0];

%% -------- select cell --------
DataTemp = tmp.chRes(3).Data;
psthMatrixAll = arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                        neuron.spkRes(DevIdx).PSTH', num2cell(1:numel(trialTypes)), ...
                                    'UniformOutput', false)', ...
                        DataTemp, ...
                'UniformOutput', false);
Temp = cellfun(@cell2mat, psthMatrixAll, 'UniformOutput', false);
psthMatrixAll = permute(cat(3,Temp{:}),[3 1 2]);
[nNeuron, nCond, nTime] = size(psthMatrixAll);

%% ---------- Condition labels ----------
condNames = { ...
    'Inc1','Inc2','Inc4','Inc8','Inc16','Inc32','IncCtrl', ...
    'Dec1','Dec2','Dec4','Dec8','Dec16','Dec32','DecCtrl'};

insertNums = [1 2 4 8 16 32 500, 1 2 4 8 16 32 500];
condGroup  = [ones(1,7), 2*ones(1,7)];   % 1 = A, 2 = B
colors = [ ...
    0.0000 0.0000 1.0000;  % 蓝
    0.1667 0.0000 0.8333;  
    0.3333 0.0000 0.6667;  
    0.5000 0.0000 0.5000;  
    0.6667 0.0000 0.3333;  
    0.8333 0.0000 0.1667;  
    1.0000 0.0000 0.0000]; % 红
% Optional time vector
timeVec = 1:nTime;   % replace with real ms if available

%% ---------- Optional smoothing ----------
% Smooth along time dimension to reduce noise
doSmooth = false;
smoothWin = 15;  % adjust if needed

PSTH_s = psthMatrixAll;
if doSmooth
    for n = 1:nNeuron
        for c = 1:nCond
            PSTH_s(n,c,:) = smoothdata(squeeze(psthMatrixAll(n,c,:)), 'gaussian', smoothWin);
        end
    end
end

%% ---------- Baseline subtraction (recommended) ----------
% Define baseline window, modify according to your experiment
% Example: first 100 time points as baseline
baselineIdx = find(tPSTH > windowBase(1) & tPSTH < windowBase(2));
PSTH_bs = PSTH_s;
for n = 1:nNeuron
    for c = 1:nCond
        x = squeeze(PSTH_s(n,c,:));
        b = mean(x(baselineIdx));
        PSTH_bs(n,c,:) = x - b;
    end
end

%% ---------- Build population matrix for PCA ----------
X = zeros(nCond*nTime, nNeuron);
rowIdx = 1;
for c = 1:nCond
    for t = 1:nTime
        X(rowIdx,:) = PSTH_bs(:,c,t)';   % 1 x neuron
        rowIdx = rowIdx + 1;
    end
end

%% ---------- Z-score across states for each neuron ----------
Xz = zscore(X, 0, 1);   % normalize each neuron column

%% ---------- PCA ----------
[coeff, score, latent, ~, explained, mu] = pca(Xz);

% coeff: neuron x PC
% score: (condition*time) x PC

nPCplot = 5;

fprintf('Explained variance of first %d PCs:\n', nPCplot);
disp(explained(1:nPCplot));

%% ---------- Reshape PCA score back to condition x time x PC ----------
score_ctp = zeros(nCond, nTime, size(score,2));

rowIdx = 1;
for c = 1:nCond
    for t = 1:nTime
        score_ctp(c,t,:) = score(rowIdx,:);
        rowIdx = rowIdx + 1;
    end
end

%% ------------------------------
% 计算原始轨迹距离
%% ------------------------------
nPairs = 7;
nPC = 3;
distAB = zeros(nPairs,nTime);
for k = 1:nPairs
    trajA = squeeze(score_ctp(k,:,1:nPC));      % A condition
    trajB = squeeze(score_ctp(k+7,:,1:nPC));    % B condition
    distAB(k,:) = sqrt(sum((trajA - trajB).^2, 2));  % Euclidean distance
end

% Permutation 计算显著性
%% ------------------------------
nPerm = 500;
distPerm = zeros(nPairs, nTime, nPerm);

for p = 1:nPerm
    % 随机打乱条件标签
    permIdx = randperm(nCond);  % 14 条条件随机重排
    for k = 1:nPairs
        trajA_perm = squeeze(score_ctp(permIdx(k),:,1:nPC));
        trajB_perm = squeeze(score_ctp(permIdx(k+7),:,1:nPC));
        distPerm(k,:,p) = sqrt(sum((trajA_perm - trajB_perm).^2,2));
    end
end

%% ------------------------------
% 标记显著分离时间段
%% ------------------------------
sig_mask = false(nPairs,nTime);  % boolean mask
for k = 1:nPairs
    for t = 1:nTime
        % p-value = proportion of permuted distances >= 原始距离
        pval = mean(distPerm(k,t,:) >= distAB(k,t));
        sig_mask(k,t) = (pval < 0.05);
    end
end

%%
figure('Color','w','WindowState','maximized'); hold on;
h_bar = 0.6; gap = 0.2;
y_min = linspace(-5, (nPairs-1)*(h_bar+gap), nPairs);
y_max = y_min + h_bar;

colors = [0 0 1;0.1667 0 0.8333;0.3333 0 0.6667;0.5 0 0.5;0.6667 0 0.3333;0.8333 0 0.1667;1 0 0]; 

for k = 1:nPairs
    plot(tPSTH, distAB(k,:), 'LineWidth',2,'Color',colors(k,:));
    
    % 标记显著分离时间段
    sig_idx = sig_mask(k,:);
    sig_diff = diff([0 sig_idx 0]);
    starts = find(sig_diff == 1);
    ends   = find(sig_diff == -1) - 1;
    
    % 横条标记显著区间
    for s = 1:length(starts)
        fill([tPSTH(starts(s)) tPSTH(ends(s)) tPSTH(ends(s)) tPSTH(starts(s))], ...
             [y_min(k) y_min(k) y_max(k) y_max(k)], ...
             colors(k,:), 'FaceAlpha',0.4, 'EdgeColor','none', 'HandleVisibility', 'off');
    end
end

xlabel('Time (ms)');
ylabel('Trajectory distance (A vs B)');
title('Condition A/B trajectory distance with permutation significance');
legend({'Insert1','Insert2','Insert4','Insert8','Insert16','Insert32','Control'}, 'Location','eastoutside');
grid on; box on;

%% =========================
% Plot 2: 2D neural trajectories (PC1 vs PC2)
%% =========================
figure('Name','Neural trajectories: PC1-PC2','NumberTitle','off','Color','w','WindowState','maximized');
hold on;

colorA = [...
    1.0 1.0 0.5;   % 条件1: 浅黄
    1.0 0.85 0.4;  % 条件2: 黄橙
    1.0 0.7 0.3;   % 条件3: 橙
    1.0 0.55 0.2;  % 条件4: 深橙
    0.9 0.35 0.2;  % 条件5: 红橙
    0.8 0.2 0.2;   % 条件6: 红
    0.7 0.0 0.0;   % 条件7: 深红
];

colorB = [...
    0.6 1.0 1.0;   % 条件1: 浅青
    0.4 0.9 1.0;   % 条件2: 天青
    0.2 0.8 1.0;   % 条件3: 浅蓝
    0.0 0.7 1.0;   % 条件4: 蓝
    0.0 0.55 0.9;  % 条件5: 深蓝
    0.0 0.4 0.8;   % 条件6: 深蓝+绿
    0.0 0.25 0.7;  % 条件7: 深蓝
];

for c = 1:7
    plot(squeeze(score_ctp(c,:,1)), squeeze(score_ctp(c,:,2)), ...
        'LineWidth', 2, 'Color', colorA(c,:));
    plot(score_ctp(c,1,1), score_ctp(c,1,2), 'o', ...
        'MarkerFaceColor', colorA(c,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 6, 'HandleVisibility','off');
end

for c = 8:14
    plot(squeeze(score_ctp(c,:,1)), squeeze(score_ctp(c,:,2)), ...
        '--', 'LineWidth', 2, 'Color', colorB(c-7,:));
    plot(score_ctp(c,1,1), score_ctp(c,1,2), 's', ...
        'MarkerFaceColor', colorB(c-7,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 6, 'HandleVisibility','off');
end

xlabel(sprintf('PC1 (%.2f%%)', explained(1)));
ylabel(sprintf('PC2 (%.2f%%)', explained(2)));
title('Population trajectories in PC1-PC2 space');
legend(condNames, 'Location', 'eastoutside');
grid on; axis tight;

%% =========================
% Plot 3: 3D neural trajectories (PC1-PC2-PC3)
%% =========================
figure('Name','Neural trajectories: PC1-PC2-PC3','NumberTitle','off','Color','w','WindowState','maximized');
hold on;

for c = 1:7
    plot3(squeeze(score_ctp(c,:,1)), squeeze(score_ctp(c,:,2)), squeeze(score_ctp(c,:,3)), ...
        'LineWidth', 2, 'Color', colorA(c,:));
end

for c = 8:14
    plot3(squeeze(score_ctp(c,:,1)), squeeze(score_ctp(c,:,2)), squeeze(score_ctp(c,:,3)), ...
        '--', 'LineWidth', 2, 'Color', colorB(c-7,:));
end

xlabel(sprintf('PC1 (%.2f%%)', explained(1)));
ylabel(sprintf('PC2 (%.2f%%)', explained(2)));
zlabel(sprintf('PC3 (%.2f%%)', explained(3)));
title('Population trajectories in PC1-PC2-PC3 space');
grid on; axis tight; view(3);

