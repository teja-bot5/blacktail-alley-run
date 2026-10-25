import { describe, it, expect } from 'vitest';
import { applyChoice, applyTimeout, createInitialRun, gameOverReason } from '../src/game/rules.js';

const sampleEvent = { id: 'test-event', emergency: true, choices: [
  { label: 'Repair', cashDelta: -20, chaosDelta: -5, scoreDelta: 10, rentDelta: 8, result: 'Fixed.' },
  { label: 'Ignore', cashDelta: 0, chaosDelta: 20, scoreDelta: 0, rentDelta: 0, result: 'Ignored.' }
], timeout: { cashDelta: -15, chaosDelta: 20, scoreDelta: -2, rentDelta: 0, result: 'Timed out.' } };
function runWith(event = sampleEvent) { return { ...createInitialRun(), activeEvent: structuredClone(event) }; }

describe('RENT IS DUE rules', () => {
  it('applies a choice and advances the floor', () => {
    const next = applyChoice(runWith(), 0);
    expect(next.cash).toBe(80); expect(next.chaos).toBe(0); expect(next.floor).toBe(2); expect(next.score).toBe(10); expect(next.rentCollected).toBe(8);
  });
  it('clamps chaos at 100 and triggers game over', () => {
    const run = { ...runWith(), chaos: 90 };
    const next = applyChoice(run, 1);
    expect(next.chaos).toBe(100); expect(next.screen).toBe('gameover'); expect(gameOverReason(next)).toMatch(/chaos/i);
  });
  it('ends the run when cash reaches zero', () => {
    const run = { ...runWith(), cash: 10, activeEvent: { ...sampleEvent, choices: [{ cashDelta: -20, chaosDelta: 0 }] } };
    const next = applyChoice(run, 0);
    expect(next.cash).toBe(0); expect(next.screen).toBe('gameover');
  });
  it('applies the emergency timeout effect', () => {
    const next = applyTimeout(runWith());
    expect(next.cash).toBe(85); expect(next.chaos).toBe(20); expect(next.floor).toBe(2);
  });
  it('does not apply a choice twice after the active event is cleared', () => {
    const once = applyChoice(runWith(), 0);
    const twice = applyChoice(once, 0);
    expect(twice).toEqual(once);
  });
  it('ignores invalid choice indexes', () => {
    const run = runWith();
    expect(applyChoice(run, 99)).toEqual(run);
  });
});
