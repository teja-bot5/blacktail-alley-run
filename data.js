export const TENANTS = {
  ghost: { id: 'ghost', name: 'THE GHOST', tagline: 'A tenant with unfinished business', color: '#b7c7c0', icon: '◌' },
  vampire: { id: 'vampire', name: 'THE VAMPIRE', tagline: 'Sunlight is a lease violation', color: '#b95f67', icon: '♜' },
  worm: { id: 'worm', name: 'THE WORM', tagline: 'Has very specific requirements', color: '#a6b87a', icon: '〰' },
  chicken: { id: 'chicken', name: 'THE CHICKEN', tagline: 'Pays in assets, not currency', color: '#d9b56f', icon: '♟' }
};

export const EVENT_POOL = [
  { id: 'ghost-pipes', tenant: 'ghost', title: 'THE PIPES ARE SINGING', description: 'The radiators hum in a chorus. The walls are sweating cold water.', minFloor: 1, choices: [
    { label: 'Patch the pipes', cashDelta: -20, chaosDelta: -10, scoreDelta: 30, rentDelta: 15, result: 'The pipes stop singing. The building requests an encore.' },
    { label: 'Ignore the choir', cashDelta: 0, chaosDelta: 18, scoreDelta: 0, rentDelta: 0, result: 'The apartment floods with cold, accusatory silence.' },
    { label: 'Charge a séance fee', cashDelta: 12, chaosDelta: 8, scoreDelta: 10, rentDelta: 12, result: 'The ghost pays. The pipes begin humming in Latin.' }
  ]},
  { id: 'vampire-dawn', tenant: 'vampire', title: 'SUNLIGHT EMERGENCY', description: 'Dawn is approaching. Your tenant calls this a hostile work environment.', minFloor: 1, emergency: true, seconds: 8, timeout: { cashDelta: -12, chaosDelta: 15, scoreDelta: -5, rentDelta: 0, result: 'The curtains lose the battle. So does your deposit.' }, choices: [
    { label: 'Install blackout curtains', cashDelta: -18, chaosDelta: -10, scoreDelta: 25, rentDelta: 15, result: 'The vampire approves the darkness. Dramatically.' },
    { label: 'Offer a decorative coffin', cashDelta: -10, chaosDelta: -4, scoreDelta: 15, rentDelta: 10, result: 'A coffin is installed. It has excellent natural light.' },
    { label: 'Tell them it is morning', cashDelta: 0, chaosDelta: 18, scoreDelta: 0, rentDelta: 0, result: 'The tenant hisses. Your building insurance hisses back.' }
  ]},
  { id: 'worm-moat', tenant: 'worm', title: 'A MOAT. INDOORS.', description: 'The worm requests a moat under the bed to improve morale and humidity.', minFloor: 1, choices: [
    { label: 'Install the moat', cashDelta: -14, chaosDelta: -6, scoreDelta: 22, rentDelta: 12, result: 'The moat is a hit with the local worm community.' },
    { label: 'Explain basic architecture', cashDelta: 0, chaosDelta: 15, scoreDelta: 0, rentDelta: 0, result: 'The worm files a complaint with the concept of architecture.' },
    { label: 'Paint a moat', cashDelta: -5, chaosDelta: 2, scoreDelta: 12, rentDelta: 8, result: 'The moat is two-dimensional. The worm calls it minimalist.' }
  ]},
  { id: 'chicken-eggs', tenant: 'chicken', title: 'RENT IN EGGS', description: 'The chicken has delivered rent. It is warm, fragile, and faintly judgmental.', minFloor: 1, choices: [
    { label: 'Accept the eggs', cashDelta: 14, chaosDelta: -2, scoreDelta: 20, rentDelta: 14, result: 'The eggs are accepted as legal tender in one very small jurisdiction.' },
    { label: 'Demand actual money', cashDelta: 0, chaosDelta: 12, scoreDelta: 0, rentDelta: 0, result: 'The chicken contacts its lawyer. The lawyer is also a chicken.' },
    { label: 'Sell them as antiques', cashDelta: 20, chaosDelta: 8, scoreDelta: 24, rentDelta: 20, result: 'A collector buys them. Nobody asks why.' }
  ]},
  { id: 'ghost-cold', tenant: 'ghost', title: 'THE ROOM IS TOO ALIVE', description: 'The bedroom is below freezing. Your coffee is hovering and developing opinions.', minFloor: 2, choices: [
    { label: 'Install insulation', cashDelta: -22, chaosDelta: -8, scoreDelta: 24, rentDelta: 14, result: 'The room warms up. The coffee returns to its cup.' },
    { label: 'Leave it haunted', cashDelta: 0, chaosDelta: 17, scoreDelta: 0, rentDelta: 0, result: 'The room becomes an ice cave with excellent ambience.' },
    { label: 'Sell the cold as a feature', cashDelta: 10, chaosDelta: 10, scoreDelta: 12, rentDelta: 10, result: 'It is now a premium cryotherapy studio. Nobody signed a waiver.' }
  ]},
  { id: 'worm-floor', tenant: 'worm', title: 'THE FLOOR WON’T STOP SQUEAKING', description: 'A thousand tiny squeaks are coming from under the carpet. None are in rhythm.', minFloor: 3, emergency: true, seconds: 7, timeout: { cashDelta: -10, chaosDelta: 14, scoreDelta: -4, rentDelta: 0, result: 'The floor forms a union and negotiates directly with the ceiling.' }, choices: [
    { label: 'Lift the flooring', cashDelta: -20, chaosDelta: -8, scoreDelta: 26, rentDelta: 12, result: 'A worm colony is discovered. It has retained legal counsel.' },
    { label: 'Install a drum kit', cashDelta: -12, chaosDelta: -3, scoreDelta: 18, rentDelta: 10, result: 'The squeaks improve into a restless rhythm section.' },
    { label: 'Call it modern music', cashDelta: 0, chaosDelta: 13, scoreDelta: 5, rentDelta: 0, result: 'The rent stays the same. The noise now has a name.' }
  ]},
  { id: 'chicken-feathers', tenant: 'chicken', title: 'FEATHER WEATHER', description: 'A feather storm has taken over the hallway. Visibility is now mostly decorative.', minFloor: 2, choices: [
    { label: 'Vacuum the hall', cashDelta: -12, chaosDelta: -8, scoreDelta: 20, rentDelta: 12, result: 'The hallway becomes almost respectable.' },
    { label: 'Let nature decide', cashDelta: 0, chaosDelta: 17, scoreDelta: 0, rentDelta: 0, result: 'The feathers establish a tiny independent government.' },
    { label: 'Charge for nesting', cashDelta: 12, chaosDelta: 7, scoreDelta: 15, rentDelta: 12, result: 'The hallway is now a boutique nesting experience.' }
  ]}
];

export function getTenantData(id) { return TENANTS[id] || TENANTS.ghost; }
export function getEventFromPool(floor, usedEventIds = [], random = Math.random) {
  let available = EVENT_POOL.filter(e => e.minFloor <= floor && !usedEventIds.includes(e.id));
  if (!available.length) available = EVENT_POOL.filter(e => e.minFloor <= floor);
  const event = available[Math.floor(random() * available.length)];
  return event ? structuredClone(event) : null;
}
