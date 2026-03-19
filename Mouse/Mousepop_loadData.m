cd(fileparts(mfilename('fullpath')));

switch DataSetName
    case "RawPop"
    % load data
    protStr      = "LocalGlobal_3_3o75_TempSpec";
    ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA\TDT\CTL_New\", protStr, "processedRes");
    searchPattern = fullfile(ROOTPATH, '**', 'chSpkRes_V1.mat');
    fileList = dir(searchPattern);
    tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    chResAll = vertcat(tmp.chSpkRes);
    tPSTH = tmp(1).params.tPSTH;

    case "ProcessPop1"
    % load process data
    protStr      = "LocalGlobal_3_3o75_TempSpec";
    ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 3), "Figure\LocalGlobal", protStr, "Mice");
    searchPattern = fullfile(ROOTPATH, '**', 'PopData_SelectByPossion.mat');
    fileList = dir(searchPattern);
    tmp = arrayfun(@(f) load(fullfile(f.folder,f.name)), fileList);
    tPSTH = tmp.tPSTH;

end



