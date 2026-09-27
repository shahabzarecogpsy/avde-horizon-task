function START_AVDE_TIMING_SELFTEST()
% START_AVDE_TIMING_SELFTEST  Unattended 112-game run on the REAL lab display.
% runMode 'timingtest': Psychtoolbox synchronization tests are ENFORCED, the
% release manifest is verified and the simulator is refused; responses are
% generated automatically (no keyboard). Complements - does not replace - a
% human keyboard rehearsal. Afterwards:
%   python tools/timing_report.py data/<ID>_games.csv data/<ID>_events.csv
rootDir = fileparts(mfilename('fullpath')); addpath(rootDir, '-begin');
cfdRoot = strtrim(getenv('CFD_ROOT'));
if isempty(cfdRoot) || ~isfolder(cfdRoot); cfdRoot = uigetdir(rootDir, 'Select the Chicago Face Database image folder'); end
if isequal(cfdRoot, 0); return; end
run_AVDE(['TEST_TIMING_' datestr(now,'yyyymmdd_HHMMSS')], cfdRoot, 'timingtest');
end
