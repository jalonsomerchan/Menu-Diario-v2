const MAX_IMAGE_WIDTH = 500
const JPEG_QUALITY = 0.82

function loadImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const image = new Image()
    image.onload = () => {
      URL.revokeObjectURL(url)
      resolve(image)
    }
    image.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('No se pudo leer la imagen seleccionada.'))
    }
    image.src = url
  })
}

async function getImageDimensions(file) {
  if (typeof createImageBitmap === 'function') {
    try {
      const bitmap = await createImageBitmap(file)
      const { width, height } = bitmap
      return { source: bitmap, width, height }
    } catch {
      // Fall back to HTMLImageElement for formats not supported by createImageBitmap.
    }
  }

  const image = await loadImage(file)
  return { source: image, width: image.naturalWidth, height: image.naturalHeight }
}

export async function compressPhoto(file) {
  const { source, width, height } = await getImageDimensions(file)
  if (!width || !height) throw new Error('La imagen seleccionada no tiene un tamaño válido.')

  const scale = Math.min(1, MAX_IMAGE_WIDTH / width)
  const canvas = document.createElement('canvas')
  canvas.width = Math.max(1, Math.round(width * scale))
  canvas.height = Math.max(1, Math.round(height * scale))
  const context = canvas.getContext('2d')
  if (!context) throw new Error('No se pudo preparar la imagen para subirla.')
  context.drawImage(source, 0, 0, canvas.width, canvas.height)
  source.close?.()

  const blob = await new Promise((resolve, reject) => {
    canvas.toBlob(
      (result) => result ? resolve(result) : reject(new Error('No se pudo comprimir la imagen.')),
      'image/jpeg',
      JPEG_QUALITY,
    )
  })
  const name = `${file.name.replace(/\.[^.]+$/, '') || 'foto'}.jpg`
  return new File([blob], name, { type: 'image/jpeg', lastModified: Date.now() })
}
