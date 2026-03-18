function [max_value, max_location] = find_max_with_smoothing(x, y, window_start, window_end, smooth_method, smooth_param)
% 平滑后找窗口内的最大值
% 输入：
%   x, y - 曲线数据点
%   window_start, window_end - 窗口边界
%   smooth_method - 平滑方法：'moving', 'gaussian', 'sgolay', 'lowess'等
%   smooth_param - 平滑参数（窗口大小或平滑因子）
% 输出：
%   max_value - 平滑后的最大值
%   max_location - 最大值对应的x坐标

    % 设置默认值
    if nargin < 5
        smooth_method = 'gaussian';  % 默认滑动平均
    end
    if nargin < 6
        smooth_param = 5;  % 默认窗口大小
    end
    
    % 找到窗口内的数据索引
    window_indices = find(x >= window_start & x <= window_end);
    
    if isempty(window_indices)
        max_value = [];
        max_location = [];
        warning('指定窗口内没有数据点');
        return;
    end
    
    % 提取窗口内的数据
    x_window = x(window_indices);
    y_window = y(window_indices);
    
    % 平滑处理
    if exist('smoothdata', 'file')  % 优先使用smoothdata（内置于MATLAB）
        y_smoothed = smoothdata(y_window, smooth_method, smooth_param);
    elseif exist('smooth', 'file')   % 如果有Curve Fitting Toolbox
        y_smoothed = smooth(y_window, smooth_param, smooth_method);
    else
        % 如果都没有，使用简单的滑动平均
        warning('未找到平滑函数，使用简单滑动平均');
        y_smoothed = movmean(y_window, smooth_param);
    end
    
    % 在平滑后的数据上找最大值
    [max_value, idx] = max(y_smoothed);
    max_location = x_window(idx);
    
    % % 可视化对比
    % figure('Position', [100, 100, 1200, 500]);
    % 
    % % 子图1：原始数据和平滑数据对比
    % subplot(1, 2, 1);
    % plot(x_window, y_window, 'b.-', 'LineWidth', 1, 'MarkerSize', 8, 'DisplayName', '原始数据');
    % hold on;
    % plot(x_window, y_smoothed, 'r-', 'LineWidth', 2, 'DisplayName', ['平滑数据 (', smooth_method, ')']);
    % plot(max_location, max_value, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', '最大值');
    % plot([window_start window_start], ylim, 'k--', 'LineWidth', 1, 'DisplayName', '窗口边界');
    % plot([window_end window_end], ylim, 'k--', 'LineWidth', 1);
    % hold off;
    % xlabel('x');
    % ylabel('y');
    % title('窗口内数据平滑及最大值');
    % legend('Location', 'best');
    % grid on;
    % 
    % % 子图2：整体曲线视图
    % subplot(1, 2, 2);
    % plot(x, y, 'b-', 'LineWidth', 1, 'DisplayName', '完整曲线');
    % hold on;
    % plot(x_window, y_window, 'g-', 'LineWidth', 2, 'DisplayName', '窗口内数据');
    % plot(max_location, max_value, 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', '检测到的最大值');
    % plot([window_start window_start], ylim, 'k--', 'LineWidth', 1);
    % plot([window_end window_end], ylim, 'k--', 'LineWidth', 1);
    % hold off;
    % xlabel('x');
    % ylabel('y');
    % title('整体视图');
    % legend('Location', 'best');
    % grid on;
    
    % 显示结果
    fprintf('窗口 [%.2f, %.2f] 内的最大值（平滑后）：\n', window_start, window_end);
    fprintf('平滑方法: %s, 参数: %d\n', smooth_method, smooth_param);
    fprintf('位置: x = %.4f, 最大值: y = %.4f\n', max_location, max_value);
    fprintf('原始数据在该位置的值: y = %.4f\n', y_window(idx));
end