#!/usr/bin/env node
// ~/.config/nvim/scripts/smart-move.mjs
// (루트 자동 감지 + 폴더 이동 + import 업데이트)

import fs from "node:fs";
import path from "node:path";

const exists = (p) => {
  try {
    fs.accessSync(p);
    return true;
  } catch {
    return false;
  }
};
const mkdirp = (p) => fs.mkdirSync(p, { recursive: true });
const findUp = (cands, dir = process.cwd()) => {
  let d = path.resolve(dir);
  while (true) {
    for (const c of cands) {
      const p = path.join(d, c);
      if (exists(p)) return p;
    }
    const parent = path.dirname(d);
    if (parent === d) return null;
    d = parent;
  }
};

function detectRoot() {
  const f = findUp(["pubspec.yaml", "package.json", "tsconfig.json", ".git"]);
  return f ? path.dirname(f) : process.cwd();
}

function detectType(root) {
  if (exists(path.join(root, "pubspec.yaml"))) return "flutter";
  const pkg = path.join(root, "package.json");
  if (exists(pkg)) {
    const p = JSON.parse(fs.readFileSync(pkg, "utf8"));
    const d = { ...(p.dependencies || {}), ...(p.devDependencies || {}) };
    if (d["@nestjs/core"]) return "nestjs";
    if (d["@sveltejs/kit"] || exists(path.join(root, "svelte.config.js")))
      return "svelte";
    return "ts";
  }
  return "unknown";
}

const mkdir = (p) => fs.mkdirSync(p, { recursive: true });
const rename = (a, b) => {
  mkdir(path.dirname(b));
  fs.renameSync(a, b);
};

// Flutter 처리
function flutterMove(root, oldPath, newPath) {
  const pubspec = fs.readFileSync(path.join(root, "pubspec.yaml"), "utf8");
  const pkg = pubspec.match(/^\s*name:\s*([A-Za-z0-9_]+)\s*$/m)?.[1];
  if (!pkg) throw new Error("pubspec.yaml에 name이 없음");

  const lib = path.join(root, "lib");
  const relOld = path.relative(lib, oldPath).split(path.sep).join("/");
  const relNew = path.relative(lib, newPath).split(path.sep).join("/");
  rename(oldPath, newPath);

  const before = `package:${pkg}/${relOld}`;
  const after = `package:${pkg}/${relNew}`;

  let files = 0;
  for (const f of walkFiles(lib, ".dart")) {
    const txt = fs.readFileSync(f, "utf8");
    if (txt.includes(before)) {
      fs.writeFileSync(f, txt.replaceAll(before, after), "utf8");
      files++;
    }
  }
  console.log(
    `✅ Flutter moved ${relOld} → ${relNew} (${files} files updated)`,
  );
}

function* walkFiles(dir, ext) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* walkFiles(p, ext);
    else if (e.isFile() && p.endsWith(ext)) yield p;
  }
}

// TS 처리
async function tsMove(root, oldPath, newPath) {
  const { Project } = await import("ts-morph");
  const tsconfig = ["tsconfig.json", "tsconfig.base.json"]
    .map((f) => path.join(root, f))
    .find(exists);
  const project = tsconfig
    ? new Project({ tsConfigFilePath: tsconfig })
    : new Project();

  const stat = fs.statSync(oldPath);
  if (stat.isDirectory()) {
    const allFiles = fs
      .readdirSync(oldPath, { recursive: true })
      .filter((f) => /\.(t|j)sx?$/.test(f))
      .map((f) => path.join(oldPath, f));
    for (const f of allFiles) {
      const rel = path.relative(oldPath, f);
      const dest = path.join(newPath, rel);
      rename(f, dest);
      const sf = project.getSourceFile(f);
      if (sf) sf.moveImmediately(dest);
    }
  } else {
    rename(oldPath, newPath);
    const sf = project.getSourceFile(oldPath);
    if (sf) sf.moveImmediately(newPath);
  }
  await project.save();
  console.log(`✅ TS moved ${oldPath} → ${newPath}`);
}

// Main
(async () => {
  const [, , oldArg, newArg] = process.argv;
  if (!oldArg || !newArg) {
    console.error("Usage: node smart-move.mjs <old> <new>");
    process.exit(1);
  }

  const root = detectRoot();
  const type = detectType(root);
  const oldPath = path.resolve(oldArg);
  const newPath = path.resolve(newArg);
  console.log(`📂 Detected ${type} project (root: ${root})`);

  try {
    if (type === "flutter") flutterMove(root, oldPath, newPath);
    else if (["ts", "nestjs", "svelte"].includes(type))
      await tsMove(root, oldPath, newPath);
    else rename(oldPath, newPath);
  } catch (e) {
    console.error("❌", e.message || e);
  }
})();
