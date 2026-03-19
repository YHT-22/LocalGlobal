function LocalGlobalparams = LA_ParseLocalGlobalParams_TempSpec(ProtocolStr)

ConfigExcelPATH = strcat(fileparts(fileparts(mfilename("fullpath"))), "\config\MouseLA_LocalGlobalConfig.xlsx");
LocalGlobalparamsAll = table2struct(readtable(ConfigExcelPATH, "Sheet", "LocalGlobal"));
idx = find(strcmp(ProtocolStr, {LocalGlobalparamsAll.ProtocolType}));
SoundROOTPATH = evalin('base', 'SoundROOTPATH');

%% update
% LocalGlobalparamsAll(idx).Duration = string(DurationInfo(1) * 1000);
% writetable(struct2table(LocalGlobalparamsAll), ConfigExcelPATH, "Sheet", "LocalGlobal");

%% get params
LocalGlobalparams.Protocol = string(LocalGlobalparamsAll(idx).ProtocolType);
LocalGlobalparams.stimStrs = regexpi(string(LocalGlobalparamsAll(idx).stimStrs), ",", "split");
LocalGlobalparams.Colors = regexpi(string(LocalGlobalparamsAll(idx).Colors), ",", "split");
LocalGlobalparams.GroupTypes = cellfun(@double, ...
                                rowFcn(@(x) regexpi(x, ",", "split"), ...
                                regexpi(string(LocalGlobalparamsAll(idx).GroupTypes), ";", "split")', "UniformOutput", false),...
                                'UniformOutput', false);
LocalGlobalparams.SoundMatPath = string(LocalGlobalparamsAll(idx).SoundMatPath);
LocalGlobalparams.trialonset_Win = double(regexpi(string(LocalGlobalparamsAll(idx).trialonset_Window), ",", "split"));
LocalGlobalparams.Window = double(regexpi(string(LocalGlobalparamsAll(idx).devonset_Window), ",", "split"));
LocalGlobalparams.ICAWindow = double(regexpi(string(LocalGlobalparamsAll(idx).ICAWindow), ",", "split"));
LocalGlobalparams.plotWin = double(regexpi(string(LocalGlobalparamsAll(idx).plotWindow), ",", "split"));
LocalGlobalparams.compareWin = double(regexpi(string(LocalGlobalparamsAll(idx).compareWindow), ",", "split"));
LocalGlobalparams.sigTestWin = double(regexpi(string(LocalGlobalparamsAll(idx).sigTestWin), ",", "split"));
LocalGlobalparams.sigTestMethod = "ttest2";
eval(strcat("LocalGlobalparams.chPlotFcn = ", string(LocalGlobalparamsAll(idx).chPlotFcn), ";"))

%load sound wave
SoundsInfo = [];
[Sound1, Soundfs] = audioread(fullfile(SoundROOTPATH, '\2025-06-12_LocalGlobal_3_3o75_None_Int_Cor\Reg3_3o75_3_Seq1.wav'));
Sound2 = audioread(fullfile(SoundROOTPATH, '\2025-06-12_LocalGlobal_3_3o75_None_Int_Cor\Reg3_3o75_3_Seq2.wav'));
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
LocalGlobalparams.LocalGlobalsoundinfo = SoundsInfo;

end
