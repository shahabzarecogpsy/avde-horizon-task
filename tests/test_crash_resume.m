function nFail = test_crash_resume(cfdRoot, outFile, which)
% End-to-end interruption/resume scenarios on the headless simulator.
% "Crashes" are exceptions injected at a flip, a keyboard poll, or a named
% persistence boundary (fault hooks); they are NOT OS process kills - see
% tests/tools/process_kill_test.py for real process termination.
% Data go to an isolated temp root (never the package data/ folder).
S = local_scenarios(); if nargin >= 3 && ~isempty(which); S = S(which); end
fid = fopen(outFile,'a'); nFail = 0;
for k = 1:numel(S)
    sc = S(k); env = test_env(['cr_' sc.name]); pid = sprintf('TEST_CR_%s', sc.name);
    nCrash = 0; msg = '';
    for attempt = 1:numel(sc.crashes)+1
        opts = struct('hardKill', sc.hardKill, 'failComprehensionCycles', sc.failComp);
        if attempt <= numel(sc.crashes); f = fieldnames(sc.crashes{attempt}); for q = 1:numel(f); opts.(f{q}) = sc.crashes{attempt}.(f{q}); end; end
        mock_reset(opts);
        try
            run_AVDE(pid, cfdRoot, 'development'); break;
        catch ME
            global AVDE_MOCK
            if isempty(AVDE_MOCK) || ~AVDE_MOCK.crashed; msg = ME.message; break; end
            nCrash = nCrash + 1;
        end
    end
    [ok, detail] = local_verify(env, pid, sc);
    if ~isempty(msg); ok = false; detail = [detail ' | unexpected error: ' msg]; end
    nFail = nFail + ~ok;
    fprintf(fid, '%s,%d,%d,%d,"%s"\n', sc.name, nCrash, ok, sc.hardKill, strrep(detail,'"',''''));
    fflush(fid);
    fprintf('%-34s crashes=%d ok=%d %s\n', sc.name, nCrash, ok, detail);
    clear env
end
fclose(fid);
end

function S = local_scenarios()
c = @(varargin) struct(varargin{:});
S = struct('name',{},'crashes',{},'hardKill',{},'failComp',{},'expectAborted',{},'expectPractice',{},'expectResumes',{});
add = @(S, n, cr, hk, fc, ab, pr, rs) [S c('name',n,'crashes',{cr},'hardKill',hk,'failComp',fc,'expectAborted',ab,'expectPractice',pr,'expectResumes',rs)];
S = add(S,'none',{},false,0,[],1,0);
S = add(S,'practice_hard',{c('crashGlobalFlip',150)},true,0,[],1,1);
S = add(S,'g005_preview_hard',{c('crashGame',5,'crashFlipInGame',4)},true,0,5,1,1);
S = add(S,'g040_choice_soft',{c('crashGame',40,'crashFlipInGame',19)},false,0,40,1,1);
S = add(S,'break1_hard',{c('crashInBreak',1)},true,0,[],1,1);
S = add(S,'g017_after_break_hard',{c('crashGame',17,'crashFlipInGame',1)},true,0,17,1,1);
S = add(S,'break6_soft',{c('crashInBreak',6)},false,0,[],1,1);
S = add(S,'g096_last_before_break',{c('crashGame',96,'crashFlipInGame',3)},true,0,96,1,1);
S = add(S,'g111_and_g112_hard',{c('crashGame',111,'crashFlipInGame',10),c('crashGame',112,'crashFlipInGame',2)},true,0,[111 112],1,2);
S = add(S,'comp_fail_once',{},false,1,[],2,0);
% persistence-boundary fault injection (audit item 1 and related windows)
S = add(S,'fault_resume_before_checkpoint',{c('crashGame',5,'crashFlipInGame',4),c('faultAt','resume_before_checkpoint')},true,0,5,1,1);
S = add(S,'fault_resume_after_checkpoint',{c('crashGame',5,'crashFlipInGame',4),c('faultAt','resume_after_checkpoint')},true,0,5,1,2);
S = add(S,'fault_after_commit_g020',{c('faultAt','after_commit','faultGame',20)},true,0,[],1,1);
S = add(S,'fault_after_live_start_g030',{c('faultAt','after_live_start','faultGame',30)},true,0,30,1,1);
S = add(S,'fault_break1_after_checkpoint',{c('faultAt','break_after_pre_checkpoint')},true,0,[],1,1);
end

function [ok, detail] = local_verify(env, pid, sc)
ok = false; detail = '';
f = fullfile(env.dataRoot, sprintf('%s_AVDE-v0_13-FINALPILOT-112_complete.mat',pid));
if ~isfile(f); detail = 'no complete file'; return; end
S = load(f); s = S.session; G = s.gameSummaries;
st = {G.slotStatus}; ab = find(strncmp(st,'aborted',7)); co = find(strcmp(st,'completed'));
chk = {};
chk{end+1} = {'112 slots', numel(G)==112 && isequal([G.game],1:112)};
chk{end+1} = {'aborted exactly as expected (exposed games never replayed)', isequal(ab(:)', sc.expectAborted(:)')};
chk{end+1} = {'all others completed', numel(co)==112-numel(sc.expectAborted)};
okLogs = true;
for g = co; L = s.gameLogs{g}; okLogs = okLogs && ~isempty(L) && all([L.game]==g) && strcmp(L(1).eventType,'game_reset') && strcmp(L(end).eventType,'game_end') && all(strcmp({L.attemptType},'core')); end
for g = ab; okLogs = okLogs && isempty(s.gameLogs{g}); end
chk{end+1} = {'logs belong to their game, labelled core, none duplicated', okLogs};
okP = true; for c = 1:numel(s.practice.cycles); for g = 1:numel(s.practice.cycles(c).gameLogs); L = s.practice.cycles(c).gameLogs{g}; okP = okP && all(strcmp({L.attemptType},'practice')); end; end
chk{end+1} = {'practice events labelled practice', okP};
ref = avde_build_plan(avde_config(env.root,pid,'')); chk{end+1} = {'plan preserved', strcmp(ref(1).planID, s.plan(1).planID)};
chk{end+1} = {'6 breaks, sections 1..6', numel(s.breakLog)==6 && isequal(sort([s.breakLog.afterSection]),1:6)};
chk{end+1} = {'resume log count', numel(s.resumeLog)==sc.expectResumes};
chk{end+1} = {'practice cycles', numel(s.practice.cycles)==sc.expectPractice && s.practice.cycles(end).passed};
stimOK = true;
for g = co
    L = s.gameLogs{g}; pv = L(strcmp({L.eventType},'affective_preview')); m = s.stimulusMap(g);
    want = {}; nx = struct('A',1,'B',1);
    for q = 1:4; src = m.previewOrder(q); lst = m.(['preview' src]); want{q} = s.pools.core(lst(nx.(src))).file; nx.(src) = nx.(src)+1; end %#ok<AGROW>
    stimOK = stimOK && isequal({pv.imageFile}, want);
end
chk{end+1} = {'preview faces exactly as pre-generated', stimOK};
live = dir(fullfile(env.dataRoot,'live','*.mat')); ck = dir(fullfile(env.dataRoot,'checkpoints','*.mat'));
chk{end+1} = {'recovery files cleaned', isempty(live) && isempty(ck)};
bad = cellfun(@(x) ~x{2}, chk); ok = ~any(bad);
if ok; detail = sprintf('all %d checks passed; aborted=[%s]', numel(chk), num2str(ab)); else; detail = ['FAILED: ' strjoin(cellfun(@(x) x{1}, chk(bad), 'UniformOutput', false), '; ')]; end
end
