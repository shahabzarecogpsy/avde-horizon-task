function e = avde_fill_event_design(e, cfg, p, reward, history, stimMapID)
if nargin < 6; stimMapID = ''; end
e.participantID = cfg.participantID; e.buildID = cfg.buildID; e.planID = p.planID; e.stimulusMapID = stimMapID;
e.rewardTemplateID = reward.rewardTemplateID;
e.game = p.game; e.section = p.section; e.sectionPosition = p.sectionPosition; e.atomID = p.atomID;
f = {'horizon','information','valenceCondition','pairType','highOption','optionARewardLevel','optionAValence', ...
     'optionBRewardLevel','optionBValence','moreInformativeOption','lessInformativeOption','lessObservedRewardLevel', ...
     'lessObservedValence','forcedCountA','forcedCountB','forcedSequence','forcedOrderHL','previewOrder', ...
     'optionASide','optionBSide','leftSource','rightSource','leftRewardLevel','leftValence','rightRewardLevel','rightValence', ...
     'rewardGap','rewardMeanLow','rewardMeanHigh','rewardSD'};
for k = 1:numel(f); e.(f{k}) = p.(f{k}); end
e.forcedMeanA = reward.forcedMeanA; e.forcedMeanB = reward.forcedMeanB; e.forcedGapObserved = reward.forcedGapObserved;
[e.displayedMeanA, e.displayedMeanB] = avde_history_stats(history);
end
