// scripts/syncAllRoadmaps.js
require('dotenv').config();
const path = require('path');
const fs = require('fs');
const glob = require('glob');
const mongoose = require('mongoose');

const connectDB = require('../src/config/db');
const Career = require('../src/modules/career/career.model');
const Roadmap = require('../src/modules/roadmap/roadmap.model');

const ROADMAP_REPO_PATH =
  process.env.ROADMAP_REPO_PATH || path.join(__dirname, '..', 'vendor', 'developer-roadmap');

function toTitleCase(slug) {
  return slug
    .replace(/[-_]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

// Extract a readable title from node.data.label
function extractLabel(node) {
  const raw = node?.data?.label;

  if (!raw) return null;

  // label might be string or rich text; handle simplest case
  if (typeof raw === 'string') {
    const t = raw.replace(/<[^>]*>/g, '').trim(); // remove html tags if any
    return t.length ? t : null;
  }

  // Sometimes label can be object/array in editors; fallback to JSON string
  try {
    const s = JSON.stringify(raw);
    return s && s !== '{}' ? s : null;
  } catch {
    return null;
  }
}

function isUsefulNode(node) {
  // We will exclude pure layout/decoration nodes.
  // Keep anything that has a non-empty label.
  const label = extractLabel(node);
  if (!label) return false;

  // Filter out huge paragraphs with empty-ish labels can still pass; keep basic check:
  if (label.length < 2) return false;

  return true;
}

function loadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

async function upsertCareerByRoadmapId(roadmapId) {
  const name = toTitleCase(roadmapId);
  const career = await Career.findOneAndUpdate(
    { name },
    {
      $setOnInsert: {
        name,
        description: `Imported roadmap: ${roadmapId}`,
        requiredSkills: [],
        skills: [],
      },
    },
    { upsert: true, new: true }
  );
  return career;
}

async function main() {
  await connectDB();

 const pattern = path
  .join(ROADMAP_REPO_PATH, 'src', 'data', 'roadmaps', '*', '*.json')
  .replace(/\\/g, '/'); // ✅ make glob work on Windows
const jsonFiles = glob.sync(pattern, { nodir: true });
const filteredFiles = jsonFiles.filter((f) => {
  const base = path.basename(f).toLowerCase();
  return base !== 'mapping.json' && base !== 'migration-mapping.json';
});
console.log('Pattern used:', pattern);
console.log(`Found ${filteredFiles.length} roadmap JSON files`);
for (const file of filteredFiles) {    const roadmapId = path.basename(file, '.json'); // ✅ filename (frontend, frontend-beginner, etc.)
    const json = loadJson(file);

   let steps = [];

if (Array.isArray(json.nodes)) {
  // ✅ Format A: Graph-based roadmap (nodes/edges)
  steps = json.nodes
    .filter(isUsefulNode)
    .map((n) => {
      const title = extractLabel(n);
      const y = n?.position?.y ?? 0;
      const x = n?.position?.x ?? 0;
      return { nodeId: n.id, type: n.type, title, x, y };
    })
    .sort((a, b) => (a.y - b.y) || (a.x - b.x))
    .map((s, idx) => ({
      title: s.title,
      description: `roadmap.sh nodeId=${s.nodeId} type=${s.type}`,
      skillTag: roadmapId,
      order: idx + 1,
      resources: [],
    }));
} else {
  // ✅ Format B: “Checklist/tree” roadmaps (no nodes[])
  // We try common keys that appear in these JSONs.
  const candidates =
    json.topics ||
    json.items ||
    json.sections ||
    json.roadmap ||
    json.content ||
    [];

  const flat = [];

  function walk(value) {
    if (!value) return;

    if (Array.isArray(value)) {
      value.forEach(walk);
      return;
    }

    if (typeof value === 'object') {
      // try to capture a readable title from common keys
      const t =
        value.title ||
        value.name ||
        value.label ||
        value.text ||
        (typeof value.id === 'string' ? value.id : null);

      if (typeof t === 'string') {
        const clean = t.replace(/<[^>]*>/g, '').trim();
        if (clean.length >= 2) flat.push(clean);
      }

      // recurse into all object values
      Object.values(value).forEach(walk);
    }
  }

  walk(candidates);

  // de-duplicate while preserving order
  const uniq = [];
  const seen = new Set();
  for (const t of flat) {
    const key = t.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      uniq.push(t);
    }
  }

  steps = uniq.map((title, idx) => ({
    title,
    description: `roadmap.sh imported (non-graph format)`,
    skillTag: roadmapId,
    order: idx + 1,
    resources: [],
  }));
}

if (!steps.length) {
  console.log(`⚠️ Skip ${roadmapId}: could not extract steps`);
  continue;
}

    

    const career = await upsertCareerByRoadmapId(roadmapId);

    // Convert to your roadmap schema format
   const phase = {
  title: toTitleCase(roadmapId),
  order: 1,
  steps, // ✅ already in correct schema shape now
};

    // IMPORTANT: Your roadmap model currently does not include sourceRoadmapId,
    // so we identify by careerId only and overwrite phases for that career.
    // (Later we can add sourceRoadmapId if needed.)
    await Roadmap.findOneAndUpdate(
      { careerId: career._id },
      { $set: { careerId: career._id, phases: [phase] } },
      { upsert: true, new: true }
    );

    console.log(`✅ Imported ${roadmapId}: steps=${steps.length}`);
  }

  await mongoose.disconnect();
  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});