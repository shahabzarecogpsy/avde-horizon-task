function env = test_env(tag)
% Isolated test environment: a fresh data root under tempdir (never the package's
% data/ folder), simulator on the path. Returns a guard that restores the MATLAB
% path, environment variables and the simulator global when it is cleared.
root = fileparts(fileparts(mfilename('fullpath')));
env.root = root;
env.dataRoot = fullfile(tempdir, sprintf('AVDE_test_data_%s_%s', tag, datestr(now,'yyyymmddHHMMSSFFF')));
env.oldPath = path; env.oldDataRoot = getenv('AVDE_DATA_ROOT'); env.oldAnswer = getenv('AVDE_NONINTERACTIVE_ANSWER');
addpath(fullfile(root,'tests','mock_ptb')); addpath(fullfile(root,'src')); addpath(root);
setenv('AVDE_DATA_ROOT', env.dataRoot); setenv('AVDE_NONINTERACTIVE_ANSWER','y');
env.guard = onCleanup(@() local_restore(env));
end
function local_restore(env)
global AVDE_MOCK
test_clean_data(env.dataRoot);
setenv('AVDE_DATA_ROOT', env.oldDataRoot); setenv('AVDE_NONINTERACTIVE_ANSWER', env.oldAnswer);
AVDE_MOCK = []; path(env.oldPath);
end
