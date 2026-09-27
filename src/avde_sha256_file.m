function hex=avde_sha256_file(filePath)
% SHA-256 (lowercase hex) of a file's bytes.
if ~isfile(filePath); hex=''; return; end
fid=fopen(filePath,'rb');
if fid<0; error('AVDE:HashOpen','Could not open file for hashing: %s',filePath); end
c=onCleanup(@() fclose(fid)); %#ok<NASGU>
if exist('OCTAVE_VERSION','builtin')
    b=fread(fid,Inf,'*uint8'); hex=avde_sha256_bytes(b);
else
    md=java.security.MessageDigest.getInstance('SHA-256');
    while true
        b=fread(fid,1024*1024,'*uint8');
        if isempty(b); break; end
        md.update(b);
    end
    d=typecast(md.digest(),'uint8');
    hex=lower(reshape(dec2hex(d,2).',1,[]));
end
end
