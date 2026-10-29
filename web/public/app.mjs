import {
  units, defaultSettings, maximumEntries, parseInput, convert, format,
  selectedUnits, validateSettings, validateHistory,
} from "./converter.mjs";

const element = (id) => document.getElementById(id);
const storageKeys = {
  settings: "metric-converter.web.settings.v1",
  history: "metric-converter.web.history.v1",
};

function storageWarning(message, error) {
  console.error(message, error);
  element("storage-warning").textContent = message;
  element("storage-warning").hidden = false;
}

function load(key, fallback, validate) {
  try {
    const stored = localStorage.getItem(key);
    return stored === null ? fallback : validate(JSON.parse(stored));
  } catch (error) {
    storageWarning("Saved data could not be read. Defaults are being used for the affected data. Browser storage may be unavailable or damaged.", error);
    return fallback;
  }
}

function persist(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch (error) {
    storageWarning("Changes are only kept for this session because browser storage could not be updated. Check available space and browser privacy settings.", error);
    return false;
  }
}

let settings = load(storageKeys.settings, { ...defaultSettings }, validateSettings);
let history = load(storageKeys.history, [], validateHistory);
let currentConversion = null;
const input = element("value");
const actionStatus = element("action-status");

function describe(entry) {
  return `${format(entry.inputValue, settings.precision)} ${units[entry.sourceUnit].symbol} = ${format(entry.outputValue, settings.precision)} ${units[entry.destinationUnit].symbol}`;
}

function renderHistory() {
  element("history-list").replaceChildren(...history.map((entry) => {
    const item = document.createElement("li");
    item.textContent = describe(entry);
    return item;
  }));
  element("empty-history").hidden = history.length > 0;
  element("clear").disabled = history.length === 0;
}

function renderConversion() {
  const [sourceUnit, destinationUnit] = selectedUnits(settings);
  element("value-label").textContent = `Value in ${units[sourceUnit].name.toLowerCase()}`;
  element("imperial-to-metric").setAttribute("aria-pressed", String(settings.direction === "imperialToMetric"));
  element("metric-to-imperial").setAttribute("aria-pressed", String(settings.direction === "metricToImperial"));
  const value = parseInput(input.value);
  let feedback = input.value.trim() ? "Enter a valid, finite number (use a decimal point)." : "Enter a number to see the conversion.";
  currentConversion = null;
  if (value !== null) {
    try {
      currentConversion = {
        inputValue: value, sourceUnit, destinationUnit,
        outputValue: convert(value, sourceUnit, destinationUnit),
      };
      feedback = "Ready to save or copy.";
    } catch (error) {
      if (!(error instanceof RangeError)) throw error;
      feedback = error.message;
    }
  }
  input.setAttribute("aria-invalid", String(Boolean(input.value.trim()) && !currentConversion));
  element("input-feedback").textContent = feedback;
  element("result").textContent = currentConversion
    ? `${format(currentConversion.outputValue, settings.precision)} ${units[destinationUnit].symbol}` : "—";
  element("equation").textContent = currentConversion ? describe(currentConversion) : "Your result appears here";
  element("save").disabled = !currentConversion;
  element("copy").disabled = !currentConversion;
}

function settingsChanged() {
  persist(storageKeys.settings, settings);
  actionStatus.textContent = "";
  renderConversion();
  renderHistory();
}

element("metric-unit").value = settings.metricUnit;
element("imperial-unit").value = settings.imperialUnit;
element("precision").value = String(settings.precision);

for (const [id, key] of [["metric-unit", "metricUnit"], ["imperial-unit", "imperialUnit"], ["precision", "precision"]]) {
  element(id).addEventListener("change", (event) => {
    settings[key] = key === "precision" ? Number(event.target.value) : event.target.value;
    settingsChanged();
  });
}
for (const [id, direction] of [["imperial-to-metric", "imperialToMetric"], ["metric-to-imperial", "metricToImperial"]]) {
  element(id).addEventListener("click", () => {
    settings.direction = direction;
    settingsChanged();
  });
}
input.addEventListener("input", () => {
  actionStatus.textContent = "";
  renderConversion();
});
element("negate").addEventListener("click", () => {
  const text = input.value.trim();
  input.value = text.startsWith("-") ? text.slice(1) : `-${text.replace(/^\+/, "")}`;
  actionStatus.textContent = "";
  renderConversion();
  input.focus();
});
element("conversion-form").addEventListener("submit", (event) => {
  event.preventDefault();
  if (!currentConversion) {
    actionStatus.textContent = element("input-feedback").textContent;
    return;
  }
  history = [currentConversion, ...history].slice(0, maximumEntries);
  const saved = persist(storageKeys.history, history);
  renderHistory();
  actionStatus.textContent = saved ? "Saved to recent conversions." : "Added for this session only.";
});
element("copy").addEventListener("click", async () => {
  if (!currentConversion) return;
  const text = `${format(currentConversion.outputValue, settings.precision)} ${units[currentConversion.destinationUnit].symbol}`;
  try {
    if (!navigator.clipboard?.writeText) throw new Error("Clipboard access is unavailable.");
    await navigator.clipboard.writeText(text);
    actionStatus.textContent = "Result copied.";
  } catch (error) {
    console.error("Could not copy the conversion.", error);
    actionStatus.textContent = "Could not access the clipboard. Touch and hold the result to copy it manually.";
  }
});
element("clear").addEventListener("click", () => {
  history = [];
  const saved = persist(storageKeys.history, history);
  renderHistory();
  actionStatus.textContent = saved ? "Conversion history cleared." : "History cleared for this session only.";
});

renderConversion();
renderHistory();

async function prepareOfflineAccess() {
  const status = element("offline-status");
  if (!("serviceWorker" in navigator)) {
    status.textContent = "Offline access is unavailable in this browser. Use Safari over HTTPS on iPhone.";
    return;
  }
  let ready = false;
  const updateStatus = () => {
    status.textContent = ready
      ? navigator.onLine ? "Ready for offline use." : "You're offline. Conversions still work."
      : "Preparing offline access. Keep this page open until it is ready.";
  };
  window.addEventListener("online", updateStatus);
  window.addEventListener("offline", updateStatus);
  try {
    // Relative URLs also work when hosted under a GitHub Pages repository path.
    const registration = await navigator.serviceWorker.register("./sw.js");
    const worker = registration.installing || registration.waiting;
    worker?.addEventListener("statechange", () => {
      if (worker.state === "redundant" && !ready) {
        status.textContent = "Offline setup failed. Reconnect and reload this page to try again.";
      }
    });
    updateStatus();
    await navigator.serviceWorker.ready;
    ready = true;
    updateStatus();
  } catch (error) {
    console.error("Offline setup failed.", error);
    status.textContent = "Offline setup failed. Open this page over HTTPS (or localhost), then reload to try again.";
  }
}

prepareOfflineAccess();
