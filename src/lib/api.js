const configuredBase = import.meta.env.VITE_API_BASE
const defaultBase =
  typeof window !== 'undefined' && /^(localhost|127\.0\.0\.1)$/.test(window.location.hostname)
    ? 'http://localhost/OV2/api'
    : 'https://alon.one/api'
export const API_BASE = (configuredBase || defaultBase).replace(/\/$/, '')

export class ApiError extends Error {
  constructor(message, { status = 0, code = '', details = null } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
    this.details = details
  }
}

export async function apiRequest(path, token, options = {}) {
  const response = await fetch(`${API_BASE}/${path.replace(/^\//, '')}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...options.headers,
    },
  })
  const payload = await response.json().catch((reason) => {
    if (options.signal?.aborted) throw reason
    return {}
  })
  if (!response.ok || payload.ok === false) {
    const authReason = import.meta.env.DEV ? payload.details?.auth?.reason : ''
    const detail = authReason ? ` (${authReason})` : ''
    throw new ApiError(
      `${payload.message || `La API respondió con ${response.status}.`}${detail}`,
      {
        status: response.status,
        code: payload.code || '',
        details: payload.details || null,
      },
    )
  }
  return payload.data ?? payload
}

export async function getJson(path, token) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 20000)
  try {
    return await apiRequest(path, token, { signal: controller.signal })
  } catch (reason) {
    if (controller.signal.aborted) {
      throw new ApiError('El servidor está tardando demasiado. Comprueba tu conexión y vuelve a intentarlo.', { code: 'timeout' })
    }
    if (reason instanceof TypeError) {
      throw new ApiError('No se pudo conectar con el servidor. Comprueba tu conexión y vuelve a intentarlo.', { code: 'network' })
    }
    throw reason
  } finally {
    clearTimeout(timeout)
  }
}
export function postJson(path, token, body) {
  return apiRequest(path, token, { method: 'POST', body: JSON.stringify(body) })
}

export async function uploadFile(path, token, file, fields = {}) {
  const formData = new FormData()
  Object.entries(fields).forEach(([key, value]) => formData.append(key, String(value)))
  formData.append('file', file)

  const response = await fetch(`${API_BASE}/${path.replace(/^\//, '')}`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: formData,
  })
  const payload = await response.json().catch(() => ({}))
  if (!response.ok || payload.ok === false) {
    const authReason = import.meta.env.DEV ? payload.details?.auth?.reason : ''
    const detail = authReason ? ` (${authReason})` : ''
    throw new ApiError(
      `${payload.message || `La API respondió con ${response.status}.`}${detail}`,
      {
        status: response.status,
        code: payload.code || '',
        details: payload.details || null,
      },
    )
  }
  return payload.data ?? payload
}
