function ds = avde_setup_display(cfg)
% Initialize Psychtoolbox display and an explicitly identified response device.
PsychDefaultSetup(1); % AVDE palette is specified in the classic 0..255 range.
KbName('UnifyKeyNames');
oldSkip=Screen('Preference','SkipSyncTests');
Screen('Preference','SkipSyncTests',double(cfg.debug.skipSyncTests));
win=[]; deviceIndex=[];
try
    screens=Screen('Screens'); screenNumber=max(screens);
    if cfg.debug.windowed
        [win,winRect]=PsychImaging('OpenWindow',screenNumber,cfg.display.background,cfg.debug.windowRect);
    else
        [win,winRect]=PsychImaging('OpenWindow',screenNumber,cfg.display.background);
    end
    Screen('ColorRange',win,cfg.display.colorRange); activeColorRange=Screen('ColorRange',win);
    if abs(activeColorRange-cfg.display.colorRange)>1e-6
        error('AVDE:ColorRangeMismatch','Expected color range %.1f; detected %.3f.',cfg.display.colorRange,activeColorRange);
    end
    [w,h]=RectSize(winRect);
    if w<cfg.display.minimumResolution(1) || h<cfg.display.minimumResolution(2)
        error('AVDE:DisplayTooSmall','Minimum supported resolution is %dx%d; detected %dx%d.', ...
            cfg.display.minimumResolution(1),cfg.display.minimumResolution(2),w,h);
    end
    ifi=Screen('GetFlipInterval',win);
    try; [displayWidthMM,displayHeightMM]=Screen('DisplaySize',screenNumber); catch; displayWidthMM=NaN; displayHeightMM=NaN; end
    try; nominalHz=Screen('NominalFrameRate',screenNumber); catch; nominalHz=NaN; end
    Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextFont',win,cfg.display.baseFont); Screen('TextStyle',win,0);
    if cfg.display.hideCursor && ~cfg.debug.showMouse; HideCursor; end
    Priority(MaxPriority(win));

    % Response keyboard: never silently choose among multiple keyboards in a data run.
    try
        [kbIdx,kbNames,kbInfo]=GetKeyboardIndices;
    catch
        [kbIdx,kbNames]=GetKeyboardIndices; kbInfo=[];
    end
    if isempty(kbIdx); error('AVDE:NoKeyboard','Psychtoolbox did not detect a keyboard-like response device.'); end
    if ~isempty(cfg.input.keyboardDeviceIndex)
        deviceIndex=cfg.input.keyboardDeviceIndex;
        if ~ismember(deviceIndex,kbIdx)
            error('AVDE:KeyboardDevice','Configured keyboardDeviceIndex %d is not among detected keyboard indices.',deviceIndex);
        end
    elseif numel(kbIdx)==1 || ~cfg.input.requireExplicitDeviceIfMultiple || strcmpi(cfg.mode,'development')
        deviceIndex=kbIdx(1);
    else
        msg=sprintf('Multiple keyboards detected. Set AVDE_KEYBOARD_DEVICE_INDEX explicitly. Detected:\n');
        for k=1:numel(kbIdx); msg=sprintf('%s  index %d: %s\n',msg,kbIdx(k),kbNames{k}); end %#ok<AGROW>
        error('AVDE:MultipleKeyboards','%s',msg);
    end
    keys=avde_keymap(cfg); KbQueueCreate(deviceIndex); KbQueueStart(deviceIndex);
    Screen('FillRect',win,cfg.display.background); initialVBL=Screen('Flip',win);

    if cfg.debug.verbose
        fprintf('AVDE display: %dx%d, measured IFI %.6f s (%.2f Hz).\n',w,h,ifi,1/ifi);
        fprintf('Response keyboard index %d: %s\n',deviceIndex,local_name(deviceIndex,kbIdx,kbNames));
    end
    ds=struct(); ds.win=win; ds.winRect=winRect; ds.screenNumber=screenNumber;
    ds.width=w; ds.height=h; ds.center=[w/2 h/2]; ds.ifi=ifi;
    ds.displayWidthMM=displayWidthMM; ds.displayHeightMM=displayHeightMM; ds.nominalHz=nominalHz;
    ds.colorRange=activeColorRange; ds.initialVBL=initialVBL; ds.oldSkipSyncTests=oldSkip;
    ds.keys=keys; ds.syncTestsSkipped=logical(cfg.debug.skipSyncTests); ds.keyboardDeviceIndex=deviceIndex; ds.keyboardName=local_name(deviceIndex,kbIdx,kbNames);
    try
        pos=find(kbIdx==deviceIndex,1); ds.keyboardInfo=kbInfo(pos);
    catch
        ds.keyboardInfo=[];
    end
    ds.opened=true;
catch ME
    try; if ~isempty(deviceIndex); KbQueueStop(deviceIndex); KbQueueRelease(deviceIndex); end; catch; end
    try; Priority(0); catch; end
    try; ShowCursor; catch; end
    try; Screen('CloseAll'); catch; end
    try; Screen('Preference','SkipSyncTests',oldSkip); catch; end
    rethrow(ME);
end
end

function n=local_name(idx,indices,names)
pos=find(indices==idx,1); if isempty(pos); n='unknown'; else; n=names{pos}; end
end
