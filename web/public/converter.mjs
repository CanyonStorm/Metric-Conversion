export const units = Object.freeze({
  millimetres: { name: "Millimetres", symbol: "mm", factor: 1, system: "metric" },
  centimetres: { name: "Centimetres", symbol: "cm", factor: 10, system: "metric" },
  metres: { name: "Metres", symbol: "m", factor: 1000, system: "metric" },
  inches: { name: "Inches", symbol: "in", factor: 25.4, system: "imperial" },
  feet: { name: "Feet", symbol: "ft", factor: 304.8, system: "imperial" },
  yards: { name: "Yards", symbol: "yd", factor: 914.4, system: "imperial" },
});

export const defaultSettings = Object.freeze({
  direction: "imperialToMetric",
  metricUnit: "millimetres",
  imperialUnit: "inches",
  precision: 2,
});

export const maximumEntries = 25;

export function parseInput(text) {
  const trimmed = text.trim();
  if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i.test(trimmed)) return null;
  const value = Number(trimmed);
  return Number.isFinite(value) ? value : null;
}

export function convert(value, source, destination) {
  if (!Number.isFinite(value) || !Object.hasOwn(units, source) || !Object.hasOwn(units, destination)) {
    throw new TypeError("A finite value and valid length units are required.");
  }
  const result = value * units[source].factor / units[destination].factor;
  if (!Number.isFinite(result)) throw new RangeError("This value is too large to convert.");
  return result;
}

export function format(value, precision) {
  if (!Number.isFinite(value) || !Number.isInteger(precision) || precision < 0 || precision > 4) {
    throw new TypeError("Formatting requires a finite value and 0-4 decimal places.");
  }
  // Unlike toFixed, Intl also keeps decimal places for values at or above 1e21.
  return value.toLocaleString("en-US", {
    useGrouping: false,
    minimumFractionDigits: precision,
    maximumFractionDigits: precision,
  });
}

export function selectedUnits(settings) {
  return settings.direction === "metricToImperial"
    ? [settings.metricUnit, settings.imperialUnit]
    : [settings.imperialUnit, settings.metricUnit];
}

export function validateSettings(value) {
  if (!value || !["metricToImperial", "imperialToMetric"].includes(value.direction)
      || !Object.hasOwn(units, value.metricUnit) || units[value.metricUnit].system !== "metric"
      || !Object.hasOwn(units, value.imperialUnit) || units[value.imperialUnit].system !== "imperial"
      || !Number.isInteger(value.precision) || value.precision < 0 || value.precision > 4) {
    throw new TypeError("Saved conversion settings are invalid.");
  }
  return {
    direction: value.direction,
    metricUnit: value.metricUnit,
    imperialUnit: value.imperialUnit,
    precision: value.precision,
  };
}

export function validateHistory(value) {
  if (!Array.isArray(value)) throw new TypeError("Saved conversion history is invalid.");
  return value.slice(0, maximumEntries).map((entry) => {
    if (!entry || !Number.isFinite(entry.inputValue)) {
      throw new TypeError("Saved conversion history contains an invalid entry.");
    }
    return {
      inputValue: entry.inputValue,
      sourceUnit: entry.sourceUnit,
      destinationUnit: entry.destinationUnit,
      outputValue: convert(entry.inputValue, entry.sourceUnit, entry.destinationUnit),
    };
  });
}
