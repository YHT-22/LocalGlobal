%% =========================
%  Population PSTH Sorting
%  Based on Poisson Latency
%  =========================
%% -------- load data --------
ccc;
DataSetName = "RawPop";
run('load_popData.m');
SavePATH = fullfile(getRootDirPath(mfilename("fullpath"), 3), "Figure\LocalGlobal", protStr, "Mice");
mkdir(SavePATH);
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(contains(trialTypes, "Control"));
GroupIdx = {1:7, 8:14};

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
save(fullfile(SavePATH, "PopData_SelectByPossion.mat"), "chRes", "tPSTH", '-v7.3');

%% -------- visualization --------
windowPlot = [-100, 500];
plotWinIdx = find(tPSTH >= windowPlot(1) & tPSTH <= windowPlot(2));
stimstrtemp = cellfun(@(x) strsplit(x, '_'), cellstr(trialTypes), 'UniformOutput', false);
legends = cellfun(@(x) string(x{3}), stimstrtemp);
PSTHData = []; normPSTH = [];
for fIdx = 1 : 2
    figure('Color','w','WindowState','maximized');
    cellIdx = finalOrder{ControlIdx(fIdx)};
    for gIdx = 1 : size(GroupIdx, 2)
        tIdxs = GroupIdx{gIdx};
        for tIdx = tIdxs
            mSubplot(RowNum + 1, numel(tIdxs), tIdx, [1, 1], "margins", [0.03, 0.03, 0.06, 0.05]);
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
            plot(sortedLatencies{tIdx}(plotlatencyIdx), plotCellNumIdx, 'r.','markersize',10);
    
            xline(0,'--w','LineWidth',1.5)
            if tIdx > 7
                xlabel('Time (ms)');
            end
            if tIdx == 1 | tIdx == 8
                ylabel('Neuron (sorted by latency)')
            end
            title([char(strrep(trialTypes(tIdx), "_", "-")) ' (n = ' num2str(length(cellIdx)) ')'])        
            set(gca,'fontsize',8,'linewidth',1.2)
        end
        mSubplot(RowNum + 1, size(GroupIdx, 2), 2*size(GroupIdx, 2) + gIdx, [1, 1], "margins", [0.03, 0.03, 0.05, 0.12]);
        MeanPSTH = cell2mat(cellfun(@(x) mean(x, 1), PSTHData(tIdxs), 'UniformOutput', false)');
        plot(tPSTH(plotWinIdx)', MeanPSTH(:, plotWinIdx), 'LineWidth', 2);hold on;
        title(strrep(string(regexpi(trialTypes(ControlIdx(gIdx)), '(\w+ms)', 'tokens')), '_', '-'));
        legend(legends(tIdxs), "Location", "best");

    end
end