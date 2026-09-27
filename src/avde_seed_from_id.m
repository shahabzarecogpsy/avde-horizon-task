function seed = avde_seed_from_id(participantID)
% Stable positive 31-bit seed derived from participant ID.
% Simple polynomial hash; deterministic across MATLAB platforms.
s = double(uint8(char(participantID)));
h = 0;
modulus = 2147483646; % 2^31 - 2
for k = 1:numel(s)
    h = mod(h * 131 + s(k), modulus);
end
seed = h + 1;
end
