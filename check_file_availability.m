clc;
% Get the current directory path
directory = pwd;

% Specify the filenames to check
filenames = {'accel_overlay_V6.m', 'participant_parameters_V9.m', 'HR_spect_phase.m', 'PPG_flatten_phase.m'};

% Initialize a logical array to store the availability of files
fileAvailability = false(1, numel(filenames));

% Loop through each filename and check its availability
for i = 1:numel(filenames)
    filePath = fullfile(directory, filenames{i});
    fileAvailability(i) = exist(filePath, 'file') == 2;  % 2 represents a file in MATLAB
end

% Display the availability of files
for i = 1:numel(filenames)
    if fileAvailability(i)
        disp(['Program File "', filenames{i}, '" is available.']);
    else
        disp(['Program File "', filenames{i}, '" is not available.']);
    end
end


% Check if all initial files are available
if all(fileAvailability)
    % Display a new line after the message
    disp('All Program Files were found.');
    disp(' ');  % New line
    %import participant parameters
    participant_parameters_V9;
    % Specify the data files to check availability
    additionalFilenames = {filename_Patch, filename_Actiheart, filename_Actiheart_accl, filename_K5};

    % Initialize a logical array to store the availability of additional files
    additionalFileAvailability = false(1, numel(additionalFilenames));

    % Loop through each additional filename and check its availability
    for i = 1:numel(additionalFilenames)
        filePath = fullfile(directory, additionalFilenames{i});
        additionalFileAvailability(i) = exist(filePath, 'file') == 2;  % 2 represents a file in MATLAB
    end

    % Display the availability of additional files
    for i = 1:numel(additionalFilenames)
        if additionalFileAvailability(i)
            disp(['Data file "', additionalFilenames{i}, '" is available.']);
        else
            disp(['Data file "', additionalFilenames{i}, '" is not available.']);
        end
    end
    % display error message that is useful
    if ~any(additionalFileAvailability)
        disp('Check participant_parameters_V9.m or directory for errors.');
    end
else
    disp('Not all initial files are available. Check directory for missing or renamed program files.');
end
