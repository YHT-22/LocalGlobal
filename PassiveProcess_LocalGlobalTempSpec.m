function trialAll = PassiveProcess_LocalGlobalTempSpec(epocs)
%load sound wave
SoundRootPath = 'G:\LocalGlobal\Sounds';
SoundsInfo = [];
[Sound1, Soundfs] = audioread(fullfile(SoundRootPath, '2025-06-12_LocalGlobal_3_3o75_None_Int_Cor\Reg3_3o75_3_Seq1.wav'));
Sound2 = audioread(fullfile(SoundRootPath, '2025-06-12_LocalGlobal_3_3o75_None_Int_Cor\Reg3_3o75_3_Seq2.wav'));
% Sound3 = audioread('.\LocalGlobal\Sounds\2025-06-09_RegInsert_Freq\LocalGlobal_Frequency_f1_2000_f2_2025.wav');
% Sound4 = audioread('.\LocalGlobal\Sounds\2025-06-09_RegInsert_Freq\LocalGlobal_Frequency_f2_2025_f1_2000.wav');
SoundsWave = {Sound1, Sound2};
SoundsInfo = [];
for sIdx = 1 : length(SoundsWave)
    SoundWave_Temp = SoundsWave{sIdx};
    timeSamplePoints = linspace(1/Soundfs, length(SoundWave_Temp)/Soundfs, length(SoundWave_Temp))' * 1000;% ms
    ICIOnset = timeSamplePoints(diff([0; SoundWave_Temp]) > 0);% ms
    ICISeq = round(diff(ICIOnset), 2);
    BaseICI = mode(ICISeq);
    InsertICI = unique(ICISeq(ICISeq ~= BaseICI));
    ICISeq = [ICISeq; BaseICI];
    if BaseICI < InsertICI
        onIdx = find(diff([ICISeq(1); ICISeq]) > 0);
        offIdx = find(diff([ICISeq(1); ICISeq]) < 0);
    else
        onIdx = find(diff([ICISeq(1); ICISeq]) < 0);
        offIdx = find(diff([ICISeq(1); ICISeq]) > 0);
    end
    InsertOnTime = ICIOnset(onIdx);
    InsertOffTime = ICIOnset(offIdx);
    InsertNumber = offIdx - onIdx;
    SoundNameTemp = {['Temp_', num2str(BaseICI), '_', num2str(InsertICI)]};
    % construct struct
    SoundsInfoTemp = cell2struct([SoundNameTemp, num2cell(BaseICI), num2cell(InsertICI), SoundsWave(sIdx), ...
                                  {[InsertNumber, InsertOnTime, InsertOffTime]}],...
                                {'SoundName', 'BaseICI', 'InsertICI', 'SoundWave', 'InsertTimeAndNum'}, 2);
    SoundsInfo = [SoundsInfo; SoundsInfoTemp];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trialOdrAll = epocs.ordr.data;
trialOdr_TempIdx = find(trialOdrAll == 1 | trialOdrAll == 2);
trialOnset_Temp = epocs.Swep.onset(trialOdr_TempIdx) * 1000; % ms
trialAll = [];
cellArrayAll = [];

for tIdx = 1 : length(trialOnset_Temp)
    devordr = [];
    trialOnTime = trialOnset_Temp(tIdx);
    TypeOrdr = trialOdrAll(trialOdr_TempIdx(tIdx));
    Insert_Num = SoundsInfo(TypeOrdr).InsertTimeAndNum(:, 1);
    trialNum      = (tIdx - 1) * numel(Insert_Num) + (1 : numel(Insert_Num))';
    BaseICI = SoundsInfo(TypeOrdr).BaseICI;
    InsertICI = SoundsInfo(TypeOrdr).InsertICI;
    Insert_Time = SoundsInfo(TypeOrdr).InsertTimeAndNum(:, 2) + trialOnTime;
    if BaseICI < InsertICI
        trialType = cellfun(@(InNum) strcat(string(BaseICI), '_', string(InsertICI), '_Inc_N', string(InNum)), ...
                            mat2cell(Insert_Num, ones([size(Insert_Num, 1), 1])));
        for i = 1:length(Insert_Num)
            devordr(i, 1) = find(Insert_Num(i) == sort(Insert_Num));
        end
    elseif BaseICI > InsertICI
        trialType = cellfun(@(InNum) strcat(string(BaseICI), '_', string(InsertICI), '_Dec_N', string(InNum)), ...
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


