
 im1 = im2double(InputImage);
 im1 = rgb2gray(InputImage);
 im2 = im2double(InputImage);
 im2 = rgb2gray(InputImage);

points1 = detectSURFFeatures( im1 );
features1 = extractFeatures( im1,points1 );

points2 = detectSURFFeatures( im2);
features2 = extractFeatures( im2,points1 );

indexPairs = matchFeatures( features1, features2, ’Unique’, true );

matchedPoints1 = points1( indexPairs( :,1 ) );
matchedPoints2 = points2( indexPairs( :,2 ) );

im1_points = matchedPoints1.Location ;
im2_points = matchedPoints2.Location ;

A=estimateTransform( im1_points, im2_points );