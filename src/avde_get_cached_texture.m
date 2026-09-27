function [tex, imgSize] = avde_get_cached_texture(tc, imageIdx)
k = find(tc.idx==imageIdx, 1);
if isempty(k); error('AVDE:TextureCacheMiss','Image %d not prepared for this game.', imageIdx); end
tex = tc.tex(k); imgSize = tc.size(k,:);
end
