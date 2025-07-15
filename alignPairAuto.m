function [alignedImgs, tforms, statuses, outputPath] = alignPairAuto(inputPath)
    % Modified version of alignPair that automatically saves without user dialog
    % Returns an additional outputPath parameter
    % Load images
    fileList = [...
        dir(fullfile(inputPath, '*.jpg')); ...
        dir(fullfile(inputPath, '*.jpeg')); ...
        dir(fullfile(inputPath, '*.png')); ...
        dir(fullfile(inputPath, '*.bmp')); ...
        dir(fullfile(inputPath, '*.tif')); ...
        dir(fullfile(inputPath, '*.tiff')) ...
    ];


    if isempty(fileList)
        error("Cannot find any supported images (JPG/JPEG/PNG/BMP/TIF/TIFF) in the folder");
    end

    % Load refernce
    refImg = imread(fullfile(inputPath, fileList(1).name));
    refImg = ensureRGB(refImg);
    grayRef = rgb2gray(refImg);

    % Create interactive interface
    hFig = figure('Name', 'Point Selection', 'Position', [100, 100, 1600, 900]);
    subplot('Position', [0.05, 0.05, 0.7, 0.9]); % 70% width for image
    imshow(refImg); 
    title('Please select 4-10 stable feature points. (Press Enter when done)', 'FontSize', 14);
    hold on;
   
    baseInstructions = {
        'TIPS:'
        '1. Select stable feature points (e.g., river, coastline, roof).'
        '2. Disperse points to avoid clustering in one area.'
        '3. Avoid moving objects (e.g., cars, people, vegetation).'
        '4. Avoid points too close to the edge.'
        'Press ENTER to finish selection'
        'Press BACKSPACE/DEL to remove last point'
        'Points selected: 0'
    };

    % Panel background
    instructionPanel = uipanel('Title', 'Instructions', ...
        'Position', [0.8, 0.3, 0.13, 0.6], ...
        'FontSize', 12, ...
        'BackgroundColor', [0.1 0.15 0.25]);

    % Display each line as a separate text box (for spacing control)
    numLines = numel(baseInstructions);
    hTextList = gobjects(numLines, 1); % for later update
    for i = 1:numLines
        hTextList(i) = uicontrol('Style', 'text', ...
            'Parent', instructionPanel, ...
            'Units', 'normalized', ...
            'Position', [0.05, 1 - i*0.11, 0.9, 0.1], ... % control vertical spacing
            'String', baseInstructions{i}, ...
            'FontSize', 11, ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', [0.1 0.15 0.25]);
    end
    applyDarkTheme(hFig);

    function updateCounter()
        numPoints = size(selectedPoints, 1);
        instructionText{5} = ['5. Points selected: ' num2str(numPoints)];
        set(hTextList(end), 'String', ['6. Points selected: ' num2str(numPoints)]);
    end       
    
    selectedPoints = [];
    pointHandles = [];
    textHandles = [];
    
    while true
        try
            [x, y, button] = ginput(1);
        catch
            break;
        end
        
        % Exit on Enter key
        if isempty(button) || button == 13
            break;
        % Remove last point on Backspace/Delete
        elseif button == 8 || button == 127
            if ~isempty(selectedPoints)
                delete(pointHandles(end));
                delete(textHandles(end));
                selectedPoints(end, :) = [];
                pointHandles(end) = [];
                textHandles(end) = [];
                updateCounter();
            end
        % Add new point on left click
        elseif button == 1
            selectedPoints(end+1, :) = [x, y]; %#ok<AGROW>
            pointHandles(end+1) = plot(x, y, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
            textHandles(end+1) = text(x+15, y+15, num2str(size(selectedPoints,1)), ...
                'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
            updateCounter();
        end
    end
    
    % Close selection figure
    close(hFig);
       
    % Verify minimum points requirement
    if size(selectedPoints, 1) < 4
        error('At least 4 points must be selected');
    end
    fixedPoints = selectedPoints;
    
    % Detect features of reference
    roi = getBoundingBox(fixedPoints);
    refPoints = detectORBFeatures(grayRef, 'ROI', roi);
    if refPoints.Count < 20
        roi = inflateROI(roi, 2);
        refPoints = detectORBFeatures(grayRef, 'ROI', roi);
    end
    [refFeatures, refValidPoints] = extractFeatures(grayRef, refPoints);

     % Initialization
    n = numel(fileList) - 1;
    alignedImgs = cell(1, n);
    tforms = cell(1, n);
    statuses = strings(1, n);
    inlierCounts = zeros(1, n); % optional
    
    MIN_MATCH_COUNT = 10;
    MIN_INLIERS = 6;
    
    accumTform = affine2d(eye(3));
    
    prevFeatures = refFeatures;
    prevValidPoints = refValidPoints;
    prevImg = refImg;
    grayPrev = grayRef;

    hWait = waitbar(0, 'Aligning images...');
    for i = 1:n
        movImg = imread(fullfile(inputPath, fileList(i+1).name));
        movImg = ensureRGB(movImg);
        grayMov = rgb2gray(movImg);
        
        % Gaussian smoothing to suppress noise
        grayMovSmooth = imgaussfilt(grayMov, 1.0);
    
        % Feature detection & selection
        movPoints = detectORBFeatures(grayMovSmooth);
        N = min(round(0.6 * movPoints.Count), 40000);
        strongestPoints = selectStrongest(movPoints, N);
        [movFeatures, movValidPoints] = extractFeatures(grayMovSmooth, strongestPoints);
        
        % Feature matching
        indexPairs = matchFeatures(prevFeatures, movFeatures, ...
            'MatchThreshold', 80, 'MaxRatio', 0.8, 'Unique', true);
    
        if size(indexPairs, 1) < MIN_MATCH_COUNT
            alignedImgs{i} = movImg;
            tforms{i} = accumTform;
            statuses(i) = "failed_match";
            warning("Too few matches for image %d", i+1);
            continue;
    end
    
    matchedPrevPts = prevValidPoints.Location(indexPairs(:,1), :);
    matchedMovPts = movValidPoints.Location(indexPairs(:,2), :);
    
    try
         [stepTform, inlierIdx] = estimateGeometricTransform2D( ...
                matchedMovPts, matchedPrevPts, 'affine', ...
                'MaxNumTrials', 7250, 'MaxDistance', 5, 'Confidence', 97);
        catch
            alignedImgs{i} = movImg;
            tforms{i} = accumTform;
            statuses(i) = "failed_estimate";
            warning("Transformation estimation failed for image %d", i+1);
            continue;
        end
    
        % Inlier check
        numInliers = sum(inlierIdx);
        inlierCounts(i) = numInliers;
    
        if numInliers < MIN_INLIERS
            alignedImgs{i} = movImg;
            tforms{i} = accumTform;
            statuses(i) = "too_few_inliers";
            warning("Too few inliers for image %d", i+1);
            continue;
        end

    % Update cumulative transformation
    accumTform = affine2d(stepTform.T * accumTform.T);
    alignedImg = imwarp(movImg, accumTform, 'OutputView', imref2d(size(refImg)));

    alignedImgs{i} = alignedImg;
    tforms{i} = accumTform;
    statuses(i) = "success";

    % Update reference
    prevFeatures = movFeatures;
    prevValidPoints = movValidPoints;
    prevImg = movImg;
    grayPrev = grayMov;
    
    % Update waitbar
    waitbar(i/n,hWait,sprintf('Aligning images...%d / %d', i, n));
    end

    close(hWait);

    % Automatically save aligned images to .cache folder in current directory
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    cacheDir = fullfile(pwd, '.cache');
    if ~exist(cacheDir, 'dir')
        mkdir(cacheDir);
    end
    outputPath = fullfile(cacheDir, ['aligned_' timestamp]);
    mkdir(outputPath);
    
    % Save reference image
    imwrite(refImg, fullfile(outputPath, fileList(1).name));
    
    % Save aligned images
    for i = 1:n
        if statuses(i) == "success"
            imwrite(alignedImgs{i}, fullfile(outputPath, fileList(i+1).name));
        else
            % Save original image if alignment failed
            imwrite(alignedImgs{i}, fullfile(outputPath, fileList(i+1).name));
        end
    end
    
    disp("Aligned images automatically saved to: " + outputPath);
    
    % Add reference image to the beginning of alignedImgs for consistency
    alignedImgs = [{refImg}, alignedImgs];
    statuses = ["success", statuses];
    tforms = [{affine2d(eye(3))}, tforms];
end

%% Subfunction
function img = ensureRGB(img)
    if size(img, 3) == 1
        img = repmat(img, [1, 1, 3]);
    end
end

   
function roi = getBoundingBox(points)
    padding = 50;
    xmin = max(1, min(points(:,1)) - padding);
    ymin = max(1, min(points(:,2)) - padding);
    xmax = max(points(:,1)) + padding;
    ymax = max(points(:,2)) + padding;
    width = xmax - xmin;
    height = ymax - ymin;
    roi = round([xmin, ymin, width, height]);
end

function roi = inflateROI(originalROI, factor)
    cx = originalROI(1) + originalROI(3)/2;
    cy = originalROI(2) + originalROI(4)/2;
    newW = originalROI(3) * factor;
    newH = originalROI(4) * factor;
    roi = [cx - newW/2, cy - newH/2, newW, newH];
end