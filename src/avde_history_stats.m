function [meanA, meanB] = avde_history_stats(history)
% Participant-visible means per option (NaN = not sampled; -Inf = timeout).
a = history(:,1); b = history(:,2); a = a(isfinite(a)); b = b(isfinite(b));
if isempty(a); meanA = NaN; else; meanA = mean(a); end
if isempty(b); meanB = NaN; else; meanB = mean(b); end
end
