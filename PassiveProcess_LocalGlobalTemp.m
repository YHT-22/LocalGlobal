function trialAll = PassiveProcess_LocalGlobalTemp(epocs)
%check ICI sequence
ExcludeICIIdx  = find(roundn(epocs.ICI0.data, -1) == 0);
epocs.ICI0.data(ExcludeICIIdx) = [];
epocs.ICI0.onset(ExcludeICIIdx) = [];
epocs.ICI0.offset(ExcludeICIIdx) = [];
epocs.ordr.data(ExcludeICIIdx) = [];
epocs.ordr.onset(ExcludeICIIdx) = [];
epocs.ordr.offset(ExcludeICIIdx) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trialOnset = epocs.Swep.onset * 1000; % ms
ICIOnset = epocs.ICI0.onset * 1000; % ms
ICIAll = epocs.ICI0.data;
trialAll = [];
cellArrayAll = [];
for tIdx = 1 : length(trialOnset)
    devordr = [];
    if tIdx < length(trialOnset)
        trialtimeIdx = find(ICIOnset >= trialOnset(tIdx) & ICIOnset < trialOnset(tIdx + 1));
    else
        trialtimeIdx = find(ICIOnset >= trialOnset(tIdx));
    end
    onIdx    = find([0; diff(ICIAll(trialtimeIdx))]);
    InsertICI   = ICIAll(trialtimeIdx(onIdx(1)));
    BaseICI    = ICIAll(trialtimeIdx(onIdx(2)));

    ICIOnsetTemp = ICIOnset(trialtimeIdx);
    InsertIdx = find(ICIAll(trialtimeIdx) == InsertICI);
    IdxTemp = [find([0; diff(InsertIdx)] ~= 1);numel(InsertIdx)+1];
    Insert_Num = diff(IdxTemp);
    Insert_Time = ICIOnsetTemp(InsertIdx(IdxTemp(1:end-1)));
    trialNum      = (tIdx - 1) * numel(Insert_Num) + (1 : numel(Insert_Num))';
    if BaseICI < InsertICI
        trialType = cellfun(@(InNum) strcat(string(BaseICI), '_', string(InsertICI), '_IncN', string(InNum)), ...
                            mat2cell(Insert_Num, ones([size(Insert_Num, 1), 1])));
        for i = 1:length(Insert_Num)
            devordr(i, 1) = find(Insert_Num(i) == sort(Insert_Num));
        end
    elseif BaseICI > InsertICI
        trialType = cellfun(@(InNum) strcat(string(BaseICI), '_', string(InsertICI), '_DecN', string(InNum)), ...
                            mat2cell(Insert_Num, ones([size(Insert_Num, 1), 1])));
        for i = 1:length(Insert_Num)
            devordr(i, 1) = find(Insert_Num(i) == sort(Insert_Num)) + numel(Insert_Num);
        end
    end

    % construct struct
    matrixCell = num2cell([trialNum, Insert_Time, devordr, ...
                    repmat(InsertICI, numel(trialNum), 1), ...
                    repmat(BaseICI, numel(trialNum), 1), ...
                    Insert_Num]);
    strCell = arrayfun(@(x) x, trialType, 'UniformOutput', false);
    cellArrayTemp = [matrixCell, strCell];
    cellArrayAll = [cellArrayAll; cellArrayTemp];

end
    trialAll      = cell2struct([cellArrayAll(:, 1), cellArrayAll(:, 2), cellArrayAll(:, 3), ...
                                cellArrayAll(:, 4), cellArrayAll(:, 5), cellArrayAll(:, 6), ...
                                cellArrayAll(:, 7)], ... 
                                {'trialNum', 'soundOnsetSeq', 'devOrdr', 'InsertICI', 'BaseICI', 'InsertNum', 'trialType'}, 2); 
end


