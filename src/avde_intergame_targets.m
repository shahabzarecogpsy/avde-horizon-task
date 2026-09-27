function t = avde_intergame_targets(previousGameEndOnset, cfg)
% Absolute targets for an uninterrupted transition inside a section:
%   game_reset(N+1) = game_end(N) + interGameEndToReset   (1.5 s)
%   first face(N+1) = game_reset(N+1) + gameReset          (0.5 s)  => 2.0 s end-to-face
t = struct('previousGameEndOnset',NaN,'gameResetTargetOnset',NaN,'firstFaceTargetOnset',NaN);
if nargin < 1 || isempty(previousGameEndOnset) || ~isfinite(previousGameEndOnset); return; end
t.previousGameEndOnset = previousGameEndOnset;
t.gameResetTargetOnset = previousGameEndOnset + cfg.timing.interGameEndToReset;
t.firstFaceTargetOnset = t.gameResetTargetOnset + cfg.timing.gameReset;
end
