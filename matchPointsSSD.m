function [m1,m2] = matchPoints(frame1, C1, frame2, C2, threshold) % corners 1 and corners 2
%matchPoints Perform matching between points.
%   [m1,m2] = matchPoints(frame1, C1, frame2, C2). Match points between the
%   points C1 from frame1 and points C2 from frame2. We also have the
%   thershold as an input.

% First thing, remove points that have x and y on the edges of the picture
Cond1 = C1(:,1) == 1;
Cond2 = C1(:,1) == size(frame1,2);
Cond3 = C1(:,2) == 1;
Cond4 = C1(:,2) == size(frame1,1);
CondAll = Cond1 | Cond2 | Cond3 | Cond4;
C1(CondAll,:) = [];

Cond1 = C2(:,1) == 1;
Cond2 = C2(:,1) == size(frame2,2);
Cond3 = C2(:,2) == 1;
Cond4 = C2(:,2) == size(frame2,1);
CondAll = Cond1 | Cond2 | Cond3 | Cond4;
C2(CondAll,:) = [];


C1size = size(C1,1);
C2size = size(C2,1);

matchedPoints = zeros(C1size,4);
count = 1;

% For every feature of the first frame
for i=1:C1size
    x1 = C1(i,1);
    y1 = C1(i,2);
     
    f1neighbors = [frame1(y1-1,x1-1), frame1(y1-1,x1), frame1(y1-1,x1+1),...
                   frame1(y1,  x1-1), frame1(y1,x1  ), frame1(y1,x1+1  ),...
                   frame1(y1+1,x1-1), frame1(y1+1,x1), frame1(y1+1,x1+1)];              
    
    % For every feature of the second frame frame
    SSD = zeros(C2size,1);
    for j=1:C2size
        x2 = C2(j,1);
        y2 = C2(j,2);
        f2neighbors = [frame2(y2-1,x2-1), frame2(y2-1,x2), frame2(y2-1,x2+1),...
                       frame2(y2,  x2-1), frame2(y2,x2  ), frame2(y2,x2+1  ),...
                       frame2(y2+1,x2-1), frame2(y2+1,x2), frame2(y2+1,x2+1)];
        
        % Calculate the SSD for every points
        SSD(j) = 0;
        for k=1:9
            SSD(j) = SSD(j) + (double(f1neighbors(k)) - double(f2neighbors(k)))^2;
        end
    end
    
    mins = sort(SSD(:));
    min1 = mins(1);
    min2 = mins(2);
    % Now we find the smallest SSD calculated
    [m,index] = min(SSD);
    x2 = C2(index,1);
    y2 = C2(index,2);

    % if the smallest is lower than a threshold, we select a match
    if min1/min2 < threshold
        matchedPoints(count,1) = x1;
        matchedPoints(count,2) = y1;
        matchedPoints(count,3) = x2;
        matchedPoints(count,4) = y2;
        count = count + 1;

        % Since a match happened, remove the point from C2
        C2(index,:) = [];
        C2size = size(C2,1);
    end  
end

m1 = matchedPoints(:,1:2);
m2 = matchedPoints(:,3:4);