/**
 * 社区互动接口（点赞 / 收藏 / 评论，对应后端 SocialController: /api/social）
 * 登录态由 request 层自动携带 Authorization 头。
 */
import { get, post, del } from './request'

/**
 * 点赞 / 取消点赞（切换，需登录）  POST /api/social/archives/{id}/like
 * @returns { data: { liked: boolean, likeCount: number } }
 */
export function toggleLike(archiveId) {
  return post(`/social/archives/${archiveId}/like`)
}

/**
 * 收藏 / 取消收藏（切换，需登录）  POST /api/social/archives/{id}/favorite
 * @returns { data: { favorited: boolean, favoriteCount: number } }
 */
export function toggleFavorite(archiveId) {
  return post(`/social/archives/${archiveId}/favorite`)
}

/**
 * 互动状态汇总（无需登录；带 token 额外返回我是否赞过/藏过）
 * GET /api/social/archives/{id}/interaction
 * @returns { data: { likeCount, favoriteCount, commentCount, liked, favorited } }
 */
export function getInteraction(archiveId) {
  return get(`/social/archives/${archiveId}/interaction`)
}

/**
 * 评论列表（无需登录，带评论人用户名，按时间升序）
 * GET /api/social/archives/{id}/comments
 * @returns { data: [{ id, archiveId, userId, username, content, createTime }] }
 */
export function fetchComments(archiveId) {
  return get(`/social/archives/${archiveId}/comments`)
}

/**
 * 发表评论（需登录，≤500 字）  POST /api/social/archives/{id}/comments
 * @returns { data: 刚发表的完整评论（带 username） }
 */
export function addComment(archiveId, content) {
  return post(`/social/archives/${archiveId}/comments`, { content })
}

/**
 * 删除自己的评论（需登录）  DELETE /api/social/comments/{commentId}
 */
export function deleteComment(commentId) {
  return del(`/social/comments/${commentId}`)
}
