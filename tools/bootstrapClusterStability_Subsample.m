function [Pco, clusterStability, neuronReliability, results] = ...
    bootstrapClusterStability_Subsample(reduced, idx0, k, initReplication, bootNum, subFrac)
% 按神经元重采样（subsampling）评估聚类稳定性
%
% 输入：
%   reduced   - [N x d] PCA降维后的特征矩阵
%   idx0      - [N x 1] 原始聚类标签（基于全体神经元得到）
%   k         - 聚类数
%   B         - 重采样次数，例如 200
%   subFrac   - 每次抽样比例，例如 0.8
%
% 输出：
%   Pco               - [N x N] 共聚类概率矩阵
%   clusterStability  - [k x 1] 每个cluster的稳定性
%   neuronReliability - [N x 1] 每个神经元的可靠性
%   results           - 结构体，保存中间结果
%
% 示例：
%   [Pco, clusterStability, neuronReliability, results] = ...
%       bootstrapClusterStability_Subsample(reduced, idx0, 4, 200, 0.8);

    rng(1);  % 固定随机种子，保证可复现

    N = size(reduced, 1);
    m = round(subFrac * N);

    coMat = zeros(N, N);      % 两个神经元被分到同一类的次数
    countMat = zeros(N, N);   % 两个神经元共同被抽中的次数

    % 保存每次重采样结果（可选）
    sampleIdx_all = cell(bootNum,1);
    idx_boot_all  = cell(bootNum,1);

    for b = 1:bootNum
        %--------------------------------------------------------------
        % 1) 随机抽取一部分神经元（不放回）
        %--------------------------------------------------------------
        sampleIdx = sort(randperm(N, m));
        Xb = reduced(sampleIdx, :);

        %--------------------------------------------------------------
        % 2) 在子样本上重新聚类
        %--------------------------------------------------------------
        idx_b = kmeans(Xb, k, ...
            'Replicates', initReplication, ...
            'MaxIter', 1000, ...
            'Display', 'off');

        sampleIdx_all{b} = sampleIdx;
        idx_boot_all{b}  = idx_b;

        %--------------------------------------------------------------
        % 3) 统计共同出现 + 同类次数
        %--------------------------------------------------------------
        for ii = 1:m
            i = sampleIdx(ii);

            % 自己和自己
            countMat(i,i) = countMat(i,i) + 1;
            coMat(i,i)    = coMat(i,i) + 1;

            for jj = ii+1:m
                j = sampleIdx(jj);

                % 共同出现一次
                countMat(i,j) = countMat(i,j) + 1;
                countMat(j,i) = countMat(j,i) + 1;

                % 若本轮被分到同一类，则同类次数 +1
                if idx_b(ii) == idx_b(jj)
                    coMat(i,j) = coMat(i,j) + 1;
                    coMat(j,i) = coMat(j,i) + 1;
                end
            end
        end
    end

    %--------------------------------------------------------------
    % 4) 计算共聚类概率矩阵
    %--------------------------------------------------------------
    Pco = coMat ./ max(countMat, 1);

    % 对角线设为1
    for i = 1:N
        Pco(i,i) = 1;
    end

    %--------------------------------------------------------------
    % 5) 每个cluster的稳定性
    %    定义：该cluster内两两神经元的平均共聚类概率
    %--------------------------------------------------------------
    clusterStability = nan(k,1);

    for c = 1:k
        members = find(idx0 == c);

        if numel(members) <= 1
            clusterStability(c) = NaN;
            continue;
        end

        subMat = Pco(members, members);
        mask = ~eye(numel(members));   % 去掉对角线
        vals = subMat(mask);

        clusterStability(c) = mean(vals, 'omitnan');
    end

    %--------------------------------------------------------------
    % 6) 每个神经元的可靠性
    %    定义：该神经元与"原始同类神经元"的平均共聚类概率
    %--------------------------------------------------------------
    neuronReliability = nan(N,1);

    for i = 1:N
        sameMembers = find(idx0 == idx0(i));
        sameMembers(sameMembers == i) = [];

        if isempty(sameMembers)
            neuronReliability(i) = NaN;
        else
            neuronReliability(i) = mean(Pco(i, sameMembers), 'omitnan');
        end
    end

    %--------------------------------------------------------------
    % 7) 打包输出
    %--------------------------------------------------------------
    results = struct();
    results.coMat = coMat;
    results.countMat = countMat;
    results.sampleIdx_all = sampleIdx_all;
    results.idx_boot_all = idx_boot_all;
    results.B = bootNum;
    results.subFrac = subFrac;
end
