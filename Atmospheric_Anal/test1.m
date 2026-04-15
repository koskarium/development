%% ==========================================================
% ERA5 MIL-310 Analysis (Parallel by City)
% ===========================================================
clear; clc;

% --------------------------
% Start Parallel Pool
% --------------------------
if isempty(gcp('nocreate'))
    parpool;
end

%% ==========================================================
%  Directories
% ===========================================================
dir_base = 'Era5/Cities';
dir_post = 'Era5/Postprocess';

if ~isfolder(dir_base)
    error('--Directory not found: %s', dir_base);
end

if ~isfolder(dir_post)
    mkdir(dir_post)
end

path_post = fullfile(pwd, dir_post);

%% ==========================================================
%  Scan Files
% ===========================================================
file_pattern = fullfile(dir_base, 'ERA_*.csv');
file_list = dir(file_pattern);

file_pointers = table('Size', [length(file_list), 3], ...
    'VariableTypes', {'string', 'double', 'string'}, ...
    'VariableNames', {'City', 'Year', 'FilePath'});

fprintf('--Scanning directory...\n');

for i = 1:length(file_list)

    fname = file_list(i).name;
    parts = split(extractBefore(fname, ".csv"), "_");

    if numel(parts) >= 3
        file_pointers(i,:) = {
            string(parts{2}), ...
            str2double(parts{3}), ...
            fullfile(file_list(i).folder, fname)
        };
    else
        fprintf('Bad filename: %s\n', fname);
    end
end

disp('--File pointer table ready');

%% ==========================================================
%  Parallel Loop by City
% ===========================================================
fprintf('\n---- Starting Parallel Analysis ----\n');

unique_cities = unique(file_pointers.City);

parfor i = 1:length(unique_cities)

    current_city = unique_cities(i);
    fprintf('------ Processing %s\n', current_city);

    % --------------------------
    % Setup output directory
    % --------------------------
    current_path_dir = fullfile(path_post, current_city);

    if ~exist(current_path_dir, 'dir')
        mkdir(current_path_dir)
    end

    % --------------------------
    % Get files for this city
    % --------------------------
    city_files = file_pointers(file_pointers.City == current_city, :);

    % Preallocate
    current_temp_data = cell(height(city_files),1);

    % --------------------------
    % Load all years (SERIAL)
    % --------------------------
    for j = 1:height(city_files)

        try
            current_temp_data{j} = readtable(city_files.FilePath(j));
        catch ME
            fprintf('Error loading %s\n', city_files.FilePath(j));
            fprintf('%s\n', ME.message);
            current_temp_data{j} = [];
        end
    end

    % Remove empty
    current_temp_data = current_temp_data(~cellfun(@isempty, current_temp_data));

    if isempty(current_temp_data)
        fprintf('No data for %s\n', current_city);
        continue
    end

    % Combine
    current_big_table = vertcat(current_temp_data{:});

    % Validate column
    if ~ismember('t2m', current_big_table.Properties.VariableNames)
        fprintf('Missing t2m in %s\n', current_city);
        continue
    end

    %% ======================================================
    %  Kernel Density (Full Dataset)
    % =======================================================
    [k1,xk1] = ksdensity(current_big_table.t2m);

    f1 = figure('Visible','off');
    plot(xk1,k1);
    title(sprintf('t2m for %s', current_city));
    xlabel('t2m (K)');

    saveas(f1, fullfile(current_path_dir,'kernel_density_full.png'));
    close(f1);

    %% ======================================================
    %  YEARLY ANALYSIS
    % =======================================================
    results_annual = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='year', ...
        savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    writetable(results_annual, ...
        fullfile(current_path_dir, sprintf('MIL310_summary_%s_year.csv', current_city)));

    %% ======================================================
    %  MONTHLY (1hr)
    % =======================================================
    results_monthly = mil310stats(current_big_table, 't2m', current_city, ...
        groupBy='month', ...
        savePlotPath=path_post, ...
        exceedance_pct=[1,5,10,90,95,99]);

    writetable(results_monthly, ...
        fullfile(current_path_dir, sprintf('MIL310_summary_%s_month_1hr.csv', current_city)));

    %% ======================================================
    %  MOVING AVERAGES
    % =======================================================
    windows = [6, 24, 72];

    for w = windows

        var_name = sprintf('t2m_%d', w);

        current_big_table.(var_name) = movmean( ...
            current_big_table.t2m, ...
            [w-1 0], ...
            "Endpoints","fill" ...
        );

        results = mil310stats(current_big_table, var_name, current_city, ...
            groupBy='month', ...
            savePlotPath=path_post, ...
            exceedance_pct=[1,5,10,90,95,99]);

        writetable(results, ...
            fullfile(current_path_dir, ...
            sprintf('MIL310_summary_%s_month_%dhr.csv', current_city, w)));
    end

end

fprintf('\n--- Analysis Complete ---\n');