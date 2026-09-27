function avde_cleanup(ds)
% Restore keyboard/display state even after errors.
try
    if isstruct(ds) && isfield(ds,'keyboardDeviceIndex')
        KbQueueStop(ds.keyboardDeviceIndex); KbQueueRelease(ds.keyboardDeviceIndex);
    else
        KbQueueStop; KbQueueRelease;
    end
catch
end
try; Priority(0); catch; end
try; ShowCursor; catch; end
try
    if isstruct(ds) && isfield(ds,'opened') && ds.opened; Screen('CloseAll'); end
catch
end
try
    if isstruct(ds) && isfield(ds,'oldSkipSyncTests'); Screen('Preference','SkipSyncTests',ds.oldSkipSyncTests); end
catch
end
end
