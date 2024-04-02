load dalekosaur/object.mat

patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
xlabel('Xo-axis'); ylabel('Yo-axis'); zlabel('Zo-axis');

ObjectDirectory = 'dalekosaur';
InputImage = imread("InputImage1.jpg");
InputImage = rgb2gray(InputImage);
InputImage = im2double(InputImage);

  
[impoints2D, objpoints3D] = clickPoints( InputImage, ObjectDirectory );

figure;
imshow(I); hold on;
plot( impoints2D(:,1), impoints2D(:,2), 'b.');

figure;
patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
plot3( objpoints3D(:,1), objpoints3D(:,2), objpoints3D(:,3), 'b.' );
