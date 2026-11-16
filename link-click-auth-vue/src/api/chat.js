/**
 * 好友聊天接口（对应后端 ChatController: /api/chat）
 * 登录态由 request 层自动携带 Authorization 头。
 */
import { get, post } from './request'

/**
 * 会话总览：每个好友的最近一条消息 + 未读数 + 资料
 * GET /api/chat/conversations
 * → [{ friendId, username, nickname, avatar, lastContent, lastTime, unread }]
 */
export function fetchConversations() {
  return get('/chat/conversations')
}

/** 未读消息总数（导航栏红点轮询用）  GET /api/chat/unread → { total } */
export function fetchUnread() {
  return get('/chat/unread')
}

/**
 * 与某好友的聊天记录（每次拉取自动标记已读）
 * GET /api/chat/{friendId}/messages?beforeId=0 → [{ id, senderId, content, createTime, username, nickname, avatar }]
 */
export function fetchHistory(friendId, beforeId = 0) {
  return get(`/chat/${friendId}/messages`, { beforeId })
}

/** 发送私信  POST /api/chat/{friendId}/messages {content} */
export function sendMessage(friendId, content) {
  return post(`/chat/${friendId}/messages`, { content })
}

/** 标记某好友发来的消息为已读  POST /api/chat/{friendId}/read → { unread } */
export function markRead(friendId) {
  return post(`/chat/${friendId}/read`)
}
