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

// 封面照片：按 id 对应 public/img/archives/{id}.png（AI 生成的电影感主题图）
export const ARCHIVE_COVER = {
  1: '/img/archives/1.png',
  2: '/img/archives/2.png',
  3: '/img/archives/3.png',
  4: '/img/archives/4.png',
  5: '/img/archives/5.png',
  6: '/img/archives/6.png',
  7: '/img/archives/7.png',
  8: '/img/archives/8.png',
  9: '/img/archives/9.png',
  10: '/img/archives/10.png'
}

// 是否有真实封面图（命中 ARCHIVE_COVER 且非 undefined）
export const hasCover = (m) => !!ARCHIVE_COVER[m && m.id]

// 封面样式：有照片 → 照片+暗化渐变；无照片 → 回退渐变色（ArchiveCard 会叠加插画层）
export function coverStyle(m) {
  const url = ARCHIVE_COVER[m && m.id]
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
