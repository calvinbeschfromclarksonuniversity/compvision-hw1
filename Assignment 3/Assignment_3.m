open estimate_transform.m
load dalekosaur/object.mat

patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
xlabel('Xo-axis'); ylabel('Yo-axis'); zlabel('Zo-axis');

ObjectDirectory = 'dalekosaur';
InputImage = imread("InputImage1.jpg");

  
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
