import 'dart:convert';
import 'package:spatial_draft/core/models/spatial_project.dart';

/// Generates a standalone interactive 3D Web/HTML viewer document.
class Interactive3dHtmlExporter {
  const Interactive3dHtmlExporter._();

  /// Generates a self-contained HTML document with interactive 3D orbit.
  static String generateHtml(SpatialProject project) {
    final title = project.title;
    final planesJson = jsonEncode(
      project.planes.map((p) => p.toJson()).toList(),
    );
    final strokesJson = jsonEncode(
      project.strokes.map((s) => s.toJson()).toList(),
    );
    final waypoints3D = project.bookmarks.where((b) => b.is3D).toList();
    final waypointsJson = jsonEncode(
      waypoints3D.map((b) => b.toJson()).toList(),
    );
    final initYaw = project.cameraYaw;
    final initPitch = project.cameraPitch;
    final initDist = project.cameraDistance;

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport"
  content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<title>$title — SpatialDraft 3D Viewer</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: #0f1115;
    color: #f8fafc;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
      Roboto, sans-serif;
    overflow: hidden;
    touch-action: none;
    user-select: none;
  }
  #canvas {
    display: block;
    width: 100vw;
    height: 100vh;
    cursor: grab;
  }
  #canvas:active { cursor: grabbing; }
  .hud-top {
    position: absolute;
    top: 20px;
    left: 20px;
    background: rgba(18, 22, 30, 0.85);
    backdrop-filter: blur(16px);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 12px;
    padding: 10px 16px;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  }
  .hud-title {
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0.5px;
    color: #38bdf8;
  }
  .hud-badge {
    font-size: 11px;
    font-family: monospace;
    background: rgba(56, 189, 248, 0.2);
    color: #38bdf8;
    padding: 2px 6px;
    border-radius: 4px;
  }
  .dock-bottom {
    position: absolute;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(18, 22, 30, 0.88);
    backdrop-filter: blur(18px);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 16px;
    padding: 8px 14px;
    display: flex;
    align-items: center;
    gap: 10px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  }
  .btn {
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.15);
    color: #e2e8f0;
    border-radius: 8px;
    padding: 6px 12px;
    font-size: 12px;
    cursor: pointer;
    transition: all 0.15s ease;
  }
  .btn:hover { background: rgba(56, 189, 248, 0.2); border-color: #38bdf8; }
  .btn.active { background: #0284c7; color: white; border-color: #38bdf8; }
  .stats { font-family: monospace; font-size: 11px; color: #94a3b8; }
</style>
</head>
<body>
<div class="hud-top">
  <div class="hud-title">$title</div>
  <div class="hud-badge">3D Mental Canvas</div>
</div>

<canvas id="canvas"></canvas>

<div class="dock-bottom">
  <button id="tourBtn" class="btn" style="display: none;">
    ▶ Storyboard Tour
  </button>
  <button id="spinBtn" class="btn">Auto Spin</button>
  <button id="resetBtn" class="btn">Reset Camera</button>
  <span id="stats" class="stats">Yaw: 0° | Pitch: 0°</span>
</div>

<script>
  const planes = $planesJson;
  const strokes = $strokesJson;
  const waypoints = $waypointsJson;

  let cameraYaw = $initYaw;
  let cameraPitch = $initPitch;
  let cameraDist = $initDist;
  let isSpinning = false;
  let isTouring = false;
  let tourIndex = 0;
  let tourStartTime = 0;
  let tourStart = { yaw: 0, pitch: 0, dist: 900 };
  let tourTarget = { diffYaw: 0, pitch: 0, dist: 0 };

  const canvas = document.getElementById('canvas');
  const ctx = canvas.getContext('2d');
  const stats = document.getElementById('stats');
  const spinBtn = document.getElementById('spinBtn');
  const resetBtn = document.getElementById('resetBtn');
  const tourBtn = document.getElementById('tourBtn');

  if (waypoints && waypoints.length >= 2) {
    tourBtn.style.display = 'inline-block';
  }

  function resize() {
    canvas.width = window.innerWidth * window.devicePixelRatio;
    canvas.height = window.innerHeight * window.devicePixelRatio;
    render();
  }
  window.addEventListener('resize', resize);

  function project3D(x, y, z, cx, cy) {
    const cosY = Math.cos(cameraYaw);
    const sinY = Math.sin(cameraYaw);
    const x1 = x * cosY + z * sinY;
    const y1 = y;
    const z1 = -x * sinY + z * cosY;

    const cosP = Math.cos(cameraPitch);
    const sinP = Math.sin(cameraPitch);
    const x2 = x1;
    const y2 = y1 * cosP - z1 * sinP;
    const z2 = y1 * sinP + z1 * cosP;

    const depth = cameraDist + z2;
    if (depth <= 20.0) return null;
    const factor = cameraDist / depth;

    return {
      sx: cx + x2 * factor,
      sy: cy + y2 * factor,
      depth: z2
    };
  }

  function transformPlane2D(plane, u, v) {
    const cosR = Math.cos(plane.roll || 0);
    const sinR = Math.sin(plane.roll || 0);
    const x1 = u * cosR - v * sinR;
    const y1 = u * sinR + v * cosR;

    const cosP = Math.cos(plane.pitch || 0);
    const sinP = Math.sin(plane.pitch || 0);
    const x2 = x1;
    const y2 = y1 * cosP;
    const z2 = y1 * sinP;

    const cosY = Math.cos(plane.yaw || 0);
    const sinY = Math.sin(plane.yaw || 0);
    const x3 = x2 * cosY + z2 * sinY;
    const y3 = y2;
    const z3 = -x2 * sinY + z2 * cosY;

    return {
      x: (plane.originX || 0) + x3,
      y: (plane.originY || 0) + y3,
      z: (plane.originZ || 0) + z3
    };
  }

  function render() {
    const dpr = window.devicePixelRatio || 1;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const cx = canvas.width / 2;
    const cy = canvas.height / 2;

    // Render Planes
    for (const plane of planes) {
      if (plane.isVisible === false) continue;
      const hw = (plane.width || 2000) / 2;
      const hh = (plane.height || 2000) / 2;
      const corners = [
        transformPlane2D(plane, -hw, -hh),
        transformPlane2D(plane, hw, -hh),
        transformPlane2D(plane, hw, hh),
        transformPlane2D(plane, -hw, hh)
      ];
      const sc = corners.map(c => project3D(c.x, c.y, c.z, cx, cy));
      if (sc.some(p => p === null)) continue;

      ctx.beginPath();
      ctx.moveTo(sc[0].sx, sc[0].sy);
      for (let i = 1; i < 4; i++) ctx.lineTo(sc[i].sx, sc[i].sy);
      ctx.closePath();

      const rawHex = (plane.colorValue || 0x00ffcc) & 0xffffff;
      const hex = '#' + rawHex.toString(16).padStart(6, '0');
      ctx.fillStyle = hex + '0d';
      ctx.fill();
      ctx.strokeStyle = hex + '66';
      ctx.lineWidth = 1.2 * dpr;
      ctx.stroke();
    }

    // Render Strokes
    const planeMap = {};
    for (const p of planes) planeMap[p.id] = p;

    for (const stroke of strokes) {
      const plane = planeMap[stroke.planeId || 'plane_primary'] || planes[0];
      if (plane && plane.isVisible === false) continue;
      if (!stroke.points || stroke.points.length === 0) continue;

      const pts = [];
      for (const pt of stroke.points) {
        const u = pt.x - 2000;
        const v = pt.y - 2000;
        const w = transformPlane2D(plane, u, v);
        const sp = project3D(w.x, w.y, w.z, cx, cy);
        if (sp) pts.push(sp);
      }
      if (pts.length < 2) continue;

      ctx.beginPath();
      ctx.moveTo(pts[0].sx, pts[0].sy);
      for (let i = 1; i < pts.length; i++) {
        ctx.lineTo(pts[i].sx, pts[i].sy);
      }
      const c = stroke.color || 0xffffffff;
      const hex = '#' + (c & 0xffffff).toString(16).padStart(6, '0');
      const isWash = stroke.brushStyle === 'wash';
      const baseWidth = stroke.lineWeight === 'silhouette' ? 3.0 : 1.8;
      ctx.strokeStyle = hex;
      ctx.lineWidth = (isWash ? baseWidth * 3.2 : baseWidth) * dpr;
      ctx.globalAlpha = isWash ? 0.35 : 1.0;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.stroke();
      ctx.globalAlpha = 1.0;
    }

    const yDeg = Math.round((cameraYaw * 180 / Math.PI) % 360);
    const pDeg = Math.round(cameraPitch * 180 / Math.PI);
    stats.textContent = 'Yaw: ' + yDeg + '° | Pitch: ' + pDeg + '°';
  }

  // Pointer Interaction
  let isDragging = false;
  let lastX = 0;
  let lastY = 0;

  canvas.addEventListener('pointerdown', e => {
    isDragging = true;
    lastX = e.clientX;
    lastY = e.clientY;
  });

  window.addEventListener('pointermove', e => {
    if (!isDragging) return;
    const dx = e.clientX - lastX;
    const dy = e.clientY - lastY;
    lastX = e.clientX;
    lastY = e.clientY;

    cameraYaw -= dx * 0.006;
    cameraPitch = Math.max(-1.2, Math.min(1.2, cameraPitch + dy * 0.006));
    render();
  });

  window.addEventListener('pointerup', () => { isDragging = false; });
  window.addEventListener('wheel', e => {
    cameraDist = Math.max(300, Math.min(3000, cameraDist + e.deltaY * 0.5));
    render();
  });

  spinBtn.addEventListener('click', () => {
    isSpinning = !isSpinning;
    spinBtn.classList.toggle('active', isSpinning);
    if (isSpinning) spinLoop();
  });

  function spinLoop() {
    if (!isSpinning) return;
    cameraYaw += 0.008;
    render();
    requestAnimationFrame(spinLoop);
  }

  resetBtn.addEventListener('click', () => {
    cameraYaw = $initYaw;
    cameraPitch = $initPitch;
    cameraDist = $initDist;
    render();
  });

  tourBtn.addEventListener('click', () => {
    isTouring = !isTouring;
    tourBtn.classList.toggle('active', isTouring);
    tourBtn.textContent = isTouring ? '⏸ Pause Tour' : '▶ Storyboard Tour';
    if (isTouring) {
      if (isSpinning) {
        isSpinning = false;
        spinBtn.classList.remove('active');
      }
      tourIndex = 0;
      startNextTourSegment();
    }
  });

  function startNextTourSegment() {
    if (!isTouring || !waypoints || waypoints.length === 0) return;
    const wp = waypoints[tourIndex];
    tourStart = { yaw: cameraYaw, pitch: cameraPitch, dist: cameraDist };
    const targetYaw = wp.cameraYaw || 0;
    const diffYaw =
      ((targetYaw - tourStart.yaw + Math.PI) % (2 * Math.PI)) - Math.PI;
    tourTarget = {
      diffYaw: diffYaw,
      pitch: (wp.cameraPitch || 0) - tourStart.pitch,
      dist: (wp.cameraDistance || 900) - tourStart.dist
    };
    tourStartTime = performance.now();
    requestAnimationFrame(tourLoop);
  }

  function tourLoop(now) {
    if (!isTouring) return;
    const elapsed = now - tourStartTime;
    const duration = 1800;
    const t = Math.min(1.0, elapsed / duration);
    const ease = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

    cameraYaw = tourStart.yaw + tourTarget.diffYaw * ease;
    cameraPitch = tourStart.pitch + tourTarget.pitch * ease;
    cameraDist = tourStart.dist + tourTarget.dist * ease;
    render();

    if (t < 1.0) {
      requestAnimationFrame(tourLoop);
    } else {
      tourIndex = (tourIndex + 1) % waypoints.length;
      setTimeout(() => {
        if (isTouring) startNextTourSegment();
      }, 500);
    }
  }

  resize();
</script>
</body>
</html>
''';
  }
}
