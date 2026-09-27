function out = avde_autopilot(cmd, value)
% Unattended timing self-test on real hardware (DEVELOPMENT mode only).
% Enabled only by run_AVDE runMode 'timingtest' (sync tests enforced) and reset on exit.
% Responses are generated without the keyboard; all displays, scheduling,
% disk I/O and saving are the real ones. Never active in participant mode.
persistent on
if isempty(on); on = false; end
if nargin >= 1 && strcmp(cmd,'set'); on = logical(value); end
out = on;
end
