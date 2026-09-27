function hex=avde_sha256_text(txt)
% SHA-256 (lowercase hex) of UTF-8 text. MATLAB: Java MessageDigest; Octave: hash().
b=uint8(unicode2native(char(txt),'UTF-8'));
hex=avde_sha256_bytes(b);
end
