function Transform_Image = transform_Image( input_image, transform_matrix, transform_type )
    input_image = im2double(input_image);
    input_image = rgb2gray(input_image);

    [h,w] = size(input_image);
    corners = [1 w w 1; 1 1 h h; 1 1 1 1];

    corners = transform_matrix * corners;
    
    corners = [ceil(corners(1,:)./corners(3,:)); ceil(corners(2,:)./corners(3,:))];


    xmin = min([1, corners(1,:)]);
    xmax = max(corners(1,:));

    ymin = min([1, corners(2,:)]);
    ymax = max(corners(2,:));

    display_size = [xmax - xmin + 1, ymax - ymin + 1];

    [X,Y] = meshgrid( xmin:xmax, ymin:ymax );
    coords = [X(:)';Y(:)';];
    coords = [coords(1,:);coords(2,:);ones(1, size(coords,2));];

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