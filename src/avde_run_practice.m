function [passed, practice] = avde_run_practice(ds, L, cfg, pool, imageCache)
% Practice + comprehension gate (max cfg.practice.maxCycles cycles).
practice.cycles = struct('cycle',{},'plan',{},'gameLogs',{},'gameSummaries',{},'comprehension',{},'passed',{});
passed = false;
pcfg = cfg; pcfg.stim.minImageLagGames = 1; pcfg.stim.minIdentityLagGames = 1;
for cycle = 1:cfg.practice.maxCycles
    plan = avde_build_practice_plan(cfg, cycle);
    for g = 1:numel(plan); plan(g).planID = sprintf('PRACTICE_C%d', cycle); end
    rewards = avde_generate_reward_templates(plan, cfg, sprintf('practice_c%d', cycle));
    stim = avde_assign_stimuli_to_plan(plan, pool, pcfg, sprintf('practice_c%d', cycle));
    logs = cell(numel(plan),1); sums = repmat(avde_empty_game_summary(), numel(plan), 1); prevEnd = NaN;
    for g = 1:numel(plan)
        guided = cycle == 1 && g <= cfg.practice.guidedGames;
        if guided; avde_show_asset_screen(ds, cfg, sprintf('practice_guided_%d.png', g), true); prevEnd = NaN; end
        if g == 1 && cycle > 1; avde_show_asset_screen(ds, cfg, 'practice_repeat.png', true); prevEnd = NaN; end
        opts = struct('isPractice',true,'previousGameEndOnset',prevEnd,'progress',[],'liveFile','');
        [logs{g}, sums(g)] = avde_run_game(ds, L, cfg, plan(g), rewards(g), stim(g), pool, imageCache, opts);
        prevEnd = sums(g).gameEndOnset;
    end
    avde_show_asset_screen(ds, cfg, 'comp_intro.png', true);
    [ok, answers] = avde_run_comprehension(ds, cfg);
    practice.cycles(cycle) = struct('cycle',cycle,'plan',plan,'gameLogs',{logs},'gameSummaries',sums,'comprehension',answers,'passed',ok);
    if ok
        passed = true; avde_show_asset_screen(ds, cfg, 'comp_pass.png', true); return;
    end
    if cycle < cfg.practice.maxCycles
        avde_show_asset_screen(ds, cfg, 'comp_fail.png', true);
        avde_show_instructions(ds, cfg);
    else
        avde_show_asset_screen(ds, cfg, 'comp_stop.png', true);
    end
end
end
