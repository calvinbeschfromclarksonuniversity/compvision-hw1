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


%% Estimate camera projection matrix M
M = estimateCameraProjectionMatrix(impoints2D, objpoints3D);


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