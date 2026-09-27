function mock_reset(opts)
% Headless Psychtoolbox simulator for Octave tests (virtual clock).
% Virtual time advances by (a) the REAL wall-clock time spent executing task
% code (computation and disk I/O are therefore measured, not simulated) and
% (b) instantaneous jumps for waits (flip targets, response latencies, breaks).
global AVDE_MOCK
if nargin < 1; opts = struct(); end
M = struct('V',1000,'lastReal',time(),'ifi',1/60,'origin',1000,'flips',0,'lastFlip',NaN,'tex',0,'openTex',0, ...
    'maxOpenTex',0,'pTimeout',0.02,'pAnticip',0.03,'pHeld',0.03,'pFast',0.05,'pSimul',0.03,'pEdge',0.02,'scripts',{{}},'trialLog',{{}},'faultAt','','faultGame',NaN,'breakSeconds',20, ...
    'crashGame',NaN,'crashGlobalFlip',NaN,'crashFlipInGame',NaN,'crashInBreak',NaN,'hardKill',false,'game',NaN,'flipInGame',0, ...
    'trial',[],'expectedAnswer','','failComprehensionCycles',0,'compAnswers',0,'yield',0.001,'flipLog',zeros(0,4), ...
    'rngState',[],'crashed',false,'sectionBreak',NaN);
f = fieldnames(opts); for k = 1:numel(f); M.(f{k}) = opts.(f{k}); end
M.rs = rand('state'); rand('state', 12345); M.mockRand = rand('state'); rand('state', M.rs); %#ok<RAND>
AVDE_MOCK = M;
end
