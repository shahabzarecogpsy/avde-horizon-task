function audit = avde_audit_reward_schedule(plan, rewards, cfg)
% Structural + realized audit of the reward templates. Throws on any violation.
assert(numel(rewards)==numel(plan),'AVDE:RewardCount','One template per game required.');
tol = cfg.reward.forcedGapTolerance;
lowAll = []; highAll = []; fGap = zeros(1,numel(plan));
for g = 1:numel(plan)
    p = plan(g); r = rewards(g);
    assert(r.game==p.game,'AVDE:RewardGame','Template/game mismatch.');
    for o = 'AB'
        lev = p.(['option' o 'RewardLevel']);
        mu = r.(['mu' o]);
        if strcmp(lev,'High'); assert(abs(mu-p.rewardMeanHigh)<1e-12,'AVDE:RewardMean','High mean mismatch.'); highAll = [highAll r.(['seq' o])]; %#ok<AGROW>
        else; assert(abs(mu-p.rewardMeanLow)<1e-12,'AVDE:RewardMean','Low mean mismatch.'); lowAll = [lowAll r.(['seq' o])]; end %#ok<AGROW>
        seq = r.(['seq' o]); f = r.(['forced' o]);
        assert(numel(seq)==cfg.reward.nPotentialPerSource,'AVDE:RewardLength','Template length.');
        assert(numel(f)==p.(['forcedCount' o]) && isequal(seq(1:numel(f)),f),'AVDE:RewardForced','Forced prefix.');
        assert(all(seq==round(seq)) && all(seq>=cfg.reward.lower) && all(seq<=cfg.reward.upper),'AVDE:RewardBounds','Bounds/integers.');
    end
    fGap(g) = mean(r.(['forced' p.highOption])) - mean(r.(['forced' p.lowOption]));
    assert(abs(fGap(g)-p.rewardGap)<=tol,'AVDE:ForcedGap','Displayed forced gap must equal the latent gap in game %d.',g);
end
assert(numel(unique({rewards.rewardTemplateID}))==numel(rewards),'AVDE:RewardTemplateID','Template IDs must be unique.');
audit = struct('nGames',numel(plan),'minReward',min([lowAll highAll]),'maxReward',max([lowAll highAll]), ...
    'lowMeanRealized',mean(lowAll),'lowSDRealized',std(lowAll),'highMeanRealized',mean(highAll),'highSDRealized',std(highAll), ...
    'forcedGapMin',min(fGap),'forcedGapMax',max(fGap),'maxGenerationAttempt',max([rewards.generationAttempt]));
end
