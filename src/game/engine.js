import { getEventFromPool } from './data.js';
import { applyChoice, applyTimeout, createInitialRun } from './rules.js';
import { clearRun, loadRecords, saveRecords, saveRun } from './storage.js';

export function createGameController(render) {
  const state = { screen: 'home', run: null, records: loadRecords(), sound: true, timer: null, deadline: null, pausedRemaining: null };
  function persist() { if (state.run) saveRun(state.run); }
  function stopTimer() { if (state.timer) clearInterval(state.timer); state.timer = null; state.deadline = null; }
  function updateRecords() {
    if (!state.run) return;
    state.records = { bestFloor: Math.max(state.records.bestFloor, state.run.floor), bestScore: Math.max(state.records.bestScore, state.run.score) };
    saveRecords(state.records);
  }
  function addEvent() {
    const event = getEventFromPool(state.run.floor, state.run.usedEventIds);
    state.run.activeEvent = event;
    state.run.resolved = false;
    if (event?.emergency) startTimer(event.seconds || 8);
    else stopTimer();
  }
  function startTimer(seconds) {
    stopTimer(); state.deadline = Date.now() + seconds * 1000;
    state.timer = setInterval(() => {
      if (state.screen !== 'gameplay' || !state.run?.activeEvent?.emergency) return;
      if (Date.now() >= state.deadline) {
        stopTimer(); state.run = applyTimeout(state.run); afterResolution();
      } else render(state);
    }, 120);
  }
  function afterResolution() {
    if (state.run.screen === 'gameover') { updateRecords(); clearRun(); state.screen = 'gameover'; }
    else addEvent();
    persist(); render(state);
  }
  function start() {
    stopTimer(); state.run = createInitialRun(); state.screen = 'gameplay'; addEvent(); persist(); render(state);
  }
  function choose(index) {
    if (state.screen !== 'gameplay' || !state.run?.activeEvent || state.run.resolved) return;
    stopTimer(); state.run = applyChoice(state.run, index); afterResolution();
  }
  function pause() { if (state.screen !== 'gameplay') return; if (state.timer) state.pausedRemaining = Math.max(0, state.deadline - Date.now()); stopTimer(); state.screen = 'pause'; render(state); }
  function resume() { if (state.screen !== 'pause') return; state.screen = 'gameplay'; if (state.run?.activeEvent?.emergency) startTimer(Math.max(1, (state.pausedRemaining || 1000) / 1000)); state.pausedRemaining = null; render(state); }
  function home() { stopTimer(); state.screen = 'home'; state.run = null; clearRun(); render(state); }
  function restart() { start(); }
  function toggleSound() { state.sound = !state.sound; render(state); }
  function remainingSeconds() { return state.deadline ? Math.max(0, Math.ceil((state.deadline - Date.now()) / 1000)) : 0; }
  return { state, start, choose, pause, resume, home, restart, toggleSound, remainingSeconds };
}
