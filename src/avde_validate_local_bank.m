function audit=avde_validate_local_bank(manifest,cfg)
% Enforce the locked psychometric gates on the included local CFD bank.
% This is a software consistency gate, not a substitute for the independent
% crossed rater-by-stimulus validation analysis that produced the CSV.
if isempty(manifest); error('AVDE:LocalBankEmpty','Validated CFD bank is empty.'); end
rr=cfg.stim.validation.ratingRange;
fields={'localValence','localArousal','expressionIntensity','expressionRecognition','threat','approachAvoidance'};
for f=1:numel(fields)
    x=[manifest.(fields{f})];
    if any(~isfinite(x) | x<rr(1) | x>rr(2))
        error('AVDE:ValidationRange','Included field %s must be finite and within %.1f..%.1f.',fields{f},rr(1),rr(2));
    end
end
classes={'Positive','Negative'};
mu=zeros(1,2); n=zeros(1,2);
for c=1:2
    idx=strcmp({manifest.valenceClass},classes{c}); n(c)=sum(idx);
    if n(c)==0; error('AVDE:ValidationClassEmpty','Validated bank has no %s items.',classes{c}); end
    mu(c)=mean([manifest(idx).localValence]);
end
sepPN=mu(1)-mu(2);
if sepPN<cfg.stim.validation.minValenceClassSeparation
    error('AVDE:ValidationValenceSeparation', ...
        'Included bank fails class-level valence separation: Positive-Negative %.2f; require >= %.2f.', ...
        sepPN,cfg.stim.validation.minValenceClassSeparation);
end
for c=1:2
    x=[manifest(strcmp({manifest.valenceClass},classes{c})).expressionRecognition];
    if any(x<cfg.stim.validation.minRecognitionAffectiveClasses)
        error('AVDE:ValidationRecognition','Every included %s item must have expression recognition >= %.1f%%.', ...
            classes{c},cfg.stim.validation.minRecognitionAffectiveClasses);
    end
end
audit=struct('nPositive',n(1),'nNegative',n(2), ...
    'meanValencePositive',mu(1),'meanValenceNegative',mu(2), ...
    'classValenceSeparation',sepPN, ...
    'minRecognitionAffectiveClasses',cfg.stim.validation.minRecognitionAffectiveClasses);
end
