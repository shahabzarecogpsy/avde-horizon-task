function avde_live_save(file, game, phase, eventLog, ident)
% Tiny marker: which core game is running and the last reached phase, plus the
% participant/build/plan identity so a resume can verify ownership.
% Snapshots are written at phase boundaries only, so they can lag the actual
% exposure by up to one phase. Size is bounded by one game's events.
live = struct('participantID',ident.participantID,'behaviourHash',ident.behaviourHash,'planID',ident.planID, ...
    'game',game,'phase',phase,'time',avde_now(),'eventLog',eventLog);
avde_atomic_save(file, 'live', live);
end
