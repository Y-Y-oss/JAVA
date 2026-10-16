/**
 * 认证相关接口（对应后端 AuthController: /api/auth/*）
 */
import { get, post } from './request'

/**
 * 获取图形验证码  GET /api/auth/captcha
 * @returns { data: { captchaId, image, expireSeconds, length } }
 *          image 是 data URI，直接给 <img> 用；答案只在服务端保存
 */
export function getCaptcha() {
  return get('/auth/captcha')
}

/**
 * 用户注册  POST /api/auth/register
 * @param {{username:string,password:string,confirmPassword:string,captchaId:string,captchaCode:string,phone?:string}} payload
 *        phone 选填，留空即不绑定手机号
 */
export function register(payload) {
  return post('/auth/register', payload)
}

/**
 * 用户登录  POST /api/auth/login
 * @param {{account:string,password:string}} payload account 支持用户名或手机号
 * @returns { data: { accessToken, refreshToken, tokenType, expiresIn, refreshExpiresIn,
 *                    id, username, phone, nickname, role } }
 *          后端对「账号不存在 / 密码错误 / 账号禁用」统一返回"账号或密码错误"（防账号枚举）
 */
export function login(payload) {
  return post('/auth/login', payload)
}

/**
 * 退出登录  POST /api/auth/logout
 * 需要 Authorization 头（由 request 层自动携带）。
 * 后端会把 accessToken 加入黑名单，并吊销该用户全部刷新令牌。
 */
export function logout() {
  return post('/auth/logout')
}

/**
 * 获取当前登录用户信息  GET /api/auth/profile
 * 需要 Authorization 头。用于页面刷新后恢复登录态。
 */
export function profile() {
  return get('/auth/profile')
}

/**
 * 发送短信验证码  GET /api/auth/send-code?phone=xxx
 * 注册流程已改用图形验证码，此接口保留给重置密码等场景。
 * @returns { data: { phone, expireSeconds, resendSeconds, code } }
 *          code 仅在后端 auth.sms.debug=true（演示模式）时返回
 */
export function sendCode(phone) {
  return get('/auth/send-code', { phone })
}
