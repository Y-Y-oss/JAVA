/**
 * 用户资料接口（头像上传、修改昵称等）
 */
import { uploadFile, put } from './request'

/**
 * 上传头像（需登录）  POST /api/auth/avatar  (multipart/form-data)
 * 服务端保存到 uploads/avatars/ 并写回用户资料。
 * @param {File} file 图片文件（png/jpg/webp/gif，≤5MB）
 * @returns { data: { url } } 头像相对路径
 */
export function uploadAvatar(file) {
  return uploadFile('/auth/avatar', file)
}

/**
 * 修改个人资料（当前后端只开放昵称）  PUT /api/auth/profile
 * @param {string} nickname 昵称，1-50 位
 * @returns { data: 更新后的用户资料 }
 */
export function updateProfile(nickname) {
  return put('/auth/profile', { nickname })
}
