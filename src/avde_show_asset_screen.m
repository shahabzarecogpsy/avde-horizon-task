function onset = avde_show_asset_screen(ds, cfg, name, waitForKey, footer)
% Show a pre-rendered Persian screen (PNG). Missing assets are fatal (no
% platform-dependent text fallback).
if nargin < 4; waitForKey = true; end
if nargin < 5; footer = ''; end
p = fullfile(cfg.paths.instructionsFA, name);
if ~isfile(p); error('AVDE:InstructionAsset','Missing instruction asset: %s', p); end
img = imread(p); if ndims(img)==2; img = repmat(img,[1 1 3]); end
tex = Screen('MakeTexture', ds.win, img); c = onCleanup(@() Screen('Close', tex)); %#ok<NASGU>
sc = min(ds.width/size(img,2), ds.height/size(img,1));
dest = CenterRectOnPointd([0 0 size(img,2)*sc size(img,1)*sc], ds.width/2, ds.height/2);
Screen('FillRect', ds.win, cfg.display.background); Screen('DrawTexture', ds.win, tex, [], dest);
if ~isempty(footer)
    Screen('TextSize', ds.win, cfg.runtime.font.body);
    DrawFormattedText(ds.win, footer, 'center', dest(4) - 0.12*(dest(4)-dest(2)), [60 70 85]);
end
onset = Screen('Flip', ds.win);
if waitForKey; avde_wait_for_continue(ds); end
end
