function safeID = avde_validate_participant_id(participantID)
% Validate participant identifier once so every output path is safe and stable.
safeID=char(participantID);
if isempty(safeID) || isempty(regexp(safeID,'^[A-Za-z0-9][A-Za-z0-9_\-]{0,63}$','once'))
    error('AVDE:ParticipantID', ...
        'Participant ID must be 1-64 characters and contain only letters, numbers, underscore, or hyphen.');
end
end
