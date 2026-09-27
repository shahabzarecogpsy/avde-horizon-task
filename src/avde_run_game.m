function [eventLog, summary] = avde_run_game(ds, L, cfg, p, reward, stim, manifest, imageCache, opts)
% Execute one game with absolute, frame-locked scheduling.
% opts: isPractice, previousGameEndOnset (NaN = no inter-game target),
%       progress ([g N] or []), liveFile ('' = no live marker writes).
%
% Disk-I/O policy inside a game: the only writes are tiny live-state markers
% issued immediately AFTER a flip whose next flip is >= 0.8 s away (last forced
% point; each joint outcome). No write occurs between a response and its
% outcome, or anywhere on the inter-game path except the per-game journal
% commit performed by the caller.
attemptType = 'core'; if opts.isPractice; attemptType = 'practice'; end
eventLog = repmat(avde_empty_event(),0,1);
summary = local_init_summary(p, reward, stim, attemptType);
t0 = GetSecs; tc = avde_preload_game_textures(ds, stim, manifest, imageCache);
texCleanup = onCleanup(@() avde_close_texture_cache(tc)); %#ok<NASGU>
summary.texturePrepSeconds = GetSecs - t0;
targets = avde_intergame_targets(opts.previousGameEndOnset, cfg);
summary.previousGameEndOnset = targets.previousGameEndOnset;
summary.gameResetTargetOnset = targets.gameResetTargetOnset;
summary.firstFaceTargetOnset = targets.firstFaceTargetOnset;
if isfinite(targets.gameResetTargetOnset)
    summary.interGamePrepSlackSeconds = targets.gameResetTargetOnset - GetSecs;
    requested = targets.gameResetTargetOnset;
else
    requested = GetSecs + cfg.timing.flipLeadFrames*ds.ifi;
end
history = nan(0,2); prog = opts.progress; smap = stim.stimulusMapID;

% 0. game_reset: empty board, progress counter visible; 5 or 10 history rows show the horizon.
avde_draw_base(ds, L, cfg, p, history, '', prog); t = avde_scheduled_flip(ds, requested);
summary.gameResetActualOnset = t.actualOnset;
e = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'game_reset',0), t, cfg.timing.gameReset); eventLog(end+1,1) = e;
if isfinite(targets.firstFaceTargetOnset); requested = targets.firstFaceTargetOnset; else; requested = t.actualOnset + cfg.timing.gameReset; end

% 1. Face preview: 4 source-linked images (X Y Y X), before any points.
nx.A = 1; nx.B = 1;
for k = 1:4
    src = stim.previewOrder(k);
    list = stim.(['preview' src]); imageIdx = list(nx.(src)); nx.(src) = nx.(src) + 1;
    [tex, sz] = avde_get_cached_texture(tc, imageIdx);
    if strcmp(src, p.leftSource); bounds = L.previewLeft; card = L.leftCard; cs = L.leftConnectorStart; isLeft = true;
    else; bounds = L.previewRight; card = L.rightCard; cs = L.rightConnectorStart; isLeft = false; end
    dest = avde_fit_image_rect(sz, bounds);
    Screen('FillRect', ds.win, cfg.display.background);
    Screen('FillRect', ds.win, cfg.display.border, InsetRect(dest,-8,-8)); Screen('DrawTexture', ds.win, tex, [], dest);
    avde_draw_overlay(ds, L, cfg, p, history, src, prog);
    cy = mean(dest([2 4])); if isLeft; ce = [dest(1) cy]; else; ce = [dest(3) cy]; end
    Screen('DrawLine', ds.win, cfg.display.border, cs(1), cs(2), ce(1), ce(2), max(3,cfg.runtime.lineWidth+1));
    t = avde_scheduled_flip(ds, requested);
    e = avde_fill_event_image(avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'affective_preview',k), t, cfg.timing.previewImage), manifest(imageIdx));
    e.note = ['preview source ' src]; eventLog(end+1,1) = e; %#ok<AGROW>
    if k == 1
        summary.firstFaceActualOnset = t.actualOnset;
        if isfinite(targets.previousGameEndOnset)
            summary.interGameEndToResetSeconds = summary.gameResetActualOnset - targets.previousGameEndOnset;
            summary.interGameEndToFirstFaceSeconds = t.actualOnset - targets.previousGameEndOnset;
            summary.interGameTimingError = summary.interGameEndToFirstFaceSeconds - cfg.timing.interGameEndToFirstFace;
            summary.interGameLate = summary.interGameTimingError > cfg.timing.interGameWarnFrames*ds.ifi;
        end
    end
    avde_draw_base(ds, L, cfg, p, history, '', prog);
    t2 = avde_scheduled_flip(ds, t.actualOnset + cfg.timing.previewImage);
    eventLog(end+1,1) = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'preview_iti',k), t2, cfg.timing.previewITI); %#ok<AGROW>
    requested = t2.actualOnset + cfg.timing.previewITI;
end

% 2. Forced (instructed, passive) point samples; no faces.
ix.A = 1; ix.B = 1;
for k = 1:4
    src = p.forcedSequence(k);
    avde_draw_base(ds, L, cfg, p, history, src, prog); t = avde_scheduled_flip(ds, requested);
    e = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'forced_cue',k), t, cfg.timing.forcedCue); e.note = ['instructed source ' src]; eventLog(end+1,1) = e; %#ok<AGROW>
    f = reward.(['forced' src]); pt = f(ix.(src)); ix.(src) = ix.(src) + 1;
    if src=='A'; history(end+1,:) = [pt NaN]; else; history(end+1,:) = [NaN pt]; end %#ok<AGROW>
    avde_draw_base(ds, L, cfg, p, history, src, prog); t2 = avde_scheduled_flip(ds, t.actualOnset + cfg.timing.forcedCue);
    e = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'forced_point',k), t2, cfg.timing.forcedPoint); e.reward = pt;
    if src=='A'; e.displayA = sprintf('%d',pt); e.displayB = 'XX'; else; e.displayA = 'XX'; e.displayB = sprintf('%d',pt); end
    eventLog(end+1,1) = e; %#ok<AGROW>
    if k == 4 && ~isempty(opts.liveFile); avde_live_save(opts.liveFile, p.game, 'forced_complete', eventLog, opts.liveIdent); end
    avde_draw_base(ds, L, cfg, p, history, '', prog); t3 = avde_scheduled_flip(ds, t2.actualOnset + cfg.timing.forcedPoint);
    eventLog(end+1,1) = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'forced_iti',k), t3, cfg.timing.forcedITI); %#ok<AGROW>
    requested = t3.actualOnset + cfg.timing.forcedITI;
end
[mA, mB] = avde_history_stats(history); mm.A = mA; mm.B = mB;
if abs((mm.(p.highOption) - mm.(p.lowOption)) - p.rewardGap) > cfg.reward.forcedGapTolerance
    error('AVDE:ForcedEvidenceRuntime','Displayed forced evidence does not equal the gap in game %d.', p.game);
end

% 3. Free choices with joint (points + face) outcomes.
nr.A = reward.nextIndexA; nr.B = reward.nextIndexB; ni.A = 1; ni.B = 1; prev = '';
for ft = 1:p.horizon
    [choice, ce] = avde_collect_choice(ds, L, cfg, p, history, requested, prog);
    e = local_merge(local_event(cfg, p, reward, history, smap, attemptType, 'free_choice',ft), ce); e.freeTrial = ft; e.previousChoice = prev; eventLog(end+1,1) = e; %#ok<AGROW>
    if ft == 1
        summary.firstRT = choice.rt; summary.firstTimeout = choice.timeout;
        if ~choice.timeout
            summary.firstChoice = choice.source;
            summary.firstChosenRewardLevel = p.(['option' choice.source 'RewardLevel']);
            summary.firstChosenValence = p.(['option' choice.source 'Valence']);
            summary.firstHighChoice = double(strcmp(choice.source, p.highOption));
            if p.horizon == 6; summary.firstChosenLessObserved = double(strcmp(choice.source, p.lessInformativeOption)); end
        end
    end
    if choice.timeout
        summary.nTimeouts = summary.nTimeouts + 1;
        history(end+1,:) = [-Inf -Inf]; %#ok<AGROW>
        avde_draw_base(ds, L, cfg, p, history, '', prog);
        ti = avde_scheduled_flip(ds, e.actualOnset + cfg.timing.choiceHardTimeout + cfg.timing.timeoutFeedbackDelay);   % after the post-deadline drain
        ie = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'outcome_iti',ft), ti, cfg.timing.outcomeITI); ie.note = 'timeout: choice consumed, no points, no face';
        eventLog(end+1,1) = ie; %#ok<AGROW>
        requested = ti.actualOnset + cfg.timing.outcomeITI; continue;
    end
    summary.nValidChoices = summary.nValidChoices + 1; prev = choice.source; s = choice.source;
    seq = reward.(['seq' s]); pt = seq(nr.(s)); nr.(s) = nr.(s) + 1;
    ol = stim.(['outcome' s]); imageIdx = ol(ni.(s)); ni.(s) = ni.(s) + 1;
    if s=='A'; history(end+1,:) = [pt NaN]; else; history(end+1,:) = [NaN pt]; end %#ok<AGROW>
    summary.pointsEarned = summary.pointsEarned + pt;
    req = max(choice.responseTime + cfg.timing.outcomeDelayFrames*ds.ifi, GetSecs + 0.5*ds.ifi);
    oe = avde_show_joint_outcome(ds, L, cfg, p, history, choice, pt, imageIdx, manifest, tc, req, prog);
    oe = local_merge(local_event(cfg, p, reward, history, smap, attemptType, 'joint_outcome',ft), oe); oe.freeTrial = ft; oe.previousChoice = e.previousChoice;
    eventLog(end+1,1) = oe; %#ok<AGROW>
    if ~isempty(opts.liveFile); avde_live_save(opts.liveFile, p.game, sprintf('outcome_%d',ft), eventLog, opts.liveIdent); end
    requested = oe.actualOnset + cfg.timing.jointOutcome;
    if ft < p.horizon
        avde_draw_base(ds, L, cfg, p, history, '', prog); ti = avde_scheduled_flip(ds, requested);
        eventLog(end+1,1) = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'outcome_iti',ft), ti, cfg.timing.outcomeITI); %#ok<AGROW>
        requested = ti.actualOnset + cfg.timing.outcomeITI;
    end
end

% 4. game_end: blank boundary; anchors the next in-section transition.
Screen('FillRect', ds.win, cfg.display.background); te = avde_scheduled_flip(ds, requested);
eventLog(end+1,1) = avde_apply_timing(local_event(cfg, p, reward, history, smap, attemptType, 'game_end',p.horizon), te, 0);
summary.gameEndOnset = te.actualOnset; summary.duration = te.actualOnset - summary.gameResetActualOnset;
end

function e = local_event(cfg, p, reward, history, smap, attemptType, type, idx)
e = avde_fill_event_design(avde_empty_event(), cfg, p, reward, history, smap);
e.attemptType = attemptType; e.eventType = type; e.eventIndex = idx;
end

function e = local_merge(e, src)
% Copy response/outcome fields into an event whose identity and design fields
% were set by local_event. Identity/design fields are never overwritten (a v0.13.2
% defect let the outcome helper's default attemptType='core' overwrite 'practice').
protect = {'attemptType','eventType','eventIndex','participantID','buildID','planID','stimulusMapID', ...
    'rewardTemplateID','game','section','sectionPosition','atomID'};
f = fieldnames(src);
for k = 1:numel(f)
    if any(strcmp(f{k}, protect)); continue; end
    v = src.(f{k});
    if isfield(e, f{k}) && ~(ischar(v) && isempty(v)) && ~(isnumeric(v) && isscalar(v) && isnan(v)); e.(f{k}) = v; end
end
end

function s = local_init_summary(p, reward, stim, attemptType)
s = avde_empty_game_summary();
f = {'game','section','sectionPosition','atomID','horizon','information','valenceCondition','pairType','planID', ...
     'highOption','optionARewardLevel','optionAValence','optionBRewardLevel','optionBValence','optionASide','optionBSide', ...
     'moreInformativeOption','lessInformativeOption','lessObservedRewardLevel','lessObservedValence','forcedSequence', ...
     'forcedOrderHL','previewOrder','rewardGap'};
for k = 1:numel(f); s.(f{k}) = p.(f{k}); end
s.attemptType = attemptType; s.stimulusMapID = stim.stimulusMapID; s.rewardTemplateID = reward.rewardTemplateID;
s.forcedMeanA = reward.forcedMeanA; s.forcedMeanB = reward.forcedMeanB; s.forcedGapObserved = reward.forcedGapObserved;
s.rewardGenerationAttempt = reward.generationAttempt;
end
