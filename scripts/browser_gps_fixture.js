// Development browser test fixture ONLY. Never loaded by the application.
(() => {
  if (!['localhost', '127.0.0.1'].includes(location.hostname)) throw new Error('GPS fixture is restricted to localhost');
  const label = document.createElement('div');
  label.id = 'gps-test-banner';
  label.textContent = 'SIMULATED GPS TEST — NOT YOUR REAL LOCATION';
  label.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99999;background:#7f1d1d;color:white;text-align:center;font-weight:bold;padding:6px';
  document.body.append(label);
  const test = window.__gpsTest = { watches: new Map(), cleared: [], next: 0, mode: 'success', lat: 10.15, lng: 78.15, accuracy: 120, initial: null };
  const reading = () => ({ coords: { latitude:test.lat, longitude:test.lng, accuracy:test.accuracy, altitude:null, altitudeAccuracy:null, heading:null, speed:null }, timestamp:Date.now() });
  test.emit = (lat,lng) => { test.lat=lat; test.lng=lng; for (const callback of test.watches.values()) callback.success(reading()); };
  test.fail = code => { for (const callback of [...test.watches.values()]) callback.failure({code,message:'SIMULATED TEST ERROR'}); };
  Object.defineProperty(navigator, 'geolocation', { configurable:true, value:{
    getCurrentPosition(success,failure) { test.initial={success,failure}; queueMicrotask(() => test.mode === 'denied' ? failure({code:1,message:'SIMULATED DENIAL'}) : success(reading())); },
    watchPosition(success,failure) { const id=++test.next; test.watches.set(id,{success,failure}); queueMicrotask(() => test.mode === 'denied' ? failure({code:1,message:'SIMULATED DENIAL'}) : success(reading())); return id; },
    clearWatch(id) { test.cleared.push(id); test.watches.delete(id); }
  }});
  return 'SIMULATED localhost-only fixture ready';
})()
