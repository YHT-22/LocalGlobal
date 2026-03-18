function [normPSTH, sortedPSTH, latencies, finalOrder, sortedLatencies] = cal_NeuronLatencies_possion(psthMatrix, trialSpk, th, windowBase, windowResp)

% ==========================================================
% Population PSTH Sorting Based on Poisson Latency
%
% INPUT
%   psthMatrix : N × T PSTH matrix (neurons × time)
%   trialSpk   : cell array {N×1}, each cell contains trial spike times
%   th         : Poisson significance threshold (e.g. 1e-6)
%   windowBase : baseline window [start end] (ms)
%   windowResp : response window [start end] (ms)
%
% OUTPUT
%   normPSTH        : sorted normalized PSTH
%   finalOrder      : neuron sorting index
%   sortedLatencies : latency of sorted neurons
%
% Example:
% [normPSTH, order, latency] = ...
%    mu_populationPSTH_latencySort(psthMatrix, trialSpk, tPSTH, ...
%                                  1e-6, [-200 0], [0 300]);
% ==========================================================

numNeurons = size(psthMatrix,1);
latencies = NaN(numNeurons,1);

fprintf('Computing latency for %d neurons...\n', numNeurons);

%% -------- latency detection --------
for i = 1:numNeurons

spikes = cell2mat(trialSpk{i});

if isempty(spikes)
    continue
end

numTrials = size(trialSpk{i},1);

% baseline firing rate
base_spikes = sum(spikes >= windowBase(1) & spikes <= windowBase(2));
base_duration = diff(windowBase)/1000;

sprate_base = base_spikes / (numTrials * base_duration);
sprate_base = max(sprate_base,0.01);

% response spikes
resp_spikes = sort(spikes(spikes >= windowResp(1) & spikes <= windowResp(2)));

if isempty(resp_spikes)
    continue
end

% Poisson detection
n = 1:length(resp_spikes);

t_relative = (resp_spikes - windowResp(1))/1000;

lambda = numTrials * sprate_base .* t_relative;

P = 1 - poisscdf(n' - 1 , lambda + eps);

idx = find(P < th ,1,'first');

if ~isempty(idx)
    latencies(i) = resp_spikes(idx);
end

end

%% -------- neuron sorting --------
responsiveIdx = find(~isnan(latencies));

[sortedLatencies, sOrder] = sort(latencies(responsiveIdx),'ascend');

finalOrder = responsiveIdx(sOrder);

fprintf('Responsive neurons: %d / %d\n', length(finalOrder), numNeurons);

%% -------- PSTH processing --------
sortedPSTH = psthMatrix(finalOrder,:);

% smoothing
sortedPSTH = smoothdata(sortedPSTH,2,'gaussian',5);

% normalization
normFactor = max(sortedPSTH,[],2);
normFactor(normFactor==0) = 1;
normPSTH = sortedPSTH ./ normFactor;


end
