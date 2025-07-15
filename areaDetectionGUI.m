function areaDetectionGUI(imageFolder)
    % Create full-screen GUI figure
    screenSize = get(0, 'ScreenSize');
    fillAllImages(imageFolder)
    fig = figure('Name', 'Land Identification', ...
                 'NumberTitle', 'off', ...
                 'MenuBar', 'none', ...
                 'Toolbar', 'none', ...
                 'Position', screenSize);
    applyDarkTheme(fig);

    % Load image files
    imgPath = imageFolder;
    if imgPath == 0, close(fig); return; end
    files = dir(fullfile(imgPath, '*.jpg'));
    if isempty(files)
        files = dir(fullfile(imgPath, '*.png'));
    end
    if isempty(files)
        errordlg('The gallery is empty, please provide at least one image');
        close(fig); return;
    end
    imgNames = {files.name};
    imgSet = cell(1, numel(imgNames));
    for i = 1:numel(imgNames)
        imgSet{i} = imread(fullfile(imgPath, imgNames{i}));
    end

    % Determine folder name and detection mode based on folder name
    folderName = lower(imageFolder);
    [~, folderNameOnly] = fileparts(imageFolder);
    folderNameLower = lower(folderNameOnly);
    
    % Set GUI title based on dataset type
    if contains(folderNameLower, 'glacier')
        taskTitle = 'Highlight Glacier Regions';
    elseif contains(folderNameLower, 'rainforest')
        taskTitle = 'Highlight Farmland Regions';
    elseif contains(folderNameLower, 'kuwait') || contains(folderNameLower, 'dubai')
        taskTitle = 'Highlight Coastal Cities';
    elseif contains(folderNameLower, 'frauenkirche')
        taskTitle = 'Highlight Orange Roofs';
    elseif contains(folderNameLower, 'wiesn')
        taskTitle = 'Highlight vegetation area';
    else
        taskTitle = 'Highlight Custom Regions for Saving and Naming';
    end

    % Set detection mode based on folder name
    if contains(folderName, 'rainforest')
        detectionMode = 'farmland';
    elseif contains(folderName, 'glacier')
        detectionMode = 'snow';
    elseif contains(folderName, 'kuwait')
        detectionMode = 'kuwait';
    elseif contains(folderName, 'dubai')
        detectionMode = 'dubai';
    elseif contains(folderName, 'frauenkirche')
        detectionMode = 'frauenkirche';
    elseif contains(folderName, 'wiesn')
        detectionMode = 'wiesn';
    else
        detectionMode = 'cluster';
    end

    % Load the first image and run detection
    currentIdx = 1;
    currentImgName = imgNames{currentIdx};
    currentImg = im2double(imgSet{currentIdx});
    [~, props] = runDetection(currentImg, detectionMode);

    % Show current image with bounding boxes
    ax = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.15 0.25 0.7 0.7]);
    imshow(currentImg, 'Parent', ax);
    title(ax, [taskTitle, ' — ', currentImgName],'FontSize', 16, 'Interpreter', 'none');
    hold(ax, 'on');
    hRects = drawRects(props, ax, detectionMode);

    % Dropdown for selecting image
    uicontrol(fig, 'Style', 'text', 'String', 'Select Image：', ...
              'Units', 'normalized', 'Position', [0.13 0.17 0.2 0.05], ...
              'FontSize', 16, ...
              'BackgroundColor', [0.1 0.15 0.25], ...
              'ForegroundColor', [1 1 1]);
    popupImg = uicontrol(fig, 'Style', 'popupmenu', 'String', imgNames, ...
              'Units', 'normalized', 'Position', [0.3 0.165 0.2 0.05], ...
              'Value', 1, 'Callback', @updateImage, ...
              'FontSize', 14, ...
              'BackgroundColor', [0.1 0.15 0.25], ...
              'ForegroundColor', [1 1 1]);

    % Toggle button to show/hide rectangles
    toggleBtn = uicontrol(fig, 'Style', 'togglebutton', 'String', 'Hide Regions', ...
                 'Units', 'normalized', 'Position', [0.625 0.18 0.2 0.05], ...
                 'FontSize', 11, 'Value', 0, ...
                 'Callback', @toggleDisplay, ...
                 'FontSize', 16, ...
                 'BackgroundColor', [0.1 0.15 0.25], ...
                 'ForegroundColor', [1 1 1]);

    % Save image button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save Image', ...
          'Units', 'normalized', 'Position', [0.55 0.1 0.15 0.05], ...
          'FontSize', 16, 'Callback', @saveCurrentImage);

    % Exit button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Exit', ...
              'Units', 'normalized', 'Position', [0.75 0.1 0.15 0.05], ...
              'FontSize', 16, 'Callback', @(~,~) close(fig));
    applyDarkTheme(fig);

    % Display TIPS panel
    tipsPanel = uipanel(fig, ...
        'Title', 'TIPS:', ...
        'FontSize', 14, ...
        'Position', [0.85 0.45 0.1 0.4725], ...
        'BackgroundColor', [0.1 0.15 0.25], ...
        'ForegroundColor', [1 1 1]);

    % Show tips based on mode
    if strcmp(detectionMode, 'cluster')
        tipsText = {
            ' '
            '- You can manually select a cluster ID (1-6) based on your observation.'
            ' '
            '- Clusters are generated in an unsupervised manner and have no predefined semantic meaning.'
            ' '
            '- You may explore and export regions of interest using the "Save Image" button for annotation.'
        };
    else
        tipsText = {
            ' '
            '- For this dataset, we focus on specific regions.'
            ' '
            '- The title indicates which region is being analyzed.'
        };
    end

    uicontrol(tipsPanel, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.02 0.98 0.98], ...
        'FontSize', 14, ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.1 0.15 0.25], ...
        'ForegroundColor', [1 1 1], ...
        'String', tipsText);

    % Cluster selection popup (only shown for 'cluster' mode)
    if strcmp(detectionMode, 'cluster')
        uicontrol(fig, 'Style', 'text', 'String', 'Select Cluster:', ...
                  'Units', 'normalized', 'Position', [0.13 0.08 0.2 0.05], ...
                  'FontSize', 16, ...
                  'BackgroundColor', [0.1 0.15 0.25], ...
                  'ForegroundColor', [1 1 1]);        
        popupCluster = uicontrol(fig, 'Style', 'popupmenu', 'String', {'1','2','3','4','5','6'}, ...
                  'Units', 'normalized', 'Position', [0.3 0.075 0.2 0.05], ...
                  'Callback', @updateCluster, ...
                  'FontSize', 14, ...
                  'BackgroundColor', [0.1 0.15 0.25], ...
                  'ForegroundColor', [1 1 1]);
        currentTextHandle = uicontrol(fig, 'Style', 'text', ...
            'String', 'Viewing Cluster: 1', ...
            'Units', 'normalized', ...
            'Position', [0.3 0.045 0.2 0.05], ...
            'FontSize', 14, ...
            'BackgroundColor', [0.1 0.15 0.25], ...
            'ForegroundColor', [1 1 1]);
    end

    % Updates displayed image and overlays corresponding detection results
    function updateImage(~, ~)
        currentIdx = get(popupImg, 'Value');
        currentImgName = imgNames{currentIdx};
        currentImg = im2double(imgSet{currentIdx});
        [~, props, ~, ~] = runDetection(currentImg, detectionMode);

        cla(ax);
        imshow(currentImg, 'Parent', ax);
        title(ax, [taskTitle, ' — ', currentImgName],'FontSize', 16, 'Interpreter', 'none');
        hold(ax, 'on');
        if ~isempty(hRects)
            valid = isgraphics(hRects);
            delete(hRects(valid));
        end
        hRects = drawRects(props, ax, detectionMode);
        if get(toggleBtn, 'Value') == 1
            set(hRects, 'Visible', 'off');
            set(toggleBtn, 'String', 'Show Regions');
        else
            set(hRects, 'Visible', 'on');
            set(toggleBtn, 'String', 'Hide Regions');
        end
    end

    % Updates display to highlight selected cluster region
    function updateCluster(~, ~)
        if ~strcmp(detectionMode, 'cluster')
            return;
        end
        clusterID = get(popupCluster, 'Value');
        set(currentTextHandle, 'String', sprintf('Current Cluster: %d', clusterID));
        [~, ~, ~, clusterMap] = runDetection(currentImg, 'cluster');
        mask = (clusterMap == clusterID);
        mask = imopen(mask, strel('disk', 1));
        mask = imclose(mask, strel('disk', 2));
        stats = regionprops(mask, 'BoundingBox', 'Area');
        props = stats([stats.Area] > 400);
        cla(ax);
        imshow(currentImg, 'Parent', ax);
        hold(ax, 'on');
        hRects = drawRects(props, ax, 'cluster');
    end

    % Show or hide current bounding boxes (region overlays)
    function toggleDisplay(~, ~)
        if isempty(hRects)
            return;
        end
        validRects = hRects(isgraphics(hRects));

        if get(toggleBtn, 'Value') == 0
            set(validRects, 'Visible', 'on');
            set(toggleBtn, ...
               'String', 'Hide Regions', ...
               'BackgroundColor', [0.1 0.15 0.25]);
        else
            set(validRects, 'Visible', 'off');
            set(toggleBtn, ...
                'String', 'Show Regions', ...
                'BackgroundColor', [0.1 0.15 0.25]);
        end
    end

    % Saves the current annotated view as an image file (PNG or JPG)
    function saveCurrentImage(~, ~)
        F = getframe(ax);
        [file,path] = uiputfile({'*.png';'*.jpg'}, 'Save Annotated Image');
        if isequal(file,0)
            return;
        end
        imwrite(F.cdata, fullfile(path, file));
    end

end

% Calls the appropriate highlight function based on mode name
function [mask, props, clusterImg, clusterMap] = runDetection(img, mode)
    clusterImg = [];
    clusterMap = [];
    switch mode
        case 'farmland'
            [mask, props] = highlightFarmland(im2double(img));
        case 'snow'
            [mask, props] = highlightSnow(im2double(img));
        case 'kuwait'
            [mask, props] = highlightCityKuwait(im2double(img));
        case 'dubai'
            [mask, props] = highlightCityDubai(im2double(img));
        case 'frauenkirche'
            [mask, props] = highlightFrauenkircheRoof(im2double(img));
        case 'wiesn'
            [mask, props] = highlightWiesn(im2double(img));
        case 'cluster'
            nClusters = 6;
            imgSingle = im2single(img);
            clusterMap = imsegkmeans(imgSingle, nClusters);
            mask = clusterMap == 1;
            stats = regionprops(mask, 'BoundingBox', 'Area');
            props = stats([stats.Area] > 400);
            clusterImg = label2rgb(clusterMap);
        otherwise
            [mask, props] = highlightFarmland(im2double(img));
    end
end

% Detects greenish vegetation or farmland areas using HSV thresholds
function [mask, props] = highlightFarmland(img)
    hsv = rgb2hsv(img);
    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);
    cond_H = H >= 10/360 & H <= 80/360;
    cond_S = S >= 0.08 & S <= 0.63;
    cond_V = V >= 0.31 & V <= 0.94;
    mask = cond_H & cond_S & cond_V;
    mask = imopen(mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 5));
    mask = bwareaopen(mask, 300);
    props = regionprops(mask, 'BoundingBox', 'Area');
end

% Detects snow regions based on brightness and low saturation in HSV space
function [mask, props] = highlightSnow(img)
    hsvImg = rgb2hsv(img);
    S = hsvImg(:,:,2); V = hsvImg(:,:,3);
    mask = (V >= 0.85 & V <= 1.0) & (S < 0.4);
    mask = imopen(mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 6));
    mask = imfill(mask, 'holes');
    props = regionprops(mask, 'BoundingBox', 'Area');
end

% Detects Dubai-style city regions using color and texture features
function [mask, props] = highlightCityDubai(img)
    hsvImg = rgb2hsv(img);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);
    colorMask = (S < 0.4) & (V > 0.4) & (V < 0.8);
    gray = rgb2gray(img);
    textureMap = stdfilt(gray, ones(5));
    textureMask = textureMap > 0.05;
    mask = colorMask & textureMask;
    mask = imopen(mask, strel('disk', 3));
    mask = imclose(mask, strel('disk', 5));
    mask = imfill(mask, 'holes');
    props = regionprops(mask, 'BoundingBox', 'Area');
end

% Detects Kuwait-style reddish city blocks using combined HSV and RGB conditions
function [mask, props] = highlightCityKuwait(img)
    img = im2double(img);
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);
    hsv = rgb2hsv(img);
    H = hsv(:,:,1); 
    S = hsv(:,:,2); 
    V = hsv(:,:,3);
    maskH = (H >= 0.01 & H <= 0.85);
    maskS = (S >= 0.10 & S <= 0.40);
    maskV = (V >= 0.60 & V <= 0.92);
    hsvMask = maskH & maskS & maskV;
    rgbMask = (R > 100/255) & (G > 80/255) & (B > 80/255) & ...
              (R > G + 5/255) & (R > B + 5/255);
    mask = hsvMask & rgbMask;
    mask = imopen(mask, strel('disk', 3));
    mask = imclose(mask, strel('disk', 6));
    mask = imfill(mask, 'holes');
    CC = bwconncomp(mask);
    stats = regionprops(CC, 'BoundingBox', 'Area');
    minArea = 1200;
    idx = find([stats.Area] > minArea);
    props = stats(idx);
    mask = ismember(labelmatrix(CC), idx);
end

% Detects Frauenkirche roof structures based on distinctive red-green-blue contrast
function [mask, props] = highlightFrauenkircheRoof(img)
    img = im2double(img);
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);
    condR = (R > 0.35) & (R < 0.85);
    condG = (G > 0.2)  & (G < 0.55);
    condB = (B > 0.15) & (B < 0.4);
    condRG = (R > G + 0.10);
    condRB = (R > B + 0.10);
    mask = condR & condG & condB & condRG & condRB;
    mask = imopen(mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 6));
    mask = imfill(mask, 'holes');
    stats = regionprops(mask, 'BoundingBox', 'Area');
    minArea = 800;
    props = stats([stats.Area] > minArea);
    L = labelmatrix(bwconncomp(mask));
    keepLabels = ismember(L, find([stats.Area] > minArea));
    mask = keepLabels > 0;
end

% Detects vegetation in the Oktoberfest (Wiesn) scene using HSV and texture constraints
function [mask, props] = highlightWiesn(img)
    img = im2double(img);
    hsvImg = rgb2hsv(img);
    grayImg = rgb2gray(img);
    H = hsvImg(:,:,1); S = hsvImg(:,:,2); V = hsvImg(:,:,3);
    condH = (H > 0.10) & (H < 0.50);
    condS = (S > 0.05) & (S < 0.65);
    condV = (V > 0.15) & (V < 0.85);
    textureMap = stdfilt(grayImg, true(5));
    condTexture = (textureMap > 0.01) & (textureMap < 0.18);
    mask = condH & condS & condV & condTexture;
    mask = imopen(mask, strel('disk', 2));
    mask = imclose(mask, strel('disk', 5));
    mask = imfill(mask, 'holes');
    CC = bwconncomp(mask);
    stats = regionprops(CC, 'BoundingBox', 'Area');
    areaThreshold = 60;
    idx = find([stats.Area] > areaThreshold);
    props = stats(idx);
    mask = ismember(labelmatrix(CC), idx);
end

% Draws bounding boxes around detected regions with color based on detection mode
function hRects = drawRects(props, ax, mode)
    hRectsTemp = gobjects(length(props), 1);
    count = 0;
    if strcmp(mode, 'farmland')
        color = 'yellow';
    elseif strcmp(mode, 'snow')
        color = 'green';
    elseif strcmp(mode, 'dubai') || strcmp(mode, 'kuwait')
        color = 'red';
    elseif strcmp(mode, 'frauenkirche')
        color = 'cyan';
    elseif strcmp(mode, 'wiesn')
        color = [1 0.5 0];
    else
        color = 'magenta';
    end
    for k = 1:length(props)
        if props(k).Area > 300
            count = count + 1;
            hRectsTemp(count) = rectangle(ax, 'Position', props(k).BoundingBox, ...
                                          'EdgeColor', color, 'LineWidth', 1.5);
        end
    end
    hRects = hRectsTemp(1:count);
end