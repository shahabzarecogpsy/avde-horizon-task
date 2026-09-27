function avde_draw_game_header(ds, L, cfg, p, progress)
% Top band (above decks; never overlaps faces, decks, cues or rewards):
% progress counter "g / N" (Latin digits, core games only), constant position.
% The number of free choices is conveyed only by the number of history rows
% under each source (5 rows = 1 free choice, 10 rows = 6), drawn from game onset.
if cfg.display.showProgress && ~isempty(progress)
    Screen('TextSize', ds.win, cfg.runtime.font.progress);
    DrawFormattedText(ds.win, sprintf('%d / %d', progress(1), progress(2)), 'center', 'center', cfg.display.progressText, [], [], [], [], [], L.progressRect);
end
end
