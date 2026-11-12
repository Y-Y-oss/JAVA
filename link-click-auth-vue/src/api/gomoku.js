/**
 * 五子棋在线对弈接口（对应后端 GomokuController: /api/gomoku）
 * 双端通过轮询「我的对局」与「对局详情」实现同步。
 */
import { get, post } from './request'

/**
 * 邀请好友对弈（需登录且必须是好友）  POST /api/gomoku/invite
 * @param {number} friendId 好友 id
 * @param {'black'|'white'} color 我执的颜色（黑方先手）
 * @returns { data: 对局详情（含 id） }
 */
export function inviteGomoku(friendId, color) {
  return post('/gomoku/invite', { friendId, color })
}

/**
 * 我的对局列表  GET /api/gomoku/my
 * @returns { data: { toAccept: [], waiting: [], playing: [], finished: [] } }
 */
export function fetchMyGames() {
  return get('/gomoku/my')
}

/** 接受邀请（被邀请人）  POST /api/gomoku/{id}/accept → data: 对局详情 */
export function acceptGomoku(id) {
  return post(`/gomoku/${id}/accept`)
}

/** 拒绝邀请  POST /api/gomoku/{id}/decline */
export function declineGomoku(id) {
  return post(`/gomoku/${id}/decline`)
}

/** 对局详情（轮询用）  GET /api/gomoku/{id} */
export function fetchGomokuGame(id) {
  return get(`/gomoku/${id}`)
}

/** 落子  POST /api/gomoku/{id}/move {x, y} → data: 更新后的对局详情 */
export function moveGomoku(id, x, y) {
  return post(`/gomoku/${id}/move`, { x, y })
}

/** 认输  POST /api/gomoku/{id}/resign */
export function resignGomoku(id) {
  return post(`/gomoku/${id}/resign`)
}
