/**
 * 时光档案的视觉工具：封面配色 / 标签图标 / 封面图 / 可见性文案 / 主题色。
 * 首页、时间线、相册、社区 四个页面共用，保证视觉统一、避免重复代码。
 *
 * 关于「不要纯色块」：
 * - 有封面图（id 命中 ARCHIVE_COVER）→ 用真实影像；
 * - 无封面图 → 由 ArchiveCard 渲染「多层渐变 + 标签大图标 + 漂浮装饰」的插画式封面，
 *   绝不是平铺的纯色/渐变方块。
 */

// 标签 → 封面渐变色（仅作为无图时的插画底，不单独作为卡片主视觉）
export const TAG_COLORS = {
  私语: 'linear-gradient(135deg,#2de2e6,#8a5cff)',
  信件: 'linear-gradient(135deg,#ff48c4,#8a5cff)',
  告白: 'linear-gradient(135deg,#7af5f7,#2de2e6)',
  约定: 'linear-gradient(135deg,#8a5cff,#ff48c4)'
}
export const coverColor = (tag) => TAG_COLORS[tag] || 'linear-gradient(135deg,#2de2e6,#ff48c4)'

// 标签 → 主题色（用于卡片 hover 辉光、描边、数据看板点缀）
export const TAG_ACCENT = {
  私语: '#2de2e6',
  信件: '#ff48c4',
  告白: '#7af5f7',
  约定: '#8a5cff'
}
export const tagAccent = (tag) => TAG_ACCENT[tag] || '#2de2e6'

// 标签 → 主题图标（SVG path）
export const TAG_ICONS = {
  私语: 'M4 5h16a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H10l-5 4v-4H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z',
  信件: 'M3 6h18a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z M3 7l9 6 9-6',
  告白: 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
  约定: 'M12 2l2.9 6.3 6.9.7-5.1 4.7 1.4 6.8L12 17.8 5.9 20.5l1.4-6.8L2.2 9.7l6.9-.7z'
}
export const DEFAULT_ICON = 'M4 7h3l2-2h6l2 2h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z M12 17a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z'
export const coverIcon = (tag) => TAG_ICONS[tag] || DEFAULT_ICON

// ===== 封面照片映射 =====
// 设计目标：每张档案（演示 or 用户新建）都拿到「互不相同」的封面，
// 避免社区墙 / 相册 / 首页胶片墙大量撞图、显得千篇一律。
//
// 之前的问题：用「标签/通用词」做子串匹配（如把 tag=私语 也当关键词），
// 导致所有「私语」档案都命中同一张 g1、所有「约定」命中 g5、所有「告白」命中 g2……
// 现在改为：① 标杆档案用「精确标题」匹配（绝不误伤）；② 其余按 id 取图（id 唯一 ⇒ 封面唯一）。

// 全部可用封面图（AI 生成的电影感主题图，每张互不相同，共 24 张）
export const COVER_POOL = [
  '/img/gallery/g1.png', '/img/gallery/g2.png', '/img/gallery/g3.png',
  '/img/gallery/g4.png', '/img/gallery/g5.png', '/img/gallery/g6.png',
  '/img/gallery/g7.png', '/img/gallery/g8.png', '/img/gallery/g9.png',
  '/img/gallery/g10.png', '/img/gallery/g11.png', '/img/gallery/g12.png',
  '/img/gallery/g13.png', '/img/gallery/g14.png',
  '/img/archives/1.png', '/img/archives/2.png', '/img/archives/3.png',
  '/img/archives/4.png', '/img/archives/5.png', '/img/archives/6.png',
  '/img/archives/7.png', '/img/archives/8.png', '/img/archives/9.png',
  '/img/archives/10.png'
]

// 标杆档案：精确标题 → 专属封面（与档案内容一一对应，绝不撞图）
export const CURATED_COVER = {
  '雨中私语': '/img/gallery/g1.png',
  '未寄出的信': '/img/gallery/g3.png',
  '天台上的告白': '/img/gallery/g2.png',
  '时光闭锁': '/img/gallery/g5.png',
  '平安夜的路灯': '/img/gallery/g6.png',
  '山顶看日出': '/img/gallery/g4.png',
  '旧书店的邂逅': '/img/archives/7.png',
  '情人节乌龙': '/img/gallery/g8.png',
  '毕业那年的蝉鸣': '/img/gallery/g9.png',
  '国庆骑行': '/img/archives/10.png'
}

// 档案封面：用户上传的真实照片优先；否则回退到精确语义封面 / 按 id 取图（保证互不相同）
export function coverUrl(m) {
  if (!m) return ''
  // 用户上传的封面（相对或绝对 URL），优先级最高
  if (m.cover && (m.cover.startsWith('/') || m.cover.startsWith('http'))) return m.cover
  const t = m.title
  if (t && CURATED_COVER[t]) return CURATED_COVER[t]
  const id = m.id
  if (id != null) return COVER_POOL[(Number(id) - 1) % COVER_POOL.length]
  return ''
}

// 是否有真实封面图
export const hasCover = (m) => !!coverUrl(m)

// 封面样式：有照片 → 照片+暗化渐变；无照片 → 回退渐变色（ArchiveCard 会叠加插画层）
export function coverStyle(m) {
  const url = coverUrl(m)
  if (url) {
    return {
      backgroundImage: `linear-gradient(180deg, rgba(10,14,39,.10) 0%, rgba(10,14,39,.70) 100%), url("${url}")`,
      backgroundPosition: 'center'
    }
  }
  return { background: coverColor((m && m.tag) || '') }
}

// 可见性文案：0=仅自己 1=公开到档案墙
export const visibilityText = (v) => (v === 1 ? '公开 · 档案墙' : '仅自己可见')

// 已知标签（用于分类区块顺序）
export const KNOWN_TAGS = ['私语', '信件', '告白', '约定']
