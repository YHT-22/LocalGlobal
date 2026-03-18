%% ===============================
% Baseline Z-score latency method
% ===============================
%% -------- load data --------
ccc;
run('load_popData.m');
trialTypes = arrayfun(@(x) string(x.stimStr), [chResAll(1).spkRes]);
ControlIdx = find(contains(trialTypes, "Control"));
GroupIdx = {1:7, 8:14};

%% -------- select cell --------
sigtestRes = arrayfun(@(x) arrayfun(@(y) ttest(y.devCount, y.baseCount, "Alpha",  0.01), x.spkRes), chResAll, 'UniformOutput', false);
sigIdx = find(cellfun(@(x) any(x(ControlIdx) == 1), sigtestRes));
chResAll_sig = chResAll(sigIdx);

%% -------- params --------
baselineWindow = [-200 0];      % baseline window (ms)
responseWindow = [0 300];       % response window (ms)
zThresh = 3;                    % Z-score threshold
minBins = 4;                    % 连续超过阈值的bin数量
RowNum = size(GroupIdx, 2);
ColNum = numel(trialTypes);

%% -------- calculate --------
latencies = []; sortedLatencies = []; finalOrder =[];
psthMatrixAll = arrayfun(@(neuron) cellfun(@(DevIdx) ...
                                        neuron.spkRes(DevIdx).PSTH', num2cell(1:numel(chResAll_sig(1).spkRes)), ...
                                    'UniformOutput', false)', ...
                        chResAll_sig, ...
                'UniformOutput', false);
psthMatrixAll = cellfun(@cell2mat, changeCellRowNum(psthMatrixAll), 'UniformOutput', false);
for tIdx = 1 : numel(trialTypes)
    [latencies{tIdx, 1}, sortedLatencies{tIdx, 1}, finalOrder{tIdx, 1}, ~] = ...
    cal_NeuronLatencies_continueBins(psthMatrixAll{tIdx}, baselineWindow, responseWindow, tPSTH, zThresh, minBins);
end
 
%% -------- visualization --------

for gIdx = 1 : size(GroupIdx, 2)
    tIdxs = GroupIdx{gIdx};
    cellIdx = finalOrder{ControlIdx(gIdx)};
    for tIdx = tIdxs
        mSubplot(RowNum, numel(tIdxs), tIdx, [1, 1], "margins",  [0.03, 0.03, 0.06, 0.03]);
        plotlatencyIdx = find(ismember(finalOrder{tIdx}, cellIdx));
        plotCellNumIdx = find(ismember(cellIdx, finalOrder{tIdx}));
        % -------- PSTH processing --------
        PSTHData = psthMatrixAll{tIdx}(cellIdx, :);
        % smoothing
        % sortedPSTH = smoothdata(sortedPSTH,2,'gaussian',5);
        normFactor = max(PSTHData,[],2);
        normFactor(normFactor==0) = 1;
        normPSTH = PSTHData ./ normFactor;
        imagesc(tPSTH,1:length(cellIdx),normPSTH);
        axis tight
        
        colormap(jet);
        colorbar;
        
        hold on;
        % plot(sortedLatencies{tIdx}(plotlatencyIdx), plotCellNumIdx, 'r.','markersize',10);
        
        xline(0,'--w','LineWidth',1.5);
        if tIdx > 7
            xlabel('Time (ms)');
        end
        if tIdx == 1 | tIdx == 8
            ylabel('Neuron (sorted by latency)');
        end
        title([char(strrep(trialTypes(tIdx), "_", "-")) ' (n = ' num2str(length(cellIdx)) ')']);
        
        set(gca,'fontsize',8,'linewidth',1.2);
    end
end