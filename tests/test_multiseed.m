function test_multiseed(firstSeed, nSeeds, cfdRoot, outFile)
% Plan + reward + stimulus-schedule validation across many participant IDs.
% Every seed must pass avde_validate_plan, avde_audit_reward_schedule and
% avde_validate_stimulus_schedule; summary statistics are written to outFile.
root = fileparts(fileparts(mfilename('fullpath'))); oldPath = path; restorePath = onCleanup(@() path(oldPath)); addpath(fullfile(root,'src')); addpath(root); %#ok<NASGU>
fid = fopen(outFile,'a');
for s = firstSeed:firstSeed+nSeeds-1
    pid = sprintf('SEED%05d', s);
    cfg = avde_config(root, pid, cfdRoot);
    t = tic; plan = avde_build_plan(cfg); rep = avde_validate_plan(plan, cfg); tp = toc(t);
    R = avde_generate_reward_templates(plan, cfg, 'core'); ra = avde_audit_reward_schedule(plan, R, cfg);
    M = avde_build_cfd_manifest(cfg); pools = avde_partition_manifest(M, cfg);
    stim = avde_assign_stimuli_to_plan(plan, pools.core, cfg, 'core'); sr = avde_validate_stimulus_schedule(plan, stim, pools.core, cfg);
    [chiHL, pHL, chiLess, pLess] = local_identity_association(plan, stim, pools.core);
    % run-lengths and section composition
    h = [plan.horizon]; vv = double(strcmp({plan.valenceCondition},'PP'))+2*double(strcmp({plan.valenceCondition},'NN')); mv = 1; c2 = 1; for i = 2:numel(vv); if vv(i)==vv(i-1); c2=c2+1; mv=max(mv,c2); else; c2=1; end; end
    mr = 1; c = 1; for i = 2:numel(h); if h(i)==h(i-1); c=c+1; mr=max(mr,c); else; c=1; end; end
    pr = avde_build_practice_plan(cfg,1); pv = arrayfun(@(p) sprintf('H%d%s',p.horizon,p.valenceCondition), pr, 'UniformOutput', false);
    ok = isequal(sort(pv(:)'), sort({'H1NN','H1PN','H1PP','H6NN','H6PN','H6PP'}));
    if ~ok; error('AVDE:PracticeCoverage','Practice cycle 1 does not cover all cells for %s', pid); end
    fprintf(fid, '%d,%s,%s,%.2f,%d,%d,%d,%d,%d,%.3f,%.3f,%.3f,%.3f,%d,%.4f,%.4f,%.4f,%.4f,%d\n', s, pid, plan(1).planID, tp, ...
        isequal(rep.H6PNJoint, 8*ones(2)), sr.minPlannedImageLag, sr.minPlannedIdentityLag, ra.maxGenerationAttempt, ...
        mr, ra.lowMeanRealized, ra.highMeanRealized, ra.forcedGapMin, ra.forcedGapMax, sr.nImages, chiHL, pHL, chiLess, pLess, ok);
    fflush(fid);
end
fclose(fid);
end

function [c1, p1, c2, p2] = local_identity_association(plan, stim, core)
% identity x (shown with High vs Low option) and identity x (less- vs more-observed option, H6)
ids = unique({core.identityKey}); nI = numel(ids); T1 = zeros(nI,2); T2 = zeros(nI,2);
[~, loc] = ismember({core.identityKey}, ids);
for g = 1:numel(plan)
    p = plan(g); s = stim(g);
    for o = 'AB'
        idx = [s.(['preview' o]) s.(['outcome' o])]; col1 = 1 + strcmp(p.highOption, o);
        for i = idx; T1(loc(i),col1) = T1(loc(i),col1) + 1; end
        if p.horizon == 6
            col2 = 1 + strcmp(p.lessInformativeOption, o);
            for i = idx; T2(loc(i),col2) = T2(loc(i),col2) + 1; end
        end
    end
end
[c1, p1] = local_chi(T1); [c2, p2] = local_chi(T2);
end
function [x, p] = local_chi(T)
T = T(sum(T,2)>0,:); E = sum(T,2)*sum(T,1)/sum(T(:)); x = sum(sum((T-E).^2./E)); df = (size(T,1)-1)*(size(T,2)-1);
p = 1 - gammainc(x/2, df/2);
end
