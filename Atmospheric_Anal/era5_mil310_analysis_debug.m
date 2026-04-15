%% ==========================================================
% ERA5 MIL-310 Analysis (Parallel + Struct Output)
% ===========================================================
clear; clc;

if isempty(gcp('nocreate'))
    parpool;
end

dir_base = 'Era5/Cities';
dir_post = 'Era5/Postprocess';

if ~isfolder(dir_base)
    error('--Directory not found: %s', dir_base);
end

if ~isfolder(dir_post)
    mkdir(dir_post)
end

path_post = fullfile(pwd, dir_post);

%% Scan Files
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

% ✅ STORAGE FOR PARFOR
results_all = cell(length(unique_cities),1);

%% ==========================================================
% PARALLEL LOOP
% ===========================================================
parfor i = 1:length(unique_cities)

    current_city = unique_cities(i);
    fprintf('Processing %s\n', current_city);

    current_path_dir = fullfile(path_post, current_city);
    if ~exist(current_path_dir, 'dir')
        mkdir(current_path_dir)
    end

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

    %% =============================
    % ANALYSIS
    % =============================

    % YEARLY
    results_annual = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='year', savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    % MONTHLY 1hr
    results_1hr = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    % 6hr
    current_big_table.t2m_6 = movmean(current_big_table.t2m,[5 0],"Endpoints","fill");
    results_6hr = mil310stats(current_big_table, 't2m_6', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    % 24hr
    current_big_table.t2m_24 = movmean(current_big_table.t2m,[23 0],"Endpoints","fill");
    results_24hr = mil310stats(current_big_table, 't2m_24', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    % 72hr
    current_big_table.t2m_72 = movmean(current_big_table.t2m,[71 0],"Endpoints","fill");
    results_72hr = mil310stats(current_big_table, 't2m_72', current_city, ...
        groupBy='month', savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    %% =============================
    % SAVE CSV (unchanged behavior)
    % =============================
    writetable(results_annual, fullfile(current_path_dir, sprintf('MIL310_summary_%s_year.csv',current_city)));
    writetable(results_1hr,    fullfile(current_path_dir, sprintf('MIL310_summary_%s_month_1hr.csv',current_city)));
    writetable(results_6hr,    fullfile(current_path_dir, sprintf('MIL310_summary_%s_month_6hr.csv',current_city)));
    writetable(results_24hr,   fullfile(current_path_dir, sprintf('MIL310_summary_%s_month_24hr.csv',current_city)));
    writetable(results_72hr,   fullfile(current_path_dir, sprintf('MIL310_summary_%s_month_72hr.csv',current_city)));

    %% =============================
    % STORE STRUCT
    % =============================
    city_struct = struct();
    city_struct.city = current_city;
    city_struct.yearly = results_annual;
    city_struct.monthly_1hr = results_1hr;
    city_struct.monthly_6hr = results_6hr;
    city_struct.monthly_24hr = results_24hr;
    city_struct.monthly_72hr = results_72hr;

    results_all{i} = city_struct;

end

%% ==========================================================
% COMBINE + SAVE
% ===========================================================
results_all = [results_all{:}];

save(fullfile(path_post,'MIL310_all_results.mat'), ...
    'results_all', '-v7.3');

fprintf('\n--- Analysis + Struct Save Complete ---\n');