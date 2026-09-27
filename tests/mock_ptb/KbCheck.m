function [down, secs, code] = KbCheck(varargin)
% Returns the simulated 'key held' state of the current choice trial.
global AVDE_MOCK
secs = GetSecs(); code = zeros(1,256); down = false;
st = dbstack;
if any(strcmp({st.name},'avde_collect_choice')) && ~isempty(AVDE_MOCK.trial) && AVDE_MOCK.trial.held
    down = true; code(AVDE_MOCK.trial.heldKey) = 1;
end
end
