ccc;
cd(fileparts(mfilename('fullpath')));

tic
spkSelect_Window = [-500, 1200];
baseline_Window = [-200, 0];
% ROOTPATH = 'E:\Lab members\YHT\DATA\MAT DATA\TDT\CTL_New';
ROOTPATH = strcat(getRootDirPath(mfilename("fullpath"), 3), "DATA\MAT DATA\TDT\CTL_New");
SoundROOTPATH = "E:\Lab members\YHT\MATLABCode\LocalGlobal\Sounds";
temp = dir(fullfile(ROOTPATH, "LocalGlobal_3_3o75_TempSpec"));

%%
date = string({temp(~matches({temp.name}', [".", "..", "processedRes"])).name}');
protStr      = ["LocalGlobal_3_3o75_TempSpec"];
cellfun(@(x) mProcess_LocalGlobal_MouseRHD(ROOTPATH, protStr, x), date, "uni", false);

toc