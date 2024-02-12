import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


function transform_image(input_image, transform_matrix, transform_type)
  result_size = transform_matrix * [size(input_image, 1), size(input_image, 2), 1];
  result = rand(RGB{N0f8}, abs(result_size[1]), abs(result_size[2]));

  inverse = inv(transform_matrix); #CHANGE THIS

  for i = 1:size(result, 1)
    for j = 1:size(result, 2)
      sample_pos = inverse * [i, j, 1];
      sample_pos = sample_pos / sample_pos[3];
      sample_pos = [abs(ceil(a)) for a in sample_pos];
      sample_pos = Int.(sample_pos);
      result[i, j] = input_image[sample_pos[1], sample_pos[2]];
    end
  end

  result
end

img = load("image3.jpg");

plt = plot(img);

scale = [2 0 0; 0 2 0; 0 0 1];
scaled = transform_image(img, scale, "scale");

reflect = [1 0 0; 0 -1 0; 0 0 1];
reflected = transform_image(img, reflect, "reflect");

scaled_plt = plot(scaled);
reflected_plt = plot(reflected);
plt_fin = plot(plt, scaled_plt, reflected_plt, layout=(3, 1), legend=true);
display(plt_fin);
