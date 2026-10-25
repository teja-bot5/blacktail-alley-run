import './styles.css';
import { createGameController } from './game/engine.js';
import { renderApp } from './ui/render.js';

let controller;
function render(state) { renderApp(state, controller); }
controller = createGameController(render);
render(controller.state);

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  const action = button.dataset.action;
  if (action === 'start') controller.start();
  if (action === 'choose') controller.choose(Number(button.dataset.index));
  if (action === 'pause') controller.pause();
  if (action === 'resume') controller.resume();
  if (action === 'restart') controller.restart();
  if (action === 'home') controller.home();
  if (action === 'sound') controller.toggleSound();
});

document.addEventListener('visibilitychange', () => {
  if (document.hidden && controller.state.screen === 'gameplay') controller.pause();
});
