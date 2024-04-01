load dalekosaur/object.mat

patch('vertices', Xo', 'faces', Faces, 'facecolor', 'w', 'edgecolor', 'k');
axis vis3d;
axis equal;
xlabel('Xo-axis'); ylabel('Yo-axis'); zlabel('Zo-axis');

ObjectDirectory = ' dalekosaur';

[impoints, objpoints3D] = clickPoints( InputImage1, ObjectDirectory );