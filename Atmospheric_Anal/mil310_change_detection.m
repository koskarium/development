function stats = mil310_change_detection(data, var, options)
% ==========================================================
% MIL-310 style change detection
% Combines:
%   1. KS test (full distribution shift)
%   2. Rank-sum tests at exceedance levels (tail shift)
% ==========================================================

arguments
    data table
    var (1,1) string
    options.window1 (1,2) double
    options.window2 (1,2) double
    options.exceedance_pct (1,:) double = [1 5 10]
    options.alpha (1,1) double = 0.05
end

w1 = options.window1;
w2 = options.window2;

pct = options.exceedance_pct;
pct_vals = 100 - pct;

alpha = options.alpha;

months = 1:12;
numE = length(pct);

% ----------------------------------------------------------
% Output:
% Month | KS_p | KS_sig | p(exceedances...)
% ----------------------------------------------------------
results = cell(12, 3 + numE);

for m = months

    % ----------------------------
    % Extract windows
    % ----------------------------
    x1 = data.(var)(data.month == m & data.year >= w1(1) & data.year <= w1(2));
    x2 = data.(var)(data.month == m & data.year >= w2(1) & data.year <= w2(2));

    x1 = x1(~isnan(x1));
    x2 = x2(~isnan(x2));

    if isempty(x1) || isempty(x2)
        continue
    end

    % ======================================================
    % 1. KS TEST (distribution shift)
    % ======================================================
    [h_ks, p_ks] = kstest2(x1, x2, 'Alpha', alpha);

    % ======================================================
    % 2. Shared thresholds for exceedance levels
    % ======================================================
    pooled = [x1; x2];
    thresholds = prctile(pooled, pct_vals);

    p_tail = NaN(1, numE);

    for k = 1:numE

        t = thresholds(k);

        x1_ex = x1(x1 >= t);
        x2_ex = x2(x2 >= t);

        % Need enough samples for rank-sum
        if numel(x1_ex) >= 5 && numel(x2_ex) >= 5
            p_tail(k) = ranksum(x1_ex, x2_ex);
        end

    end

    % ======================================================
    % Store results
    % ======================================================
    results(m,:) = [{m}, {p_ks}, {h_ks}, num2cell(p_tail)];

end

% ==========================================================
% Column names
% ==========================================================
tail_names = arrayfun(@(x) sprintf('p_%d', x), pct, 'UniformOutput', false);

varNames = [{'Month','KS_p','KS_sig'}, tail_names];

stats = cell2table(results, 'VariableNames', varNames);

fprintf("---- Change detection complete (%d-%d vs %d-%d)\n", ...
    w1(1), w1(2), w2(1), w2(2));

end