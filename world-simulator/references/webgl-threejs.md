# WebGL & Three.js 3D Simulation Reference

## Table of Contents
1. [Three.js Setup Pattern](#setup)
2. [InstancedMesh for Massive Particle Counts](#instanced)
3. [3D Particle Systems via Points](#points)
4. [Orbit Controls & Camera](#camera)
5. [Lighting & Materials](#lighting)
6. [Post-Processing (Bloom/Glow)](#postprocessing)
7. [3D Labels & Annotations](#labels)
8. [Complete 3D Simulation Template](#template)

---

## 1. Three.js Setup Pattern {#setup}

Always load Three.js from CDN in artifacts (no npm in browser context).

```html
<!-- Required imports -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<!-- OrbitControls must be loaded separately for r128 -->
<script>
// Since r128 doesn't bundle OrbitControls on CDN easily, implement lightweight version:
class SimpleOrbitControls {
  constructor(camera, domElement) {
    this.camera = camera;
    this.target = new THREE.Vector3();
    this.spherical = { radius: 5, phi: Math.PI/4, theta: 0 };
    this.isDragging = false;
    this.prevMouse = { x: 0, y: 0 };
    
    domElement.addEventListener('mousedown', e => { this.isDragging=true; this.prevMouse={x:e.clientX,y:e.clientY}; });
    domElement.addEventListener('mouseup', () => this.isDragging=false);
    domElement.addEventListener('mousemove', e => {
      if (!this.isDragging) return;
      const dx = e.clientX - this.prevMouse.x;
      const dy = e.clientY - this.prevMouse.y;
      this.spherical.theta -= dx * 0.005;
      this.spherical.phi = Math.max(0.1, Math.min(Math.PI-0.1, this.spherical.phi - dy * 0.005));
      this.prevMouse = {x: e.clientX, y: e.clientY};
      this.update();
    });
    domElement.addEventListener('wheel', e => {
      this.spherical.radius = Math.max(1, Math.min(100, this.spherical.radius + e.deltaY * 0.01));
      this.update();
    });
    this.update();
  }
  
  update() {
    const { radius, phi, theta } = this.spherical;
    this.camera.position.set(
      this.target.x + radius * Math.sin(phi) * Math.sin(theta),
      this.target.y + radius * Math.cos(phi),
      this.target.z + radius * Math.sin(phi) * Math.cos(theta)
    );
    this.camera.lookAt(this.target);
  }
}
</script>
```

### Scene Initialization
```javascript
// Canonical Three.js setup for simulations
function initThreeJS() {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x030712);
  scene.fog = new THREE.FogExp2(0x030712, 0.02); // Optional atmospheric fog
  
  const camera = new THREE.PerspectiveCamera(
    60,                               // FOV
    window.innerWidth / window.innerHeight, // Aspect
    0.01,                             // Near plane
    10000                             // Far plane
  );
  camera.position.set(0, 5, 15);
  
  const renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: false,
    powerPreference: 'high-performance'
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // Cap at 2x for performance
  renderer.outputEncoding = THREE.sRGBEncoding;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  document.body.appendChild(renderer.domElement);
  
  const controls = new SimpleOrbitControls(camera, renderer.domElement);
  
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
  
  return { scene, camera, renderer, controls };
}
```

---

## 2. InstancedMesh for Massive Particle Counts {#instanced}

Use InstancedMesh when rendering 1,000–100,000 identical geometry objects. Single draw call.

```javascript
function createInstancedParticles(scene, count, radius = 0.08) {
  const geometry = new THREE.SphereGeometry(radius, 6, 6); // Low poly for performance
  const material = new THREE.MeshStandardMaterial({
    color: 0x4f46e5,
    emissive: 0x3730a3,
    emissiveIntensity: 0.5,
    metalness: 0.1,
    roughness: 0.6,
  });
  
  const mesh = new THREE.InstancedMesh(geometry, material, count);
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage); // Will update every frame
  
  // Color per instance
  const colors = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    colors[i*3]   = Math.random();
    colors[i*3+1] = 0.5 + Math.random() * 0.5;
    colors[i*3+2] = 1.0;
  }
  mesh.instanceColor = new THREE.InstancedBufferAttribute(colors, 3);
  
  scene.add(mesh);
  return mesh;
}

// Update instance positions from physics data
const dummy = new THREE.Object3D();

function updateInstancedMesh(mesh, positions, count) {
  for (let i = 0; i < count; i++) {
    dummy.position.set(positions[i*3], positions[i*3+1], positions[i*3+2]);
    dummy.updateMatrix();
    mesh.setMatrixAt(i, dummy.matrix);
  }
  mesh.instanceMatrix.needsUpdate = true;
}
```

---

## 3. 3D Particle Systems via Points {#points}

For millions of particles as points/sprites — single draw call, GPU-rendered.

```javascript
function createPointCloud(scene, count) {
  const positions = new Float32Array(count * 3);
  const colors = new Float32Array(count * 3);
  const sizes = new Float32Array(count);
  
  for (let i = 0; i < count; i++) {
    positions[i*3]   = (Math.random()-0.5) * 20;
    positions[i*3+1] = (Math.random()-0.5) * 20;
    positions[i*3+2] = (Math.random()-0.5) * 20;
    colors[i*3] = 0.3 + Math.random() * 0.7;
    colors[i*3+1] = 0.6 + Math.random() * 0.4;
    colors[i*3+2] = 1.0;
    sizes[i] = Math.random() * 3 + 1;
  }
  
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));
  
  const material = new THREE.PointsMaterial({
    size: 0.15,
    vertexColors: true,
    transparent: true,
    opacity: 0.85,
    blending: THREE.AdditiveBlending, // Glow effect
    depthWrite: false,
    sizeAttenuation: true,            // Particles far away appear smaller
  });
  
  const points = new THREE.Points(geometry, material);
  scene.add(points);
  return { points, positions }; // Return positions array for physics updates
}

// Update point cloud from physics simulation
function updatePointCloud(points, physicsPositions) {
  const attr = points.geometry.getAttribute('position');
  for (let i = 0; i < physicsPositions.length; i++) {
    attr.array[i] = physicsPositions[i];
  }
  attr.needsUpdate = true;
}
```

---

## 4. Lighting & Materials {#lighting}

### Scientific Visualization Lighting Rig
```javascript
function setupLighting(scene) {
  // Ambient: fills shadows softly
  const ambient = new THREE.AmbientLight(0x111133, 0.8);
  scene.add(ambient);
  
  // Key light: primary illumination
  const keyLight = new THREE.DirectionalLight(0x6366f1, 2.0);
  keyLight.position.set(5, 10, 5);
  scene.add(keyLight);
  
  // Fill light: secondary, softer
  const fillLight = new THREE.DirectionalLight(0x818cf8, 0.5);
  fillLight.position.set(-5, 5, -5);
  scene.add(fillLight);
  
  // Rim light: edge highlighting (cinematic)
  const rimLight = new THREE.DirectionalLight(0x34d399, 0.3);
  rimLight.position.set(0, -5, -10);
  scene.add(rimLight);
  
  // Point lights for "glowing core" effect
  const coreGlow = new THREE.PointLight(0x4f46e5, 2, 8);
  coreGlow.position.set(0, 0, 0);
  scene.add(coreGlow);
  
  return { ambient, keyLight, fillLight, rimLight, coreGlow };
}
```

### Emissive/Glowing Material (Atoms, Stars, Energy)
```javascript
const glowMaterial = new THREE.MeshStandardMaterial({
  color: 0x1e1b4b,
  emissive: new THREE.Color(0x4f46e5),
  emissiveIntensity: 2.0,
  transparent: true,
  opacity: 0.9,
});

// Atom nucleus: bright core
const nucleusMat = new THREE.MeshStandardMaterial({
  color: 0xfef3c7,
  emissive: new THREE.Color(0xf59e0b),
  emissiveIntensity: 3.0,
  metalness: 0.3,
  roughness: 0.2,
});
```

---

## 5. 3D Labels & Annotations {#labels}

```javascript
// Create floating text label in 3D space
function createLabel(text, color = '#c7d2fe') {
  const canvas = document.createElement('canvas');
  canvas.width = 256; canvas.height = 64;
  const ctx = canvas.getContext('2d');
  
  ctx.fillStyle = 'rgba(0,0,0,0)';
  ctx.clearRect(0, 0, 256, 64);
  
  ctx.font = 'bold 24px "Segoe UI", sans-serif';
  ctx.fillStyle = color;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 128, 32);
  
  const texture = new THREE.CanvasTexture(canvas);
  const material = new THREE.SpriteMaterial({ map: texture, transparent: true, depthWrite: false });
  const sprite = new THREE.Sprite(material);
  sprite.scale.set(2, 0.5, 1);
  return sprite;
}

// Usage: label follows a 3D object
const label = createLabel('Hydrogen (H)');
hydrogenAtom.add(label); // Child of the atom — moves with it
label.position.set(0, 1.5, 0); // Offset above the atom
```

---

## 6. Complete 3D Simulation Template {#template}

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>{{3D_SIM_NAME}}</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { background:#030712; overflow:hidden; font-family:'Segoe UI',monospace; }
  canvas { display:block; }
  #hud {
    position:fixed; top:20px; left:20px; width:260px;
    background:rgba(0,0,0,0.8); border:1px solid rgba(99,102,241,0.3);
    border-radius:12px; padding:16px; color:#e2e8f0; font-size:13px;
    line-height:1.9; backdrop-filter:blur(10px);
  }
  #hud h3 { color:#818cf8; font-size:14px; margin-bottom:8px; }
  .val { color:#34d399; font-weight:bold; }
  #controls {
    position:fixed; bottom:20px; left:50%; transform:translateX(-50%);
    display:flex; gap:8px; background:rgba(0,0,0,0.8);
    border:1px solid rgba(99,102,241,0.3); border-radius:50px;
    padding:10px 20px; backdrop-filter:blur(10px);
  }
  .btn { background:rgba(99,102,241,0.15); border:1px solid rgba(99,102,241,0.4);
    color:#c7d2fe; border-radius:20px; padding:6px 14px; cursor:pointer; font-size:12px; }
  .btn:hover { background:rgba(99,102,241,0.4); }
  #hint { position:fixed; bottom:70px; left:50%; transform:translateX(-50%);
    color:rgba(148,163,184,0.5); font-size:11px; pointer-events:none; }
</style>
</head>
<body>
<div id="hud">
  <h3>🌐 {{3D_SIM_NAME}}</h3>
  <div>FPS: <span class="val" id="fps">60</span></div>
  <div>Objects: <span class="val" id="objCount">0</span></div>
  <div>Time: <span class="val" id="simTime">0.00s</span></div>
  <hr style="border-color:rgba(99,102,241,0.2); margin:8px 0">
  <div style="color:#fbbf24; font-size:11px;">{{KEY_FORMULA}}</div>
  <br>
  <div style="color:#94a3b8; font-size:11px;">{{EDUCATIONAL_FACT}}</div>
</div>
<div id="controls">
  <button class="btn" id="btnPause">⏸ Pause</button>
  <button class="btn" id="btnReset">↺ Reset</button>
  <button class="btn" id="btnSpeed">⚡ Speed</button>
  <button class="btn" id="btnWire">⬡ Wireframe</button>
</div>
<div id="hint">🖱 Drag to orbit · Scroll to zoom · Click particles to inspect</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script>
// ── Simple Orbit Controls ─────────────────────────────────────
class OrbitCam {
  constructor(cam, dom) {
    this.cam=cam; this.r=15; this.phi=Math.PI/4; this.theta=0;
    this.target=new THREE.Vector3(); this.drag=false; this.prev={x:0,y:0};
    dom.addEventListener('mousedown',e=>{this.drag=true;this.prev={x:e.clientX,y:e.clientY};});
    window.addEventListener('mouseup',()=>this.drag=false);
    window.addEventListener('mousemove',e=>{
      if(!this.drag)return;
      this.theta-=(e.clientX-this.prev.x)*0.004;
      this.phi=Math.max(0.1,Math.min(Math.PI-0.1,this.phi-(e.clientY-this.prev.y)*0.004));
      this.prev={x:e.clientX,y:e.clientY}; this.update();
    });
    dom.addEventListener('wheel',e=>{this.r=Math.max(2,Math.min(80,this.r+e.deltaY*0.01));this.update();});
    this.update();
  }
  update() {
    const {r,phi,theta}=this;
    this.cam.position.set(r*Math.sin(phi)*Math.sin(theta),r*Math.cos(phi),r*Math.sin(phi)*Math.cos(theta));
    this.cam.lookAt(this.target);
  }
}

// ── Scene Setup ───────────────────────────────────────────────
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x030712);
const W=window.innerWidth, H=window.innerHeight;
const camera = new THREE.PerspectiveCamera(60, W/H, 0.01, 5000);
const renderer = new THREE.WebGLRenderer({antialias:true});
renderer.setSize(W, H);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
document.body.appendChild(renderer.domElement);
const controls = new OrbitCam(camera, renderer.domElement);

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth/window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// ── Lighting ──────────────────────────────────────────────────
scene.add(new THREE.AmbientLight(0x111133, 1));
const key = new THREE.DirectionalLight(0x818cf8, 2);
key.position.set(5,10,5); scene.add(key);
const fill = new THREE.DirectionalLight(0x34d399, 0.4);
fill.position.set(-5,5,-5); scene.add(fill);

// ── Grid / Reference ──────────────────────────────────────────
const grid = new THREE.GridHelper(20, 20, 0x1e293b, 0x1e293b);
scene.add(grid);

// ── DOMAIN OBJECTS — CUSTOMIZE BELOW ─────────────────────────
// {{3D_DOMAIN_CODE}}
const objects = []; // Populate with your 3D objects

// ── Physics State ─────────────────────────────────────────────
let paused=false, speed=1.0, simTime=0, fps=60, lastTs=0;
let wireframe=false;

// ── Update ────────────────────────────────────────────────────
function update(dt) {
  // {{3D_PHYSICS_UPDATE}}
  for (const obj of objects) {
    if (obj.update) obj.update(dt);
  }
}

// ── Render Loop ───────────────────────────────────────────────
function loop(ts) {
  const dt = Math.min((ts-lastTs)/1000, 0.05) * speed;
  fps = Math.round(1/Math.max((ts-lastTs)/1000, 0.001));
  lastTs = ts;
  if (!paused) { update(dt); simTime += dt; }
  renderer.render(scene, camera);
  document.getElementById('fps').textContent = fps;
  document.getElementById('objCount').textContent = objects.length;
  document.getElementById('simTime').textContent = simTime.toFixed(2)+'s';
  requestAnimationFrame(loop);
}

// ── Controls ──────────────────────────────────────────────────
document.getElementById('btnPause').addEventListener('click', () => paused=!paused);
document.getElementById('btnReset').addEventListener('click', () => { simTime=0; initScene(); });
document.getElementById('btnSpeed').addEventListener('click', () => speed = speed >= 4 ? 0.25 : speed*2);
document.getElementById('btnWire').addEventListener('click', () => {
  wireframe=!wireframe;
  scene.traverse(obj => { if(obj.material) obj.material.wireframe = wireframe; });
});
document.addEventListener('keydown', e => {
  if(e.code==='Space'){e.preventDefault();paused=!paused;}
  if(e.key==='r'||e.key==='R') { simTime=0; initScene(); }
});

function initScene() {
  // {{3D_INIT_CODE}}
}

initScene();
requestAnimationFrame(loop);
</script>
</body>
</html>
```

---

## References

- **Three.js Documentation** — https://threejs.org/docs/
- **Three.js r128 CDN** — https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js
- **"Real-Time Rendering"** — Akenine-Möller et al., 4th Edition
- **Bruno Simon's Three.js Journey** — https://threejs-journey.com/
- **NVIDIA Isaac Sim** — https://developer.nvidia.com/isaac-sim (for robotics/physics)
- **"WebGPU Fundamentals"** — https://webgpufundamentals.org/ (next-gen, compute shaders)
