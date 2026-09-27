% START_AVDE_DEVELOPMENT  Launcher for development/test runs (IDs start with TEST).
% Sync tests are skipped; every output is labelled DEVELOPMENT_NOT_SCIENTIFICALLY_VALID.
clc; rootDir = fileparts(mfilename('fullpath')); if isempty(rootDir); rootDir = pwd; end
addpath(rootDir, '-begin');
answer = inputdlg({'TEST participant ID (must start with TEST):'}, 'AVDE development session', [1 60], {['TEST_' datestr(now,'yyyymmdd_HHMMSS')]});
if isempty(answer); fprintf('Cancelled.\n'); return; end
cfdRoot = strtrim(getenv('CFD_ROOT'));
if isempty(cfdRoot) || ~isfolder(cfdRoot)
    cfdRoot = uigetdir(rootDir, 'Select the Chicago Face Database image folder');
    if isequal(cfdRoot, 0); fprintf('Cancelled.\n'); return; end
end
run_AVDE(strtrim(answer{1}), cfdRoot, 'development');
