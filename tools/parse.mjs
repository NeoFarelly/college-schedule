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

const toMin = (s) => {
  const [h, m] = s.split(':').map(Number);
  return h * 60 + m;
};

function parseBells(text) {
  const cols = [[], [], []];
  for (const line of text.split('\n')) {
    const m = line.match(/^\s*(\d{1,2})\s+(.*)$/);
    if (!m) continue;
    const n = Number(m[1]);
    if (n < 1 || n > 12) continue;
    const ranges = [...m[2].matchAll(/(\d{1,2})\D{0,2}(\d{2})\s*[-–—]\s*(\d{1,2})\D{0,2}(\d{2})/g)]
      .map((r) => ({
        start: `${r[1].padStart(2, '0')}:${r[2]}`,
        end: `${r[3].padStart(2, '0')}:${r[4]}`,
      }));
    for (let c = 0; c < 3; c++) {
      if (ranges[c]) cols[c][n - 1] = ranges[c];
    }
  }
  const valid = (col) => {
    if (!col.length || col.some((v) => !v)) return null;
    if (col.length < 6) return null;
    for (let i = 0; i < col.length; i++) {
      const s = toMin(col[i].start);
      const e = toMin(col[i].end);
      if (e <= s || e - s > 120) return null;
      if (i > 0) {
        const gap = s - toMin(col[i - 1].end);
        if (gap < 5 || gap > 35) return null;
      }
    }
    return col;
  };
  const weekday = valid(cols[0]);
  const thursday = valid(cols[1]);
  const saturday = valid(cols[2]);
  if (!weekday || !thursday || !saturday) return null;
  return { weekday, thursday, saturday };
}

try {
  const ocr = parseBells(await readFile('sources/bells-ocr.txt', 'utf8'));
  if (ocr) {
    ocr.updatedAt = new Date().toISOString();
    ocr.source = 'ocr';
    await writeFile('data/bells.json', JSON.stringify(ocr, null, 1));
    bellsUpdatedAt = ocr.updatedAt;
    console.log('bells updated from OCR');
  } else {
    console.log('bells OCR unreadable, keeping committed bells.json');
  }
} catch {
  console.log('bells OCR missing, keeping committed bells.json');
}

await writeFile('data/index.json', JSON.stringify({ group: GROUP, days, bellsUpdatedAt }, null, 1));
console.log('index', days.length, 'days');