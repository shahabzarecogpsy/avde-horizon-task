function tc = avde_preload_game_textures(ds, stim, manifest, imageCache)
% Create PTB textures for one game from the in-RAM image cache (no disk I/O).
idx = unique([stim.previewA(:); stim.previewB(:); stim.outcomeA(:); stim.outcomeB(:)])';
tc.idx = idx; tc.tex = zeros(1,numel(idx)); tc.size = zeros(numel(idx),2);
for k = 1:numel(idx)
    img = imageCache(manifest(idx(k)).sha256);
    tc.tex(k) = Screen('MakeTexture', ds.win, img);
    tc.size(k,:) = [size(img,2) size(img,1)];
end
end
