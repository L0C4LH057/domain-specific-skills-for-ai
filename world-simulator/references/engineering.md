# Engineering & Prototype Simulation Reference

## 1. Structural Engineering (Finite Element–Inspired)

```javascript
// Spring-mass system for structural simulation
class StructuralMesh {
  constructor(nodes, beams) {
    // nodes: [{x, y, z, fixed, mass}]
    // beams: [{i, j, stiffness, restLength, maxStress}]
    this.nodes = nodes.map(n=>({...n, vx:0,vy:0,vz:0,ax:0,ay:0,az:0,stress:0}));
    this.beams = beams.map(b=>{
      const n1=nodes[b.i], n2=nodes[b.j];
      const dx=n2.x-n1.x, dy=n2.y-n1.y;
      return {...b, restLength:b.restLength||Math.sqrt(dx*dx+dy*dy), strain:0};
    });
    this.gravity = -9.8;
    this.dampening = 0.98;
  }
  
  update(dt, externalLoad=null) {
    // Reset forces
    for (const n of this.nodes) { n.ax=0; n.ay=this.gravity; }
    
    // Apply external load
    if (externalLoad) {
      const node = this.nodes[externalLoad.nodeIdx];
      node.ax += externalLoad.fx / node.mass;
      node.ay += externalLoad.fy / node.mass;
    }
    
    // Beam spring forces
    for (const beam of this.beams) {
      const n1=this.nodes[beam.i], n2=this.nodes[beam.j];
      const dx=n2.x-n1.x, dy=n2.y-n1.y;
      const len=Math.sqrt(dx*dx+dy*dy)||1;
      const extension=len-beam.restLength;
      beam.strain=extension/beam.restLength;
      const force=beam.stiffness*extension;
      const fx=force*(dx/len), fy=force*(dy/len);
      
      if (!n1.fixed){n1.ax+=fx/n1.mass;n1.ay+=fy/n1.mass;}
      if (!n2.fixed){n2.ax-=fx/n2.mass;n2.ay-=fy/n2.mass;}
    }
    
    // Integrate
    for (const n of this.nodes) {
      if (n.fixed) continue;
      n.vx=(n.vx+n.ax*dt)*this.dampening;
      n.vy=(n.vy+n.ay*dt)*this.dampening;
      n.x+=n.vx*dt; n.y+=n.vy*dt;
    }
  }
  
  render(ctx, toScreen) {
    for (const beam of this.beams) {
      const n1=this.nodes[beam.i], n2=this.nodes[beam.j];
      const p1=toScreen(n1.x,n1.y), p2=toScreen(n2.x,n2.y);
      // Color by stress: blue=compression, red=tension
      const stress=Math.abs(beam.strain);
      const r=Math.min(255,stress*2000), b=Math.min(255,stress*2000);
      ctx.beginPath(); ctx.moveTo(p1.x,p1.y); ctx.lineTo(p2.x,p2.y);
      ctx.strokeStyle=beam.strain>0?`rgba(${r},80,80,0.9)`:`rgba(80,80,${b},0.9)`;
      ctx.lineWidth=2+stress*20; ctx.stroke();
    }
    for (const n of this.nodes) {
      const p=toScreen(n.x,n.y);
      ctx.beginPath(); ctx.arc(p.x,p.y,n.fixed?8:6,0,Math.PI*2);
      ctx.fillStyle=n.fixed?'#ef4444':'#94a3b8'; ctx.fill();
    }
  }
}

// Pre-built engineering scenarios
function buildSuspensionBridge(cx, cy, span=600, towers=2) {
  const nodes=[], beams=[];
  // Tower nodes, deck nodes, cable nodes...
  // (full bridge construction code)
  return { nodes, beams };
}

function buildTruss(cx, cy, w=400, h=100, panels=8) {
  const nodes=[], beams=[];
  const panelW=w/panels;
  // Top chord, bottom chord, diagonals
  for (let i=0;i<=panels;i++) {
    nodes.push({x:cx-w/2+i*panelW, y:cy-h/2, vx:0,vy:0, fixed:i===0||i===panels, mass:1});
    nodes.push({x:cx-w/2+i*panelW, y:cy+h/2, vx:0,vy:0, fixed:false, mass:1});
  }
  // Connect chords and diagonals
  for (let i=0;i<panels;i++) {
    const t0=i*2, t1=(i+1)*2, b0=i*2+1, b1=(i+1)*2+1;
    beams.push({i:t0,j:t1,stiffness:500},{i:b0,j:b1,stiffness:500});
    beams.push({i:t0,j:b0,stiffness:300},{i:t0,j:b1,stiffness:200});
  }
  return {nodes,beams};
}
```

## 2. Fluid Flow & Pipe Systems

```javascript
// Simplified Navier-Stokes on grid (Eulerian)
class FluidGrid {
  constructor(w, h, res=40) {
    this.cols=Math.floor(w/res); this.rows=Math.floor(h/res);
    this.res=res;
    const n=this.cols*this.rows;
    this.vx=new Float32Array(n); this.vy=new Float32Array(n);
    this.density=new Float32Array(n); this.pressure=new Float32Array(n);
    this.viscosity=0.1;
  }
  
  idx(x,y){return y*this.cols+x;}
  
  addDensity(x,y,amount){
    const i=this.idx(Math.floor(x/this.res),Math.floor(y/this.res));
    if(i>=0&&i<this.density.length) this.density[i]+=amount;
  }
  
  addVelocity(x,y,vx,vy){
    const i=this.idx(Math.floor(x/this.res),Math.floor(y/this.res));
    if(i>=0&&i<this.vx.length){this.vx[i]+=vx;this.vy[i]+=vy;}
  }
  
  diffuse(dt){
    const a=dt*this.viscosity*(this.cols*this.rows);
    for(let k=0;k<20;k++){
      for(let y=1;y<this.rows-1;y++){
        for(let x=1;x<this.cols-1;x++){
          const i=this.idx(x,y);
          this.vx[i]=(this.vx[i]+a*(this.vx[i-1]+this.vx[i+1]+this.vx[i-this.cols]+this.vx[i+this.cols]))/(1+4*a);
          this.vy[i]=(this.vy[i]+a*(this.vy[i-1]+this.vy[i+1]+this.vy[i-this.cols]+this.vy[i+this.cols]))/(1+4*a);
        }
      }
    }
  }
  
  render(ctx) {
    for(let y=0;y<this.rows;y++){
      for(let x=0;x<this.cols;x++){
        const i=this.idx(x,y);
        const d=Math.min(this.density[i],1);
        if(d>0.01){
          ctx.fillStyle=`rgba(99,102,241,${d})`;
          ctx.fillRect(x*this.res,y*this.res,this.res,this.res);
        }
        // Velocity arrows
        const vMag=Math.sqrt(this.vx[i]**2+this.vy[i]**2);
        if(vMag>0.01){
          const cx2=x*this.res+this.res/2, cy2=y*this.res+this.res/2;
          const scale=Math.min(vMag*5,this.res*0.4);
          ctx.beginPath(); ctx.moveTo(cx2,cy2);
          ctx.lineTo(cx2+this.vx[i]/vMag*scale,cy2+this.vy[i]/vMag*scale);
          ctx.strokeStyle=`rgba(34,197,94,0.6)`; ctx.lineWidth=1; ctx.stroke();
        }
      }
    }
  }
}
```

## 3. Electrical Circuit Simulation

```javascript
class CircuitSimulation {
  constructor() {
    this.components=[]; // {type:'R'|'C'|'L'|'V'|'wire', x1,y1,x2,y2,value,current}
    this.nodes=[];      // Junction points with voltages
    this.electrons=[];  // Visual particles flowing through wire
    this.time=0;
  }
  
  // Spawn electrons proportional to current
  spawnElectrons(component, dt) {
    const rate = Math.abs(component.current) * 50;
    if (Math.random() < rate*dt) {
      this.electrons.push({
        x: component.x1, y: component.y1,
        targetX: component.x2, targetY: component.y2,
        progress: 0,
        component: component,
        positive: component.current > 0,
      });
    }
  }
  
  update(dt) {
    this.time+=dt;
    // Move electrons along wire
    for (const e of this.electrons) {
      e.progress+=Math.abs(e.component.current)*dt*0.5;
      e.x=e.component.x1+(e.component.x2-e.component.x1)*e.progress;
      e.y=e.component.y1+(e.component.y2-e.component.y1)*e.progress;
    }
    this.electrons=this.electrons.filter(e=>e.progress<1.0);
  }
  
  render(ctx) {
    // Draw components
    for (const c of this.components) {
      if (c.type==='wire') {
        ctx.beginPath(); ctx.moveTo(c.x1,c.y1); ctx.lineTo(c.x2,c.y2);
        ctx.strokeStyle='rgba(148,163,184,0.7)'; ctx.lineWidth=2; ctx.stroke();
      }
      // Draw resistor, capacitor, etc. as symbols...
    }
    // Draw electrons
    for (const e of this.electrons) {
      ctx.beginPath(); ctx.arc(e.x,e.y,3,0,Math.PI*2);
      ctx.fillStyle=e.positive?'rgba(239,68,68,0.9)':'rgba(99,102,241,0.9)';
      ctx.fill();
    }
  }
}
```

---

## References

- **"Engineering Mechanics: Statics & Dynamics"** — Meriam & Kraige
- **PyBullet Physics** — https://pybullet.org/ (Python rigid body + multi-physics)
- **"Computational Fluid Dynamics"** — Anderson, McGraw-Hill
- **"Numerical Recipes in C"** — Press et al. (algorithms reference)
- **Godot Engine** — https://godotengine.org/ (lightweight 3D/2D simulation)
- **"Introduction to Finite Element Analysis"** — Bhavikatti
- **Three.js Examples** — https://threejs.org/examples/ (visual reference for 3D engineering viz)
