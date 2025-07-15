function applyDarkTheme(fig)
%APPLYDARKTHEME  Set dark background and white text for all components in a figure
%
%   applyDarkTheme(fig)
%
%   fig — Figure handle to apply dark theme

    darkBG = [0.1 0.15 0.25];   % black background
    darkFG = [1 1 1];   % white foreground (text)

    % Set figure background
    set(fig, 'Color', darkBG);

    % Find all objects inside figure
    allObjs = findall(fig);
    for h = allObjs'
        % Set background color if property exists
        if isprop(h, 'BackgroundColor')
            try set(h, 'BackgroundColor', darkBG); end
        end

        % Set foreground or font color if property exists
        if isprop(h, 'ForegroundColor')
            try 
                set(h, 'ForegroundColor', darkFG); 
            end
        end
        if isprop(h, 'FontColor')
            try set(h, 'FontColor', darkFG); end
        end

        % If axes, set axis and grid colors
        if strcmp(get(h, 'Type'), 'axes')
            set(h, ...
                'Color',          darkBG, ...
                'XColor',         darkFG, ...
                'YColor',         darkFG, ...
                'ZColor',         darkFG, ...
                'GridColor',      darkFG, ...
                'MinorGridColor', darkFG);
            if isgraphics(h.Title)
                h.Title.Color = darkFG;
            end
        end
    end
end
