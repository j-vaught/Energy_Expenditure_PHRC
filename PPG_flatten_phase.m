% This MATLAB script processes Photoplethysmography (PPG) data to calculate 
% time-domain heart rate. It starts by importing PPG data, normalizing and 
% flattening the data, and then detecting peaks. These peaks are used to 
% calculate the heart rate.

% Define epoch length in seconds
epoch = 0.5;

% Set up for data import
delimiterIn = ',';
headerlinesIn = 1;  

% Import PPG data
%filename_Patch defined in participant_parameters_V9
participant_parameters_V9;

PPG_data_from_file = importdata(filename_Patch, delimiterIn, headerlinesIn);

% Define the row to start analyzing data from or STARTING POINT
import_line = 2;

% Extract raw PPG data and remove mean over epoch length
raw_PPG_data = transpose(PPG_data_from_file.data(1+round(trial_start*fs_PPG):end,1));
PPG = raw_PPG_data - movmean(raw_PPG_data, epoch*fs_PPG);

% Calculate the number of samples in an epoch window
samples_PPG = round((epoch)*fs_PPG);

% Define time vector
PPG_time_vector = (1/fs_PPG) * [1:1:length(PPG)];

% Apply a low pass filter to remove motion artifacts and other slow processes
filtered_PPG_data = lowpass(PPG, 3.5, fs_PPG, 'ImpulseResponse', 'iir', 'Steepness', 0.8);

% Find the moving maximum of the absolute filtered signal over the epoch
PPG_trend = movmax(abs(filtered_PPG_data), samples_PPG);

% Normalize and flatten the PPG signal
PPG_flat = filtered_PPG_data ./ PPG_trend;

% Find positive peaks greater than 0.5 in the flattened PPG signal
[m,I] = findpeaks(PPG_flat .* (PPG_flat > 0.5));

% Calculate the time domain heart rate from the peak intervals
HR_flat = 60 ./ [diff(PPG_time_vector(I)), 1];

% Clean up the HR data by filling outliers with the previous moving median value and apply moving mean filter
HR_flat = filloutliers(HR_flat, 'previous', 'movmedian', 40);
HR_flat = movmean(HR_flat, time_resolution);
