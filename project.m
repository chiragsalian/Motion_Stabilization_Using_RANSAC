clear all; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Getting the video
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

obj = VideoReader('VID_20150503_130115.mp4'); % shaky_car is a video from matlab
nFrames = obj.NumberOfFrames;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Video result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

writerObj = VideoWriter(strcat('new2_',obj.Name));
open(writerObj);

% cumulative starts with the identity = no change
Hcumulative = [1 0 0;0 1 0; 0 0 1];

% wait bar
wbar = waitbar(0,'Initializing waitbar...');

for k=2:nFrames
    % update waitbar
    waitbar((k/nFrames),wbar,sprintf('Progres: %0.2f%%...', (k/nFrames)*100));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Reading frames of a video
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    frame1 = read(obj,k-1);
    
    frame2 = read(obj,k);
    frame2original = frame2;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Need to transform the frames?
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % if the frame is colored, we need to turn it to grayscale
    if (size(frame1, 3) == 3)
        frame1 = rgb2gray(frame1);
        frame2 = rgb2gray(frame2);
        toGray = 1;
    end

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
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get and apply tranform
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if(pointsA.Count > 3)
        [tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'affine');
        % the transformation should also include out acumulative transform
        H = tform.T;
        Hcumulative = H * Hcumulative;
    end    
    
    % apply the transformation
    frame2transformed = imwarp(frame2original, affine2d(Hcumulative), 'OutputView', imref2d(size(frame2original)));
    
    % show
    % figure(1); imshow(frame2transformed,[]);
    
    % write, crop
    h = size(frame2transformed,1);
    w = size(frame2transformed,2);
    ch = round(0.05 * h);
    cw = round(0.05 * w);
    writeVideo(writerObj,frame2transformed((1+ch):(h-ch), (1+cw):(w-cw),:));
end

% close write video
close(writerObj);

% close wait bar
close(wbar); 
