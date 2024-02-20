import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots", "Markdown", "Interpolations"])
using Images, FileIO, ImageMagick, ImageIO, Plots, Markdown, Interpolations

"""
bilinear_interpolate(image::Array{RGB{N0f8}, 2}, pos::Vector{Float64})

Performs bilinear interpolation on the given image at the given coordinates.
Returns appropriate pixel color value.

Arguments:
- `image`: The source image to interpolate.
- `pos`: The position at which to interpolate.

Returns: A pixel color object interpolated from the source image at the given coordinates.

"""
function bilinear_interpolate(image::Array{RGB{N0f8}, 2}, pos::Vector{Float64});
  pos = pos .- 0.5;
  pixels_pos = [[floor(pos[1]) ceil(pos[2])], [ceil(pos[1]) ceil(pos[2])], [floor(pos[1]) floor(pos[2])], [ceil(pos[1]) floor(pos[2])]];
  pixels = [RGB(0, 0, 0), RGB(0, 0, 0), RGB(0, 0, 0), RGB(0, 0, 0)];
  for i = 1:size(pixels)[1];
    #if(pixels_pos[i][1] < 1 || pixels_pos[i][1] > size(image)[1] || pixels_pos[i][2] < 1 || pixels_pos[i][2] > size(image)[2])
      #return RGB(0, 0, 0);
    if(pixels_pos[i][1] < 1)
      pixels_pos[i][1] = 1;
    elseif(pixels_pos[i][2] < 1)
      pixels_pos[i][2] = 1;
    elseif(pixels_pos[i][1] > size(image)[1])
      pixels_pos[i][1] = size(image)[1];
    elseif(pixels_pos[i][2] > size(image)[2])
      pixels_pos[i][2] = size(image)[2];
    else
      pixels[i] = image[Int(pixels_pos[i][1]), Int(pixels_pos[i][2])];
    end
  end

  pos = pos - (floor.(pos));

  pass_1 = pos[1] * pixels[2] + (1 - pos[1]) * pixels[1];
  pass_2 = pos[1] * pixels[4] + (1 - pos[1]) * pixels[3];
  pos[2] * pass_1 + (1 - pos[2]) * pass_2
end

"""
transform_image(input_image, transform_matrix, transform_type)

Function to transform an image. 

# Arguments
- `input_image`: The image being transformed of type jpg or png.
- `transform_matrix`: The matrix contianing the transformation.
- `transform_type`: A string representing the type of transformation (translation, scale, rotate... etc).

# Returns
The transformed image.
"""
function transform_image(input_image, transform_matrix, transform_type)
  
  # transformation matrices can't be mutated if they're to be used again to the same effect
  trans_matrix = deepcopy(transform_matrix);
  swapper = deepcopy(trans_matrix);

  #switch x and y in matrices to account for julia's [y, x] representation of image coordinates
  trans_matrix[1, 2] = swapper[2, 1];
  trans_matrix[2, 1] = swapper[1, 2];
  trans_matrix[1, 3] = swapper[2, 3];
  trans_matrix[2, 3] = swapper[1, 3];
  trans_matrix[3, 1] = swapper[3, 2];
  trans_matrix[3, 2] = swapper[3, 1];
  trans_matrix[1, 1] = swapper[2, 2];
  trans_matrix[2, 2] = swapper[1, 1];

  # create an initial array of the coordinates of the image's four corners
  corners = Array[[0, 0, 1], [size(input_image, 1), 0, 1], [0, size(input_image, 2), 1], [size(input_image, 1), size(input_image, 2), 1]];
  
  # find the transformed position of each corner
  for i = 1:4
    corners[i] = trans_matrix * corners[i];
    corners[i] = corners[i] / corners[i][3];
  end

  # get rectangular boundaries of result (image must be rectangular)
  xmin = minimum(p[1] for p in corners);
  xmax = maximum(p[1] for p in corners);
  ymin = minimum(p[2] for p in corners);
  ymax = maximum(p[2] for p in corners);
  
  # construct datastructure for transformed image
  display_size = [xmax - xmin, ymax - ymin];
  result = rand(RGB{N0f8}, round(Int, floor(display_size[1])), round(Int, floor(display_size[2]))); 

  # translation to the origin - picture files start at (0, 0) and contain no negatives
  display_translation = [1 0 -xmin; 0 1 -ymin; 0 0 1];

  # calculate inverse through required methods
  inverse = trans_matrix;
  if transform_type == "translate"
    trans_matrix[1,3] *= -1
    trans_matrix[2,3] *= -1
    inverse = trans_matrix
  elseif transform_type == "rotate"
    trans_matrix[1,2] *= -1
    trans_matrix[2,1] *= -1
    inverse = trans_matrix
  elseif transform_type == "reflect"
    inverse = trans_matrix
  elseif transform_type == "shear"
    trans_matrix[1,2] *= -1
    trans_matrix[2,1] *= -1
    inverse = trans_matrix
  else
  inverse = inv(trans_matrix); 
  end
  
  # For every pixel in the new image that needs to be filled,
  # calculate its position on the plane of the original translated
  # image from its pixel position, and use that to sample a color
  # from the original image (using bilinear interpolation)
  for i = 1:size(result)[1]
    for j = 1:size(result)[2]
      sample_pos = inv(display_translation) * [i, j, 1];
      sample_pos = inverse * sample_pos;

      if sample_pos[3] == 0
        sample_pos[3] = 1;
      end
      sample_pos = sample_pos / sample_pos[3];

      if sample_pos[1] <= 0 || sample_pos[1] > size(input_image, 1) || sample_pos[2] <= 0 || sample_pos[2] > size(input_image)[2]
        result[i, j] = RGB(0, 0, 0);
      else
        result[i, j] = bilinear_interpolate(input_image, [sample_pos[1], sample_pos[2]]);
      end
    end
  end

  result
end

meech = load("image3.jpg");
plant = load("image1.png");
room = load("image2.png");

# create transformation matrices
scale_meech = [1920/size(meech)[2] 0 0; 0 1080/size(meech)[1] 0; 0 0 1];
scale_plant = [1920/size(plant)[2] 0 0; 0 1080/size(plant)[1] 0; 0 0 1];
scale_room = [1920/size(room)[2] 0 0; 0 1080/size(room)[1] 0; 0 0 1];
reflect = [1 0 0; 0 -1 0; 0 0 1];
rotate30 = [cos(deg2rad(30)) -sin(deg2rad(30)) 0; sin(deg2rad(30)) cos(deg2rad(30)) 0; 0 0 1];
shear = [1 0.5 0; 0 1 0; 0 0 1];
scale_half = [0.5 0 0; 0 0.5 0; 0 0 1];
rotate20 = [cos(deg2rad(-20)) -sin(deg2rad(-20)) 0; sin(deg2rad(-20)) cos(deg2rad(-20)) 0; 0 0 1]
translate = [1 0 300; 0 1 500; 0 0 1];
affine_1 = [1 .4 .4; .1 1 .3; 0 0 1];
affine_2 = [2.1 -.35 -.1; -.3 .7 .3; 0 0 1];
homography_1 = [.8 .2 .3; -.1 .9 -.1; .0005 -.0005 1];
homography_2 = [29.25 13.95 20.25; 4.95 35.55 9.45; 0.045 0.09 45.0];

# transform the images and save each as an image file
save("meech1.png", transform_image(meech, scale_meech, "scale"));
save("meech2.png", transform_image(meech, reflect, "reflect"));
save("meech3.png", transform_image(meech, rotate30, "rotate"));
save("meech4.png", transform_image(meech, shear, "shear"));
save("meech5.png", transform_image(transform_image(transform_image(meech, translate, "translate"), rotate20, "rotate"), scale_half, "scale"));
save("meech6-1.png", transform_image(meech, affine_1, "affine"));
save("meech6-2.png", transform_image(meech, affine_2, "affine"));
save("meech7-1.png", transform_image(meech, homography_1, "homography"));
save("meech7-2.png", transform_image(meech, homography_2, "homography"));

save("plant1.png", transform_image(plant, scale_plant, "scale"));
save("plant2.png", transform_image(plant, reflect, "reflect"));
save("plant3.png", transform_image(plant, rotate30, "rotate"));
save("plant4.png", transform_image(plant, shear, "shear"));
save("plant5.png", transform_image(transform_image(transform_image(plant, translate, "translate"), rotate20, "rotate"), scale_half, "scale"));
save("plant6-1.png", transform_image(plant, affine_1, "affine"));
save("plant6-2.png", transform_image(plant, affine_2, "affine"));
save("plant7-1.png", transform_image(plant, homography_1, "homography"));
save("plant7-2.png", transform_image(plant, homography_2, "homography"));

save("room1.png", transform_image(room, scale_room, "scale"));
save("room2.png", transform_image(room, reflect, "reflect"));
save("room3.png", transform_image(room, rotate30, "rotate"));
save("room4.png", transform_image(room, shear, "shear"));
save("room5.png", transform_image(transform_image(transform_image(room, translate, "translate"), rotate20, "rotate"), scale_half, "scale"));
save("room6-1.png", transform_image(room, affine_1, "affine"));
save("room6-2.png", transform_image(room, affine_2, "affine"));
save("room7-1.png", transform_image(room, homography_1, "homography"));
save("room7-2.png", transform_image(room, homography_2, "homography"));


