function fillAllImages(imageFolder)
    imgPath = imageFolder;
    if imgPath == 0, close(fig); return; end
    imgFiles = dir(fullfile(imgPath, '*.jpg'));
    if isempty(imgFiles)
        imgFiles = dir(fullfile(imgPath, '*.png'));
    end
    imgNames = {imgFiles.name};
    n = numel(imgNames);
    images = cell(1, n);
    for i = 1:n
        fullPath = fullfile(imageFolder, imgNames{i});
        if exist(fullPath, 'file')
            images{i} = im2double(imread(fullPath));
        else
            error('Can not find %s', fullPath);
        end
    end

    filledImages = images;
    for i = 2:n
        filledImages{i} = fillFully(images{i}, filledImages{i-1});
    end

    for i = 1:n
        fullPath = fullfile(imageFolder, imgNames{i});
        imwrite(filledImages{i}, fullPath);
    end
end

function filled = fillFully(currImg, refImg)
    currMask = detectBlackMask(currImg);
    refMask  = ~detectBlackMask(refImg);
    validMask = currMask & refMask;
    filled = currImg;
    for c = 1:3
        currC = currImg(:,:,c);
        refC  = refImg(:,:,c);
        currC(validMask) = refC(validMask);
        filled(:,:,c) = currC;
    end
    filled = blendEdge(filled, refImg, validMask);
    filled = inpaintResidualBlack(filled);
end

function blended = blendEdge(filled, refImg, validMask)
    se = strel('disk', 6);
    dilated = imdilate(validMask, se);
    blendMask = dilated & ~validMask;

    distance = bwdist(~blendMask);
    alpha = mat2gray(distance);

    blended = filled;
    for c = 1:3
        f = filled(:,:,c);
        r = refImg(:,:,c);
        f(blendMask) = f(blendMask).*(1 - alpha(blendMask)) + r(blendMask).*alpha(blendMask);
        blended(:,:,c) = f;
    end
end

function final = inpaintResidualBlack(img)
    final = img;
    mask = detectBlackMask(img);

    for c = 1:3
        channel = img(:,:,c);
        channel = regionfill(channel, mask);
        final(:,:,c) = channel;
    end
end

function mask = detectBlackMask(img)
    threshold = 0.12;
    mask = all(img < threshold, 3);
end