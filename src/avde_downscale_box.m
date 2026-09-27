function out = avde_downscale_box(img, k)
% Integer box-filter (area-average) downscale by factor k; uint8 in/out.
if k <= 1; out = img; return; end
[h,w,c] = size(img);
h2 = floor(h/k); w2 = floor(w/k);
x = double(img(1:h2*k, 1:w2*k, :));
x = reshape(x, k, h2, k*w2, c);
x = reshape(mean(x,1), h2, k, w2, c);
out = uint8(round(reshape(mean(x,2), h2, w2, c)));
end
