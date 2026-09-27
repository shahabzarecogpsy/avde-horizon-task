function varargout = Screen(cmd, varargin)
global AVDE_MOCK
varargout = cell(1, max(nargout,1));
switch cmd
    case 'Flip'
        mock_advance();
        when = 0; if numel(varargin) >= 2; when = varargin{2}; end
        AVDE_MOCK.flips = AVDE_MOCK.flips + 1; AVDE_MOCK.flipInGame = AVDE_MOCK.flipInGame + 1;
        if isfinite(AVDE_MOCK.crashGame) && AVDE_MOCK.game == AVDE_MOCK.crashGame && AVDE_MOCK.flipInGame == AVDE_MOCK.crashFlipInGame
            AVDE_MOCK.crashed = true; AVDE_MOCK.crashGame = NaN;
            error('MOCK:Crash','Simulated crash at game %d flip %d', AVDE_MOCK.game, AVDE_MOCK.flipInGame);
        end
        if isfinite(AVDE_MOCK.crashGlobalFlip) && AVDE_MOCK.flips == AVDE_MOCK.crashGlobalFlip
            AVDE_MOCK.crashGlobalFlip = NaN; AVDE_MOCK.crashed = true; error('MOCK:Crash','Simulated crash at global flip %d', AVDE_MOCK.flips);
        end
        V = max(AVDE_MOCK.V, when);
        n = ceil((V - AVDE_MOCK.origin)/AVDE_MOCK.ifi - 1e-9);
        vbl = AVDE_MOCK.origin + n*AVDE_MOCK.ifi;
        missed = double(when > 0 && vbl > when + AVDE_MOCK.ifi + 1e-9);
        AVDE_MOCK.V = vbl; AVDE_MOCK.lastFlip = vbl;
        st = dbstack; if any(strcmp({st.name},'avde_collect_choice')); mock_new_trial(vbl); end
        AVDE_MOCK.flipLog(end+1,:) = [AVDE_MOCK.game AVDE_MOCK.flipInGame vbl when];
        varargout = {vbl, vbl, vbl, missed, 0};
    case 'MakeTexture'
        img = varargin{2};
        assert(isa(img,'uint8') && any(ndims(img)==[2 3]) && size(img,1)>1, 'MOCK:BadTexture', 'MakeTexture expects uint8 image');
        AVDE_MOCK.tex = AVDE_MOCK.tex + 1; AVDE_MOCK.openTex = AVDE_MOCK.openTex + 1;
        AVDE_MOCK.maxOpenTex = max(AVDE_MOCK.maxOpenTex, AVDE_MOCK.openTex);
        varargout{1} = AVDE_MOCK.tex;
    case 'Close'
        if numel(varargin) >= 1; AVDE_MOCK.openTex = AVDE_MOCK.openTex - numel(varargin{1}); end
    case 'Preference'; varargout{1} = 0;
    case 'Screens'; varargout{1} = 0;
    case 'ColorRange'; varargout{1} = 255;
    case 'GetFlipInterval'; varargout{1} = AVDE_MOCK.ifi;
    case 'DisplaySize'; varargout = {530, 300};
    case 'NominalFrameRate'; varargout{1} = 60;
    otherwise   % drawing commands: validate argument presence only
        if any(strcmp(cmd, {'FillRect','FrameRect','DrawTexture','DrawLine','FillPoly'}))
            assert(numel(varargin) >= 2, 'MOCK:Args', 'Screen %s missing arguments', cmd);
        end
end
end
