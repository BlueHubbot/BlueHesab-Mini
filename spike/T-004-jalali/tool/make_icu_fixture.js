// Writes test/fixtures/icu_nowruz.csv for the T-004 spike (SP-04, DT-05).
// Source of truth here is ICU's Persian calendar as shipped with Node.js
// (Intl.DateTimeFormat with "-u-ca-persian"); the script prints the ICU
// version into the file header. Synthetic reference data, no user data.
// Usage (from spike/T-004-jalali): node tool/make_icu_fixture.js
'use strict';
const fs = require('fs');

const fmt = new Intl.DateTimeFormat('en-u-ca-persian-nu-latn', {
  timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric',
});
const DAY = 86400000;

function persian(t) {
  const parts = {};
  for (const p of fmt.formatToParts(new Date(t))) parts[p.type] = p.value;
  return [parseInt(parts.year, 10), Number(parts.month), Number(parts.day)];
}

// Nowruz (1 Farvardin) of every Jalali year whose whole year lies in
// Gregorian 1900-03-21 … 2124-03-19 (the range the tests assert against).
const nowruz = new Map();
for (let t = Date.UTC(1900, 0, 1); t < Date.UTC(2125, 0, 1); t += DAY) {
  const [y, m, d] = persian(t);
  if (m === 1 && d === 1) nowruz.set(y, t);
}
const years = [...nowruz.keys()].sort((a, b) => a - b);
const lines = [
  `# ICU ${process.versions.icu} (Node ${process.version}), Persian calendar`,
  '# jalali_year,gregorian_nowruz,days_in_year',
];
for (let i = 0; i + 1 < years.length; i++) {
  const y = years[i];
  const days = Math.round((nowruz.get(years[i + 1]) - nowruz.get(y)) / DAY);
  lines.push(`${y},${new Date(nowruz.get(y)).toISOString().slice(0, 10)},${days}`);
}
fs.writeFileSync('test/fixtures/icu_nowruz.csv', lines.join('\n') + '\n');
console.log(`wrote ${years.length - 1} years ${years[0]}..${years[years.length - 2]}`);
