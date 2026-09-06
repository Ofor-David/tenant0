// Exec plan §8.5 - load test against design §5.3's SLO:
// cache-hit p99 < 150ms, cache-miss p99 < 500ms, 50 req/s/tenant sustained.
// Run: k6 run -e GATEWAY_IP=<ip> -e API_KEY=<key> -e TENANT=<tenant> serving/k6/load-test.js
import http from 'k6/http';
import { check } from 'k6';

const GATEWAY_IP = __ENV.GATEWAY_IP;
const API_KEY = __ENV.API_KEY;
const TENANT = __ENV.TENANT;
const URL = `http://${GATEWAY_IP}/t/${TENANT}/embed`;
const CACHE_HIT_TEXT = 'k6-cache-hit-fixed-text';

const params = {
  headers: {
    'X-API-Key': API_KEY,
    'Content-Type': 'application/json',
  },
};

export const options = {
  scenarios: {
    cache_hit: {
      executor: 'constant-arrival-rate',
      rate: 50,
      timeUnit: '1s',
      duration: '30s',
      preAllocatedVUs: 20,
      maxVUs: 100,
      exec: 'cacheHit',
    },
    // Offset start so the two scenarios don't compete for the same TEI/DB
    // capacity at once - each is measured against its own SLO independently.
    cache_miss: {
      executor: 'constant-arrival-rate',
      rate: 50,
      timeUnit: '1s',
      duration: '30s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      exec: 'cacheMiss',
      startTime: '35s',
    },
  },
  thresholds: {
    'http_req_duration{scenario:cache_hit}': ['p(99)<150'],
    'http_req_duration{scenario:cache_miss}': ['p(99)<500'],
  },
};

// Warm the cache-hit key once before the cache_hit scenario runs, so its
// own first sample isn't itself a miss.
export function setup() {
  http.post(URL, JSON.stringify({ inputs: CACHE_HIT_TEXT }), params);
}

export function cacheHit() {
  const res = http.post(URL, JSON.stringify({ inputs: CACHE_HIT_TEXT }), params);
  check(res, { 'status 200': (r) => r.status === 200, 'cache hit': (r) => r.json('cache') === 'hit' });
}

export function cacheMiss() {
  // Unique text every call - a repeat would hit the cache and defeat the
  // point of this scenario.
  const text = `k6-cache-miss-${__VU}-${__ITER}-${Date.now()}`;
  const res = http.post(URL, JSON.stringify({ inputs: text }), params);
  check(res, { 'status 200': (r) => r.status === 200, 'cache miss': (r) => r.json('cache') === 'miss' });
}
