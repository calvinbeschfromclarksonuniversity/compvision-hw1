load dalekosaur/object.mat

patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
xlabel('Xo-axis'); ylabel('Yo-axis'); zlabel('Zo-axis');

ObjectDirectory = 'dalekosaur';
InputImage = imread("InputImage1.png");

  
[impoints2D, objpoints3D] = clickPoints( InputImage, ObjectDirectory );
%% New section
figure;
imshow(InputImage); hold on;
plot( impoints2D(:,1), impoints2D(:,2), 'b.');

    figure;
patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
plot3( objpoints3D(:,1), objpoints3D(:,2), objpoints3D(:,3), 'b.' );


%% Estimate camera projection matrix M, estimate K,R,t
M = estimateCameraProjectionMatrix(impoints2D, objpoints3D);

A = M(:, 1:3);
b = M(:, 4);
C = A*transpose(A);

lambda = 1 / sqrt(C(3,3));
lambdasq = lambda * lambda;
xc = lambdasq * C(1, 3);
yc = lambdasq * C(2, 3);

fy = sqrt(abs(lambdasq*C(2,2) - yc.^2));
alpha = (1 / fy)*((xc.^2)*C(1,2) - xc*yc);
fx = sqrt(abs(lambdasq * C(1,1) - alpha.^2 - xc.^2));

K = [fx alpha xc; 0 fy yc; 0 0 1];

R = transpose(K) * A / sqrt(C(3,3));
if det(R) ~= 1
    R = -R;
    lambda = -lambda;
end
t = lambda * transpose(K) * b;

%% Verify

estim = zeros(size(impoints2D, 1), 2);
for i = 1:(size(estim, 1))
    homog = M * [objpoints3D(i,1); objpoints3D(i,2); objpoints3D(i,3); 1];
    estim(i, :) = homog(1:2) ./ homog(3);
end

imshow("InputImage1.png");
hold on;c

plot(estim(:, 1), estim(:, 2), 'ro', 'MarkerSize', 10)

hold off;


%% Estimate Transform
function A = estimateCameraProjectionMatrix( im_points, obj_points )

%creating matrix 
P = zeros(size(im_points, 1) * 2, 11);

%filling matrix with values of points derived via linear equations. 
for i = 1:(size(im_points, 1))
    P(i*2 - 1, :) = [-obj_points(i, 1) -obj_points(i, 2) -obj_points(i, 3) -1 0 0 0 0 im_points(i, 1)*obj_points(i,1) im_points(i, 1)*obj_points(i,2) im_points(i,1)*obj_points(i,3)];
    P(i*2, :) = [0 0 0 0 -obj_points(i, 1) -obj_points(i, 2) -obj_points(i, 3) -1 im_points(i, 2)*obj_points(i, 1) im_points(i, 2)*obj_points(i,2) im_points(i,2)*obj_points(i,3)];
end


%using SVD to find best fit homography 
if size(P,1) == 8
    [U,S,V] = svd(P);
else
    [U,S,V] = svd(P,'econ');
end

q = V(:,end);

%returning homography values
A = [q(1) q(2) q(3) q(4); q(5) q(6) q(7) q(8); q(9) q(10) q(11) 1];

end


function Transform_Image = transform_Image( input_image, transform_matrix, transform_type )
    input_image = im2double(input_image);
    input_image = im2gray(input_image);

    [h,w] = size(input_image);
    corners = [1 w w 1; 1 1 h h; 1 1 1 1];

    corners = transform_matrix * corners;
    
    xlocations = round(corners(1,:)./corners(3,:));
    ylocations = round(corners(2,:)./corners(3,:));


    xmin = 1;
    xmax = max(xlocations);

    ymin = 1;
    ymax = max(ylocations);

    display_size = [xmax - xmin + 1, ymax - ymin + 1];

    [X,Y] = meshgrid( xmin:xmax, ymin:ymax );
    coords = [X(:)';Y(:)';];
    coords = [coords(1,:);coords(2,:);ones(1, display_size(1)*display_size(2));];

    if (strcmp(transform_type, "translate"))
        inverse = transform_matrix;
        inverse(1,3)= -inverse(1,3);
        inverse(2,3)= -inverse(2,3);

     elseif (strcmp(transform_type, "rotate"))
        inverse = transform_matrix;
        inverse(1,2)= -inverse(1,2);
        inverse(2,1)= -inverse(2,1);

     elseif (strcmp(transform_type, "reflect"))
        inverse = transform_matrix;

    elseif (strcmp(transform_type, "shear"))
        inverse = transform_matrix;
        inverse(1,2)= -inverse(1,2);
        inverse(2,1)= -inverse(2,1);
   
     else 
        inverse = inv(transform_matrix);

     end
    sample_pos = inverse * coords;

    x = sample_pos(1,:)./sample_pos(3,:);
    y = sample_pos(2,:)./sample_pos(3,:);

   x = reshape( x', display_size(2), display_size(1));
   y = reshape( y', display_size(2), display_size(1));

    Transform_Image = interp2( input_image, x, y );
    
   
end