% Assign participant number
participant_num = '2525';

% Specify filenames related to the participant. 
% Ensure these files are saved in the same folder as the script.
filename_Patch = strcat(participant_num, '_TEST.TXT');
filename_Actiheart = strcat(participant_num, '_hr.txt');
filename_Actiheart_accl = strcat(participant_num, '_accl.txt');
filename_K5 = strcat(participant_num, '_K5.xlsx');

% Specify the trial start time in seconds. The minimum is 1s. This can be changed as per requirements.
trial_start = 322;

% Specify the trial length in seconds. Here, it's set to 2685 seconds or roughly 22 minutes.
trial_length = 2685;

% Set the Photoplethysmography (PPG) sampling rate. This value is fixed and should not be changed.
fs_PPG = 86.8;

% Specify starting heart rate for resting heart rate calculations. If HR_start=0, the calculated starting peak will be used.
HR_start = 0;
specify_start = round((HR_start/600)*1024); % Convert to index for frequency vector in spectrogram.

% Set the offset in seconds between PATCH and Actiheart. This should be determined from the protocol tracking sheet for each experiment.
t_Actiheart_shift = (5*60+20);  

% Set the time resolution for the spectrogram. Default value is suggested to be 30s.
% This value should only be changed if needed and after consultation with the Principal Investigator (PI).
time_resolution = 20;  

% Set the time to average RMS acceleration over in seconds. This value should be set after consultation with the PI.
average_time = 5;      
