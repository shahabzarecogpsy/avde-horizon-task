function cache = avde_build_image_cache(ds, cfg, manifests, L)
% Decode every face that can appear (practice + core pools) ONCE at startup,
% downscale it in RAM with an integer box filter to (at least) the largest
% on-screen face height, and keep the pixels in memory only (never saved).
% Per-game texture creation then needs no disk I/O or JPEG decoding.
targetH = max(L.previewLeft(4)-L.previewLeft(2), L.outcomeCenter(4)-L.outcomeCenter(2));
cache = containers.Map('KeyType','char','ValueType','any');
all_ = [];
for m = 1:numel(manifests); for i = 1:numel(manifests{m}); all_(end+1).path = manifests{m}(i).path; all_(end).sha256 = manifests{m}(i).sha256; end; end %#ok<AGROW>
t0 = GetSecs;
for i = 1:numel(all_)
    key = all_(i).sha256;
    if isKey(cache,key); continue; end
    img = imread(all_(i).path);
    if ndims(img)==2; img = repmat(img,[1 1 3]); end
    if size(img,3) > 3; img = img(:,:,1:3); end
    k = max(1, floor(size(img,1) / max(1,targetH)));
    cache(key) = avde_downscale_box(img, k);
end
if cfg.debug.verbose; fprintf('Image cache: %d images in %.1f s.\n', cache.Count, GetSecs-t0); end
end
