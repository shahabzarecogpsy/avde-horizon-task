function env = avde_environment_snapshot()
env = struct('platform',computer,'interpreter','MATLAB','interpreterVersion',version,'psychtoolboxVersion','unknown','hostname','');
if exist('OCTAVE_VERSION','builtin'); env.interpreter = 'Octave'; end
try; env.psychtoolboxVersion = PsychtoolboxVersion; catch; end
h = getenv('COMPUTERNAME'); if isempty(h); h = getenv('HOSTNAME'); end; env.hostname = h;
end
