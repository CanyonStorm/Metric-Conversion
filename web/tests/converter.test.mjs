import test from "node:test";
import assert from "node:assert/strict";
import {
  units, defaultSettings, maximumEntries, parseInput, convert, format,
  selectedUnits, validateSettings, validateHistory,
} from "../public/converter.mjs";

test("matches the native app's conversion examples", () => {
  assert.ok(Math.abs(convert(90, "millimetres", "inches") - 3.5433070866) < 1e-10);
  assert.ok(Math.abs(convert(21, "inches", "millimetres") - 533.4) < 1e-10);
  assert.ok(Math.abs(convert(2, "metres", "yards") - 2.187226596675415) < 1e-15);
});

test("all six unit pairs round-trip positive, negative, and zero values", () => {
  for (const source of Object.keys(units)) {
    for (const destination of Object.keys(units)) {
      for (const value of [-123.456, 0, 123.456]) {
        const result = convert(convert(value, source, destination), destination, source);
        assert.ok(Math.abs(result - value) < 1e-10);
      }
    }
  }
});

test("input accepts finite decimal/scientific numbers and rejects malformed input", () => {
  for (const [text, expected] of [[" 34 ", 34], ["-.5", -.5], ["+2.", 2], ["1e3", 1000], ["0", 0]]) {
    assert.equal(parseInput(text), expected);
  }
  for (const text of ["", " ", "Infinity", "infinity", "NaN", "1e309", "0x10", "0b10", "1,5", "1 2", "--1", "12mm"]) {
    assert.equal(parseInput(text), null, text);
  }
});

test("formats exactly 0-4 decimal places including large numbers", () => {
  assert.equal(format(533.4, 2), "533.40");
  assert.equal(format(3.5433070866, 4), "3.5433");
  assert.equal(format(2.9, 0), "3");
  assert.equal(format(0, 3), "0.000");
  assert.equal(format(1e21, 2), "1000000000000000000000.00");
  for (const precision of [-1, 5, 1.5, "2"]) {
    assert.throws(() => format(1, precision), TypeError);
  }
  assert.throws(() => format(Infinity, 2), TypeError);
});

test("conversion rejects unknown units, non-finite inputs, and overflow", () => {
  for (const value of [Infinity, NaN, "2"]) {
    assert.throws(() => convert(value, "metres", "feet"), TypeError);
  }
  for (const unit of ["invalid", "toString", "__proto__"]) {
    assert.throws(() => convert(1, unit, "feet"), TypeError);
  }
  assert.throws(() => convert(Number.MAX_VALUE, "metres", "millimetres"), RangeError);
});

test("settings restore only valid values and select the correct direction", () => {
  assert.deepEqual(validateSettings(defaultSettings), defaultSettings);
  assert.deepEqual(selectedUnits(defaultSettings), ["inches", "millimetres"]);
  const settings = { ...defaultSettings, direction: "metricToImperial", metricUnit: "metres", imperialUnit: "yards", precision: 4 };
  assert.deepEqual(selectedUnits(validateSettings(settings)), ["metres", "yards"]);
  for (const invalid of [null, {}, { ...settings, precision: 5 }, { ...settings, metricUnit: "feet" },
    { ...settings, imperialUnit: "__proto__" }, { ...settings, direction: "wrong" }]) {
    assert.throws(() => validateSettings(invalid), TypeError);
  }
});

test("history restores at most 25 entries and recalculates output rather than trusting storage", () => {
  const entry = { inputValue: 21, sourceUnit: "inches", destinationUnit: "millimetres", outputValue: -999 };
  const restored = validateHistory(Array.from({ length: 30 }, () => entry));
  assert.equal(restored.length, maximumEntries);
  assert.ok(Math.abs(restored[0].outputValue - 533.4) < 1e-10);
  for (const invalid of [null, {}, [null], [{ ...entry, inputValue: Infinity }], [{ ...entry, sourceUnit: "oops" }]]) {
    assert.throws(() => validateHistory(invalid), TypeError);
  }
});
