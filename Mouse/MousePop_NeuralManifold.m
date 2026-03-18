%% =============================
% Population neural manifold
% PCA trajectory
% =============================
ccc;
cd(fileparts(mfilename('fullpath')));

%% load data
run('load_popData.m');
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(contains(trialTypes, "Control"));

%% select cell
sigtestRes = arrayfun(@(x) arrayfun(@(y) ttest(y.devCount, y.baseCount, "Alpha",  0.01), x.spkRes), chResAll, 'UniformOutput', false);
sigIdx = find(cellfun(@(x) any(x(ControlIdx) == 1), sigtestRes));
chResAll_sig = chResAll(sigIdx);

%%
psthMatrixAll = arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                        neuron.spkRes(DevIdx).PSTH', num2cell(1:numel(chResAll_sig(1).spkRes)), ...
                                    'UniformOutput', false)', ...
                        chResAll_sig, ...
                'UniformOutput', false);
psthData = cellfun(@cell2mat, changeCellRowNum(psthMatrixAll), 'UniformOutput', false);
numCond = numel(chResAll_sig(1).spkRes);
% psthData{1} ... psthData{14}
% 每个矩阵: neurons × time
timeAxes = tPSTH;

%% ---------- 参数 ----------
smoothSigma = 5;
baselineWindow = [-200 0];
respWindow = [0 300];
nPC = 3;

%% ---------- 找baseline index ----------
baseIdx = timeAxes >= baselineWindow(1) & timeAxes <= baselineWindow(2);

%% ---------- 预处理 ----------
procData = cell(numCond,1);

for c = 1:numCond
    
    psth = psthData{c};
    
    % baseline subtraction
    base = mean(psth(:,baseIdx),2);
    psth = psth - base;
    
    % zscore normalization
    psth = zscore(psth,0,2);
    
    % temporal smoothing
    psth = smoothdata(psth,2,'gaussian',smoothSigma);
    
    procData{c} = psth;
    
end

%% ---------- 拼接数据做PCA ----------
allData = [];

for c = 1:numCond
    
    data = procData{c}';
    
    allData = [allData; data];
    
end

%% ---------- PCA ----------
[coeff,score,latent] = pca(allData);

explainedVar = latent / sum(latent);

fprintf('PC1 variance = %.2f%%\n',explainedVar(1)*100)
fprintf('PC2 variance = %.2f%%\n',explainedVar(2)*100)
fprintf('PC3 variance = %.2f%%\n',explainedVar(3)*100)

%% ---------- 绘制 manifold ----------
figure('color','w','position',[200 200 900 700])
hold on

colors = lines(numCond);

for c = 1:numCond
    
    data = procData{c}';
    
    proj = data * coeff(:,1:nPC);
    
    pc1 = proj(:,1);
    pc2 = proj(:,2);
    pc3 = proj(:,3);
    
    %% 轨迹
    % plot3(pc1,pc2,pc3,'Color',colors(c,:),'LineWidth',2)
    
    %% 起点
    scatter3(pc1(1),pc2(1),pc3(1),70,colors(c,:),'filled')
    
    %% 终点
    scatter3(pc1(end),pc2(end),pc3(end),70,colors(c,:),'d','filled')
    
    %% stimulus onset
    onsetIdx = find(timeAxes==0);
    
    scatter3(pc1(onsetIdx),pc2(onsetIdx),pc3(onsetIdx),90,'k','filled')
    
    %% trajectory arrows
    step = 100;

    idx = 1:step:length(pc1);
    
    % 位置
    x = pc1(idx(1:end-1));
    y = pc2(idx(1:end-1));
    z = pc3(idx(1:end-1));
    
    % 方向
    u = pc1(idx(2:end)) - pc1(idx(1:end-1));
    v = pc2(idx(2:end)) - pc2(idx(1:end-1));
    w = pc3(idx(2:end)) - pc3(idx(1:end-1));
    
    quiver3(x,y,z,u,v,w,0,'Color',colors(c,:),'LineWidth',2);

end

grid on

xlabel('PC1')
ylabel('PC2')
zlabel('PC3')

title('Population Neural Manifold Dynamics')

view(40,30)

%% ---------- neural trajectory speed ----------
figure('color','w','position',[200 200 800 500])
hold on

for c = 1:numCond
    
    data = procData{c}';
    
    proj = data * coeff(:,1:nPC);
    
    % trajectory speed
    dX = diff(proj);
    
    speed = sqrt(sum(dX.^2,2));
    
    plot(timeAxes(2:end),speed,'LineWidth',2)
    
end

xlabel('Time (ms)')
ylabel('Neural State Speed')

title('Neural Trajectory Speed')

xline(0,'k--')

set(gca,'fontsize',12,'linewidth',1.2)

%% ---------- manifold variance ----------
figure('color','w')

bar(explainedVar(1:10)*100)

xlabel('Principal Component')
ylabel('Variance Explained (%)')

title('Neural Manifold Variance Structure')

set(gca,'fontsize',12)