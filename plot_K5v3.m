clc;
clear;
close all;

%Quick check so we can know what our problems are when things dont run.
check_file_availability;

% Load HR spectral phase data
HR_spect_phase;

% Load participant parameters
participant_parameters_V9;

% Import K5 data
K5_all = importdata(filename_K5, ',', 2);

t_K5 = K5_all.data(:, 1);
VO2_norm = K5_all.data(:, 13);

% Interpolate HR and RMS Acceleration data
HR_smooth_interp = interp1(t_Actiheart, HR_smooth_interp, t_K5);
rms_accel_interp = interp1(time_actiheart, sqrt(movmean(ENMO_actiheart.^2, 50*3)), t_K5);

% Combined Plot: Normalized VO2 and RMS ENMO vs Interpolated Heart Rate
figure;
yyaxis left
scatter(HR_smooth_interp, VO2_norm);
ylabel('Normalized VO2');

yyaxis right
scatter(HR_smooth_interp, rms_accel_interp);
ylabel('RMS ENMO over 3s (Accelerometer Units)');

title(['Participant ', num2str(participant_num), ': Normalized VO2 and RMS ENMO(3s) vs. Heart Rate']);
xlabel('Interpolated Heart Rate (BPM)');
set(gca,'FontSize',10);
