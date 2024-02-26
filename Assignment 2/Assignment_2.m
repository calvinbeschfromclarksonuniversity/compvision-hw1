open transform_Image.m

%reading images in and converting to greyscale
im1 = imread("Image1.jpg");
im2 = imread("Image2.jpg");

im1 = rgb2gray(im1);
im1 = im2double(im1);

im2 = rgb2gray(im2);
im2 = im2double(im2);

%Obtaining correspondence points using the SURF function
points1 = detectSURFFeatures( im1 );
points2 = detectSURFFeatures( im2 );

%Obdtaining feature descriptors of both images
features1 = extractFeatures( im1,points1 );
features2 = extractFeatures( im2,points2 );

%matching the features to get index pairs of corresponding indicies in image one and two
indexPairs = matchFeatures( features1, features2, "Unique", true );

%isolating each image's indicies
matchedPoints1 = points1( indexPairs( :,1 ) );
matchedPoints2 = points2( indexPairs( :,2 ) );

%converting indicies to coordinates
im1_points = matchedPoints1.Location;
im2_points = matchedPoints2.Location ;


test1 = [1373 1204; 1841 1102; 1733 1213; 2099 1297];
test2 = [182 1160; 728 1055; 617 1172; 1001 1247];
a = estimateTransform(test1, test2);

%Calling the ransac function to return the transformation matrix
a1 = estimateTransformRANSAC(im1_points, im2_points);

%applying the transformation
im2_transformed = transform_Image( im2, inv(a1), "homography");

%getting rid of not a number
nanlocations = isnan( im2_transformed );
im2_transformed( nanlocations )=0;

%displaying and writing the translated image
imshow(im2_transformed);
imwrite(im2_transformed,"image2Translate.png");

%expanding image one to fit the transformed image 2
im1_expanded = zeros(size(im2_transformed));
im1_expanded(1:size(im1, 1), 1:size(im1, 2)) = im1;

%displaying and writing im1_expanded
imshow(im1_expanded);
imwrite(im1_expanded,"image1expanded.png");

%obtaining the ramp parameters
[x_overlap,y_overlap]=ginput(2);

%setting each side of the ramp overlap
overlapleft=round(x_overlap(1));
overlapright=round(x_overlap(2));

%creating the ramp 
ramp = zeros(1, size(im1_expanded,2));
ramp(1, overlapright:end) = ones(1, size(im1_expanded,2)-overlapright+1);
rangesize = overlapright-overlapleft;
ramp(1,overlapleft:overlapright) = 0:1/rangesize:1;
plot(ramp);

%applying the ramp to each image
im2_blend = im2_transformed .* repmat( ramp,size(im2_transformed,1),1 );
im1_blend = im1_expanded .* repmat( 1-ramp,size(im1_expanded,1),1 );

%combining the two images, and displaying and saving the resulting panorama
panorama = im2_blend+ im1_blend;
imshow(panorama);
imwrite(panorama,"panorama.png");

%% Estimate Transform
function A = estimateTransform( im1_points, im2_points )

%creating matrix 
P = zeros(size(im1_points, 1), 9);

%filling matrix with values of points derived via linear equations. 
for i = 1:(size(im1_points))
    P(i*2 - 1, :) = [-1*im1_points(i, 1) -1*im1_points(i, 2) -1 0 0 0 im1_points(i, 1)*im2_points(i, 1) im1_points(i, 2)*im2_points(i, 1) im2_points(i, 1)];
    P(i*2, :) = [0 0 0 -1*im1_points(i, 1) -1*im1_points(i, 2) -1 im1_points(i, 1)*im2_points(i, 2) im1_points(i, 2)*im2_points(i, 2) im2_points(i, 2)];
end


%using SVD to find best fit homography 
if size(P,1) == 8
    [U,S,V] = svd(P);
else
    [U,S,V] = svd(P,'econ');
end

q = V(:,end);

%returning homography values
A = [q(1) q(2) q(3); q(4) q(5) q(6); q(7) q(8) q(9)];

end

%% Ransac
function A_rans = estimateTransformRANSAC(im1_points, im2_points)

%number of cycles
Nransac = 10000;

%threshold for ideal values
t = 4;

%how many possible points
n = size(im1_points,1);

%min number of points
k = 4;

nbest = 0;
idxbest = [];

for i_ransac = 1:Nransac

    % randomly selecting a sample set of indices to compute A
    idx = randperm( n,k );

    %taking those poines from each image
    pts1i = im1_points(idx,:);
    pts2i = im2_points(idx,:);

    %running the estimate transform on those points
    A_test = estimateTransform( pts1i,pts2i );

    %calculating the estimated points
    pts2e = A_test * [im1_points';ones(1,n)];
    pts2e = pts2e(1:2,:) ./ pts2e(3,:);
    pts2e = pts2e';

    %calculating the distance between the calculated and actual points
    d = sqrt((pts2e(:,1)-im2_points(:,1)).^2 + (pts2e(:,2)-im2_points(:,2)).^2);

    %finding the total number of points whose error distance is lower than the threshold
    idxgood = d < t;
    ngood = sum(idxgood);

    %if the sum of points is better than the previous best, set it as best
    if ngood > nbest
        nbest = ngood;
        idxbest = idxgood;
    end
end

%removing the outliers from the best fit homography
pts1inliers = im1_points(idxbest,:);
pts2inliers = im2_points(idxbest,:);

%creating the final transform without outliers
A_rans = estimateTransform( pts1inliers, pts2inliers );

end