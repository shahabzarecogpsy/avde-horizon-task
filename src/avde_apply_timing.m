function e = avde_apply_timing(e, t, requestedDuration)
e.requestedOnset = t.requestedOnset; e.actualOnset = t.actualOnset; e.stimulusOnsetTime = t.stimulusOnsetTime;
e.onsetError = t.onsetError; e.missedFrame = t.missedFrame; e.requestedDuration = requestedDuration;
end
