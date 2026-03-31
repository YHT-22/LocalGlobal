function FWHM_matrix = cal_NeuronalWidthUnified(data, baseline_window, k)
% 统一计算兴奋型和抑制型神经元响应宽度
%
% data: neurons × time × stimuli
% baseline_window: [start_idx, end_idx]
% k: 阈值倍数（默认2）

if nargin < 3
    k = 2;
end

[nNeurons, nTime, nStimuli] = size(data);
FWHM_matrix = NaN(nNeurons, nStimuli);
t = 1:nTime;

for neuron = 1:nNeurons
    for stim = 1:nStimuli
        response = squeeze(data(neuron, :, stim));
        
        % 基线均值和标准差
        baseline = mean(response(baseline_window(1):baseline_window(2)));
        baseline_std = std(response(baseline_window(1):baseline_window(2)));
        threshold = baseline + k*baseline_std;
        
        r_max = max(response);
        r_min = min(response);
        
        % 判定响应类型
        peak_diff = r_max - baseline;
        trough_diff = baseline - r_min;
        
        if max(peak_diff, trough_diff) < k*baseline_std
            % 无显著响应
            FWHM_matrix(neuron, stim) = NaN;
            continue;
        end
        
        if peak_diff >= trough_diff
            % 兴奋型
            extreme = r_max;
        else
            % 抑制型
            extreme = r_min;
        end
        
        % 半峰/半谷值相对基线
        half_val = baseline + 0.5*(extreme - baseline);
        
        if peak_diff >= trough_diff
            % 兴奋型：上升沿到半峰
            peak_idx = find(response == r_max, 1);
            rise_idx = find(response(1:peak_idx) >= half_val, 1, 'first');
            fall_idx = find(response(peak_idx:end) <= half_val, 1, 'first') + peak_idx - 1;
        else
            % 抑制型：下降沿到半谷
            trough_idx = find(response == r_min, 1);
            rise_idx = find(response(1:trough_idx) <= half_val, 1, 'first');
            fall_idx = find(response(trough_idx:end) >= half_val, 1, 'first') + trough_idx - 1;
        end
        
        FWHM_matrix(neuron, stim) = t(fall_idx) - t(rise_idx);
    end
end
end