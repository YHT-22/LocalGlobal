ccc;
cd(fileparts(mfilename('fullpath')));

tic
protStr      = "LocalGlobal_4_5_Temp";

spkSelect_Window = [-500, 1500];
baseline_Window = [-200, 0];
ROOTPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA\Rat\CTL_New");
FigPATH = fullfile(getRootDirPath(mfilename("fullpath"), 4), "Figure\LocalGlobal");
temp = dir(fullfile(ROOTPATH, protStr));

%%
date = string({temp(~matches({temp.name}', [".", "..", "processedRes"])).name}');
cellfun(@(x) RatProcess_LocalGlobal_Temp(ROOTPATH, protStr, x), date, "uni", false);

toc