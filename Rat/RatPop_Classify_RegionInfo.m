% AC
ACIdx = find(rowFcn(@(x) contains(x(1), "AC"), cellclusterInfo));
AC_clusterInfo = cellclusterInfo(ACIdx, :);
[a, b] = sort(double(AC_clusterInfo(:, 2)));
AC_ClassifyPSTHMatrix = cellfun(@(AC_psth) cellfun(@(classIdx) AC_psth(b(a == classIdx), :), ...
                                        num2cell(unique(idx0)), 'UniformOutput', false), ...
                        cellfun(@(x) x(ACIdx, :), psthMatrixTemp, 'uni', false), 'UniformOutput', false);
AC_ClassifyIdx = cellfun(@(classIdx) b(a == classIdx), num2cell(unique(idx0)), 'UniformOutput', false);
a = []; b=[];
% MGB
MGBIdx = find(rowFcn(@(x) contains(x(1), "MGB"), cellclusterInfo));
MGB_clusterInfo = cellclusterInfo(MGBIdx, :);
[a, b] = sort(double(MGB_clusterInfo(:, 2)));
MGB_ClassifyPSTHMatrix = cellfun(@(MGB_psth) cellfun(@(classIdx) MGB_psth(b(a == classIdx), :), ...
                                        num2cell(unique(idx0)), 'UniformOutput', false), ...
                        cellfun(@(x) x(MGBIdx, :), psthMatrixTemp, 'uni', false), 'UniformOutput', false);
MGB_ClassifyIdx = cellfun(@(classIdx) b(a == classIdx), num2cell(unique(idx0)), 'UniformOutput', false);
a = []; b=[];
% IC
ICIdx = find(rowFcn(@(x) contains(x(1), "IC"), cellclusterInfo));
IC_clusterInfo = cellclusterInfo(ICIdx, :);
[a, b] = sort(double(IC_clusterInfo(:, 2)));
IC_ClassifyPSTHMatrix = cellfun(@(IC_psth) cellfun(@(classIdx) IC_psth(b(a == classIdx), :), ...
                                        num2cell(unique(idx0)), 'UniformOutput', false), ...
                        cellfun(@(x) x(ICIdx, :), psthMatrixTemp, 'uni', false), 'UniformOutput', false);
IC_ClassifyIdx = cellfun(@(classIdx) b(a == classIdx), num2cell(unique(idx0)), 'UniformOutput', false);
a = []; b=[];
% CN
CNIdx = find(rowFcn(@(x) contains(x(1), "CN"), cellclusterInfo));
CN_clusterInfo = cellclusterInfo(CNIdx, :);
[a, b] = sort(double(CN_clusterInfo(:, 2)));
CN_ClassifyPSTHMatrix = cellfun(@(CN_psth) cellfun(@(classIdx) CN_psth(b(a == classIdx), :), ...
                                        num2cell(unique(idx0)), 'UniformOutput', false), ...
                        cellfun(@(x) x(CNIdx, :), psthMatrixTemp, 'uni', false), 'UniformOutput', false);
CN_ClassifyIdx = cellfun(@(classIdx) b(a == classIdx), num2cell(unique(idx0)), 'UniformOutput', false);
a = []; b=[];
