ccc;
cd(fileparts(mfilename('fullpath')));

tic
% MonkeyName = "Joker";
MonkeyName = "CM";
protStr      = "LocalGlobal_4_4o06_Temp";
spkSelect_Window = [-500, 1200];
baseline_Window = [-200, 0];
ROOTPATH = strcat(getRootDirPath(mfilename("fullpath"), 3), "DATA\MAT DATA\", MonkeyName, "\CTL_New");
temp = dir(fullfile(ROOTPATH, protStr));

%%
date = string({temp(~matches({temp.name}', [".", "..", "processedRes"])).name}');
cellfun(@(x) mProcess_LocalGlobal_MLA(ROOTPATH, protStr, x), date, "uni", false);

toc