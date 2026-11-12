/**
 * 用户资料接口（头像上传等）
 */
import { uploadFile } from './request'

/**
 * 上传头像（需登录）  POST /api/auth/avatar  (multipart/form-data)
 * 服务端保存到 uploads/avatars/ 并写回用户资料。
 * @param {File} file 图片文件（png/jpg/webp/gif，≤5MB）
 * @returns { data: { url } } 头像相对路径
 */
export function uploadAvatar(file) {
  return uploadFile('/auth/avatar', file)
}
