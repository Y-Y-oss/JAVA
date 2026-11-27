/**
 * 每款小游戏一套独立的视觉主题。
 * 通过 GameFrame 注入到弹窗根节点，CSS 变量会自然继承到游戏组件内部，
 * 让按钮 / 状态文字 / 高亮色跟着各自主题变化，不再"八款游戏一个样"。
 */
export const GAME_THEMES = {
  maze: {
    name: '时空迷宫',
    vibe: '赛博时空',
    main: '#2ff5c8',
    second: '#0bb8e6',
    accent: '#a6ffe8',
    rgb: '47, 245, 200',
    ink: '#041f1f',
    bg: 'linear-gradient(160deg, rgba(6, 42, 44, .96), rgba(6, 16, 34, .98))',
    ambient: 'grid'
  },
  breakout: {
    name: '打砖块',
    vibe: '熔岩霓虹',
    main: '#ff8a3d',
    second: '#ff2e7e',
    accent: '#ffd166',
    rgb: '255, 138, 61',
    ink: '#2c0a16',
    bg: 'linear-gradient(160deg, rgba(52, 10, 28, .96), rgba(24, 7, 22, .98))',
    ambient: 'embers'
  },
  memory: {
    name: '记忆翻牌',
    vibe: '樱花幻境',
    main: '#ff8ad8',
    second: '#a06bff',
    accent: '#ffd6ef',
    rgb: '255, 138, 216',
    ink: '#2a0c2a',
    bg: 'linear-gradient(160deg, rgba(48, 12, 46, .96), rgba(20, 9, 38, .98))',
    ambient: 'petals'
  },
  '2048': {
    name: '2048',
    vibe: '鎏金数字',
    main: '#ffd166',
    second: '#ff8f3d',
    accent: '#fff2b8',
    rgb: '255, 209, 102',
    ink: '#2c1c05',
    bg: 'linear-gradient(160deg, rgba(50, 32, 8, .96), rgba(24, 16, 10, .98))',
    ambient: 'digits'
  },
  mines: {
    name: '扫雷',
    vibe: '战术雷达',
    main: '#ff6b6b',
    second: '#ffb347',
    accent: '#ffc9a3',
    rgb: '255, 107, 107',
    ink: '#2a0d0d',
    bg: 'linear-gradient(160deg, rgba(48, 14, 16, .96), rgba(22, 10, 12, .98))',
    ambient: 'radar'
  },
  slide: {
    name: '数字华容道',
    vibe: '极光冰川',
    main: '#7ad7ff',
    second: '#7a8cff',
    accent: '#ccf4ff',
    rgb: '122, 215, 255',
    ink: '#061f2e',
    bg: 'linear-gradient(160deg, rgba(7, 36, 54, .96), rgba(8, 14, 38, .98))',
    ambient: 'ice'
  },
  snake: {
    name: '贪吃蛇',
    vibe: '生物荧光',
    main: '#4dffb8',
    second: '#8a5cff',
    accent: '#d4ff8a',
    rgb: '77, 255, 184',
    ink: '#04241a',
    bg: 'linear-gradient(160deg, rgba(6, 44, 32, .96), rgba(8, 12, 34, .98))',
    ambient: 'energy'
  },
  gomoku: {
    name: '五子棋',
    vibe: '水墨鎏金',
    main: '#ffd98a',
    second: '#c9a227',
    accent: '#fff4cc',
    rgb: '255, 217, 138',
    ink: '#241a08',
    bg: 'linear-gradient(160deg, rgba(40, 30, 10, .96), rgba(14, 12, 20, .98))',
    ambient: 'ink'
  }
}

export const DEFAULT_THEME = GAME_THEMES.maze

export function getGameTheme(key) {
  return GAME_THEMES[key] || DEFAULT_THEME
}

/** 生成注入到主题容器的 CSS 变量 */
export function themeVars(theme) {
  return {
    '--game-main': theme.main,
    '--game-second': theme.second,
    '--game-accent': theme.accent,
    '--game-rgb': theme.rgb,
    '--game-ink': theme.ink,
    '--game-bg': theme.bg,
    // 覆盖全局主题色：游戏内部按钮 / 状态 / 高亮都会随游戏变化
    '--cyan': theme.main,
    '--cyan-soft': theme.accent,
    '--purple': theme.second,
    '--magenta': theme.accent
  }
}
