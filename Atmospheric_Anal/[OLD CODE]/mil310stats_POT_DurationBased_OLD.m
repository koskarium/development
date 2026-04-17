%% =================== Reconstruct Time Vector from T_data =================
time_table = datetime(T_data.Year, T_data.Month, T_data.Day, T_data.Hour, 0, 0);
T_vec = T_data.Temperature_C;   % temperature vector

%% =================== Duration-Based Series =================
durations = [1 6 24 72];   % in hours
Tdur = struct();

for d = durations
    Tdur.(sprintf('h%d',d)) = movmean(T_vec,d,'Endpoints','discard');
end

%% =================== Peak-Over-Threshold (POT) =================
returnPeriods = [10 25 50];   % in years
results = struct();

for d = durations
    Td = Tdur.(sprintf('h%d',d));
    
    % Adjust time to match length of moving mean
    timeDur = time_table(1:length(Td));
    
    % Choose threshold = 95th percentile
    u = prctile(Td,95);
    
    % Exceedances
    exceed = Td(Td > u) - u;
    
    % Corresponding times
    exceedTimes = timeDur(Td > u);
    
    %% Decluster exceedances (48-hour minimum gap)
    minGap = hours(48);
    independentIdx = [true; diff(exceedTimes) > minGap];
    exceedDeclustered = exceed(independentIdx);
    
    %% Fit Generalized Pareto Distribution
    [paramEsts, ~] = gpfit(exceedDeclustered);
    k = paramEsts(1);      % shape
    sigma = paramEsts(2);  % scale
    
    %% Compute exceedance rate per year
    nyears = years(time_table(end) - time_table(1));
    lambda = length(exceedDeclustered) / nyears;
    
    %% Compute return levels
    results.(sprintf('h%d',d)) = struct();
    for Treturn = returnPeriods
        zT = u + (sigma/k) * ((lambda*Treturn)^k - 1);
        results.(sprintf('h%d',d)).(sprintf('RP%d',Treturn)) = zT;
    end
end

%% =================== Display Results =================
fprintf('\nDuration-Based POT Return Levels (°C)\n');
fprintf('--------------------------------------\n');

for d = durations
    fprintf('\nDuration: %dh\n', d);
    for Treturn = returnPeriods
        z = results.(sprintf('h%d',d)).(sprintf('RP%d',Treturn));
        fprintf('Return Period: %d years -> %.2f°C\n', Treturn, z);
    end
end