im1 = imread("Image1.jpg");
im2 = imread("Image2.jpg");

im1 = rgb2gray(im1);
im1 = im2double(im1);

im2 = rgb2gray(im2);
im2 = im2double(im2);

points1 = detectSURFFeatures( im1 );
features1 = extractFeatures( im1,points1 );

points2 = detectSURFFeatures( im2 );
features2 = extractFeatures( im2,points2 );

indexPairs = matchFeatures( features1, features2, "Unique", true );

matchedPoints1 = points1( indexPairs( :,1 ) );
matchedPoints2 = points2( indexPairs( :,2 ) );

im1_points = matchedPoints1.Location;
im2_points = matchedPoints2.Location ;


%% Part 3
im1 = imread("Image1.jpg");
im2 = imread("Image2.jpg");
im1 = rgb2gray(im1);
im1 = im2double(im1);
im2 = rgb2gray(im2);
im2 = im2double(im2);
points1 = detectSURFFeatures( im1 );
features1 = extractFeatures( im1,points1 );
points2 = detectSURFFeatures( im2 );
features2 = extractFeatures( im2,points2 );
indexPairs = matchFeatures( features1, features2, "Unique", true );
matchedPoints1 = points1( indexPairs( :,1 ) );
matchedPoints2 = points2( indexPairs( :,2 ) );
im1_points = matchedPoints1.Location;
im2_points = matchedPoints2.Location;
%% testing
a = [1373 1204; 1841 1102; 1733 1213; 2099 1297];
b = [182 1160; 728 1055; 617 1172; 1001 1247];
teehee  = estimateTransform(a, b)
teeheehee = estimateTransform(b, a)
%heehee = estimateTransform(im1_points(1:4, :), im2_points(1:4, :))
%% Part 3
function A = estimateTransform( im1_points, im2_points )
    P = zeros(size(im1_points, 1), 9);
    for i = 1:(size(im1_points))
        P(i*2 - 1, :) = [-1*im1_points(i, 1) -1*im1_points(i, 2) -1 0 0 0 im1_points(i, 1)*im2_points(i, 1) im1_points(i, 2)*im2_points(i, 1) im2_points(i, 1)];
        P(i*2, :) = [0 0 0 -1*im1_points(i, 1) -1*im1_points(i, 2) -1 im1_points(i, 1)*im2_points(i, 2) im1_points(i, 2)*im2_points(i, 2) im2_points(i, 2)];
    end
    r = zeros(2 * size(im1_points, 1), 1);
    [U, S, V] = svd(P)
    min_not_zero = 57312;
    mindex = [0, 0];
    for i = 1:size(S, 1)
        for j = 1:size(S, 1)
            if (S(i, j) < min_not_zero && S(i, j) ~= 0)
                min_not_zero = S(i, j);
                mindex = [i, j];
            end
        end
    end
    q = V(mindex(2), :)
    A = [q(1) q(2) q(3); q(4) q(5) q(6); q(7) q(8) q(9)]
    
end

function Est =estimateTransformRansac( im1_points, im2_points )
    Nransac = 10000;

    n = size(im1_points, 1);

    k = 4;

    nbest = 0;
    Abest = [];
    idxbest = [];

    for i_ransac = 1:Nransac
        idx = randperm(n, k);

        pts1i = im1_points(idx, :);
        pts2i = im2_points(idx, :);

        A_test = estimateTransform(pts1i, pts2i);

        pts2estim = A*[im1_points';ones(1,n)];
        pts2estim = pts2estim(1:2,:)./pts2estim(3,:);
        pts2estim = pts2estim';
        d = sqrt(( pts2estim(:,1) -im2_points(:,1)).^2 + ( pts2estim(:,2) -im2_points(:,2)).^2);

        idxgood = d < t;
        ngood = sum(idxgood);
        Agood = A;

        if ngood > nbest;
            nbest = ngood;
            Abest = Agood;
            idxbest = idxgood;
        end
    end
    pts1inliers = im1_points(idxbest,:)
    pts2inliers = im2_points(idxbest,:)

    A_inliners = estimateTransform(pts1inliers, pts2inliers); 
end