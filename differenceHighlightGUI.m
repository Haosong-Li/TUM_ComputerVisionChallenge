function differenceHighlightGUI(imageFolder)
    % Create main full-screen GUI window
    screenSize = get(0, 'ScreenSize');
    fillAllImages(imageFolder)
    fig = figure('Name', 'Difference Highlight GUI', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'Toolbar', 'none', ...
                 'Position', screenSize);
    applyDarkTheme(fig);

    % Load image list from folder
    imgPath = imageFolder;
    if imgPath == 0, close(fig); return; end
    imgFiles = dir(fullfile(imgPath, '*.jpg'));
    if isempty(imgFiles)
        imgFiles = dir(fullfile(imgPath, '*.png'));
    end
    imgNames = {imgFiles.name};

    % Require at least two images to compare
    if numel(imgNames) < 2
        errordlg('Please provide at least two images!');
        close(fig); return;
    end

    % Load default selected images
    img1Name = imgNames{1};
    img2Name = imgNames{2};
    img1 = imread(fullfile(imgPath, img1Name));
    img2 = imread(fullfile(imgPath, img2Name));

    % Display image 1 on the left axis
    ax1 = subplot('Position', [0.05 0.3 0.4 0.65]);
    im1Handle = imshow(img1, 'Parent', ax1);
    title(ax1, 'Image 1','FontSize', 16);

    % Display image 2 or mask overlay on the right axis
    ax2 = subplot('Position', [0.55 0.3 0.4 0.65]);
    im2Handle = imshow(img2, 'Parent', ax2);
    title(ax2, 'Image 2','FontSize', 16);

    % Dropdown for selecting image 1
    uicontrol(fig, 'Style', 'text', 'String', 'Image 1:', ...
              'Units', 'normalized', 'Position', [0.075 0.31 0.05 0.04], ...
              'FontSize', 16);
    popup1 = uicontrol(fig, 'Style', 'popupmenu', 'String', imgNames, ...
              'Units', 'normalized', 'Position', [0.13 0.2975 0.1 0.05], ...
              'Value', 1, 'Callback', @updateSelection, ...
              'FontSize', 14);

    % Dropdown for selecting image 2
    uicontrol(fig, 'Style', 'text', 'String', 'Image 2:', ...
              'Units', 'normalized', 'Position', [0.25 0.31 0.05 0.04], ...
              'FontSize', 16);
    popup2 = uicontrol(fig, 'Style', 'popupmenu', 'String', imgNames, ...
              'Units', 'normalized', 'Position', [0.3075 0.2975 0.1 0.05], ...
              'Value', 2, 'Callback', @updateSelection, ...
              'FontSize', 14);

    % Toggle button to show/hide difference mask
    toggleMask = uicontrol(fig, 'Style', 'togglebutton', 'String', 'Show Mask', ...
                'Units', 'normalized', 'Position', [0.7 0.31 0.125 0.06], ...
                'Value', 1, 'Callback', @updateDisplay, ...
                'FontSize', 16,...
                'BackgroundColor',[0.1 0.15 0.25]);

    % Threshold controls (label, input, +, - buttons)
    uicontrol(fig, 'Style', 'text', 'String', 'Threshold:', ...
              'Units', 'normalized', 'Position', [0.65 0.2 0.08 0.04], ...
              'FontSize', 16);
    thresholdEdit = uicontrol(fig, 'Style', 'edit', 'String', '75', ...
              'Units', 'normalized', 'Position', [0.725 0.205 0.04 0.04], ...
              'Callback', @updateDisplay, ...
              'FontSize', 16);
    uicontrol(fig, 'Style', 'pushbutton', 'String', '+', ...
              'Units', 'normalized', 'Position', [0.775 0.205 0.04 0.04], ...
              'Callback', @(~,~) changeThresh(5), ...
              'FontSize', 16);
    uicontrol(fig, 'Style', 'pushbutton', 'String', '-', ...
              'Units', 'normalized', 'Position', [0.82 0.205 0.04 0.04], ...
              'Callback', @(~,~) changeThresh(-5), ...
              'FontSize', 16);

    % Save result as image
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save Result', ...
              'Units', 'normalized', ...
              'Position', [0.125 0.2 0.1 0.05], ...
              'FontSize', 16, ...
              'Callback', @saveImage);

    % Exit button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Exit', ...
              'Units', 'normalized', ...
              'Position', [0.275 0.2 0.08 0.05], ...
              'FontSize', 16, ...
              'Callback', @(~,~) close(fig));

    % Initial update
    updateDisplay();
    applyDarkTheme(fig);

    % Update selection from dropdowns
    function updateSelection(~, ~)
        val1 = popup1.Value;
        val2 = popup2.Value;
        if val1 == val2
            errordlg('Please select a different image to compare!');
            return;
        end
        img1 = imread(fullfile(imgPath, imgNames{val1}));
        img2 = imread(fullfile(imgPath, imgNames{val2}));
        set(im1Handle, 'CData', img1);
        set(im2Handle, 'CData', img2);
        updateDisplay();
    end

    % Adjust threshold up/down
    function changeThresh(delta)
        v = str2double(thresholdEdit.String);
        v = min(250, max(5, v + delta));
        thresholdEdit.String = num2str(v);
        updateDisplay();
    end

    % Update the display based on mask toggle and threshold
    function updateDisplay(~, ~)
        if toggleMask.Value == 0
            set(im2Handle, 'CData', img2);
            set(toggleMask, 'BackgroundColor', [0.1 0.15 0.25]);
            return;
        end
        threshold = str2double(thresholdEdit.String);
        threshold = min(250, max(5, threshold));
        thresholdEdit.String = num2str(threshold);

        [highlightImg, ~, ~] = visualizeDifferenceHighlight(img1, img2, threshold);
        maskOnly = highlightImg;
        set(im2Handle, 'CData', maskOnly);
        set(toggleMask, 'BackgroundColor', [0 0 0]);
    end

    % Save current right axis as PNG image
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

% Difference Highlight Visualization
function [highlightImg, diffA, diffB] = visualizeDifferenceHighlight(imgA, imgB, threshold)
    imgA = im2double(imgA);
    imgB = im2double(imgB);
    diffMap = sqrt(mean((imgA - imgB).^2, 3));
    diffA = (diffMap > 0.1) & (mean(imgA, 3) > mean(imgB, 3));
    diffB = (diffMap > 0.1) & (mean(imgB, 3) > mean(imgA, 3));
    diffA = bwareaopen(diffA, round(threshold));
    diffB = bwareaopen(diffB, round(threshold));
    temp = imoverlay(imgB, diffA, 'yellow');
    highlightImg = imoverlay(temp, diffB, 'yellow');
end