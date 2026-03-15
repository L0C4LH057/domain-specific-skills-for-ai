# Visual Design & Interaction Reference

## Color Palettes for Simulations

```javascript
const PALETTES = {
  // Physics / Energy
  energy: {
    cold:   {r:50,  g:100, b:255},  // Cold = blue
    warm:   {r:255, g:180, b:50},   // Warm = amber
    hot:    {r:255, g:50,  b:50},   // Hot = red
    plasma: {r:255, g:255, b:255},  // Plasma = white
  },
  
  // Chemistry
  chemistry: {
    H:  {r:255,g:255,b:255}, C: {r:80,g:80,b:80},
    N:  {r:50,g:100,b:255},  O: {r:255,g:50,b:50},
    Na: {r:150,g:100,b:255}, Cl:{r:100,g:200,b:50},
    positive: {r:255,g:100,b:100},
    negative: {r:100,g:100,b:255},
  },
  
  // Biology
  biology: {
    membrane: {r:99,g:102,b:241},
    cytoplasm:{r:6,g:182,b:212},
    nucleus:  {r:251,g:191,b:36},
    dna:      {r:34,g:197,b:94},
    infected: {r:239,g:68,b:68},
    healthy:  {r:99,g:102,b:241},
    immune:   {r:34,g:197,b:94},
  },
  
  // Universe
  cosmos: {
    starO:    {r:160,g:190,b:255},
    starG:    {r:255,g:220,b:150},
    starM:    {r:255,g:80,b:40},
    nebula:   {r:99,g:102,b:241},
    darkMatter:{r:30,g:30,b:60},
    blackHole:{r:0,g:0,b:0},
  },
  
  // Investigation
  investigation: {
    suspect:  {r:239,g:68,b:68},
    victim:   {r:249,g:115,b:22},
    witness:  {r:234,g:179,b:8},
    evidence: {r:251,g:191,b:36},
    cleared:  {r:34,g:197,b:94},
  },
};

// Temperature-to-color mapping (blackbody radiation)
function tempToColor(temp, minTemp=0, maxTemp=5000) {
  const t = (temp-minTemp)/(maxTemp-minTemp);
  if (t < 0.33) return {r:50+t*3*205, g:50+t*3*50, b:255-t*3*100};
  if (t < 0.66) return {r:255, g:100+(t-0.33)*3*100, b:155-(t-0.33)*3*155};
  return {r:255, g:200+(t-0.66)*3*55, b:Math.max(0,(t-0.66)*3*200-100)};
}

// Charge-to-color
function chargeToColor(charge) {
  if (charge > 0) return {r:255, g:80+charge*50, b:80};  // Red for positive
  if (charge < 0) return {r:80, g:80, b:255-charge*50};   // Blue for negative
  return {r:200, g:200, b:200};                            // Grey for neutral
}
```

## Glow Effects

```javascript
// Soft particle glow (the signature look of great particle sims)
function drawGlowingParticle(ctx, x, y, radius, color, intensity=1.0) {
  const grd = ctx.createRadialGradient(x, y, 0, x, y, radius*3);
  grd.addColorStop(0,   `rgba(${color.r},${color.g},${color.b},${intensity})`);
  grd.addColorStop(0.3, `rgba(${color.r},${color.g},${color.b},${intensity*0.5})`);
  grd.addColorStop(0.7, `rgba(${color.r},${color.g},${color.b},${intensity*0.15})`);
  grd.addColorStop(1,   'rgba(0,0,0,0)');
  ctx.beginPath();
  ctx.arc(x, y, radius*3, 0, Math.PI*2);
  ctx.fillStyle = grd;
  ctx.fill();
}

// Trail rendering — key to beautiful particle motion
function renderWithTrail(ctx, W, H, trailAlpha=0.12) {
  // Call this FIRST in render loop, before drawing particles
  ctx.fillStyle = `rgba(3,7,18,${trailAlpha})`;
  ctx.fillRect(0, 0, W, H);
  // Then draw particles with ctx.globalCompositeOperation = 'lighter'
}

// Bloom effect (software post-processing)
function applyBloom(ctx, W, H, threshold=200, spread=3) {
  const imageData = ctx.getImageData(0, 0, W, H);
  const data = imageData.data;
  // Extract bright pixels → blur → add back
  for (let i=0; i<data.length; i+=4) {
    const brightness = (data[i]+data[i+1]+data[i+2])/3;
    if (brightness > threshold) {
      // This pixel contributes to bloom — add diffuse glow to neighbors
      // (simplified software bloom — for production use WebGL framebuffer)
    }
  }
}
```

## Canvas Interaction Patterns

```javascript
// Mouse interaction modes
const INTERACTION_MODES = {
  attract:  'Attract particles toward cursor (gravity well)',
  repel:    'Push particles away from cursor (explosion)',
  vortex:   'Spin particles in a circular pattern',
  paint:    'Spawn new particles at cursor position',
  select:   'Click to inspect individual particles',
  slice:    'Draw a line to cut through particle fields',
  heat:     'Increase particle velocity near cursor',
  freeze:   'Decrease particle velocity near cursor',
};

// Vortex force
function applyVortexForce(px, py, pvx, pvy, mx, my, strength=2) {
  const dx=mx-px, dy=my-py;
  const r=Math.sqrt(dx*dx+dy*dy)||1;
  if (r > 150) return {dvx:0, dvy:0};
  const intensity=(1-r/150)*strength;
  // Perpendicular to radial direction = circular motion
  return { dvx: -dy/r*intensity, dvy: dx/r*intensity };
}

// Pinch-to-zoom (touch)
let lastTouchDist = 0;
canvas.addEventListener('touchmove', (e) => {
  if (e.touches.length === 2) {
    const dx=e.touches[0].clientX-e.touches[1].clientX;
    const dy=e.touches[0].clientY-e.touches[1].clientY;
    const dist=Math.sqrt(dx*dx+dy*dy);
    if (lastTouchDist) {
      const scale = dist / lastTouchDist;
      cameraZoom *= scale;
    }
    lastTouchDist = dist;
  }
}, {passive:false});
```

## HUD Design System

```javascript
// Consistent HUD CSS for all simulations
const HUD_CSS = `
  .sim-hud {
    position:fixed; top:20px; left:20px; width:260px;
    background:rgba(3,7,18,0.85); border:1px solid rgba(99,102,241,0.3);
    border-radius:14px; padding:16px; color:#e2e8f0;
    font-family:'Segoe UI',sans-serif; font-size:13px; line-height:1.9;
    backdrop-filter:blur(12px); box-shadow:0 4px 30px rgba(0,0,0,0.5);
    z-index:100;
  }
  .sim-hud h3 { color:#818cf8; font-size:14px; margin-bottom:10px; letter-spacing:0.5px; }
  .sim-hud .metric { display:flex; justify-content:space-between; margin:2px 0; }
  .sim-hud .val { color:#34d399; font-weight:600; font-variant-numeric:tabular-nums; }
  .sim-hud .formula { color:#fbbf24; font-size:11.5px; font-style:italic; margin-top:8px; opacity:0.9; }
  .sim-hud .fact { color:#94a3b8; font-size:11px; margin-top:8px; line-height:1.5; border-top:1px solid rgba(99,102,241,0.2); padding-top:8px; }
  .sim-hud hr { border:none; border-top:1px solid rgba(99,102,241,0.2); margin:8px 0; }
  
  .sim-controls {
    position:fixed; bottom:20px; left:50%; transform:translateX(-50%);
    display:flex; gap:8px; background:rgba(3,7,18,0.85);
    border:1px solid rgba(99,102,241,0.3); border-radius:50px;
    padding:10px 20px; backdrop-filter:blur(12px); z-index:100;
  }
  .sim-btn {
    background:rgba(99,102,241,0.15); border:1px solid rgba(99,102,241,0.35);
    color:#c7d2fe; border-radius:20px; padding:6px 14px; cursor:pointer;
    font-size:12px; transition:all 0.2s; white-space:nowrap;
    font-family:'Segoe UI',sans-serif;
  }
  .sim-btn:hover { background:rgba(99,102,241,0.4); border-color:rgba(129,140,248,0.6); }
  .sim-btn.active { background:rgba(99,102,241,0.5); color:white; }
  
  .sim-tooltip {
    position:fixed; max-width:240px; background:rgba(3,7,18,0.95);
    border:1px solid rgba(99,102,241,0.4); border-radius:10px;
    padding:12px 15px; color:#e2e8f0; font-size:12px; line-height:1.6;
    pointer-events:none; display:none; z-index:200; backdrop-filter:blur(10px);
    box-shadow:0 4px 20px rgba(0,0,0,0.6);
  }
  
  .sim-hint {
    position:fixed; bottom:70px; left:50%; transform:translateX(-50%);
    color:rgba(148,163,184,0.45); font-size:11px; pointer-events:none;
    font-family:'Segoe UI',sans-serif; letter-spacing:0.3px;
  }
`;
```

---

## References

- **"The Visual Display of Quantitative Information"** — Edward Tufte
- **DotWave.js** — Physics-based dot backgrounds 2026 — lightweight particle UI
- **"Real-Time Rendering, 4th Ed."** — Akenine-Möller et al.
- **Quantum Particle Simulation JS** — GPU-accelerated quantum effects library
- **"The Art of Scientific Visualization"** — IEEE Visualization Conference proceedings
- **INSYDIUM NeXus** — Professional GPU VFX — https://insydium.ltd/products/nexus/
- **"Design for Information"** — Isabel Meirelles
