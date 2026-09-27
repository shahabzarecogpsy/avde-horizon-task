function [w, r] = PsychImaging(cmd, varargin)
w = 10; r = [0 0 1920 1080];
if numel(varargin) >= 3; r = varargin{3}; end
end
