function avde_game_commit_save(cfg, files, game, gameLog, summary)
% Journal one completed core game (size independent of game number).
commit = struct('schemaVersion',2,'participantID',cfg.participantID,'protocolVersion',cfg.protocolVersion, ...
    'buildID',cfg.buildID,'behaviourHash',cfg.behaviourHash,'game',game,'time',avde_now(), ...
    'gameLog',gameLog,'gameSummary',summary);
avde_atomic_save(files.commit(game), 'commit', commit);
end
