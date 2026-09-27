function f = avde_paths_for(cfg)
% All per-participant recovery/output file names in one place.
id = regexprep(char(cfg.participantID),'[^A-Za-z0-9_\-]','_');
pr = regexprep(char(cfg.protocolVersion),'[^A-Za-z0-9_\-]','_');
f.checkpoint = fullfile(cfg.paths.checkpoints, sprintf('%s_%s_checkpoint.mat', id, pr));
f.live = fullfile(cfg.paths.live, sprintf('%s_%s_live.mat', id, pr));
f.commitPattern = fullfile(cfg.paths.live, sprintf('%s_%s_core_*_commit.mat', id, pr));
f.commitRegex = ['^' regexptranslate('escape', sprintf('%s_%s_core_', id, pr)) '(\d{3})_commit\.mat$'];
f.commit = @(g) fullfile(cfg.paths.live, sprintf('%s_%s_core_%03d_commit.mat', id, pr, g));
f.final = fullfile(cfg.paths.output, sprintf('%s_%s_complete.mat', id, pr));
f.error = fullfile(cfg.paths.output, sprintf('%s_%s_ERROR.mat', id, pr));
f.prefix = fullfile(cfg.paths.output, id);
end
