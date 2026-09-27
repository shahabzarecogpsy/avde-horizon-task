function t = avde_wait_for_continue(ds)
% Wait for SPACE (after releasing any held key). Returns the press time.
if avde_autopilot(); WaitSecs(1.0); t = GetSecs; return; end
avde_kb_release_wait(ds); avde_kb_flush(ds); t = NaN;
while true
    [pressed, fp] = avde_kb_check(ds);
    if pressed
        if fp(ds.keys.escape) > 0; error('AVDE:UserAbort','Aborted by ESCAPE.'); end
        if fp(ds.keys.continue) > 0; t = fp(ds.keys.continue); break; end
    end
    WaitSecs('YieldSecs', 0.005);
end
avde_kb_release_wait(ds);
end
