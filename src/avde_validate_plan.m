function report = avde_validate_plan(plan, cfg)
% Exhaustive validation of the final-pilot design. Any violation throws an
% error BEFORE data collection. Checks the full joint design, not marginals.
P = plan(:);
N = numel(P);
req(N==112 && cfg.task.nGames==112, 'PlanSize', 'exactly 112 games');
req(isequal([P.game], 1:N), 'GameIndex', 'games numbered 1..112 in order');

H = [P.horizon]; VC = {P.valenceCondition};
isH1 = H==1; isH6 = H==6;
req(sum(isH1)==48 && sum(isH6)==64 && all(isH1|isH6), 'HorizonCounts', 'H1=48, H6=64');
req(all(strcmp({P(isH1).information},'Equal')) && all([P(isH1).forcedCountA]==2) && all([P(isH1).forcedCountB]==2), 'H1Info', 'H1 information [2 2] only');
for g = find(isH6)
    p = P(g);
    req(strcmp(p.information,'Unequal') && isequal(sort([p.forcedCountA p.forcedCountB]),[1 3]), 'H6Info', 'H6 information [3 1] only');
    req(p.(['forcedCount' p.lessInformativeOption])==1 && p.(['forcedCount' p.moreInformativeOption])==3, 'H6InfoLabels', 'more/less labels match forced counts');
end
cnt = @(m) sum(m);
req(cnt(isH1&strcmp(VC,'PP'))==16 && cnt(isH1&strcmp(VC,'NN'))==16 && cnt(isH1&strcmp(VC,'PN'))==16, 'H1Valence', 'H1 PP/NN/PN = 16/16/16');
req(cnt(isH6&strcmp(VC,'PP'))==16 && cnt(isH6&strcmp(VC,'NN'))==16 && cnt(isH6&strcmp(VC,'PN'))==32, 'H6Valence', 'H6 PP/NN/PN = 16/16/32');

% Per-game semantic consistency
for g = 1:N
    p = P(g);
    req(any(strcmp(p.highOption,{'A','B'})) && ~strcmp(p.highOption,p.lowOption) && any(strcmp(p.lowOption,{'A','B'})), 'HighLabel', 'High/Low labels');
    req(strcmp(p.(['option' p.highOption 'RewardLevel']),'High') && strcmp(p.(['option' p.lowOption 'RewardLevel']),'Low'), 'RewardLevels', 'reward levels match High label');
    req(p.rewardGap==cfg.reward.gap && abs(p.rewardMeanHigh-p.rewardMeanLow-cfg.reward.gap)<1e-12 && ...
        abs(p.rewardMeanLow-(cfg.reward.center-cfg.reward.gap/2))<1e-12 && p.rewardSD==cfg.reward.sd, 'RewardConstants', 'single gap and means');
    va = p.optionAValence; vb = p.optionBValence;
    switch p.valenceCondition
        case 'PP'; req(strcmp(va,'Positive')&&strcmp(vb,'Positive'), 'PairSemantics', 'PP');
        case 'NN'; req(strcmp(va,'Negative')&&strcmp(vb,'Negative'), 'PairSemantics', 'NN');
        case 'PN'; req(~strcmp(va,vb) && all(ismember({va,vb},{'Positive','Negative'})), 'PairSemantics', 'PN');
        otherwise; req(false,'PairSemantics','unknown valence condition');
    end
    expPT = sprintf('%s_L%s_H%s',p.valenceCondition,p.(['option' p.lowOption 'Valence'])(1),p.(['option' p.highOption 'Valence'])(1));
    req(strcmp(p.pairType,expPT), 'PairType', 'pairType label consistent');
    seq = p.forcedSequence;
    req(numel(seq)==4 && sum(seq=='A')==p.forcedCountA && sum(seq=='B')==p.forcedCountB, 'ForcedSequence', 'forced sequence counts');
    hl = seq; hl(seq==p.highOption)='H'; hl(seq==p.lowOption)='L';
    req(strcmp(hl,p.forcedOrderHL), 'ForcedOrderHL', 'forced order H/L coding');
    req(any(strcmp(p.leftSource,{'A','B'})) && ~strcmp(p.leftSource,p.rightSource), 'Sides', 'side mapping');
    req(strcmp(p.(['option' p.leftSource 'Side']),'L') && strcmp(p.(['option' p.rightSource 'Side']),'R'), 'SideLabels', 'side labels');
    req(strcmp(p.leftRewardLevel,p.(['option' p.leftSource 'RewardLevel'])) && strcmp(p.leftValence,p.(['option' p.leftSource 'Valence'])), 'LeftFields', 'left fields');
    req(strcmp(p.rightRewardLevel,p.(['option' p.rightSource 'RewardLevel'])) && strcmp(p.rightValence,p.(['option' p.rightSource 'Valence'])), 'RightFields', 'right fields');
    po = p.previewOrder;
    req(numel(po)==4 && po(1)==po(4) && po(2)==po(3) && po(1)~=po(2) && po(1)==p.previewFirstSource, 'PreviewOrder', 'preview XYYX');
    if p.horizon==6
        req(strcmp(p.lessObservedRewardLevel,p.(['option' p.lessInformativeOption 'RewardLevel'])) && ...
            strcmp(p.lessObservedValence,p.(['option' p.lessInformativeOption 'Valence'])), 'LessObservedFields', 'less-observed descriptors');
    end
end

% ---- joint design cells -------------------------------------------------
h1pn = P(isH1 & strcmp(VC,'PN'));
posHigh = arrayfun(@(p) strcmp(p.(['option' p.highOption 'Valence']),'Positive'), h1pn);
req(sum(posHigh)==8 && sum(~posHigh)==8, 'H1PNValenceReward', 'H1-PN Positive-High / Negative-High = 8/8');
for vc = {'PP','NN'}
    s = P(isH6 & strcmp(VC,vc{1}));
    req(sum(strcmp({s.lessObservedRewardLevel},'High'))==8 && sum(strcmp({s.lessObservedRewardLevel},'Low'))==8, ['H6' vc{1} 'LessObs'], ['H6-' vc{1} ' less-observed High/Low = 8/8']);
end
pn6 = P(isH6 & strcmp(VC,'PN'));
T = zeros(2,2); vals = {'Negative','Positive'}; levs = {'High','Low'};
for i=1:2; for j=1:2
    T(i,j) = sum(strcmp({pn6.lessObservedValence},vals{i}) & strcmp({pn6.lessObservedRewardLevel},levs{j}));
end; end
req(isequal(T,8*ones(2,2)), 'H6PNJoint', 'H6-PN less-observed valence x reward = 8/8/8/8');
posLess = sum(strcmp({pn6.lessObservedValence},'Positive'));
posMore = sum(arrayfun(@(p) strcmp(p.(['option' p.moreInformativeOption 'Valence']),'Positive'), pn6));
negLess = sum(strcmp({pn6.lessObservedValence},'Negative'));
negMore = sum(arrayfun(@(p) strcmp(p.(['option' p.moreInformativeOption 'Valence']),'Negative'), pn6));
hiLess = sum(strcmp({pn6.lessObservedRewardLevel},'High'));
hiMore = sum(arrayfun(@(p) strcmp(p.(['option' p.moreInformativeOption 'RewardLevel']),'High'), pn6));
req(posLess==16 && posMore==16 && negLess==16 && negMore==16, 'H6PNValenceInfo', 'H6-PN Positive/Negative less- vs more-observed = 16/16');
req(hiLess==16 && hiMore==16, 'H6PNRewardInfo', 'H6-PN High less- vs more-observed = 16/16');

% ---- presentation counterbalancing (exact within every 8-game atom) -------
atomIDs = unique({P.atomID});
req(numel(atomIDs)==14, 'Atoms', '14 atoms');
for a = 1:numel(atomIDs)
    s = P(strcmp({P.atomID},atomIDs{a}));
    req(numel(s)==8, 'AtomSize', 'atom size 8');
    hiA = strcmp({s.highOption},'A');
    hiL = strcmp({s.leftSource},{s.highOption});
    pvH = strcmp({s.previewFirstSource},{s.highOption});
    req(sum(hiA)==4 && sum(hiL)==4 && sum(pvH)==4, 'AtomMarginals', ['balanced A/B, side, preview in ' atomIDs{a}]);
    % full 2x2x2 factorial: every combination exactly once
    code = 4*hiA + 2*hiL + pvH;
    req(isequal(sort(code),0:7), 'AtomFactorial', ['2x2x2 factorial in ' atomIDs{a}]);
    if s(1).horizon==1
        first = cellfun(@(x) x(1),{s.forcedOrderHL}); last = cellfun(@(x) x(4),{s.forcedOrderHL});
        c = 2*(first=='H') + (last=='H');
        req(isequal(local_hist(c,0:3),[2 2 2 2]), 'H1ForcedOrder', ['H1 first/last forced sample balanced in ' atomIDs{a}]);
        req(numel(unique({s.forcedOrderHL}))==6, 'H1ForcedOrderSet', 'all six 2:2 orders used');
    else
        pos = arrayfun(@(p) find(p.forcedSequence==p.lessInformativeOption), s);
        req(isequal(local_hist(pos,1:4),[2 2 2 2]), 'H6ForcedOrder', ['H6 less-observed sample position balanced in ' atomIDs{a}]);
        lessL = strcmp({s.leftSource},{s.lessInformativeOption});
        req(sum(lessL)==4, 'H6LessSide', ['less-observed side balanced in ' atomIDs{a}]);
    end
    if strcmp(s(1).valenceCondition,'PN')
        req(sum(strcmp({s.leftValence},'Positive'))==4, 'PNSide', ['Positive side balanced in ' atomIDs{a}]);
    end
end
% global presentation balance
hiAll = strcmp({P.highOption},'A'); req(sum(hiAll)==56, 'HighAB', 'High A/B = 56/56');
posA = sum(strcmp({P.optionAValence},'Positive')); posB = sum(strcmp({P.optionBValence},'Positive'));
req(posA==posB, 'PositiveAB', 'Positive A/B balanced');
mi = {P(isH6).moreInformativeOption}; req(sum(strcmp(mi,'A'))==32 && sum(strcmp(mi,'B'))==32, 'MoreInfAB', 'more-informed A/B = 32/32');
req(sum(strcmp({P.leftSource},{P.highOption}))==56, 'HighSide', 'High left/right = 56/56');
req(sum(strcmp({P.optionASide},'L'))==56, 'ASide', 'option A left/right = 56/56');

% ---- sections and breaks ----------------------------------------------------
S = [P.section];
req(isequal(S, repelem(1:7,16)), 'Sections', 'seven consecutive 16-game sections');
req(isequal(cfg.task.breakAfterGames,[16 32 48 64 80 96]), 'Breaks', 'breaks after 16,32,48,64,80,96');
secH1 = arrayfun(@(s) sum(isH1 & S==s), 1:7);
req(isequal(sort(secH1),[6 7 7 7 7 7 7]), 'SectionHorizon', 'H1 per section = six 7s and one 6');
for a = 1:numel(atomIDs)
    sa = S(strcmp({P.atomID},atomIDs{a}));
    req(all(ismember(1:7, sa)) && max(local_hist(sa,1:7))==2, 'SectionAtoms', ['atom spread over all sections: ' atomIDs{a}]);
end
for s = 1:7
    r = P(S==s);
    req(abs(sum(strcmp({r.leftSource},{r.highOption}))-8)<=2, 'SectionSide', 'High side near-balanced within section');
end

% run-length limits over the whole 112-game sequence (breaks do not reset them)
req(local_maxrun(H) <= cfg.plan.maxRunSameHorizon, 'RunHorizon', 'max run of same horizon');
req(local_maxrun(double(strcmp(VC,'PP')) + 2*double(strcmp(VC,'NN'))) <= cfg.plan.maxRunSameValenceCondition, 'RunValence', 'max run of same valence condition');

report = struct('status','PASS','nGames',N,'planID',P(1).planID, ...
    'H6PNJoint',T,'H6PNRows',{vals},'H6PNCols',{levs},'sectionH1',secH1);
end

function req(cond, id, msg)
if ~cond; error(['AVDE:Plan' id], 'Plan validation failed: %s', msg); end
end

function h = local_hist(x, edges)
h = zeros(1,numel(edges));
for k = 1:numel(edges); h(k) = sum(x(:)==edges(k)); end
end

function m = local_maxrun(x)
m = 1; c = 1;
for i = 2:numel(x); if x(i)==x(i-1); c = c+1; m = max(m,c); else; c = 1; end; end
end
