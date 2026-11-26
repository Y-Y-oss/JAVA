/**
 * 游戏成绩本地存储（localStorage），纯前端、不依赖后端。
 * 每个游戏一条记录，字段由各游戏自定义；大厅只负责读取展示。
 * 统一字段约定：
 *   bestScore / bestTime / bestMoves  最佳成绩
 *   maxLevel                          最高到达关卡
 *   clears                            累计通关次数
 *   lastPlayed                        最后游玩时间戳
 */
const PREFIX = 'lc_game_'

export function getRecord(key) {
  try {
    const raw = localStorage.getItem(PREFIX + key)
    const obj = raw ? JSON.parse(raw) : {}
    return obj && typeof obj === 'object' ? obj : {}
  } catch (_) {
    return {}
  }
}

export function getAllRecords(keys) {
  const out = {}
  for (const k of keys) out[k] = getRecord(k)
  return out
}

export function saveRecord(key, patch) {
  const next = { ...getRecord(key), ...patch, lastPlayed: Date.now() }
  try {
    localStorage.setItem(PREFIX + key, JSON.stringify(next))
  } catch (_) { /* 隐私模式 / 配额满，忽略即可，不影响游玩 */ }
  return next
}

/** 标记一次通关：累计次数 + 可选的成绩补丁 */
export function markClear(key, patch = {}) {
  const cur = getRecord(key)
  return saveRecord(key, { clears: (cur.clears || 0) + 1, ...patch })
}

/** 数值型最佳成绩更新：mode = 'max' 越大越好 / 'min' 越小越好 */
export function updateBest(key, field, value, mode = 'max') {
  const cur = getRecord(key)
  const old = cur[field]
  if (old == null || (mode === 'min' ? value < old : value > old)) {
    return saveRecord(key, { [field]: value })
  }
  return cur
}

export function formatDuration(sec) {
  const s = Math.max(0, Math.floor(sec || 0))
  const m = Math.floor(s / 60)
  return m > 0 ? `${m}:${String(s % 60).padStart(2, '0')}` : `${s}s`
}
