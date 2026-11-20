import { writeFile, mkdir } from 'node:fs/promises';
import WordExtractor from 'word-extractor';

const UA = { 'User-Agent': 'Mozilla/5.0 (compatible; schedule-bot/1.0)' };
const get = async (url) => {
  const r = await fetch(url, { headers: UA });
  if (!r.ok) throw new Error(`${r.status} ${url}`);
  return r;
};

await mkdir('sources', { recursive: true });

const calendar = await (await get('https://guo-mpk.by/raspisanie/')).text();
const days = [...new Set(
  [...calendar.matchAll(/raspisanie\/\d{2}-\d{2}-\d{4}-raspisanie-uchashhihsya\/\?occurrence=(\d{4}-\d{2}-\d{2})/g)]
    .map((m) => m[1]),
)].sort();

const extractor = new WordExtractor();
const found = [];
for (const date of days.slice(0, 21)) {
  const [y, m, d] = date.split('-');
  const url = `https://guo-mpk.by/wp-content/uploads/${y}/${m}/${d}.${m}.${y}-raspisanie-uchashhihsya.doc`;
  try {
    const buf = Buffer.from(await (await get(url)).arrayBuffer());
    await writeFile('sources/tmp.doc', buf);
    const doc = await extractor.extract('sources/tmp.doc');
    await writeFile(`sources/doc-${date}.txt`, doc.getBody());
    found.push(date);
    console.log('ok', date);
  } catch (e) {
    console.log('skip', date, e.message);
  }
}

const bellsPage = await (await get('https://guo-mpk.by/raspisanie-zvonkov/')).text();
const fileParam = bellsPage.match(/get_viewer&(?:amp;)?file=([^&"#]+)/);
let pdfUrl;
if (fileParam) {
  pdfUrl = decodeURIComponent(fileParam[1]);
} else {
  const direct = bellsPage.match(/https:\/\/guo-mpk\.by\/wp-content\/uploads\/[^"'&\s<>]+\.pdf/);
  if (!direct) throw new Error('bells pdf url not found');
  pdfUrl = direct[0];
}
const pdf = Buffer.from(await (await get(pdfUrl)).arrayBuffer());
await writeFile('sources/bells.pdf', pdf);
await writeFile('sources/bells-url.txt', pdfUrl);
await writeFile('sources/days.json', JSON.stringify(found));
console.log('bells', pdfUrl, 'days', found.length);