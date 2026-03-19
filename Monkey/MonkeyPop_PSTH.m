ccc;
cd(fileparts(mfilename('fullpath')));

%% load data
protStr = "LocalGlobal_3_3o75_TempSpec";
DataSetName = "RawPop";
MonkeyName = "CC";
MatName = 'chSpkRes_V1.mat';
run('MonkeyPop_loadData.m');

%% params
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
GroupIdx = {1:7, 8:14};
ControlIdx = find(contains(trialTypes, "Control"));

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
yscale = [-1.5, 9.5];
plotWin = [-100, 300];
tPSTH = tmp(1).params.tPSTH;
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
groupTitles = [unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{1}))), ...
               unique(cellfun(@(x) string([x{1}, '-', x{2}]), stimstrtemp(GroupIdx{2})))];
legends = cellfun(@(x) string(x{3}), stimstrtemp);
for gIdx = 1 : numel(GroupIdx)
    subplot(1, 2, gIdx);
    plot(tPSTH, y{gIdx, 1}, 'LineWidth', 2);
    title(strcat(groupTitles(gIdx), " (n=", num2str(numel(chResAll_sig)), ")"));
    legend(legends(GroupIdx{gIdx}), "Location", "best");
end
scaleAxes("x", plotWin);
scaleAxes("y", yscale);




