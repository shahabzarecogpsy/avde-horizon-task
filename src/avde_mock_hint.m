function out = avde_mock_hint(kind, value)
% Test hook. In a real Psychtoolbox run the global is empty and this is a no-op.
global AVDE_MOCK
out = false;
if isempty(AVDE_MOCK) || ~isstruct(AVDE_MOCK); return; end
switch kind
    case 'answer'; AVDE_MOCK.expectedAnswer = value;
    case 'game'; AVDE_MOCK.game = value; AVDE_MOCK.flipInGame = 0;
    case 'break'; AVDE_MOCK.sectionBreak = value;
    case 'fault'
        gameOK = ~isfield(AVDE_MOCK,'faultGame') || ~isfinite(AVDE_MOCK.faultGame) || isequal(AVDE_MOCK.game, AVDE_MOCK.faultGame);
        if isfield(AVDE_MOCK,'faultAt') && strcmp(AVDE_MOCK.faultAt, value) && gameOK
            AVDE_MOCK.faultAt = ''; AVDE_MOCK.crashed = true; error('MOCK:Crash','Injected fault at %s', value);
        end
    case 'hardkill'; out = isfield(AVDE_MOCK,'hardKill') && AVDE_MOCK.hardKill;
end
end
