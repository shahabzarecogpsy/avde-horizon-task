function files = avde_list_files(rootDir, excludeTopDirs)
% Recursive, portable file listing. Returns relative paths with '/' separators, sorted.
if nargin < 2; excludeTopDirs = {}; end
files = {};
stack = {''};
while ~isempty(stack)
    rel = stack{end}; stack(end) = [];
    d = dir(fullfile(rootDir, rel));
    for k = 1:numel(d)
        nm = d(k).name;
        if any(strcmp(nm,{'.','..'})); continue; end
        if isempty(rel); r = nm; else; r = [rel '/' nm]; end
        if d(k).isdir
            if isempty(rel) && any(strcmp(nm, excludeTopDirs)); continue; end
            if any(strcmp(nm,{'__pycache__','.git'})); continue; end
            stack{end+1} = r; %#ok<AGROW>
        else
            if numel(nm)>4 && strcmp(nm(end-3:end),'.pyc'); continue; end
            files{end+1} = r; %#ok<AGROW>
        end
    end
end
files = sort(files);
end
