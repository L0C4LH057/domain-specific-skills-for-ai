# Physics Particle Simulations Reference

## Table of Contents
1. [Gravitational N-Body Systems](#gravity)
2. [Quantum Mechanics Visualization](#quantum)
3. [Fluid Dynamics (SPH)](#fluid)
4. [Gas Kinetics & Thermodynamics](#gas)
5. [Electromagnetism & Charged Particles](#em)
6. [Wave Mechanics](#waves)
7. [Nuclear Physics](#nuclear)
8. [Chaos & Nonlinear Systems](#chaos)

---

## 1. Gravitational N-Body Systems {#gravity}

Simulates gravitational attraction between massive bodies. Planets, stars, galaxies.

```javascript
// Gravitational force: F = G*m1*m2 / r²
const G = 6.674e-11; // Real value — scale for simulation

function applyGravity(bodies) {
  for (let i = 0; i < bodies.length; i++) {
    for (let j = i+1; j < bodies.length; j++) {
      const dx = bodies[j].x - bodies[i].x;
      const dy = bodies[j].y - bodies[i].y;
      const dz = (bodies[j].z || 0) - (bodies[i].z || 0);
      const r2 = dx*dx + dy*dy + dz*dz;
      const r = Math.sqrt(r2) + 1; // Softening to prevent singularity
      const force = G_SIM * bodies[i].mass * bodies[j].mass / (r*r);
      const fx = force * dx/r, fy = force * dy/r, fz = force * dz/r;
      
      bodies[i].ax += fx / bodies[i].mass;
      bodies[i].ay += fy / bodies[i].mass;
      bodies[j].ax -= fx / bodies[j].mass;
      bodies[j].ay -= fy / bodies[j].mass;
    }
  }
}

// Orbital velocity for circular orbit: v = sqrt(G*M/r)
function orbitalVelocity(centralMass, radius, G_SIM) {
  return Math.sqrt(G_SIM * centralMass / radius);
}

// Visual: draw gravitational field lines
function drawGravField(ctx, bodies, W, H, resolution = 30) {
  for (let x = 0; x < W; x += resolution) {
    for (let y = 0; y < H; y += resolution) {
      let fx=0, fy=0;
      for (const body of bodies) {
        const dx=body.x-x, dy=body.y-y;
        const r = Math.sqrt(dx*dx+dy*dy)+1;
        const f = body.mass/(r*r);
        fx += f*dx/r; fy += f*dy/r;
      }
      const mag = Math.sqrt(fx*fx+fy*fy);
      const len = Math.min(mag*resolution*5, resolution*0.8);
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + fx/mag*len, y + fy/mag*len);
      ctx.strokeStyle = `rgba(99,102,241,${Math.min(mag*20,0.5)})`;
      ctx.lineWidth = 0.5;
      ctx.stroke();
    }
  }
}
```

**Educational annotations**:
- Show escape velocity: `v_esc = sqrt(2GM/r)`
- Show Lagrange points (L1–L5) for binary systems
- Display orbital period: `T = 2π * sqrt(r³/GM)`

---

## 2. Quantum Mechanics Visualization {#quantum}

Visualize quantum probability densities, wave-particle duality, orbitals.

```javascript
// Hydrogen atom probability density |ψ|²
// Quantum numbers: n (principal), l (angular), m (magnetic)
function hydrogenProbability(r, theta, phi, n, l, m) {
  // Simplified 2D radial probability for visualization
  // P(r) = r² * |R_nl(r)|²
  const a0 = 1; // Bohr radius in simulation units
  
  // Radial wavefunctions (simplified for common orbitals)
  const orbitals = {
    '1s': r => 2 * Math.exp(-r/a0),
    '2s': r => (1/Math.sqrt(8)) * (2 - r/a0) * Math.exp(-r/(2*a0)),
    '2p': r => (1/Math.sqrt(24)) * (r/a0) * Math.exp(-r/(2*a0)),
    '3s': r => (2/81/Math.sqrt(3)) * (27 - 18*r/a0 + 2*(r/a0)**2) * Math.exp(-r/(3*a0)),
    '3p': r => (8/(27*Math.sqrt(6))) * (6 - r/a0) * (r/a0) * Math.exp(-r/(3*a0)),
    '3d': r => (4/(81*Math.sqrt(30))) * (r/a0)**2 * Math.exp(-r/(3*a0)),
  };
  
  return orbitals;
}

// Wave function collapse animation
function collapseWaveFunction(particles, measurement_point) {
  // Before measurement: particles exist as probability cloud
  // After measurement: particles collapse to definite position
  for (const p of particles) {
    const prob = calculateProbability(p, measurement_point);
    if (Math.random() < prob) {
      // Particle "found" here — collapse to definite position
      p.definite = true;
      p.x = measurement_point.x + (Math.random()-0.5)*5;
      p.y = measurement_point.y + (Math.random()-0.5)*5;
    }
  }
}

// Double-slit interference pattern
function doubleSlitIntensity(x, y, d, lambda, L) {
  // Path difference: d*sin(theta) where sin(theta) ≈ x/L
  const pathDiff = d * x / Math.sqrt(x*x + L*L);
  const phase = 2 * Math.PI * pathDiff / lambda;
  // Intensity: I = I₀ * cos²(δ/2)
  return Math.cos(phase/2) ** 2;
}

// Visual quantum field — probability cloud rendering
function renderQuantumCloud(ctx, orbital, cx, cy, scale, color) {
  const samples = 5000;
  for (let i = 0; i < samples; i++) {
    const r = Math.random() * scale * 6;
    const theta = Math.random() * Math.PI * 2;
    const prob = orbital(r) ** 2 * r; // Probability density * r for 3D effect
    if (Math.random() < prob * scale * 0.5) {
      const x = cx + r * Math.cos(theta);
      const y = cy + r * Math.sin(theta);
      ctx.beginPath();
      ctx.arc(x, y, 1.5, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${color}, ${prob * 2})`;
      ctx.fill();
    }
  }
}
```

---

## 3. Fluid Dynamics (SPH) {#fluid}

Smoothed Particle Hydrodynamics — simulates liquids with surface tension and pressure.

```javascript
// SPH kernel function (Poly6)
function kernel(r, h) {
  if (r > h) return 0;
  const x = 1 - (r*r)/(h*h);
  return (315 / (64 * Math.PI * Math.pow(h, 9))) * x*x*x;
}

// SPH pressure kernel (Spiky)
function pressureKernel(r, h) {
  if (r > h) return 0;
  return -(45 / (Math.PI * Math.pow(h, 6))) * (h-r)*(h-r);
}

// SPH viscosity kernel
function viscKernel(r, h) {
  if (r > h) return 0;
  return (45 / (Math.PI * Math.pow(h, 6))) * (h-r);
}

class SPHFluid {
  constructor(count) {
    this.n = count;
    this.pos = new Float32Array(count * 2);
    this.vel = new Float32Array(count * 2);
    this.force = new Float32Array(count * 2);
    this.density = new Float32Array(count);
    this.pressure = new Float32Array(count);
    this.h = 30;          // Smoothing radius
    this.mass = 1;
    this.restDensity = 300;
    this.gasConst = 2000;
    this.viscosity = 200;
    this.surfaceTension = 0.0728;
  }
  
  computeDensityPressure(spatialHash) {
    for (let i = 0; i < this.n; i++) {
      this.density[i] = 0;
      const neighbors = spatialHash.query(this.pos[i*2], this.pos[i*2+1], this.h);
      for (const j of neighbors) {
        const dx = this.pos[j*2] - this.pos[i*2];
        const dy = this.pos[j*2+1] - this.pos[i*2+1];
        const r = Math.sqrt(dx*dx + dy*dy);
        this.density[i] += this.mass * kernel(r, this.h);
      }
      // Equation of state: p = k*(ρ - ρ₀)
      this.pressure[i] = this.gasConst * (this.density[i] - this.restDensity);
    }
  }
  
  computeForces(spatialHash) {
    for (let i = 0; i < this.n; i++) {
      let fx = 0, fy = 0.05; // gravity
      const neighbors = spatialHash.query(this.pos[i*2], this.pos[i*2+1], this.h);
      
      for (const j of neighbors) {
        if (i === j) continue;
        const dx = this.pos[j*2] - this.pos[i*2];
        const dy = this.pos[j*2+1] - this.pos[i*2+1];
        const r = Math.sqrt(dx*dx + dy*dy) + 0.001;
        
        // Pressure force
        const pf = -this.mass * (this.pressure[i]+this.pressure[j]) / (2*this.density[j]) * pressureKernel(r, this.h);
        fx += pf * dx/r; fy += pf * dy/r;
        
        // Viscosity force
        const vf = this.viscosity * this.mass * viscKernel(r, this.h) / this.density[j];
        fx += vf * (this.vel[j*2]-this.vel[i*2]);
        fy += vf * (this.vel[j*2+1]-this.vel[i*2+1]);
      }
      this.force[i*2] = fx; this.force[i*2+1] = fy;
    }
  }
}
```

---

## 4. Gas Kinetics & Thermodynamics {#gas}

Maxwell-Boltzmann distribution, ideal gas law, heat transfer.

```javascript
// Maxwell-Boltzmann speed distribution
function maxwellBoltzmannSpeed(temperature, mass, k_B = 1.38e-23) {
  // Most probable speed: v_mp = sqrt(2kT/m)
  // Mean speed: v_mean = sqrt(8kT/πm)
  // RMS speed: v_rms = sqrt(3kT/m)
  const kT_over_m = k_B * temperature / mass;
  return {
    mostProbable: Math.sqrt(2 * kT_over_m),
    mean: Math.sqrt(8 * kT_over_m / Math.PI),
    rms: Math.sqrt(3 * kT_over_m)
  };
}

// Spawn gas particles with MB distribution
function spawnGasParticle(x, y, temperature, mass) {
  const speeds = maxwellBoltzmannSpeed(temperature, mass);
  // Sample from MB distribution using Box-Muller transform
  const u1 = Math.random(), u2 = Math.random();
  const z = Math.sqrt(-2*Math.log(u1)) * Math.cos(2*Math.PI*u2);
  const speed = Math.abs(z * speeds.rms * 0.5 + speeds.mean);
  const angle = Math.random() * Math.PI * 2;
  return { x, y, vx: Math.cos(angle)*speed, vy: Math.sin(angle)*speed, mass, temp: temperature };
}

// Elastic collision (conservation of momentum + kinetic energy)
function elasticCollision(p1, p2) {
  const dx = p2.x - p1.x, dy = p2.y - p1.y;
  const dist = Math.sqrt(dx*dx + dy*dy) || 1;
  const nx = dx/dist, ny = dy/dist;
  const dvx = p1.vx - p2.vx, dvy = p1.vy - p2.vy;
  const dotProduct = dvx*nx + dvy*ny;
  if (dotProduct > 0) return; // Already moving apart
  const impulse = 2 * dotProduct / (p1.mass + p2.mass);
  p1.vx -= impulse * p2.mass * nx;
  p1.vy -= impulse * p2.mass * ny;
  p2.vx += impulse * p1.mass * nx;
  p2.vy += impulse * p1.mass * ny;
}

// Measure temperature from particle velocities: KE = (3/2)kT
function measureTemperature(particles) {
  let totalKE = 0;
  for (const p of particles) {
    totalKE += 0.5 * p.mass * (p.vx*p.vx + p.vy*p.vy);
  }
  return (2/3) * totalKE / particles.length;
}

// Display PV = nRT check
function displayIdealGasLaw(particles, volume) {
  const n = particles.length;
  const T = measureTemperature(particles);
  const P = n * T / volume; // Simplified units
  return { n, T: T.toFixed(1), P: P.toFixed(2), pv_over_nRT: (P*volume/(n*T)).toFixed(3) };
}
```

**Educational labels**:
- `PV = nRT` — Ideal Gas Law
- `KE = ½mv²` — Kinetic Energy
- `T = (2/3) × <KE>/k_B` — Temperature definition
- Color particles by speed: cold=blue, hot=red/white

---

## 5. Electromagnetism & Charged Particles {#em}

```javascript
// Coulomb force: F = k*q1*q2/r²
const k_e = 8.99e9; // Coulomb's constant — scale for simulation

function coulombForce(p1, p2, k_SIM = 500) {
  const dx = p2.x - p1.x, dy = p2.y - p1.y;
  const r2 = dx*dx + dy*dy;
  const r = Math.sqrt(r2) + 1;
  const force = k_SIM * p1.charge * p2.charge / (r*r);
  // Positive force = repulsion, negative = attraction
  return { fx: -force*dx/r, fy: -force*dy/r };
}

// Magnetic Lorentz force: F = q(v × B)
function lorentzForce(particle, B_z) {
  // F = q * (v × B) — for 2D with B perpendicular to screen (z-axis)
  // fx = q*vy*B, fy = -q*vx*B
  return {
    fx: particle.charge * particle.vy * B_z,
    fy: -particle.charge * particle.vx * B_z
  };
}

// Draw electric field lines
function drawElectricField(ctx, charges, W, H) {
  // Sample field at grid points
  for (let x = 30; x < W; x += 40) {
    for (let y = 30; y < H; y += 40) {
      let ex=0, ey=0;
      for (const c of charges) {
        const dx=x-c.x, dy=y-c.y;
        const r2=dx*dx+dy*dy+1;
        const r=Math.sqrt(r2);
        const f=c.charge/r2;
        ex+=f*dx/r; ey+=f*dy/r;
      }
      const mag=Math.sqrt(ex*ex+ey*ey)||1;
      const len=15;
      ctx.beginPath();
      ctx.moveTo(x-ex/mag*len*0.5, y-ey/mag*len*0.5);
      ctx.lineTo(x+ex/mag*len*0.5, y+ey/mag*len*0.5);
      // Arrow head
      const angle=Math.atan2(ey,ex);
      ctx.lineTo(x+ex/mag*len*0.5-5*Math.cos(angle-0.3), y+ey/mag*len*0.5-5*Math.sin(angle-0.3));
      ctx.strokeStyle=`rgba(${ex>0?'251,146,60':'96,165,250'},0.5)`;
      ctx.lineWidth=0.8; ctx.stroke();
    }
  }
}
```

---

## 6. Chaos & Nonlinear Systems {#chaos}

Lorenz attractor, double pendulum, population dynamics.

```javascript
// Lorenz Attractor: dx/dt = σ(y-x), dy/dt = x(ρ-z)-y, dz/dt = xy-βz
function lorenzStep(x, y, z, dt, sigma=10, rho=28, beta=8/3) {
  const dx = sigma * (y - x);
  const dy = x * (rho - z) - y;
  const dz = x * y - beta * z;
  return { x: x+dx*dt, y: y+dy*dt, z: z+dz*dt };
}

// Double Pendulum (chaotic system)
function doublePendulumStep(state, m1=1, m2=1, l1=1, l2=1, g=9.8, dt=0.02) {
  const { theta1, theta2, omega1, omega2 } = state;
  const dTheta = theta2 - theta1;
  const sinDT = Math.sin(dTheta), cosDT = Math.cos(dTheta);
  
  // Equations of motion (Lagrangian mechanics)
  const denom1 = (2*m1+m2) - m2*Math.cos(2*dTheta);
  const alpha1 = (-g*(2*m1+m2)*Math.sin(theta1) - m2*g*Math.sin(theta1-2*theta2)
                  - 2*sinDT*m2*(omega2*omega2*l2+omega1*omega1*l1*cosDT)) / (l1*denom1);
  const alpha2 = (2*sinDT*(omega1*omega1*l1*(m1+m2)+g*(m1+m2)*Math.cos(theta1)
                  +omega2*omega2*l2*m2*cosDT)) / (l2*denom1);
  
  return {
    theta1: theta1 + omega1*dt, theta2: theta2 + omega2*dt,
    omega1: omega1 + alpha1*dt, omega2: omega2 + alpha2*dt
  };
}
```

---

## References

- **"Smoothed Particle Hydrodynamics"** — Monaghan, 1992
- **"The Feynman Lectures on Physics"** — Feynman, Leighton, Sands — https://feynmanlectures.caltech.edu/
- **"Computational Physics"** — Giordano & Nakanishi
- **PyBullet** — Python physics for robotics/AI — https://pybullet.org/
- **INSYDIUM NeXus** — GPU fluid simulation (professional) — https://insydium.ltd/products/nexus/
- **Khan Academy Physics** — https://www.khanacademy.org/science/physics
- **PhET Interactive Simulations** — University of Colorado — https://phet.colorado.edu/
