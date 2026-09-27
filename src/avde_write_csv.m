function avde_write_csv(S, file)
% Portable CSV writer for a struct array of scalar numeric/logical/char fields.
if isempty(S); return; end
S = S(:); f = fieldnames(S);
fid = fopen(file, 'w', 'n', 'UTF-8'); if fid < 0; error('AVDE:CSV','Cannot write %s', file); end
c = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', strjoin(f', ','));
for i = 1:numel(S)
    v = cell(1,numel(f));
    for k = 1:numel(f)
        x = S(i).(f{k});
        if ischar(x)
            v{k} = ['"' strrep(x,'"','""') '"'];
        elseif islogical(x) && isscalar(x)
            v{k} = sprintf('%d', x);
        elseif isnumeric(x) && isscalar(x)
            if isnan(x); v{k} = ''; elseif x==round(x) && abs(x)<1e9; v{k} = sprintf('%d', x); else; v{k} = sprintf('%.6f', x); end
        elseif isnumeric(x)
            v{k} = ['"' strtrim(sprintf('%g ', x)) '"'];
        else
            v{k} = '';
        end
    end
    fprintf(fid, '%s\n', strjoin(v, ','));
end
end
