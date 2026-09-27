function avde_kb_release_wait(ds)
% Wait until all keys on the selected response keyboard are released.
while true
    [down,~,~]=KbCheck(ds.keyboardDeviceIndex);
    if ~down; break; end
    WaitSecs('YieldSecs',0.005);
end
end
