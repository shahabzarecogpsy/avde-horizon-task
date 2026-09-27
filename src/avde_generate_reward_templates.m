function rewards = avde_generate_reward_templates(plan, cfg, streamTag)
% Precompute one independent reward template per game.
%
% Reward contract (single-gap final pilot):
%  * Latent means: Low = center - gap/2 = 18, High = center + gap/2 = 22 (SD 8).
%  * Every reward is an integer drawn from N(mu, SD) truncated to [lower, upper]
%    (rejection sampling), then rounded.
%  * Forced evidence: the forced samples of both options are drawn from those
%    same distributions and a candidate set is accepted only if the displayed
%    sample-mean difference High - Low equals the latent gap EXACTLY (4 points).
%    Hence the observed forced ranking always matches the latent ranking.
%  * Free-choice rewards (the remaining 10 - forcedCount draws per option) are
%    drawn only after the forced set is accepted, so they are unconditioned
%    draws from the latent distributions.
%  * Streams are isolated: the reward RNG depends only on participant, plan
%    hash and streamTag, never on how many random numbers other modules used.
if nargin < 3 || isempty(streamTag); streamTag = 'core'; end
assert(strcmpi(cfg.reward.forcedEvidenceMode,'exact-observed-gap') && cfg.reward.roundToInteger, 'AVDE:RewardMode', ...
    'This release implements only integer rewards with exact observed forced gap.');
oldRng = rng; restoreRng = onCleanup(@() rng(oldRng)); %#ok<NASGU>
seedKey = sprintf('%s|reward|%s|%s|%d', cfg.participantID, streamTag, plan(1).planID, numel(plan));
rng(avde_seed_from_id(seedKey), 'twister');
rewards = repmat(avde_empty_reward(), numel(plan), 1);
nPot = cfg.reward.nPotentialPerSource;
for g = 1:numel(plan)
    p = plan(g);
    mu.A = local_mu(p, 'A'); mu.B = local_mu(p, 'B');
    nF.A = p.forcedCountA; nF.B = p.forcedCountB;
    assert(nF.A>=1 && nF.B>=1 && nF.A+p.horizon<=nPot && nF.B+p.horizon<=nPot, 'AVDE:RewardCounts', 'Reward template too short.');
    hi = p.highOption; lo = p.lowOption;
    accepted = false;
    for attempt = 1:cfg.reward.maxGenerationAttempts
        fA = local_draw(mu.A, nF.A, cfg); fB = local_draw(mu.B, nF.B, cfg);
        f.A = fA; f.B = fB;
        if abs((mean(f.(hi)) - mean(f.(lo))) - p.rewardGap) <= cfg.reward.forcedGapTolerance
            accepted = true; break;
        end
    end
    if ~accepted
        error('AVDE:RewardGeneration','No exact forced evidence for game %d after %d attempts.', p.game, cfg.reward.maxGenerationAttempts);
    end
    tA = local_draw(mu.A, nPot - nF.A, cfg); tB = local_draw(mu.B, nPot - nF.B, cfg);
    r = avde_empty_reward();
    r.game = p.game; r.muA = mu.A; r.muB = mu.B;
    r.seqA = [fA tA]; r.seqB = [fB tB]; r.forcedA = fA; r.forcedB = fB;
    r.forcedMeanA = mean(fA); r.forcedMeanB = mean(fB);
    r.forcedMeanHigh = mean(f.(hi)); r.forcedMeanLow = mean(f.(lo));
    r.forcedGapObserved = r.forcedMeanHigh - r.forcedMeanLow;
    r.forcedGapError = r.forcedGapObserved - p.rewardGap;
    r.nextIndexA = nF.A + 1; r.nextIndexB = nF.B + 1; r.generationAttempt = attempt;
    key = sprintf('%s|G%d|A=%s|B=%s', streamTag, p.game, sprintf('%d,', r.seqA), sprintf('%d,', r.seqB));
    h = avde_sha256_text(key); r.rewardTemplateID = ['RT' upper(h(1:16))];
    rewards(g) = r;
end
end

function m = local_mu(p, opt)
if strcmp(p.(['option' opt 'RewardLevel']),'High'); m = p.rewardMeanHigh; else; m = p.rewardMeanLow; end
end

function x = local_draw(mu, n, cfg)
x = avde_draw_truncnorm(mu, cfg.reward.sd, cfg.reward.lower, cfg.reward.upper, n);
x = round(x);
if any(x < cfg.reward.lower) || any(x > cfg.reward.upper)
    error('AVDE:RewardBounds','Reward outside configured bounds.');
end
end
