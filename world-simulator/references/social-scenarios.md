# Social Scenarios & Investigation Simulation Reference

## Table of Contents
1. [Criminal Investigation Scene Simulation](#crime)
2. [Legal Argument / Court Simulation](#legal)
3. [Social Network Dynamics](#social)
4. [Economic Market Simulations](#economic)
5. [Traffic & Urban Flow](#traffic)
6. [Disaster & Emergency Response](#disaster)

---

## 1. Criminal Investigation Scene Simulation {#crime}

Agent-based simulation of crime scene reconstruction, timeline visualization, evidence flow.

```javascript
class CrimeSceneSimulation {
  constructor(canvas, scenario) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.W = canvas.width;
    this.H = canvas.height;
    this.scenario = scenario;
    
    // Scene elements
    this.agents = [];      // People (suspects, victim, witnesses)
    this.evidence = [];    // Evidence markers
    this.timeline = [];    // Event sequence
    this.currentTime = 0;  // Simulation time (minutes)
    this.playbackTime = 0; // Current playback position
    
    this.buildScene(scenario);
  }
  
  buildScene(scenario) {
    // Locations
    this.locations = scenario.locations.map(loc => ({
      name: loc.name,
      x: loc.x * this.W,
      y: loc.y * this.H,
      radius: loc.radius || 40,
      color: loc.color || 'rgba(99,102,241,0.2)',
    }));
    
    // Agents from scenario data
    for (const person of scenario.people) {
      this.agents.push({
        id: person.id,
        name: person.name,
        role: person.role, // 'suspect', 'victim', 'witness', 'officer'
        x: person.startX * this.W,
        y: person.startY * this.H,
        path: person.path || [],  // [{time, x, y}] waypoints
        pathIndex: 0,
        color: this.getRoleColor(person.role),
        evidence: person.evidence || [],
        alibi: person.alibi || '',
        motive: person.motive || '',
        highlighted: false,
      });
    }
    
    // Evidence items
    for (const ev of scenario.evidence) {
      this.evidence.push({
        id: ev.id,
        type: ev.type,         // 'fingerprint', 'dna', 'weapon', 'document', 'witness_account'
        x: ev.x * this.W,
        y: ev.y * this.H,
        discovered: false,
        discoveryTime: ev.discoveryTime || 0,
        linksTo: ev.linksTo || [],  // Array of suspect IDs
        weight: ev.weight || 0.5,   // Evidence weight 0-1
        description: ev.description,
        collected: false,
      });
    }
  }
  
  getRoleColor(role) {
    const colors = {
      suspect:  { fill:'rgba(239,68,68,0.9)',   ring:'#ef4444' },
      victim:   { fill:'rgba(249,115,22,0.9)',  ring:'#f97316' },
      witness:  { fill:'rgba(234,179,8,0.9)',   ring:'#eab308' },
      officer:  { fill:'rgba(34,197,94,0.9)',   ring:'#22c55e' },
      unknown:  { fill:'rgba(148,163,184,0.9)', ring:'#94a3b8' },
    };
    return colors[role] || colors.unknown;
  }
  
  update(dt) {
    this.playbackTime += dt;
    
    // Move agents along their paths
    for (const agent of this.agents) {
      if (!agent.path.length) continue;
      const nextWaypoint = agent.path[agent.pathIndex];
      if (!nextWaypoint) continue;
      
      if (this.playbackTime >= nextWaypoint.time) {
        const target = { x: nextWaypoint.x * this.W, y: nextWaypoint.y * this.H };
        const dx=target.x-agent.x, dy=target.y-agent.y;
        const dist=Math.sqrt(dx*dx+dy*dy);
        if (dist < 5) {
          agent.pathIndex = Math.min(agent.pathIndex+1, agent.path.length-1);
        } else {
          const speed = 80; // pixels per second
          agent.x += (dx/dist)*speed*dt;
          agent.y += (dy/dist)*speed*dt;
        }
      }
    }
    
    // Reveal evidence at discovery times
    for (const ev of this.evidence) {
      if (!ev.discovered && this.playbackTime >= ev.discoveryTime) {
        ev.discovered = true;
      }
    }
  }
  
  render() {
    const ctx = this.ctx;
    
    // Clear
    ctx.fillStyle='rgba(15,23,42,0.95)';
    ctx.fillRect(0,0,this.W,this.H);
    
    // Draw floor plan / locations
    for (const loc of this.locations) {
      ctx.beginPath();
      ctx.arc(loc.x,loc.y,loc.radius,0,Math.PI*2);
      ctx.fillStyle=loc.color;
      ctx.fill();
      ctx.strokeStyle='rgba(99,102,241,0.5)';
      ctx.lineWidth=1.5; ctx.stroke();
      ctx.fillStyle='rgba(199,210,254,0.7)';
      ctx.font='11px sans-serif'; ctx.textAlign='center';
      ctx.fillText(loc.name, loc.x, loc.y+loc.radius+14);
    }
    
    // Draw agent paths (ghost trails)
    for (const agent of this.agents) {
      if (agent.path.length < 2) continue;
      ctx.beginPath();
      const start = agent.path[0];
      ctx.moveTo(start.x*this.W, start.y*this.H);
      for (let i=1; i<Math.min(agent.pathIndex+1, agent.path.length); i++) {
        ctx.lineTo(agent.path[i].x*this.W, agent.path[i].y*this.H);
      }
      ctx.strokeStyle=`${agent.color.ring}40`; ctx.lineWidth=1.5;
      ctx.setLineDash([4,4]); ctx.stroke(); ctx.setLineDash([]);
    }
    
    // Draw evidence connections (links to suspects)
    for (const ev of this.evidence) {
      if (!ev.discovered) continue;
      for (const suspectId of ev.linksTo) {
        const suspect = this.agents.find(a=>a.id===suspectId);
        if (!suspect) continue;
        ctx.beginPath();
        ctx.moveTo(ev.x, ev.y); ctx.lineTo(suspect.x, suspect.y);
        ctx.strokeStyle=`rgba(251,191,36,${ev.weight*0.6})`;
        ctx.lineWidth=ev.weight*3; ctx.setLineDash([8,4]); ctx.stroke();
        ctx.setLineDash([]);
      }
    }
    
    // Draw evidence markers
    for (const ev of this.evidence) {
      if (!ev.discovered) continue;
      const evIcons = { fingerprint:'🖐', dna:'🧬', weapon:'🔪', document:'📄',
                        witness_account:'👁', phone:'📱', camera:'📷', default:'🔍' };
      ctx.font='18px serif';
      ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(evIcons[ev.type]||evIcons.default, ev.x, ev.y);
      // Pulsing ring for newly discovered
      const pulse = (Math.sin(Date.now()*0.005)+1)*0.5;
      ctx.beginPath(); ctx.arc(ev.x,ev.y,15+pulse*5,0,Math.PI*2);
      ctx.strokeStyle=`rgba(251,191,36,${0.5-pulse*0.3})`; ctx.lineWidth=2; ctx.stroke();
    }
    
    // Draw agents
    for (const agent of this.agents) {
      // Shadow
      ctx.beginPath(); ctx.arc(agent.x+2,agent.y+2,14,0,Math.PI*2);
      ctx.fillStyle='rgba(0,0,0,0.4)'; ctx.fill();
      
      // Body
      ctx.beginPath(); ctx.arc(agent.x,agent.y,14,0,Math.PI*2);
      ctx.fillStyle=agent.color.fill; ctx.fill();
      ctx.strokeStyle=agent.highlighted?'#fbbf24':agent.color.ring;
      ctx.lineWidth=agent.highlighted?3:2; ctx.stroke();
      
      // Role icon
      const roleIcons={suspect:'S',victim:'V',witness:'W',officer:'O'};
      ctx.fillStyle='white'; ctx.font='bold 11px sans-serif';
      ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(roleIcons[agent.role]||'?', agent.x, agent.y);
      
      // Name label
      ctx.fillStyle='rgba(226,232,240,0.9)'; ctx.font='10px sans-serif';
      ctx.fillText(agent.name, agent.x, agent.y+22);
    }
  }
  
  // Calculate probability of guilt based on evidence
  calculateEvidenceScore(suspectId) {
    let totalWeight = 0, score = 0;
    for (const ev of this.evidence) {
      if (!ev.discovered) continue;
      totalWeight += ev.weight;
      if (ev.linksTo.includes(suspectId)) score += ev.weight;
    }
    return totalWeight > 0 ? score/totalWeight : 0;
  }
}
```

---

## 2. Legal Argument Visualization {#legal}

```javascript
class LegalArgumentSimulation {
  constructor() {
    this.arguments = [];  // [{text, side:'prosecution'|'defense', weight, respondedTo}]
    this.evidence = [];   // [{description, type:'physical'|'testimonial'|'documentary', weight, admitted}]
    this.verdict = null;
    this.balance = 0.5;   // 0=defense wins, 1=prosecution wins
  }
  
  addArgument(text, side, weight=0.5) {
    this.arguments.push({text, side, weight, id:this.arguments.length, x:0, y:0, vx:0, vy:0});
    this.recalculateBalance();
  }
  
  addEvidence(desc, type, weight, admitted=true, side='prosecution') {
    this.evidence.push({desc, type, weight, admitted, side});
    if (admitted) this.recalculateBalance();
  }
  
  recalculateBalance() {
    let proWeight=0, defWeight=0;
    for (const a of this.arguments) {
      if (a.side==='prosecution') proWeight+=a.weight;
      else defWeight+=a.weight;
    }
    for (const e of this.evidence) {
      if (!e.admitted) continue;
      if (e.side==='prosecution') proWeight+=e.weight*1.5;
      else defWeight+=e.weight*1.5;
    }
    const total=proWeight+defWeight||1;
    this.balance=proWeight/total;
  }
  
  // Visual: scales of justice particle representation
  renderScales(ctx, cx, cy) {
    // Draw scales
    const leftX=cx-120, rightX=cx+120;
    const proY=cy+100*(this.balance-0.5)*2;      // Prosecution pan
    const defY=cy-100*(this.balance-0.5)*2;      // Defense pan
    
    // Beam
    ctx.beginPath(); ctx.moveTo(leftX,proY); ctx.lineTo(rightX,defY);
    ctx.strokeStyle='rgba(251,191,36,0.8)'; ctx.lineWidth=3; ctx.stroke();
    
    // Pans
    for (const [x,y,label] of [[leftX,proY,'Prosecution'],[rightX,defY,'Defense']]) {
      ctx.beginPath(); ctx.arc(x,y,50,0,Math.PI*2);
      ctx.strokeStyle='rgba(251,191,36,0.5)'; ctx.lineWidth=2; ctx.stroke();
      ctx.fillStyle='rgba(251,191,36,0.1)'; ctx.fill();
      ctx.fillStyle='rgba(226,232,240,0.8)'; ctx.font='12px sans-serif';
      ctx.textAlign='center'; ctx.fillText(label,x,y+65);
    }
    
    // Fulcrum
    ctx.beginPath(); ctx.moveTo(cx-10,cy-100); ctx.lineTo(cx+10,cy-100); ctx.lineTo(cx,cy);
    ctx.closePath(); ctx.fillStyle='rgba(251,191,36,0.6)'; ctx.fill();
    
    // "Beyond reasonable doubt" threshold line
    ctx.beginPath(); ctx.setLineDash([8,4]);
    ctx.moveTo(cx-5,cy-80); ctx.lineTo(cx-130,cy+90);
    ctx.strokeStyle='rgba(239,68,68,0.5)'; ctx.lineWidth=1.5; ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle='rgba(239,68,68,0.6)'; ctx.font='9px sans-serif';
    ctx.textAlign='left'; ctx.fillText('Beyond reasonable doubt',cx-125,cy+105);
  }
}
```

---

## 3. Social Network Dynamics {#social}

```javascript
class SocialNetworkSimulation {
  constructor(nodes, edges) {
    this.nodes = nodes.map(n => ({
      ...n, x: Math.random()*800, y: Math.random()*600,
      vx:0, vy:0, influence:0
    }));
    this.edges = edges;
    this.infectionSource = null;  // For information/misinformation spread
  }
  
  // Force-directed layout (Fruchterman-Reingold)
  updateLayout(dt) {
    const k = Math.sqrt((800*600)/this.nodes.length);
    
    // Repulsion between all nodes
    for (let i=0; i<this.nodes.length; i++) {
      for (let j=i+1; j<this.nodes.length; j++) {
        const a=this.nodes[i], b=this.nodes[j];
        const dx=b.x-a.x, dy=b.y-a.y;
        const dist=Math.sqrt(dx*dx+dy*dy)||1;
        const repulse = k*k/dist * 0.1;
        a.vx-=repulse*dx/dist; a.vy-=repulse*dy/dist;
        b.vx+=repulse*dx/dist; b.vy+=repulse*dy/dist;
      }
    }
    
    // Attraction along edges
    for (const edge of this.edges) {
      const a=this.nodes[edge.source], b=this.nodes[edge.target];
      if (!a||!b) continue;
      const dx=b.x-a.x, dy=b.y-a.y;
      const dist=Math.sqrt(dx*dx+dy*dy)||1;
      const attract=(dist*dist/k)*0.05;
      a.vx+=attract*dx/dist; a.vy+=attract*dy/dist;
      b.vx-=attract*dx/dist; b.vy-=attract*dy/dist;
    }
    
    // Integrate
    for (const node of this.nodes) {
      node.x+=node.vx*dt*50; node.y+=node.vy*dt*50;
      node.vx*=0.7; node.vy*=0.7;
      node.x=Math.max(30,Math.min(770,node.x));
      node.y=Math.max(30,Math.min(570,node.y));
    }
  }
  
  // Spread information/belief through network
  spreadInfluence(sourceId, spreadRate=0.1) {
    const source = this.nodes.find(n=>n.id===sourceId);
    if (!source) return;
    source.influence = 1.0;
    
    for (const edge of this.edges) {
      const fromNode = edge.source===sourceId ? this.nodes.find(n=>n.id===edge.target) :
                       edge.target===sourceId ? this.nodes.find(n=>n.id===edge.source) : null;
      if (fromNode && fromNode.influence < 1.0) {
        fromNode.influence += spreadRate * (edge.weight||0.5);
        fromNode.influence = Math.min(1, fromNode.influence);
      }
    }
  }
}
```

---

## References

- **"Visualizing Criminal Justice Data"** — Bureau of Justice Statistics
- **"Agent-Based Models of Geographical Systems"** — Heppenstall et al.
- **"The Logic of Scientific Discovery"** — Karl Popper (evidence theory)
- **Gephi** — Open-source network visualization — https://gephi.org/
- **"Network Science"** — Barabási — http://networksciencebook.com/
- **"Crowd Simulation"** — Helbing & Molnár, 1995 (Social Force Model)
- **NASA WorldWind** — Geospatial simulation platform
