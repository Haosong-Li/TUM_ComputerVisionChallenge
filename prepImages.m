% Main function of preprocessing
function imagesOutput = prepImages(imagesInput, mode)
    if nargin < 2
        mode = 'auto';
    end
    info = struct();
    [images, refIndex] = selectRefImageByStd(imagesInput);
    refImage = images{refIndex};
    if strcmpi(mode, 'auto')
        info = detectSceneType(images);
        if info.isDarkSet
            mode = 'brightness-only';
        elseif info.isGreenPlain || info.isGlacier || info.isCoast
            mode = 'auto-skip';
        else         
            mode = 'retinex';
        end
    end
    imagesOutput = cell(size(images));
    for i = 1:numel(images)
        image = images{i};
        switch lower(mode)
            case 'basic'
                for c = 1:3
                    image(:,:,c) = histeq(image(:,:,c));
                end
            case 'brightness-only'
                for c = 1:3
                    image(:,:,c) = adapthisteq(image(:,:,c));
                end
            case 'retinex'
                image = simpleRetinexRGB(image);
            case {'skip', 'auto-skip'}
            otherwise
                error('Unknow mode：%s', mode);
        end
        if ~strcmpi(mode, 'skip') && ~strcmpi(mode, 'brightness-only')
            if strcmpi(mode, 'auto-skip')
                if isfield(info, 'isGlacier')
                    if ~info.isGlacier && ~info.isGreenPlain
                        image = imhistmatch(image, refImage);
                    end
                else
                    image = imhistmatch(image, refImage);
                end
            else
                image = imhistmatch(image, refImage);
            end
        end
        image = im2double(image);
        image = imbilatfilt(image);
        image = image(1:(end-58), :, :);
        imagesOutput{i} = image;
        
    end
end

% Choose a reference image to match the brightness and style
function [imagesOut, refIdx] = selectRefImageByStd(images)
    n = numel(images);
    grayImages = cell(1, n); 
    for i = 1:n
        img = images{i};
        if size(img, 3) == 3
            grayImages{i} = rgb2gray(img);
        else
            grayImages{i} = img;
        end
    end
    stdVals = zeros(1, n);
    for i = 1:n
        stdVals(i) = std(double(grayImages{i}(:)));
    end
    meanDiffs = zeros(1, n);
    for i = 1:n
        diffs = abs(stdVals(i) - stdVals);
        diffs(i) = [];
        meanDiffs(i) = mean(diffs);
    end
    minVal = min(meanDiffs);
    minIdxList = find(meanDiffs == minVal);
    refIdx = minIdxList(end);
    imagesOut = images;
end

% Detection atlas type: plain, glacier, coast
function info = detectSceneType(imagesInput)
    numImages = numel(imagesInput);
    stdValues = zeros(1, numImages);
    blueRatios = zeros(1, numImages);
    for i = 1:numImages
        img = imagesInput{i};
        if size(img,3) == 3
            gray = rgb2gray(img);
        else
            gray = img;
        end
        if isfloat(gray)
            gray = gray * 255;
        else
            gray = double(gray);
        end
        stdValues(i) = std(gray(:));
        R = double(img(:,:,1));
        B = double(img(:,:,3));
        meanR = mean(R(:));
        meanB = mean(B(:));
        blueRatios(i) = meanB / meanR;
    end
    numHighStd = sum(stdValues >= 70);
    numLowStd  = sum(stdValues <= 30);
    numDarkStd = sum(stdValues <= 20);
    if numImages <= 2
        isGlacierSet = any(stdValues >= 70);
        isGreenSet   = any(stdValues <= 30);
        isDarkSet = any(stdValues <= 20);
    else
        isGlacierSet = numHighStd / numImages >= 0.5;
        isGreenSet = numLowStd / numImages  >= 0.5;
        isDarkSet = numDarkStd / numImages >=0.75;
    end
    avgBlueRatio = mean(blueRatios);

    if avgBlueRatio >= 0.98
        isCoastSet = true;
    else
        isCoastSet = false;
    end
    info = struct();
    info.stdValues = stdValues;
    info.isGlacier = isGlacierSet;
    info.isGreenPlain = isGreenSet;
    info.isCoast = isCoastSet;
    info.isDarkSet = isDarkSet;
end

% Retinex image enhancement method
function out = simpleRetinexRGB(imgRGB)
    if isa(imgRGB, 'double')
        imgRGB = im2uint8(imgRGB);
    end
    imgYCbCr = rgb2ycbcr(imgRGB);
    Y = imgYCbCr(:,:,1);
    Y_double = im2double(Y);
    sigmas = [15, 60, 150];
    weights = [0.3, 0.5, 0.2];
    retinex = zeros(size(Y_double));
    Y_safe = max(Y_double, 1e-6);

    for i = 1:length(sigmas)
        blurred = imgaussfilt(Y_safe, sigmas(i));
        blurred = max(blurred, 1e-6);
        retinex = retinex + weights(i) * (log(Y_safe) - log(blurred));
    end
    retinex = retinex / sum(weights);
    retinex = retinex - mean(retinex(:));
    retinex = retinex / (std(retinex(:)) + 1e-6);
    retinex = tanh(retinex);
    retinex = mat2gray(retinex);
    Y_blend = 0.1 * retinex + 0.9 * Y_double;
    imgYCbCr(:,:,1) = im2uint8(Y_blend);
    out = ycbcr2rgb(imgYCbCr);
end