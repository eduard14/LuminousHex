const fs = require("fs");
const path = require("path");

const sourcePath = path.join(__dirname, "..", "index.js");
const source = fs.readFileSync(sourcePath, "utf8");

const declared = new Set([
  "Array",
  "Boolean",
  "Buffer",
  "Date",
  "Error",
  "Intl",
  "Map",
  "Math",
  "Number",
  "Object",
  "Promise",
  "RegExp",
  "Set",
  "String",
  "require",
]);

for (const match of source.matchAll(/\bfunction\s+([A-Za-z_$][\w$]*)\s*\(/g)) {
  declared.add(match[1]);
}

for (const match of source.matchAll(/\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)\b/g)) {
  declared.add(match[1]);
}

for (const match of source.matchAll(/\b(?:const|let|var)\s+\{([^}]+)\}\s*=/g)) {
  for (const entry of match[1].split(",")) {
    const name = entry.split(":").pop().trim();
    if (/^[A-Za-z_$][\w$]*$/.test(name)) {
      declared.add(name);
    }
  }
}

const ignored = new Set([
  "async",
  "catch",
  "for",
  "if",
  "return",
  "switch",
  "while",
]);

const missing = new Set();
for (const match of source.matchAll(/(^|[^.\w$])([A-Za-z_$][\w$]*)\s*\(/gm)) {
  const name = match[2];
  if (!ignored.has(name) && !declared.has(name)) {
    missing.add(name);
  }
}

if (missing.size > 0) {
  console.error(
    `Possible undefined function call(s): ${Array.from(missing).sort().join(", ")}`,
  );
  process.exit(1);
}
