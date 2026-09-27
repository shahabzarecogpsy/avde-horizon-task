function live = avde_live_load(file)
live = [];
if isfile(file)
    try; S = load(file,'live'); live = S.live; catch; live = struct('game',NaN,'phase','unreadable','time','','eventLog',[]); end
end
end
