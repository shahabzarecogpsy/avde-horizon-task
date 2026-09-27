function cfg = avde_finalize_runtime_config(cfg, ds)
% Derive scale-aware typography and immutable runtime/display metadata.
scale = min(ds.width / cfg.display.referenceResolution(1), ds.height / cfg.display.referenceResolution(2));
scale = max(0.72, min(1.40, scale));
cfg.runtime.scale = scale;
cfg.runtime.font.small = round(22 * scale);
cfg.runtime.font.body = round(30 * scale);
cfg.runtime.font.history = round(34 * scale);
cfg.runtime.font.medium = round(36 * scale);
cfg.runtime.font.large = round(48 * scale);
cfg.runtime.font.source = round(52 * scale);
cfg.runtime.font.choiceCue = round(58 * scale);
cfg.runtime.font.outcome = round(50 * scale);
cfg.runtime.font.progress = round(30 * scale);
cfg.runtime.lineWidth = max(2, round(3 * scale));
cfg.runtime.timestamp = datestr(now, 30);
cfg.runtime.screenNumber=ds.screenNumber; cfg.runtime.widthPx=ds.width; cfg.runtime.heightPx=ds.height;
cfg.runtime.ifi=ds.ifi; cfg.runtime.measuredHz=1/ds.ifi; cfg.runtime.nominalHz=ds.nominalHz;
cfg.runtime.keyboardDeviceIndex=ds.keyboardDeviceIndex; cfg.runtime.keyboardName=ds.keyboardName;
if isfinite(cfg.display.monitorWidthCm); cfg.runtime.monitorWidthCm=cfg.display.monitorWidthCm;
elseif isfinite(ds.displayWidthMM) && ds.displayWidthMM>0; cfg.runtime.monitorWidthCm=ds.displayWidthMM/10;
else; cfg.runtime.monitorWidthCm=NaN; end
cfg.runtime.viewingDistanceCm=cfg.display.viewingDistanceCm;
if isfinite(cfg.runtime.monitorWidthCm) && cfg.runtime.monitorWidthCm>0 && isfinite(cfg.runtime.viewingDistanceCm) && cfg.runtime.viewingDistanceCm>0
    totalDeg=2*atan((cfg.runtime.monitorWidthCm/2)/cfg.runtime.viewingDistanceCm)*180/pi;
    cfg.runtime.horizontalVisualAngleDeg=totalDeg; cfg.runtime.pixelsPerDegree=ds.width/totalDeg;
else
    cfg.runtime.horizontalVisualAngleDeg=NaN; cfg.runtime.pixelsPerDegree=NaN;
end
end
