ccc;
cd(fileparts(mfilename('fullpath')));

%% save Path
FigRootPath = "E:\Lab members\YHT\Figure\LocalGlobal";

%% load data
DataSetName = "RawPop";
protStr      = "LocalGlobal_3_3o75_TempSpec";
run('Mousepop_loadData.m');
SavePath = fullfile(FigRootPath, protStr, "Mouse");
mkdir(SavePath);

%% params
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
GroupIdx = {1:7, 8:14};
ControlIdx = find(contains(trialTypes, "Control"));

%% select cell
sigtestRes = arrayfun(@(x) arrayfun(@(y) ttest(y.devCount, y.baseCount, "Alpha",  0.01), x.spkRes), chResAll, 'UniformOutput', false);
sigIdx = find(cellfun(@(x) any(x(ControlIdx) == 1), sigtestRes));
chResAll_sig = chResAll(sigIdx);

%% process
y = [];
for gIdx = 1 : numel(GroupIdx)
    Idx = GroupIdx{gIdx};
    for tIdx = 1 : numel(Idx)
        y{gIdx, 1}(:, tIdx) = mean(cell2mat(arrayfun(@(x) x.spkRes(Idx(tIdx)).PSTH - x.spkRes(Idx(tIdx)).baseFR, chResAll_sig, 'UniformOutput', false)'), 2);
    end
end
NeuronNum = numel(chResAll_sig);

%% plot PSTH
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
yscale = [-0.5, 3];
plotWin = [-100, 300];
tPSTH = tmp(1).params.tPSTH;
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
groupTitles = [unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{1}))), ...
               unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{2})))];
legends = cellfun(@(x) string(x{3}), stimstrtemp);
FigRes = figure("Color", "w");
for gIdx = 1 : numel(GroupIdx)
    subplot(1, 2, gIdx);
    set(gca, 'ColorOrder', colorpool, 'NextPlot', 'replacechildren');

    plot(tPSTH, y{gIdx, 1}, 'LineWidth', 2);
    title(groupTitles(gIdx));
    legend(legends(GroupIdx{gIdx}), "Location", "best");
    annotation("textbox", [.5 .88 .1 .1], "String", strcat("Mouse (n = ", string(NeuronNum), ")"), ...
        "BackgroundColor", "none", "EdgeColor", "none", "FitBoxToText", "on", "FontSize", 14);
end
scaleAxes("x", plotWin);
scaleAxes("y", yscale);

%% print
exportgraphics(FigRes, fullfile(SavePath, "Mouse_PSTHRawWave.jpg"));
close;



