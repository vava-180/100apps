/* =========================================================================
   Day 9 QRコード 自己テスト（開発用・アプリ本体とは別物）

   目的：index.html のQR生成エンジンが「本当に正しいQRを作れているか」を、
         アプリとは別に独立して書いた“読み取り器（デコーダ）”で検証する。

   流れ：
     1) index.html からQR生成のコードだけを取り出して動かす
     2) 文字列をQRにする → そのQRを独立デコーダで読み戻す → 元の文字列と一致するか
     3) 誤り訂正符号（リード・ソロモン）が数学的に正しいか（割り切れるか）
     4) バージョン自動選択の境界（14/15, 26/27 … 106/107バイト）が正しいか
     5) フォーマット情報（誤り訂正レベル＝M／マスク番号）が正しく書けているか

   使い方（このフォルダで）:  node qr-self-test.js
   ※ Node.js だけで動きます。外部ライブラリ・ネット通信は使いません。
   ========================================================================= */

const { readFileSync } = require('fs');
const path = require('path');

// --- index.html から「画面操作の手前まで」のQR生成コードを取り出して読み込む ---
const html = readFileSync(path.join(__dirname, 'index.html'), 'utf8');
const encoderScript = html
  .split('<script>')[1]
  .split('/* =========================== ここから画面の操作')[0];
eval(encoderScript); // これで generateQR(text) が使えるようになる

/* =========================================================================
   ここから下は「検証する側」。エンジンとは別に独立して実装する
   （こうすることで、エンジン側のバグがあればテストが食い違って気づける）
   ========================================================================= */

// バージョンごとの仕様（レベルM）— デコーダ側でも独立に持っておく
const SPEC = {
  1: { ec: 10, blocks: [16] },
  2: { ec: 16, blocks: [28] },
  3: { ec: 26, blocks: [44] },
  4: { ec: 18, blocks: [32, 32] },
  5: { ec: 24, blocks: [43, 43] },
  6: { ec: 16, blocks: [27, 27, 27, 27] },
};
const ALIGN_POS = { 2: 18, 3: 22, 4: 26, 5: 30, 6: 34 };

// マスク条件（エンジンと同じ定義。読み戻すには同じ計算が必要）
function maskCond(mask, r, c) {
  switch (mask) {
    case 0: return (r + c) % 2 === 0;
    case 1: return r % 2 === 0;
    case 2: return c % 3 === 0;
    case 3: return (r + c) % 3 === 0;
    case 4: return (Math.floor(r / 2) + Math.floor(c / 3)) % 2 === 0;
    case 5: return ((r * c) % 2) + ((r * c) % 3) === 0;
    case 6: return (((r * c) % 2) + ((r * c) % 3)) % 2 === 0;
    case 7: return (((r + c) % 2) + ((r * c) % 3)) % 2 === 0;
  }
}

// 機能パターン（位置検出・タイミング・フォーマット予約など）の場所マップを作る
function buildFunc(version) {
  const size = 4 * version + 17;
  const func = Array.from({ length: size }, () => new Array(size).fill(false));
  const mark = (r, c) => { if (r >= 0 && r < size && c >= 0 && c < size) func[r][c] = true; };
  const finder = (top, left) => { for (let r = -1; r <= 7; r++) for (let c = -1; c <= 7; c++) mark(top + r, left + c); };
  finder(0, 0); finder(0, size - 7); finder(size - 7, 0);
  for (let i = 8; i < size - 8; i++) { mark(6, i); mark(i, 6); }
  const ap = ALIGN_POS[version];
  if (ap !== undefined) for (let r = -2; r <= 2; r++) for (let c = -2; c <= 2; c++) mark(ap + r, ap + c);
  mark(size - 8, 8);
  for (let i = 0; i <= 8; i++) { mark(8, i); mark(i, 8); }
  for (let i = 0; i < 8; i++) { mark(8, size - 1 - i); mark(size - 1 - i, 8); }
  return { func, size };
}

// データを並べた順番（ジグザグ）をそのままたどる＝エンジンと同じ順序で読む
function* dataCells(size, func) {
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right = 5;
    for (let v = 0; v < size; v++) {
      for (let c = 0; c < 2; c++) {
        const col = right - c;
        const upward = ((right + 1) & 2) === 0;
        const row = upward ? size - 1 - v : v;
        if (func[row][col]) continue;
        yield [row, col];
      }
    }
  }
}

// フォーマット情報を読み取って、誤り訂正レベルとマスク番号を取り出す
function readFormat(modules) {
  const g = (r, c) => (modules[r][c] ? 1 : 0);
  const b = [];
  for (let i = 0; i <= 5; i++) b[i] = g(8, i);
  b[6] = g(8, 7); b[7] = g(8, 8); b[8] = g(7, 8);
  for (let i = 9; i < 15; i++) b[i] = g(14 - i, 8);
  let val = 0;
  for (let i = 0; i < 15; i++) val |= b[i] << i;
  val ^= 0x5412;                 // 生成時のXORを元に戻す
  const data5 = val >> 10;       // 上位5ビットが本体（下位10ビットはBCH誤り訂正）
  return { ecl: data5 >> 3, mask: data5 & 0b111 };
}

// QR（true=黒のマス目）を読み戻して、元の文字列・モード・マスクを取り出す
function decodeQR(qr) {
  const { modules, size, version } = qr;
  const { func } = buildFunc(version);
  const { ecl, mask } = readFormat(modules);

  // マスクを外す（同じ条件でもう一度XORすれば元に戻る）
  const m = modules.map(row => row.slice());
  for (let r = 0; r < size; r++) for (let c = 0; c < size; c++) {
    if (func[r][c]) continue;
    if (maskCond(mask, r, c)) m[r][c] = !m[r][c];
  }

  // ジグザグ順にビットを読み、8ビットずつまとめて符号語（バイト）にする
  const bits = [];
  for (const [r, c] of dataCells(size, func)) bits.push(m[r][c] ? 1 : 0);

  const { ec, blocks } = SPEC[version];
  const sumData = blocks.reduce((a, b) => a + b, 0);
  const total = sumData + ec * blocks.length;
  const cw = [];
  for (let i = 0; i < total; i++) {
    let v = 0;
    for (let j = 0; j < 8; j++) v = (v << 1) | (bits[i * 8 + j] || 0);
    cw.push(v);
  }

  // インターリーブ（並べ替え）を元に戻す：データ部・誤り訂正部それぞれ
  const interData = cw.slice(0, sumData);
  const interEC = cw.slice(sumData);
  const dataBlocks = blocks.map(() => []);
  const ecBlocks = blocks.map(() => []);
  let di = 0;
  for (let i = 0; i < Math.max(...blocks); i++)
    for (let k = 0; k < blocks.length; k++) if (i < blocks[k]) dataBlocks[k].push(interData[di++]);
  let ei = 0;
  for (let i = 0; i < ec; i++)
    for (let k = 0; k < blocks.length; k++) ecBlocks[k].push(interEC[ei++]);

  // データ符号語をブロック順につなげて、中身を読む
  const concat = [].concat(...dataBlocks);
  let bp = 0;
  const read = n => { let v = 0; for (let i = 0; i < n; i++) { const byte = concat[bp >> 3]; const bit = (byte >> (7 - (bp & 7))) & 1; v = (v << 1) | bit; bp++; } return v; };
  const mode = read(4);          // 0b0100 = バイトモード
  const count = read(8);         // 文字数（バイト）
  const bytes = [];
  for (let i = 0; i < count; i++) bytes.push(read(8));
  const text = new TextDecoder().decode(Uint8Array.from(bytes));

  return { mode, ecl, mask, text, dataBlocks, ecBlocks };
}

// --- 誤り訂正符号（リード・ソロモン）の独立チェック用：GF(256)の掛け算 ---
const EXP = [], LOG = [];
(() => { let x = 1; for (let i = 0; i < 255; i++) { EXP[i] = x; LOG[x] = i; x <<= 1; if (x & 0x100) x ^= 0x11d; } })();
const gmul = (a, b) => (a === 0 || b === 0) ? 0 : EXP[(LOG[a] + LOG[b]) % 255];

// 生成多項式（degree次）を独立に作る
function genPoly(degree) {
  let p = [1];
  for (let i = 0; i < degree; i++) {
    const np = new Array(p.length + 1).fill(0);
    for (let j = 0; j < p.length; j++) { np[j] ^= p[j]; np[j + 1] ^= gmul(p[j], EXP[i]); }
    p = np;
  }
  return p; // 高次→低次（先頭が最高次=1）
}

// 「データ＋誤り訂正」が生成多項式で割り切れる（余り0）か確認する
// ＝ 正しいQRが満たすべき数学的な性質。スキャナはこれを使って読み取る。
function isDivisible(block, degree) {
  const gen = genPoly(degree);
  const res = block.slice();
  for (let i = 0; i < block.length - degree; i++) {
    const coef = res[i];
    if (coef !== 0) for (let j = 0; j < gen.length; j++) res[i + j] ^= gmul(gen[j], coef);
  }
  return res.slice(res.length - degree).every(v => v === 0);
}

/* ============================ テスト実行 ============================ */
let pass = 0, fail = 0;
function check(name, cond, detail = '') {
  if (cond) { pass++; console.log('  ✓ ' + name); }
  else { fail++; console.log('  ✗ ' + name + (detail ? '  → ' + detail : '')); }
}

console.log('\n=== Day 9 QRコード 自己テスト ===\n');

// 1) 往復テスト：生成 → 読み戻し → 元の文字列と一致するか
console.log('[1] 往復テスト（生成したQRを読み戻して元の文字列と一致するか）');
const roundTripCases = [
  'HELLO WORLD',
  'https://github.com/',
  'https://example.com/path?a=1&b=2',
  '日本語のテスト文字列です',          // UTF-8（マルチバイト）
  'Mixed 日本語 and ABC 123!',
  'a',
];
for (const text of roundTripCases) {
  const qr = generateQR(text);
  if (!qr) { check(`"${text}"`, false, '生成できなかった'); continue; }
  const d = decodeQR(qr);
  const ok = d.text === text && d.mode === 0b0100 && d.ecl === 0;
  check(`"${text}" (ver${qr.version})`, ok, ok ? '' : `読み戻し="${d.text}" mode=${d.mode} ecl=${d.ecl}`);
}

// 2) 誤り訂正符号（リード・ソロモン）が割り切れるか
console.log('\n[2] 誤り訂正符号の数学的な正しさ（割り切れる＝余り0）');
for (const text of ['HELLO WORLD', 'https://github.com/', 'A'.repeat(106)]) {
  const qr = generateQR(text);
  const d = decodeQR(qr);
  const { ec } = SPEC[qr.version];
  let allOk = true;
  d.dataBlocks.forEach((db, k) => { if (!isDivisible(db.concat(d.ecBlocks[k]), ec)) allOk = false; });
  check(`"${text.length > 20 ? text.slice(0, 20) + '…' : text}" (ver${qr.version}, ${d.dataBlocks.length}ブロック)`, allOk);
}

// 3) バージョン自動選択の境界
console.log('\n[3] バージョン自動選択の境界（文字数 → 期待バージョン）');
const boundaries = [
  [14, 1], [15, 2], [26, 2], [27, 3], [42, 3], [43, 4],
  [62, 4], [63, 5], [84, 5], [85, 6], [106, 6], [107, null],
];
for (const [len, expected] of boundaries) {
  const qr = generateQR('A'.repeat(len));
  const got = qr ? qr.version : null;
  check(`${len}バイト → ver${expected === null ? 'なし(長すぎ)' : expected}`, got === expected, `実際=${got === null ? 'なし' : 'ver' + got}`);
}

// 4) フォーマット情報（誤り訂正レベル＝M、マスクは0〜7のどれか）
console.log('\n[4] フォーマット情報（誤り訂正レベルM・マスク番号）');
for (const text of ['HELLO WORLD', 'https://github.com/']) {
  const qr = generateQR(text);
  const f = readFormat(qr.modules);
  check(`"${text}" ecl=M(0) mask=${f.mask}`, f.ecl === 0 && f.mask >= 0 && f.mask <= 7, `ecl=${f.ecl} mask=${f.mask}`);
}

// --- 結果まとめ ---
console.log(`\n=== 結果: ${pass} 件成功 / ${fail} 件失敗 ===\n`);
process.exit(fail === 0 ? 0 : 1);
