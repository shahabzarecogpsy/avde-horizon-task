function hex=avde_sha256_bytes(b)
% SHA-256 of a uint8 vector. Implementation-independent result (tested
% against known vectors in tests/test_hashing.m).
b=uint8(b(:)');
if exist('OCTAVE_VERSION','builtin')
    hex=lower(hash('sha256',char(b)));
else
    md=java.security.MessageDigest.getInstance('SHA-256');
    if ~isempty(b); md.update(b); end
    d=typecast(md.digest(),'uint8');
    hex=lower(reshape(dec2hex(d,2).',1,[]));
end
end
