% START_AVDE_PARTICIPANT  One-click launcher for real participants (v0.13.0).
% Psychtoolbox synchronization tests are enforced; if they fail, the task does
% not start (fix the display setup; do NOT switch to development mode for a
% real participant). The release manifest must verify.
clc; rootDir = fileparts(mfilename('fullpath')); if isempty(rootDir); rootDir = pwd; end
addpath(rootDir, '-begin');
answer = inputdlg({'Participant ID (letters/digits/_/-; must NOT start with TEST):'}, 'AVDE participant session', [1 60], {''});
if isempty(answer); fprintf('Cancelled.\n'); return; end
pid = strtrim(answer{1});
cfdRoot = strtrim(getenv('CFD_ROOT'));
if isempty(cfdRoot) || ~isfolder(cfdRoot)
    cfdRoot = uigetdir(rootDir, 'Select the Chicago Face Database image folder');
    if isequal(cfdRoot, 0); fprintf('Cancelled.\n'); return; end
end
run_AVDE(pid, cfdRoot, 'participant');
