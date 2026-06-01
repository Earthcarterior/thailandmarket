// ============================================================================
//  build.mjs — สร้างเวอร์ชัน minified/obfuscated สำหรับ deploy ลง dist/
//
//  - source ในรีโปยังอ่านได้ตามปกติ (maintain ต่อได้)
//  - dist/ คือไฟล์ที่ย่อ + mangle ชื่อตัวแปร local แล้ว (อ่าน source ยากมาก)
//
//  ความปลอดภัยของการ build:
//   * terser ตั้ง toplevel:false → ฟังก์ชัน/ตัวแปร global ที่ถูกเรียกจาก
//     inline onclick (เช่น openProduct, toggleWish) จะไม่ถูก rename/ตัดทิ้ง
//   * mangle เฉพาะตัวแปร local ในฟังก์ชัน → ลด readability โดยไม่เปลี่ยน behavior
//
//  รัน:  npm run build
// ============================================================================
import { minify as minifyHtml } from 'html-minifier-terser';
import { minify as minifyJs } from 'terser';
import { promises as fs } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve('.');
const OUT  = path.resolve('dist');

// ไฟล์/โฟลเดอร์ที่ไม่ต้อง deploy
const SKIP = new Set([
  'node_modules', 'dist', '.git', '.github',
  'build.mjs', 'package.json', 'package-lock.json', '.gitignore',
  'updateone.zip',
]);
// นามสกุลที่เป็นไฟล์ dev/ความลับ — ไม่ควรเสิร์ฟต่อสาธารณะ
const SKIP_EXT = new Set(['.sql', '.md', '.zip']);

// ── terser options (ใช้ทั้ง inline <script> และไฟล์ .js) ────────────────────
const terserOpts = {
  compress: { toplevel: false, drop_debugger: true },
  mangle:   { toplevel: false },              // ไม่แตะชื่อ global → onclick ใช้ได้
  format:   { comments: false },
};

const htmlOpts = {
  collapseWhitespace: true,
  conservativeCollapse: false,
  removeComments: true,
  minifyCSS: true,
  minifyJS: terserOpts,
  keepClosingSlash: true,
  removeAttributeQuotes: false,               // กัน attribute พังในกรณีค่ามีช่องว่าง
  ignoreCustomComments: [/^!/],
  continueOnParseError: true,                 // markup เพี้ยนบางจุด → minify best-effort ต่อ
};

let nHtml = 0, nJs = 0, nCopy = 0;
const warnings = [];

async function walk(relDir = '') {
  const absDir = path.join(ROOT, relDir);
  for (const entry of await fs.readdir(absDir, { withFileTypes: true })) {
    const rel = path.join(relDir, entry.name);
    if (relDir === '' && SKIP.has(entry.name)) continue;
    if (entry.isDirectory()) { await walk(rel); continue; }

    const ext = path.extname(entry.name).toLowerCase();
    if (SKIP_EXT.has(ext)) continue;

    const src = path.join(ROOT, rel);
    const dst = path.join(OUT, rel);
    await fs.mkdir(path.dirname(dst), { recursive: true });

    if (ext === '.html') {
      const input = await fs.readFile(src, 'utf8');
      try {
        await fs.writeFile(dst, await minifyHtml(input, htmlOpts));
        nHtml++;
      } catch (e) {
        await fs.writeFile(dst, input);          // fallback: เสิร์ฟไฟล์ดิบ ไม่ให้เว็บพัง
        warnings.push(`HTML minify ไม่ผ่าน (copy ดิบแทน): ${rel} — ${e.message.split('\n')[0]}`);
        nCopy++;
      }
    } else if (ext === '.js') {
      const input = await fs.readFile(src, 'utf8');
      try {
        const res = await minifyJs(input, terserOpts);
        await fs.writeFile(dst, res.code ?? input);
        nJs++;
      } catch (e) {
        await fs.writeFile(dst, input);
        warnings.push(`JS minify ไม่ผ่าน (copy ดิบแทน): ${rel} — ${e.message.split('\n')[0]}`);
        nCopy++;
      }
    } else {
      await fs.copyFile(src, dst);               // CNAME, รูป, css, ฯลฯ
      nCopy++;
    }
  }
}

await fs.rm(OUT, { recursive: true, force: true });
await fs.mkdir(OUT, { recursive: true });
await walk();
console.log(`✓ build เสร็จ → dist/  (html:${nHtml}  js:${nJs}  copied:${nCopy})`);
if (warnings.length) {
  console.log(`\n⚠️  ${warnings.length} ไฟล์ minify ไม่ผ่าน (เสิร์ฟแบบดิบ):`);
  for (const w of warnings) console.log('   - ' + w);
}

