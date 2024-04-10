open transform_Image.m

%% Estimate Transform
function A = estimateCameraProjectionMatrix( im1_points, im2_points )

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

