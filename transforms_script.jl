import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots", "Markdown", "Interpolations"])
using Images, FileIO, ImageMagick, ImageIO, Plots, Markdown, Interpolations


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
The transformed image on a plot (no standard output).
"""
function transform_image(input_image, transform_matrix, transform_type)
  
  swapper = copy(transform_matrix);
  #=
  transform_matrix[:, 1] = swapper[:, 2];
  transform_matrix[:, 2] = swapper[:, 1];
  transform_matrix = [-1 0 0; 0 -1 0; 0 0 1] * transform_matrix; =#

  #transform_matrix = transpose(transform_matrix);

  transform_matrix[1, 2] = swapper[2, 1];
  transform_matrix[2, 1] = swapper[1, 2];

  transform_matrix[1, 3] = swapper[2, 3];
  transform_matrix[2, 3] = swapper[1, 3];

  transform_matrix[3, 1] = swapper[3, 2];
  transform_matrix[3, 2] = swapper[3, 1];
  
  transform_matrix[1, 1] = swapper[2, 2];
  transform_matrix[2, 2] = swapper[1, 1];

  println(String("Swapped $(transform_type) transformation matrix: $(transform_matrix)"));
  

  #create an initial array of the coordinates of the image's four corners
  corners = Array[[0, 0, 1], [size(input_image, 1), 0, 1], [0, size(input_image, 2), 1], [size(input_image, 1), size(input_image, 2), 1]];

  for i = 1:4
    corners[i] = transform_matrix * corners[i];
    corners[i] = corners[i] / corners[i][3];
  end

  println(String("Translated corners: $(corners)"));

  #get rectangular boundaries of result
  
  xmin = minimum(p[1] for p in corners);
  xmax = maximum(p[1] for p in corners);
  ymin = minimum(p[2] for p in corners);
  ymax = maximum(p[2] for p in corners);

  display_size = [xmax - xmin, ymax - ymin];
  display_translation = [1 0 -xmin; 0 1 -ymin; 0 0 1];

  println(String("Display translation: $(display_translation)"));

  result = rand(RGB{N0f8}, round(Int, floor(display_size[1])), round(Int, floor(display_size[2]))); 

   #= inverse = transform_matrix;
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
  end =#
  
  inverse = inv(transform_matrix);

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
        result[i, j] = bilinear_interpolate(input_image, [sample_pos[1], sample_pos[2]]);
      end
    end
  end

  for i = 1:size(result)[1]
    for j = 1:size(result)[2]
      sample_pos = inv(display_translation) * [i, j, 1];
      sample_pos = inverse * sample_pos;

      if sample_pos[3] == 0
        sample_pos[3] = 1;
      end
      sample_pos = sample_pos / sample_pos[3];

      if sample_pos[1] <= 0 || sample_pos[1] > size(input_image)[1] || sample_pos[2] <= 0 || sample_pos[2] > size(input_image)[2]
        result[i, j] = RGB(0, 0, 0);
      else
        #result[i, j] = bilinear_interpolate(input_image, sample_pos);

        sample_pos = [ceil(x) for x in sample_pos];
        sample_pos = Int.(sample_pos);
        result[i, j] = input_image[sample_pos[1], sample_pos[2]];
      end
    end
  end

  result
end

meech = load("image3.jpg");
plant = load("image1.png");
room = load("image2.png");

scale_meech = [1920/size(meech)[2] 0 0; 0 1080/size(meech)[1] 0; 0 0 1];
scale_plant = [1920/size(plant)[2] 0 0; 0 1080/size(plant)[1] 0; 0 0 1];
scale_room = [1920/size(room)[2] 0 0; 0 1080/size(room)[1] 0; 0 0 1];
reflect = [-1 0 0; 0 1 0; 0 0 1];
rotate30 = [cos(deg2rad(30)) -sin(deg2rad(30)) 0; sin(deg2rad(30)) cos(deg2rad(30)) 0; 0 0 1];
shear = [1 0.5 0; 0 1 0; 0 0 1];
scale_half = [0.5 0 0; 0 0.5 0; 0 0 1];
rotate20 = [cos(deg2rad(-20)) -sin(deg2rad(-20)) 0; sin(deg2rad(-20)) cos(deg2rad(-20)) 0; 0 0 1]
translate = [1 0 300; 0 1 500; 0 0 1];
affine_1 = [1 .4 .4; .1 1 .3; 0 0 1];
affine_2 = [2.1 -.35 -.1; -.3 .7 .3; 0 0 1];
homography_1 = [.8 .2 .3; -.1 .9 -.1; .0005 -.0005 1];
homography_2 = [29.25 13.95 20.25; 4.95 35.55 9.45; 0.045 0.09 45.0];

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


"""
# The scale matrix and function calls for question 1
scale0 = [1920/size(img)[1] 0 0; 0 1080/size(img)[2] 0; 0 0 1];
scale1 = [1920/size(img1)[1] 0 0; 0 1080/size(img1)[2] 0; 0 0 1];
scale2 = [1920/size(img2)[1] 0 0; 0 1080/size(img2)[2] 0; 0 0 1];
#scaled = transform_image(img, scale0, "scale");
scaled1 = transform_image(img1, scale1, "scale");
#scaled2 = transform_image(img2, scale2, "scale");

#The reflection matrix and function calls for question 2
reflect = [-1 0 0; 0 1 0; 0 0 1];
#reflected = transform_image(img, reflect, "reflect");
reflected1 = transform_image(img1, reflect, "reflect");
#reflected2 = transform_image(img2, reflect, "reflect");

#The rotation matrix and function calls for question 3
rotate = [cos(deg2rad(-30)) -sin(deg2rad(-30)) 0; sin(deg2rad(-30)) cos(deg2rad(-30)) 0; 0 0 1];
#rotated = transform_image(img, rotate, "rotate");
rotated1 = transform_image(img1, rotate, "rotate");
#rotated2 = transform_image(img2, rotate, "rotate");

#The Shear matrix and function calls for question 4
shear = [1 0 0; 0.5 1 0; 0 0 1];
shear = [0 1 0; 1 0.5 0; 0 0 1];
shear = [1 0.5 0; 0 1 0; 0 0 1];
#sheared = transform_image(img, shear, "shear");
sheared1 = transform_image(img1, shear, "shear");
#sheared2 = transform_image(img2, shear, "shear");

#The scale, rotate, and translate matricies, followed by the function calls for question 5
scale_half = [0.5 0 0; 0 0.5 0; 0 0 1];
rotate20 = [cos(deg2rad(20)) -sin(deg2rad(20)) 0; sin(deg2rad(20)) cos(deg2rad(20)) 0; 0 0 1]
translate = [1 0 300; 0 1 500; 0 0 1];
#fived = transform_image(transform_image(transform_image(img, translate, "translate"), rotate20, "rotate"), scale_half, "scale");
fived1 = transform_image(transform_image(transform_image(img1, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");
#fived2 = transform_image(transform_image(transform_image(img2, translate, "translate"), rotate20, "rotate"), scale_half, "scale_half");

#The first affline matrix and function calls
affine_1 = [1 .4 .4; .1 1 .3; 0 0 1];
#affine_1d = transform_image(img, affine_1, "affine");
affine_1_1d = transform_image(img1, affine_1, "affine");
#affine_1_2d = transform_image(img2, affine_1, "affine");

#The second affline matrix and function calls
affine_2 = [2.1 -.35 -.1; -.3 .7 .3; 0 0 1];
#affine_2d = transform_image(img, affine_2, "affine");
affine_2_1d = transform_image(img1, affine_2, "affine");
#affine_2_2d = transform_image(img2, affine_2, "affine");

#The first homography matrix and function calls
homography_1 = [.8 .2 .3; -.1 .9 -.1; .0005 -.0005 1];
#homography_1d = transform_image(img, homography_1, "homography");
homography_1_1d = transform_image(img1, homography_1, "homography");
#homography_1_2d = transform_image(img2, homography_1, "homography");

#The second homography matrix and function calls
homography_2 = [29.25 13.95 20.25; 4.95 35.55 9.45; 0.045 0.09 45.0];
#homography_2d = transform_image(img, homography_2, "homography");
homography_2_1d = transform_image(img1, homography_2, "homography");
#homography_2_2d = transform_image(img2, homography_2, "homography");

#=
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
=#
#Creating plots for image 2
scaled1_plt = plot(scaled1, aspect_ratio=1);
reflected1_plt = plot(reflected1, aspect_ratio=1);
rotated1_plt = plot(rotated1, aspect_ratio=1);
sheared1_plt = plot(sheared1, aspect_ratio=1);
fived1_plt = plot(fived1, aspect_ratio=1);
affine_1_1d_plt = plot(affine_1_1d, aspect_ratio=1);
affine_2_1d_plt = plot(affine_2_1d, aspect_ratio=1);
homography_1_1d_plt = plot(homography_1_1d, aspect_ratio=1);
homography_2_1d_plt = plot(homography_2_1d, aspect_ratio=1);
#=
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
=#

#Displaying the image 1 plot
#plt_fin = plot(scaled_plt, reflected_plt, rotated_plt, sheared_plt, fived_plt, affine_1d_plt, affine_2d_plt, homography_1d_plt, homography_2d_plt, layout=(3, 3), legend=true);
#display(plt_fin);

#Displaying the image 2 plot
plt_fin1 = plot(scaled1_plt, reflected1_plt, rotated1_plt, sheared1_plt, fived1_plt, affine_1_1d_plt, affine_2_1d_plt, homography_1_1d_plt, homography_2_1d_plt, layout=(3, 3), legend=true);
display(plt_fin1);

#Displaying the image 3 plot 
#plt_fin2 = plot(scaled2_plt, reflected2_plt, rotated2_plt, sheared2_plt1, fived2_plt, affine_1_2d_plt, affine_2_2d_plt, homography_1_1d_plt, homography_2_1d_plt, layout=(3, 3), legend=true);
#display(plt_fin1);

#=
rotate = [cos(deg2rad(3)) -sin(deg2rad(3)) 0; sin(deg2rad(3)) cos(deg2rad(3)) 0; 0 0 1];
rotated = transform_image(img, rotate, "rotate");
plt = plot(rotated);
display(plt);
=#
"""

