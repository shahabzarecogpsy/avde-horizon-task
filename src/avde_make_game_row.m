function r = avde_make_game_row(spec, cfg)
% Construct one plan row from explicit, independent design choices.
% spec fields: atomID, atomIndex, horizon (1|6), vc ('PP'|'NN'|'PN'),
%   lowVal, highVal ('Positive'|'Negative'), lessObs ('Equal'|'High'|'Low'),
%   highIsA, highLeft, previewHighFirst (logical), forcedOrderHL (4 chars of H/L).
r = avde_empty_planrow();
r.atomID = spec.atomID; r.atomIndex = spec.atomIndex;
r.horizon = spec.horizon; r.valenceCondition = spec.vc;
r.rewardGap = cfg.reward.gap; r.rewardCenter = cfg.reward.center; r.rewardSD = cfg.reward.sd;
r.rewardMeanLow = cfg.reward.center - cfg.reward.gap/2; r.rewardMeanHigh = cfg.reward.center + cfg.reward.gap/2;
r.pairType = sprintf('%s_L%s_H%s', spec.vc, spec.lowVal(1), spec.highVal(1));
if spec.highIsA; hi = 'A'; lo = 'B'; else; hi = 'B'; lo = 'A'; end
r.highOption = hi; r.lowOption = lo;
r.(['option' hi 'RewardLevel']) = 'High'; r.(['option' lo 'RewardLevel']) = 'Low';
r.(['option' hi 'Valence']) = spec.highVal; r.(['option' lo 'Valence']) = spec.lowVal;
hl = spec.forcedOrderHL;
if spec.horizon == 1
    assert(strcmp(spec.lessObs,'Equal') && sum(hl=='H')==2 && sum(hl=='L')==2, 'AVDE:GameRow','H1 must be Equal [2 2].');
    r.information = 'Equal'; r.moreInformativeOption = 'Equal'; r.lessInformativeOption = 'Equal';
    r.lessObservedRewardLevel = 'Equal'; r.lessObservedValence = 'Equal';
else
    assert(spec.horizon==6 && any(strcmp(spec.lessObs,{'High','Low'})), 'AVDE:GameRow','H6 must be Unequal [3 1].');
    if strcmp(spec.lessObs,'High'); less = hi; more = lo; lessL = 'H'; else; less = lo; more = hi; lessL = 'L'; end
    assert(sum(hl==lessL)==1 && numel(hl)==4, 'AVDE:GameRow','H6 forced order must contain one less-observed sample.');
    r.information = 'Unequal'; r.moreInformativeOption = more; r.lessInformativeOption = less;
    r.lessObservedRewardLevel = spec.lessObs; r.lessObservedValence = r.(['option' less 'Valence']);
end
r.forcedOrderHL = hl;
seq = hl; seq(hl=='H') = hi; seq(hl=='L') = lo; r.forcedSequence = seq;
r.forcedCountA = sum(seq=='A'); r.forcedCountB = sum(seq=='B');
if spec.highLeft; r.leftSource = hi; r.rightSource = lo; else; r.leftSource = lo; r.rightSource = hi; end
if strcmp(r.leftSource,'A'); r.optionASide = 'L'; r.optionBSide = 'R'; else; r.optionASide = 'R'; r.optionBSide = 'L'; end
r.leftRewardLevel = r.(['option' r.leftSource 'RewardLevel']);  r.leftValence = r.(['option' r.leftSource 'Valence']);
r.rightRewardLevel = r.(['option' r.rightSource 'RewardLevel']); r.rightValence = r.(['option' r.rightSource 'Valence']);
if spec.previewHighFirst; first = hi; second = lo; else; first = lo; second = hi; end
r.previewOrder = [first second second first]; r.previewFirstSource = first;
end
