import Pkg
Pkg.add(["Images", "FileIO", "ImageMagick", "ImageIO", "Plots"])
using Images, FileIO, ImageMagick, ImageIO, Plots


img = load("image3.jpg");
plt = plot(img);
display(plt);
