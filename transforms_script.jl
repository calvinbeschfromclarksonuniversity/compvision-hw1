import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


function transform_image(input_image, transform_matrix, transform_type)
  #result_boundary = transform_matrix * [size(input_image, 1), size(input_image, 2), 1];
  #result = rand(RGB{N0f8}, abs(result_size[1]), abs(result_size[2]));

  corners = transform_matrix * transpose([0 0 1;
                size(input_image)[1] 0 1;
                0 size(input_image)[2] 1;
                size(input_image)[1] size(input_image)[2] 1]);
  corners = transpose(corners);

  #get rectangular boundaries of result
  xmin = xmax = ymin = ymax = 0;
  for i in 1:size(corners)[1]
    if corners[i][1] < xmin
      xmin = corners[i][1];
    end
    if corners[i][1] > xmax
      xmax = corners[i][1];
    end
    if corners[i][2] < ymin
      ymin = corners[i][2];
    end
    if corners[i][2] > ymax
      ymax = corners[i][2];
    end
  end

  display_size = [xmax - xmin, ymax - ymin];
  display_translation = [1 0 -xmin; 0 1 -ymin; 0 0 1];

  result = rand(RGB{N0f8}, display_size[1], display_size[2]); 
  

  inverse = inv(transform_matrix); #CHANGE THIS

  for i = 1:size(result, 1)
    for j = 1:size(result, 2)
      sample_pos = inverse * [i, j, 1];
      sample_pos = sample_pos / sample_pos[3];
      if sample_pos[1] < 0 || sample_pos[1] > size(input_image, 1) || sample_pos[2] < 0 || sample_pos[2] > size(input_image)[2]
        result[i, j] = (0f, 0f, 0f);
      else
        sample_pos = display_translation * sample_pos;
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

reflect = [1 0 0; 0 -1 0; 0 0 1];
reflected = transform_image(img, reflect, "reflect");

scaled_plt = plot(scaled);
reflected_plt = plot(reflected);
plt_fin = plot(plt, scaled_plt, reflected_plt, layout=(3, 1), legend=true);
display(plt_fin);
