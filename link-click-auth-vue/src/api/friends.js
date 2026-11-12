/**
 * 好友接口（对应后端 FriendController: /api/friends）
 * 登录态由 request 层自动携带 Authorization 头。
 */
import { get, post, del } from './request'

/**
 * 申请添加好友（需登录，对方验证后才成为好友）  POST /api/friends/apply
 * @param {string} username 对方用户名
 */
export function applyFriend(username) {
  return post('/friends/apply', { username })
}

/** 同意好友申请（只能处理发给自己的）  POST /api/friends/apply/{id}/accept */
export function acceptFriend(id) {
  return post(`/friends/apply/${id}/accept`)
}

/** 拒绝好友申请  POST /api/friends/apply/{id}/reject */
export function rejectFriend(id) {
  return post(`/friends/apply/${id}/reject`)
}

/** 我的好友列表  GET /api/friends  → [{ id, friendId, username, nickname, createTime }] */
export function fetchFriends() {
  return get('/friends')
}

/** 收到的待验证申请  GET /api/friends/pending → [{ id, userId, username, nickname, createTime }] */
export function fetchFriendRequests() {
  return get('/friends/pending')
}

/** 我发出的待验证申请  GET /api/friends/sent */
export function fetchSentRequests() {
  return get('/friends/sent')
}

/** 删除好友（双向删除）  DELETE /api/friends/{friendUserId} */
export function removeFriend(friendUserId) {
  return del(`/friends/${friendUserId}`)
}
