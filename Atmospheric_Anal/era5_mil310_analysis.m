% This code is to analyze atmosphere data ala MIL-310-HBK. 
% This code will intake hourly data mined using era5_pipeline.py.
% The city split is done with the previosuly mentioned python scrip that
% uses cities.csv as a reference to what cities to pull the data from. 

% Author: Kevin O. Negron
% Email: kevin.o.negron.civ@us.navy.mil
% Matlab: R2023a Update 5 (9.14.0.2337262)
% Version: 1.0.0
% Initial: 2026.0215
% Latest: 2026.0304

% Notes
% 2026/03/04 Made changes to incorp the data set from ERA5
% 2026/02/15 This initial version uses mil310_generate_sample to run since we do not have the dataset available 

%% ==========================================================
% ERA5 MIL-310 Analysis
% ===========================================================
clear; clc;

% Start parallel pool if needed
if isempty(gcp('nocreate'))
    parpool;
end

%% ==========================================================
% DIRECTORIES
% ==========================================================
dir_base = 'Era5/Cities';
dir_post = 'Era5/Postprocess';

if ~isfolder(dir_base)
    error('--Directory not found: %s', dir_base);
end

if ~isfolder(dir_post)
    mkdir(dir_post);
end

path_post = fullfile(pwd, dir_post);

%% ==========================================================
% CHANGE DETECTION SETTINGS (USER CONTROLLED)
% ==========================================================
latest_year = year(datetime("today"));

window1 = [latest_year-29, latest_year];   % 30-year baseline
window2 = [latest_year-4,  latest_year];   % 5-year recent

exceedance_levels = [1 5 10 90 95 99];

%% ==========================================================
% SCAN FILES
% ==========================================================
file_pattern = fullfile(dir_base, 'ERA_*.csv');
file_list = dir(file_pattern);

file_pointers = table('Size', [length(file_list), 3], ...
    'VariableTypes', {'string', 'double', 'string'}, ...
    'VariableNames', {'City', 'Year', 'FilePath'});

for i = 1:length(file_list)

    fname = file_list(i).name;
    parts = split(extractBefore(fname, ".csv"), "_");

    if numel(parts) >= 3
        file_pointers(i,:) = {
            string(parts{2}), ...
            str2double(parts{3}), ...
            fullfile(file_list(i).folder, fname)
        };
    end
end

unique_cities = unique(file_pointers.City);

%% ==========================================================
% STORAGE
% ==========================================================
results_all = cell(length(unique_cities),1);

%% ==========================================================
% PARALLEL CITY LOOP
% ==========================================================
parfor i = 1:length(unique_cities)

    current_city = unique_cities(i);
    fprintf('Processing %s\n', current_city);

    current_path_dir = fullfile(path_post, current_city);
    if ~exist(current_path_dir, 'dir')
        mkdir(current_path_dir);
    end

    %% --------------------------
    % GET FILES
    % --------------------------
    city_files = file_pointers(file_pointers.City == current_city, :);
    current_temp_data = cell(height(city_files),1);

    for j = 1:height(city_files)
        try
            current_temp_data{j} = readtable(city_files.FilePath(j));
        catch
            current_temp_data{j} = [];
        end
    end

    current_temp_data = current_temp_data(~cellfun(@isempty, current_temp_data));

    if isempty(current_temp_data)
        continue
    end

    current_big_table = vertcat(current_temp_data{:});

    if ~ismember('t2m', current_big_table.Properties.VariableNames)
        continue
    end

    %% ======================================================
    % MIL-310 ANALYSIS
    % ======================================================

    results_annual = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='year', savePlotPath=path_post, ...
        exceedance_pct=exceedance_levels);

    results_1hr = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=exceedance_levels);

    current_big_table.t2m_6 = movmean(current_big_table.t2m,[5 0],"Endpoints","fill");
    results_6hr = mil310stats(current_big_table, 't2m_6', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=exceedance_levels);

    current_big_table.t2m_24 = movmean(current_big_table.t2m,[23 0],"Endpoints","fill");
    results_24hr = mil310stats(current_big_table, 't2m_24', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=exceedance_levels);

    current_big_table.t2m_72 = movmean(current_big_table.t2m,[71 0],"Endpoints","fill");
    results_72hr = mil310stats(current_big_table, 't2m_72', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=exceedance_levels);

    %% ======================================================
    % CHANGE DETECTION (KS + RANK-SUM)
    % ======================================================

    change_1hr = mil310_change_detection(current_big_table, 't2m', ...
        window1=window1, window2=window2, ...
        exceedance_pct=exceedance_levels);

    change_6hr = mil310_change_detection(current_big_table, 't2m_6', ...
        window1=window1, window2=window2, ...
        exceedance_pct=exceedance_levels);

    change_24hr = mil310_change_detection(current_big_table, 't2m_24', ...
        window1=window1, window2=window2, ...
        exceedance_pct=exceedance_levels);

    change_72hr = mil310_change_detection(current_big_table, 't2m_72', ...
        window1=window1, window2=window2, ...
        exceedance_pct=exceedance_levels);

    %% ======================================================
    % SAVE CSV OUTPUTS
    % ======================================================

    writetable(results_annual, fullfile(current_path_dir, sprintf('MIL310_%s_year.csv',current_city)));
    writetable(results_1hr,    fullfile(current_path_dir, sprintf('MIL310_%s_month_1hr.csv',current_city)));
    writetable(results_6hr,    fullfile(current_path_dir, sprintf('MIL310_%s_month_6hr.csv',current_city)));
    writetable(results_24hr,   fullfile(current_path_dir, sprintf('MIL310_%s_month_24hr.csv',current_city)));
    writetable(results_72hr,   fullfile(current_path_dir, sprintf('MIL310_%s_month_72hr.csv',current_city)));

    writetable(change_1hr, fullfile(current_path_dir, sprintf('MIL310_CHANGE_%s_1hr.csv',current_city)));
    writetable(change_6hr, fullfile(current_path_dir, sprintf('MIL310_CHANGE_%s_6hr.csv',current_city)));
    writetable(change_24hr, fullfile(current_path_dir, sprintf('MIL310_CHANGE_%s_24hr.csv',current_city)));
    writetable(change_72hr, fullfile(current_path_dir, sprintf('MIL310_CHANGE_%s_72hr.csv',current_city)));

    %% ======================================================
    % STRUCT STORAGE
    % ======================================================

    city_struct = struct();
    city_struct.city = current_city;   
    city_struct.yearly = results_annual;

    city_struct.monthly_1hr = results_1hr;
    city_struct.monthly_6hr = results_6hr;
    city_struct.monthly_24hr = results_24hr;
    city_struct.monthly_72hr = results_72hr;

    city_struct.change_1hr = change_1hr;
    city_struct.change_6hr = change_6hr;
    city_struct.change_24hr = change_24hr;
    city_struct.change_72hr = change_72hr;

    results_all{i} = city_struct;

end

%% ==========================================================
% SAVE MASTER STRUCT
% ==========================================================
results_all = [results_all{:}];

save(fullfile(path_post,'MIL310_ALL_RESULTS.mat'), ...
    'results_all', '-v7.3');

fprintf('\n--- FULL MIL-310 + CHANGE DETECTION COMPLETE ---\n');