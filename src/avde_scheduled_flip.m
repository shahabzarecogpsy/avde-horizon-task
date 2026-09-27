function t = avde_scheduled_flip(ds, requestedOnset)
% Frame-locked flip. The PTB 'when' argument is half a frame before the target,
% selecting the first retrace at/after (target - ifi/2). onsetError is therefore
% in [-ifi/2, +ifi/2) when no frame is missed.
if nargin < 2 || isempty(requestedOnset) || ~isfinite(requestedOnset)
    requestedOnset = GetSecs + ds.ifi*1.5;
end
[vbl, stimOn, ~, missed] = Screen('Flip', ds.win, max(0, requestedOnset - 0.5*ds.ifi));
t = struct('requestedOnset',requestedOnset,'actualOnset',vbl,'stimulusOnsetTime',stimOn, ...
    'missedFrame',missed>0,'onsetError',vbl-requestedOnset);
end
