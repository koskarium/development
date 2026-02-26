%% ==========================================================
%  Synthetic Hourly Temperature Generator
%  30-Year Record with Seasonal + Diurnal + Heatwaves
% ===========================================================

clear; clc;

%% Create hourly time vector (30 years)

startDate = datetime(1991,1,1,0,0,0);
endDate   = datetime(2020,12,31,23,0,0);
time = (startDate:hours(1):endDate)';
N = length(time);

%% Base mean temperature

Tmean = 18;        % annual mean temperature (°C)

%% Seasonal cycle (annual sine wave)

doy = day(time,'dayofyear');
seasonAmp = 12;    % seasonal amplitude (°C)

Tseason = seasonAmp * sin(2*pi*(doy-200)/365);

%% Diurnal cycle

hourOfDay = hour(time);
diurnalAmp = 6;    % day-night variation (°C)

Tdiurnal = diurnalAmp * sin(2*pi*(hourOfDay-15)/24);

%% Random variability (weather noise)

rng(1);   % reproducible
noise = randn(N,1) * 2;

%% Add Heatwave Events

Theat = zeros(N,1);

for yr = 1991:2020
    
    % 1–3 heatwaves per year
    nEvents = randi([1 3]);
    
    for e = 1:nEvents
        
        % random summer day
        startHW = datetime(yr,6,1) + days(randi([0 90]));
        durationDays = randi([3 7]);
        
        idx = time >= startHW & time <= startHW + days(durationDays);
        
        % Add strong anomaly
        Theat(idx) = Theat(idx) + 6 + rand*3;
    end
end

%% Final Temperature Series

T = Tmean + Tseason + Tdiurnal + noise + Theat;

%% Extract year, month, day, hour
Year  = year(time);
Month = month(time);
Day   = day(time);
Hour  = hour(time);

%% Create table
T_data = table(Year, Month, Day, Hour, T, ...
               'VariableNames', {'Year', 'Month', 'Day', 'Hour', 'Temperature_C'});

%% Quick Visualization

figure;
plot(time(1:2000), T(1:2000))
title('Sample of Synthetic Hourly Temperature')
ylabel('Temperature (°C)')
xlabel('Time')
grid on