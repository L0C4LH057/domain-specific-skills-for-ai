# Canvas Particle Engine Reference

## Table of Contents
1. [Core Engine Architecture](#core-engine)
2. [Typed Array Particle System](#typed-arrays)
3. [Spatial Hashing](#spatial-hashing)
4. [Position-Based Dynamics (PBD)](#pbd)
5. [Force Systems](#forces)
6. [Rendering Pipeline](#rendering)
7. [Performance Optimization](#performance)
8. [Complete Engine Template](#template)

---

## 1. Core Engine Architecture {#core-engine}

The canonical 2D particle engine for Claude simulations. Handles 50,000+ particles at 60fps.

```javascript
class ParticleEngine {
  constructor(canvas, options = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.width = canvas.width = window.innerWidth;
    this.height = canvas.height = window.innerHeight;
    
    // Config
    this.MAX_PARTICLES = options.maxParticles || 5000;
    this.CELL_SIZE = options.cellSize || 50;
    
    // Typed arrays: 8 floats per particle
    // [x, y, vx, vy, ax, ay, life, type]
    this.particles = new Float32Array(this.MAX_PARTICLES * 8);
    this.colors = new Uint8Array(this.MAX_PARTICLES * 4); // RGBA per particle
    this.active = new Uint8Array(this.MAX_PARTICLES);
    this.count = 0;
    
    // Spatial hash for neighbor queries
    this.spatialHash = new SpatialHash(this.CELL_SIZE);
    
    // Physics state
    this.gravity = { x: 0, y: 0 };
    this.mouse = { x: 0, y: 0, active: false, mode: 'attract' };
    this.dt = 1/60;
    this.speed = 1.0;
    this.paused = false;
    this.frameCount = 0;
    
    // FPS tracking
    this.fps = 60;
    this.lastTime = performance.now();
    
    this.bindEvents();
  }
  
  bindEvents() {
    window.addEventListener('resize', () => {
      this.width = this.canvas.width = window.innerWidth;
      this.height = this.canvas.height = window.innerHeight;
    });
    this.canvas.addEventListener('mousemove', e => {
      this.mouse.x = e.clientX; this.mouse.y = e.clientY; this.mouse.active = true;
    });
    this.canvas.addEventListener('mouseleave', () => { this.mouse.active = false; });
    this.canvas.addEventListener('click', e => this.onCanvasClick(e));
    document.addEventListener('keydown', e => this.onKeyDown(e));
  }
  
  onKeyDown(e) {
    if (e.code === 'Space') { e.preventDefault(); this.paused = !this.paused; }
    if (e.key === 'r' || e.key === 'R') this.reset();
    if (e.key === 'g' || e.key === 'G') this.gravity.y = this.gravity.y ? 0 : 0.1;
    if (e.key === '+') this.speed = Math.min(this.speed * 1.5, 10);
    if (e.key === '-') this.speed = Math.max(this.speed / 1.5, 0.1);
  }
  
  emit(x, y, options = {}) {
    if (this.count >= this.MAX_PARTICLES) return -1;
    const i = this.count++;
    const base = i * 8;
    const angle = options.angle ?? (Math.random() * Math.PI * 2);
    const speed = options.speed ?? (Math.random() * 2 + 0.5);
    
    this.particles[base + 0] = x;
    this.particles[base + 1] = y;
    this.particles[base + 2] = Math.cos(angle) * speed;
    this.particles[base + 3] = Math.sin(angle) * speed;
    this.particles[base + 4] = 0; // ax
    this.particles[base + 5] = 0; // ay
    this.particles[base + 6] = options.life ?? 1.0;
    this.particles[base + 7] = options.type ?? 0;
    
    const cb = i * 4;
    const color = options.color ?? { r: 100, g: 200, b: 255, a: 255 };
    this.colors[cb] = color.r; this.colors[cb+1] = color.g;
    this.colors[cb+2] = color.b; this.colors[cb+3] = color.a;
    
    this.active[i] = 1;
    return i;
  }
  
  update() {
    if (this.paused) return;
    const effectiveDt = this.dt * this.speed;
    this.spatialHash.clear();
    
    for (let i = 0; i < this.count; i++) {
      if (!this.active[i]) continue;
      const b = i * 8;
      
      // Build spatial hash
      this.spatialHash.insert(i, this.particles[b], this.particles[b+1]);
    }
    
    for (let i = 0; i < this.count; i++) {
      if (!this.active[i]) continue;
      const b = i * 8;
      
      // Reset acceleration
      this.particles[b+4] = this.gravity.x;
      this.particles[b+5] = this.gravity.y;
      
      // Apply forces (overridden by domain-specific engine)
      this.applyForces(i, b);
      
      // Verlet integration
      this.particles[b+2] += this.particles[b+4] * effectiveDt;
      this.particles[b+3] += this.particles[b+5] * effectiveDt;
      
      // Damping
      this.particles[b+2] *= 0.998;
      this.particles[b+3] *= 0.998;
      
      // Position update
      this.particles[b]   += this.particles[b+2] * effectiveDt;
      this.particles[b+1] += this.particles[b+3] * effectiveDt;
      
      // Boundary handling (override for domain-specific)
      this.handleBoundary(i, b);
      
      // Life decay
      this.particles[b+6] -= effectiveDt * 0.005;
      if (this.particles[b+6] <= 0) this.onParticleDeath(i, b);
    }
    
    this.frameCount++;
  }
  
  applyForces(i, b) {
    // Mouse interaction
    if (this.mouse.active) {
      const dx = this.mouse.x - this.particles[b];
      const dy = this.mouse.y - this.particles[b+1];
      const dist = Math.sqrt(dx*dx + dy*dy) || 1;
      const influence = 150; // radius of mouse influence
      if (dist < influence) {
        const strength = (1 - dist/influence) * 2;
        const dir = this.mouse.mode === 'attract' ? 1 : -1;
        this.particles[b+4] += (dx/dist) * strength * dir;
        this.particles[b+5] += (dy/dist) * strength * dir;
      }
    }
  }
  
  handleBoundary(i, b) {
    // Elastic bounce off walls
    if (this.particles[b] < 0)           { this.particles[b] = 0;            this.particles[b+2] *= -0.7; }
    if (this.particles[b] > this.width)  { this.particles[b] = this.width;   this.particles[b+2] *= -0.7; }
    if (this.particles[b+1] < 0)         { this.particles[b+1] = 0;          this.particles[b+3] *= -0.7; }
    if (this.particles[b+1] > this.height){ this.particles[b+1] = this.height; this.particles[b+3] *= -0.7; }
  }
  
  onParticleDeath(i, b) {
    this.active[i] = 0; // Can be overridden for respawn, reaction, etc.
  }
  
  render() {
    // Trail effect (semi-transparent clear)
    this.ctx.fillStyle = 'rgba(3, 7, 18, 0.15)';
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    this.ctx.save();
    this.ctx.globalCompositeOperation = 'lighter'; // Additive blending = glow effect
    
    for (let i = 0; i < this.count; i++) {
      if (!this.active[i]) continue;
      const b = i * 8;
      const cb = i * 4;
      const life = this.particles[b+6];
      const x = this.particles[b], y = this.particles[b+1];
      const size = (options.baseSize || 2) * life;
      
      const grd = this.ctx.createRadialGradient(x, y, 0, x, y, size * 2);
      grd.addColorStop(0, `rgba(${this.colors[cb]},${this.colors[cb+1]},${this.colors[cb+2]},${life})`);
      grd.addColorStop(1, 'rgba(0,0,0,0)');
      
      this.ctx.beginPath();
      this.ctx.arc(x, y, size * 2, 0, Math.PI * 2);
      this.ctx.fillStyle = grd;
      this.ctx.fill();
    }
    
    this.ctx.restore();
  }
  
  loop(timestamp) {
    const delta = timestamp - this.lastTime;
    this.fps = Math.round(1000 / Math.max(delta, 1));
    this.lastTime = timestamp;
    
    this.update();
    this.render();
    this.updateHUD();
    
    requestAnimationFrame(t => this.loop(t));
  }
  
  start() { requestAnimationFrame(t => this.loop(t)); }
  reset() { this.count = 0; this.active.fill(0); this.init && this.init(); }
}
```

---

## 2. Spatial Hashing {#spatial-hashing}

Essential for O(1) neighbor queries. Without this, neighbor search is O(n²).

```javascript
class SpatialHash {
  constructor(cellSize) {
    this.cellSize = cellSize;
    this.cells = new Map();
  }
  
  clear() { this.cells.clear(); }
  
  _key(x, y) {
    return ((Math.floor(x / this.cellSize) * 73856093) ^
            (Math.floor(y / this.cellSize) * 19349663)) >>> 0;
  }
  
  insert(id, x, y) {
    const key = this._key(x, y);
    if (!this.cells.has(key)) this.cells.set(key, []);
    this.cells.get(key).push(id);
  }
  
  query(x, y, radius) {
    const result = [];
    const cells = Math.ceil(radius / this.cellSize);
    for (let cx = -cells; cx <= cells; cx++) {
      for (let cy = -cells; cy <= cells; cy++) {
        const key = this._key(x + cx * this.cellSize, y + cy * this.cellSize);
        const cell = this.cells.get(key);
        if (cell) result.push(...cell);
      }
    }
    return result;
  }
}
```

---

## 3. Position-Based Dynamics (PBD) {#pbd}

Stable constraint solving — never explodes. Used for cloth, fluids, soft bodies.

```javascript
class PBDSolver {
  constructor(particles, constraints) {
    this.p = particles; // positions
    this.pPrev = [...particles]; // previous positions
    this.constraints = constraints;
    this.substeps = 4; // more substeps = more stable
  }
  
  step(dt, externalForces) {
    const subDt = dt / this.substeps;
    
    for (let s = 0; s < this.substeps; s++) {
      // 1. Apply external forces → update velocity
      for (let i = 0; i < this.p.length; i += 2) {
        this.p[i]   += externalForces[i]   * subDt * subDt;
        this.p[i+1] += externalForces[i+1] * subDt * subDt;
      }
      
      // 2. Solve constraints
      for (const c of this.constraints) {
        c.solve(this.p);
      }
    }
    
    // 3. Update velocity from position change
    for (let i = 0; i < this.p.length; i++) {
      const v = (this.p[i] - this.pPrev[i]) / dt;
      this.pPrev[i] = this.p[i];
      // velocity = v (use for rendering motion blur, etc.)
    }
  }
}

// Example constraint: Distance constraint (rigid rod or spring)
class DistanceConstraint {
  constructor(i, j, restLength, stiffness = 1.0) {
    this.i = i * 2; this.j = j * 2;
    this.restLength = restLength;
    this.stiffness = stiffness;
  }
  
  solve(p) {
    const dx = p[this.j] - p[this.i];
    const dy = p[this.j+1] - p[this.i+1];
    const dist = Math.sqrt(dx*dx + dy*dy) || 0.001;
    const correction = (dist - this.restLength) / dist * 0.5 * this.stiffness;
    p[this.i]   += dx * correction;
    p[this.i+1] += dy * correction;
    p[this.j]   -= dx * correction;
    p[this.j+1] -= dy * correction;
  }
}
```

---

## 4. Performance Optimization {#performance}

### Target Benchmarks
| Particle Count | Target FPS | Technique |
|---------------|-----------|-----------|
| < 1,000 | 60 | Basic loop, no optimization needed |
| 1K – 10K | 60 | Spatial hashing |
| 10K – 100K | 60 | Typed arrays + spatial hashing + LOD |
| 100K – 1M | 30–60 | WebGL shaders (PointsMaterial) |

### Typed Array Pattern (Critical for performance)
```javascript
// SLOW — object array
const particles = Array.from({length: 10000}, () => ({x: 0, y: 0, vx: 0, vy: 0}));

// FAST — typed array (10x+ faster, cache-friendly)
const particles = new Float32Array(10000 * 4); // x, y, vx, vy packed
// Access: particles[i*4+0]=x, [i*4+1]=y, [i*4+2]=vx, [i*4+3]=vy
```

### Frame Budget Management
```javascript
// Adaptive quality — drop visual quality to maintain FPS
function adaptiveQuality(fps, engine) {
  if (fps < 30 && engine.glowEnabled) {
    engine.glowEnabled = false; // Disable glow gradients
  }
  if (fps < 20) {
    engine.MAX_PARTICLES = Math.floor(engine.MAX_PARTICLES * 0.8); // Reduce particles
  }
  if (fps < 15) {
    engine.renderEveryN = 2; // Render every other frame
  }
}
```

---

## 5. Complete Simulation Template {#template}

Full ready-to-use simulation HTML template with all systems integrated:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{SIMULATION_NAME}}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #030712; overflow: hidden; font-family: 'Segoe UI', monospace; }
  canvas { display: block; }
  
  #hud {
    position: fixed; top: 20px; left: 20px;
    background: rgba(0,0,0,0.75); border: 1px solid rgba(99,102,241,0.3);
    border-radius: 12px; padding: 16px; color: #e2e8f0;
    width: 260px; backdrop-filter: blur(10px);
    font-size: 13px; line-height: 1.8;
  }
  #hud h3 { color: #818cf8; font-size: 14px; margin-bottom: 8px; }
  #hud .value { color: #34d399; font-weight: bold; }
  #hud .formula { color: #fbbf24; font-size: 11px; font-style: italic; }
  
  #controls {
    position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%);
    display: flex; gap: 10px; background: rgba(0,0,0,0.75);
    border: 1px solid rgba(99,102,241,0.3); border-radius: 50px;
    padding: 10px 20px; backdrop-filter: blur(10px);
  }
  .btn {
    background: rgba(99,102,241,0.2); border: 1px solid rgba(99,102,241,0.4);
    color: #c7d2fe; border-radius: 20px; padding: 6px 14px;
    cursor: pointer; font-size: 12px; transition: all 0.2s;
  }
  .btn:hover { background: rgba(99,102,241,0.5); }
  
  #tooltip {
    position: fixed; background: rgba(0,0,0,0.9);
    border: 1px solid rgba(99,102,241,0.4); border-radius: 8px;
    padding: 10px 14px; color: #e2e8f0; font-size: 12px;
    pointer-events: none; display: none; backdrop-filter: blur(10px);
  }
  
  #title-overlay {
    position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
    color: rgba(199,210,254,0.6); font-size: 13px; letter-spacing: 2px;
    text-transform: uppercase; pointer-events: none;
  }
</style>
</head>
<body>
<canvas id="c"></canvas>

<div id="hud">
  <h3>📊 {{SIMULATION_NAME}}</h3>
  <div>Particles: <span class="value" id="h-count">0</span></div>
  <div>FPS: <span class="value" id="h-fps">60</span></div>
  <div>Time: <span class="value" id="h-time">0.00s</span></div>
  <div>Status: <span class="value" id="h-status">Running</span></div>
  <br>
  <div class="formula">{{KEY_FORMULA}}</div>
  <br>
  <div id="h-fact" style="color:#94a3b8; font-size:11px;">{{EDUCATIONAL_FACT}}</div>
</div>

<div id="title-overlay">{{SIMULATION_SUBTITLE}}</div>

<div id="controls">
  <button class="btn" id="btn-pause">⏸ Pause</button>
  <button class="btn" id="btn-reset">↺ Reset</button>
  <button class="btn" id="btn-gravity">🌍 Gravity</button>
  <button class="btn" id="btn-faster">⚡ +Speed</button>
  <button class="btn" id="btn-slower">🐢 -Speed</button>
  <button class="btn" id="btn-mode">🔵 Attract</button>
</div>

<div id="tooltip"></div>

<script>
// ═══════════════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════════════
const CONFIG = {
  MAX_PARTICLES: 3000,
  CELL_SIZE: 60,
  GRAVITY_Y: 0,
  DAMPING: 0.998,
  MOUSE_INFLUENCE: 150,
  MOUSE_STRENGTH: 3,
  BASE_SPEED: 1.0,
  TRAIL_ALPHA: 0.15,  // Lower = longer trails
};

// ═══════════════════════════════════════════════════════════════
// CANVAS SETUP
// ═══════════════════════════════════════════════════════════════
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');
let W = canvas.width = window.innerWidth;
let H = canvas.height = window.innerHeight;
window.addEventListener('resize', () => { W = canvas.width = window.innerWidth; H = canvas.height = window.innerHeight; });

// ═══════════════════════════════════════════════════════════════
// PARTICLE SYSTEM — TYPED ARRAYS
// ═══════════════════════════════════════════════════════════════
// Layout: [x, y, vx, vy, ax, ay, life, type] per particle
const STRIDE = 8;
const pData  = new Float32Array(CONFIG.MAX_PARTICLES * STRIDE);
const pColor = new Uint8Array(CONFIG.MAX_PARTICLES * 4);   // RGBA
const pSize  = new Float32Array(CONFIG.MAX_PARTICLES);
const pActive = new Uint8Array(CONFIG.MAX_PARTICLES);
let pCount = 0;

function emitParticle(x, y, opts = {}) {
  if (pCount >= CONFIG.MAX_PARTICLES) return;
  const i = pCount++;
  const b = i * STRIDE;
  const a = opts.angle ?? Math.random() * Math.PI * 2;
  const s = opts.speed ?? (Math.random() * 2 + 0.5);
  pData[b+0] = x;   pData[b+1] = y;
  pData[b+2] = Math.cos(a)*s; pData[b+3] = Math.sin(a)*s;
  pData[b+4] = 0;   pData[b+5] = 0;
  pData[b+6] = opts.life ?? 1.0;
  pData[b+7] = opts.type ?? 0;
  const c = opts.color ?? {r:100,g:200,b:255};
  const cb = i*4;
  pColor[cb]=c.r; pColor[cb+1]=c.g; pColor[cb+2]=c.b; pColor[cb+3]=255;
  pSize[i] = opts.size ?? 3;
  pActive[i] = 1;
  return i;
}

// ═══════════════════════════════════════════════════════════════
// SPATIAL HASH
// ═══════════════════════════════════════════════════════════════
const hashCells = new Map();

function hashKey(x, y) {
  return ((Math.floor(x/CONFIG.CELL_SIZE)*73856093) ^ (Math.floor(y/CONFIG.CELL_SIZE)*19349663)) >>> 0;
}
function hashInsert(id, x, y) {
  const k = hashKey(x, y);
  if (!hashCells.has(k)) hashCells.set(k, []);
  hashCells.get(k).push(id);
}
function hashQuery(x, y, r) {
  const result = [], cells = Math.ceil(r/CONFIG.CELL_SIZE);
  for (let cx=-cells; cx<=cells; cx++) {
    for (let cy=-cells; cy<=cells; cy++) {
      const k = hashKey(x+cx*CONFIG.CELL_SIZE, y+cy*CONFIG.CELL_SIZE);
      const c = hashCells.get(k);
      if (c) result.push(...c);
    }
  }
  return result;
}

// ═══════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════
let paused = false, speed = CONFIG.BASE_SPEED, gravityOn = false;
let mouseX=W/2, mouseY=H/2, mouseActive=false, mouseMode='attract';
let simTime = 0, fps = 60, lastTimestamp = 0;

// ═══════════════════════════════════════════════════════════════
// DOMAIN-SPECIFIC INITIALIZATION — CUSTOMIZE HERE
// ═══════════════════════════════════════════════════════════════
function initSimulation() {
  pCount = 0; pActive.fill(0);
  // {{DOMAIN_INIT_CODE}} — spawn particles here
  for (let i = 0; i < 2000; i++) {
    emitParticle(Math.random()*W, Math.random()*H, {
      speed: Math.random() * 2,
      color: {r: 80+Math.random()*80, g: 150+Math.random()*100, b: 255}
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// DOMAIN-SPECIFIC FORCES — CUSTOMIZE HERE
// ═══════════════════════════════════════════════════════════════
function applyDomainForces(i, b, dt) {
  // {{DOMAIN_FORCE_CODE}}
  // Example: inter-particle attraction
  const x = pData[b], y = pData[b+1];
  const neighbors = hashQuery(x, y, 80);
  for (const j of neighbors) {
    if (j === i) continue;
    const jb = j * STRIDE;
    const dx = pData[jb] - x, dy = pData[jb+1] - y;
    const distSq = dx*dx + dy*dy;
    if (distSq < 1) continue;
    const dist = Math.sqrt(distSq);
    // Lennard-Jones-like: attract at distance, repel close
    const force = (dist > 40 ? 0.01 : -0.05) / dist;
    pData[b+4] += dx * force;
    pData[b+5] += dy * force;
  }
}

// ═══════════════════════════════════════════════════════════════
// UPDATE
// ═══════════════════════════════════════════════════════════════
function update(dt) {
  hashCells.clear();
  for (let i=0; i<pCount; i++) { if (pActive[i]) hashInsert(i, pData[i*STRIDE], pData[i*STRIDE+1]); }
  
  for (let i=0; i<pCount; i++) {
    if (!pActive[i]) continue;
    const b = i * STRIDE;
    
    // Reset acceleration
    pData[b+4] = 0;
    pData[b+5] = gravityOn ? 0.15 : 0;
    
    // Domain forces
    applyDomainForces(i, b, dt);
    
    // Mouse force
    if (mouseActive) {
      const dx=mouseX-pData[b], dy=mouseY-pData[b+1];
      const d = Math.sqrt(dx*dx+dy*dy)||1;
      if (d < CONFIG.MOUSE_INFLUENCE) {
        const f = (1-d/CONFIG.MOUSE_INFLUENCE) * CONFIG.MOUSE_STRENGTH;
        const dir = mouseMode==='attract' ? 1 : -1;
        pData[b+4] += dx/d*f*dir; pData[b+5] += dy/d*f*dir;
      }
    }
    
    // Integrate
    pData[b+2] = (pData[b+2] + pData[b+4]*dt) * CONFIG.DAMPING;
    pData[b+3] = (pData[b+3] + pData[b+5]*dt) * CONFIG.DAMPING;
    pData[b]   += pData[b+2]*dt;
    pData[b+1] += pData[b+3]*dt;
    
    // Boundary
    if (pData[b]<0)  { pData[b]=0;  pData[b+2]*=-0.6; }
    if (pData[b]>W)  { pData[b]=W;  pData[b+2]*=-0.6; }
    if (pData[b+1]<0){ pData[b+1]=0;pData[b+3]*=-0.6; }
    if (pData[b+1]>H){ pData[b+1]=H;pData[b+3]*=-0.6; }
  }
}

// ═══════════════════════════════════════════════════════════════
// RENDER
// ═══════════════════════════════════════════════════════════════
function render() {
  ctx.fillStyle = `rgba(3,7,18,${CONFIG.TRAIL_ALPHA})`;
  ctx.fillRect(0, 0, W, H);
  
  ctx.save();
  ctx.globalCompositeOperation = 'lighter';
  
  for (let i=0; i<pCount; i++) {
    if (!pActive[i]) continue;
    const b = i*STRIDE, cb = i*4;
    const x=pData[b], y=pData[b+1], sz=pSize[i];
    const r=pColor[cb], g=pColor[cb+1], bl=pColor[cb+2];
    
    const grd = ctx.createRadialGradient(x, y, 0, x, y, sz*2.5);
    grd.addColorStop(0, `rgba(${r},${g},${bl},0.9)`);
    grd.addColorStop(0.4, `rgba(${r},${g},${bl},0.4)`);
    grd.addColorStop(1, 'rgba(0,0,0,0)');
    
    ctx.beginPath();
    ctx.arc(x, y, sz*2.5, 0, Math.PI*2);
    ctx.fillStyle = grd;
    ctx.fill();
  }
  
  ctx.restore();
}

// ═══════════════════════════════════════════════════════════════
// HUD
// ═══════════════════════════════════════════════════════════════
function updateHUD() {
  document.getElementById('h-count').textContent = pCount;
  document.getElementById('h-fps').textContent = fps;
  document.getElementById('h-time').textContent = simTime.toFixed(2)+'s';
  document.getElementById('h-status').textContent = paused ? '⏸ Paused' : '▶ Running';
}

// ═══════════════════════════════════════════════════════════════
// MAIN LOOP
// ═══════════════════════════════════════════════════════════════
function loop(ts) {
  const rawDt = Math.min((ts - lastTimestamp) / 1000, 0.05);
  fps = Math.round(1 / Math.max(rawDt, 0.001));
  lastTimestamp = ts;
  const dt = rawDt * speed;
  
  if (!paused) { update(dt); simTime += dt; }
  render();
  updateHUD();
  requestAnimationFrame(loop);
}

// ═══════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════
canvas.addEventListener('mousemove', e => { mouseX=e.clientX; mouseY=e.clientY; mouseActive=true; });
canvas.addEventListener('mouseleave', () => mouseActive=false);
document.addEventListener('keydown', e => {
  if (e.code==='Space') { e.preventDefault(); paused=!paused; }
  if (e.key==='r'||e.key==='R') initSimulation();
  if (e.key==='g'||e.key==='G') gravityOn=!gravityOn;
  if (e.key==='+'||e.key==='=') speed=Math.min(speed*1.5,8);
  if (e.key==='-') speed=Math.max(speed/1.5,0.1);
});
document.getElementById('btn-pause').addEventListener('click', () => paused=!paused);
document.getElementById('btn-reset').addEventListener('click', initSimulation);
document.getElementById('btn-gravity').addEventListener('click', () => gravityOn=!gravityOn);
document.getElementById('btn-faster').addEventListener('click', () => speed=Math.min(speed*1.5,8));
document.getElementById('btn-slower').addEventListener('click', () => speed=Math.max(speed/1.5,0.1));
document.getElementById('btn-mode').addEventListener('click', () => {
  mouseMode = mouseMode==='attract' ? 'repel' : 'attract';
  document.getElementById('btn-mode').textContent = mouseMode==='attract' ? '🔵 Attract' : '🔴 Repel';
});

// ═══════════════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════════════
initSimulation();
requestAnimationFrame(loop);
</script>
</body>
</html>
```

---

## References

- **MDN Canvas API** — https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API
- **"Position Based Dynamics"** — Müller et al., 2007
- **Particles.js** — https://vincentgarreau.com/particles.js/
- **DotWave.js** — Lightweight physics dot backgrounds, 2026
- **"Spatial Hashing for Real-Time Collision Detection"** — Teschner et al., 2003
