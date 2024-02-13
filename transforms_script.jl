import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


function transform_image(input_image, transform_matrix, transform_type)
  #result_boundary = transform_matrix * [size(input_image, 1), size(input_image, 2), 1];
  #result = rand(RGB{N0f8}, abs(result_size[1]), abs(result_size[2]));

  #create an initial array of the coordinates of the image's four corners
  corners = Array[[0, 0, 1], [size(input_image, 1), 0, 1], [0, size(input_image, 2), 1], [size(input_image, 1), size(input_image, 2), 1]];
  println(corners)

  #Transform the corners 
  for i = 1:4
    corners[i] = transform_matrix * corners[i];
  end
  println(corners)

  #get rectangular boundaries of result
  
  xmin = minimum(p[1] for p in corners);
  xmax = maximum(p[1] for p in corners);
  ymin = minimum(p[2] for p in corners);
  ymax = maximum(p[2] for p in corners);

  display_size = [xmax - xmin, ymax - ymin];
  display_translation = [1 0 -xmin; 0 1 -ymin; 0 0 1];

  println(xmin)
  println(ymin)
  println(display_translation)
  println(display_size)

  result = rand(RGB{N0f8}, round(Int, floor(display_size[1])), round(Int, floor(display_size[2]))); 
  
  if transform_type == "translate"
    transform_matrix[1,3] *= -1
    transform_matrix[2,3] *= -1
    inverse = transform_matrix
  elseif transform_type == "rotate"
    transform_matrix[1,2] *= -1
    transform_matrix[2,1] *= -1
    inverse = transform_matrix
  elseif transform_type == "reflect"
    inverse = transform_matrix
  elseif transform_type == "shear"
    transform_matrix[1,2] *= -1
    transform_matrix[2,1] *= -1
    inverse = transform_matrix
  else
  inverse = inv(transform_matrix); 
  end

  for i = 1:size(result, 1)
    for j = 1:size(result, 2)
      sample_pos = inverse * [i, j, 1];
      if sample_pos[3] == 0
        sample_pos[3] = .00001;
      end
      sample_pos = display_translation * sample_pos;
      sample_pos = sample_pos / sample_pos[3];
      if sample_pos[1] <= 0 || sample_pos[1] > size(input_image, 1) || sample_pos[2] <= 0 || sample_pos[2] > size(input_image)[2]
        result[i, j] = RGB(0, 0, 0);
      else
        sample_pos = [(ceil(a)) for a in sample_pos];
        sample_pos = Int.(sample_pos);
        result[i, j] = input_image[sample_pos[1], sample_pos[2]];
      end
    end
  end

  result
end

img = load("image3.jpg");
img1 = load("image1.png");
img2 = load("image2.png");

#=
# The scale matrix and function calls for question 1
scale = [3.67346939 0 0; 0 11.2941176 0; 0 0 1];
scaled = transform_image(img, scale, "scale");
scaled1 = transform_image(img1, scale, "scale");
scaled2 = transform_image(img2, scale, "scale");

#The reflection matrix and function calls for question 2
reflect = [-1 0 0; 0 1 0; 0 0 1];
reflected = transform_image(img, reflect, "reflect");
reflected1 = transform_image(img1, reflect, "reflect");
reflected2 = transform_image(img2, reflect, "reflect");

#The rotation matrix and function calls for question 3
rotate = [cos(deg2rad(-30)) -sin(deg2rad(-30)) 0; sin(deg2rad(-30)) cos(deg2rad(-30)) 0; 0 0 1];
rotated = transform_image(img, rotate, "rotate");
rotated1 = transform_image(img1, rotate, "rotate");
rotated2 = transform_image(img2, rotate, "rotate");

#The Shear matrix and function calls for question 4
shear = [1 0.5 0; 0 1 0; 0 0 1];
sheared = transform_image(img, shear, "shear");
sheared1 = transform_image(img1, shear, "shear");
sheared2 = transform_image(img2, shear, "shear");

#The scale, rotate, and translate matricies, followed by the function calls for question 5
scale_half = [0.5 0 0; 0 0.5 0; 0 0 1];
rotate20 = [cos(deg2rad(20)) -sin(deg2rad(20)) 0; sin(deg2rad(20)) cos(deg2rad(20)) 0; 0 0 1]
translate = [1 0 300; 0 1 500; 0 0 1];
fived = transform_image(transform_image(transform_image(img, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");
fived1 = transform_image(transform_image(transform_image(img1, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");
fived2 = transform_image(transform_image(transform_image(img2, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");

#The first affline matrix and function calls
affine_1 = [1 .4 .4; .1 1 .3; 0 0 1];
affine_1d = transform_image(img, affine_1, "affine");
affine_1_1d = transform_image(img1, affine_1, "affine");
affine_1_2d = transform_image(img2, affine_1, "affine");

#The second affline matrix and function calls
affine_2 = [2.1 -.35 -.1; -.3 .7 .3; 0 0 1];
affine_2d = transform_image(img, affine_2, "affine");
affine_2_1d = transform_image(img1, affine_2, "affine");
affine_2_2d = transform_image(img2, affine_2, "affine");

#The first homography matrix and function calls
homography_1 = [.8 .2 .3; -.1 .9 -.1; .0005 -.0005 1];
homography_1d = transform_image(img, homography_1, "homography");
homography_1_1d = transform_image(img1, homography_1, "homography");
homography_1_2d = transform_image(img2, homography_1, "homography");

#The second homography matrix and function calls
homography_2 = [29.25 13.95 20.25; 4.95 35.55 9.45; 0.045 0.09 45.0];
homography_2d = transform_image(img, homography_2, "homography");
homography_2_1d = transform_image(img1, homography_2, "homography");
homography_2_2d = transform_image(img2, homography_2, "homography");
println(homography_2)

#Creating plots for image 1
scaled_plt = plot(scaled);
reflected_plt = plot(reflected);
rotated_plt = plot(rotated);
sheared_plt = plot(sheared);
fived_plt = plot(fived);
affine_1d_plt = plot(affine_1d);
affine_2d_plt = plot(affine_2d);
homography_1d_plt = plot(homography_1d);
homography_2d_plt = plot(homography_2d);

#Creating plots for image 2
scaled1_plt = plot(scaled1);
reflected1_plt = plot(reflected1);
rotated1_plt = plot(rotated1);
sheared1_plt = plot(sheared1);
fived1_plt = plot(fived1);
affine_1_1d_plt = plot(affine_1_1d);
affine_2_1d_plt = plot(affine_2_1d);
homography_1_1d_plt = plot(homography_1_1d);
homography_2_1d_plt = plot(homography_2_1d);

#creating plots for image 3
scaled2_plt = plot(scaled2);
reflected2_plt = plot(reflected2);
rotated2_plt = plot(rotated2);
sheared2_plt = plot(sheared2);
fived2_plt = plot(fived2);
affine_1_2d_plt = plot(affine_1_2d);
affine_2_2d_plt = plot(affine_2_2d);
homography_1_2d_plt = plot(homography_1_2d);
homography_2_2d_plt = plot(homography_2_2d);

#Displaying the image 1 plot
plt_fin = plot(scaled_plt, reflected_plt, rotated_plt, sheared_plt, fived_plt, affine_1d_plt, affine_2d_plt, homography_1d_plt, homography_2d_plt, layout=(3, 3), legend=true);
display(plt_fin);

#Displaying the image 2 plot
plt_fin1 = plot(scaled1_plt, reflected1_plt, rotated1_plt, sheared1_plt1, fived1_plt, affine_1_1d_plt, affine_2_1d_plt, homography_1_1d_plt, homography_2_1d_plt, layout=(3, 3), legend=true);
display(plt_fin1);

#Displaying the image 3 plot 
plt_fin2 = plot(scaled2_plt, reflected2_plt, rotated2_plt, sheared2_plt1, fived2_plt, affine_1_2d_plt, affine_2_2d_plt, homography_1_1d_plt, homography_2_1d_plt, layout=(3, 3), legend=true);
display(plt_fin1);
=#

rotate = [cos(deg2rad(-30)) -sin(deg2rad(-30)) 0; sin(deg2rad(-30)) cos(deg2rad(-30)) 0; 0 0 1];
rotated = transform_image(img, rotate, "rotate");
plt = plot(rotated);
display(plt);