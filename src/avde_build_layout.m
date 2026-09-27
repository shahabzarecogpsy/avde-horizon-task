function L = avde_build_layout(winRect, cfg)
% Resolution-aware AVDE layout.
% Design constraints: deck centre-to-centre separation is 0.40 of content width;
% 5/10 history rows; face images remain 150% of the retained legacy linear reference
% bounds; preview faces are shifted toward their own deck while preserving a
% strict connector/deck clearance; response arrows remain on the inner deck
% sides; no face/deck overlap.
[w,h]=RectSize(winRect); targetAspect=16/9;
if w/h>=targetAspect; ch=h; cw=ch*targetAspect; else; cw=w; ch=cw/targetAspect; end
ox=(w-cw)/2; oy=(h-ch)/2; X=@(f) ox+f*cw; Y=@(f) oy+f*ch;
L.w=w; L.h=h; L.cw=cw; L.ch=ch; L.ox=ox; L.oy=oy; L.contentRect=[ox oy ox+cw oy+ch];
L.centerX=X(.5); L.centerY=Y(.5);

% Decks are moved outward symmetrically so their centres are separated by
% exactly 0.40 x content width (0.30 and 0.70 of the content corridor).
L.leftCenterX=X(.30); L.rightCenterX=X(.70); panelW=.110*cw; panelH=.770*ch;
L.leftCard=CenterRectOnPointd([0 0 panelW panelH],L.leftCenterX,Y(.525));
L.rightCard=CenterRectOnPointd([0 0 panelW panelH],L.rightCenterX,Y(.525));
sourceSz=.080*ch; L.leftSource=CenterRectOnPointd([0 0 sourceSz sourceSz],L.leftCenterX,Y(.175));
L.rightSource=CenterRectOnPointd([0 0 sourceSz sourceSz],L.rightCenterX,Y(.175));

L.historyTop=Y(.295); L.historyRowH=.056*ch; L.historyRowsShort=5; L.historyRowsLong=10;
L.historyCellW=.090*cw; L.historyCellH=.046*ch;

% Face bounds remain exactly 1.5x the retained legacy linear bounds. Preview bounds are
% no longer almost centred: each is positioned adjacent to its associated deck.
% This makes source association visually local while preserving an explicit
% deck-to-image corridor for the connector line.
previewW=.1785*cw; previewH=.525*ch;
minGap=cfg.display.minimumElementGapFraction*cw;
L.previewDeckGap=max(1.5*minGap,.018*cw);
py=Y(.555); py1=py-previewH/2; py2=py+previewH/2;
L.previewLeft=[L.leftCard(3)+L.previewDeckGap, py1, L.leftCard(3)+L.previewDeckGap+previewW, py2];
L.previewRight=[L.rightCard(1)-L.previewDeckGap-previewW, py1, L.rightCard(1)-L.previewDeckGap, py2];
outcomeW=.2205*cw; outcomeH=.525*ch;
L.outcomeCenter=CenterRectOnPointd([0 0 outcomeW outcomeH],X(.50),Y(.555));
L.leftConnectorStart=[L.leftCard(3) Y(.48)]; L.rightConnectorStart=[L.rightCard(1) Y(.48)];

% Response arrows occupy the empty corridor immediately inside each deck.
L.responseArrowHalfW=max(12,round(.012*cw)); L.responseArrowHalfH=max(12,round(.014*ch));
L.responseOutlineInset=max(5,round(.006*min(cw,ch)));
L.leftCueCenter=[L.leftCard(3)+.025*cw,Y(.525)]; L.rightCueCenter=[L.rightCard(1)-.025*cw,Y(.525)];
L.outcomeLabelOffset=max(34,round(.045*ch));
% Top band: progress counter (above source markers/decks).
L.progressRect=[X(.40) Y(.006) X(.60) Y(.054)];
L.messageRect=[X(.10) Y(.16) X(.90) Y(.84)]; L.sliderRect=[X(.20) Y(.55) X(.80) Y(.62)];

local_assert_layout(L,cfg);
if isfield(cfg,'debug') && cfg.debug.verbose
    fprintf(['AVDE layout v0.13.0: %dx%d; deck separation %.0f px (0.40 x content width); ' ...
        'preview-deck gap %.0f px; 150%% face bounds %.0fx%.0f (preview), %.0fx%.0f (outcome).\n'], ...
        w,h,L.rightCenterX-L.leftCenterX,L.previewDeckGap,previewW,previewH,outcomeW,outcomeH);
end
end

function local_assert_layout(L,cfg)
if L.contentRect(1)<0 || L.contentRect(2)<0 || L.contentRect(3)>L.w || L.contentRect(4)>L.h
    error('AVDE:LayoutBounds','Content rectangle exceeds the window.');
end
gap=cfg.display.minimumElementGapFraction*L.cw;
faces={L.previewLeft,L.previewRight,L.outcomeCenter}; cards={L.leftCard,L.rightCard};
for f=1:numel(faces)
    for c=1:numel(cards)
        if local_rect_distance(faces{f},cards{c})<gap
            error('AVDE:LayoutOverlap','Face bounds are too close to/overlap a deck (required gap %.1f px).',gap);
        end
    end
end
% Preview images must sit on the correct side of the central corridor and be
% closer to their own deck than to the opposite deck.
if mean(L.previewLeft([1 3]))>=L.centerX || mean(L.previewRight([1 3]))<=L.centerX
    error('AVDE:LayoutPreviewSide','Preview image bounds are not shifted toward their associated deck.');
end
if local_rect_distance(L.previewLeft,L.leftCard)>=local_rect_distance(L.previewLeft,L.rightCard) || ...
        local_rect_distance(L.previewRight,L.rightCard)>=local_rect_distance(L.previewRight,L.leftCard)
    error('AVDE:LayoutPreviewAssociation','Preview image is not visually closer to its associated deck.');
end
% The connector corridor is explicit and strictly larger than the minimum gap.
if L.previewLeft(1)-L.leftCard(3) < gap || L.rightCard(1)-L.previewRight(3) < gap
    error('AVDE:LayoutConnectorClearance','Insufficient source-image connector clearance.');
end
% The two possible preview bounding rectangles may overlap because only one
% preview image is displayed per event. Neither may overlap a deck or outcome
% display that is simultaneously visible in that event.
% Arrow triangles must not enter the deck itself.
if L.leftCueCenter(1)-L.responseArrowHalfW <= L.leftCard(3) || L.rightCueCenter(1)+L.responseArrowHalfW >= L.rightCard(1)
    error('AVDE:LayoutCueOverlap','Response-arrow geometry overlaps a source deck.');
end
% The header band must stay clear of source markers, decks and face bounds.
headerBottom=L.progressRect(4);
if headerBottom+gap > min([L.leftSource(2) L.rightSource(2) L.leftCard(2) L.rightCard(2) L.previewLeft(2) L.outcomeCenter(2)])
    error('AVDE:LayoutHeader','Header band overlaps task elements.');
end
% All 10 H6 rows must fit within cards with bottom clearance.
lastY=L.historyTop+(L.historyRowsLong-1)*L.historyRowH;
if lastY+L.historyCellH/2 > min(L.leftCard(4),L.rightCard(4))-.015*L.ch
    error('AVDE:LayoutHistory','H6 history rows exceed deck bounds.');
end
end

function d=local_rect_distance(a,b)
dx=max([b(1)-a(3),a(1)-b(3),0]); dy=max([b(2)-a(4),a(2)-b(4),0]); d=hypot(dx,dy);
end
