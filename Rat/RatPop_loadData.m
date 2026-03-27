cd(fileparts(mfilename('fullpath')));

protStr      = evalin('base', 'protStr');
MatName = evalin('base', 'MatName');
switch DataSetName
    case "RawPop"
    % load data
    ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA\Rat\CTL_New\", protStr, "processedRes");
    searchPattern = fullfile(ROOTPATH, '**', MatName);
    fileList = dir(searchPattern);
    tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    chResAll = vertcat(tmp.chSpkRes);
    tPSTH = tmp(1).params.tPSTH;

    case "ProcessPop1"
    % load process data
    % ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal", protStr, "Rat");
    % searchPattern = fullfile(ROOTPATH, '**', 'res.mat');
    % fileList = dir(searchPattern);
    % tmp = arrayfun(@(f) load(fullfile(f.folder,f.name), "chSpikeLfp"), fileList);
    % tPSTH = tmp(1).chSpikeLfp(1).chSPK(1).PSTH(:, 1);

end



