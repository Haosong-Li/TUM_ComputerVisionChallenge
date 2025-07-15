% --- Input: ---
% --- Output:
% imgs: array of images in folder
% timestamps: array of datetime objects (year + month only)
% selectedPath: the path to the selected folder
% ---
function [imgs, timestamps, selectedPath] = getLocation()
    % Prompt user to select a folder starting from 'Datasets'
    baseDir = fullfile(pwd, 'Datasets');
    if ~isfolder(baseDir)
        error('Base directory "Datasets" not found.');
    end

    selectedPath = uigetdir(baseDir, 'Select a Location Folder');
    if isequal(selectedPath, 0)
        imgs = {};
        timestamps = {};
        selectedPath = '';
        error('Folder selection canceled by user.');
    end

    % Supported image extensions
    extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff'};
    files = [];
    for i = 1:length(extensions)
        files = [files; dir(fullfile(selectedPath, extensions{i}))];
    end

    if isempty(files)
        error('No supported image files found in selected folder.');
    end

    % Sort files alphabetically
    [~, idx] = sort({files.name});
    files = files(idx);

    % Determine format from first file
[~, firstName, ~] = fileparts(files(1).name);
useTimeOnly = false;

if strlength(firstName) == 15  % Format: YYYY_MM_DD_HHmm
    useTimeOnly = true;
elseif strlength(firstName) == 7  % Format: YYYY_MM
    useTimeOnly = false;
else
    error('Unrecognized filename format.');
end

% Preallocate
n = numel(files);
imgs = cell(1, n);
timestamps = datetime.empty(1, 0);  % << Use datetime array, not cell

for k = 1:n
    fullPath = fullfile(files(k).folder, files(k).name);
    imgs{k} = im2double(imread(fullPath));
    [~, nameOnly, ~] = fileparts(files(k).name);

    if useTimeOnly
        timeStr = nameOnly(end-3:end);  % e.g., '1430'
        dt = datetime(timeStr, 'InputFormat', 'HHmm');
    else
        dt = datetime(nameOnly, 'InputFormat', 'yyyy_MM');
    end

    timestamps(k) = dt;  % << Directly into datetime array
end

