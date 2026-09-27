function avde_draw_source(ds, L, cfg, source, p, highlightSource)
% Neutral source marker (plain square) above each deck. As in all previous
% builds, no per-game symbol is drawn: sources are identified by screen side.
if strcmp(source, p.leftSource); rect = L.leftSource; else; rect = L.rightSource; end
isHL = nargin>=6 && ~isempty(highlightSource) && strcmp(source, highlightSource);
if isHL; border = cfg.display.forcedCue; else; border = cfg.display.sourceBorder; end
Screen('FillRect', ds.win, cfg.display.sourceFill, rect);
Screen('FrameRect', ds.win, border, rect, cfg.runtime.lineWidth + 2*double(isHL));
end
