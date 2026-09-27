function archiveDir = avde_archive_incomplete_session(cfg, files, reason)
% Move (never delete) every recovery file of an incomplete run to data/archive.
archiveDir = fullfile(cfg.paths.archive, sprintf('%s_%s_%s', regexprep(cfg.participantID,'[^A-Za-z0-9_\-]','_'), datestr(now,'yyyymmdd_HHMMSS'), reason));
mkdir(archiveDir);
cand = {files.checkpoint, files.live};
D = dir(files.commitPattern); for i = 1:numel(D); cand{end+1} = fullfile(D(i).folder, D(i).name); end %#ok<AGROW>
for i = 1:numel(cand)
    if isfile(cand{i}); [ok,msg] = movefile(cand{i}, archiveDir); if ~ok; error('AVDE:Archive','%s',msg); end; end
end
fid = fopen(fullfile(archiveDir,'ARCHIVE_REASON.txt'),'w'); fprintf(fid,'%s\n%s\n',reason,avde_now()); fclose(fid);
end
