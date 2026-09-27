function avde_verify_release_manifest(rootDir)
% Verify SHA256SUMS.txt: every listed file matches, and every release file
% (everything except data/ and the manifest itself) is listed.
manifestFile = fullfile(rootDir,'SHA256SUMS.txt');
if ~isfile(manifestFile); error('AVDE:MissingReleaseManifest','Missing SHA256SUMS.txt.'); end
txt = fileread(manifestFile);
tok = regexp(txt,'(?m)^([0-9a-fA-F]{64})\s{2}(\S.*?)\s*$','tokens');
if isempty(tok); error('AVDE:ReleaseManifestFormat','SHA256SUMS.txt has no valid entries.'); end
listed = cell(1,numel(tok));
for k = 1:numel(tok)
    rel = strrep(tok{k}{2},'\','/'); if strncmp(rel,'./',2); rel = rel(3:end); end
    listed{k} = rel;
    p = fullfile(rootDir, strrep(rel,'/',filesep));
    if ~isfile(p); error('AVDE:ReleaseFileMissing','Listed release file missing: %s',rel); end
    if ~strcmpi(avde_sha256_file(p), tok{k}{1}); error('AVDE:ReleaseHashMismatch','Release file modified: %s',rel); end
end
actual = avde_list_files(rootDir, {'data'});
actual = actual(~strcmp(actual,'SHA256SUMS.txt'));
if ~isequal(sort(actual), sort(listed))
    error('AVDE:ReleaseManifestCoverage','SHA256SUMS.txt does not exactly cover the release (unlisted: %s | missing: %s).', ...
        strjoin(setdiff(actual,listed),','), strjoin(setdiff(listed,actual),','));
end
end
