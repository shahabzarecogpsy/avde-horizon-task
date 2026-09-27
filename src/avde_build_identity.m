function id = avde_build_identity(rootDir, cfg)
% Automatic build identity. behaviourHash covers every file that can change
% participant-facing behaviour or the design (launchers, config, src, assets).
% A single edited byte in any of them yields a different build identity, so
% behaviourally different builds can never share metadata.
files = avde_list_files(rootDir, {'data','docs','tests','tools'});
keep = false(size(files));
for k = 1:numel(files)
    f = files{k};
    keep(k) = strcmp(f,'avde_config.m') || strcmp(f,'run_AVDE.m') || strncmp(f,'START_',6) || ...
        strncmp(f,'src/',4) || strncmp(f,'assets/',7);
end
files = files(keep);
lines = cell(1,numel(files));
for k = 1:numel(files)
    lines{k} = [avde_sha256_file(fullfile(rootDir, strrep(files{k},'/',filesep))) '  ' files{k}];
end
id.behaviourFiles = files;
id.behaviourHash = avde_sha256_text(strjoin(lines, sprintf('\n')));
id.buildID = sprintf('%s+%s', cfg.version, id.behaviourHash(1:12));
manifest = fullfile(rootDir,'SHA256SUMS.txt');
if isfile(manifest); id.releaseManifestSha256 = avde_sha256_file(manifest); else; id.releaseManifestSha256 = ''; end
end
