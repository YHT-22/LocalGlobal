%% =========================
%  Population PSTH Sorting
%  Based on Poisson Latency
%  =========================
ccc;
cd(getRootDirPath(mfilename("fullpath"), 3));

%% -------- load data --------
DataSetName = "RawPop";
% MonkeyName = "CC";
% protStr = "LocalGlobal_3_3o75_TempSpec";

MonkeyName = "CM";
% MonkeyName = "Joker";
protStr = "LocalGlobal_4_4o06_Temp";

MatName = 'chSpkRes_V1.mat';
run('MonkeyPop_loadData.m');
SavePATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal", protStr);
mkdir(SavePATH);

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
trialSpkAll = changeCellRowNum(arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                                        neuron.spkRes(DevIdx).trialSpk, num2cell(1:numel(chResAll_sig(1).spkRes)), ...
                                                    'UniformOutput', false)', ...
                                        chResAll_sig, ...
                                'UniformOutput', false));

%% -------- params --------
th = 1e-6;                   % 显著性阈值
windowBase = [-200 0];       % baseline window (ms)
windowResp = [0 300];        % response window (ms)
RowNum = size(GroupIdx, 2);
ColNum = numel(trialTypes);

%% -------- calculate --------
normPSTH =[]; finalOrder = []; sortedLatencies = [];
for tIdx = 1 : numel(trialTypes)
    [normPSTH{tIdx}, sortedPSTH{tIdx}, latencies{tIdx}, finalOrder{tIdx}, sortedLatencies{tIdx}] = ...
    cal_NeuronLatencies_possion(psthMatrixAll{tIdx}, trialSpkAll{tIdx}, th, windowBase, windowResp);
end
%% -------- save data --------
savecellIdx = cellfun(@(x) finalOrder{x}, num2cell(ControlIdx), 'UniformOutput', false);
savecellIdx_inter = intersect(savecellIdx{1}, savecellIdx{2});
chRes(1).Info = "Possion_SortByInc";
chRes(1).Data = chResAll_sig(savecellIdx{1});
chRes(2).Info = "Possion_SortByDec";
chRes(2).Data = chResAll_sig(savecellIdx{2});
chRes(3).Info = "Possion_SortBoth";
chRes(3).Data = chResAll_sig(savecellIdx_inter);
save(fullfile(SavePATH, strcat(MonkeyName, "_PopData_SelectByPossion.mat")), "chRes", "tPSTH", '-v7.3');

%% -------- visualization --------
windowPlot = [-100, 500];
plotWinIdx = find(tPSTH >= windowPlot(1) & tPSTH <= windowPlot(2));
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
legends = cellfun(@(x) string(x{3}), stimstrtemp);
PSTHData = []; normPSTH = [];

set(0, ...
    'DefaultFigureUnits', 'pixels', ...
    'DefaultFigurePosition', get(0,'ScreenSize'));
FigRes = gobjects(1, 2);
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

for fIdx = 1 : 2
    FigRes(fIdx) = figure('Color','w');
    cellIdx = finalOrder{ControlIdx(fIdx)};
    for gIdx = 1 : size(GroupIdx, 2)
        tIdxs = GroupIdx{gIdx};
        linecount = 0;
        for tIdx = tIdxs
            mSubplot(RowNum + 1, numel(tIdxs), tIdx, [1, 1], "margins", [0.03, 0.03, 0.06, 0.05]);
            linecount = linecount + 1;
            plotlatencyIdx = find(ismember(finalOrder{tIdx}, cellIdx));
            plotCellNumIdx = find(ismember(cellIdx, finalOrder{tIdx}));
            % -------- PSTH processing --------
            PSTHData{tIdx} = psthMatrixAll{tIdx}(cellIdx, :);
            % smoothing
            % sortedPSTH = smoothdata(sortedPSTH,2,'gaussian',5);
            normFactor = max(PSTHData{tIdx},[],2);
            normFactor(normFactor==0) = 1;
            normPSTH{tIdx} = PSTHData{tIdx} ./ normFactor;
            imagesc(tPSTH(plotWinIdx),1:length(cellIdx),normPSTH{tIdx}(:, plotWinIdx));
            axis tight
            
            colormap(jet)
            colorbar
            
            hold on
            plot(sortedLatencies{tIdx}(plotlatencyIdx), plotCellNumIdx, 'r.', 'markersize', 10);
    
            xline(0,'--w','LineWidth',1.5);
            if tIdx > numel(tIdxs)
                xlabel('Time (ms)');
            end
            if ismember(tIdx, ControlIdx)
                ylabel('Neuron (sorted by latency)');
            end
            title([char(strrep(trialTypes(tIdx), "_", "-")) ' (n = ' num2str(length(cellIdx)) ')']);        
            set(gca,'fontsize',8,'linewidth',1.2);
        end
        mSubplot(RowNum + 1, size(GroupIdx, 2), 2*size(GroupIdx, 2) + gIdx, [1, 1], "margins", [0.03, 0.03, 0.05, 0.12]);
        set(gca, 'ColorOrder', colorpool, 'NextPlot', 'replacechildren');
        MeanPSTH = cell2mat(cellfun(@(x) mean(x, 1), PSTHData(tIdxs), 'UniformOutput', false)');
        plot(tPSTH(plotWinIdx)', MeanPSTH(:, plotWinIdx), 'LineWidth', 2);hold on;
        title(strrep(string(regexpi(strrep(trialTypes(ControlIdx(gIdx)), '.', 'o'), '(\w+ms)', 'tokens')), '_', '-'));
        legend(legends(tIdxs), "Location", "best");

    end
    %% print figure
    exportgraphics(FigRes(fIdx), fullfile(SavePATH, strcat(MonkeyName, "_SortBy", ...
        string(regexpi(strrep(trialTypes(ControlIdx(fIdx)), '.', 'o'), '(\w+ms)', 'tokens')), ...
        "_PSTHHeatmap_possion.jpg")));
    
end
close all;


