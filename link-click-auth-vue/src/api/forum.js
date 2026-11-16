/**
 * 论坛接口（对应后端 ForumController: /api/forum）
 * 登录态由 request 层自动携带 Authorization 头。
 */
import { get, post, del } from './request'

/**
 * 帖子列表（无需登录）
 * GET /api/forum/posts?page=1&size=20
 * → { total, page, size, records: [{ id, userId, title, content, replyCount, createTime, username, nickname, avatar }] }
 */
export function fetchPosts(page = 1, size = 20) {
  return get('/forum/posts', { page, size })
}

/** 发布帖子（需登录）  POST /api/forum/posts {title, content} → { id } */
export function createPost(title, content) {
  return post('/forum/posts', { title, content })
}

/**
 * 帖子详情 + 回复列表（无需登录）
 * GET /api/forum/posts/{id}
 * → { id, title, content, ... , replies: [{ id, userId, content, createTime, username, nickname, avatar }] }
 */
export function fetchPostDetail(id) {
  return get(`/forum/posts/${id}`)
}

/** 发表回复（需登录）  POST /api/forum/posts/{id}/replies {content} → 回复对象（含 replyCount） */
export function addReply(postId, content) {
  return post(`/forum/posts/${postId}/replies`, { content })
}

/** 删除帖子（自己的，管理员可删任意）  DELETE /api/forum/posts/{id} */
export function deletePost(postId) {
  return del(`/forum/posts/${postId}`)
}

/** 删除回复（自己的，管理员可删任意）  DELETE /api/forum/replies/{id} → { replyCount } */
export function deleteReply(replyId) {
  return del(`/forum/replies/${replyId}`)
}
