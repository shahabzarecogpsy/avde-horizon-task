function manifest = avde_build_cfd_manifest(cfg)
% Scan the local CFD folder (images are never bundled or modified).
% Main-CFD filenames: CFD-<race><gender>-<model>-<photo>-<expression>, e.g. CFD-WF-001-003-HC.
% identityKey = CFD-<race><gender>-<model>; race/gender are parsed from the filename
% and overridden by the local-validation CSV if one is supplied.
root = cfg.paths.cfdRoot;
if isempty(root) || ~isfolder(root); error('AVDE:CFDRoot','CFD root is missing or invalid: %s',root); end
rel = avde_list_files(root, {});
empty = avde_empty_manifest_row();
rows = repmat(empty, 0, 1);
for i = 1:numel(rel)
    [~,nm,ext] = fileparts(rel{i});
    if ~any(strcmpi(ext, cfg.stim.allowedExtensions)); continue; end
    % No nested groups: MATLAB and Octave return nested tokens differently.
    tok = regexpi(nm,'^CFD-([A-Z])([FM])-([0-9]{3})-([0-9]{3})-(HC|HO|N|A|F)$','tokens','once');
    if isempty(tok) || numel(tok) ~= 5; continue; end
    expr = upper(tok{5}); vc = '';
    if any(strcmp(expr,cfg.stim.positiveExpressions)); vc = 'Positive'; end
    if any(strcmp(expr,cfg.stim.negativeExpressions)); vc = 'Negative'; end
    if isempty(vc); continue; end
    r = empty;
    r.path = fullfile(root, strrep(rel{i},'/',filesep)); r.file = [nm ext]; r.expression = expr;
    r.race = upper(tok{1}); r.gender = upper(tok{2});
    r.modelID = sprintf('CFD-%s%s-%s', r.race, r.gender, tok{3}); r.identityKey = r.modelID; r.valenceClass = vc;
    r.validationInclude = true;
    rows(end+1,1) = r; %#ok<AGROW>
end
if isempty(rows); error('AVDE:NoCFDImages','No usable CFD HC/A images found below %s',root); end
keys = lower({rows.file});
if numel(unique(keys)) ~= numel(keys); error('AVDE:DuplicateCFDFilename','Duplicate CFD file names below CFD root.'); end
[~,ord] = sort(keys); rows = rows(ord);
if cfg.stim.requireLocalValidation || (~isempty(cfg.stim.localValidationCsv) && isfile(cfg.stim.localValidationCsv))
    if isempty(cfg.stim.localValidationCsv) || ~isfile(cfg.stim.localValidationCsv)
        error('AVDE:ValidationRequired','Set AVDE_LOCAL_VALIDATION_CSV to the locked item-level validation file.');
    end
    rows = avde_apply_local_validation(rows, cfg);
    avde_validate_local_bank(rows, cfg);
end
% keep identities that have every configured Positive and Negative expression
req = [cfg.stim.positiveExpressions cfg.stim.negativeExpressions];
ids = unique({rows.identityKey}); keepID = false(size(ids));
for k = 1:numel(ids)
    ex = {rows(strcmp({rows.identityKey},ids{k})).expression};
    keepID(k) = all(ismember(req, ex));
end
rows = rows(ismember({rows.identityKey}, ids(keepID)));
for i = 1:numel(rows); rows(i).sha256 = avde_sha256_file(rows(i).path); end
manifest = rows;
end
