/**
 * 登录会话存储：accessToken / refreshToken / 用户信息
 *
 * 「记住我」→ localStorage（关浏览器也保留）；
 * 不勾     → sessionStorage（关掉标签页即失效）。
 * 两种存储同一 key，读取时 localStorage 优先，清的时候两边都清。
 */

const KEY = 'lc_session'

/**
 * 保存登录返回的会话数据
 * @param {object} data 后端 /auth/login 返回的 data
 * @param {boolean} remember 是否「记住我」
 */
export function saveSession(data, remember) {
  const payload = {
    accessToken: data.accessToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn,
    refreshExpiresIn: data.refreshExpiresIn,
    user: {
      id: data.id,
      username: data.username,
      phone: data.phone,
      nickname: data.nickname,
      role: data.role
    },
    savedAt: Date.now()
  }
  clearSession()
  const store = remember ? localStorage : sessionStorage
  store.setItem(KEY, JSON.stringify(payload))
}

/** 读取会话；没有或数据损坏时返回 null */
export function loadSession() {
  const raw = localStorage.getItem(KEY) || sessionStorage.getItem(KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch (err) {
    clearSession()
    return null
  }
}

/** 取当前访问令牌；未登录返回空串 */
export function getAccessToken() {
  const s = loadSession()
  return s && s.accessToken ? s.accessToken : ''
}

/** 退出登录 / 凭证失效时调用 */
export function clearSession() {
  localStorage.removeItem(KEY)
  sessionStorage.removeItem(KEY)
}
