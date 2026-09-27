function n = avde_game_commit_clear(files)
% Remove journals only after the complete file and CSVs were written.
D = dir(files.commitPattern); n = 0;
for i = 1:numel(D)
    if ~isempty(regexp(D(i).name, files.commitRegex, 'once')); delete(fullfile(D(i).folder, D(i).name)); n = n+1; end
end
% Also remove this participant's orphaned temporary files (*.tmp.mat) that a process
% kill during an atomic save can leave behind (they are never read).
[~, ck] = fileparts(files.checkpoint); [~, lv] = fileparts(files.live); stem = lv(1:end-numel('_live'));
T = [dir(fullfile(fileparts(files.checkpoint), [ck '.tmp.mat'])); dir(fullfile(fileparts(files.live), [stem '*.tmp.mat']))];
for i = 1:numel(T); delete(fullfile(T(i).folder, T(i).name)); end
end
