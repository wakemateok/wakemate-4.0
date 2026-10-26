const fs = require('node:fs/promises');
const path = require('node:path');
const assert = require('node:assert/strict');
const sharp = require('sharp');

const root = path.resolve(__dirname, '..');
const source = path.join(root, 'design/brand-assets-20261027');
const assets = path.join(root, 'assets/brand');
const resources = path.join(root, 'android/app/src/pvtb/res');
const qa = process.env.WAKEMATE_BRAND_QA_DIR;

async function opaqueGeometry(input) {
  const { data, info } = await sharp(input).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let left = info.width, top = info.height, right = -1, bottom = -1;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      if (data[(y * info.width + x) * 4 + 3] > 32) {
        left = Math.min(left, x); right = Math.max(right, x);
        top = Math.min(top, y); bottom = Math.max(bottom, y);
      }
    }
  }
  assert(right > left && bottom > top, 'The logo must not be blank');
  const centerX = (left + right) / 2, centerY = (top + bottom) / 2;
  let radius = 0;
  for (let y = top; y <= bottom; y++) {
    for (let x = left; x <= right; x++) {
      if (data[(y * info.width + x) * 4 + 3] > 32) {
        radius = Math.max(radius, Math.hypot(x - centerX, y - centerY));
      }
    }
  }
  return { left, top, width: right - left + 1, height: bottom - top + 1, radius };
}

async function main() {
  await fs.mkdir(assets, { recursive: true });
  const master = path.join(source, 'wakemate_symbol_master.png');
  assert((await sharp(master).metadata()).hasAlpha, 'Transparent symbol master required');
  const bounds = await opaqueGeometry(master);
  const cut = await sharp(master).extract({ left: bounds.left, top: bounds.top, width: bounds.width, height: bounds.height }).png().toBuffer();
  await sharp(cut).resize({ width: 512 }).png().toFile(path.join(assets, 'wakemate_symbol.png'));
  await sharp(path.join(source, 'wakemate_logo_master.png'))
    .trim({ background: '#FFFFFF', threshold: 18 })
    .resize({ width: 768 }).png().toFile(path.join(assets, 'wakemate_logo.png'));

  for (const [density, scale] of Object.entries({ mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 })) {
    const directory = path.join(resources, `mipmap-${density}`);
    await fs.mkdir(directory, { recursive: true });
    const size = Math.round(108 * scale);
    // Keep all nontransparent pixels, including the bean, inside Android's 66dp safe circle.
    const factor = ((66 / 108) * size / 2 - 2) / bounds.radius;
    const foreground = await sharp(cut).resize(Math.max(1, Math.floor(bounds.width * factor)), Math.max(1, Math.floor(bounds.height * factor)), { fit: 'fill' }).png().toBuffer();
    const canvas = await sharp({ create: { width: size, height: size, channels: 4, background: '#00000000' } })
      .composite([{ input: foreground, gravity: 'center' }]).png().toBuffer();
    const geometry = await opaqueGeometry(canvas);
    assert(geometry.radius < size * 66 / 108 / 2, `Adaptive safe zone exceeded at ${density}`);
    await fs.writeFile(path.join(directory, 'ic_launcher_foreground.png'), canvas);
    const { data, info } = await sharp(canvas).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    for (let i = 0; i < data.length; i += 4) data[i] = data[i + 1] = data[i + 2] = 255;
    await sharp(data, { raw: info }).png().toFile(path.join(directory, 'ic_launcher_monochrome.png'));
    const legacySize = Math.round(48 * scale);
    const legacyFactor = (legacySize * .42) / bounds.radius;
    const legacyMark = await sharp(cut).resize(Math.floor(bounds.width * legacyFactor), Math.floor(bounds.height * legacyFactor), { fit: 'fill' }).png().toBuffer();
    await sharp({ create: { width: legacySize, height: legacySize, channels: 4, background: '#FFFFFF' } })
      .composite([{ input: legacyMark, gravity: 'center' }]).png().toFile(path.join(directory, 'ic_launcher.png'));
    if (qa && density === 'xxxhdpi') {
      await fs.mkdir(qa, { recursive: true });
      const visible = await sharp(canvas).flatten({ background: '#FFFFFF' }).extract({ left: 72, top: 72, width: 288, height: 288 }).png().toBuffer();
      for (const shape of ['circle', 'rounded-square']) {
        const mask = Buffer.alloc(288 * 288 * 4);
        for (let y = 0; y < 288; y++) for (let x = 0; x < 288; x++) {
          const dx = x - 143.5, dy = y - 143.5;
          const inside = shape === 'circle'
            ? Math.hypot(dx, dy) <= 144
            : Math.hypot(Math.max(Math.abs(dx) - 92, 0), Math.max(Math.abs(dy) - 92, 0)) <= 52;
          const offset = (y * 288 + x) * 4;
          mask[offset] = mask[offset + 1] = mask[offset + 2] = 255;
          mask[offset + 3] = inside ? 255 : 0;
        }
        await sharp(visible).composite([{ input: await sharp(mask, { raw: { width: 288, height: 288, channels: 4 } }).png().toBuffer(), blend: 'dest-in' }]).png().toFile(path.join(qa, `launcher-${shape}.png`));
      }
    }
    console.log(`${density}: ${legacySize}px standard, ${size}px adaptive; safe zone OK`);
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
