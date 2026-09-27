function b = avde_run_break(ds, cfg, sectionDone)
% Participant-controlled rest break after section sectionDone (1..6).
avde_mock_hint('break', sectionDone);
onset = avde_show_asset_screen(ds, cfg, 'break.png', false, sprintf('%d / %d', sectionDone, cfg.task.nSections));
avde_wait_until(onset + cfg.breaks.minimumDuration);
pressT = avde_wait_for_continue(ds); endT = GetSecs;
b = struct('afterSection',sectionDone,'afterGame',sectionDone*cfg.task.gamesPerSection,'onset',onset, ...
    'keyPressTime',pressT,'endTime',endT,'duration',endT-onset,'wallClock',avde_now());
end
