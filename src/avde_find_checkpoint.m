function [found, session] = avde_find_checkpoint(files)
found = false; session = [];
if isfile(files.checkpoint)
    S = load(files.checkpoint, 'session'); session = S.session; found = true;
end
end
