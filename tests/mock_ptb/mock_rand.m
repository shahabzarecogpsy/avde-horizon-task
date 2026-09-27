function x = mock_rand(varargin)
% Isolated RNG for the simulated participant (does not perturb task RNG streams).
global AVDE_MOCK
s = rand('state'); rand('state', AVDE_MOCK.mockRand); x = rand(varargin{:}); AVDE_MOCK.mockRand = rand('state'); rand('state', s); %#ok<RAND>
end
