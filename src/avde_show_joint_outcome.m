function e = avde_show_joint_outcome(ds, L, cfg, p, history, choice, point, imageIdx, manifest, tc, requestedOnset, progress)
% Points (+N) and a face of the chosen source's valence, chosen deck outlined.
m = manifest(imageIdx); [tex, sz] = avde_get_cached_texture(tc, imageIdx); dest = avde_fit_image_rect(sz, L.outcomeCenter);
Screen('FillRect', ds.win, cfg.display.background); Screen('FillRect', ds.win, cfg.display.border, InsetRect(dest,-8,-8));
Screen('DrawTexture', ds.win, tex, [], dest);
avde_draw_overlay(ds, L, cfg, p, history, '', progress);
if strcmp(choice.source, p.leftSource); card = L.leftCard; else; card = L.rightCard; end
Screen('FrameRect', ds.win, cfg.display.chosenBorder, InsetRect(card,-L.responseOutlineInset,-L.responseOutlineInset), cfg.runtime.lineWidth+5);
Screen('TextSize', ds.win, cfg.runtime.font.outcome);
DrawFormattedText(ds.win, sprintf('+%d', round(point)), 'center', dest(2) - L.outcomeLabelOffset, cfg.display.text);
t = avde_scheduled_flip(ds, requestedOnset);
e = avde_fill_image_timing(m, t, cfg.timing.jointOutcome);
e.choice = choice.source; e.chosenSide = choice.side; e.reward = point;
e.chosenRewardLevel = p.(['option' choice.source 'RewardLevel']); e.chosenValence = p.(['option' choice.source 'Valence']);
if p.horizon == 6; e.chosenMoreInformative = double(strcmp(choice.source, p.moreInformativeOption)); end
end

function e = avde_fill_image_timing(m, t, dur)
e = avde_fill_event_image(avde_empty_event(), m);
e = avde_apply_timing(e, t, dur);
end
