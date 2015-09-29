clear all; close all;

% cumulative starts with the identity = no change
Hcumulative = [1 0 0;0 1 0; 0 0 1];

% flags
toGray = 0;
resize = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Getting the video
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
obj = VideoReader('VID_20150503_130140.mp4');
nFrames = obj.NumberOfFrames;

frame = read(obj,11);
frame1 = frame;
frame1original = frame1;
    
frame = read(obj,12);
frame2 = frame;
frame2original = frame2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need to transform the frames?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (size(frame1, 3) == 3)
    frame1 = rgb2gray(frame1);
    frame2 = rgb2gray(frame2);
    toGray = 1;
end

if (size(frame1, 1) >= 320)
    numrowsOriginal = size(frame1, 1);
    numcolOriginal = size(frame1, 2);
    
    newRowNum = numrowsOriginal/4;
    
    frame1 = imresize(frame1, [newRowNum NaN]);
    frame2 = imresize(frame2, [newRowNum NaN]);
    resize = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Finding feature points
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ptThresh = 0.3;
    pointsA = detectFASTFeatures(frame1, 'MinContrast', ptThresh);
    pointsB = detectFASTFeatures(frame2, 'MinContrast', ptThresh);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Finding matches of those points
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [featuresA, pointsA] = extractFeatures(frame1, pointsA);
    [featuresB, pointsB] = extractFeatures(frame2, pointsB);
    
    indexPairs = matchFeatures(featuresA, featuresB);
    pointsA = pointsA(indexPairs(:, 1), :);
    pointsB = pointsB(indexPairs(:, 2), :);
    
    % If image had to go to grayscale, jsut save those points in a
    % different variable to display.
    if(toGray == 1)
        pointsAresized = pointsA;
        pointsBresized = pointsB;
    end
    
    % If the image was resized we need to transform the points. For
    % instance, if we had a picture that originally had 1080 rows we
    % resized it to have 320 rows. So the points are between 0 and 320, but
    % since we want to transform the original frame they actually have to
    % be between 0 and 1080 first.
    if (resize == 1) 
        % resized points
        numrowsTransformed = size(frame1, 1);
        numcolTransformed = size(frame1, 2);
        pointsAresized = pointsA;
        pointsBresized = pointsB;
        
        % cols
        OldRangeCol = numcolTransformed;
        NewRangeCol = numcolOriginal;
        pointsA.Location(:,1) = (((pointsA.Location(:,1)) * NewRangeCol) / OldRangeCol);
        pointsB.Location(:,1) = (((pointsB.Location(:,1)) * NewRangeCol) / OldRangeCol);
        
        % rows
        OldRangeRow = numrowsTransformed;
        NewRangeRow = numrowsOriginal;
        pointsA.Location(:,2) = (((pointsA.Location(:,2)) * NewRangeRow) / OldRangeRow);
        pointsB.Location(:,2) = (((pointsB.Location(:,2)) * NewRangeRow) / OldRangeRow);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get and apply tranform
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'affine');
    
    % the transformation should also include out acumulative transform
    H = tform.T;
    Hcumulative = H * Hcumulative;
    
    % apply the transformation
    if (resize == 1 || toGray == 1)        
        frame2transformed = imwarp(frame2original, affine2d(Hcumulative), 'OutputView', imref2d(size(frame2original)));
        pointsBmp = transformPointsForward(tform, pointsBm.Location);
        
        figure; imshow(frame1); hold on
        %plot(pointsAresized);

        figure; imshow(frame2); hold on
        %plot(pointsAresized);

        % ploting the matches
        figure; showMatchedFeatures(frame1, frame2, pointsAresized, pointsBresized);

        figure;
        showMatchedFeatures(frame1original, frame2transformed, pointsAm, pointsBmp);
        legend('A', 'B');
    else
        frame2transformed = imwarp(frame2, affine2d(Hcumulative), 'OutputView', imref2d(size(frame2)));
        pointsBmp = transformPointsForward(tform, pointsBm.Location);
        
        figure; imshow(frame1); hold on
        plot(pointsA);

        figure; imshow(frame2); hold on
        plot(pointsA);

        % ploting the matches
        figure; showMatchedFeatures(frame1, frame2, pointsA, pointsB);

        figure;
        showMatchedFeatures(frame1, frame2transformed, pointsAm, pointsBmp);
        legend('A', 'B');
    end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%