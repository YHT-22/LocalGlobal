function [latencies, sortedLatencies, finalOrder, normPSTH] = cal_NeuronLatencies_continueBins(psthMatrix, baselineWindow, responseWindow, tPSTH, zThresh, minBins)
%
% 输入:
%   psthMatrix     - [numNeurons x timeBins] PSTH矩阵
%   baselineWindow - 基线时间窗口 [start end]
%   responseWindow - 响应时间窗口 [start end]
%   tPSTH          - 时间向量，对应psthMatrix的列
%   zThresh        - Z-score阈值 (可选, 默认 2)
%   minBins        - 连续bins数目 (可选, 默认 3)
%
% 输出:
%   latencies         - 所有神经元的延迟 (NaN表示不响应)
%   sortedLatencies   - 响应神经元延迟按升序排列
%   finalOrder        - 响应神经元排序索引
%   normPSTH          - 排序后归一化的PSTH矩阵

if nargin < 5 || isempty(zThresh)
    zThresh = 2;
end

if nargin < 6 || isempty(minBins)
    minBins = 3;
end

numNeurons = size(psthMatrix,1);
latencies = NaN(numNeurons,1);

baseIdx = find(tPSTH >= baselineWindow(1) & tPSTH <= baselineWindow(2));
respIdx = find(tPSTH >= responseWindow(1) & tPSTH <= responseWindow(2));

%% 计算每个神经元的 latency
for i = 1:numNeurons
    psth = psthMatrix(i,:);
    baseMean = mean(psth(baseIdx));
    baseStd = std(psth(baseIdx));

    if baseStd == 0
        baseStd = 0.001;
    end
    
    % Z-score
    zPSTH = (psth - baseMean) / baseStd;
    zResp = zPSTH(respIdx);
    above = zResp > zThresh;
    
    % 检测连续 bin
    for t = 1:length(above)-minBins+1
        if all(above(t:t+minBins-1))
            latencies(i) = tPSTH(respIdx(t));
            break
        end
    end
end

%% 排序
responsiveIdx = find(~isnan(latencies));
[sortedLatencies, sOrder] = sort(latencies(responsiveIdx),'ascend');
finalOrder = responsiveIdx(sOrder);

%% PSTH排序与归一化
psth_sorted = psthMatrix(finalOrder,:);
normFactor = max(psth_sorted,[],2);
normFactor(normFactor==0) = 1;
normPSTH = psth_sorted ./ normFactor;

end
