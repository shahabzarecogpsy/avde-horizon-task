function avde_close_texture_cache(tc)
if isempty(tc) || ~isfield(tc,'tex'); return; end
t = tc.tex(tc.tex>0);
if ~isempty(t); try; Screen('Close', t); catch; end; end
end
