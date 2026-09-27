function E = avde_finalize_event_derived_fields(E)
% Realized (actually displayed) image/identity repeat lags, in games.
lastFile = containers.Map('KeyType','char','ValueType','double');
lastID = containers.Map('KeyType','char','ValueType','double');
for i = 1:numel(E)
    if isempty(E(i).imageFile); continue; end
    g = E(i).game;
    if isKey(lastFile, E(i).imageFile); E(i).imageRepeatLagGames = g - lastFile(E(i).imageFile); end
    if isKey(lastID, E(i).imageIdentityKey); E(i).identityRepeatLagGames = g - lastID(E(i).imageIdentityKey); end
    lastFile(E(i).imageFile) = g; lastID(E(i).imageIdentityKey) = g;
end
end
