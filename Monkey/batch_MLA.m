ccc;
cd(fileparts(mfilename('fullpath')));

tic
% MonkeyName = "Joker";
MonkeyName = "CM";
protStr      = "LocalGlobal_4_4o06_Temp";

% MonkeyName = "CC";
% protStr      = "LocalGlobal_3_3o75_TempSpec";
spkSelect_Window = [-500, 1200];
baseline_Window = [-200, 0];
SoundROOTPATH = "G:\MATLAB Code\LocalGlobal\Sounds";
ROOTPATH = strcat(getRootDirPath(mfilename("fullpath"), 4), "DATA\MAT DATA\", MonkeyName, "\CTL_New");
temp = dir(fullfile(ROOTPATH, protStr));

%%
date = string({temp(~matches({temp.name}', [".", "..", "processedRes"])).name}');
switch protStr
    case "LocalGlobal_4_4o06_Temp"
        cellfun(@(x) mProcess_LocalGlobal_Temp(ROOTPATH, protStr, x), date, "uni", false);
    case "LocalGlobal_3_3o75_TempSpec"
        cellfun(@(x) mProcess_LocalGlobal_TempSpec(ROOTPATH, protStr, x), date, "uni", false);
end

toc