function run_AVDE(participantID, cfdRoot, runMode)
% AVDE final pilot (v0.13.3). runMode: 'participant' (default) | 'development' | 'timingtest'.
%  participant : Psychtoolbox sync tests enforced (no override); release manifest
%                verified; real Psychtoolbox required (simulator rejected); face files
%                hash-checked on resume. IDs must NOT start with TEST.
%  development : IDs MUST start with TEST; sync tests skipped; every output is
%                labelled DEVELOPMENT_NOT_SCIENTIFICALLY_VALID.
%  timingtest  : IDs MUST start with TEST_TIMING; sync tests ENFORCED; manifest
%                verified; real Psychtoolbox required; responses are generated
%                automatically (no keyboard); labelled TIMING_TEST_AUTOPILOT.
if nargin < 1 || isempty(participantID); participantID = input('Participant ID: ','s'); end
if nargin < 2; cfdRoot = ''; end
if nargin < 3 || isempty(runMode); runMode = 'participant'; end
rootDir = fileparts(mfilename('fullpath')); addpath(fullfile(rootDir,'src'),'-begin');
participantID = avde_validate_participant_id(char(participantID));
cfg = avde_config(rootDir, participantID, cfdRoot);
runMode = lower(strtrim(char(runMode)));
isTestID = strncmpi(participantID,'TEST',4);
switch runMode
    case 'participant'
        if isTestID; error('AVDE:ParticipantModeID','Participant mode forbids IDs starting with TEST.'); end
        cfg.mode = 'participant'; cfg.debug.skipSyncTests = false; dataStatus = 'PARTICIPANT'; avde_autopilot('set', false);
        avde_verify_release_manifest(rootDir); avde_require_real_ptb(rootDir);
    case 'development'
        if ~isTestID; error('AVDE:DevelopmentModeID','Development mode requires an ID starting with TEST.'); end
        avde_autopilot('set', false);
        cfg.mode = 'development'; cfg.debug.skipSyncTests = true; dataStatus = 'DEVELOPMENT_NOT_SCIENTIFICALLY_VALID';
    case 'timingtest'
        if ~strncmpi(participantID,'TEST_TIMING',11); error('AVDE:TimingModeID','Timing-test mode requires an ID starting with TEST_TIMING.'); end
        cfg.mode = 'timingtest'; cfg.debug.skipSyncTests = false; dataStatus = 'TIMING_TEST_AUTOPILOT_NOT_PARTICIPANT_DATA';
        avde_verify_release_manifest(rootDir); avde_require_real_ptb(rootDir);
        avde_autopilot('set', true); autopilotGuard = onCleanup(@() avde_autopilot('set', false)); %#ok<NASGU>
        fprintf('*** TIMING TEST: sync tests enforced; responses generated automatically (no keyboard). ***\n');
    otherwise
        error('AVDE:RunMode','runMode must be participant, development or timingtest.');
end
cfg.dataStatus = dataStatus;
if ~isempty(cfg.stim.localValidationCsv)
    if ~isfile(cfg.stim.localValidationCsv)
        error('AVDE:ValidationCsvMissing','AVDE_LOCAL_VALIDATION_CSV is set but the file does not exist: %s', cfg.stim.localValidationCsv);
    end
    cfg.stim.localValidationSha256 = avde_sha256_file(cfg.stim.localValidationCsv);
end
id = avde_build_identity(rootDir, cfg);
cfg.buildID = id.buildID; cfg.behaviourHash = id.behaviourHash; cfg.releaseManifestSha256 = id.releaseManifestSha256;
for d = {cfg.paths.output, cfg.paths.checkpoints, cfg.paths.live, cfg.paths.archive}
    if ~exist(d{1},'dir'); mkdir(d{1}); end
end
fprintf('\nAVDE BUILD %s | %s | mode %s | participant %s\n\n', cfg.buildID, cfg.protocolVersion, cfg.mode, participantID);
avde_check_dependencies(cfg);
files = avde_paths_for(cfg);
if isfile(files.final); error('AVDE:CompletedParticipant','Completed data already exist for %s. If its CSV files are missing or incomplete, run avde_reexport(''%s'').', participantID, files.final); end

% ---------------- resume decision ----------------------------------------
[hasCk, saved] = avde_find_checkpoint(files);
hasLive = isfile(files.live); hasCommits = ~isempty(dir(files.commitPattern));
resumeRun = false;
if hasCk
    if ~strcmp(saved.meta.behaviourHash, cfg.behaviourHash) || ~strcmp(saved.meta.runMode, cfg.mode)
        if strcmp(cfg.mode,'development')
            a = avde_archive_incomplete_session(cfg, files, 'incompatible_build'); fprintf('Incompatible TEST checkpoint archived: %s\n', a); hasCk = false;
        else
            error('AVDE:CheckpointIncompatible','Checkpoint was written by a different build/mode (%s). Resume is not allowed; use a new participant ID.', saved.meta.buildID);
        end
    else
        ans_ = local_ask(sprintf('Incomplete session found for %s. Resume it? [Y/n]: ', participantID));
        resumeRun = isempty(ans_) || any(strcmpi(ans_,{'y','yes'}));
        if ~resumeRun
            tok = local_ask(sprintf('Type %s to archive it and restart with the SAME ID (prior exposure will be recorded): ', cfg.resume.scientificRestartToken));
            if ~strcmp(tok, cfg.resume.scientificRestartToken); error('AVDE:ResumeDeclined','Nothing changed. Resume, or use a new participant ID.'); end
            a = avde_archive_incomplete_session(cfg, files, 'restart_confirmed'); fprintf('Archived: %s\n', a); hasCk = false;
            restartArchive = a;
        end
    end
elseif hasLive || hasCommits
    error('AVDE:OrphanRecoveryFiles','Recovery journal files exist without a checkpoint for %s. Inspect data/live before continuing.', participantID);
end

try
    if resumeRun
        session = saved; plan = session.plan; rewards = session.rewards; stim = session.stimulusMap; pools = session.pools;
        avde_verify_stimulus_pool_files(pools);
        [session, rep] = avde_replay_game_commits(session, cfg, files);
        rl = local_resume_record(session, rep);
        live = avde_live_load(files.live); liveToDelete = false;
        if ~isempty(live)
            g = live.game;
            local_check_live_identity(live, cfg, plan);
            if isfinite(g) && g <= session.lastCompletedCoreGame
                rl.liveStatus = 'stale_cleared'; liveToDelete = true;
            elseif isfinite(g) && g == session.lastCompletedCoreGame + 1
                % Approved policy: a partly exposed game is closed as ABORTED; never replayed or replaced.
                s = local_summary_from_plan(plan(g), rewards(g), stim(g));
                s.slotStatus = 'aborted_interrupted'; s.abortPhase = live.phase; s.note = 'interrupted; records retained; not replayed';
                session.gameSummaries(g) = s; session.abortedLogs{g} = live.eventLog;
                session.lastCompletedCoreGame = g; rl.liveStatus = sprintf('game_%d_aborted_at_%s', g, live.phase); liveToDelete = true;
            else
                error('AVDE:LiveStateGap','Live marker for game %d does not follow the last completed game %d.', g, session.lastCompletedCoreGame);
            end
        end
        rl.resumedAtGame = session.lastCompletedCoreGame + 1; session.resumeLog(end+1) = rl;
        session.meta.resumeCount = session.meta.resumeCount + 1;
        % Durability order: (1) persist the reconciled state (replayed journals +
        % any aborted slot), (2) only then delete the live marker. An interruption
        % between (1) and (2) leaves a marker for an already-closed slot, which the
        % next resume classifies as stale (idempotent). The abort decision can
        % therefore never be lost and an exposed game can never be replayed.
        avde_mock_hint('fault','resume_before_checkpoint');
        avde_atomic_save(files.checkpoint, 'session', session);
        avde_mock_hint('fault','resume_after_checkpoint');
        if liveToDelete; delete(files.live); end
    else
        plan = avde_build_plan(cfg); planReport = avde_validate_plan(plan, cfg);
        rewards = avde_generate_reward_templates(plan, cfg, 'core'); rewardAudit = avde_audit_reward_schedule(plan, rewards, cfg);
        manifest = avde_build_cfd_manifest(cfg); pools = avde_partition_manifest(manifest, cfg);
        stim = avde_assign_stimuli_to_plan(plan, pools.core, cfg, 'core'); stimReport = avde_validate_stimulus_schedule(plan, stim, pools.core, cfg);
    end

    ds = avde_setup_display(cfg); cleanupObj = onCleanup(@() avde_cleanup(ds)); %#ok<NASGU>
    cfg = avde_finalize_runtime_config(cfg, ds); L = avde_build_layout(ds.winRect, cfg);
    avde_show_asset_screen(ds, cfg, 'loading.png', false);
    imageCache = avde_build_image_cache(ds, cfg, {pools.practice, pools.core}, L);

    if ~resumeRun
        session = local_init_session(cfg, id, dataStatus, plan, planReport, rewards, rewardAudit, stim, stimReport, pools, ds);
        if exist('restartArchive','var'); session.meta.restartArchive = restartArchive; end
        avde_atomic_save(files.checkpoint, 'session', session);
    else
        session.displayHistory{end+1} = local_display_record(ds);
        avde_show_asset_screen(ds, cfg, 'resume.png', true);
    end

    % ---------------- instructions + practice (restarted if interrupted) ----
    if ~strcmp(session.stage,'core')
        avde_show_instructions(ds, cfg);
        [ok, practice] = avde_run_practice(ds, L, cfg, pools.practice, imageCache);
        session.practice = practice;
        if ~ok
            session.stage = 'practice_failed'; avde_atomic_save(files.checkpoint, 'session', session);
            error('AVDE:PracticeGateFailed','Comprehension check not passed after %d cycles.', cfg.practice.maxCycles);
        end
        session.stage = 'core'; avde_atomic_save(files.checkpoint, 'session', session);
    end

    % ---------------- core games ------------------------------------------
    gps = cfg.task.gamesPerSection; N = cfg.task.nGames;
    last = session.lastCompletedCoreGame;
    if last > 0 && mod(last,gps)==0 && last < N && ~any([session.breakLog.afterSection]==last/gps)
        session = local_break(session, ds, cfg, files, last/gps);        % break owed before resuming
    end
    prevEnd = NaN;                                                        % never carry timing across a resume/break
    for g = session.lastCompletedCoreGame+1 : N
        avde_mock_hint('game', g);
        liveIdent = struct('participantID',cfg.participantID,'behaviourHash',cfg.behaviourHash,'planID',plan(1).planID);
        avde_live_save(files.live, g, 'game_started', repmat(avde_empty_event(),0,1), liveIdent);
        avde_mock_hint('fault','after_live_start');
        opts = struct('isPractice',false,'previousGameEndOnset',prevEnd,'progress',[g N],'liveFile',files.live,'liveIdent',liveIdent);
        [gl, gs] = avde_run_game(ds, L, cfg, plan(g), rewards(g), stim(g), pools.core, imageCache, opts);
        avde_game_commit_save(cfg, files, g, gl, gs);                     % bounded-size journal (the only per-game write)
        avde_mock_hint('fault','after_commit');
        delete(files.live);
        session.gameLogs{g} = gl; session.gameSummaries(g) = gs; session.lastCompletedCoreGame = g;
        prevEnd = gs.gameEndOnset;
        if cfg.debug.verbose && mod(g,gps)==0; fprintf('  core game %d/%d done (%s)\n', g, N, avde_now()); end
        if mod(g,gps)==0 && g < N
            session = local_break(session, ds, cfg, files, g/gps); prevEnd = NaN;
        end
    end

    % ---------------- completion ------------------------------------------
    session.completed = true; session.stage = 'complete'; session.meta.endTime = avde_now();
    session.qc = avde_session_qc(session, cfg);
    avde_atomic_save(files.final, 'session', session);
    avde_export_csv(session, cfg, files);
    avde_game_commit_clear(files); delete(files.checkpoint);
    avde_show_asset_screen(ds, cfg, 'end.png', false); WaitSecs(2);
catch ME
    if exist('session','var') && isstruct(session) && ~avde_mock_hint('hardkill')
        try
            session.lastError = struct('identifier',ME.identifier,'message',ME.message,'time',avde_now());
            avde_atomic_save(files.error, 'session', session);
        catch
        end
    end
    rethrow(ME);
end
end

% =========================================================================
function session = local_break(session, ds, cfg, files, sectionDone)
% Full checkpoint at the break (participant-paced; outside every timed path),
% then the participant-controlled break itself.
session.stage = 'core'; avde_atomic_save(files.checkpoint, 'session', session);
avde_mock_hint('fault','break_after_pre_checkpoint');
b = avde_run_break(ds, cfg, sectionDone);
if isempty(session.breakLog); session.breakLog = b; else; session.breakLog(end+1) = b; end
avde_atomic_save(files.checkpoint, 'session', session);
end

function session = local_init_session(cfg, id, dataStatus, plan, planReport, rewards, rewardAudit, stim, stimReport, pools, ds)
session = struct();
session.meta = struct('participantID',cfg.participantID,'version',cfg.version,'protocolVersion',cfg.protocolVersion, ...
    'releaseID',cfg.releaseID,'buildID',id.buildID,'behaviourHash',id.behaviourHash,'releaseManifestSha256',id.releaseManifestSha256, ...
    'runMode',cfg.mode,'dataStatus',dataStatus,'dataRoot',cfg.paths.output,'syncTestsSkipped',logical(cfg.debug.skipSyncTests), ...
    'randomSeed',cfg.randomSeed,'planID',plan(1).planID,'planHash',avde_plan_hash(plan),'stimulusMapID',stim(1).stimulusMapID, ...
    'localValidationSha256',cfg.stim.localValidationSha256,'startTime',avde_now(),'endTime','','resumeCount',0,'restartArchive','');
session.environment = avde_environment_snapshot();
session.config = cfg;
session.plan = plan; session.planValidation = planReport;
session.rewards = rewards; session.rewardAudit = rewardAudit;
session.stimulusMap = stim; session.stimulusValidation = stimReport;
session.pools = local_strip_pools(pools);
session.displayHistory = {local_display_record(ds)};
session.stage = 'startup'; session.completed = false;
session.practice = struct('cycles',struct('cycle',{},'plan',{},'gameLogs',{},'gameSummaries',{},'comprehension',{},'passed',{}));
session.lastCompletedCoreGame = 0;
session.gameLogs = cell(cfg.task.nGames,1); session.abortedLogs = cell(cfg.task.nGames,1);
s = repmat(avde_empty_game_summary(), cfg.task.nGames, 1);
for g = 1:cfg.task.nGames; s(g) = local_summary_from_plan(plan(g), rewards(g), stim(g)); s(g).slotStatus = 'pending'; end
session.gameSummaries = s;
session.breakLog = struct('afterSection',{},'afterGame',{},'onset',{},'keyPressTime',{},'endTime',{},'duration',{},'wallClock',{});
session.resumeLog = struct('time',{},'checkpointStage',{},'lastGameInCheckpoint',{},'journalReplayed',{},'liveStatus',{},'resumedAtGame',{});
end

function pools = local_strip_pools(pools)
% Keep identifiers and all item-level covariates (no pixels).
keep = {'path','file','sha256','expression','modelID','identityKey','valenceClass','race','gender','localValence','localArousal', ...
    'expressionIntensity','expressionRecognition','threat','approachAvoidance','matchStratum','attractiveness','perceivedAge','assignedCoreValence'};
for f = {'practice','core'}
    M = pools.(f{1}); drop = setdiff(fieldnames(M), keep);
    pools.(f{1}) = rmfield(M, drop);
end
end

function r = local_display_record(ds)
r = struct('width',ds.width,'height',ds.height,'ifi',ds.ifi,'nominalHz',ds.nominalHz, ...
    'keyboardDeviceIndex',ds.keyboardDeviceIndex,'keyboardName',ds.keyboardName,'syncTestsSkipped',ds.syncTestsSkipped,'time',avde_now());
end

function rl = local_resume_record(session, rep)
rl = struct('time',avde_now(),'checkpointStage',session.stage,'lastGameInCheckpoint',session.lastCompletedCoreGame-rep.nReplayed, ...
    'journalReplayed',rep.nReplayed,'liveStatus','none','resumedAtGame',NaN);
end

function s = local_summary_from_plan(p, reward, stim)
s = avde_empty_game_summary();
f = {'game','section','sectionPosition','atomID','horizon','information','valenceCondition','pairType','planID', ...
     'highOption','optionARewardLevel','optionAValence','optionBRewardLevel','optionBValence','optionASide','optionBSide', ...
     'moreInformativeOption','lessInformativeOption','lessObservedRewardLevel','lessObservedValence','forcedSequence', ...
     'forcedOrderHL','previewOrder','rewardGap'};
for k = 1:numel(f); s.(f{k}) = p.(f{k}); end
s.stimulusMapID = stim.stimulusMapID; s.rewardTemplateID = reward.rewardTemplateID;
s.forcedMeanA = reward.forcedMeanA; s.forcedMeanB = reward.forcedMeanB; s.forcedGapObserved = reward.forcedGapObserved;
end

function local_check_live_identity(live, cfg, plan)
% A live marker is interpreted only if it belongs to this participant, build and plan.
ok = isfield(live,'participantID') && strcmp(live.participantID, cfg.participantID) && ...
     isfield(live,'behaviourHash') && strcmp(live.behaviourHash, cfg.behaviourHash) && ...
     isfield(live,'planID') && strcmp(live.planID, plan(1).planID);
if ~ok; error('AVDE:LiveMarkerIdentity','The live marker does not belong to this participant/build/plan. Inspect data/live before continuing.'); end
end

function a = local_ask(prompt)
a = getenv('AVDE_NONINTERACTIVE_ANSWER');
if isempty(a); a = input(prompt,'s'); else; fprintf('%s%s (non-interactive)\n', prompt, a); end
a = strtrim(a);
end
