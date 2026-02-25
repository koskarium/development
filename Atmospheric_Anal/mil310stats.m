%% mil310_calc.m
% Calculate MIL-HDBK-310 exceedance values (1%,5%,10%) for ERA5 cities

%% Set up folders relative to script
script_folder = fileparts(mfilename('fullpath'));  % folder where script resides
cities_folder = fullfile(script_folder, 'Era5', 'Cities'); % folder with CSVs

output_file = fullfile(script_folder, 'Era5', 'MIL310_summary.csv');

%% Find all CSV files
csv_files = dir(fullfile(cities_folder, 'ERA_*.csv'));
if isempty(csv_files)
    error('No CSV files found in %s', cities_folder);
end

%% Define percentiles for MIL-HDBK-310
exceedance_pct = [1, 5, 10];  % percent exceedance
percentile_values = 100 - exceedance_pct;  % convert to MATLAB percentile (below)

%% Prepare results table
results = table('Size',[0 5],...
                'VariableTypes', {'string','double','double','double','double'},...
                'VariableNames', {'City','Year','MIL1','MIL5','MIL10'});

%% Loop through files
for k = 1:length(csv_files)
    csv_name = csv_files(k).name;
    csv_path = fullfile(csv_files(k).folder, csv_name);
    
    % Extract city and year from filename
    % Expected format: ERA_<CityName>_<Year>.csv
    tokens = split(csv_name, {'_','.'});
    city = string(tokens{2});
    year_val = str2double(tokens{3});
    
    % Load data
    data = readtable(csv_path);
    
    % Ensure temperature column exists
    if ~ismember('t2m', data.Properties.VariableNames)
        error('CSV %s missing column "t2m"', csv_name);
    end
    
    temps = data.t2m;  % in K
    
    % Calculate MIL for each exceedance
    MIL_values = prctile(temps, percentile_values);
    
    % Append to results
    results = [results; {city, year_val, MIL_values(1), MIL_values(2), MIL_values(3)}];
    
    fprintf('Processed %s: MIL 1%%=%.2f K, 5%%=%.2f K, 10%%=%.2f K\n',...
            city, MIL_values(1), MIL_values(2), MIL_values(3));
end

%% Save results
writetable(results, output_file);
fprintf('MIL-HDBK-310 summary saved to %s\n', output_file);