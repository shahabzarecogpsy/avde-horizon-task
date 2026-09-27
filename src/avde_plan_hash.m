function h = avde_plan_hash(plan)
% SHA-256 of a canonical text serialization of every scientific/presentation
% field of the plan (planID itself excluded so the hash can define it).
f = {'game','section','sectionPosition','atomID','horizon','information','valenceCondition','pairType', ...
    'rewardGap','rewardMeanLow','rewardMeanHigh','highOption','optionARewardLevel','optionAValence', ...
    'optionBRewardLevel','optionBValence','moreInformativeOption','lessInformativeOption', ...
    'lessObservedRewardLevel','lessObservedValence','forcedCountA','forcedCountB','forcedSequence', ...
    'optionASide','optionBSide','previewOrder'};
parts = cell(1,numel(plan));
for g = 1:numel(plan)
    v = cell(1,numel(f));
    for k = 1:numel(f)
        x = plan(g).(f{k});
        if ischar(x); v{k} = x; else; v{k} = sprintf('%.10g',x); end
    end
    parts{g} = strjoin(v,',');
end
h = avde_sha256_text(strjoin(parts,';'));
end
