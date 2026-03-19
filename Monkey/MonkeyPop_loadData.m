cd(fileparts(mfilename('fullpath')));

protStr      = evalin('base', 'protStr');
MonkeyName = evalin('base', 'MonkeyName');
MatName = evalin('base', 'MatName');
switch DataSetName
    case "RawPop"
    % load data
    ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA", MonkeyName, "\CTL_New\", protStr, "processedRes");
    searchPattern = fullfile(ROOTPATH, '**', MatName);
    fileList = dir(searchPattern);
    tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    chResAll = vertcat(tmp.chSpkRes);
    tPSTH = tmp(1).params.tPSTH;

    case "ProcessPop1"
    % load process data
    % ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 3), "Figure\LocalGlobal", protStr, "Mice");
    % searchPattern = fullfile(ROOTPATH, '**', 'PopData_SelectByPossion.mat');
    % fileList = dir(searchPattern);
    % tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    % tPSTH = tmp.tPSTH;

end



