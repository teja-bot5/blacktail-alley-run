const RECORDS_KEY = 'rent-is-due-records-v1';
const RUN_KEY = 'rent-is-due-run-v1';
export function loadRecords() {
  try { const x = JSON.parse(localStorage.getItem(RECORDS_KEY) || '{}'); return { bestFloor: Number(x.bestFloor) || 0, bestScore: Number(x.bestScore) || 0 }; }
  catch { return { bestFloor: 0, bestScore: 0 }; }
}
export function saveRecords(records) { try { localStorage.setItem(RECORDS_KEY, JSON.stringify(records)); } catch {} }
export function saveRun(run) { try { localStorage.setItem(RUN_KEY, JSON.stringify(run)); } catch {} }
export function clearRun() { try { localStorage.removeItem(RUN_KEY); } catch {} }
