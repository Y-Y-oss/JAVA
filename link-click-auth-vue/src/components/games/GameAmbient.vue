<script setup>
/**
 * 每款游戏专属的氛围特效层（纯装饰，pointer-events:none）。
 * 八套动画语言完全不同：星轨 / 余烬 / 花瓣 / 数字雨 / 雷达 / 冰晶 / 能量流 / 水墨。
 */
defineProps({ theme: { type: String, default: 'grid' } })

const seq = (n) => Array.from({ length: n }, (_, i) => i)
const rnd = (a, b, i) => {
  const x = Math.sin((i + 1) * 91.7) * 10000
  return a + (x - Math.floor(x)) * (b - a)
}

// 预生成散布粒子，位置固定，只靠 CSS 动，避免每帧重排
const motes = seq(30).map((i) => ({
  left: rnd(0, 100, i),
  top: rnd(0, 100, i + 80),
  size: rnd(2, 6, i + 12),
  delay: rnd(0, 4, i + 33),
  dur: rnd(2.4, 5.2, i + 51)
}))
const digits = seq(22).map((i) => ({
  left: rnd(0, 100, i),
  delay: rnd(0, 3.6, i + 9),
  dur: rnd(2.2, 4.4, i + 21),
  size: rnd(11, 20, i + 41),
  text: [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048][i % 11]
}))
const petals = seq(18).map((i) => ({
  left: rnd(0, 100, i),
  delay: rnd(0, 4.5, i + 7),
  dur: rnd(3.4, 6.2, i + 19),
  size: rnd(9, 17, i + 29)
}))
const embers = seq(26).map((i) => ({
  left: rnd(0, 100, i),
  delay: rnd(0, 4, i + 11),
  dur: rnd(2.6, 5.4, i + 23),
  size: rnd(2, 5, i + 37)
}))

const moteStyle = (m) => ({
  left: m.left + '%', top: m.top + '%', width: m.size + 'px', height: m.size + 'px',
  animationDelay: m.delay + 's', animationDuration: m.dur + 's'
})
const digitStyle = (d) => ({
  left: d.left + '%', fontSize: d.size + 'px',
  animationDelay: d.delay + 's', animationDuration: d.dur + 's'
})
const petalStyle = (p) => ({
  left: p.left + '%', fontSize: p.size + 'px',
  animationDelay: p.delay + 's', animationDuration: p.dur + 's'
})
const emberStyle = (e) => ({
  left: e.left + '%', width: e.size + 'px', height: e.size + 'px',
  animationDelay: e.delay + 's', animationDuration: e.dur + 's'
})
</script>

<template>
  <div class="amb" :class="'amb-' + theme" aria-hidden="true">
    <!-- 🌀 迷宫：透视星轨网格 + 漂移光点 -->
    <template v-if="theme === 'grid'">
      <div class="grid-floor"></div>
      <div class="grid-horizon"></div>
      <i v-for="(m, i) in motes" :key="'g' + i" class="g-mote" :style="moteStyle(m)"></i>
    </template>

    <!-- 🔥 打砖块：上升余烬 + 横向激光扫线 -->
    <template v-else-if="theme === 'embers'">
      <div class="ember-glow"></div>
      <i v-for="(m, i) in embers" :key="'e' + i" class="ember" :style="emberStyle(m)"></i>
      <div class="ember-beam"></div>
    </template>

    <!-- 🌸 记忆翻牌：樱花飘落 + 旋转菱形光环 -->
    <template v-else-if="theme === 'petals'">
      <div class="petal-halo"></div>
      <span v-for="(m, i) in petals" :key="'p' + i" class="petal" :style="petalStyle(m)">✿</span>
    </template>

    <!-- 🔢 2048：金色数字雨 + 底部光柱 -->
    <template v-else-if="theme === 'digits'">
      <div class="digit-pillar"></div>
      <span v-for="(m, i) in digits" :key="'n' + i" class="digit" :style="digitStyle(m)">{{ m.text }}</span>
    </template>

    <!-- 💣 扫雷：雷达扫描扇 + 同心环 -->
    <template v-else-if="theme === 'radar'">
      <div class="radar-orbit"></div>
      <div class="radar-sweep"></div>
      <div class="radar-scan"></div>
    </template>

    <!-- ❄️ 华容道：极光波 + 漂浮冰晶 -->
    <template v-else-if="theme === 'ice'">
      <div class="aurora"></div>
      <i v-for="(m, i) in motes.slice(0, 20)" :key="'i' + i" class="shard" :style="moteStyle(m)"></i>
    </template>

    <!-- 🐍 贪吃蛇：流动能量带 + 荧光孢子 -->
    <template v-else-if="theme === 'energy'">
      <i v-for="n in 3" :key="'b' + n" class="energy-band" :style="{ '--n': n }"></i>
      <i v-for="(m, i) in motes" :key="'s' + i" class="mote" :style="moteStyle(m)"></i>
    </template>

    <!-- ⚫ 五子棋：水墨涟漪 + 鎏金沉浮 -->
    <template v-else-if="theme === 'ink'">
      <i v-for="n in 4" :key="'r' + n" class="ink-ring" :style="{ '--n': n }"></i>
      <div class="ink-wash"></div>
      <i v-for="(m, i) in motes" :key="'k' + i" class="gold-dust" :style="moteStyle(m)"></i>
    </template>
  </div>
</template>

<style scoped>
.amb {
  position: absolute; inset: 0; z-index: 0; overflow: hidden;
  pointer-events: none; border-radius: inherit; opacity: .85;
}

/* 🌀 迷宫：时空网格 */
.grid-floor {
  position: absolute; left: -20%; right: -20%; bottom: -42%; height: 92%;
  background-image:
    linear-gradient(rgba(var(--game-rgb), .35) 1px, transparent 1px),
    linear-gradient(90deg, rgba(var(--game-rgb), .35) 1px, transparent 1px);
  background-size: 44px 44px;
  transform: perspective(340px) rotateX(66deg);
  transform-origin: bottom center;
  animation: floorFlow 5s linear infinite;
  mask-image: linear-gradient(to top, #000 10%, transparent 78%);
}
.grid-horizon {
  position: absolute; left: 10%; right: 10%; top: 38%; height: 2px;
  background: linear-gradient(90deg, transparent, var(--game-main), transparent);
  box-shadow: 0 0 30px 6px rgba(var(--game-rgb), .35);
  animation: horizonPulse 3s ease-in-out infinite;
}
@keyframes floorFlow { to { background-position: 0 44px, 44px 0 } }
@keyframes horizonPulse { 0%, 100% { opacity: .45 } 50% { opacity: 1 } }
.g-mote {
  position: absolute; border-radius: 50%; background: var(--game-accent);
  box-shadow: 0 0 8px var(--game-main);
  animation: moteDrift var(--g-dur, 4s) ease-in-out infinite alternate;
}
@keyframes moteDrift {
  0% { opacity: .12; transform: translate3d(0, 0, 0) scale(.6) }
  100% { opacity: .9; transform: translate3d(-14px, -22px, 0) scale(1.5) }
}

/* 🔥 打砖块：余烬 */
.ember-glow {
  position: absolute; left: 50%; bottom: -34%; width: 80%; height: 70%; margin-left: -40%;
  background: radial-gradient(ellipse, rgba(255, 138, 61, .38), transparent 68%);
  filter: blur(24px); animation: emberPulse 2.6s ease-in-out infinite;
}
@keyframes emberPulse { 0%, 100% { opacity: .45 } 50% { opacity: 1 } }
.ember {
  position: absolute; bottom: -10px; border-radius: 50% 50% 40% 40%;
  background: linear-gradient(180deg, var(--game-accent), var(--game-second));
  box-shadow: 0 0 10px var(--game-main);
  animation: emberRise var(--g-dur, 4s) linear infinite;
}
@keyframes emberRise {
  0% { transform: translateY(0) scale(.7); opacity: 0 }
  14% { opacity: 1 }
  100% { transform: translateY(-620px) translateX(28px) scale(.1); opacity: 0 }
}
.ember-beam {
  position: absolute; left: -30%; top: 30%; width: 160%; height: 2px;
  background: linear-gradient(90deg, transparent, var(--game-accent), transparent);
  box-shadow: 0 0 18px 3px rgba(255, 46, 126, .5);
  animation: beamSweep 4.5s ease-in-out infinite;
}
@keyframes beamSweep { 0%, 100% { transform: translateY(-120px) skewY(-6deg); opacity: 0 } 50% { transform: translateY(180px) skewY(4deg); opacity: .85 } }

/* 🌸 记忆翻牌：花瓣 */
.petal-halo {
  position: absolute; left: 50%; top: 50%; width: 300px; height: 300px; margin: -150px 0 0 -150px;
  border: 2px dashed rgba(255, 138, 216, .3); border-radius: 50%;
  box-shadow: 0 0 60px rgba(160, 107, 255, .18), inset 0 0 60px rgba(255, 138, 216, .12);
  animation: haloSpin 18s linear infinite;
}
@keyframes haloSpin { to { transform: rotate(360deg) scale(1.06) } }
.petal {
  position: absolute; top: -24px; color: var(--game-main);
  text-shadow: 0 0 12px var(--game-main), 0 0 24px rgba(160, 107, 255, .6);
  animation: petalFall var(--g-dur, 4s) linear infinite;
}
@keyframes petalFall {
  0% { transform: translate3d(0, -30px, 0) rotate(0deg); opacity: 0 }
  12% { opacity: .95 }
  88% { opacity: .95 }
  100% { transform: translate3d(70px, 540px, 0) rotate(560deg); opacity: 0 }
}

/* 🔢 2048：数字雨 */
.digit-pillar {
  position: absolute; left: 50%; bottom: -30%; width: 160px; height: 90%; margin-left: -80px;
  background: linear-gradient(to top, rgba(255, 209, 102, .3), transparent);
  filter: blur(26px); animation: emberPulse 3s ease-in-out infinite;
}
.digit {
  position: absolute; top: -40px; font-weight: 900; color: var(--game-main);
  text-shadow: 0 0 14px rgba(255, 209, 102, .75);
  animation: digitFall var(--g-dur, 3s) linear infinite;
}
@keyframes digitFall {
  0% { transform: translateY(-40px) rotate(-14deg); opacity: 0 }
  10% { opacity: .85 }
  85% { opacity: .85 }
  100% { transform: translateY(560px) rotate(20deg); opacity: 0 }
}

/* 💣 扫雷：雷达 */
.radar-orbit {
  position: absolute; left: 50%; top: 50%; width: 330px; height: 330px; margin: -165px 0 0 -165px;
  border-radius: 50%;
  border: 1px solid rgba(255, 107, 107, .28);
  box-shadow: inset 0 0 0 56px rgba(255, 107, 107, .035), inset 0 0 0 112px rgba(255, 107, 107, .03);
  animation: emberPulse 3.2s ease-in-out infinite;
}
.radar-sweep {
  position: absolute; left: 50%; top: 50%; width: 165px; height: 165px;
  transform-origin: 0 0;
  background: conic-gradient(from 0deg, rgba(255, 107, 107, .42), transparent 72deg);
  animation: radarSpin 3.6s linear infinite;
}
@keyframes radarSpin { to { transform: rotate(360deg) } }
.radar-scan {
  position: absolute; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, transparent, var(--game-main), transparent);
  box-shadow: 0 0 14px var(--game-second);
  animation: scanDown 4.2s linear infinite;
}
@keyframes scanDown { from { top: -2px; opacity: 0 } 12%, 88% { opacity: .8 } to { top: 100%; opacity: 0 } }

/* ❄️ 华容道：极光 + 冰晶 */
.aurora {
  position: absolute; left: -40%; top: -20%; width: 180%; height: 130%;
  background: linear-gradient(110deg, transparent 12%, rgba(122, 215, 255, .18) 34%, rgba(122, 140, 255, .22) 52%, rgba(204, 244, 255, .16) 68%, transparent 88%);
  filter: blur(22px); animation: auroraMove 6s ease-in-out infinite;
}
@keyframes auroraMove { 0%, 100% { transform: translateX(-8%) skewY(-5deg) } 50% { transform: translateX(8%) skewY(5deg) } }
.shard {
  position: absolute; background: linear-gradient(135deg, rgba(204, 244, 255, .9), rgba(122, 140, 255, .2));
  clip-path: polygon(50% 0, 100% 50%, 50% 100%, 0 50%);
  animation: shardFloat var(--g-dur, 4s) ease-in-out infinite alternate;
}
@keyframes shardFloat {
  0% { opacity: .1; transform: translateY(18px) rotate(0deg) }
  100% { opacity: .85; transform: translateY(-26px) rotate(160deg) }
}

/* 🐍 贪吃蛇：能量带 */
.energy-band {
  position: absolute; left: -30%; width: 160%; height: 30px;
  top: calc(18% + var(--n) * 26%);
  background: linear-gradient(90deg, transparent, var(--game-main), var(--game-second), transparent);
  background-size: 200% 100%; filter: blur(10px); opacity: .5;
  animation: energyFlow 3.4s linear infinite, energyWave 2.8s ease-in-out infinite;
  animation-delay: calc(var(--n) * -.6s);
}
@keyframes energyFlow { from { background-position: 200% 0 } to { background-position: -20% 0 } }
@keyframes energyWave { 0%, 100% { transform: translateX(-20px) skewX(-12deg) } 50% { transform: translateX(20px) skewX(12deg) } }
.mote {
  position: absolute; border-radius: 50%; background: var(--game-accent);
  box-shadow: 0 0 10px var(--game-main);
  animation: moteUp var(--g-dur, 4s) linear infinite;
}
@keyframes moteUp { 0% { transform: translateY(20px); opacity: 0 } 20% { opacity: .9 } 100% { transform: translateY(-380px); opacity: 0 } }

/* ⚫ 五子棋：水墨涟漪 */
.ink-wash {
  position: absolute; left: 50%; top: 50%; width: 380px; height: 380px; margin: -190px 0 0 -190px;
  background: radial-gradient(circle, rgba(255, 217, 138, .18) 0%, rgba(201, 162, 39, .07) 40%, transparent 68%);
  filter: blur(10px); animation: emberPulse 4s ease-in-out infinite;
}
.ink-ring {
  position: absolute; left: 50%; top: 50%; width: 120px; height: 120px; margin: -60px 0 0 -60px;
  border: 1px solid rgba(255, 217, 138, .55); border-radius: 50%;
  animation: inkRipple 4.8s ease-out calc(var(--n) * -1.2s) infinite;
}
@keyframes inkRipple {
  0% { transform: scale(.35); opacity: 0 }
  18% { opacity: .85 }
  100% { transform: scale(3.2); opacity: 0 }
}
.gold-dust {
  position: absolute; border-radius: 50%; background: var(--game-main);
  box-shadow: 0 0 10px var(--game-accent);
  animation: dustFloat var(--g-dur, 4s) ease-in-out infinite alternate;
}
@keyframes dustFloat {
  0% { opacity: .1; transform: translateY(24px) scale(.6) }
  100% { opacity: .95; transform: translateY(-22px) scale(1.45) }
}
</style>
