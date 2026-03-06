% This code is to analyze atmosphere data ala MIL-310-HBK.
%   results = mil310stats(data, var, city, options)
%
%   Inputs:
%       data - A table containing columns: Year, Month, Var1, Var2
%       var     - A string specifying the column name to analyze (e.g., "t2m").
%       city    - A string with the name of the city for the results table.
%       options - (Optional) A struct with fields: .groupBy, .exceedance_pct
%           groupBy - A string, either 'month' (default) or 'year', to specify the analysis method.
%           exceedance_pct  - An array of exceedance percentages (e.g., [1, 5, 10]).
%           save_dir        - The directory where plots will be saved, if selected
%
%   Outputs:
%       results - A table summarizing the exceedance_pct e.g. 1%, 5%, and 10% exceedance
%                 temperatures and the month they occurred in for each year.


% Notes
% 2026/02/15 The initial version


function results = mil310stats(data,var,city, options)
%% ==========================================================
%  Initialize and Input Validation
%  ==========================================================

% Default if there is no grouping or the 'month' is wrong
arguments
    data table
    var (1,1) string
    city (1,1) string
    options.groupBy (1,1) string {mustBeMember(options.groupBy, {'year', 'month'})} = 'month'
    options.exceedance_pct (1,:) double {mustBeNumeric, mustBePositive} = [1, 5, 10]
    options.savePlotPath (1,1) string = "" % Default is an empty string (plots OFF)
end

% Define percent exceedances
groupBy = options.groupBy;
exceedance_pct = options.exceedance_pct;
savePlotPath = options.savePlotPath;
percentile_values = 100 - exceedance_pct;
num_pct = length(exceedance_pct); % Number of percentiles to calculate

city_name = string(city);

% Unique years
years_list = unique(data.year);
num_years = length(years_list);

% Find column names ignoring case
var_names = data.Properties.VariableNames;
year_col = var_names{lower(var_names) == "year"};
month_col = var_names{lower(var_names) == "month"};

varstudy = string(var); % The name of the column we want to analyze
if ~ismember(varstudy, data.Properties.VariableNames)
    error('The variable "%s" was not found in the input data table.', varstudy);
end

fprintf('-------> Calculating MIL-HDBK-310 stats for "%s" in %s, grouped by %s...\n', varstudy, city_name, groupBy);

%% ==========================================================
%  Analysis by grouping
%  ==========================================================

switch lower(groupBy)
    %%  Analysis by Year
    case 'year'
        years_list = unique(data.(year_col));
        num_years = length(years_list);
        results_cell = cell(num_years, 2 + (2 * num_pct)); % City, Year, N-values, N-months

        for i = 1:num_years
            yr = years_list(i);
            year_data = data(data.(year_col) == yr, :);
            MIL_monthly = NaN(12, num_pct);

            for m = 1:12
                studyvar = year_data.(varstudy)(year_data.(month_col) == m);
                if ~isempty(studyvar)
                    MIL_monthly(m, :) = prctile(studyvar, percentile_values);
                end
            end

            [MIL_annual, month_idx] = max(MIL_monthly, [], 1, 'omitnan');
            results_cell(i, :) = [ {city}, {yr}, num2cell(MIL_annual), num2cell(month_idx) ];
        end

        % Dynamically create variable names
        val_names = arrayfun(@(x) sprintf('%s_%d', varstudy, x), exceedance_pct, 'UniformOutput', false);
        mon_names = arrayfun(@(x) sprintf('Month_%d', x), exceedance_pct, 'UniformOutput', false);
        result_var_names = [{'City', 'Year'}, val_names, mon_names];

        %  Plot

    %%  Analysis by Month
    case 'month'
        months_list = 1:12;
        results_cell = cell(12, 2 + num_pct); % City, Month, N-values

        for i = 1:12
            m = months_list(i);
            
            % Get all data for a specific month across ALL years
            month_data = data.(varstudy)(data.(month_col) == m);
            
            % Calculate percentiles for the entire multi-year month dataset
            if ~isempty(month_data)
                climatology_pct = prctile(month_data, percentile_values);
            else
                climatology_pct = NaN(1, num_pct);
            end
            
            results_cell(i, :) = [ {city}, {m}, num2cell(climatology_pct) ];
        end
        
        % Dynamically create variable names
        val_names = arrayfun(@(x) sprintf('%s_%d', varstudy, x), exceedance_pct, 'UniformOutput', false);
        result_var_names = [{'City', 'Month'}, val_names];

    otherwise
        error('Invalid groupBy option. Please choose ''year'' or ''month''.');
end
%%  Plots
if savePlotPath ~= ""
    fprintf('-------> Generating and saving plots to: %s\n', savePlotPath);
    colors = lines(num_pct);

    switch lower(groupBy)
        case 'year'
            plot_dir = fullfile(savePlotPath, city, varstudy,"ks_year");
            if ~isfolder(plot_dir)
                mkdir(plot_dir);
            end
            
            % Plotting for Year-by-Year Analysis
            years_to_plot = unique(data.(year_col));
            for i = 1:length(years_to_plot)
                yr = years_to_plot(i);
                year_data = data(data.(year_col) == yr, :).(varstudy);

                if isempty(year_data)
                    continue;
                end

                fig = figure('Visible', 'off');
                %fig.Position = [817 570 1183 668];
                [k1,xk1] = ksdensity(year_data);
                plot(xk1,k1);
                hold on;
                exceedance_values = prctile(year_data, percentile_values);
                legend_entries = cell(1, num_pct + 1);
                legend_entries{1} = 'Kernel Density';
                for p_idx = 1:num_pct
                    val = exceedance_values(p_idx); pct = exceedance_pct(p_idx);
                    xline(val, 'LineWidth', 2, 'Color', colors(p_idx,:));
                    legend_entries{p_idx + 1} = sprintf('%d%% Excd (%.1f)', pct, val);
                end
                hold off;
                grid on;
                title(sprintf('Density Plot for %s - %d', city, yr));
                xlabel(varstudy);
                ylabel('Probability Density');
                legend(legend_entries, 'Location', 'best');
                filename = fullfile(plot_dir, sprintf('%s_%s_%d.png', city, varstudy, yr));
                saveas(fig, filename); close(fig);
            end

        case 'month'
            plot_dir = fullfile(savePlotPath, city, varstudy,"ks_month");
            if ~isfolder(plot_dir)
                mkdir(plot_dir);
            end
          
            month_names = ["January", "February", "March", "April", "May", "June", "July", ...
                "August", "September", "October", "November", "December"];
            parfor m = 1:12
                % Get all data for the month across all years
                month_data = data.(varstudy)(data.(month_col) == m);
                if isempty(month_data), continue; end

                fig = figure('Visible', 'off');
                fig.Position = [817 570 1183 668];
                [k1,xk1] = ksdensity(month_data);
                plot(xk1,k1);
                hold on;

                % Calculate percentages
                exceedance_values = prctile(month_data, percentile_values);
                legend_entries = cell(1, num_pct + 1);
                legend_entries{1} = 'Kernel Density';
                for p_idx = 1:num_pct
                    val = exceedance_values(p_idx); pct = exceedance_pct(p_idx);
                    xline(val, 'LineWidth', 2, 'Color', colors(p_idx,:));
                    legend_entries{p_idx + 1} = sprintf('%d%% Excd (%.1f)', pct, val);
                end

                hold off; 
                grid on;
                title(sprintf('Density Plot for %s - %s', city, month_names(m)));
                xlabel(varstudy); 
                ylabel('Probability Density');
                legend(legend_entries, 'Location', 'best');

                % Save with a descriptive name
                filename = fullfile(plot_dir, sprintf('%s_%s_%d.png', city, varstudy, m));
                saveas(fig, filename); close(fig);
            end
    end
    fprintf('-------> Plot generation complete.\n');
end

%% ==========================================================
%  Output Table 
%  ==========================================================
results = cell2table(results_cell, 'VariableNames', string(result_var_names));
fprintf('-------> Calculation complete.\n');
end
