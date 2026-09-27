function plan = avde_build_practice_plan(cfg, cycle)
% Practice mirrors the final pilot exactly (same horizons, information
% structures, pair types, single gap 4, timing and displays).
% Cycle 1: six games, one per horizon x valence condition. Games 1-2 are
%   guided (H1-PP then H6-PP); the remaining four are in random order.
% Cycle >= 2 (only after a failed comprehension check): three games
%   (H1-PN, H6-PN, and H6-PP or H6-NN at random), in random order.
% Every presentation/design choice not fixed above (which option is High,
% sides, preview order, forced order, which H6 option is less observed and,
% in PN, which valence is High / less observed) is drawn at random per game,
% so practice cannot teach a fixed structural regularity.
if nargin < 2; cycle = 1; end
oldRng = rng; restoreRng = onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(avde_seed_from_id(sprintf('%s|practice|%d', cfg.participantID, cycle)),'twister');
if cycle == 1
    cells = {1,'PP'; 6,'PP'};
    rest = {1,'NN'; 6,'NN'; 1,'PN'; 6,'PN'}; rest = rest(randperm(4),:);
    cells = [cells; rest];
else
    extra = {'PP','NN'}; cells = {1,'PN'; 6,'PN'; 6,extra{randi(2)}}; cells = cells(randperm(3),:);
end
if cycle == 1; assert(size(cells,1) == cfg.practice.nGames, 'AVDE:PracticeConfig', 'cfg.practice.nGames must equal the six practice cells.'); end
plan = repmat(avde_empty_planrow(), size(cells,1), 1);
for g = 1:size(cells,1)
    h = cells{g,1}; vc = cells{g,2};
    switch vc
        case 'PP'; lowVal = 'Positive'; highVal = 'Positive';
        case 'NN'; lowVal = 'Negative'; highVal = 'Negative';
        case 'PN'; if rand < 0.5; lowVal = 'Positive'; highVal = 'Negative'; else; lowVal = 'Negative'; highVal = 'Positive'; end
    end
    if h == 1
        lessObs = 'Equal'; orders = {'HHLL','HLHL','HLLH','LHHL','LHLH','LLHH'}; hl = orders{randi(6)};
    else
        if rand < 0.5; lessObs = 'High'; hl = 'LLLL'; hl(randi(4)) = 'H'; else; lessObs = 'Low'; hl = 'HHHH'; hl(randi(4)) = 'L'; end
    end
    spec = struct('atomID',sprintf('PRACTICE_H%d_%s',h,vc),'atomIndex',0,'horizon',h,'vc',vc, ...
        'lowVal',lowVal,'highVal',highVal,'lessObs',lessObs,'highIsA',rand<0.5,'highLeft',rand<0.5, ...
        'previewHighFirst',rand<0.5,'forcedOrderHL',hl);
    r = avde_make_game_row(spec, cfg);
    r.planID = sprintf('PRACTICE_C%d', cycle); r.game = -(100*cycle + g); r.section = 0; r.sectionPosition = g;
    plan(g) = r;
end
end
