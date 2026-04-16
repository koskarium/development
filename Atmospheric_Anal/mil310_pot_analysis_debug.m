function pot = mil310_pot_analysis_debug(time_table, Td, options)
% ==========================================================
% Peak-Over-Threshold (POT) EVT analysis (dual tail flexible)
% ==========================================================

arguments
    time_table datetime
    Td (:,1) double
    options.threshold_pct (1,1) double = 95
    options.lower_pct (1,1) double = 5
    options.minGap duration = hours(48)
    options.returnPeriods (1,:) double = [10 25 50]
end

pot = struct();
pot.returnPeriods = options.returnPeriods;

time_table = time_table(:);

%% ==========================================================
% ================= UPPER TAIL ==============================
%% ==========================================================

% ----------------------------------------------------------
% THRESHOLD SELECTION (definition of “extreme regime”)
% ----------------------------------------------------------
u_high = prctile(Td, options.threshold_pct);

% ----------------------------------------------------------
% EXCEEDANCES (raw extreme events above threshold)
% ----------------------------------------------------------
idx_high = Td > u_high;
exceed_high = Td(idx_high) - u_high;
time_high = time_table(idx_high);

% ----------------------------------------------------------
% SORTING (required before declustering)
% Ensures time differences are meaningful
% ----------------------------------------------------------
[time_high, s] = sort(time_high);
exceed_high = exceed_high(s);

% ----------------------------------------------------------
% DECLUSTERING (remove dependent events)
% Ensures independence assumption for EVT/GPD validity
% ----------------------------------------------------------
keep = [true; diff(time_high) > options.minGap];
exceed_high = exceed_high(keep);
time_high = time_high(keep);

% ----------------------------------------------------------
% OUTPUT STRUCT INITIALIZATION
% ----------------------------------------------------------
pot.upper.threshold = u_high;
pot.upper.n = numel(exceed_high);

% ----------------------------------------------------------
% EXCEEDANCE RATE (frequency of extreme events per year)
% ----------------------------------------------------------
pot.upper.lambda = pot.upper.n / years(time_table(end) - time_table(1));

% ----------------------------------------------------------
% GPD FIT (core EVT step)
% Models distribution of exceedances
% ----------------------------------------------------------
if pot.upper.n >= 20
    [parem_u, ~] = gpfit(exceed_high);
    
    k = parem_u(1);
    sigma = parem_u(2);

    pot.upper.shape = k;
    pot.upper.scale = sigma;

    % ------------------------------------------------------
    % RETURN LEVELS (engineering risk outputs)
    % Converts GPD → T-year extreme estimates
    % ------------------------------------------------------
    for T = options.returnPeriods
        if abs(k) > 1e-6
            zT = u_high + (sigma/k) * ((pot.upper.lambda*T)^k - 1);
        else
            zT = u_high + sigma * log(pot.upper.lambda*T);
        end
        pot.upper.return_levels.(sprintf("RP%d",T)) = zT;
    end
else
    pot.upper.status = "insufficient_data";
end

%% ==========================================================
% ================= LOWER TAIL ==============================
%% ==========================================================

% ----------------------------------------------------------
% THRESHOLD SELECTION (cold extreme boundary)
% ----------------------------------------------------------
u_low = prctile(Td, options.lower_pct);

% ----------------------------------------------------------
% EXCEEDANCES (lower-tail transformation)
% NOTE: mirror transform for EVT consistency
% ----------------------------------------------------------
idx_low = Td < u_low;
exceed_low = u_low - Td(idx_low);
time_low = time_table(idx_low);

% ----------------------------------------------------------
% SORTING (required before declustering)
% ----------------------------------------------------------
[time_low, s] = sort(time_low);
exceed_low = exceed_low(s);

% ----------------------------------------------------------
% DECLUSTERING (remove temporal dependence)
% ----------------------------------------------------------
keep = [true; diff(time_low) > options.minGap];
exceed_low = exceed_low(keep);
time_low = time_low(keep);

% ----------------------------------------------------------
% OUTPUT STRUCT INITIALIZATION
% ----------------------------------------------------------
pot.lower.threshold = u_low;
pot.lower.n = numel(exceed_low);

% ----------------------------------------------------------
% EXCEEDANCE RATE (cold extreme frequency)
% ----------------------------------------------------------
pot.lower.lambda = pot.lower.n / years(time_table(end) - time_table(1));

% ----------------------------------------------------------
% GPD FIT (cold extreme distribution model)
% ----------------------------------------------------------
if pot.lower.n >= 20
    [parem_l, ~] = gpfit(exceed_low);

    k = parem_l(1);
    sigma = parem_l(2); 

    pot.lower.shape = k;
    pot.lower.scale = sigma;

    % ------------------------------------------------------
    % RETURN LEVELS (cold extreme estimates)
    % ------------------------------------------------------
    for T = options.returnPeriods
        if abs(k) > 1e-6
            zT = u_low - (sigma/k) * ((pot.lower.lambda*T)^k - 1);
        else
            zT = u_low - sigma * log(pot.lower.lambda*T);
        end
        pot.lower.return_levels.(sprintf("RP%d",T)) = zT;
    end
else
    pot.lower.status = "insufficient_data";
end

%% ==========================================================
% FINAL OUTPUT FLAG
% ==========================================================
pot.status = "ok";

end