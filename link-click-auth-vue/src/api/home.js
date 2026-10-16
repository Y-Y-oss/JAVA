/**
 * 首页 / 档案相关接口（对应后端 ArchiveController: /api/archives）
 *
 * 说明：原先前端预留的 /api/search、/api/home/memories 在真实后端中并不存在，
 * 真实后端用 /api/archives 提供「时光档案」数据。这里统一改为对接真实接口。
 * 登录态由 request 层自动携带 Authorization 头，无需手动传 token。
 */
import { get } from './request'

/**
 * 我的档案列表（需登录）  GET /api/archives?page=1&size=10
 * @param {number} page 页码，从 1 开始
 * @param {number} size 每页条数
 * @returns { data: { total, page, size, records: Archive[] } }
 *          Archive 字段：id, userId, title, content, archiveDate(yyyy-MM-dd),
 *          tag, visibility(0仅自己/1公开), createTime, updateTime
 */
export function fetchArchives(page = 1, size = 8) {
  return get('/archives', { page, size })
}

/**
 * 公开档案墙（无需登录）  GET /api/archives/public?page=1&size=10
 * @returns { data: { total, page, size, records: Archive[] } }
 */
export function fetchPublicArchives(page = 1, size = 8) {
  return get('/archives/public', { page, size })
}

/**
 * 档案详情  GET /api/archives/{id}（需登录，只能看自己的或公开到档案墙的）
 * @returns { data: Archive }
 */
export function getArchive(id) {
  return get('/archives/' + id)
}

/**
 * 搜索我的档案（需登录）  GET /api/archives/search?q=关键字&page=1&size=50
 * 后端按 标题/内容/标签/时光节点 模糊匹配，仅返回当前用户自己的档案。
 * 返回结构与 fetchArchives 一致：{ total, page, size, keyword, records: Archive[] }
 */
export function searchArchives(q, page = 1, size = 50) {
  return get('/archives/search', { q, page, size })
}

/**
 * 搜索公开档案墙（无需登录）  GET /api/archives/public/search?q=关键字&page=1&size=10
 * 跨所有用户公开（visibility=1）档案，返回带 username 的记录。
 * 返回结构：{ total, page, size, keyword, records: { id,userId,username,title,content,archiveDate,tag,... }[] }
 */
export function searchPublicArchives(q, page = 1, size = 8) {
  return get('/archives/public/search', { q, page, size })
}
