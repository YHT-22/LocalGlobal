cd(fileparts(mfilename('fullpath')));

protStr      = evalin('base', 'protStr');
MatName = evalin('base', 'MatName');
switch DataSetName
    case "RawPop"
    % load data
    % ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA\Rat\TDT\CTL_New\", protStr);
    % searchPattern = fullfile(ROOTPATH, '**', MatName);
    % fileList = dir(searchPattern);
    % tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    % chResAll = vertcat(tmp.chSpkRes);
    % tPSTH = tmp(1).params.tPSTH;

    case "ProcessPop1"
    % load process data
    ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 3), "Figure\LocalGlobal", protStr);
    searchPattern = fullfile(ROOTPATH, '**', 'res.mat');
    fileList = dir(searchPattern);
    tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    tPSTH = tmp.tPSTH;

end



