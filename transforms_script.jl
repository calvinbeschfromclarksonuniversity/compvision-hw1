import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


function transform_image(input_image, transform_matrix, transform_type)
  #result_boundary = transform_matrix * [size(input_image, 1), size(input_image, 2), 1];
  #result = rand(RGB{N0f8}, abs(result_size[1]), abs(result_size[2]));

  corners = Array[[0, 0, 1], [size(input_image, 1), 0, 1], [0, size(input_image, 2), 1], [size(input_image, 1), size(input_image, 2), 1]];
  println(corners)

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
  println(xmax)
  println(ymin)
  println(ymax)
  println("")
  println(display_translation)

  result = rand(RGB{N0f8}, round(Int, floor(display_size[1])), round(Int, floor(display_size[2]))); 
  

  inverse = inv(transform_matrix); #CHANGE THIS

  for i = 1:size(result, 1)
    for j = 1:size(result, 2)
      sample_pos = inverse * [i, j, 1];
      sample_pos = sample_pos / sample_pos[3];
      sample_pos = display_translation * sample_pos;
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

plt = plot(img);

scale = [2 0 0; 0 2 0; 0 0 1];
scaled = transform_image(img, scale, "scale");

reflect = [-1 0 0; 0 1 0; 0 0 1];
reflected = transform_image(img, reflect, "reflect");

rotate = [cos(deg2rad(30)) -sin(deg2rad(30)) 0; sin(deg2rad(30)) cos(deg2rad(30)) 0; 0 0 1];
rotated = transform_image(img, rotate, "rotate");

shear = [1 0.5 0; 0 1 0; 0 0 1];
sheared = transform_image(img, shear, "shear");

scale_half = [0.5 0 0; 0 0.5 0; 0 0 1];
rotate20 = [cos(deg2rad(20)) -sin(deg2rad(20)) 0; sin(deg2rad(20)) cos(deg2rad(20)) 0; 0 0 1]
translate = [1 0 300; 0 1 500; 0 0 1];
fived = transform_image(transform_image(transform_image(img, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");

affine_1 = [1 .4 .4; .1 1 .3; 0 0 1];
affine_1d = transform_image(img, affine_1, "affine");

affine_2 = [2.1 -.35 -.1; -.3 .7 .3; 0 0 1];
affine_2d = transform_image(img, affine_2, "affine");

homography_1 = [.8 .2 .3; -.1 .9 -.1; .0005 -.0005 1];
homography_1d = transform_image(img, homography_1, "homography");

homography_2 = [29.25 13.95 20.25; 4.95 35.55 9.45; 0.045 0.09 45.0];
homography_2d = transform_image(img, homography_2, "homography");
println(homography_2)

scaled_plt = plot(scaled);
reflected_plt = plot(reflected);
rotated_plt = plot(rotated);
sheared_plt = plot(sheared);
fived_plt = plot(fived);
affine_1d_plt = plot(affine_1d_plt);
affine_2d_plt = plot(affine_2d_plt);
homography_1d_plt = plot(homography_1d);
homography_2d_plt = plot(homograpdy_2d);

plt_fin = plot(plt, scaled_plt, reflected_plt, rotated_plt, sheared_plt, fived_plt, affine_1d_plt, affine_2d_plt, homograpdy_1d_plt, homography_2d_plt, layout=(3, 3), legend=true);
display(plt_fin);
