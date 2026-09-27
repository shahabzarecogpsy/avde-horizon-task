function avde_atomic_save(file, varName, value)
% Write to a temporary file, then rename: a crash can never leave a partial file
% under the final name. Always MAT v7 (bounded, no HDF5 metadata growth).
[d,b,e] = fileparts(file); if ~exist(d,'dir'); mkdir(d); end
tmp = fullfile(d, [b '.tmp' e]);
S.(varName) = value; %#ok<STRNU>
save(tmp, '-struct', 'S', '-v7');
[ok,msg] = movefile(tmp, file, 'f');
if ~ok; error('AVDE:AtomicSave','Could not finalize %s: %s', file, msg); end
end
