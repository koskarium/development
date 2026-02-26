%% ================= MIL-HDBK-310 with Month Tracking =================
% Using synthetic T_data table (columns: Year, Month, Day, Hour, Temperature_C)

% Define percent exceedances
exceedance_pct = [1, 5, 10];
percentile_values = 100 - exceedance_pct;   % MATLAB percentile

% Unique years
years_list = unique(T_data.Year);

% Prepare results table with month columns
results = table('Size',[0 8],...
    'VariableTypes', {'string','double','double','double','double','double','double','double'},...
    'VariableNames', {'City','Year','MIL1','MIL5','MIL10','Month1','Month5','Month10'});

city_name = "SyntheticCity";

for y = 1:length(years_list)
    yr = years_list(y);
    
    months_list = 1:12;
    MIL_monthly = zeros(length(months_list), 3);  % 3 percentiles
    
    for m = months_list
        idx = T_data.Year==yr & T_data.Month==m;
        temps = T_data.Temperature_C(idx);
        if ~isempty(temps)
            MIL_monthly(m,:) = prctile(temps, percentile_values);
        else
            MIL_monthly(m,:) = NaN;
        end
    end
    
    % Annual MIL = max per percentile across months
    [MIL_annual, month_idx] = max(MIL_monthly,[],1,'omitnan');
    
    % Append to results table
    results = [results; {city_name, yr, MIL_annual(1), MIL_annual(2), MIL_annual(3), ...
                         month_idx(1), month_idx(2), month_idx(3)}];
    
    fprintf('Year %d:\n', yr);
    fprintf('  MIL1%%=%.2f°C (Month %d)\n', MIL_annual(1), month_idx(1));
    fprintf('  MIL5%%=%.2f°C (Month %d)\n', MIL_annual(2), month_idx(2));
    fprintf('  MIL10%%=%.2f°C (Month %d)\n', MIL_annual(3), month_idx(3));
end

%% Optional: save to CSV
output_file = 'MIL310_summary_synthetic_with_month.csv';
writetable(results, output_file);
fprintf('MIL-HDBK-310 summary saved to %s\n', output_file);