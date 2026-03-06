file ='D:\Atmosphere\Era5\temp\era5_2023.nc'

ncdisp(file);

% Read coordinate arrays
lat = ncread(file, 'latitude');
lon = ncread(file, 'longitude');

time = ncread(file,'valid_time');
nTime = length(time);

% Find indices for desired region
lat_idx = find(lat >= 20 & lat <= 50);
lon_idx = find(lon >= 235 & lon <= 294);

% Define subset read parameters
start = [min(lon_idx), min(lat_idx), 1];
count = [length(lon_idx), length(lat_idx), nTime];

% Subset T2M
daten_subset = ncread(file, 't2m', start, count);

% Visualize first time step
time_step = 1;  % first hour
imagesc(lon(lon_idx), lat(lat_idx), squeeze(daten_subset(:, :, time_step))')
set(gca, 'YDir', 'normal') % Correct Y-axis orientation
colorbar
title('2-meter Temperature (K)')
xlabel('Longitude')
ylabel('Latitude')

% Loop through all hours
for t = 1:size(daten_subset,3)
    imagesc(lon(lon_idx), lat(lat_idx), squeeze(daten_subset(:,:,t))')
    set(gca, 'YDir', 'normal')
    colorbar
    title(sprintf('2m Temp Hour %d', t))
    pause(0.2)
end