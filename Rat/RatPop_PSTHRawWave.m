%% ==========================================
ccc;
cd(fileparts(mfilename('fullpath')));

%% -------- load data --------
DataSetName = "RawPop";
protStr = "LocalGlobal_4_5_Temp";

MatName = 'chSpkRes_devOnset.mat';
run('RatPop_loadData.m');

SavePATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal", protStr);
mkdir(SavePATH);

%% params
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(arrayfun(@(str)contains(str, 'Inf'), trialTypes));
GroupIdx = {2:8, 10:16};
Regions = ["AC" , "MGB", "IC", "CN"];

%% -------- select cell --------
sigtestRes = arrayfun(@(x) arrayfun(@(y) ttest(y.devCount, y.baseCount, "Alpha",  0.01), x.spkRes), chResAll, 'UniformOutput', false);
sigIdx = find(cellfun(@(x) any(x(ControlIdx) == 1), sigtestRes));
chResAll_sig = chResAll(sigIdx);

%% minus baseline
y = [];
for gIdx = 1 : numel(GroupIdx)
    Idx = GroupIdx{gIdx};
    for tIdx = 1 : numel(Idx)
        y{gIdx, 1}(:, tIdx) = mean(cell2mat(arrayfun(@(x) x.spkRes(Idx(tIdx)).PSTH - x.spkRes(Idx(tIdx)).baseFR, chResAll_sig, 'UniformOutput', false)'), 2);
    end
end

%% plot PSTH
set(0, ...
    'DefaultFigureUnits', 'pixels', ...
    'DefaultFigurePosition', get(0,'ScreenSize'));
colorpool = [
    0.23 0.30 0.75  % 深蓝（最冷）
    0.27 0.46 0.82  % 蓝
    0.30 0.62 0.85  % 蓝青
    0.35 0.75 0.75  % 青
    0.60 0.80 0.60  % 青绿（过渡）
    0.85 0.75 0.45  % 黄橙
    0.90 0.55 0.30  % 橙
    0.80 0.25 0.20  % 红（最暖）
];

plotWin = [-100, 500];
tPSTH = tmp(1).params.tPSTH;
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
groupTitles = [unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{1}))), ...
               unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{2})))];
legends = cellfun(@(x) string(x{3}), stimstrtemp);
for gIdx = 1 : numel(GroupIdx)
    subplot(1, 2, gIdx);
    set(gca, 'ColorOrder', colorpool, 'NextPlot', 'replacechildren');
    plot(tPSTH, y{gIdx, 1}, 'LineWidth', 2);
    title(strcat(MonkeyName, " | ", groupTitles(gIdx), " (n=", num2str(numel(chResAll_sig)), ")"));
    legend(legends(GroupIdx{gIdx}), "Location", "best");
end
scaleAxes("x", plotWin);
scaleAxes("y", "on");

%% print figure
exportgraphics(gcf, fullfile(FigRootPath, protStr, strcat(MonkeyName, "_PSTHRawWave.jpg")));
close;



