function x = avde_draw_truncnorm(mu, sigma, lo, hi, n)
% Exact rejection sampler for N(mu,sigma) truncated to [lo,hi] (base MATLAB/Octave only).
x = nan(1,n); k = 0;
while k < n
    cand = mu + sigma*randn(1, max(16,2*(n-k)));
    cand = cand(cand>=lo & cand<=hi);
    take = min(numel(cand), n-k);
    if take>0; x(k+1:k+take) = cand(1:take); k = k+take; end
end
end
