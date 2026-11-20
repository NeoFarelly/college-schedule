import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';

const GROUP = '21Н';
const CELL_GROUP = /^\d{1,2}[А-ЯЁ]{1,2}$/;
const PAIR = /^(\d+)(?:\s+(.*))?$/;
const ROOM_TAIL = /^(.*?)\s*(\d{1,3}(?:\/[\dА-ЯЁа-яё-]*)*|[А-ЯЁ]{2,}(?:\/[\dА-ЯЁа-яё-]*)*)\s*$/;

function cells(line) {
  if (!line.trim().startsWith('│')) return null;
  return line.split('│').slice(1, -1).map((c) => c.trim());
}

function parseDay(text) {
  const lines = text.split('\n');
  let col = -1;
  const pairs = new Map();
  let lastNum = 0;
  for (const line of lines) {
    const cs = cells(line);
    if (!cs) continue;
    const groups = cs.filter((c) => CELL_GROUP.test(c));
    if (groups.length >= 2) {
      col = cs.indexOf(GROUP);
      lastNum = 0;
      continue;
    }
    if (col < 0 || col >= cs.length) continue;
    const cell = cs[col];
    if (!cell) continue;
    const m = cell.match(PAIR);
    if (m) {
      lastNum = Number(m[1]);
      const rest = (m[2] ?? '').trim();
      if (!rest) continue;
      const rm = rest.match(ROOM_TAIL);
      pairs.set(lastNum, {
        number: lastNum,
        subject: rm ? rm[1].trim() : rest,
        room: rm ? rm[2].trim() : '',
        teacher: '',
      });
    } else if (lastNum && pairs.has(lastNum)) {
      const p = pairs.get(lastNum);
      p.teacher = p.teacher ? `${p.teacher} ${cell}` : cell;
    }
  }
  return [...pairs.values()].sort((a, b) => a.number - b.number);
}

await mkdir('data', { recursive: true });
const files = (await readdir('sources')).filter((f) => /^doc-\d{4}-\d{2}-\d{2}\.txt$/.test(f));
const days = [];
for (const file of files.sort()) {
  const date = file.slice(4, 14);
  const lessons = parseDay(await readFile(`sources/${file}`, 'utf8'));
  await writeFile(`data/day-${date}.json`, JSON.stringify({ date, group: GROUP, lessons }, null, 1));
  days.push(date);
  console.log('parsed', date, lessons.length, 'lessons');
}

let bellsUpdatedAt = '';
try {
  const bells = JSON.parse(await readFile('data/bells.json', 'utf8'));
  bellsUpdatedAt = bells.updatedAt ?? '';
} catch {}
await writeFile('data/index.json', JSON.stringify({ group: GROUP, days, bellsUpdatedAt }, null, 1));
console.log('index', days.length, 'days');