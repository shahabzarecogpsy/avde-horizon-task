function avde_show_instructions(ds, cfg)
pages = {'instr_01_goal.png','instr_02_sequence.png','instr_03_choices.png'};
for i = 1:numel(pages); avde_show_asset_screen(ds, cfg, pages{i}, true); end
end
