function nFail = test_unit(cfdRoot, outFile)
% Unit and negative-path tests (headless). Each line: name,pass,detail.
% All run data go to an isolated temp root (never the package data/ folder).
env = test_env('unit'); root = env.root; D = env.dataRoot;
fid = fopen(outFile,'w'); fprintf(fid,'test,pass,detail\n');
T = {};
% hashing (FIPS 180-2 test vectors)
T{end+1} = {'sha256 "abc"', strcmp(avde_sha256_text('abc'),'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'), ''};
T{end+1} = {'sha256 empty', strcmp(avde_sha256_bytes(uint8([])),'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'), ''};
% box downscale
x = uint8(reshape(1:48,4,4,3)); y = avde_downscale_box(x,2);
T{end+1} = {'box downscale 2x', isequal(size(y),[2 2 3]) && y(1,1,1)==round(mean([1 2 5 6])) && y(2,2,3)==round(mean([43 44 47 48])), ''};
% layout at several resolutions
cfg = avde_config(root,'TEST_U',cfdRoot); cfg.runtime.lineWidth = 3; okL = true;
for r = [1280 720; 1920 1080; 2560 1440; 1920 1200; 1366 768]'
    try; avde_build_layout([0 0 r(1) r(2)], setfield(cfg,'debug',setfield(cfg.debug,'verbose',false))); catch e; okL = false; end %#ok<SFLD>
end
T{end+1} = {'layout valid at 5 resolutions (header/faces/decks non-overlapping)', okL, ''};
% practice cycles cover design
pr1 = avde_build_practice_plan(cfg,1); pr2 = avde_build_practice_plan(cfg,2);
c1 = sort(arrayfun(@(p) sprintf('H%d%s',p.horizon,p.valenceCondition), pr1, 'UniformOutput', false));
T{end+1} = {'practice cycle 1 = 6 games, one per horizon x valence', numel(pr1)==6 && isequal(c1(:)', sort({'H1PP','H1NN','H1PN','H6PP','H6NN','H6PN'})) && pr1(1).horizon==1 && strcmp(pr1(1).valenceCondition,'PP') && pr1(2).horizon==6, ''};
T{end+1} = {'practice repeat cycle = 3 games incl. H1-PN and H6-PN', numel(pr2)==3 && sum([pr2.horizon]==6 & strcmp({pr2.valenceCondition},'PN'))==1, ''};
T{end+1} = {'practice uses single gap 4 only', all([pr1.rewardGap pr2.rewardGap]==4), ''};
% determinism
p1 = avde_build_plan(cfg); p2 = avde_build_plan(cfg);
T{end+1} = {'plan reproducible for same ID', strcmp(p1(1).planID,p2(1).planID), p1(1).planID};
cfg2 = avde_config(root,'TEST_V',cfdRoot); p3 = avde_build_plan(cfg2);
T{end+1} = {'plan differs across IDs', ~strcmp(p1(1).planID,p3(1).planID), ''};
% validator catches the old confound (Positive always more-informed in H6-PN)
bad = p1; idx = find([bad.horizon]==6 & strcmp({bad.valenceCondition},'PN'));
for g = idx; b = bad(g); if strcmp(b.lessObservedValence,'Positive')
    % swap information roles to make Positive always more-observed
    b.lessInformativeOption = b.moreInformativeOption; b.moreInformativeOption = setdiff('AB', b.lessInformativeOption);
    b.lessObservedValence = 'Negative'; b.lessObservedRewardLevel = b.(['option' b.lessInformativeOption 'RewardLevel']); bad(g) = b; end; end
try; avde_validate_plan(bad, cfg); caught = false; catch e; caught = ~isempty(strfind(e.identifier,'AVDE:Plan')); end %#ok<STREMP>
T{end+1} = {'validator rejects the v0.12 H6-PN confound', caught, ''};
% negative run paths
global AVDE_MOCK
test_clean_data(D); mock_reset(struct());
try; run_AVDE('TEST_X', cfdRoot, 'participant'); r = false; catch e; r = strcmp(e.identifier,'AVDE:ParticipantModeID'); end
T{end+1} = {'participant mode refuses TEST IDs', r, ''};
try; run_AVDE('P001', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:DevelopmentModeID'); end
T{end+1} = {'development mode refuses non-TEST IDs', r, ''};
try; run_AVDE('P001', cfdRoot, 'participant'); r = false; catch e; r = strncmp(e.identifier,'AVDE:Release',12) || strcmp(e.identifier,'AVDE:MissingReleaseManifest') || strcmp(e.identifier,'AVDE:MockPsychtoolbox'); pe = e.identifier; end
T{end+1} = {'participant mode cannot start without a verified manifest AND real Psychtoolbox', r, pe};
% crash at game 20 (hard kill), then: (a) delete one journal -> must refuse; (b) orphan files
test_clean_data(D); mock_reset(struct('crashGame',20,'crashFlipInGame',3,'hardKill',true)); setenv('AVDE_NONINTERACTIVE_ANSWER','y');
try; run_AVDE('TEST_NEG', cfdRoot, 'development'); catch; end
J = dir(fullfile(D,'live','*_core_018_commit.mat')); delete(fullfile(J(1).folder,J(1).name));
mock_reset(struct());
try; run_AVDE('TEST_NEG', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:GameCommitGap'); end
T{end+1} = {'resume refuses a missing journal entry (no silent skip)', r, ''};
delete(fullfile(D,'checkpoints','*.mat'));
try; run_AVDE('TEST_NEG', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:OrphanRecoveryFiles'); end
T{end+1} = {'orphan journals without checkpoint are refused', r, ''};
% stale live marker (crash after commit, before marker deletion) is cleared, not aborted
test_clean_data(D); mock_reset(struct('crashGame',9,'crashFlipInGame',2,'hardKill',true));
try; run_AVDE('TEST_STALE', cfdRoot, 'development'); catch; end
L = dir(fullfile(D,'live','*_live.mat')); S = load(fullfile(L(1).folder,L(1).name)); S.live.game = 8; live = S.live; save('-v7', fullfile(L(1).folder,L(1).name), 'live');
mock_reset(struct());
try; run_AVDE('TEST_STALE', cfdRoot, 'development'); F = load(fullfile(D,'TEST_STALE_AVDE-v0_13-FINALPILOT-112_complete.mat'));
    st = {F.session.gameSummaries.slotStatus}; r = all(strcmp(st,'completed')) && strcmp(F.session.resumeLog(1).liveStatus,'stale_cleared');
catch e; r = false; end
T{end+1} = {'stale live marker for a committed game is cleared (game 9 then runs normally)', r, ''};
% declining resume without the RESTART token changes nothing
test_clean_data(D); mock_reset(struct('crashGame',3,'crashFlipInGame',2,'hardKill',true));
try; run_AVDE('TEST_DECL', cfdRoot, 'development'); catch; end
setenv('AVDE_NONINTERACTIVE_ANSWER','n'); mock_reset(struct());
try; run_AVDE('TEST_DECL', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:ResumeDeclined') && ~isempty(dir(fullfile(D,'checkpoints','*.mat'))); end
T{end+1} = {'declined resume without RESTART token leaves files untouched', r, ''};
setenv('AVDE_NONINTERACTIVE_ANSWER','y');
% ---- v0.13.3 additions -----------------------------------------------------
% keyboard adjudication with scripted presses (first 7 practice choices)
test_clean_data(D); L = 37; R = 39;
scripts = {struct('presses',[0.5 L; 0.506 R; 1.2 L]), struct('presses',[0.5 R; 0.506 L]), struct('presses',[3.9995 L]), ...
    struct('presses',[4.0005 L]), struct('presses',[-0.03 L; 0.4 L]), struct('presses',[0.3 R],'held',true,'heldKey',R), struct('presses',[0.5 L; 0.515 R])};
mock_reset(struct('scripts',{scripts}));
try; run_AVDE('TEST_KEYS', cfdRoot, 'development'); F = load(fullfile(D,'TEST_KEYS_AVDE-v0_13-FINALPILOT-112_complete.mat'));
    C = F.session.practice.cycles(1); E = [C.gameLogs{1}; C.gameLogs{2}]; fc = E(strcmp({E.eventType},'free_choice'));
    fc = fc(1:7); rt = [fc.rt]; to = [fc.timeout];
    r = [fc(1).simultaneousPress && strcmp(fc(1).chosenSide,'L') && abs(rt(1)-1.2)<1e-9, ...
         fc(2).simultaneousPress && to(2), ~to(3) && abs(rt(3)-3.9995)<1e-9, to(4), ...
         fc(5).anticipatoryPress && abs(rt(5)-0.4)<1e-9, fc(6).keyHeldAtOnset && strcmp(fc(6).chosenSide,'R'), ...
         ~fc(7).simultaneousPress && strcmp(fc(7).chosenSide,'L') && abs(rt(7)-0.5)<1e-9];
    PE = []; for g = 1:numel(C.gameLogs); PE = [PE; C.gameLogs{g}]; end %#ok<AGROW>
    lab = all(strcmp({PE.attemptType},'practice'));
catch e; r = false(1,7); lab = false; disp(e.message); end
names = {'cross-poll L+R within 6 ms rejected; later press accepted','R+L within 6 ms rejected -> timeout','press 0.5 ms before deadline accepted', ...
    'press 0.5 ms after deadline rejected (timeout)','anticipatory press ignored, later press accepted','key held at onset logged (sampled after flip)','presses 15 ms apart: first accepted'};
for k = 1:7; T{end+1} = {['keyboard: ' names{k}], r(k), ''}; end %#ok<AGROW>
T{end+1} = {'all practice events (incl. joint outcomes) labelled practice', lab, ''};
% live marker identity is verified
test_clean_data(D); mock_reset(struct('crashGame',6,'crashFlipInGame',3,'hardKill',true));
try; run_AVDE('TEST_LID', cfdRoot, 'development'); catch; end
Lf = dir(fullfile(D,'live','*_live.mat')); S = load(fullfile(Lf(1).folder,Lf(1).name)); live = S.live; live.planID = 'PFOREIGN0000'; save('-v7', fullfile(Lf(1).folder,Lf(1).name), 'live');
mock_reset(struct());
try; run_AVDE('TEST_LID', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:LiveMarkerIdentity'); end
T{end+1} = {'live marker from another plan/build/participant is refused', r, ''};
% face bank too small -> explicit error (no infinite loop)
small = fullfile(tempdir, sprintf('AVDE_test_smallcfd_%s', datestr(now,'HHMMSSFFF'))); mkdir(small);
for i = 1:15; for ex = {'HC','A'}; imwrite(uint8(128*ones(20,15,3)), fullfile(small, sprintf('CFD-WF-%03d-001-%s.jpg', i, ex{1}))); end; end
cfgS = avde_config(root,'TEST_S',small);
try; avde_partition_manifest(avde_build_cfd_manifest(cfgS), cfgS); r = false; catch e; r = strcmp(e.identifier,'AVDE:StimulusBankTooSmall'); end
if exist('confirm_recursive_rmdir'); confirm_recursive_rmdir(false); end; rmdir(small,'s'); %#ok<EXIST>
T{end+1} = {'too few paired identities -> explicit error (needs 112)', r, ''};
% validation CSV set but missing -> error
test_clean_data(D); setenv('AVDE_LOCAL_VALIDATION_CSV', fullfile(tempdir,'does_not_exist_avde.csv')); mock_reset(struct());
try; run_AVDE('TEST_CSV', cfdRoot, 'development'); r = false; catch e; r = strcmp(e.identifier,'AVDE:ValidationCsvMissing'); end
setenv('AVDE_LOCAL_VALIDATION_CSV','');
T{end+1} = {'validation CSV set but missing -> error', r, ''};
% simulator refused in participant/timing modes
try; avde_require_real_ptb(root); r = false; catch e; r = strcmp(e.identifier,'AVDE:MockPsychtoolbox'); end
T{end+1} = {'simulator (mock PTB) refused for participant/timing modes', r, ''};
% export re-run is idempotent
test_clean_data(D); mock_reset(struct());
try; run_AVDE('TEST_EXP', cfdRoot, 'development'); ff = fullfile(D,'TEST_EXP_AVDE-v0_13-FINALPILOT-112_complete.mat');
    h1 = avde_sha256_file(fullfile(D,'TEST_EXP_games.csv')); delete(fullfile(D,'TEST_EXP_events.csv')); avde_reexport(ff);
    r = isfile(fullfile(D,'TEST_EXP_events.csv')) && strcmp(h1, avde_sha256_file(fullfile(D,'TEST_EXP_games.csv')));
    G = fileread(fullfile(D,'TEST_EXP_games.csv')); r = r && ~isempty(strfind(G,'DEVELOPMENT_NOT_SCIENTIFICALLY_VALID')); %#ok<STREMP>
catch e; r = false; disp(e.message); end
T{end+1} = {'avde_reexport rebuilds CSVs identically; tables carry dataStatus', r, ''};
nFail = 0;
for k = 1:numel(T); fprintf(fid,'"%s",%d,"%s"\n',T{k}{1},T{k}{2},T{k}{3}); fprintf('%-80s %d\n',T{k}{1},T{k}{2}); nFail = nFail + ~T{k}{2}; end
fclose(fid);
end
