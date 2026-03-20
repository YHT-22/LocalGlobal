ccc;
cd(fileparts(mfilename('fullpath')));

%% save Path
% FigRootPath = "H:\Figure\LocalGlobal";
FigRootPath = "G:\Figure\LocalGlobal";

%% load data
DataSetName = "RawPop";
MonkeyName = "CC";
protStr = "LocalGlobal_3_3o75_TempSpec";

% MonkeyName = "CM";
% MonkeyName = "Joker";
% protStr = "LocalGlobal_4_4o06_Temp";

MatName = 'chSpkRes_V1.mat';
run('MonkeyPop_loadData.m');

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

%% select cell
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

switch MonkeyName
    case "CC"
        yscale = [-1.5, 9.5];
    case "CM"
        yscale = [-1.5, 11];
    case "Joker"
        yscale = [-1.5, 9.5];
end
plotWin = [-100, 500];
tPSTH = tmp(1).params.tPSTH;
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
groupTitles = [unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{1}))), ...
               unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{2})))];
legends = cellfun(@(x) string(x{3}), stimstrtemp);
for gIdx = 1 : numel(GroupIdx)
    subplot(1, 2, gIdx);
    plot(tPSTH, y{gIdx, 1}, 'LineWidth', 2);
    title(strcat(MonkeyName, " | ", groupTitles(gIdx), " (n=", num2str(numel(chResAll_sig)), ")"));
    legend(legends(GroupIdx{gIdx}), "Location", "best");
end
scaleAxes("x", plotWin);
scaleAxes("y", yscale);

%% print figure
exportgraphics(gcf, fullfile(FigRootPath, protStr, strcat(MonkeyName, "_PSTHRawWave.jpg")));
close;



