# Cosmos & Astronomy Simulation Reference

## 1. N-Body Gravitational Simulation

```javascript
// Barnes-Hut algorithm for O(n log n) gravity
class QuadTree {
  constructor(x, y, w, h) {
    this.bounds={x,y,w,h}; this.body=null; this.children=null;
    this.totalMass=0; this.cx=0; this.cy=0;
  }
  
  insert(body) {
    if (!this.body && !this.children) { this.body=body; this.updateCOM(); return; }
    if (!this.children) this.subdivide();
    for (const child of this.children) {
      if (child.contains(body)) { child.insert(body); break; }
    }
    this.body=null; this.updateCOM();
  }
  
  contains(body) {
    const {x,y,w,h}=this.bounds;
    return body.x>=x&&body.x<x+w&&body.y>=y&&body.y<y+h;
  }
  
  subdivide() {
    const {x,y,w,h}=this.bounds, hw=w/2, hh=h/2;
    this.children=[
      new QuadTree(x,y,hw,hh), new QuadTree(x+hw,y,hw,hh),
      new QuadTree(x,y+hh,hw,hh), new QuadTree(x+hw,y+hh,hw,hh)
    ];
    if (this.body) { for (const c of this.children) if(c.contains(this.body)){c.insert(this.body);break;} this.body=null; }
  }
  
  updateCOM() {
    if (this.body) { this.totalMass=this.body.mass; this.cx=this.body.x; this.cy=this.body.y; return; }
    if (this.children) {
      this.totalMass=0; let mx=0, my=0;
      for (const c of this.children) { this.totalMass+=c.totalMass; mx+=c.cx*c.totalMass; my+=c.cy*c.totalMass; }
      if (this.totalMass>0) { this.cx=mx/this.totalMass; this.cy=my/this.totalMass; }
    }
  }
  
  computeForce(body, theta=0.5, G=1) {
    const dx=this.cx-body.x, dy=this.cy-body.y;
    const r=Math.sqrt(dx*dx+dy*dy)+0.5;
    const {w,h}=this.bounds;
    if (!this.children || Math.max(w,h)/r < theta) {
      // Treat as single mass (far-field approximation)
      if (this.totalMass===0||r<1) return {fx:0,fy:0};
      const f=G*body.mass*this.totalMass/(r*r*r);
      return {fx:f*dx, fy:f*dy};
    }
    let fx=0, fy=0;
    for (const c of this.children) { const f=c.computeForce(body,theta,G); fx+=f.fx; fy+=f.fy; }
    return {fx, fy};
  }
}

// Stellar classification and colors
const STAR_TYPES = {
  O: { temp:'30,000–50,000K', color:{r:160,g:190,b:255}, size:8,  luminosity:'×30,000',  lifespan:'3M years',   label:'Blue Giant' },
  B: { temp:'10,000–30,000K', color:{r:180,g:210,b:255}, size:6,  luminosity:'×100',     lifespan:'30M years',  label:'Blue-White Star' },
  A: { temp:'7,500–10,000K',  color:{r:210,g:230,b:255}, size:5,  luminosity:'×5',       lifespan:'500M years', label:'White Star' },
  F: { temp:'6,000–7,500K',   color:{r:255,g:245,b:200}, size:4,  luminosity:'×2',       lifespan:'3B years',   label:'Yellow-White Star' },
  G: { temp:'5,200–6,000K',   color:{r:255,g:220,b:150}, size:3.5,luminosity:'×1 (Sun)', lifespan:'10B years',  label:'Yellow Dwarf (Sun-like)' },
  K: { temp:'3,700–5,200K',   color:{r:255,g:165,b:80},  size:3,  luminosity:'×0.2',     lifespan:'30B years',  label:'Orange Dwarf' },
  M: { temp:'2,400–3,700K',   color:{r:255,g:80,b:40},   size:2,  luminosity:'×0.01',    lifespan:'200B years', label:'Red Dwarf' },
};

// Galaxy particle system
function generateSpiral(cx, cy, arms=2, stars=3000) {
  const particles = [];
  for (let i=0; i<stars; i++) {
    const arm = Math.floor(Math.random()*arms);
    const t = Math.random() * Math.PI * 6;
    const r = t * 20 + Math.random() * 15;
    const angle = t + (arm/arms)*Math.PI*2;
    const x = cx + r * Math.cos(angle) + (Math.random()-0.5)*8;
    const y = cy + r * Math.sin(angle) * 0.4 + (Math.random()-0.5)*8; // Flatten for disk
    const armFraction = t/(Math.PI*6);
    const typeKeys = Object.keys(STAR_TYPES);
    const typeIdx = Math.floor(Math.pow(Math.random(),0.5)*typeKeys.length);
    const type = typeKeys[typeIdx];
    particles.push({ x, y, type, color: STAR_TYPES[type].color, size: STAR_TYPES[type].size*0.5 });
  }
  return particles;
}
```

## 2. Black Hole Gravitational Lensing

```javascript
// Gravitational lensing effect (visual distortion)
function applyGravitationalLensing(ctx, blackHoleX, blackHoleY, mass, W, H) {
  const imageData = ctx.getImageData(0, 0, W, H);
  const data = imageData.data;
  const output = new Uint8ClampedArray(data.length);
  
  for (let y=0; y<H; y++) {
    for (let x=0; x<W; x++) {
      const dx=x-blackHoleX, dy=y-blackHoleY;
      const r2=dx*dx+dy*dy;
      const r=Math.sqrt(r2)||1;
      
      // Schwarzschild radius (visual)
      const rs = mass * 20;
      if (r < rs) { // Event horizon — black
        const idx=(y*W+x)*4;
        output[idx]=output[idx+1]=output[idx+2]=0; output[idx+3]=255;
        continue;
      }
      
      // Deflection angle: α = 4GM/rc² (simplified)
      const deflection = mass * 10000 / (r2);
      const srcX = Math.round(x + dx/r * deflection);
      const srcY = Math.round(y + dy/r * deflection);
      
      if (srcX>=0&&srcX<W&&srcY>=0&&srcY<H) {
        const srcIdx=(srcY*W+srcX)*4, dstIdx=(y*W+x)*4;
        output[dstIdx]=data[srcIdx]; output[dstIdx+1]=data[srcIdx+1];
        output[dstIdx+2]=data[srcIdx+2]; output[dstIdx+3]=data[srcIdx+3];
      }
    }
  }
  ctx.putImageData(new ImageData(output, W, H), 0, 0);
}
```

## 3. Solar System Model

```javascript
const SOLAR_SYSTEM = {
  sun:     { mass:1000, radius:25, color:{r:255,g:220,b:50}, emissive:true },
  mercury: { mass:0.05, dist:80,  period:0.24, radius:4,  color:{r:180,g:150,b:120} },
  venus:   { mass:0.8,  dist:120, period:0.62, radius:7,  color:{r:220,g:180,b:100} },
  earth:   { mass:1,    dist:170, period:1.0,  radius:8,  color:{r:50,g:150,b:230} },
  mars:    { mass:0.1,  dist:230, period:1.88, radius:5,  color:{r:200,g:80,b:50} },
  jupiter: { mass:318,  dist:380, period:11.9, radius:20, color:{r:200,g:170,b:120} },
  saturn:  { mass:95,   dist:500, period:29.5, radius:17, color:{r:210,g:185,b:140}, rings:true },
};

function updateOrbit(planet, dt, t) {
  const omega = (2*Math.PI) / (planet.period * 200); // Angular velocity
  planet.angle = (planet.angle || 0) + omega * dt;
  planet.x = planet.cx + planet.dist * Math.cos(planet.angle);
  planet.y = planet.cy + planet.dist * Math.sin(planet.angle) * 0.4; // Inclined orbit
}
```

---

## References

- **"An Introduction to Modern Astrophysics"** — Carroll & Ostlie, 2nd Edition
- **"Computational Astrophysics"** — Springel et al.
- **NASA JPL Horizons** — https://ssd.jpl.nasa.gov/horizons/ (solar system data)
- **Space Engine** — https://spaceengine.org/ (reference for visual quality)
- **"The Observable Universe"** — ESA/Hubble reference
- **Three.js Solar System** — https://threejs.org/examples/#webgl_points_sprites
- **Barnes & Hut, 1986** — "A hierarchical O(N log N) force-calculation algorithm"
