import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


img = load("image3.jpg");

function transform_image(input_image, transform_matrix, transform_type)
  in_dims = collect(size(input_image));
  out_dims = transform_matrix * in_dims;

  if transform_type == "scale" 
    result = rand(RGB{N0f8}, out_dims[1], out_dims[2]);
  else 
    result = rand(RGB{N0f8}, out_dims[1], out_dims[2], out_dims[3]);
  end

  if transform_type == "scale"
    inverse = inv(transform_matrix);
  end

  size(result)

  for i = 1:size(result, 1)
    for j = 1:size(result, 2)
      orig = inverse * [i, j];
      orig = [ceil(a) for a in orig];
      orig = Int.(orig);
      result(i, j) = input_image(orig[0], orig[1]);
    end
  end

  result
end

scale = [2 0; 0 2];

timg = transform_image(img, scale, "scale")
plt = plot(timg);
display(plt);
