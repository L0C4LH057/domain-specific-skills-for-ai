# Educational Simulation Design Reference

## Table of Contents
1. [Pedagogical Framework](#pedagogy)
2. [Level-Adaptive Design](#levels)
3. [Interactive Explainer Patterns](#explainers)
4. [Subject-Specific Templates](#subjects)
5. [Assessment Through Simulation](#assessment)

---

## 1. Pedagogical Framework {#pedagogy}

### The SIMLEARN Method
Every educational simulation follows this structure:

```
S — SHOW     → Visual demonstration first. No text wall before the simulation.
I — INTRODUCE→ Brief label/annotation overlay. Core concept named, not explained.
M — MANIPULATE→ User MUST interact within 10 seconds. Drive behavior with prompts.
L — LABEL    → Key formula/law shown during interaction. Contextual, not front-loaded.
E — EXPLAIN  → Expandable "deep dive" panel. Optional for curious learners.
A — ASSESS   → Challenge mode. "Can you make X happen?" Goal-based exploration.
R — RECORD   → User can see what they discovered. Builds ownership of learning.
N — NARRATE  → Audio/visual playback of what happened. Memory consolidation.
```

### The Three Simulation Modes

**1. DEMO MODE** (teacher/AI presents):
- Simulation runs automatically
- Annotations appear step-by-step
- Narration explains what's happening
- No user control needed

**2. EXPLORE MODE** (learner-driven):
- User has full controls
- Click any particle for instant explanation
- Sandbox: change parameters freely
- "What if" questions answered live

**3. CHALLENGE MODE** (assessment):
- Given a goal: "Heat the gas to 500K" / "Make the reaction happen faster"
- User manipulates simulation to achieve it
- Success condition tracked in real-time
- Immediate feedback on approach

---

## 2. Level-Adaptive Design {#levels}

### Complexity Matrix by Age/Level

| Level | Labels | Math | Interactivity | Visual |
|-------|--------|------|---------------|--------|
| **K-6 (Children)** | Simple words, emojis | None | Click to spawn, drag things | Bright, big, cartoon-style |
| **Middle School (11-14)** | Concept names | Basic formulas | Sliders, presets | Clear, labeled, colorful |
| **High School (14-18)** | Scientific terms | Full equations | Parameter control | Scientific, detailed |
| **University** | Rigorous notation | Derivations visible | Full parameter space | Publication quality |
| **Professional** | Domain jargon | Raw values, logs | Custom inputs | Minimal, data-dense |
| **Self-learner (any age)** | Progressive labels | Show on demand | Start simple, unlock depth | Engaging, rewarding |

### Vocabulary Tier System
```javascript
const VOCAB_TIERS = {
  k6:     { atom: 'tiny building block', molecule:'stuff stuck together', electron:'tiny zapper' },
  middle: { atom: 'atom', molecule:'molecule', electron:'electron (negative charge)' },
  high:   { atom: 'atom', molecule:'molecule', electron:'electron (-1.6×10⁻¹⁹ C)' },
  uni:    { atom: 'atom', molecule:'molecule', electron:'electron (e⁻, -e)' },
};

function getLabel(term, level) {
  return VOCAB_TIERS[level]?.[term] || term;
}
```

### Complexity Reveal Pattern (Layered Learning)
```javascript
// Each concept has three layers — reveal progressively
const layers = {
  base:     { text:'Opposite charges attract', visible:true },
  formula:  { text:'F = k·q₁·q₂/r²', visible:level>='high' },
  detail:   { text:'k = 8.99×10⁹ N·m²/C²', visible:level==='uni' },
};

// "Why?" button reveals deeper layer
document.getElementById('btn-why').addEventListener('click', () => {
  currentLayer++;
  showLayer(layers[LAYER_NAMES[currentLayer]]);
});
```

---

## 3. Interactive Explainer Patterns {#explainers}

### Step-by-Step Animation Controller
```javascript
class StepByStepExplainer {
  constructor(steps) {
    this.steps = steps;  // [{title, action, annotation, formula, fact}]
    this.current = 0;
    this.auto = false;
    this.timer = null;
  }
  
  next() {
    if (this.current < this.steps.length-1) {
      this.current++;
      const step = this.steps[this.current];
      step.action();                    // Execute simulation action
      this.showAnnotation(step);        // Show label
      this.highlightFormula(step.formula);
    }
  }
  
  showAnnotation(step) {
    const el = document.getElementById('annotation');
    el.style.display='block';
    el.innerHTML = `
      <div class="step-number">Step ${this.current+1} / ${this.steps.length}</div>
      <div class="step-title">${step.title}</div>
      <div class="step-formula">${step.formula||''}</div>
      <div class="step-fact">💡 ${step.fact||''}</div>
    `;
  }
  
  startAutoPlay(intervalMs=3000) {
    this.timer = setInterval(() => {
      if (this.current >= this.steps.length-1) clearInterval(this.timer);
      else this.next();
    }, intervalMs);
  }
}
```

### Particle Click-to-Explain System
```javascript
// When user clicks a particle, show educational popup
canvas.addEventListener('click', (e) => {
  const clicked = findParticleAt(e.clientX, e.clientY);
  if (!clicked) return;
  
  const tooltip = document.getElementById('tooltip');
  tooltip.style.display = 'block';
  tooltip.style.left = (e.clientX + 15) + 'px';
  tooltip.style.top = (e.clientY - 10) + 'px';
  tooltip.innerHTML = buildParticleExplanation(clicked);
});

function buildParticleExplanation(particle) {
  const templates = {
    electron: (p) => `
      <strong>⚡ Electron</strong><br>
      Charge: -1.6×10⁻¹⁹ C<br>
      Speed: ${(Math.sqrt(p.vx*p.vx+p.vy*p.vy)*100).toFixed(0)} km/s<br>
      Orbital: ${p.orbital || 'n=1'}<br>
      <em>Electrons determine chemical bonding!</em>
    `,
    gas_molecule: (p) => `
      <strong>💨 Gas Molecule</strong><br>
      KE: ${(0.5*(p.vx*p.vx+p.vy*p.vy)).toFixed(3)} (sim units)<br>
      Speed: ${Math.sqrt(p.vx*p.vx+p.vy*p.vy).toFixed(2)} m/s<br>
      Type: ${p.moleculeType || 'N₂'}<br>
      <em>KE = ½mv² → Temperature!</em>
    `,
  };
  const template = templates[particle.type];
  return template ? template(particle) : `<strong>Particle</strong><br>x:${particle.x.toFixed(1)}, y:${particle.y.toFixed(1)}`;
}
```

### Formula Spotlight Animation
```javascript
// Highlight a formula with pulsing effect when it's relevant
class FormulaSpotlight {
  constructor(containerId) { this.container = document.getElementById(containerId); }
  
  show(formula, explanation, duration=4000) {
    const el = document.createElement('div');
    el.className = 'formula-spotlight';
    el.innerHTML = `
      <div class="formula-text">${formula}</div>
      <div class="formula-explain">${explanation}</div>
    `;
    this.container.appendChild(el);
    setTimeout(() => el.classList.add('visible'), 100);
    setTimeout(() => { el.classList.remove('visible'); setTimeout(()=>el.remove(), 500); }, duration);
  }
}

// CSS for formula spotlight (inject into style):
const FORMULA_CSS = `
.formula-spotlight {
  position:fixed; bottom:100px; right:20px;
  background:rgba(0,0,0,0.9); border:2px solid rgba(251,191,36,0.6);
  border-radius:12px; padding:16px 20px; color:#fef3c7;
  font-size:16px; max-width:280px; opacity:0; transform:translateY(10px);
  transition:all 0.4s ease; backdrop-filter:blur(10px);
  pointer-events:none; z-index:1000;
}
.formula-spotlight.visible { opacity:1; transform:translateY(0); }
.formula-text { font-size:22px; font-family:monospace; color:#fbbf24; margin-bottom:8px; }
.formula-explain { font-size:12px; color:#e2e8f0; }
`;
```

---

## 4. Subject-Specific Templates {#subjects}

### Mathematics — Geometry & Calculus

```javascript
// Visual calculus: show Riemann sums converging to integral
class CalculusSimulation {
  constructor(f, a, b) {
    this.f = f; this.a = a; this.b = b;
    this.n = 4; // Start with 4 rectangles
    this.method = 'left'; // left, right, midpoint, trapezoidal
  }
  
  renderRiemannSum(ctx, toCanvasX, toCanvasY) {
    const dx = (this.b - this.a) / this.n;
    let sum = 0;
    for (let i = 0; i < this.n; i++) {
      const x = this.a + i*dx;
      const xSample = this.method==='left' ? x :
                      this.method==='right' ? x+dx :
                      x+dx/2; // midpoint
      const y = this.f(xSample);
      sum += y * dx;
      
      // Draw rectangle
      ctx.beginPath();
      ctx.rect(toCanvasX(x), toCanvasY(Math.max(y,0)),
               toCanvasX(x+dx)-toCanvasX(x),
               toCanvasY(0)-toCanvasY(Math.max(y,0)));
      ctx.fillStyle=`rgba(99,102,241,0.3)`;
      ctx.fill();
      ctx.strokeStyle='rgba(129,140,248,0.8)';
      ctx.stroke();
    }
    return sum;
  }
  
  increaseN() { this.n = Math.min(this.n*2, 1024); }
}
```

### History — Timeline Visualization

```javascript
class HistoricalTimelineSimulation {
  constructor(events) {
    this.events = events.sort((a,b)=>a.year-b.year);
    this.particles = []; // Events as glowing particles
    this.connections = []; // Cause-effect relationships
  }
  
  buildParticles(W, H) {
    const yearMin = this.events[0].year;
    const yearMax = this.events[this.events.length-1].year;
    
    this.particles = this.events.map((ev, i) => ({
      id: ev.id,
      x: ((ev.year - yearMin)/(yearMax-yearMin)) * (W-100) + 50,
      y: H/2 + (Math.random()-0.5) * 200,
      vx: 0, vy: 0,
      event: ev,
      color: this.getCategoryColor(ev.category),
      radius: 8 + ev.significance*4,  // Bigger = more significant
    }));
  }
  
  getCategoryColor(category) {
    const colors = {
      war:        {r:239,g:68,b:68},
      discovery:  {r:99,g:102,b:241},
      political:  {r:234,g:179,b:8},
      economic:   {r:34,g:197,b:94},
      cultural:   {r:249,g:115,b:22},
    };
    return colors[category] || {r:148,g:163,b:184};
  }
}
```

---

## 5. Assessment Through Simulation {#assessment}

```javascript
class SimulationChallenge {
  constructor(goal, successFn, hints) {
    this.goal = goal;           // Text description
    this.successFn = successFn; // Function that returns true when achieved
    this.hints = hints;         // Array of hints to reveal progressively
    this.hintIndex = 0;
    this.attempts = 0;
    this.startTime = Date.now();
    this.achieved = false;
  }
  
  check(simulationState) {
    this.attempts++;
    if (this.successFn(simulationState)) {
      this.achieved = true;
      this.onSuccess();
      return true;
    }
    if (this.attempts % 30 === 0) this.revealHint(); // Hint every 30 checks
    return false;
  }
  
  revealHint() {
    if (this.hintIndex < this.hints.length) {
      showHintPopup(this.hints[this.hintIndex++]);
    }
  }
  
  onSuccess() {
    const timeMs = Date.now() - this.startTime;
    showSuccessAnimation({
      message: `🎉 Challenge Complete!`,
      goal: this.goal,
      time: `${(timeMs/1000).toFixed(1)}s`,
      efficiency: this.attempts < 100 ? 'Excellent' : this.attempts < 500 ? 'Good' : 'Keep practicing',
    });
  }
}

// Example challenges
const CHALLENGES = {
  gasLaw: {
    goal: "Double the pressure of the gas without adding more particles",
    successFn: (sim) => sim.pressure > sim.initialPressure * 1.9,
    hints: [
      "Try making the container smaller...",
      "Pressure = Force/Area. Reduce the area!",
      "Use the wall drag tool to compress the gas",
    ]
  },
  chemical: {
    goal: "Cause at least 10 hydrogen-oxygen reactions",
    successFn: (sim) => sim.reactionCount >= 10,
    hints: [
      "Get the molecules moving faster...",
      "Try raising the temperature",
      "Higher temperature = more kinetic energy = more reactions",
    ]
  }
};
```

---

## References

- **Bloom's Taxonomy** — Classification of educational objectives
- **Piaget's Cognitive Development Theory** — Stage-based learning adaptation
- **PhET Interactive Simulations** — University of Colorado — https://phet.colorado.edu/
- **Wolfram Demonstrations Project** — https://demonstrations.wolfram.com/
- **"How People Learn"** — National Academies of Sciences, Engineering, and Medicine, 2018
- **"The Art of Problem Solving"** — Rusczyk et al. (mathematics pedagogy)
- **Khan Academy** — https://www.khanacademy.org/ (reference for level-appropriate explanations)
- **"Mindstorms: Children, Computers, and Powerful Ideas"** — Seymour Papert, 1980
- **Scratch** — MIT Media Lab — https://scratch.mit.edu/ (reference for K-6 interactivity design)
