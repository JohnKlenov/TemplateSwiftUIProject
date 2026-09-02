const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sharp = require('sharp');
const fetch = require('node-fetch');

const storage = admin.storage();

/**
 * processTrackThumbnail
 * ------------------------------------------------------------
 * Идеальный алгоритм (как в коллаже):
 * - пытается взять maxresdefault
 * - если доступен — использует его
 * - центрирует изображение
 * - заполняет квадрат 720×720 через fit:'cover'
 * - гарантированно убирает любые боковые полосы
 */

exports.processTrackThumbnail = functions.https.onCall(async (data, context) => {
  const videoId = data.videoId;
  const thumbnailURL = data.thumbnailURL;

  if (!videoId || !thumbnailURL) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'videoId и thumbnailURL обязательны'
    );
  }

  try {
    // Попытка взять maxresdefault
    let finalUrl = thumbnailURL;

    if (thumbnailURL.includes('i.ytimg.com') && thumbnailURL.includes('hqdefault')) {
      const maxUrl = thumbnailURL.replace('hqdefault', 'maxresdefault');
      try {
        const r = await fetch(maxUrl);
        if (r.ok) finalUrl = maxUrl;
      } catch (_) {
        // ignore
      }
    }

    const response = await fetch(finalUrl);
    if (!response.ok) {
      throw new Error(`Не удалось скачать thumbnail: ${finalUrl}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    let inputBuffer = Buffer.from(arrayBuffer);

    // Убираем альфу
    inputBuffer = await sharp(inputBuffer)
      .flatten({ background: { r: 0, g: 0, b: 0 } })
      .toBuffer();

    const meta = await sharp(inputBuffer).metadata();
    const minSide = Math.min(meta.width, meta.height);
    const tileSize = 720;
    const needsUpscale = minSide < tileSize;

    // Центрированное заполнение квадрата — как в коллаже
    let finalBuffer = await sharp(inputBuffer)
      .resize(tileSize, tileSize, {
        fit: 'cover',
        position: 'centre',
        kernel: sharp.kernel.lanczos3,
        withoutEnlargement: false
      })
      .jpeg({ quality: 92, chromaSubsampling: '4:4:4' })
      .toBuffer();

    if (needsUpscale) {
      finalBuffer = await sharp(finalBuffer)
        .sharpen(0.5, 0.5, 0.02)
        .jpeg({ quality: 92 })
        .toBuffer();
    }

    const bucket = storage.bucket();
    const filePath = `track-thumbnails/${videoId}.jpg`;
    const file = bucket.file(filePath);

    await file.save(finalBuffer, {
      contentType: 'image/jpeg',
      metadata: { cacheControl: 'public,max-age=31536000' }
    });

    const publicUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
      `${encodeURIComponent(filePath)}?alt=media`;

    return { thumbnailURL: publicUrl };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Ошибка обработки thumbnail'
    );
  }
});
