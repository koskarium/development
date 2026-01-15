file ='C:\Users\Oskar\Documents\GitHub\development\Atmospheric_Anal\MERRA2_400.tavg1_2d_slv_Nx.20251201.nc4'
daten = ncread(file,'TS');
% Read coordinate arrays
lat = ncread(file, 'lat');
lon = ncread(file, 'lon');

% Find indices for desired region
lat_idx = find(lat >= -50 & lat <= 50);
lon_idx = find(lon >= -130 & lon <= -60);

% Subset T2M
daten_subset = daten(lon_idx, lat_idx, :);

time_step = 1;  % first hour
imagesc(lon(lon_idx), lat(lat_idx), squeeze(daten_subset(:, :, time_step))')
set(gca, 'YDir', 'normal') % Correct Y-axis orientation
colorbar
title('2-meter Temperature (K)')
xlabel('Longitude')
ylabel('Latitude')

for t = 1:size(daten_subset,3)
    imagesc(lon(lon_idx), lat(lat_idx), squeeze(daten_subset(:,:,t))')
    set(gca, 'YDir', 'normal')
    colorbar
    title(sprintf('2m Temp Hour %d', t))
    pause(0.2)
end