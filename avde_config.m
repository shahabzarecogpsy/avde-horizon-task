function cfg = avde_config(rootDir, participantID, cfdRoot)
% avde_config  Central configuration for the AVDE final pilot (v0.13.0).
% Every parameter that can alter participant-facing behaviour or the design is
% declared here. The build identity (code hash) is computed automatically at
% startup from every executable/asset file, so an edited file can never share
% an identity with the frozen release (see avde_build_identity).

cfg.version = '0.13.3';                       % human-readable version
cfg.protocolVersion = 'AVDE-v0.13-FINALPILOT-112';
cfg.releaseID = 'AVDE_FINALPILOT_v0.13.3';     % human-readable release label
cfg.participantID = char(participantID);
cfg.rootDir = rootDir;
cfg.randomSeed = avde_seed_from_id(participantID);

%% Paths
cfg.paths.src = fullfile(rootDir, 'src');
cfg.paths.assets = fullfile(rootDir, 'assets');
cfg.paths.instructionsFA = fullfile(rootDir, 'assets', 'instructions_fa');
cfg.paths.output = getenv('AVDE_DATA_ROOT');      % optional override (recorded in meta.dataRoot)
if isempty(strtrim(cfg.paths.output)); cfg.paths.output = fullfile(rootDir, 'data'); end
cfg.paths.checkpoints = fullfile(cfg.paths.output, 'checkpoints');
cfg.paths.live = fullfile(cfg.paths.output, 'live');
cfg.paths.archive = fullfile(cfg.paths.output, 'archive');
if nargin >= 3 && ~isempty(cfdRoot); cfg.paths.cfdRoot = cfdRoot; else; cfg.paths.cfdRoot = getenv('CFD_ROOT'); end
cfg.stim.localValidationCsv = getenv('AVDE_LOCAL_VALIDATION_CSV');
cfg.stim.localValidationSha256 = '';

%% Mode / safety (runMode in run_AVDE overrides these)
cfg.mode = 'pilot';                 % pilot | development
cfg.debug.skipSyncTests = false;
cfg.debug.allowSyncFailure = false;  % pilot only, via AVDE_ALLOW_SYNC_FAILURE=1; recorded in data
cfg.debug.windowed = false;
cfg.debug.windowRect = [100 100 1500 900];
cfg.debug.showMouse = false;
cfg.debug.verbose = true;

%% Core design (final pilot; see avde_build_plan / avde_validate_plan)
cfg.task.nGames = 112;
cfg.task.nSections = 7;
cfg.task.gamesPerSection = 16;
cfg.task.breakAfterGames = [16 32 48 64 80 96];
cfg.task.horizons = [1 6];
cfg.task.gamesPerHorizon = [48 64];          % H1, H6
cfg.task.valenceConditions = {'PP','NN','PN'};
cfg.task.gamesH1 = [16 16 16];               % PP NN PN
cfg.task.gamesH6 = [16 16 32];               % PP NN PN
cfg.task.forcedObsPerGame = 4;
cfg.task.equalCounts = [2 2];                % H1 only
cfg.task.unequalCounts = [3 1];              % H6 only: more-observed : less-observed

%% Plan randomization
cfg.plan.baseSeed = 615421;
cfg.plan.maxSectionRestarts = 20;
cfg.plan.hillClimbSteps = 4000;
cfg.plan.maxRunSameHorizon = 5;              % presentation constraint within the game sequence
cfg.plan.maxRunSameValenceCondition = 4;

%% Timing (seconds)
% Inter-game contract (uninterrupted consecutive games inside a section):
%   game_end blank onset (game N) -> game_reset onset (game N+1) = interGameEndToReset
%   game_reset onset -> first facial preview                       = gameReset
%   => game_end -> first face = interGameEndToReset + gameReset = 2.000 s
cfg.timing.interGameEndToReset = 1.500;
cfg.timing.gameReset = 0.500;
cfg.timing.interGameEndToFirstFace = cfg.timing.interGameEndToReset + cfg.timing.gameReset;
cfg.timing.interGameWarnFrames = 2;          % descriptive QC threshold only
cfg.timing.previewImage = 1.200;
cfg.timing.previewITI = 0.500;
cfg.timing.forcedCue = 0.300;
cfg.timing.forcedPoint = 0.800;
cfg.timing.forcedITI = 0.500;
cfg.timing.choiceHardTimeout = 4.000;
cfg.timing.outcomeDelayFrames = 2;           % response -> outcome onset, in frames
cfg.timing.jointOutcome = 1.500;
cfg.timing.outcomeITI = 0.500;
cfg.timing.flipLeadFrames = 1.5;
cfg.timing.fastRTFlag = 0.150;               % descriptive flag only; response still counts
cfg.timing.timeoutFeedbackDelay = 0.050;     % after a timeout, feedback appears at deadline + 50 ms
                                             % (post-deadline queue drain 30 ms + preparation)

%% Reward generator (single gap by design; NOT a free parameter of this pilot)
cfg.reward.center = 20;
cfg.reward.sd = 8;
cfg.reward.gap = 4;                          % latent High mean - Low mean (22 vs 18)
cfg.reward.lower = 1;
cfg.reward.upper = 50;
cfg.reward.roundToInteger = true;
cfg.reward.nPotentialPerSource = 10;
cfg.reward.maxGenerationAttempts = 20000;
cfg.reward.forcedEvidenceMode = 'exact-observed-gap';
cfg.reward.forcedGapTolerance = 1e-9;

%% CFD stimulus mapping
cfg.stim.positiveExpressions = {'HC'};       % happy, closed mouth
cfg.stim.negativeExpressions = {'A'};        % angry
cfg.stim.allowedExtensions = {'.jpg','.jpeg','.png'};
cfg.stim.restrictToCommonExpressionIdentities = true;
cfg.stim.noIdentityRepeatWithinGame = true;
cfg.stim.minImageLagGames = 3;
cfg.stim.minIdentityLagGames = 3;
cfg.stim.maxAssignmentRestarts = 500;
cfg.stim.requireLocalValidation = false;     % pilot: optional; if AVDE_LOCAL_VALIDATION_CSV is set it is applied
cfg.stim.requiredValidationColumns = {'file','include','local_valence','local_arousal','expression_intensity','expression_recognition','threat','approach_avoidance','match_stratum','gender','race','attractiveness','perceived_age'};
cfg.stim.validation.ratingRange = [0 100];
cfg.stim.validation.minValenceClassSeparation = 10;
cfg.stim.validation.minRecognitionAffectiveClasses = 80;
cfg.stim.reservePracticeIdentities = 16;
cfg.stim.coreIdentityValenceExclusive = true;
cfg.stim.minCoreIdentitiesPerClass = [48 48];
cfg.stim.imageCacheMaxHeightFraction = 0.60; % RAM image cache: downscale to >= this fraction of screen height

%% Practice (must mirror the final pilot design; see avde_build_practice_plan)
cfg.practice.nGames = 6;                      % cycle 1 (asserted by avde_build_practice_plan)
cfg.practice.guidedGames = 2;
cfg.practice.maxCycles = 3;

%% Breaks
cfg.breaks.participantControlled = true;
cfg.breaks.minimumDuration = 0;

%% Display / layout
cfg.display.colorRange = 255;
cfg.display.background = [48 51 57];
cfg.display.panel = [86 92 102];
cfg.display.text = [245 245 245];
cfg.display.mutedText = [150 155 162];
cfg.display.progressText = [128 133 140];    % low-contrast progress counter
cfg.display.historyFill = [248 248 248];
cfg.display.historyText = [20 20 20];
cfg.display.highlight = [40 205 225];
cfg.display.forcedCue = [235 185 65];
cfg.display.chosenBorder = [70 200 110];
cfg.display.border = [235 235 235];
cfg.display.sourceFill = [242 242 242];
cfg.display.sourceBorder = [35 35 35];
cfg.display.baseFont = 'Arial';
cfg.display.minimumResolution = [1280 720];
cfg.display.referenceResolution = [1920 1080];
cfg.display.hideCursor = true;
cfg.display.showProgress = true;
cfg.display.progressCenterY = 0.060;         % fraction of content height (free band above decks)
cfg.display.monitorWidthCm = local_envnum('AVDE_MONITOR_WIDTH_CM',NaN);
cfg.display.viewingDistanceCm = local_envnum('AVDE_VIEWING_DISTANCE_CM',NaN);
cfg.display.minimumElementGapFraction = 0.010;

%% Input
cfg.keys.left = 'LeftArrow';
cfg.keys.right = 'RightArrow';
cfg.keys.continue = 'space';
cfg.keys.escape = 'ESCAPE';
cfg.input.keyboardDeviceIndex = local_envnum('AVDE_KEYBOARD_DEVICE_INDEX',[]);
cfg.input.requireExplicitDeviceIfMultiple = true;
cfg.input.simultaneousWindow = 0.010;
cfg.input.postDeadlineDrain = 0.030;          % keep reading the queue this long after the deadline

%% Output
cfg.output.writeCsvAtEnd = true;
cfg.output.matVersion = '-v7';               % never v7.3 (HDF5 metadata growth)

%% Resume / interruption recovery
cfg.resume.enabled = true;
cfg.resume.promptAtStartup = true;
cfg.resume.scientificRestartToken = 'RESTART';
end

function x=local_envnum(name,defaultValue)
v=getenv(name);
if isempty(strtrim(v)); x=defaultValue; return; end
x=str2double(v);
if ~isfinite(x); error('AVDE:EnvironmentValue','Environment variable %s must be numeric.',name); end
end
