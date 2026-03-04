% This code is to analyze atmosphere data ala MIL-310-HBK. 
% This code will intake hourly data mined using Era5_datamanager.py.
% The city split is done with the previosuly mentioned python scrip that
% uses cities.txt as a reference to what cities to pull the data from. 

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
%  Scan Directory and Create File Pointers
% ===========================================================
clear; clc;

% Directory
base_dir = 'Era5/Cities';
if ~isfolder(base_dir)
    error('--Directory not found: %s. Please ensure the Era5/Cities folder exists.', base_dir);
end

% Find all relevant CSV files
file_pattern = fullfile(base_dir, 'ERA_*.csv');
file_list = dir(file_pattern);
file_pointers = table('Size', [length(file_list), 3], ...
                      'VariableTypes', {'string', 'double', 'string'}, ...
                      'VariableNames', {'City', 'Year', 'FilePath'});

% Loop through files and parse names
fprintf('--Scanning directory and building file map...\n');
for i = 1:length(file_list)
    current_filename = file_list(i).name;
    
    % Use regular expressions to reliably extract city and year
    current_split = split(extractBefore(current_filename,".csv"),"_");
    
    if ~isempty(current_split)
        city_name = string(current_split{2});
        year_val  = str2double(current_split{3});
        full_path = fullfile(file_list(i).folder, current_filename);
        
        % Add the parsed info to our pointer table
        file_pointers(i,:) = {city_name, year_val, full_path};
    else
        fprintf('----Warning: Skipping file with unexpected name format: %s\n', filename);
    end
end

disp('--Successfully created file pointer table');


%% ==========================================================
%  Loop by City and Year to Analyze Data
% ===========================================================
fprintf('\n---- Starting Analysis Loop\n');

% Get a list of unique cities from our table
unique_cities = unique(file_pointers.City);

% Iterate through each city 
for i = 1:length(unique_cities)
    current_city = unique_cities(i);
    fprintf('------ Processing City: %s\n', current_city);
    
    % Filter the table to get all entries for the current city
    city_files = file_pointers(file_pointers.City == current_city, :);
    
    % Iterate through each available year for that city
    parfor j = 1:height(city_files)
        current_year = city_files.Year(j);
        file_to_load = city_files.FilePath(j);
        
        fprintf('-------> Loading Year: %d from file: %s\n', current_year, file_to_load);
        
        try
            current_temp_data{j} = readtable(file_to_load);
        catch ME
            fprintf('-------> ERROR loading or processing file: %s\n', file_to_load);
            fprintf('-------> Error message: %s\n', ME.message);
        end % end try
    end % end for j

    % Collapse the data struct
    current_big_table = vertcat(current_temp_data{:});
end % end for i

fprintf('\n--- Analysis Complete ---\n');

