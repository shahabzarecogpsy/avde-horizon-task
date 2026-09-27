function manifest = avde_apply_local_validation(manifest, cfg)
% Join independent local validation ratings to CFD files and exclude rejected items.
% Required columns for a scientific run are declared in cfg.stim.requiredValidationColumns.
T=readtable(cfg.stim.localValidationCsv,'TextType','string');
vars=lower(string(T.Properties.VariableNames));
for k=1:numel(cfg.stim.requiredValidationColumns)
    req=lower(string(cfg.stim.requiredValidationColumns{k}));
    if ~any(vars==req)
        error('AVDE:ValidationCSV','Local validation CSV is missing required column: %s',req);
    end
end
keyVar=T.Properties.VariableNames{find(vars=="file",1)};
keys=lower(strtrim(string(T.(keyVar))));
if numel(unique(keys))~=numel(keys)
    error('AVDE:ValidationDuplicate','Validation CSV contains duplicate file keys.');
end

for i=1:numel(manifest)
    j=find(keys==lower(string(manifest(i).file)),1);
    if isempty(j)
        manifest(i).validationInclude=false;
        continue;
    end
    manifest(i).validationInclude=local_bool(T.(local_var(T,vars,'include'))(j));
    manifest(i).localValence=local_num(T.(local_var(T,vars,'local_valence'))(j));
    manifest(i).localArousal=local_num(T.(local_var(T,vars,'local_arousal'))(j));
    manifest(i).expressionIntensity=local_num(T.(local_var(T,vars,'expression_intensity'))(j));
    manifest(i).expressionRecognition=local_num(T.(local_var(T,vars,'expression_recognition'))(j));
    manifest(i).threat=local_num(T.(local_var(T,vars,'threat'))(j));
    manifest(i).approachAvoidance=local_num(T.(local_var(T,vars,'approach_avoidance'))(j));
    if manifest(i).validationInclude && ~all(isfinite([manifest(i).localValence manifest(i).localArousal manifest(i).expressionIntensity manifest(i).expressionRecognition manifest(i).threat manifest(i).approachAvoidance]))
        error('AVDE:ValidationMissingRating','Included file %s has a missing/non-numeric required local rating.',manifest(i).file);
    end
    manifest(i).matchStratum=local_optional_text(T,vars,'match_stratum',j);
    manifest(i).gender=local_optional_text(T,vars,'gender',j);
    manifest(i).race=local_optional_text(T,vars,'race',j);
    manifest(i).attractiveness=local_optional_num(T,vars,'attractiveness',j);
    manifest(i).perceivedAge=local_optional_num(T,vars,'perceived_age',j);
    if manifest(i).validationInclude && (isempty(strtrim(manifest(i).matchStratum)) || isempty(strtrim(manifest(i).gender)) || isempty(strtrim(manifest(i).race)) || ...
            ~isfinite(manifest(i).attractiveness) || ~isfinite(manifest(i).perceivedAge))
        error('AVDE:ValidationMissingMetadata','Included file %s lacks required matching metadata.',manifest(i).file);
    end
end
manifest=manifest([manifest.validationInclude]);
if isempty(manifest); error('AVDE:ValidationEmpty','Local validation excluded every candidate CFD image.'); end
end

function v=local_var(T,vars,name) %#ok<INUSD>
pos=find(vars==lower(string(name)),1); v=T.Properties.VariableNames{pos};
end
function x=local_num(v)
if isnumeric(v) || islogical(v); x=double(v); else; x=str2double(string(v)); end
if isempty(x) || ~isfinite(x); x=NaN; end
end
function x=local_optional_num(T,vars,name,j)
pos=find(vars==lower(string(name)),1); if isempty(pos); x=NaN; else; x=local_num(T.(T.Properties.VariableNames{pos})(j)); end
end
function x=local_optional_text(T,vars,name,j)
pos=find(vars==lower(string(name)),1); if isempty(pos); x=''; else; x=char(string(T.(T.Properties.VariableNames{pos})(j))); end
end
function tf=local_bool(v)
if islogical(v); tf=logical(v); return; end
if isnumeric(v); tf=isfinite(v) && double(v)~=0; return; end
s=lower(strtrim(string(v))); tf=any(s==["1","true","yes","y","include"]);
end
