import { getTenantData } from '../game/data.js';

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[c]));
function tenantArt(tenant) {
  const t = getTenantData(tenant);
  const art = {
    ghost: `<g><path d="M55 95 C55 62 76 43 100 43 C124 43 145 62 145 95 L145 133 L127 120 L112 134 L96 120 L80 134 L66 120 L55 130Z" fill="#c6d4cc"/><ellipse cx="86" cy="84" rx="6" ry="9" fill="#262523"/><ellipse cx="114" cy="84" rx="6" ry="9" fill="#262523"/><path d="M89 103 Q100 111 111 103" fill="none" stroke="#262523" stroke-width="4" stroke-linecap="round"/></g>`,
    vampire: `<g><path d="M62 137 L70 80 L83 93 L100 65 L117 93 L130 80 L138 137Z" fill="#7c3e49"/><circle cx="100" cy="89" r="37" fill="#d8c6b6"/><path d="M64 78 L72 49 L90 62 L108 44 L133 57 L137 80Z" fill="#392b31"/><ellipse cx="87" cy="88" rx="5" ry="7" fill="#262523"/><ellipse cx="113" cy="88" rx="5" ry="7" fill="#262523"/><path d="M91 105 L96 115 L101 106 L106 115 L111 105" fill="#fff0e3" stroke="#6d343e" stroke-width="2"/></g>`,
    worm: `<g><path d="M58 112 C57 76 83 65 100 91 C118 119 143 108 139 83" fill="none" stroke="#9bb47c" stroke-width="29" stroke-linecap="round"/><circle cx="136" cy="80" r="17" fill="#9bb47c"/><circle cx="131" cy="76" r="3" fill="#262523"/><circle cx="141" cy="76" r="3" fill="#262523"/><path d="M131 87 Q137 92 144 86" fill="none" stroke="#262523" stroke-width="2" stroke-linecap="round"/></g>`,
    chicken: `<g><ellipse cx="100" cy="102" rx="38" ry="36" fill="#e0c37c"/><circle cx="100" cy="68" r="25" fill="#e0c37c"/><path d="M84 48 Q78 30 91 36 Q100 23 108 37 Q124 27 120 49" fill="#a9554c"/><path d="M98 72 L119 80 L98 86Z" fill="#c97843"/><circle cx="91" cy="65" r="4" fill="#262523"/><circle cx="109" cy="65" r="4" fill="#262523"/><path d="M74 121 L61 135 L83 130 M125 121 L139 135 L117 130" fill="none" stroke="#c97843" stroke-width="5" stroke-linecap="round"/></g>`
  };
  return `<svg class="tenant-art" viewBox="0 0 200 160" role="img" aria-label="${esc(t.name)}">${art[tenant] || art.ghost}</svg>`;
}
function roomArt(tenant) {
  const accent = getTenantData(tenant).color;
  return `<div class="room-art"><div class="window"><i></i><i></i><i></i><i></i></div><div class="moon"></div><div class="pipe"></div><div class="shelf"></div><div class="plant"><b></b><b></b><b></b></div><div class="floor-line"></div><div class="room-label">UNIT ${String(tenant).toUpperCase()}</div><div class="tenant-wrap" style="--tenant:${accent}">${tenantArt(tenant)}</div><div class="door"></div></div>`;
}
function header(run, controller) {
  const cash = run?.cash ?? 100, chaos = run?.chaos ?? 0;
  return `<header class="hud"><div class="brand-mini">R/D <span>PROPERTY MANAGEMENT</span></div><button class="icon-btn" data-action="pause" aria-label="Pause game">Ⅱ</button><div class="stats"><div class="stat"><small>FLOOR</small><strong>${run?.floor ?? 1}</strong></div><div class="stat"><small>CASH</small><strong class="cash">¢${cash}</strong></div><div class="stat chaos-stat"><small>CHAOS</small><strong>${chaos}%</strong><div class="meter"><i style="width:${chaos}%"></i></div></div></div></header>`;
}
function home(state) {
  return `<main class="screen home-screen"><div class="topline"><span>EST. NEVER</span><span>BUILDING NO. 13</span></div><div class="hero-building"><div class="sign">NO VACANCIES<br><small>ALLEGEDLY</small></div>${[0,1,2,3].map((f)=>`<div class="building-floor floor-${f}"><span></span><span></span><span class="window-lit"></span></div>`).join('')}<div class="building-door"></div><div class="roof">✦</div></div><div class="title-lockup"><p class="eyebrow">A VERY NORMAL PROPERTY BUSINESS</p><h1>RENT<br><em>IS DUE.</em></h1><p class="tagline">THE TENANTS ARE WEIRD.<br>THE MORTGAGE ISN'T.</p></div><div class="home-records"><div><small>BEST FLOOR</small><strong>${state.records.bestFloor}</strong></div><div><small>BEST SCORE</small><strong>${state.records.bestScore}</strong></div><button class="sound-toggle" data-action="sound">SOUND ${state.sound ? 'ON' : 'OFF'}</button></div><button class="primary-btn" data-action="start">START NEW SHIFT <span>↗</span></button><p class="footer-note">UNLICENSED LANDLORDING SINCE FOREVER</p></main>`;
}
function game(state, controller) {
  const run = state.run, event = run?.activeEvent;
  if (!run || !event) return `<main class="screen"><p>Loading the next tenant…</p></main>`;
  const tenant = getTenantData(event.tenant);
  const timer = controller.remainingSeconds();
  return `<main class="screen game-screen">${header(run, controller)}<div class="floor-heading"><div><p class="eyebrow">CURRENT LIABILITY</p><h2>FLOOR <span>${String(run.floor).padStart(2,'0')}</span></h2></div><div class="floor-stamp">LEASE<br>ACTIVE</div></div><section class="apartment"><div class="apartment-top"><span>UNIT ${String(run.floor).padStart(2,'0')}B</span><span>${event.emergency ? '● EMERGENCY' : 'TENANT NOTICE'}</span></div>${roomArt(event.tenant)}<div class="tenant-card"><div class="tenant-avatar" style="--tenant:${tenant.color}">${tenantArt(event.tenant)}</div><div><p class="eyebrow">${tenant.name}</p><p class="tenant-tagline">${tenant.tagline}</p></div></div></section><section class="incident"><div class="incident-meta"><span class="notice-dot"></span><span>${event.emergency ? 'TIME-SENSITIVE INCIDENT' : 'COMPLAINT #'+String(run.floor).padStart(3,'0')}</span>${event.emergency ? `<strong class="countdown">${timer}s</strong>` : ''}</div><h3>${event.title}</h3><p>${event.description}</p>${event.emergency ? `<div class="timer-track"><i style="width:${Math.min(100, timer / (event.seconds || 8) * 100)}%"></i></div>` : ''}</section><section class="choices"><p class="eyebrow">WHAT'S THE PLAN, BOSS?</p><div class="choice-list">${event.choices.map((c,i)=>`<button class="choice-btn choice-${i}" data-action="choose" data-index="${i}"><span class="choice-number">0${i+1}</span><span class="choice-copy"><strong>${c.label}</strong><small>${c.cashDelta > 0 ? '+' : ''}${c.cashDelta} cash · ${c.chaosDelta > 0 ? '+' : ''}${c.chaosDelta} chaos</small></span><span class="choice-arrow">↗</span></button>`).join('')}</div></section><div class="feedback" aria-live="polite">${run.feedback || 'Every decision is legally binding. Probably.'}</div></main>`;
}
function pause(state) {
  return `<main class="screen overlay-screen"><div class="overlay-card"><p class="eyebrow">TEMPORARY COWARDICE</p><h2>SHIFT<br>PAUSED.</h2><p>The tenants are still being weird. They can wait.</p><button class="primary-btn" data-action="resume">BACK TO WORK ↗</button><button class="secondary-btn" data-action="restart">RESTART SHIFT</button><button class="text-btn" data-action="home">QUIT TO LOBBY</button></div></main>`;
}
function gameover(state) {
  const run = state.run;
  return `<main class="screen overlay-screen gameover-screen"><div class="broken-building">▥<span>×</span>▥</div><p class="eyebrow">NOTICE OF TERMINATION</p><h2>YOU'RE<br><em>EVICTED.</em></h2><p class="gameover-reason">${run?.reason || 'The building has elected a new landlord.'}</p><div class="results"><div><small>FLOORS SURVIVED</small><strong>${Math.max(0,(run?.floor || 1)-1)}</strong></div><div><small>RENT COLLECTED</small><strong>¢${run?.rentCollected || 0}</strong></div><div><small>FINAL SCORE</small><strong>${run?.score || 0}</strong></div></div><button class="primary-btn" data-action="restart">APPEAL THE EVICTION ↗</button><button class="secondary-btn" data-action="home">RETURN TO LOBBY</button><p class="footer-note">YOUR DEPOSIT WAS NEVER COMING BACK.</p></main>`;
}
export function renderApp(state, controller) {
  const root = document.getElementById('app');
  if (!root) return;
  const markup = state.screen === 'home' ? home(state) : state.screen === 'gameplay' ? game(state, controller) : state.screen === 'pause' ? pause(state) : gameover(state);
  root.innerHTML = markup;
}
