function avde_draw_response_cues(ds, L, cfg)
% Choice cue: both decks outlined, arrows on the inner side of each deck.
inset = L.responseOutlineInset;
Screen('FrameRect', ds.win, cfg.display.highlight, InsetRect(L.leftCard,-inset,-inset), cfg.runtime.lineWidth+4);
Screen('FrameRect', ds.win, cfg.display.highlight, InsetRect(L.rightCard,-inset,-inset), cfg.runtime.lineWidth+4);
cx = L.leftCueCenter(1); cy = L.leftCueCenter(2); hw = L.responseArrowHalfW; hh = L.responseArrowHalfH;
Screen('FillPoly', ds.win, cfg.display.highlight, [cx-hw,cy; cx+hw,cy-hh; cx+hw,cy+hh], 1);
cx = L.rightCueCenter(1); cy = L.rightCueCenter(2);
Screen('FillPoly', ds.win, cfg.display.highlight, [cx+hw,cy; cx-hw,cy-hh; cx-hw,cy+hh], 1);
end
