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

    % --- Rename files to YYYY_MM ---
    datePatterns = {
        '(\d{1,2})_(\d{4})', 'MM_YYYY';      % e.g., 3_2022
        '(\d{4})_(\d{1,2})', 'YYYY_MM';      % e.g., 2022_3
        '(\d{4})-(\d{2})-(\d{2})', 'YYYY-MM-DD'; % e.g., 2022-03-15
        '(\d{8})', 'YYYYMMDD';              % e.g., 20220315
    };

    for i = 1:length(files)
        name = files(i).name;
        oldPath = fullfile(files(i).folder, name);
        [~, nameOnly, ext] = fileparts(name);

        renamed = false;

        for p = 1:size(datePatterns, 1)
            pattern = datePatterns{p, 1};
            tokens = regexp(nameOnly, pattern, 'tokens');
            if ~isempty(tokens)
                tokens = tokens{1};
                switch datePatterns{p, 2}
                    case 'MM_YYYY'
                        mm = sprintf('%02d', str2double(tokens{1}));
                        yyyy = tokens{2};
                    case 'YYYY_MM'
                        yyyy = tokens{1};
                        mm = sprintf('%02d', str2double(tokens{2}));
                    case 'YYYY-MM-DD'
                        yyyy = tokens{1};
                        mm = tokens{2};
                    case 'YYYYMMDD'
                        yyyy = tokens{1}(1:4);
                        mm = tokens{1}(5:6);
                    otherwise
                        continue;
                end
                newName = [yyyy '_' mm ext];
                newPath = fullfile(files(i).folder, newName);
                if ~exist(newPath, 'file')
                    movefile(oldPath, newPath);
                    fprintf('Renamed: %s -> %s\n', name, newName);
                    files(i).name = newName;  % Update in struct
                    renamed = true;
                else
                    fprintf('Skipped (exists): %s\n', newName);
                end
                break;
            end
        end

        if ~renamed
            fprintf('Unrecognized format: %s (skipped)\n', name);
        end
    end

    % Refresh file list after renaming
    files = [];
    for i = 1:length(extensions)
        files = [files; dir(fullfile(selectedPath, extensions{i}))];
    end

    % Sort files alphabetically
    [~, idx] = sort({files.name});
    files = files(idx);

    % Preallocate
    n = numel(files);
    imgs = cell(1, n);
    timestamps = datetime.empty(1, 0);

    for k = 1:n
        fullPath = fullfile(files(k).folder, files(k).name);
        imgs{k} = im2double(imread(fullPath));
        [~, nameOnly, ~] = fileparts(files(k).name);

        try
            dt = datetime(nameOnly, 'InputFormat', 'yyyy_MM');
        catch
            warning('Could not parse datetime from file: %s', files(k).name);
            dt = NaT;
        end

        timestamps(k) = dt;
    end
end

