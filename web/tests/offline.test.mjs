import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

const publicRoot = new URL("../public/", import.meta.url);
const source = await readFile(new URL("sw.js", publicRoot), "utf8");

function worker(scope = "https://example.test/Metric-Conversion/") {
  const listeners = {};
  const stored = new Map();
  const deleted = [];
  const fetched = [];
  let claimed = false;
  const cache = {
    addAll: async (urls) => {
      for (const url of urls) stored.set(url, `cached:${url}`);
    },
    match: async (request) => stored.get(typeof request === "string" ? request : request.url),
  };
  const prefix = `metric-converter:${scope}:`;
  vm.runInNewContext(source, {
    URL,
    self: {
      registration: { scope },
      clients: { claim: async () => { claimed = true; } },
      addEventListener: (name, listener) => { listeners[name] = listener; },
    },
    caches: {
      open: async () => cache,
      keys: async () => [`${prefix}v0`, `${prefix}v1`, "another-app", "metric-converter:https://example.test/other/:v1"],
      delete: async (name) => { deleted.push(name); },
    },
    fetch: async (request) => { fetched.push(request.url); return "network"; },
  });
  return { listeners, stored, deleted, fetched, scope, get claimed() { return claimed; } };
}

async function dispatchLifecycle(state, name) {
  let completion;
  state.listeners[name]({ waitUntil: (promise) => { completion = promise; } });
  await completion;
}

function dispatchFetch(state, path, mode = "cors", method = "GET") {
  let response;
  state.listeners.fetch({
    request: { url: new URL(path, state.scope).href, mode, method },
    respondWith: (promise) => { response = promise; },
  });
  return response;
}

test("all precached files exist and root/subdirectory hosting both work offline", async () => {
  for (const scope of ["https://example.test/", "https://example.test/Metric-Conversion/"]) {
    const state = worker(scope);
    await dispatchLifecycle(state, "install");
    assert.equal(state.stored.size, 10);
    for (const url of state.stored.keys()) {
      const path = url.slice(scope.length) || "index.html";
      const content = await readFile(new URL(path, publicRoot));
      assert.ok(content.length > 0, path);
    }
    for (const path of ["./", "./?from=home", "./index.html?from=home"]) {
      assert.equal(await dispatchFetch(state, path, "navigate"), `cached:${scope}`);
    }
    assert.equal(await dispatchFetch(state, "./app.mjs"), `cached:${scope}app.mjs`);
    assert.deepEqual(state.fetched, []);
  }
});

test("activation removes only this app's old caches", async () => {
  const state = worker();
  await dispatchLifecycle(state, "activate");
  assert.deepEqual(state.deleted, [`metric-converter:${state.scope}:v0`]);
  assert.equal(state.claimed, true);
});

test("unrelated URLs and non-GET requests are not intercepted", () => {
  const state = worker();
  for (const path of ["https://other.test/", "../other/", "./unknown", "./app.mjs?different-version"]) {
    assert.equal(dispatchFetch(state, path), undefined);
  }
  assert.equal(dispatchFetch(state, "./", "navigate", "POST"), undefined);
});

test("missing cached assets use the network without returning success-shaped fallbacks", async () => {
  const state = worker();
  assert.equal(await dispatchFetch(state, "./app.mjs"), "network");
  assert.deepEqual(state.fetched, [`${state.scope}app.mjs`]);
});

test("manifest and iPhone icons have valid relative URLs and real PNG dimensions", async () => {
  const manifest = JSON.parse(await readFile(new URL("manifest.webmanifest", publicRoot), "utf8"));
  assert.equal(manifest.display, "standalone");
  assert.equal(manifest.start_url, "./");
  assert.equal(manifest.scope, "./");
  const icons = [...manifest.icons, { src: "./icons/apple-touch-icon.png", sizes: "180x180" }];
  for (const icon of icons) {
    const bytes = await readFile(new URL(icon.src, publicRoot));
    assert.equal(bytes.subarray(1, 4).toString(), "PNG");
    const [width, height] = icon.sizes.split("x").map(Number);
    assert.equal(bytes.readUInt32BE(16), width);
    assert.equal(bytes.readUInt32BE(20), height);
  }
});
