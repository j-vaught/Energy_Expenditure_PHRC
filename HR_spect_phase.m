% MATLAB script - Version 6 (as of 12/14/2022)
% This version introduces refined time shift calculations between Actiheart and Patch signals 
% through acceleration signal correlation. It uses cross-correlation analysis from accel_overlay_V6.m.
% In this version, the Actiheart signal is truncated to match the Patch signal length for accurate metrics computation.
% All participant-specific modifications are isolated into a separate script - participant_parameters_V5.m.
% The script compares Patch PPG with Actiheart ECG, aligning them using participant_parameters_V5.m. The datasets are 
% time-aligned by interpolating to the smaller vector, which is HRPPG in this case.
% PPG_flatten time domain HR_flat is modified to be tied to time_resolution in participant_parameters_V5.m.
% HR_corr_accel_V5 can be used to remove motion artifacts either with an external optimization loop or manually within the script.
% The user can specify the starting heart rate based on the participant's resting heart rate, and specify time resolution for the spectrogram if required.

clear;

% importing participant parameters
participant_parameters_V9;
% Importing acceleration signals for refined time shift calculations.
accel_overlay_V6;

% Computing time domain PPG HR from systolic-systolic spacing.
PPG_flatten_phase; 

% Importing slow motion artifact and DC-offset removed raw PPG signal.
PPG_conv=raw_PPG_data;
PPG_conv=[diff(raw_PPG_data),0];
PPG_conv=angle(hilbert(PPG_conv));

% Convert PPG data into a spectrogram.
[p,f,t]=pspectrum(PPG_conv, fs_PPG, 'spectrogram','FrequencyLimits',[0.5 3.5],'TimeResolution',time_resolution);

% Initialize variables for spectral analysis.
x=1:1:length(t);    
p(:,x)=p(:,x)./max(p(:,x)); % Normalize to between 0 and 1
idx=x./x;
width=x./x;
[pk1, idx1]=max(p(:,1));
idx(1)=idx1*(specify_start==0)+specify_start*(specify_start>0); 

% Fourier peak detection and decision tree implementation for each time point.
for i=2:1:length(t)
  [X, iX, wX]=findpeaks(p(:,i).*(p(:,i)>0.9)); 
 if isempty(iX)  
    idx(i)=idx(i-1);
    width(i)=nan;
 else 
     idx(i)=iX(end);
    width(i)=wX(end);
 end
end

% Derivation of heart rate from peak frequency.
HR_sp=60*f(idx);  

% HR spectrogram calculation, with outliers removed and replaced.
HR_sp_smooth=movmean(filloutliers(HR_sp,'previous','movmedian',20),1)';
HR_sp_smooth=interp1(t, HR_sp_smooth, PPG_time_vector(I));  

HRPPG=HR_sp_smooth;

% Importing Actiheart Data
fid=fopen(filename_Actiheart, 'rt');
ACTIHEART = textscan(fid, '%T%f%f%s%s%s','headerlines', 7,'delimiter','\t');
fclose(fid);
t_Actiheart=86400*datenum(ACTIHEART{1,1});
t_Actiheart=t_Actiheart-t_Actiheart(1);  
t_Actiheart=t_Actiheart+t_Actiheart_shift-trial_start+t_shift; 
HR_Actiheart=ACTIHEART{1,2}; 
HR_Actiheart=HR_Actiheart./(HR_Actiheart>0); 

% Truncate Actiheart to patch length.
[start_Actiheart, I_start]=min(abs(t_Actiheart-0)); 
[end_Actiheart, I_end]=min(abs(t_Actiheart-time(end)));  
t_Actiheart=t_Actiheart(I_start:I_end);
HR_Actiheart=HR_Actiheart(I_start:I_end);

% Calculate self consistency over time.
num_beats=60;

% Initialize an array to contain the self consistency per second.
scs_per_sec = zeros(length(HR_sp_smooth)-30, 3);
k = 1; 
width_interp=interp1(t, width, PPG_time_vector(I)); 

ppg_time = PPG_time_vector(I);    
i = 1;                   
j = 1;                   
while ppg_time(i) <= 30
    i = i + 1;
end

while i < length(HR_sp_smooth)
    smooth = HR_sp_smooth(j:i);
    flat = HR_flat(j:i);
    self_consist = sum((abs(flat-smooth)<10)/length(smooth));
    scs_per_sec(k, 2) = self_consist;
    std_width = std((10/1024)*width_interp(j:i)*60);
    scs_per_sec(k, 3) = std_width;
    scs_per_sec(k, 1) = ppg_time(floor((i + j)/2));
    k = k+1;
    j = j + 1;
    i = i + 1;
end

% Resample HR_flat time domain Actiheart HR down to t_Actiheart for metrics.
HR_smooth_interp=interp1(PPG_time_vector(I), HR_sp_smooth,t_Actiheart);

% Computing all metrics.
Actiheart_accuracy=sum(abs(HR_Actiheart-HR_smooth_interp)<5)/length(HR_smooth_interp);
PPG_self_consistency=sum(abs(HR_flat-HR_sp_smooth)<10)/length(HR_sp_smooth);
Actiheart_RMSE=nanstd((HR_smooth_interp-HR_Actiheart));
Actiheart_MAE_BPM=nanmean(abs(HR_smooth_interp-HR_Actiheart));
Actiheart_MAE_percent=nanmean(abs(HR_smooth_interp-HR_Actiheart)./HR_Actiheart);
time_PPG=(length(PPG)/fs_PPG)/60;  
mean_width=mean((10/1024)*width*60);
std_width=std((10/1024)*width*60);
median_width=median((10/1024)*width*60);
max_width=max((10/1024)*width*60);

% Output the metrics and heart rate.
metrics = table(Actiheart_accuracy, PPG_self_consistency, Actiheart_RMSE, Actiheart_MAE_BPM, Actiheart_MAE_percent, mean_width, std_width, median_width, max_width);
metrics_n = participant_num + "_metrics.xlsx";
writetable(metrics,metrics_n);
HR_Output = table(["Time", PPG_time_vector(I); "HR_PPG" , HR_sp_smooth;].');
HR_Output_n = participant_num + "_PATCH_HR.csv";
writetable(HR_Output, HR_Output_n)

% Output Self Consistency Per Second.
var_names = ["Time", "Self Consistency", "STD Width"];
scs_output = array2table(scs_per_sec);
scs_output.Properties.VariableNames(1:3) = {'Time', 'Self Consistency', 'STD Width'};
writetable(scs_output, participant_num + "_Self_Consistency.csv")
