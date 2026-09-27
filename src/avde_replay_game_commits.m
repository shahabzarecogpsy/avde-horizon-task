function [session, info] = avde_replay_game_commits(session, cfg, files)
% Merge journaled games newer than the checkpoint, strictly in order.
info = struct('nFound',0,'nReplayed',0,'games',[]);
D = dir(files.commitPattern); games = [];
for i = 1:numel(D)
    tok = regexp(D(i).name, files.commitRegex, 'tokens', 'once');
    if ~isempty(tok); games(end+1) = str2double(tok{1}); end %#ok<AGROW>
end
games = sort(games); info.nFound = numel(games);
for g = games
    if g <= session.lastCompletedCoreGame; continue; end
    if g ~= session.lastCompletedCoreGame + 1
        error('AVDE:GameCommitGap','Journal has game %d but game %d is missing. Refusing to skip or reorder.', g, session.lastCompletedCoreGame+1);
    end
    S = load(files.commit(g), 'commit'); c = S.commit;
    if c.game ~= g || ~strcmp(c.participantID, cfg.participantID) || ~strcmp(c.behaviourHash, cfg.behaviourHash) || c.gameSummary.game ~= g
        error('AVDE:GameCommitIncompatible','Journal entry for game %d does not belong to this participant/build.', g);
    end
    session.gameLogs{g} = c.gameLog; session.gameSummaries(g) = c.gameSummary;
    session.lastCompletedCoreGame = g; info.nReplayed = info.nReplayed + 1; info.games(end+1) = g;
end
end
