function avde_check_dependencies(cfg)
fns = {'Screen','KbName','KbQueueCreate','KbQueueCheck','GetKeyboardIndices','GetSecs','WaitSecs','PsychImaging'};
for i = 1:numel(fns)
    if ~any(exist(fns{i}) == [2 3 5]); error('AVDE:MissingDependency','Psychtoolbox function not found: %s', fns{i}); end %#ok<EXIST>
end
if isempty(cfg.paths.cfdRoot) || ~isfolder(cfg.paths.cfdRoot)
    error('AVDE:MissingCFD','CFD root not configured: pass it to run_AVDE or set CFD_ROOT.');
end
req = {'instr_01_goal.png','instr_02_sequence.png','instr_03_choices.png','practice_guided_1.png','practice_guided_2.png', ...
    'practice_repeat.png','comp_intro.png','comp_q1.png','comp_q2.png','comp_q3.png','comp_q4.png','comp_q5.png', ...
    'comp_pass.png','comp_fail.png','comp_stop.png','break.png','loading.png','end.png','resume.png'};
for i = 1:numel(req)
    if ~isfile(fullfile(cfg.paths.instructionsFA, req{i})); error('AVDE:MissingAsset','Missing participant screen: %s', req{i}); end
end
end
