function mProcess_LocalGlobal_Temp(ROOTPATH, protStr, date)
%% Load data
baseline_Window = evalin('base', 'baseline_Window');

for pIndex = 1 : length(protStr)
    SAVEPATH                 = fullfile(ROOTPATH, protStr(pIndex), "processedRes", date);
%     try
        load(fullfile(ROOTPATH, protStr(pIndex), date, "spkData.mat"));
%     catch
%         continue
%     end
    spikeDataset             = spikeByCh(data.sortdata);
    LocalGlobalParams               = LA_ParseLocalGlobalParams_Temp(protStr(pIndex));
    LocalGlobalParams.Window        = evalin('base', 'spkSelect_Window');
    try
        trialAll{pIndex, 1}      = PassiveProcess_LocalGlobalTemp(data.epocs);
    catch
        disp(string(date));
        break;
    end
    trialAll{pIndex, 1} (1)  = [];
    % insertOff = [LocalGlobalParams.LocalGlobalsoundinfo(1).InsertTimeAndNum(:, 3); LocalGlobalParams.LocalGlobalsoundinfo(2).InsertTimeAndNum(:, 3)];
    % trialAll{pIndex, 1}      = addFieldToStruct(trialAll{pIndex, 1}, num2cell([trialAll{pIndex, 1}.soundOnsetSeq]' + insertOff([trialAll{pIndex, 1}.devOrdr]')), "devOnset");
    trialsSpike{pIndex, 1}   = selectSpike(spikeDataset, trialAll{pIndex, 1} , LocalGlobalParams, "trial onset");
    
    devOrdr{pIndex, 1}       = [trialAll{pIndex, 1}.devOrdr]'+(pIndex - 1)*2;
    stimStrs{pIndex, 1}      = unique([trialAll{pIndex, 1}.trialType]');
end

trialsSpike = cell2mat(trialsSpike); 
devOrdr = cell2mat(devOrdr); 

%% Parameter setting
% windows for firing rate
winDevResp = repmat([0, 300], length(unique(devOrdr)), 1);
winBaseResp = repmat(baseline_Window, length(unique(devOrdr)), 1);
% PSTH settings
binsize    = 30; % ms
binstep    = 1;  % ms
winPSTH    = LocalGlobalParams.Window; % ms
tPSTH      = (winPSTH(1) + binsize/2 : binstep : winPSTH(2) - binsize/2)';
% Filter
fhp        = 0.1;
flp        = 10;

%% Process data
spkCH = num2cell(cellfun(@(x) x(:, 1), struct2cell(trialsSpike)', "UniformOutput", false), 1);
spkCH = cellfun(@(spkTrial) cellfun(@(x) spkTrial(devOrdr == x), num2cell(unique(devOrdr)), "UniformOutput", false), spkCH, "UniformOutput", false)';
chSpkRes = cell2struct([
                    cellfun(@(x) char(strjoin([date, strrep(x, "CH", "ID")], "_")), string(fieldnames(trialsSpike)), "uni",false), ... % channel number
                    cellfun(@(spkDev) cell2struct([ ... % inner cell2struct
                            cellstr(stimStrs{:}) ... % stimStr
                            spkDev ... % trialSpike
                            cellfun(@(spkTrial, devWins) mean(calFR(spkTrial, devWins)), spkDev, num2cell(winDevResp, 2), "UniformOutput", false) ... % fring rate for winDevResp
                            cellfun(@(spkTrial, baseWins) mean(calFR(spkTrial, baseWins)), spkDev, num2cell(winBaseResp, 2), "UniformOutput", false) ... % fring rate for winBaseResp
                            cellfun(@(spkTrial) mu_calPSTH(spkTrial, winPSTH, binsize, binstep), spkDev, "UniformOutput", false) ... % PSTH
                            cellfun(@(spkTrial, devWins) cellfun(@(spk) sum(spk > devWins(1) & spk < devWins(2)), spkTrial), spkDev, num2cell(winDevResp, 2), "UniformOutput", false) ... % spk count in devWin
                            cellfun(@(spkTrial, stdWins) cellfun(@(spk) sum(spk > stdWins(1) & spk < stdWins(2)), spkTrial), spkDev, num2cell(winBaseResp, 2), "UniformOutput", false) ... % spk count in stdWin
                            ] ... % cell array boundary for inner struct
                      , ["stimStr", "trialSpk", "devFR", "baseFR", "PSTH", "devCount", "baseCount"], 2), ... % end of inner cell2struct
                    spkCH, "UniformOutput", false)] ... % cell array boundary for outer struct
           , ["CH", "spkRes"], 2); % end of outer cell2struct
%                             PSTHFilter(cellfun(@(spkTrial) calPSTH(spkTrial, winPSTH, binsize, binstep)', spkDev, "UniformOutput", false), fhp, flp, 1000/binstep, "hpfilter", "no") ... % Filtered PSTH
%                             cellfun(@(filterPSTH) mfft(filterPSTH, 1000/stepFFT), PSTHFilter(cellfun(@(spkTrial) calPSTH(spkTrial, winPSTH, binsize, binstep)', spkDev, "UniformOutput", false), fhp, flp, 1000/binstep, "hpfilter", "no"), "UniformOutput", false) ... % FFT for Filtered mean PSTH
%                             cellfun(@(spkTrial, bins) mean(mfft(cell2mat(PSTHFilter({cell2mat(cellfun(@(spk) calPSTH({spk}, winFFT, bins, stepFFT)', spkTrial, "UniformOutput", false))}, fhp, flp, 1000/binstep, "hpfilter", "no")), 1000/stepFFT), 1), spkDev, num2cell(fftsize), "UniformOutput", false) ... % mean FFT for each filtered trial
%                       ] ... % cell array boundary for inner struct
%                     , ["stimStr", "devFR", "stdFR", "PSTH", "FFT_MeanPSTH", "AmpFFT_MeanPSTH", "MeanFFT_PSTH", "AmpMeanFFT_PSTH", "devCount", "stdCount", "PSTHFiltered", "FFT_MeanPSTHFiltered", "MeanFFT_PSTHFiltered"], 2), ... % end of inner cell2struct
%                     spkCH, "UniformOutput", false)] ... % cell array boundary for outer struct
%            , ["CH", "spkRes"], 2); % end of outer cell2struct
mkdir(SAVEPATH);

params      = collectVarsInWS(["tPSTH", "stimStrs"]);
save(fullfile(SAVEPATH, "chSpkRes_V1.mat"), "chSpkRes", "params", "winBaseResp", "-v7.3");

end