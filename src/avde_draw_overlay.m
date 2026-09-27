function avde_draw_overlay(ds, L, cfg, p, history, highlightSource, progress)
% Persistent task elements (drawn on top of any face image).
if nargin < 7; progress = []; end
Screen('FillRect', ds.win, cfg.display.panel, L.leftCard);
Screen('FrameRect', ds.win, cfg.display.border, L.leftCard, cfg.runtime.lineWidth+1);
Screen('FillRect', ds.win, cfg.display.panel, L.rightCard);
Screen('FrameRect', ds.win, cfg.display.border, L.rightCard, cfg.runtime.lineWidth+1);
if ~isempty(highlightSource)
    if strcmp(highlightSource, p.leftSource); r = L.leftCard; else; r = L.rightCard; end
    Screen('FrameRect', ds.win, cfg.display.forcedCue, InsetRect(r,-L.responseOutlineInset,-L.responseOutlineInset), cfg.runtime.lineWidth+4);
end
avde_draw_source(ds, L, cfg, 'A', p, highlightSource);
avde_draw_source(ds, L, cfg, 'B', p, highlightSource);
avde_draw_history(ds, L, cfg, p, history);
avde_draw_game_header(ds, L, cfg, p, progress);
end
