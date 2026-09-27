function avde_reexport(finalMatFile)
% AVDE_REEXPORT  Rebuild all CSV files from a completed session's authoritative
% *_complete.mat and remove leftover recovery files of that participant.
% Use if a session ended (final MAT written) but CSV export or cleanup did not
% finish. Never re-runs or modifies the participant's data.
%   avde_reexport('data/P012_AVDE-v0_13-FINALPILOT-112_complete.mat')
rootDir = fileparts(mfilename('fullpath')); addpath(fullfile(rootDir,'src'),'-begin');
S = load(finalMatFile, 'session'); s = S.session;
assert(isfield(s,'completed') && s.completed, 'AVDE:Reexport', 'This file is not a completed session.');
cfg = s.config; cfg.paths.output = fileparts(finalMatFile);
cfg.paths.checkpoints = fullfile(cfg.paths.output,'checkpoints'); cfg.paths.live = fullfile(cfg.paths.output,'live');
files = avde_paths_for(cfg);
avde_export_csv(s, cfg, files);
n = avde_game_commit_clear(files);
if isfile(files.live); delete(files.live); end
if isfile(files.checkpoint); delete(files.checkpoint); end
fprintf('Re-exported CSVs for %s (%d leftover journal files removed).\n', s.meta.participantID, n);
end
