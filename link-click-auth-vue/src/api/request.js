/**
 * 统一请求封装（基于浏览器原生 fetch，不依赖 axios）
 * 后端约定返回结构：{ code: 200, message: 'xxx', data: {}, errors: {} }
 */

const BASE_URL = '/api'

/**
 * token 提供者：由 session 模块注入，request 自动携带 Authorization 头。
 * 不在本模块直接读 localStorage，保持 request 层与存储层解耦。
 */
let tokenProvider = null

export function setTokenProvider(fn) {
  tokenProvider = fn
}

class ApiError extends Error {
  constructor(message, payload = {}) {
    super(message || '请求失败')
    this.name = 'ApiError'
    this.code = payload.code
    this.data = payload.data
    this.errors = payload.errors
  }
}

/**
 * 发起请求
 * @param {string} method GET / POST
 * @param {string} url    相对路径，如 '/auth/register'
 * @param {object} params GET 查询参数
 * @param {object} body   POST 请求体（JSON）
 */
async function request(method, url, params = {}, body = null) {
  let finalUrl = BASE_URL + url

  const options = { method, headers: { Accept: 'application/json,text/plain,*/*' } }

  // 已登录时自动带上访问令牌（profile / logout 等需要鉴权的接口依赖这个）
  const token = tokenProvider ? tokenProvider() : ''
  if (token) {
    options.headers['Authorization'] = 'Bearer ' + token
  }

  if (body) {
    options.headers['Content-Type'] = 'application/json;charset=utf-8'
    options.body = JSON.stringify(body)
  } else {
    const qs = new URLSearchParams(params).toString()
    if (qs) finalUrl += (finalUrl.includes('?') ? '&' : '?') + qs
  }

  let response
  try {
    response = await fetch(finalUrl, options)
  } catch (err) {
    // 网络层失败：通常是后端没启动，或被 CORS / 代理拦截
    throw new ApiError('无法连接后端服务，请确认后端已启动（默认 http://192.168.68.14:8081）')
  }

  let text = ''
  try {
    text = await response.text()
  } catch (err) {
    text = ''
  }

  let json = null
  try {
    json = text ? JSON.parse(text) : null
  } catch (err) {
    json = null
  }

  if (!response.ok && (!json || json.code === undefined)) {
    throw new ApiError(`请求失败（HTTP ${response.status}）`)
  }

  if (!json || json.code !== 200) {
    throw new ApiError(json && json.message ? json.message : '请求失败', {
      code: json ? json.code : undefined,
      data: json ? json.data : null,
      errors: json ? json.errors : null
    })
  }

  return json
}

export const get = (url, params) => request('GET', url, params || {})
export const post = (url, body) => request('POST', url, {}, body || {})
export const put = (url, body) => request('PUT', url, {}, body || {})
export const del = (url) => request('DELETE', url)

/**
 * 上传文件（multipart/form-data），当前用于时光档案封面照片。
 * 与 request() 共用同一套错误解析与 Authorization 头注入逻辑。
 * 内部用 XMLHttpRequest 实现，以便上报真实上传进度（fetch 无法监听上传进度）。
 * @param {string} url          相对路径，如 '/archives/upload'
 * @param {File}   file         要上传的文件对象
 * @param {object} [opts]
 * @param {function} [opts.onProgress]  进度回调，参数为 0~100 的整数百分比
 */
export function uploadFile(url, file, opts = {}) {
  const finalUrl = BASE_URL + url
  const token = tokenProvider ? tokenProvider() : ''
  const form = new FormData()
  form.append('file', file)

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', finalUrl)

    if (token) xhr.setRequestHeader('Authorization', 'Bearer ' + token)

    if (opts.onProgress && typeof xhr.upload.onprogress !== 'undefined') {
      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          opts.onProgress(Math.round((e.loaded / e.total) * 100))
        }
      }
    }

    xhr.onload = () => {
      let json = null
      try {
        json = xhr.responseText ? JSON.parse(xhr.responseText) : null
      } catch (err) {
        json = null
      }
      if (xhr.status >= 200 && xhr.status < 300 && json && json.code === 200) {
        resolve(json)
      } else {
        const msg = (json && json.message) || `上传失败（HTTP ${xhr.status}）`
        reject(new ApiError(msg, {
          code: json ? json.code : xhr.status,
          data: json ? json.data : null,
          errors: json ? json.errors : null
        }))
      }
    }

    xhr.onerror = () => {
      reject(new ApiError('无法连接后端服务，请确认后端已启动（默认 http://192.168.68.14:8081）'))
    }

    xhr.send(form)
  })
}

export default { get, post, put, del, uploadFile, request }
