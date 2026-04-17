function pot = mil310_pot_analysis(time_table, Td, options)
% ==========================================================
% Peak-Over-Threshold (POT) EVT analysis (dual-tail MIL-310)
%
% FEATURES:
%   - Upper tail (hot/extreme high values)
%   - Lower tail (cold/extreme low values)
%   - Declustering (temporal independence)
%   - GPD fitting (EVT core model)
%   - Return level estimation
% ==========================================================

arguments
    time_table datetime
    Td (:,1) double
    options.threshold_pct (1,1) double = 95
    options.lower_pct (1,1) double = 5
    options.minGap duration = hours(48)
    options.returnPeriods (1,:) double = [10 25 50]
end

% ==========================================================
% INITIALIZATION
% ==========================================================
pot = struct();
pot.returnPeriods = options.returnPeriods;

time_table = time_table(:);

% Clean data
valid = ~isnan(Td) & ~isnat(time_table);
Td = Td(valid);
time_table = time_table(valid);

if numel(Td) < 50
    pot.status = "insufficient_data";
    return;
end

% Compute analysis duration in YEARS
nyears = days(time_table(end) - time_table(1)) / 365.25;

% ==========================================================
% ===================== UPPER TAIL =========================
% ==========================================================

% -------------------------
% THRESHOLD SELECTION
% -------------------------
u_high = prctile(Td, options.threshold_pct);

% -------------------------
% EXCEEDANCES (raw extremes)
% -------------------------
idx_high = Td > u_high;
exceed_high = Td(idx_high) - u_high;
time_high = time_table(idx_high);

% -------------------------
% SORT (required for time gaps)
% -------------------------
[time_high, s] = sort(time_high);
exceed_high = exceed_high(s);

% -------------------------
% DECLUSTERING (remove dependence)
% -------------------------
keep = [true; diff(time_high) > options.minGap];
exceed_high = exceed_high(keep);
time_high = time_high(keep);

% -------------------------
% OUTPUT STATS
% -------------------------
pot.upper.threshold = u_high;
pot.upper.thresholdpercent = options.threshold_pct;
pot.upper.n = numel(exceed_high);
pot.upper.lambda = pot.upper.n / nyears;

% -------------------------
% GPD FIT
% -------------------------
if pot.upper.n >= 20

    [parem_u, ~] = gpfit(exceed_high);


    k = parem_u(1);
    sigma = parem_u(2);

    pot.upper.shape = k;
    pot.upper.scale = sigma;

    % -------------------------
    % RETURN LEVELS
    % -------------------------
    pot.upper.return_levels = struct();

    for T = options.returnPeriods
        if abs(k) > 1e-6
            zT = u_high + (sigma/k) * ((pot.upper.lambda*T).^k - 1);
        else
            zT = u_high + sigma * log(pot.upper.lambda*T);
        end
        pot.upper.return_levels.(sprintf("RP%d",T)) = zT;
    end
else
    pot.upper.status = "insufficient_data";
end
% ==========================================================
% ===================== LOWER TAIL =========================
% ==========================================================

% -------------------------
% THRESHOLD SELECTION
% -------------------------
u_low = prctile(Td, options.lower_pct);

% -------------------------
% EXCEEDANCES (reflected EVT)
% -------------------------
idx_low = Td < u_low;
exceed_low = u_low - Td(idx_low);
time_low = time_table(idx_low);

% -------------------------
% SORT
% -------------------------
[time_low, s] = sort(time_low);
exceed_low = exceed_low(s);

% -------------------------
% DECLUSTERING
% -------------------------
keep = [true; diff(time_low) > options.minGap];
exceed_low = exceed_low(keep);
time_low = time_low(keep);

% -------------------------
% OUTPUT STATS
% -------------------------
pot.lower.threshold = u_low;
pot.lower.thresholdpercent = options.lower_pct;
pot.lower.n = numel(exceed_low);
pot.lower.lambda = pot.lower.n / nyears;

% -------------------------
% GPD FIT
% -------------------------
if pot.lower.n >= 20

    [parem_l, ~] = gpfit(exceed_low);

    k = parem_l(1);
    sigma = parem_l(2);

    pot.lower.shape = k;
    pot.lower.scale = sigma;

    % -------------------------
    % RETURN LEVELS (reversed sign)
    % -------------------------
    pot.lower.return_levels = struct();

    for T = options.returnPeriods
        if abs(k) > 1e-6
            zT = u_low - (sigma/k) * ((pot.lower.lambda*T).^k - 1);
        else
            zT = u_low - sigma * log(pot.lower.lambda*T);
        end
        pot.lower.return_levels.(sprintf("RP%d",T)) = zT;
    end
else
    pot.lower.status = "insufficient_data";
end

% ==========================================================
% FINAL STATUS
% ==========================================================
pot.status = "ok";

end