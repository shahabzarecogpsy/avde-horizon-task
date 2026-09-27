function dest = avde_fit_image_rect(imgSize, bounds)
% Fit image inside bounds while preserving original aspect ratio.
boxW=bounds(3)-bounds(1); boxH=bounds(4)-bounds(2);
scale=min(boxW/imgSize(1), boxH/imgSize(2));
w=imgSize(1)*scale; h=imgSize(2)*scale;
dest=CenterRectOnPointd([0 0 w h],mean(bounds([1 3])),mean(bounds([2 4])));
end
