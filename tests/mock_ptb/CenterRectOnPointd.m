function r = CenterRectOnPointd(r, x, y); w = r(3)-r(1); h = r(4)-r(2); r = [x-w/2 y-h/2 x+w/2 y+h/2]; end
