function BlendedImgGUI(imageFolder)
    % Create the main GUI window
    fig = uifigure('Name', 'Blended Image Viewer', 'Position', [100 100 1200 700]);
    folder = imageFolder;
    
    % Load images   

    files = [...
    dir(fullfile(folder, '*.jpg')); ...
    dir(fullfile(folder, '*.jpeg')); ...
    dir(fullfile(folder, '*.png')); ...
    dir(fullfile(folder, '*.bmp')); ...
    dir(fullfile(folder, '*.tif')); ...
    dir(fullfile(folder, '*.tiff')) ...
    ];

    if isempty(files)
        uialert(fig, 'No JPG/JPEG/PNG/BMP/TIF/TIFF images found in the folder.', 'Error');
        return;
    end

    % Read all images
    numImages = numel(files);
    imgList = cell(1, numImages);
    names = cell(1, numImages);
    for i = 1:numImages
        img = imread(fullfile(folder, files(i).name));
        imgList{i} = ensureRGB(img);
        names{i} = files(i).name;
    end
    imgSize = size(imgList{1});
    
    % Create UI elements
    ax = uiaxes(fig, 'Position', [350 40 900 600]);
    ax.XTick = []; ax.YTick = [];

    % Panel for image controls
    panel = uipanel(fig, 'Title', 'Image Layers & Transparency', ...
                   'Position', [30 150 300 500], 'FontWeight', 'bold', 'FontSize', 12);
    
    % Title for the control panel
    uilabel(panel, 'Text', 'Image Controls', ...
            'Position', [10, 450, 280, 30],...
            'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'center');
    
    % Create controls for each image with increased spacing
    chkBoxes = gobjects(1, numImages);
    alphaSliders = gobjects(1, numImages);
    
    % Set starting position and increased step size
    startY = 430; % Start higher up
    stepY = 40;   % Increased spacing
    
    for i = 1:numImages
        yPos = startY - (i-1)*stepY;
        
        % Checkbox
        chkBoxes(i) = uicheckbox(panel, ...
            'Value', true, ...
            'Text','',...
            'Position', [10, yPos, 20, 22]);
        
        % Image name
        uilabel(panel, ...
            'Text', names{i}, ...
            'Position', [35, yPos, 120, 22], ...
            'FontSize',15,...
            'FontWeight','bold',...
            'HorizontalAlignment', 'left');
        
        % Alpha slider (now wider since we removed the value label)
        alphaSliders(i) = uislider(panel, ...
            'Limits', [0 1], 'Value', 1, ...
            'FontSize',12,...
            'FontWeight','bold',...
            'Position', [160, yPos + 10, 130, 3]); % Increased width to 130
        
        % Set callbacks
        chkBoxes(i).ValueChangedFcn = @(src, event) updateBlend();
        alphaSliders(i).ValueChangedFcn = @(src, event) updateBlend(); % Directly update blend
    end

    % Button panel at bottom
    btnPanel = uipanel(fig, 'Position', [30 30 300 100], ...
                      'BackgroundColor', [0.96 0.96 0.96]);
    
    % Save button
    uibutton(btnPanel, ...
        'Text', 'Save Blended Image', ...
        'FontWeight', 'bold',...
        'Position', [20, 60, 260, 30], ...
        'ButtonPushedFcn', @(btn, event) saveBlendedImage());
    
    % Exit button
    uibutton(btnPanel, ...
        'Text', 'Exit', ...
        'FontWeight', 'bold',...
        'Position', [20, 20, 260, 30], ...
        'ButtonPushedFcn', @(btn, event) close(fig));

    % Store data
    guiData.imgList = imgList;
    guiData.chkBoxes = chkBoxes;
    guiData.alphaSliders = alphaSliders;
    guiData.imgSize = imgSize;
    guiData.numImages = numImages;
    guiData.ax = ax;
    guidata(fig, guiData);

    % Handle window resizing
    % set(fig, 'SizeChangedFcn', @resizeUI);
    
    % Initial blend
    updateBlend();
    applyDarkTheme(fig);

    % Ensure RGB format for all images
    function imgRGB = ensureRGB(img)
        if size(img, 3) == 1
            imgRGB = repmat(img, [1 1 3]);
        else
            imgRGB = img;
        end
    end

    % Update blend based on selected checkboxes and alpha values
    function updateBlend()
        guiData = guidata(fig);
        selected = arrayfun(@(cb) cb.Value, guiData.chkBoxes);
        alphas = arrayfun(@(s) s.Value, guiData.alphaSliders);
        
        % Apply selection to alpha values
        effectiveAlphas = selected .* alphas;
        
        % Normalize alphas if any are non-zero
        totalAlpha = sum(effectiveAlphas);
        if totalAlpha > 0
            weights = effectiveAlphas / totalAlpha;
        else
            weights = zeros(1, guiData.numImages);
        end
        
        % Create blended image with weighted sum
        blend = zeros(guiData.imgSize, 'double');
        for k = 1:guiData.numImages
            if weights(k) > 0
                blend = blend + double(guiData.imgList{k}) * weights(k);
            end
        end
        
        % Display result
        if any(selected)
            imshow(uint8(blend), 'Parent', guiData.ax);
            guiData.ax.Title.String = 'Blended Image Preview';
            guiData.ax.Title.FontSize = 22;
            guiData.ax.Title.FontWeight = 'bold';
        else
            cla(guiData.ax);
            guiData.ax.Title.String = 'No image selected';
            guiData.ax.Title.FontSize =22; 
            guiData.ax.Title.FontWeight = 'bold';
        end
    end

    % Save the blended result
    function saveBlendedImage()
        guiData = guidata(fig);
        frame = getframe(guiData.ax);
        [file, path] = uiputfile('blended.jpg', 'Save Blended Image As');
        if ischar(file)
            imwrite(frame.cdata, fullfile(path, file));
            uialert(fig, 'Image saved successfully.', 'Success');
        end
    end

    % Handle window resizing - keep controls fixed, resize preview area
    function resizeUI(src, ~)
        % Get current figure size
        figPos = src.Position;
        figWidth = figPos(3);
        figHeight = figPos(4);
        
        % Update preview area to fill available space
        newAxWidth = max(700, figWidth - 380);  % Min width 700, expand with window
        newAxHeight = max(480, figHeight - 200); % Min height 480, expand with window
        
        % Position axes to take up remaining space
        guiData.ax.Position = [350, 150, newAxWidth, newAxHeight];
    end
end