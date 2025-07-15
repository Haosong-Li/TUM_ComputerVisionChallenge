function alignmentVisualizer(inputPath, tforms)
    % ALIGNMENTVISUALIZER - Visualize image alignment transformation process

    %% Load Images
    %% Load Images
    fileList = [...
    dir(fullfile(inputPath, '*.jpg')); ...
    dir(fullfile(inputPath, '*.jpeg')); ...
    dir(fullfile(inputPath, '*.png')); ...
    dir(fullfile(inputPath, '*.bmp')); ...
    dir(fullfile(inputPath, '*.tif')); ...
    dir(fullfile(inputPath, '*.tiff')) ...
    ];

    if isempty(fileList)
        error("No JPG/JPEG/PNG/BMP/TIF/TIFF images found in the folder.");
    end


    numImages = length(fileList);
    refImg = imread(fullfile(inputPath, fileList(1).name));
    movingImgs = cell(numImages - 1, 1);
    for i = 2:numImages
        movingImgs{i-1} = imread(fullfile(inputPath, fileList(i).name));
    end

    %% GUI Setup - Compact and Organized
    fig = figure('Name', 'Image Alignment Visualizer', ...
                 'NumberTitle', 'off', ...
                 'Position', [100, 100, 1000, 700], ...  % Fixed size instead of full screen
                 'Color', [0.96 0.96 0.96], ...  % Light gray background
                 'CloseRequestFcn', @closeFigure);

    % Main panel for images - adjusted for compact layout
    mainPanel = uipanel('Parent', fig, ...
                        'Position', [0.05, 0.3, 0.9, 0.65], ...  % More space for controls
                        'BackgroundColor', [1 1 1], ...
                        'BorderType', 'none');
    
    % Create axes with equal spacing
    ax1 = axes('Parent', mainPanel, 'Position', [0.05, 0.1, 0.4, 0.8]);
    ax2 = axes('Parent', mainPanel, 'Position', [0.55, 0.1, 0.4, 0.8]);
    
    % Add titles to axes
    title(ax1, 'Original Image', 'FontSize', 12, 'FontWeight', 'bold');
    title(ax2, 'Alignment Process', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Display images
    hOriginal = imshow(zeros(size(refImg), 'uint8'), 'Parent', ax1);
    hWarped = imshow(zeros(size(refImg), 'uint8'), 'Parent', ax2);
    hold(ax2, 'on');
    hRefOverlay = imshow(refImg, 'Parent', ax2);
    set(hRefOverlay, 'AlphaData', 0.6);
    hold(ax2, 'off');

    %% Compact Control Panel
    controlPanel = uipanel('Parent', fig, ...
                          'Position', [0.05, 0.05, 0.9, 0.2], ...  % Taller panel
                          'BackgroundColor', [0.96 0.96 0.96], ...
                          'BorderType', 'none');
    
    % Organized in two rows
    topRowY = 0.6;  % Top row position (normalized)
    bottomRowY = 0.2;  % Bottom row position (normalized)
    
    % Image selection - top row
    uicontrol('Parent', controlPanel, 'Style', 'text', ...
              'String', 'Select Image:', ...
              'Units', 'normalized', ...
              'Position', [0.05, topRowY, 0.1, 0.25], ...
              'FontSize', 10, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.96 0.96 0.96]);
    
    imgDropdown = uicontrol('Parent', controlPanel, 'Style', 'popupmenu', ...
                           'String', arrayfun(@(x) sprintf('Image %d', x), 1:numImages-1, 'UniformOutput', false), ...
                           'Units', 'normalized', ...
                           'Position', [0.16, topRowY, 0.15, 0.25], ...
                           'FontSize', 10, ...
                           'Callback', @updateDisplay);
    
    % Animation controls - top row
    playBtn = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                        'String', 'Play', ...
                        'Units', 'normalized', ...
                        'Position', [0.35, topRowY, 0.1, 0.25], ...
                        'FontSize', 10, ...
                        'Callback', @playAnimation);
    
    stopBtn = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                        'String', 'Stop', ...
                        'Units', 'normalized', ...
                        'Position', [0.46, topRowY, 0.1, 0.25], ...
                        'FontSize', 10, ...
                        'Callback', @stopAnimation);
    
    % Steps control - top row
    uicontrol('Parent', controlPanel, 'Style', 'text', ...
              'String', 'Steps:', ...
              'Units', 'normalized', ...
              'Position', [0.59, topRowY, 0.05, 0.25], ...
              'FontSize', 10, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.96 0.96 0.96]);
    
    stepsEdit = uicontrol('Parent', controlPanel, 'Style', 'edit', ...
                         'String', '30', ...
                         'Units', 'normalized', ...
                         'Position', [0.65, topRowY, 0.08, 0.25], ...
                         'FontSize', 10);
    
    % Alpha control - top row
    uicontrol('Parent', controlPanel, 'Style', 'text', ...
              'String', 'Ref Opacity:', ...
              'Units', 'normalized', ...
              'Position', [0.75, topRowY, 0.1, 0.25], ...
              'FontSize', 10, ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.96 0.96 0.96]);
    
    alphaSlider = uicontrol('Parent', controlPanel, 'Style', 'slider', ...
                           'Min', 0.1, 'Max', 1, 'Value', 0.6, ...
                           'Units', 'normalized', ...
                           'Position', [0.86, topRowY, 0.12, 0.25], ...
                           'Callback', @updateAlpha);
    
    % Exit button - bottom row (centered)
    exitBtn = uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                       'String', 'Exit', ...
                       'Units', 'normalized', ...
                       'Position', [0.45, bottomRowY, 0.1, 0.25], ...
                       'FontSize', 10, ...
                       'Callback', @closeFigure);
    
    %% Status bar - bottom row
    statusText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                          'String', 'Ready', ...
                          'Units', 'normalized', ...
                          'Position', [0.05, bottomRowY, 0.3, 0.25], ...
                          'FontSize', 10, ...
                          'HorizontalAlignment', 'left', ...
                          'BackgroundColor', [0.96 0.96 0.96]);
    applyDarkTheme(fig);

    %% Store data
    guiData.movingImgs = movingImgs;
    guiData.refImg = refImg;
    guiData.tforms = tforms;
    guiData.currentIdx = 1;
    guiData.isPlaying = false;
    guidata(fig, guiData);

    updateDisplay();

    %% Callbacks
    function updateDisplay(~, ~)
        guiData = guidata(fig);
        guiData.currentIdx = get(imgDropdown, 'Value');
        guidata(fig, guiData);
        
        % Update status
        set(statusText, 'String', sprintf('Showing Image %d/%d', guiData.currentIdx, numImages-1));

        set(hOriginal, 'CData', guiData.movingImgs{guiData.currentIdx});
        set(hWarped, 'CData', guiData.movingImgs{guiData.currentIdx});
        set(hWarped, 'AlphaData', 1);
    end

    function playAnimation(~, ~)
        guiData = guidata(fig);
        if guiData.isPlaying
            set(statusText, 'String', 'Animation already running');
            return; 
        end
        
        set(statusText, 'String', 'Playing animation...');
        guiData.isPlaying = true;
        guidata(fig, guiData);

        steps = str2double(get(stepsEdit, 'String'));
        if isnan(steps) || steps < 5
            steps = 30; % Default value
            set(stepsEdit, 'String', '30');
        end
        
        idx = guiData.currentIdx;
        tform = guiData.tforms{idx + 1};
        
        for s = 1:steps
            if ~guiData.isPlaying % Check if stopped
                break;
            end
            
            frac = (s-1)/(steps-1);
            T = interpolateTransform(affine2d(eye(3)), tform, frac);
            warped = imwarp(guiData.movingImgs{idx}, T, 'OutputView', imref2d(size(guiData.refImg)));
            set(hWarped, 'CData', warped);
            
            % Update status
            set(statusText, 'String', sprintf('Playing: %.0f%% complete', frac*100));
            pause(0.03);
        end
        
        set(statusText, 'String', 'Animation completed');
        guiData.isPlaying = false;
        guidata(fig, guiData);
    end

    function stopAnimation(~, ~)
        guiData = guidata(fig);
        guiData.isPlaying = false;
        set(statusText, 'String', 'Animation stopped');
        guidata(fig, guiData);
    end

    function updateAlpha(~, ~)
        val = get(alphaSlider, 'Value');
        set(hRefOverlay, 'AlphaData', val);
        set(statusText, 'String', sprintf('Reference opacity: %.1f', val));
    end

    function closeFigure(~, ~)
        guiData = guidata(fig);
        guiData.isPlaying = false;
        delete(fig);
    end

    function T = interpolateTransform(T1, T2, frac)
        M1 = T1.T;
        M2 = T2.T;
        M = M1 + frac * (M2 - M1);
        T = affine2d(M);
    end
end