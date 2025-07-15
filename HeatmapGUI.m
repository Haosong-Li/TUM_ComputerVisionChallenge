function HeatmapGUI(imageFolder)
    % Create the main full-screen GUI window
    screenSize = get(0, 'ScreenSize');
    fillAllImages(imageFolder)
    fig = figure('Name', 'Heatmap GUI', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'Toolbar', 'none', ...
                 'Position', screenSize);

    % Initialize image folder path and get file list
    imgPath = imageFolder; 
    if imgPath == 0, close(fig); return; end
    imgFiles = dir(fullfile(imgPath, '*.jpg'));
    if isempty(imgFiles)
        imgFiles = dir(fullfile(imgPath, '*.png'));
    end
    imgNames = {imgFiles.name};

    % Require at least 2 images to proceed
    if numel(imgNames) < 2
        errordlg('Please provide at least two images!');
        close(fig); return;
    end

    % Load default reference (img1) and test (img2) images
    img1 = imread(fullfile(imgPath, imgNames{1}));
    img2 = imread(fullfile(imgPath, imgNames{2}));

    % Create display axes
    axLeft = subplot('Position', [0.05 0.3 0.4 0.65]);
    axRight = subplot('Position', [0.55 0.3 0.4 0.65]);

    % Display the initial images
    imgLeftHandle = imshow(img1, 'Parent', axLeft);
    title(axLeft, 'Mask Overlay (Compared Image)','FontSize', 16);
    imgRightHandle = imshow(img2, 'Parent', axRight);
    title(axRight, 'Heatmap','FontSize', 16);

    % Set up the colorbar and colormap for the heatmap
    cbar = colorbar(axRight, 'Position', [0.96 0.3 0.015 0.65]);
    colormap(axRight, turbo);
    clim(axRight, [0 1]);
    cbar.Label.String = 'Difference';
    cbar.Label.Color = 'w';
    cbar.Color = 'w';

    % Dropdown menu for selecting reference image
    uicontrol(fig, 'Style', 'text', 'String', 'Reference Image:', ...
              'Units', 'normalized', 'Position', [0.035 0.31 0.1 0.04], ...
              'FontSize', 16);

    popup1 = uicontrol(fig, 'Style', 'popupmenu', 'String', imgNames, ...
              'Units', 'normalized', 'Position', [0.14 0.2975 0.1 0.05], ...
              'Value', 1, 'Callback', @updateImages, ...
              'FontSize', 14);

    % Dropdown menu for selecting compared image
    uicontrol(fig, 'Style', 'text', 'String', 'Compared Image:', ...
              'Units', 'normalized', 'Position', [0.26 0.31 0.1 0.04], ...
              'FontSize', 16);

    popup2 = uicontrol(fig, 'Style', 'popupmenu', 'String', imgNames, ...
              'Units', 'normalized', 'Position', [0.365 0.2975 0.1 0.05], ...
              'Value', 2, 'Callback', @updateImages, ...
              'FontSize', 14);

    % Toggle button to show/hide masks on the heatmap (right image)
    toggleMask = uicontrol(fig, 'Style', 'togglebutton', 'String', 'Show Mask (Right)', ...
                'Units', 'normalized', 'Position', [0.775 0.31 0.125 0.06], ...
                'Value', 0, 'Callback', @updateDisplay, ...
                'FontSize', 16);
    toggleLeftMask = uicontrol(fig, 'Style', 'togglebutton', ...
        'String', 'Show Mask (Left)', ...
        'Units', 'normalized', ...
        'Position', [0.625 0.31 0.125 0.06], ...
        'FontSize', 16, ...
        'Value', 1, ...
        'Callback', @updateDisplay);

    % Threshold label and input field
    uicontrol(fig, 'Style', 'text', 'String', 'Threshold:', ...
              'Units', 'normalized', 'Position', [0.65 0.2 0.08 0.04], ...
              'FontSize', 16);

    thresholdEdit = uicontrol(fig, 'Style', 'edit', 'String', '20', ...
              'Units', 'normalized', 'Position', [0.725 0.205 0.04 0.04], ...
              'Callback', @updateDisplay, ...
              'FontSize', 16);

    % Increase/decrease threshold buttons
    uicontrol(fig, 'Style', 'pushbutton', 'String', '+', ...
              'Units', 'normalized', 'Position', [0.775 0.205 0.04 0.04], ...
              'Callback', @(~,~) changeThresh(5), ...
              'FontSize', 16);

    uicontrol(fig, 'Style', 'pushbutton', 'String', '-', ...
              'Units', 'normalized', 'Position', [0.82 0.205 0.04 0.04], ...
              'Callback', @(~,~) changeThresh(-5), ...
              'FontSize', 16);

    % Save result button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save Result', ...
              'Units', 'normalized', ...
              'Position', [0.125 0.2 0.1 0.05], ...
              'FontSize', 16, ...
              'Callback', @saveImage);

    % Exit GUI
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Exit', ...
              'Units', 'normalized', ...
              'Position', [0.275 0.2 0.08 0.05], ...
              'FontSize', 16, ...
              'Callback', @(~,~) close(fig));

    % Initial rendering
    updateDisplay();
    applyDarkTheme(fig);

    % Handle image selection change
    function updateImages(~, ~)
        val1 = popup1.Value;
        val2 = popup2.Value;
        if val1 == val2
            errordlg('Please select a different image to compare!');
            return;
        end
        img1 = imread(fullfile(imgPath, imgNames{val1}));
        img2 = imread(fullfile(imgPath, imgNames{val2}));
        updateDisplay();
    end

    % Adjust threshold and update
    function changeThresh(delta)
        v = str2double(thresholdEdit.String);
        v = min(100, max(0, v + delta));
        thresholdEdit.String = num2str(v);
        updateDisplay();
    end

    % Core function: update image displays
    function updateDisplay(~, ~)
        threshold = str2double(thresholdEdit.String);
        threshold = min(100, max(0, threshold));
        thresholdEdit.String = num2str(threshold);

        [highlightImg, maskA, maskB] = computeMask(img1, img2, 75);
        heatMap = visualizeHeat(img1, img2, maskA, maskB, threshold);

        set(imgLeftHandle, 'CData', highlightImg);

        if toggleMask.Value == 1
            heatMap = imoverlay(heatMap, maskA, 'yellow');
            heatMap = imoverlay(heatMap, maskB, 'yellow');
        end
        set(imgRightHandle, 'CData', heatMap);
        if toggleLeftMask.Value == 1
            temp = imoverlay(img2, maskA, 'yellow');
            leftImg = imoverlay(temp, maskB, 'yellow');
        else
            leftImg = img2;
        end
        set(imgLeftHandle, 'CData', leftImg);
    end

    % Save current right-side heatmap as PNG
    function saveImage(~, ~)
        [file, path] = uiputfile({'*.png','PNG Image (*.png)'; '*.jpg','JPEG Image (*.jpg)'}, ...
                                  'Save Difference Highlight As...', ...
                                  'difference_highlight.png');
        if isequal(file, 0) || isequal(path, 0)
            return;
        end
        fullPath = fullfile(path, file);
        frame = getframe(ax2);
        imwrite(frame.cdata, fullPath);
        msgbox(['Image saved to: ', fullPath], 'Save Successfully');
    end
end

% Generate heatmap based on pixel difference and threshold
function heatMap = visualizeHeat(imgA, imgB, maskA, maskB, threshold)
    grayA = double(rgb2gray(imgA));
    grayB = double(rgb2gray(imgB));
    diff = abs(grayA - grayB) - threshold;
    diff = max(diff, 0);

    diff(maskA) = diff(maskA);
    diff(maskB) = diff(maskB);

    diff = diff(1:2:end, 1:2:end);
    diff = imresize(diff, size(grayA));
    diff = mat2gray(diff);
    heatMap = ind2rgb(im2uint8(diff), turbo);
end

% Compute change masks and overlay results
function [highlightImg, diffA, diffB] = computeMask(imgA, imgB, areaThresh)
    imgA = im2double(imgA);
    imgB = im2double(imgB);
    diffMap = sqrt(mean((imgA - imgB).^2, 3));
    diffA = (diffMap > 0.1) & (mean(imgA, 3) > mean(imgB, 3));
    diffB = (diffMap > 0.1) & (mean(imgB, 3) > mean(imgA, 3));
    diffA = bwareaopen(diffA, round(areaThresh));
    diffB = bwareaopen(diffB, round(areaThresh));
    temp = imoverlay(imgB, diffA, 'yellow');
    highlightImg = imoverlay(temp, diffB, 'yellow');
end