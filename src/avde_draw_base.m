function avde_draw_base(ds, L, cfg, p, history, highlightSource, progress)
if nargin < 6; highlightSource = ''; end
if nargin < 7; progress = []; end
Screen('FillRect', ds.win, cfg.display.background);
avde_draw_overlay(ds, L, cfg, p, history, highlightSource, progress);
end
