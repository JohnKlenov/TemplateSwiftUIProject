/**
 * generatePlaylistCover — Cover‑only (без усиленного зума)
 * ------------------------------------------------------------
 * - Каждое изображение масштабируется в квадрат 720×720 с fit='cover'
 * - Используется центрирование (centre) для надёжного заполнения
 * - При апскейле мелких картинок добавляется лёгкое sharpen
 * - 2×2 коллаж без зазоров
 * - Мягкая виньетка как в YouTube Music
 * - Public URL (без signed URL, подходит для обложек)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sharp = require('sharp');
const fetch = require('node-fetch');

const storage = admin.storage();

exports.generatePlaylistCover = functions.https.onCall(async (data, context) => {
  const playlistId = data.playlistId;
  const urls = data.thumbnailURLs;

  console.log('=== generatePlaylistCover (Cover only) START ===');
  console.log('playlistId:', playlistId);
  console.log('thumbnailURLs:', urls);

  if (!playlistId || !Array.isArray(urls) || urls.length !== 4) {
    console.error('Неверные аргументы');
    throw new functions.https.HttpsError(
      'invalid-argument',
      'playlistId и ровно 4 thumbnailURLs обязательны'
    );
  }

  try {
    // 1) Скачиваем изображения
    console.log('Скачиваем 4 изображения...');
    const buffers = [];

    for (const url of urls) {
      console.log('Скачиваем:', url);

      // Попытка взять maxresdefault для YouTube
      let finalUrl = url;
      if (url.includes('i.ytimg.com') && url.includes('hqdefault')) {
        const maxUrl = url.replace('hqdefault', 'maxresdefault');
        try {
          const r = await fetch(maxUrl);
          if (r.ok) {
            console.log('Используем maxresdefault');
            finalUrl = maxUrl;
          }
        } catch (e) {
          console.log('maxresdefault не доступен, используем hqdefault');
        }
      }

      const res = await fetch(finalUrl);
      if (!res.ok) {
        console.error('Ошибка скачивания:', finalUrl);
        throw new Error(`Не удалось скачать thumbnail: ${finalUrl}`);
      }
      const arrayBuffer = await res.arrayBuffer();
      buffers.push(Buffer.from(arrayBuffer));
    }

    console.log('Все 4 изображения скачаны');

    // 2) Преобразуем каждое в квадрат 720×720 (cover, никакого лишнего зума)
    console.log('Преобразование в квадраты 720x720 (cover + центрирование)...');
    const tileSize = 720;
    const tiles = [];

    for (let i = 0; i < buffers.length; i++) {
      console.log(`Обработка изображения ${i + 1}`);

      let img = sharp(buffers[i]);

      // Удаляем альфа-канал (если есть) — иначе прозрачность покажет чёрный фон
      img = img.flatten({ background: { r: 0, g: 0, b: 0 } });

      const meta = await img.metadata();
      const minSide = Math.min(meta.width, meta.height);
      const needsUpscale = minSide < tileSize;

      let tileBuf = await img
        .resize(tileSize, tileSize, {
          fit: 'cover', // заполняет квадрат полностью, обрезая лишнее
          position: 'centre', // надёжное центрирование
          kernel: sharp.kernel.lanczos3,
          withoutEnlargement: false // разрешаем увеличение
        })
        .jpeg({ quality: 92, chromaSubsampling: '4:4:4' })
        .toBuffer();

      // Лёгкое sharpen после апскейла
      if (needsUpscale) {
        tileBuf = await sharp(tileBuf)
          .sharpen(0.5, 0.5, 0.02)
          .jpeg({ quality: 92 })
          .toBuffer();
        console.log(`Изображение ${i + 1} было апскейлено (${minSide}px → ${tileSize}px)`);
      }

      // Финальная проверка размера (на всякий случай)
      const check = await sharp(tileBuf).metadata();
      if (check.width !== tileSize || check.height !== tileSize) {
        tileBuf = await sharp(tileBuf)
          .resize(tileSize, tileSize, { fit: 'fill' })
          .jpeg({ quality: 92 })
          .toBuffer();
      }

      tiles.push(tileBuf);
    }

    console.log('Все тайлы готовы');

    // 3) Собираем 2x2 коллаж 1440x1440
    console.log('Собираем коллаж 1440x1440...');
    const collageWidth = tileSize * 2;
    const collageHeight = tileSize * 2;

    const base = sharp({
      create: {
        width: collageWidth,
        height: collageHeight,
        channels: 3,
        background: { r: 0, g: 0, b: 0 }
      }
    });

    const composite = [
      { input: tiles[0], left: 0, top: 0 },
      { input: tiles[1], left: tileSize, top: 0 },
      { input: tiles[2], left: 0, top: tileSize },
      { input: tiles[3], left: tileSize, top: tileSize }
    ];

    let collageBuffer = await base
      .composite(composite)
      .jpeg({ quality: 92, progressive: true })
      .toBuffer();

    console.log('Коллаж собран');

    // 4) Мягкая виньетка (как YouTube Music)
    console.log('Добавляем мягкую виньетку...');
    const vignetteSVG = `
      <svg width="${collageWidth}" height="${collageHeight}">
        <radialGradient id="v" cx="50%" cy="50%" r="70%">
          <stop offset="60%" stop-color="black" stop-opacity="0"/>
          <stop offset="100%" stop-color="black" stop-opacity="0.22"/>
        </radialGradient>
        <rect width="100%" height="100%" fill="url(#v)"/>
      </svg>
    `;

    const vignetteBuffer = Buffer.from(vignetteSVG);

    collageBuffer = await sharp(collageBuffer)
      .composite([{ input: vignetteBuffer, blend: 'over' }])
      .jpeg({ quality: 92 })
      .toBuffer();

    console.log('Виньетка применена');

    // 5) Сохраняем в Storage
    const bucket = storage.bucket();
    const filePath = `covers/${playlistId}.jpg`;
    const file = bucket.file(filePath);

    console.log('Сохраняем файл в Storage:', filePath);

    await file.save(collageBuffer, {
      contentType: 'image/jpeg',
      metadata: { cacheControl: 'public,max-age=31536000' }
    });

    console.log('Файл сохранён в Storage');

    // 6) Public URL (вместо signed URL, подходит для обложек)
    console.log('Генерируем публичный URL...');
    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media`;

    console.log('Public URL:', publicUrl);
    console.log('=== generatePlaylistCover END ===');

    return { coverImageURL: publicUrl };
  } catch (err) {
    console.error('generatePlaylistCover error:', err);
    throw new functions.https.HttpsError('internal', err.message || 'Ошибка генерации cover');
  }
});
