% CODE VERSION DATA 7_27_2021
% This version incorporates two different spectrogram power thresholds for steps vs. motion artifact.

clear
% Participant-specific parameters are set in the "participant_parameters_V9.m" file.
participant_parameters_V9;

% Set accelerometer sampling rate.
fs_accel=fs_PPG;

% Import data.
A = importdata(filename_Patch,',',1);

% Accelerometer readings in x, y, and z axes.
x_a=A.data(1+round(trial_start*fs_PPG):end,2);
y_a=A.data(1+round(trial_start*fs_PPG):end,3);
z_a=A.data(1+round(trial_start*fs_PPG):end,4);

% Convert accelerometer readings from bits to G's.
x_a=(x_a/1024)*25.2-16;
y_a=(y_a/1024)*25.2-16;
z_a=(z_a/1024)*25.2-16;

% Calculate time and magnitude of acceleration.
index=1:1:length(x_a);
time=index./fs_accel;
mag=sqrt(x_a.^2+y_a.^2+z_a.^2); 

% Compute jerk (rate of change of acceleration).
jerk=[diff(mag);0];

% Import actiheart accelerometer data sampled to 50Hz by Actiheart.
AA=importdata(filename_Actiheart_accl,'\t',6);
x_actiheart=AA.data(1+round(trial_start*50):end,1);
y_actiheart=AA.data(1+round(trial_start*50):end,2);
z_actiheart=AA.data(1+round(trial_start*50):end,3);
mag_actiheart=sqrt(x_actiheart.^2+y_actiheart.^2+z_actiheart.^2)/9.81;

% Compute jerk for Actiheart data and set up time vector.
jerk_actiheart=[diff(mag_actiheart);0];
time_actiheart=(1/50)*[0:1:length(mag_actiheart)-1];
time_actiheart=time_actiheart+t_Actiheart_shift;

% Truncate Actiheart data to match patch time.
[start_actiheart, i_start]=min(abs(time_actiheart-time(1))); 
[end_actiheart, i_end]=min(abs(time_actiheart-time(end)));      
time_actiheart=time_actiheart(i_start:i_end);
jerk_actiheart=jerk_actiheart(i_start:i_end);

% Downsample PATCH jerk to 50Hz Actiheart rate.
jerk_interp=interp1(time, jerk, time_actiheart)';
jerk_interp=fillmissing(jerk_interp,'spline');

% Optimize time_shift by getting cross-correlation between Actiheart and Patch jerk signals.
[correl, lags]=xcorr(jerk_interp, jerk_actiheart,50*300);
[xx, yy]=max(correl);
t_shift=lags(yy)/50;  

% Remake Actiheart jerk based on refined delay t_shift.
jerk_actiheart=[diff(mag_actiheart);0];
time_actiheart=(1/50)*[0:1:length(mag_actiheart)-1];
time_actiheart=time_actiheart+t_Actiheart_shift+t_shift;  

% Truncate again to PATCH time.
[start_actiheart, i_start]=min(abs(time_actiheart-time(1))); 
[end_actiheart, i_end]=min(abs(time_actiheart-time(end)));      
time_actiheart=time_actiheart(i_start:i_end);
jerk_actiheart=jerk_actiheart(i_start:i_end);
jerk_interp=interp1(time, jerk, time_actiheart)';
jerk_interp=fillmissing(jerk_interp,'spline');

% Calculate scaling factor from Actiheart to Patch.
average_time=5;
factor=sqrt(movmean(jerk_actiheart.^2,50*average_time))\sqrt(movmean(jerk_interp.^2,50*average_time));

% Compute ENMO (Euclidean Norm Minus One) for Patch and Actiheart data.
ENMO=cumsum(jerk_interp)-movmean(cumsum(jerk_interp),50);
ENMO_actiheart=cumsum(jerk_actiheart)-movmean(cumsum(jerk_actiheart),50);

% Linear regression to RMS ENMO over average time to get rsq.
x=sqrt(movmean(ENMO_actiheart.^2,50*average_time));
y=(1/factor)*sqrt(movmean(ENMO.^2,50*average_time));
scaling=x\y;
yfit = scaling*x; 

% Residuals analysis for r-squared computation.
yresid = y - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(y)-1) * var(y);
rsq = 1 - SSresid/SStotal;
