<script setup>
/**
 * 主题化胜利舞台（纯装饰层，pointer-events:none）
 * 每款游戏一个主题，动画语言完全不同，避免所有游戏胜利时"长一个样"：
 *   space     时光迷宫   —— 时空隧道 / 旋转星环 / 星点漂移
 *   numbers   2048       —— 金色数字雨 / 底部光柱
 *   cards     记忆翻牌   —— 花瓣飘落 / 虚线旋转环
 *   grid      扫雷       —— 安全格波浪点亮 / 横向扫描线
 *   rainbow   数字华容道 —— 彩虹扫过 / 方块依次归位弹跳
 *   fireworks 打砖块     —— 四组循环绽放的烟花
 *   snake     贪吃蛇     —— 彩虹流光带 / 光点雨
 */
defineProps({ theme: { type: String, default: 'space' } })

const R = (n, fn) => Array.from({ length: n }, (_, i) => fn(i))
const COLORS = ['#2de2e6', '#7af5f7', '#8a5cff', '#ff48c4', '#ffd166', '#ffffff']
const rnd = (a, b) => (a + Math.random() * (b - a)).toFixed(2)

const nums = R(26, (i) => ({
  left: (i * 41 + Math.random() * 28) % 100,
  delay: rnd(0, 3.2),
  dur: rnd(2, 3.8),
  size: 12 + (i % 4) * 5,
  text: [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048][i % 11]
}))
const dots = R(38, (i) => ({
  left: (i * 31 + Math.random() * 40) % 100,
  top: (i * 23 + Math.random() * 70) % 100,
  size: 1.5 + Math.random() * 2.6,
  delay: rnd(0, 2.8),
  dur: rnd(1.4, 3.2),
  color: COLORS[i % COLORS.length]
}))
const petals = R(20, (i) => ({
  left: (i * 47 + Math.random() * 30) % 100,
  delay: rnd(0, 3.4),
  dur: rnd(2.6, 4.6),
  size: 10 + (i % 4) * 4,
  color: COLORS[i % COLORS.length]
}))

function dotStyle(d) {
  return {
    left: d.left + '%', top: d.top + '%', width: d.size + 'px', height: d.size + 'px',
    background: d.color, boxShadow: `0 0 8px 1px ${d.color}`,
    animationDelay: d.delay + 's', animationDuration: d.dur + 's'
  }
}
function numStyle(n) {
  return { left: n.left + '%', fontSize: n.size + 'px', animationDelay: n.delay + 's', animationDuration: n.dur + 's' }
}
function petalStyle(p) {
  return { left: p.left + '%', fontSize: p.size + 'px', color: p.color, animationDelay: p.delay + 's', animationDuration: p.dur + 's' }
}
</script>

<template>
  <div class="ws" :class="'ws-' + theme">
    <!-- 🌀 时空隧道：旋转星环 + 星点 -->
    <template v-if="theme === 'space'">
      <div class="sp-vortex"></div>
      <i v-for="n in 4" :key="'r' + n" class="sp-ring" :style="{ '--n': n }"></i>
      <span v-for="(d, i) in dots" :key="'d' + i" class="sp-dot" :style="dotStyle(d)"></span>
    </template>

    <!-- 🔢 金色数字雨 -->
    <template v-else-if="theme === 'numbers'">
      <div class="nb-pillar"></div>
      <span v-for="(n, i) in nums" :key="'n' + i" class="nb-num" :style="numStyle(n)">{{ n.text }}</span>
    </template>

    <!-- 🃏 花瓣 + 旋转虚线环 -->
    <template v-else-if="theme === 'cards'">
      <div class="cd-halo"></div>
      <i v-for="n in 2" :key="'h' + n" class="cd-ring" :style="{ '--n': n }"></i>
      <span v-for="(p, i) in petals" :key="'p' + i" class="cd-petal" :style="petalStyle(p)">✦</span>
    </template>

    <!-- 💣 网格波浪点亮 + 扫描线 -->
    <template v-else-if="theme === 'grid'">
      <div class="gd-cells"><i v-for="n in 100" :key="n" :style="{ '--n': n }"></i></div>
      <div class="gd-scan"></div>
    </template>

    <!-- 🧩 彩虹扫过 + 方块归位弹跳 -->
    <template v-else-if="theme === 'rainbow'">
      <div class="rb-sweep"></div>
      <div class="rb-tiles"><i v-for="n in 16" :key="n" :style="{ '--n': n }"></i></div>
    </template>

    <!-- 🧱 四组循环烟花 -->
    <template v-else-if="theme === 'fireworks'">
      <div v-for="f in 4" :key="'f' + f" class="fw-burst" :class="'fw-' + f">
        <i v-for="n in 12" :key="n" :style="{ '--n': n }"></i>
      </div>
    </template>

    <!-- 🐍 彩虹流光带 + 光点雨 -->
    <template v-else-if="theme === 'snake'">
      <i v-for="n in 3" :key="'b' + n" class="sk-band" :style="{ '--n': n }"></i>
      <span v-for="(d, i) in dots" :key="'d' + i" class="sk-dot" :style="dotStyle(d)"></span>
    </template>
  </div>
</template>

<style scoped>
.ws {
  position: absolute; inset: 0; z-index: 1; overflow: hidden;
  pointer-events: none; border-radius: inherit;
}

/* ===== 🌀 space：时空隧道 ===== */
.ws-space { background: radial-gradient(circle at 50% 48%, rgba(45, 226, 230, .16), transparent 62%); }
.sp-vortex {
  position: absolute; top: 50%; left: 50%; width: 260px; height: 260px; margin: -130px 0 0 -130px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(122, 245, 247, .28) 0%, rgba(138, 92, 255, .12) 40%, transparent 70%);
  animation: vortexPulse 3s ease-in-out infinite;
}
@keyframes vortexPulse { 0%, 100% { transform: scale(.75); opacity: .6 } 50% { transform: scale(1.25); opacity: 1 } }
.sp-ring {
  position: absolute; top: 50%; left: 50%; width: 240px; height: 240px; margin: -120px 0 0 -120px;
  border-radius: 50%; border: 1px solid rgba(122, 245, 247, .5);
  box-shadow: 0 0 18px rgba(45, 226, 230, .35), inset 0 0 18px rgba(138, 92, 255, .25);
  transform: rotateX(calc(58deg + var(--n) * 8deg)) rotateY(calc(var(--n) * 22deg));
  animation: spSpin calc(5s + var(--n) * 1.4s) linear infinite;
}
@keyframes spSpin { to { transform: rotateX(65deg) rotateZ(360deg) } }
.sp-dot { position: absolute; border-radius: 50%; animation: spDrift ease-in-out infinite alternate; }
@keyframes spDrift { 0% { opacity: .15; transform: scale(.5) translate(0, 0) } 100% { opacity: 1; transform: scale(1.6) translate(-12px, -18px) } }

/* ===== 🔢 numbers：金色数字雨 ===== */
.ws-numbers { background: radial-gradient(ellipse at 50% 100%, rgba(255, 209, 102, .22), transparent 62%); }
.nb-pillar {
  position: absolute; left: 50%; bottom: -20%; width: 150px; height: 90%; margin-left: -75px;
  background: linear-gradient(180deg, transparent, rgba(255, 209, 102, .28), transparent);
  filter: blur(22px); animation: nbGlow 2.4s ease-in-out infinite;
}
@keyframes nbGlow { 0%, 100% { opacity: .4 } 50% { opacity: 1 } }
.nb-num {
  position: absolute; top: -40px; font-weight: 900; color: #ffd166;
  text-shadow: 0 0 12px rgba(255, 209, 102, .8), 0 0 26px rgba(255, 143, 61, .5);
  animation: nbFall linear infinite;
}
@keyframes nbFall {
  0% { transform: translateY(-40px) rotate(-18deg); opacity: 0 }
  12% { opacity: 1 }
  85% { opacity: 1 }
  100% { transform: translateY(500px) rotate(24deg); opacity: 0 }
}

/* ===== 🃏 cards：花瓣 + 虚线环 ===== */
.ws-cards { background: radial-gradient(circle at 50% 45%, rgba(255, 72, 196, .14), transparent 64%); }
.cd-halo {
  position: absolute; top: 50%; left: 50%; width: 260px; height: 260px; margin: -130px 0 0 -130px;
  border-radius: 50%; background: radial-gradient(circle, rgba(138, 92, 255, .22), transparent 68%);
  animation: vortexPulse 3.2s ease-in-out infinite;
}
.cd-ring {
  position: absolute; top: 50%; left: 50%; width: 220px; height: 220px; margin: -110px 0 0 -110px;
  border-radius: 50%; border: 2px dashed rgba(122, 245, 247, .45);
  animation: cdSpin calc(6s + var(--n) * 3s) linear infinite;
}
.ws-cards .cd-ring:nth-of-type(2) { animation-direction: reverse; border-color: rgba(255, 72, 196, .4); width: 170px; height: 170px; margin: -85px 0 0 -85px; }
@keyframes cdSpin { to { transform: rotate(360deg) scale(1.04) } }
.cd-petal { position: absolute; top: -30px; animation: cdFloat linear infinite; text-shadow: 0 0 10px currentColor; }
@keyframes cdFloat {
  0% { transform: translate3d(0, -30px, 0) rotate(0deg); opacity: 0 }
  12% { opacity: 1 }
  88% { opacity: 1 }
  100% { transform: translate3d(50px, 470px, 0) rotate(540deg); opacity: 0 }
}

/* ===== 💣 grid：安全格波浪点亮 ===== */
.ws-grid { background: rgba(6, 14, 30, .28); }
.gd-cells { position: absolute; inset: 12%; display: grid; grid-template-columns: repeat(10, 1fr); grid-template-rows: repeat(10, 1fr); gap: 3px; }
.gd-cells i {
  border-radius: 2px; background: rgba(45, 226, 230, .08);
  animation: gdLight 2.6s ease-in-out calc(var(--n) * 24ms) infinite;
}
@keyframes gdLight { 0%, 70%, 100% { background: rgba(45, 226, 230, .08); box-shadow: none } 12% { background: rgba(45, 226, 230, .85); box-shadow: 0 0 12px rgba(45, 226, 230, .8) } }
.gd-scan {
  position: absolute; left: 0; right: 0; height: 3px;
  background: linear-gradient(90deg, transparent, #7af5f7, transparent);
  box-shadow: 0 0 18px #2de2e6; animation: gdScan 3s linear infinite;
}
@keyframes gdScan { from { top: -3px; opacity: 0 } 10%, 90% { opacity: .9 } to { top: 100%; opacity: 0 } }

/* ===== 🧩 rainbow：彩虹扫过 + 方块弹跳 ===== */
.ws-rainbow { background: rgba(8, 10, 28, .25); }
.rb-sweep {
  position: absolute; top: -20%; left: -60%; width: 40%; height: 140%;
  background: linear-gradient(100deg, transparent, rgba(45, 226, 230, .3), rgba(138, 92, 255, .3), rgba(255, 72, 196, .3), transparent);
  filter: blur(6px); transform: skewX(-18deg); animation: rbSweep 3.4s ease-in-out infinite;
}
@keyframes rbSweep { 0% { left: -60% } 100% { left: 140% } }
.rb-tiles { position: absolute; left: 50%; top: 50%; width: 176px; height: 176px; margin: -88px 0 0 -88px;
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; }
.rb-tiles i {
  border-radius: 4px; background: rgba(122, 245, 247, .14);
  animation: rbPop 2.4s ease-in-out calc(var(--n) * 90ms) infinite;
}
@keyframes rbPop { 0%, 60%, 100% { transform: scale(1); background: rgba(122, 245, 247, .14) } 20% { transform: scale(1.22); background: rgba(45, 226, 230, .8); box-shadow: 0 0 14px rgba(45, 226, 230, .7) } }

/* ===== 🧱 fireworks：四组循环烟花 ===== */
.ws-fireworks { background: radial-gradient(circle at 50% 50%, rgba(255, 72, 196, .1), transparent 70%); }
.fw-burst { position: absolute; width: 0; height: 0; }
.fw-1 { left: 28%; top: 32%; } .fw-2 { left: 72%; top: 28%; animation-delay: -1.1s; }
.fw-3 { left: 34%; top: 74%; animation-delay: -2s; } .fw-4 { left: 74%; top: 70%; animation-delay: -2.8s; }
.fw-burst i {
  position: absolute; left: 0; top: 0; width: 7px; height: 7px; border-radius: 50%;
  background: var(--fc, #ffd166); box-shadow: 0 0 12px var(--fc, #ffd166);
  animation: fwBurst 2.6s ease-out infinite;
}
.fw-1 i { --fc: #2de2e6 } .fw-2 i { --fc: #ff48c4 } .fw-3 i { --fc: #ffd166 } .fw-4 i { --fc: #8a5cff }
@keyframes fwBurst {
  0% { transform: rotate(calc(var(--n) * 30deg)) translateX(0) scale(.2); opacity: 0 }
  12% { opacity: 1 }
  70% { transform: rotate(calc(var(--n) * 30deg)) translateX(72px) scale(1); opacity: 1 }
  100% { transform: rotate(calc(var(--n) * 30deg)) translateX(96px) scale(.1); opacity: 0 }
}

/* ===== 🐍 snake：彩虹流光带 + 光点雨 ===== */
.ws-snake { background: radial-gradient(ellipse at 50% 50%, rgba(138, 92, 255, .12), transparent 70%); }
.sk-band {
  position: absolute; left: -30%; width: 160%; height: 26px;
  background: linear-gradient(90deg, #2de2e6, #8a5cff, #ff48c4, #ffd166, #2de2e6);
  background-size: 200% 100%; filter: blur(9px); opacity: .55;
  top: calc(22% + var(--n) * 26%);
  animation: skFlow 3.6s linear infinite, skWave 2.8s ease-in-out infinite;
  animation-delay: calc(var(--n) * -.7s);
}
@keyframes skFlow { from { background-position: 200% 0 } to { background-position: -20% 0 } }
@keyframes skWave { 0%, 100% { transform: translateX(-24px) skewX(-12deg) } 50% { transform: translateX(24px) skewX(12deg) } }
.sk-dot { position: absolute; border-radius: 50%; animation: skRain linear infinite; }
@keyframes skRain { 0% { transform: translateY(-20px); opacity: 0 } 15% { opacity: 1 } 100% { transform: translateY(460px); opacity: 0 } }
</style>
