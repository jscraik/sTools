#!/usr/bin/env node
import { copyFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const cliSource = join(root, "packages/cli/dist/cli.js");
const cliDest = join(
  root,
  "src-tauri/target/debug/bundle/macos/SkillsInspector.app/Contents/MacOS/skillsctl"
);

// Ensure destination directory exists
await mkdir(dirname(cliDest), { recursive: true });

// Copy CLI to bundle
await copyFile(cliSource, cliDest);
console.log(`Bundled CLI to: ${cliDest}`);
