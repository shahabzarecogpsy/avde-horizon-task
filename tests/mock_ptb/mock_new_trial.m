function mock_new_trial(onset)
% Simulated participant for one choice screen. Each trial is a list of key
% presses [time relative to onset, key code]. Scenario mix (probabilities in
% mock_reset) exercises the adjudication rules; a test may instead queue exact
% scripts in AVDE_MOCK.scripts (consumed in order).
global AVDE_MOCK
L = 37; R = 39;
if isfield(AVDE_MOCK,'scripts') && ~isempty(AVDE_MOCK.scripts)
    T = AVDE_MOCK.scripts{1}; AVDE_MOCK.scripts(1) = [];
else
    r = mock_rand(1,8); if r(6) < 0.5; k = L; o = R; else; k = R; o = L; end
    if r(5) < AVDE_MOCK.pFast; rt = 0.08 + 0.06*r(7); else; rt = min(3.5, exp(log(0.55) + 0.45*sqrt(-2*log(max(r(7),1e-12)))*cos(2*pi*r(8)))); end
    T.held = r(3) < AVDE_MOCK.pHeld; T.heldKey = k;
    if r(1) < AVDE_MOCK.pTimeout;                         T.presses = zeros(0,2);
    elseif r(1) < AVDE_MOCK.pTimeout + AVDE_MOCK.pAnticip; T.presses = [-0.03 k; rt o];
    elseif r(1) < AVDE_MOCK.pTimeout + AVDE_MOCK.pAnticip + AVDE_MOCK.pSimul; T.presses = [rt k; rt+0.006 o; rt+0.7 k];   % cross-poll near-simultaneous, then a valid press
    elseif r(1) < AVDE_MOCK.pTimeout + AVDE_MOCK.pAnticip + AVDE_MOCK.pSimul + AVDE_MOCK.pEdge
        if r(2) < 0.5; T.presses = [3.9995 k]; else; T.presses = [4.0005 k]; end                                  % just before / just after the deadline
    else;                                                  T.presses = [rt k];
    end
end
if ~isfield(T,'held'); T.held = false; T.heldKey = 37; end
T.presses(:,1) = T.presses(:,1) + onset; T.delivered = false(size(T.presses,1),1); T.onset = onset;
AVDE_MOCK.trial = T; AVDE_MOCK.trialLog{end+1} = T;
end
