function avde_verify_stimulus_pool_files(pools)
% Verify locally stored CFD files against hashes saved at schedule creation.
names=fieldnames(pools);
for f=1:numel(names)
    M=pools.(names{f});
    if ~isstruct(M) || isempty(M) || ~isfield(M,'path') || ~isfield(M,'sha256'); continue; end
    for i=1:numel(M)
        if ~isfile(M(i).path); error('AVDE:StimulusFileMissing','Missing CFD file on resume: %s',M(i).path); end
        actual=avde_sha256_file(M(i).path);
        if ~strcmpi(actual,M(i).sha256); error('AVDE:StimulusFileHashMismatch','CFD file changed since schedule creation: %s',M(i).file); end
    end
end
end
