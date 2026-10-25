export const clamp = (n, min, max) => Math.min(Math.max(n, min), max);
export function createInitialRun() {
  return { floor: 1, cash: 100, chaos: 0, score: 0, rentCollected: 0, usedEventIds: [], activeEvent: null, feedback: 'The building is waiting for its next emergency.', screen: 'gameplay', reason: null, resolved: false };
}
export function gameOverReason(run) {
  if (run.cash <= 0) return 'The building ran out of cash. Your landlord licence has been revoked.';
  if (run.chaos >= 100) return 'The building reached maximum chaos and voted you out.';
  return null;
}
export function applyEffects(run, effects, eventId) {
  const next = { ...run, cash: clamp(run.cash + (Number(effects.cashDelta) || 0), 0, 999999), chaos: clamp(run.chaos + (Number(effects.chaosDelta) || 0), 0, 100), score: Math.max(0, run.score + (Number(effects.scoreDelta) || 0)), rentCollected: Math.max(0, run.rentCollected + (Number(effects.rentDelta) || 0)), usedEventIds: [...new Set([...run.usedEventIds, eventId])], activeEvent: null, feedback: effects.result || 'The situation has been legally handled.', resolved: true };
  const reason = gameOverReason(next);
  if (reason) return { ...next, screen: 'gameover', reason };
  return { ...next, floor: next.floor + 1, screen: 'gameplay', resolved: false };
}
export function applyChoice(run, index) {
  if (!run?.activeEvent || run.resolved) return run;
  const choice = run.activeEvent.choices[index];
  if (!choice) return run;
  return applyEffects(run, choice, run.activeEvent.id);
}
export function applyTimeout(run) {
  if (!run?.activeEvent?.emergency || run.resolved) return run;
  return applyEffects(run, run.activeEvent.timeout || { cashDelta: -10, chaosDelta: 15, result: 'Time ran out. The building made its own decision.' }, run.activeEvent.id);
}
