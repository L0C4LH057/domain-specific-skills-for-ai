# Chemistry & Biology Simulation Reference

## Table of Contents
1. [Molecular Bonding & Reactions](#molecules)
2. [Cell Biology Simulations](#cells)
3. [Epidemiology (SIR/Agent Models)](#epidemiology)
4. [DNA / Protein Structures](#dna)
5. [Ecology & Population Dynamics](#ecology)
6. [Periodic Table Particle Encoding](#periodic)

---

## 1. Molecular Bonding & Reactions {#molecules}

```javascript
// Element data for simulation
const ELEMENTS = {
  H:  { symbol:'H',  name:'Hydrogen',  mass:1,  radius:12, color:{r:255,g:255,b:255}, maxBonds:1, electronegativity:2.1 },
  C:  { symbol:'C',  name:'Carbon',    mass:12, radius:18, color:{r:80,g:80,b:80},    maxBonds:4, electronegativity:2.5 },
  N:  { symbol:'N',  name:'Nitrogen',  mass:14, radius:16, color:{r:50,g:100,b:255},  maxBonds:3, electronegativity:3.0 },
  O:  { symbol:'O',  name:'Oxygen',    mass:16, radius:17, color:{r:255,g:50,b:50},   maxBonds:2, electronegativity:3.4 },
  Na: { symbol:'Na', name:'Sodium',    mass:23, radius:20, color:{r:150,g:100,b:255}, maxBonds:1, electronegativity:0.9 },
  Cl: { symbol:'Cl', name:'Chlorine',  mass:35, radius:20, color:{r:100,g:200,b:50},  maxBonds:1, electronegativity:3.2 },
  Fe: { symbol:'Fe', name:'Iron',      mass:56, radius:22, color:{r:200,g:100,b:50},  maxBonds:3, electronegativity:1.8 },
};

// Bond types
const BOND_TYPES = {
  single: { length: 40, stiffness: 0.3, width: 2, color: 'rgba(200,200,200,0.7)' },
  double: { length: 35, stiffness: 0.4, width: 3, color: 'rgba(100,200,255,0.8)' },
  triple: { length: 30, stiffness: 0.5, width: 4, color: 'rgba(100,255,200,0.9)' },
  ionic:  { length: 60, stiffness: 0.1, width: 1.5, color: 'rgba(255,200,100,0.6)', dashed: true },
  hydrogen:{ length:70, stiffness:0.05, width:1, color:'rgba(150,150,255,0.4)', dashed:true },
};

class MoleculeSimulation {
  constructor(atoms, bonds) {
    this.atoms = atoms;   // [{element, x, y, vx, vy}]
    this.bonds = bonds;   // [{i, j, type}]
  }
  
  update(dt) {
    // PBD-style bond constraint solving
    for (const bond of this.bonds) {
      const a = this.atoms[bond.i], b = this.atoms[bond.j];
      const dx=b.x-a.x, dy=b.y-a.y;
      const dist=Math.sqrt(dx*dx+dy*dy)||1;
      const restLen = BOND_TYPES[bond.type].length;
      const k = BOND_TYPES[bond.type].stiffness;
      const correction = (dist-restLen)/dist * k;
      const massA = ELEMENTS[a.element].mass, massB = ELEMENTS[b.element].mass;
      const totalMass = massA + massB;
      a.x += dx*correction*(massB/totalMass);
      a.y += dy*correction*(massB/totalMass);
      b.x -= dx*correction*(massA/totalMass);
      b.y -= dy*correction*(massA/totalMass);
    }
    
    // Van der Waals repulsion between non-bonded atoms
    for (let i=0; i<this.atoms.length; i++) {
      for (let j=i+1; j<this.atoms.length; j++) {
        if (this.areBonded(i,j)) continue;
        const a=this.atoms[i], b=this.atoms[j];
        const dx=b.x-a.x, dy=b.y-a.y;
        const r=Math.sqrt(dx*dx+dy*dy)||1;
        const minDist = (ELEMENTS[a.element].radius + ELEMENTS[b.element].radius)*1.5;
        if (r < minDist) {
          const f=(1-r/minDist)*0.5;
          a.x-=dx/r*f; a.y-=dy/r*f;
          b.x+=dx/r*f; b.y+=dy/r*f;
        }
      }
    }
    
    // Velocity integration
    for (const atom of this.atoms) {
      atom.x+=atom.vx*dt; atom.y+=atom.vy*dt;
      atom.vx*=0.98; atom.vy*=0.98;
    }
  }
  
  areBonded(i, j) { return this.bonds.some(b => (b.i===i&&b.j===j)||(b.i===j&&b.j===i)); }
  
  render(ctx) {
    // Draw bonds
    for (const bond of this.bonds) {
      const a=this.atoms[bond.i], b=this.atoms[bond.j];
      const bt=BOND_TYPES[bond.type];
      ctx.beginPath();
      if (bt.dashed) ctx.setLineDash([6,4]);
      ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y);
      ctx.strokeStyle=bt.color; ctx.lineWidth=bt.width; ctx.stroke();
      ctx.setLineDash([]);
    }
    
    // Draw atoms
    for (const atom of this.atoms) {
      const el=ELEMENTS[atom.element];
      const grd=ctx.createRadialGradient(atom.x,atom.y,0,atom.x,atom.y,el.radius);
      grd.addColorStop(0,`rgba(${el.color.r+50},${el.color.g+50},${el.color.b+50},1)`);
      grd.addColorStop(1,`rgba(${el.color.r},${el.color.g},${el.color.b},0.8)`);
      ctx.beginPath();
      ctx.arc(atom.x,atom.y,el.radius,0,Math.PI*2);
      ctx.fillStyle=grd; ctx.fill();
      ctx.fillStyle='white'; ctx.font='bold 11px sans-serif';
      ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(atom.element,atom.x,atom.y);
    }
  }
}

// Pre-built molecules
function buildWater(cx, cy) {
  const O={element:'O',x:cx,y:cy,vx:0,vy:0};
  const H1={element:'H',x:cx-35,y:cy+25,vx:0,vy:0};
  const H2={element:'H',x:cx+35,y:cy+25,vx:0,vy:0};
  return { atoms:[O,H1,H2], bonds:[{i:0,j:1,type:'single'},{i:0,j:2,type:'single'}] };
}

function buildCO2(cx, cy) {
  const C={element:'C',x:cx,y:cy,vx:0,vy:0};
  const O1={element:'O',x:cx-55,y:cy,vx:0,vy:0};
  const O2={element:'O',x:cx+55,y:cy,vx:0,vy:0};
  return { atoms:[C,O1,O2], bonds:[{i:0,j:1,type:'double'},{i:0,j:2,type:'double'}] };
}

// Chemical reaction simulation: A + B → C
function simulateReaction(particlesA, particlesB, activationEnergy, onReaction) {
  for (const a of particlesA) {
    for (const b of particlesB) {
      const dx=b.x-a.x, dy=b.y-a.y;
      const distSq=dx*dx+dy*dy;
      const reactionRadius=50;
      if (distSq < reactionRadius*reactionRadius) {
        const kineticEnergy = 0.5*(a.vx*a.vx+a.vy*a.vy+b.vx*b.vx+b.vy*b.vy);
        if (kineticEnergy > activationEnergy) {
          onReaction(a, b); // Merge into product particle
        }
      }
    }
  }
}
```

---

## 2. Cell Biology Simulations {#cells}

```javascript
// Cell membrane simulation with lipid bilayer particles
class CellMembrane {
  constructor(cx, cy, radius, particleCount=120) {
    this.cx=cx; this.cy=cy; this.radius=radius;
    this.lipids = [];
    for (let i=0; i<particleCount; i++) {
      const angle = (i/particleCount) * Math.PI*2;
      // Outer lipid head (hydrophilic)
      this.lipids.push({
        x: cx + (radius+8)*Math.cos(angle),
        y: cy + (radius+8)*Math.sin(angle),
        angle, layer:'outer', type:'head'
      });
      // Inner lipid head
      this.lipids.push({
        x: cx + (radius-8)*Math.cos(angle),
        y: cy + (radius-8)*Math.sin(angle),
        angle, layer:'inner', type:'head'
      });
    }
  }
  
  render(ctx) {
    // Draw phospholipid bilayer
    for (const l of this.lipids) {
      const headColor = l.layer==='outer' ? 'rgba(99,102,241,0.9)' : 'rgba(129,140,248,0.9)';
      const tailEnd = { x: l.x - Math.cos(l.angle)*12, y: l.y - Math.sin(l.angle)*12 };
      // Tail
      ctx.beginPath(); ctx.moveTo(l.x,l.y); ctx.lineTo(tailEnd.x,tailEnd.y);
      ctx.strokeStyle='rgba(148,163,184,0.4)'; ctx.lineWidth=2; ctx.stroke();
      // Head
      ctx.beginPath(); ctx.arc(l.x,l.y,5,0,Math.PI*2);
      ctx.fillStyle=headColor; ctx.fill();
    }
    
    // Draw cytoplasm (interior fluid)
    ctx.beginPath(); ctx.arc(this.cx,this.cy,this.radius-16,0,Math.PI*2);
    ctx.fillStyle='rgba(6,182,212,0.05)'; ctx.fill();
  }
}

// Diffusion simulation (Fick's law)
class DiffusionSimulation {
  constructor(particles) { this.particles = particles; }
  
  update(dt, temperature=1) {
    for (const p of this.particles) {
      // Brownian motion proportional to temperature
      p.vx += (Math.random()-0.5) * temperature * 0.5;
      p.vy += (Math.random()-0.5) * temperature * 0.5;
      p.vx *= 0.95; p.vy *= 0.95;
      p.x += p.vx*dt; p.y += p.vy*dt;
    }
  }
  
  // Measure concentration gradient (for Fick's law display)
  measureConcentration(x, y, radius) {
    return this.particles.filter(p => {
      const dx=p.x-x, dy=p.y-y;
      return dx*dx+dy*dy < radius*radius;
    }).length;
  }
}
```

---

## 3. Epidemiology (SIR Model) {#epidemiology}

```javascript
// Agent-based SIR simulation
const AgentState = { SUSCEPTIBLE: 0, INFECTED: 1, RECOVERED: 2, DECEASED: 3 };

class EpidemicSimulation {
  constructor(width, height, population) {
    this.W=width; this.H=height;
    this.agents = Array.from({length:population}, (_,i) => ({
      x: Math.random()*width, y: Math.random()*height,
      vx: (Math.random()-0.5)*2, vy: (Math.random()-0.5)*2,
      state: i < 3 ? AgentState.INFECTED : AgentState.SUSCEPTIBLE,
      infectionTime: i < 3 ? 0 : -1,
      age: Math.random(),
    }));
    
    // Disease parameters
    this.transmissionRate = 0.3;  // β
    this.recoveryTime = 300;       // frames
    this.mortalityRate = 0.02;
    this.immunityRadius = 20;
    
    this.stats = { S:population-3, I:3, R:0, D:0, day:0 };
  }
  
  update(frameCount) {
    this.stats.day = Math.floor(frameCount / 60);
    let S=0, I=0, R=0, D=0;
    
    for (const agent of this.agents) {
      // Movement
      agent.vx += (Math.random()-0.5)*0.3;
      agent.vy += (Math.random()-0.5)*0.3;
      agent.vx = Math.max(-3, Math.min(3, agent.vx));
      agent.vy = Math.max(-3, Math.min(3, agent.vy));
      agent.x = (agent.x+agent.vx+this.W)%this.W;
      agent.y = (agent.y+agent.vy+this.H)%this.H;
      
      // Infection spread
      if (agent.state === AgentState.INFECTED) {
        for (const other of this.agents) {
          if (other.state !== AgentState.SUSCEPTIBLE) continue;
          const dx=agent.x-other.x, dy=agent.y-other.y;
          if (dx*dx+dy*dy < this.immunityRadius*this.immunityRadius) {
            if (Math.random() < this.transmissionRate * 0.05) {
              other.state=AgentState.INFECTED; other.infectionTime=frameCount;
            }
          }
        }
        // Recovery or death
        if (frameCount - agent.infectionTime > this.recoveryTime) {
          agent.state = Math.random() < this.mortalityRate ? AgentState.DECEASED : AgentState.RECOVERED;
        }
      }
      
      if (agent.state===AgentState.SUSCEPTIBLE) S++;
      if (agent.state===AgentState.INFECTED) I++;
      if (agent.state===AgentState.RECOVERED) R++;
      if (agent.state===AgentState.DECEASED) D++;
    }
    this.stats = {...this.stats, S,I,R,D};
  }
  
  render(ctx) {
    const stateColors = {
      [AgentState.SUSCEPTIBLE]: 'rgba(100,180,255,0.9)',
      [AgentState.INFECTED]:    'rgba(255,80,80,0.9)',
      [AgentState.RECOVERED]:   'rgba(80,255,150,0.9)',
      [AgentState.DECEASED]:    'rgba(100,100,120,0.5)',
    };
    for (const agent of this.agents) {
      if (agent.state === AgentState.DECEASED) continue;
      ctx.beginPath();
      ctx.arc(agent.x, agent.y, 4, 0, Math.PI*2);
      ctx.fillStyle = stateColors[agent.state];
      ctx.fill();
    }
  }
  
  getRNumber() {
    // Basic reproduction number R₀ estimate
    return this.transmissionRate * this.recoveryTime / 60;
  }
}
```

---

## 4. Ecology — Predator-Prey (Lotka-Volterra) {#ecology}

```javascript
class EcosystemSimulation {
  constructor(width, height) {
    this.W=width; this.H=height;
    this.prey = [];    // Rabbits
    this.predators = []; // Foxes
    this.food = [];    // Grass patches
    
    // Spawn initial population
    for (let i=0; i<80; i++) this.spawnPrey();
    for (let i=0; i<10; i++) this.spawnPredator();
    for (let i=0; i<200; i++) this.spawnFood();
    
    this.time = 0;
    this.history = {prey:[], predators:[], time:[]};
  }
  
  spawnPrey(x=Math.random()*this.W, y=Math.random()*this.H) {
    this.prey.push({ x, y, vx:(Math.random()-0.5)*2, vy:(Math.random()-0.5)*2,
      energy:1.0, age:0, id:Math.random() });
  }
  spawnPredator(x=Math.random()*this.W, y=Math.random()*this.H) {
    this.predators.push({ x, y, vx:(Math.random()-0.5)*1.5, vy:(Math.random()-0.5)*1.5,
      energy:1.0, age:0, id:Math.random() });
  }
  spawnFood() {
    this.food.push({ x:Math.random()*this.W, y:Math.random()*this.H, energy:0.5 });
  }
  
  update(dt) {
    this.time++;
    const eatRadius=20, mateRadius=30;
    
    // Prey behavior: eat food, flee predators, reproduce
    for (const p of this.prey) {
      let fx=0,fy=0;
      // Find nearest food
      let nearestFood=null, minFoodDist=999999;
      for (const f of this.food) {
        const d=Math.hypot(f.x-p.x, f.y-p.y);
        if (d<minFoodDist){minFoodDist=d;nearestFood=f;}
      }
      if (nearestFood && minFoodDist < 80) {
        fx+=(nearestFood.x-p.x)/minFoodDist*0.5;
        fy+=(nearestFood.y-p.y)/minFoodDist*0.5;
      }
      // Flee predators
      for (const pred of this.predators) {
        const d=Math.hypot(pred.x-p.x,pred.y-p.y);
        if (d<100){fx-=(pred.x-p.x)/d*2;fy-=(pred.y-p.y)/d*2;}
      }
      p.vx=(p.vx+fx*0.1)*0.95; p.vy=(p.vy+fy*0.1)*0.95;
      p.x=(p.x+p.vx+this.W)%this.W; p.y=(p.y+p.vy+this.H)%this.H;
      p.energy-=0.001; p.age++;
    }
    
    // Predator behavior: hunt prey
    for (const pred of this.predators) {
      let fx=0,fy=0;
      let nearestPrey=null, minD=999999;
      for (const p of this.prey) {
        const d=Math.hypot(p.x-pred.x,p.y-pred.y);
        if(d<minD){minD=d;nearestPrey=p;}
      }
      if (nearestPrey){fx=(nearestPrey.x-pred.x)/minD;fy=(nearestPrey.y-pred.y)/minD;}
      pred.vx=(pred.vx+fx*0.15)*0.95; pred.vy=(pred.vy+fy*0.15)*0.95;
      pred.x=(pred.x+pred.vx+this.W)%this.W; pred.y=(pred.y+pred.vy+this.H)%this.H;
      pred.energy-=0.0015; pred.age++;
    }
    
    // Interactions: eating, dying, reproducing
    this.prey = this.prey.filter(p => {
      if (p.energy <= 0 || p.age > 2000) return false;
      for (const f of this.food) {
        if(Math.hypot(f.x-p.x,f.y-p.y) < eatRadius){p.energy+=f.energy; f.energy=0;}
      }
      if (p.energy>1.5 && this.prey.length<150) {this.spawnPrey(p.x,p.y); p.energy*=0.6;}
      return true;
    });
    this.food = this.food.filter(f=>f.energy>0);
    if (this.time%30===0) this.spawnFood();
    
    this.predators = this.predators.filter(pred => {
      if (pred.energy<=0||pred.age>3000) return false;
      for (const p of this.prey) {
        if(Math.hypot(p.x-pred.x,p.y-pred.y)<eatRadius){pred.energy+=0.5;p.energy=-1;}
      }
      if(pred.energy>2&&this.predators.length<30){this.spawnPredator(pred.x,pred.y);pred.energy*=0.5;}
      return true;
    });
    
    // Record for chart
    if (this.time%60===0) {
      this.history.prey.push(this.prey.length);
      this.history.predators.push(this.predators.length);
      this.history.time.push(Math.floor(this.time/60));
      if(this.history.prey.length>100){
        this.history.prey.shift(); this.history.predators.shift(); this.history.time.shift();
      }
    }
  }
}
```

---

## References

- **"Molecular Biology of the Cell"** — Alberts et al., 7th Edition
- **"Mathematical Biology"** — Murray, Springer
- **RCSB Protein Data Bank** — https://www.rcsb.org/ (3D molecular structures)
- **BioRender** — Scientific figure creation — https://biorender.com/
- **"Epidemiological Models and Their Analytical Solutions"** — Brauer & Castillo-Chavez
- **CDC SIR Model Reference** — https://www.cdc.gov/
- **PubChem** — Chemical compound database — https://pubchem.ncbi.nlm.nih.gov/
