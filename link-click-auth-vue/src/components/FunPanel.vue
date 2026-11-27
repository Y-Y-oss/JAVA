<script setup>
import { ref, computed, inject, onBeforeUnmount } from 'vue'

/**
 * 娱乐专区 · 小玩法集市
 * 10 个纯前端互动小玩具，全部不依赖后端，点开即玩。
 */
const notify = inject('appNotify', null)
function toast(msg) { if (notify) notify(msg) }
async function copyText(text) {
  try { await navigator.clipboard.writeText(text); toast('✓ 已复制到剪贴板') }
  catch (_) { toast('复制失败，请手动选中文字') }
}

/* ============ 1. 今日运势 ============ */
const FORTUNES = [
  { level: '上上签', text: '今天宜大胆一点，想做的事就去做，好运正在路上' },
  { level: '上签', text: '会有小小的惊喜，留意身边那些不起眼的瞬间' },
  { level: '中签', text: '稳稳当当的一天，按自己的节奏来就很好' },
  { level: '小吉', text: '别急着下判断，慢半拍反而能看见更多' },
  { level: '吉', text: '适合把攒了很久的事收个尾，然后好好休息' }
]
const LUCKY_COLORS = ['#2de2e6', '#8a5cff', '#ff48c4', '#ffd166', '#7af5f7', '#7ee787']
const YI = ['整理相册', '找朋友聊聊天', '出门晒晒太阳', '把想法写下来', '重看一集番', '早点睡']
const JI = ['反复纠结', '熬夜刷手机', '空腹喝咖啡', '把话憋在心里', '临时改计划']
function localDate() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
function hashStr(s) { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return Math.abs(h) }
function makeFortune(seed, isToday) {
  return {
    ...FORTUNES[seed % FORTUNES.length],
    color: LUCKY_COLORS[(seed >> 3) % LUCKY_COLORS.length],
    num: (seed % 9) + 1,
    yi: YI[(seed >> 5) % YI.length],
    ji: JI[(seed >> 7) % JI.length],
    isToday
  }
}
const fortune = ref(makeFortune(hashStr(localDate()), true))
function drawAgain() { fortune.value = makeFortune((Math.random() * 1e9) | 0, false) }

/* ============ 2. 选择困难症救星 ============ */
const options = ref(['吃火锅', '看电影', '去散步', '继续摸鱼'])
const newOption = ref('')
const pickerResult = ref('')
const picking = ref(false)
let pickTimer = null
function addOption() {
  const v = newOption.value.trim()
  if (v && options.value.length < 12) { options.value.push(v); newOption.value = '' }
}
function removeOption(i) { if (options.value.length > 2) options.value.splice(i, 1) }
function pick() {
  if (picking.value || options.value.length < 2) return
  picking.value = true
  let ticks = 0
  if (pickTimer) clearInterval(pickTimer)
  pickTimer = setInterval(() => {
    pickerResult.value = options.value[(Math.random() * options.value.length) | 0]
    if (++ticks > 18) {
      clearInterval(pickTimer); pickTimer = null
      pickerResult.value = options.value[(Math.random() * options.value.length) | 0]
      picking.value = false
      toast('✓ 就它了，别纠结啦')
    }
  }, 70)
}

/* ============ 3. 你是时光代理人里的谁 ============ */
const QUESTIONS = [
  { q: '周末突然多出一整天，你会？', opts: [
    { t: '拉上朋友到处跑', s: { a: 2, c: 1 } }, { t: '先把计划列清楚', s: { b: 2 } },
    { t: '在家安静待着', s: { d: 2 } }, { t: '去照相馆帮忙', s: { c: 2 } } ] },
  { q: '朋友遇到麻烦，你的第一反应是？', opts: [
    { t: '马上冲过去', s: { a: 2 } }, { t: '先弄清发生了什么', s: { b: 2 } },
    { t: '先安抚情绪', s: { c: 2 } }, { t: '默默把后路准备好', s: { d: 2 } } ] },
  { q: '如果能回到过去，你最想？', opts: [
    { t: '补上那句没说出口的话', s: { a: 2 } }, { t: '修正一个关键决定', s: { b: 2 } },
    { t: '再见某人一面', s: { c: 2 } }, { t: '只看看，不改变什么', s: { d: 2 } } ] },
  { q: '团队里你通常是？', opts: [
    { t: '冲在前面的那个', s: { a: 2 } }, { t: '把控全局的那个', s: { b: 2 } },
    { t: '照顾大家的那个', s: { c: 2 } }, { t: '旁观但靠谱的那个', s: { d: 2 } } ] },
  { q: '选一件随身物品，你会带？', opts: [
    { t: '相机', s: { a: 1, c: 2 } }, { t: '笔记本', s: { b: 2 } },
    { t: '旧照片', s: { c: 1, d: 2 } }, { t: '耳机', s: { d: 2 } } ] },
  { q: '你更相信？', opts: [
    { t: '直觉，先做了再说', s: { a: 2 } }, { t: '规则和逻辑', s: { b: 2 } },
    { t: '人与人的羁绊', s: { c: 2 } }, { t: '时间自有安排', s: { d: 2 } } ] }
]
const ROLES = {
  a: { name: '程小时', emoji: '🔥', desc: '热血、直来直往，永远第一个冲出去。你相信"先做了再说"，也总能点燃身边的人。' },
  b: { name: '陆光', emoji: '❄️', desc: '冷静、克制、算无遗策。你习惯把全局看完再落子，是团队里最稳的那块压舱石。' },
  c: { name: '乔苓', emoji: '🌸', desc: '细心又温暖，总在照顾大家的情绪。照相馆因为你才有了家的味道。' },
  d: { name: '时光旅人', emoji: '🕰️', desc: '安静的观察者，看得比谁都清楚。你不急着改变什么，却总在关键时刻出现。' }
}
const quizStep = ref(0)
const quizScore = ref({ a: 0, b: 0, c: 0, d: 0 })
function answer(opt) {
  for (const k in opt.s) quizScore.value[k] += opt.s[k]
  quizStep.value++
}
function quizRestart() { quizStep.value = 0; quizScore.value = { a: 0, b: 0, c: 0, d: 0 } }
const quizResult = computed(() => {
  const top = Object.entries(quizScore.value).sort((x, y) => y[1] - x[1])[0][0]
  return ROLES[top]
})

/* ============ 4. 4-7-8 呼吸放松 ============ */
const BREATH = [{ label: '吸气', sec: 4 }, { label: '屏息', sec: 7 }, { label: '呼气', sec: 8 }]
const breathOn = ref(false)
const breathPhase = ref(0)
const breathLeft = ref(4)
const breathRounds = ref(0)
let breathTimer = null
const breathScale = computed(() => breathOn.value ? (breathPhase.value === 2 ? .78 : 1.28) : 1)
function toggleBreath() {
  if (breathOn.value) {
    breathOn.value = false
    if (breathTimer) { clearInterval(breathTimer); breathTimer = null }
  } else {
    breathOn.value = true
    breathPhase.value = 0
    breathLeft.value = BREATH[0].sec
    if (breathTimer) clearInterval(breathTimer)
    breathTimer = setInterval(() => {
      breathLeft.value--
      if (breathLeft.value <= 0) {
        breathPhase.value = (breathPhase.value + 1) % BREATH.length
        if (breathPhase.value === 0) breathRounds.value++
        breathLeft.value = BREATH[breathPhase.value].sec
      }
    }, 1000)
  }
}

/* ============ 5. 冷笑话补给站 ============ */
const JOKES = [
  '为什么照片从来不生气？因为它们都很有"涵养"，只会静静地被挂在墙上。',
  '我问时钟："你累吗？" 它说："我一直在转，但从来没走。"',
  '有一天，一块三分熟的牛排在街上走着，突然他在前方看到一块五分熟的牛排，可却没有理会他。他们为什么没打招呼？——因为他们不熟。',
  '时光代理人最怕什么？——怕客户说"就随便改一小下"。',
  '布和纸最怕什么？——不（布）怕一万，只（纸）怕万一。',
  '为什么迷宫里的人都很淡定？因为他们知道，总有出口，只是绕一点。',
  '我对日历说："你能不能慢点？" 它说："我只是替时间背锅的。"',
  '小白兔去面包店："有 100 个小面包吗？" 老板说没有。第二天又问，还是没有。第三天老板特意备了 100 个，小白兔问："有 100 个小面包吗？" 老板激动地说有！小白兔："那给我来两个。"',
  '什么锁没有孔？——迷宫的出口，得先集齐碎片才肯开。',
  '程序猿最讨厌的天气？——没有 bug 的晴天，因为不知道该干嘛。'
]
const jokeIdx = ref(0)
function nextJoke() { jokeIdx.value = (jokeIdx.value + 1 + ((Math.random() * (JOKES.length - 1)) | 0)) % JOKES.length }

/* ============ 6. 颜文字抽抽乐 ============ */
const KAOS = ['(｡•̀ᴗ-)✧', '(*´∇｀*)', '(๑>◡<๑)', '¯\\_(ツ)_/¯', '(つ﹏⊂)', '(*°▽°*)八(*°▽°*)♪', '(｡･ω･｡)ﾉ♡', '(；′⌒`)', 'ヽ(✿ﾟ▽ﾟ)ノ', '(¬‿¬ )', '(´･_･`)', '(づ｡◕‿‿◕｡)づ', '(╯°□°）╯', 'ʕ •ᴥ•ʔ', '(◕ᴗ◕✿)', '(￣▽￣")']
const kaoIdx = ref(0)
function nextKao() { kaoIdx.value = (kaoIdx.value + 1 + ((Math.random() * (KAOS.length - 1)) | 0)) % KAOS.length }

/* ============ 7. 抛硬币 & 掷骰子 ============ */
const coin = ref('')
const coinFlipping = ref(false)
const coinStats = ref({ h: 0, t: 0 })
const dice = ref(1)
const diceRolling = ref(false)
function flipCoin() {
  if (coinFlipping.value) return
  coinFlipping.value = true
  coin.value = ''
  setTimeout(() => {
    const h = Math.random() < .5
    coin.value = h ? '正面' : '反面'
    coinStats.value[h ? 'h' : 't']++
    coinFlipping.value = false
  }, 720)
}
function rollDice() {
  if (diceRolling.value) return
  diceRolling.value = true
  setTimeout(() => { dice.value = 1 + ((Math.random() * 6) | 0); diceRolling.value = false }, 620)
}

/* ============ 8. 摸鱼番茄钟 ============ */
const POMO = [5, 15, 25]
const pomoMin = ref(25)
const pomoLeft = ref(25 * 60)
const pomoOn = ref(false)
let pomoTimer = null
const pomoText = computed(() => {
  const v = pomoLeft.value
  return `${String(Math.floor(v / 60)).padStart(2, '0')}:${String(v % 60).padStart(2, '0')}`
})
function setPomo(m) {
  pomoMin.value = m
  if (pomoTimer) { clearInterval(pomoTimer); pomoTimer = null }
  pomoOn.value = false
  pomoLeft.value = m * 60
}
function togglePomo() {
  if (pomoOn.value) {
    pomoOn.value = false
    if (pomoTimer) { clearInterval(pomoTimer); pomoTimer = null }
  } else {
    if (pomoLeft.value <= 0) pomoLeft.value = pomoMin.value * 60
    pomoOn.value = true
    if (pomoTimer) clearInterval(pomoTimer)
    pomoTimer = setInterval(() => {
      pomoLeft.value--
      if (pomoLeft.value <= 0) {
        clearInterval(pomoTimer); pomoTimer = null
        pomoOn.value = false
        pomoLeft.value = 0
        toast('⏰ 时间到，起来动一动吧')
      }
    }, 1000)
  }
}
function resetPomo() { setPomo(pomoMin.value) }

/* ============ 9. 脑筋急转弯 ============ */
const RIDDLES = [
  { q: '什么东西越洗越脏？', a: '水' },
  { q: '什么门永远关不上？', a: '球门' },
  { q: '什么书买不到？', a: '遗书（也有人说：秘书）' },
  { q: '一年四季都盛开的花是什么花？', a: '塑料花' },
  { q: '什么路最窄？', a: '冤家路窄' },
  { q: '时钟什么时候不会走？', a: '它本来就不会走，只会转' },
  { q: '什么锁没有孔？', a: '迷宫里没集齐碎片的出口' },
  { q: '为什么五子棋赢了要撒彩带？', a: '因为五连值得被看见 ✦' }
]
const riddleIdx = ref(0)
const riddleRevealed = ref(false)
function nextRiddle() {
  riddleIdx.value = (riddleIdx.value + 1 + ((Math.random() * (RIDDLES.length - 1)) | 0)) % RIDDLES.length
  riddleRevealed.value = false
}

/* ============ 10. 今日心情打卡 ============ */
const MOODS = [
  { e: '😄', t: '开心' }, { e: '😌', t: '平静' }, { e: '😐', t: '一般' },
  { e: '😴', t: '好困' }, { e: '😤', t: '上头' }, { e: '🥲', t: 'emo' }
]
const moodKey = 'lc_mood_' + localDate()
const todayMood = ref(localStorage.getItem(moodKey) || '')
const moodTotal = ref(Number(localStorage.getItem('lc_mood_total') || 0))
function setMood(m) {
  if (todayMood.value) return
  todayMood.value = m.e
  localStorage.setItem(moodKey, m.e)
  moodTotal.value++
  localStorage.setItem('lc_mood_total', String(moodTotal.value))
  toast('✓ 今天的心情记下啦')
}

onBeforeUnmount(() => {
  if (pickTimer) clearInterval(pickTimer)
  if (breathTimer) clearInterval(breathTimer)
  if (pomoTimer) clearInterval(pomoTimer)
})
</script>

<template>
  <div class="play-grid">
    <!-- 1 今日运势 -->
    <section class="play-card wide">
      <div class="pc-head">
        <span class="pc-emoji">🔮</span>
        <div class="pc-hd"><h3>今日运势</h3><p>每天一支签，也可以随缘再抽一支</p></div>
        <span class="pc-tag">每日</span>
      </div>
      <div class="fortune">
        <div class="ft-level" :style="{ color: fortune.color, borderColor: fortune.color }">{{ fortune.level }}</div>
        <p class="ft-text">{{ fortune.text }}</p>
        <div class="ft-grid">
          <span>宜 <b>{{ fortune.yi }}</b></span>
          <span>忌 <b>{{ fortune.ji }}</b></span>
          <span>幸运色 <i :style="{ background: fortune.color }"></i></span>
          <span>幸运数字 <b>{{ fortune.num }}</b></span>
        </div>
        <div class="pc-row">
          <button class="pc-btn" @click="drawAgain">随缘再抽一支</button>
          <span v-if="!fortune.isToday" class="pc-hint">当前是随缘签，不是今日签</span>
        </div>
      </div>
    </section>

    <!-- 2 选择困难症救星 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">🎲</span>
        <div class="pc-hd"><h3>选择困难症救星</h3><p>把选项丢进来，让运气替你决定</p></div>
      </div>
      <div class="opt-list">
        <span v-for="(o, i) in options" :key="o + i" class="opt" @click="removeOption(i)">{{ o }} ×</span>
      </div>
      <div class="opt-add">
        <input v-model="newOption" placeholder="再加一个选项…" @keyup.enter="addOption" />
        <button @click="addOption" aria-label="添加">＋</button>
      </div>
      <div class="picker-screen" :class="{ rolling: picking }">{{ pickerResult || '？' }}</div>
      <button class="pc-btn full" :disabled="picking || options.length < 2" @click="pick">帮我决定！</button>
    </section>

    <!-- 3 角色测试 -->
    <section class="play-card wide">
      <div class="pc-head">
        <span class="pc-emoji">🎭</span>
        <div class="pc-hd"><h3>你是时光代理人里的谁</h3><p>6 道题，看看你和谁最像</p></div>
        <span class="pc-tag">性格测试</span>
      </div>
      <div v-if="quizStep < QUESTIONS.length">
        <div class="quiz-track"><i :style="{ width: (quizStep / QUESTIONS.length * 100) + '%' }"></i></div>
        <p class="quiz-q">{{ quizStep + 1 }} / {{ QUESTIONS.length }} · {{ QUESTIONS[quizStep].q }}</p>
        <div class="quiz-opts">
          <button v-for="(o, i) in QUESTIONS[quizStep].opts" :key="i" @click="answer(o)">{{ o.t }}</button>
        </div>
      </div>
      <div v-else class="quiz-result">
        <span class="qr-emoji">{{ quizResult.emoji }}</span>
        <div>
          <h4>你是「{{ quizResult.name }}」</h4>
          <p>{{ quizResult.desc }}</p>
          <button class="pc-btn ghost" @click="quizRestart">重新测一次</button>
        </div>
      </div>
    </section>

    <!-- 4 呼吸放松 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">🌬️</span>
        <div class="pc-hd"><h3>4-7-8 呼吸放松</h3><p>跟着圆环，吸 4 秒 · 屏 7 秒 · 呼 8 秒</p></div>
      </div>
      <div class="breath-wrap">
        <div class="breath-ring" :style="{ transform: 'scale(' + breathScale + ')' }">
          <span>{{ breathOn ? BREATH[breathPhase].label : '准备' }}</span>
          <b>{{ breathOn ? breathLeft : '—' }}</b>
        </div>
      </div>
      <p class="pc-center">已完成 {{ breathRounds }} 轮</p>
      <button class="pc-btn full" @click="toggleBreath">{{ breathOn ? '停止' : '开始放松' }}</button>
    </section>

    <!-- 5 冷笑话 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">😏</span>
        <div class="pc-hd"><h3>冷笑话补给站</h3><p>降温专用，笑不出来算我输</p></div>
      </div>
      <p class="joke">{{ JOKES[jokeIdx] }}</p>
      <div class="pc-row">
        <button class="pc-btn" @click="nextJoke">换一条</button>
        <button class="pc-btn ghost" @click="copyText(JOKES[jokeIdx])">复制</button>
      </div>
    </section>

    <!-- 6 颜文字 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">✧</span>
        <div class="pc-hd"><h3>颜文字抽抽乐</h3><p>随手抽一个，聊天立刻有内味</p></div>
      </div>
      <div class="kaomoji">{{ KAOS[kaoIdx] }}</div>
      <div class="pc-row">
        <button class="pc-btn" @click="nextKao">换一个</button>
        <button class="pc-btn ghost" @click="copyText(KAOS[kaoIdx])">复制</button>
      </div>
    </section>

    <!-- 7 硬币骰子 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">🪙</span>
        <div class="pc-hd"><h3>抛硬币 & 掷骰子</h3><p>把选择权交给小小的随机</p></div>
      </div>
      <div class="coin-row">
        <div class="coin" :class="{ spin: coinFlipping, heads: coin === '正面' }">{{ coin || '？' }}</div>
        <div class="dice" :class="{ roll: diceRolling }">{{ dice }}</div>
      </div>
      <p class="pc-center">正面 {{ coinStats.h }} · 反面 {{ coinStats.t }}</p>
      <div class="pc-row">
        <button class="pc-btn" @click="flipCoin">抛硬币</button>
        <button class="pc-btn ghost" @click="rollDice">掷骰子</button>
      </div>
    </section>

    <!-- 8 番茄钟 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">🍅</span>
        <div class="pc-hd"><h3>摸鱼番茄钟</h3><p>专注一小会儿，理直气壮地摸鱼</p></div>
      </div>
      <div class="pomo-time" :class="{ running: pomoOn }">{{ pomoText }}</div>
      <div class="pomo-modes">
        <button v-for="m in POMO" :key="m" :class="{ on: pomoMin === m }" @click="setPomo(m)">{{ m }} 分</button>
      </div>
      <div class="pc-row">
        <button class="pc-btn" @click="togglePomo">{{ pomoOn ? '暂停' : '开始' }}</button>
        <button class="pc-btn ghost" @click="resetPomo">重置</button>
      </div>
    </section>

    <!-- 9 脑筋急转弯 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">🧠</span>
        <div class="pc-hd"><h3>脑筋急转弯</h3><p>先自己想，再点开答案</p></div>
      </div>
      <p class="riddle-q">{{ RIDDLES[riddleIdx].q }}</p>
      <p class="riddle-a" :class="{ show: riddleRevealed }">{{ riddleRevealed ? '答：' + RIDDLES[riddleIdx].a : '答案还藏着…' }}</p>
      <div class="pc-row">
        <button class="pc-btn" @click="riddleRevealed = !riddleRevealed">{{ riddleRevealed ? '收起答案' : '揭晓答案' }}</button>
        <button class="pc-btn ghost" @click="nextRiddle">下一题</button>
      </div>
    </section>

    <!-- 10 心情打卡 -->
    <section class="play-card">
      <div class="pc-head">
        <span class="pc-emoji">💌</span>
        <div class="pc-hd"><h3>今日心情打卡</h3><p>一天一次，记下此刻的自己</p></div>
      </div>
      <div class="mood-row">
        <button
          v-for="m in MOODS" :key="m.e"
          class="mood" :class="{ on: todayMood === m.e }"
          :disabled="!!todayMood" @click="setMood(m)"
        >
          <span>{{ m.e }}</span><small>{{ m.t }}</small>
        </button>
      </div>
      <p class="pc-center">{{ todayMood ? '今天已打卡 ✓' : '点一个，记录今天的心情' }} · 累计 {{ moodTotal }} 天</p>
    </section>
  </div>
</template>

<style scoped>
.play-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(288px, 1fr)); gap: 16px; }
.play-card {
  position: relative; overflow: hidden;
  display: flex; flex-direction: column; gap: 12px; padding: 18px; border-radius: 18px;
  --toy: #2de2e6; --toy-rgb: 45, 226, 230;
  background: linear-gradient(160deg, rgba(var(--toy-rgb), .1), rgba(12, 14, 38, .72) 62%);
  border: 1px solid rgba(var(--toy-rgb), .26); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
  transition: border-color .28s, transform .28s, box-shadow .28s;
}
.play-card > * { position: relative; z-index: 1; }
.play-card::before {
  content: ''; position: absolute; z-index: 0; right: -24px; top: -24px;
  width: 140px; height: 140px; border-radius: 50%; opacity: .5;
  background: radial-gradient(circle, rgba(var(--toy-rgb), .32), transparent 68%);
  animation: toyFloat 6s ease-in-out infinite alternate;
}
@keyframes toyFloat { 0% { transform: translate(0, 0) scale(.9) } 100% { transform: translate(-18px, 22px) scale(1.15) } }
.play-card:hover {
  border-color: rgba(var(--toy-rgb), .75); transform: translateY(-3px);
  box-shadow: 0 20px 46px rgba(var(--toy-rgb), .22), inset 0 0 28px rgba(var(--toy-rgb), .07);
}
.play-card.wide { grid-column: span 2; }
@media (max-width: 760px) { .play-card.wide { grid-column: span 1; } }

/* 10 个小玩具：各自配色 + 不同纹理 */
.play-card:nth-child(1) { --toy: #b39cff; --toy-rgb: 179, 156, 255; }
.play-card:nth-child(2) { --toy: #ffd166; --toy-rgb: 255, 209, 102; }
.play-card:nth-child(3) { --toy: #ff8ad8; --toy-rgb: 255, 138, 216; }
.play-card:nth-child(4) { --toy: #2ff5c8; --toy-rgb: 47, 245, 200; }
.play-card:nth-child(5) { --toy: #ff9a5c; --toy-rgb: 255, 154, 92; }
.play-card:nth-child(6) { --toy: #7af5f7; --toy-rgb: 122, 245, 247; }
.play-card:nth-child(7) { --toy: #ff6b8a; --toy-rgb: 255, 107, 138; }
.play-card:nth-child(8) { --toy: #7ad7ff; --toy-rgb: 122, 215, 255; }
.play-card:nth-child(9) { --toy: #c9a9ff; --toy-rgb: 201, 169, 255; }
.play-card:nth-child(10) { --toy: #ffb36b; --toy-rgb: 255, 179, 107; }

/* 不同装饰纹理：星环 / 斜纹 / 点阵 / 光扇 */
.play-card:nth-child(1)::before, .play-card:nth-child(6)::before {
  border: 1px dashed rgba(var(--toy-rgb), .45); background: transparent;
  animation: toyFloat 7s ease-in-out infinite alternate, toySpin 16s linear infinite;
}
@keyframes toySpin { to { transform: rotate(360deg) } }
.play-card:nth-child(2)::before, .play-card:nth-child(7)::before {
  border-radius: 6px; transform: rotate(24deg);
  background: repeating-linear-gradient(90deg, rgba(var(--toy-rgb), .3) 0 6px, transparent 6px 18px);
}
.play-card:nth-child(3)::before, .play-card:nth-child(8)::before {
  background-image: radial-gradient(rgba(var(--toy-rgb), .55) 2px, transparent 2px);
  background-size: 18px 18px; border-radius: 0;
}
.play-card:nth-child(4)::before, .play-card:nth-child(9)::before {
  background: conic-gradient(from 40deg, transparent, rgba(var(--toy-rgb), .4), transparent 60%);
  filter: blur(4px);
}
.play-card:nth-child(5)::before, .play-card:nth-child(10)::before {
  border-radius: 30%; background: linear-gradient(135deg, rgba(var(--toy-rgb), .45), transparent 70%);
  clip-path: polygon(50% 0, 100% 50%, 50% 100%, 0 50%);
}

.pc-head { display: flex; align-items: center; gap: 12px; }
.pc-emoji {
  flex-shrink: 0; width: 42px; height: 42px; border-radius: 12px; display: grid; place-items: center; font-size: 22px;
  background: linear-gradient(150deg, rgba(var(--toy-rgb), .28), rgba(var(--toy-rgb), .06));
  border: 1px solid rgba(var(--toy-rgb), .45);
  box-shadow: 0 0 16px rgba(var(--toy-rgb), .18);
}
.pc-hd { min-width: 0; }
.pc-hd h3 { font-size: 16px; font-weight: 700; color: #eef2ff; }
.pc-hd p { font-size: 11.5px; color: #9fb0d8; margin-top: 3px; }
.pc-tag { margin-left: auto; flex-shrink: 0; font-size: 11px; color: var(--toy); padding: 3px 10px; border-radius: 999px; border: 1px solid rgba(var(--toy-rgb), .45); background: rgba(var(--toy-rgb), .1); }

.pc-row { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.pc-center { text-align: center; font-size: 12px; color: #9fb0d8; margin: 0; }
.pc-hint { font-size: 11px; color: #7e8ab0; }
.pc-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 12.5px; font-weight: 600; color: #04121f;
  padding: 8px 16px; border-radius: 10px;
  background: linear-gradient(135deg, var(--toy), var(--toy) 60%, #fff8);
  box-shadow: 0 6px 16px rgba(var(--toy-rgb), .32); transition: .22s;
}
.pc-btn:hover { transform: translateY(-1px); filter: brightness(1.06); box-shadow: 0 8px 22px rgba(var(--toy-rgb), .5); }
.pc-btn:disabled { opacity: .45; cursor: not-allowed; transform: none; }
.pc-btn.full { width: 100%; }
.pc-btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.pc-btn.ghost:hover { color: #fff; border-color: var(--toy); }

/* 运势 */
.fortune { display: flex; flex-direction: column; gap: 12px; }
.ft-level {
  align-self: flex-start; font-size: 18px; font-weight: 800; letter-spacing: 2px;
  padding: 6px 18px; border-radius: 12px; border: 1px solid; background: rgba(255, 255, 255, .05);
}
.ft-text { font-size: 14px; line-height: 1.7; color: #eef2ff; }
.ft-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; }
.ft-grid span { font-size: 12.5px; color: #9fb0d8; padding: 8px 12px; border-radius: 10px; background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .1); }
.ft-grid b { color: #eef2ff; }
.ft-grid i { display: inline-block; width: 13px; height: 13px; border-radius: 50%; vertical-align: -2px; box-shadow: 0 0 10px currentColor; }

/* 选择器 */
.opt-list { display: flex; flex-wrap: wrap; gap: 7px; min-height: 30px; }
.opt { font-size: 12px; color: #cdd6f4; padding: 5px 11px; border-radius: 999px; cursor: pointer;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16); transition: .2s; }
.opt:hover { color: #ff8aa8; border-color: var(--magenta); }
.opt-add { display: flex; gap: 8px; }
.opt-add input {
  flex: 1; min-width: 0; padding: 8px 12px; font-family: inherit; font-size: 12.5px; color: #fff; outline: none;
  background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .18); border-radius: 10px;
}
.opt-add input::placeholder { color: #7e8ab0; }
.opt-add input:focus { border-color: var(--cyan); }
.opt-add button { width: 36px; border: 1px solid rgba(255, 255, 255, .18); border-radius: 10px; cursor: pointer;
  color: #eef2ff; font-size: 18px; background: rgba(255, 255, 255, .07); }
.picker-screen {
  text-align: center; font-size: 22px; font-weight: 800; color: var(--cyan); padding: 14px;
  border-radius: 12px; background: rgba(10, 14, 39, .55); border: 1px solid rgba(45, 226, 230, .25);
  text-shadow: 0 0 14px rgba(45, 226, 230, .45);
}
.picker-screen.rolling { color: #ff8ad8; animation: shake .12s infinite; }
@keyframes shake { 0%, 100% { transform: translateX(0) } 50% { transform: translateX(2px) } }

/* 角色测试 */
.quiz-track { height: 6px; border-radius: 999px; background: rgba(255, 255, 255, .08); overflow: hidden; margin-bottom: 12px; }
.quiz-track i { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, var(--cyan), var(--purple), var(--magenta)); transition: width .35s; }
.quiz-q { font-size: 14.5px; font-weight: 600; color: #eef2ff; margin-bottom: 12px; }
.quiz-opts { display: grid; grid-template-columns: repeat(2, 1fr); gap: 9px; }
.quiz-opts button {
  font-family: inherit; font-size: 12.5px; color: #cdd6f4; cursor: pointer; text-align: left;
  padding: 10px 13px; border-radius: 11px; background: rgba(255, 255, 255, .06);
  border: 1px solid rgba(255, 255, 255, .16); transition: .2s;
}
.quiz-opts button:hover { color: #04121f; font-weight: 600; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); }
.quiz-result { display: flex; align-items: center; gap: 18px; padding: 8px 4px; }
.qr-emoji { font-size: 54px; line-height: 1; filter: drop-shadow(0 4px 16px rgba(45, 226, 230, .5)); }
.quiz-result h4 { font-size: 19px; font-weight: 700; color: var(--cyan); }
.quiz-result p { font-size: 12.5px; line-height: 1.7; color: #cdd6f4; margin: 6px 0 12px; }

/* 呼吸 */
.breath-wrap { height: 130px; display: grid; place-items: center; }
.breath-ring {
  width: 100px; height: 100px; border-radius: 50%; display: flex; flex-direction: column; align-items: center; justify-content: center;
  color: #04121f; background: radial-gradient(circle at 35% 30%, #7af5f7, #2de2e6 55%, #8a5cff);
  box-shadow: 0 0 30px rgba(45, 226, 230, .5); transition: transform 1s ease-in-out;
}
.breath-ring span { font-size: 12px; font-weight: 700; }
.breath-ring b { font-size: 22px; line-height: 1.1; }

/* 笑话 / 颜文字 / 急转弯 */
.joke, .riddle-q { font-size: 13.5px; line-height: 1.8; color: #eef2ff; min-height: 62px; }
.kaomoji { text-align: center; font-size: 24px; color: var(--cyan-soft); padding: 20px 8px;
  border-radius: 12px; background: rgba(10, 14, 39, .5); border: 1px solid rgba(45, 226, 230, .2);
  text-shadow: 0 0 14px rgba(45, 226, 230, .4); }
.riddle-a { font-size: 12.5px; color: var(--cyan-soft); min-height: 20px; opacity: .35; transition: .3s; }
.riddle-a.show { opacity: 1; font-weight: 600; }

/* 硬币 & 骰子 */
.coin-row { display: flex; gap: 16px; justify-content: center; align-items: center; padding: 8px 0; }
.coin, .dice {
  width: 68px; height: 68px; border-radius: 50%; display: grid; place-items: center;
  font-size: 14px; font-weight: 800; color: #04121f;
  background: linear-gradient(150deg, #ffd166, #ff9f43); border: 2px solid rgba(255, 255, 255, .5);
  box-shadow: 0 8px 22px rgba(255, 209, 102, .35);
}
.coin.heads { background: linear-gradient(150deg, #7af5f7, #8a5cff); }
.dice { border-radius: 16px; font-size: 30px; background: linear-gradient(150deg, #7af5f7, #b39cff); box-shadow: 0 8px 22px rgba(138, 92, 255, .35); }
.coin.spin { animation: coinSpin .72s ease-in-out; }
@keyframes coinSpin { 0% { transform: rotateY(0) } 50% { transform: rotateY(900deg) scale(1.15) } 100% { transform: rotateY(1800deg) } }
.dice.roll { animation: diceRoll .62s ease-in-out; }
@keyframes diceRoll { 0%, 100% { transform: rotate(0) } 25% { transform: rotate(25deg) scale(1.1) } 50% { transform: rotate(-25deg) scale(1.1) } 75% { transform: rotate(15deg) } }

/* 番茄钟 */
.pomo-time { text-align: center; font-size: 40px; font-weight: 800; letter-spacing: 3px; color: #eef2ff;
  font-variant-numeric: tabular-nums; padding: 6px 0; }
.pomo-time.running { color: var(--cyan); text-shadow: 0 0 20px rgba(45, 226, 230, .5); }
.pomo-modes { display: flex; gap: 8px; justify-content: center; }
.pomo-modes button {
  font-family: inherit; font-size: 12px; color: #cdd6f4; cursor: pointer; padding: 5px 14px; border-radius: 999px;
  background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .16); transition: .2s;
}
.pomo-modes button.on { color: #04121f; font-weight: 700; border-color: transparent; background: var(--cyan); }

/* 心情 */
.mood-row { display: grid; grid-template-columns: repeat(6, 1fr); gap: 6px; }
.mood {
  display: flex; flex-direction: column; align-items: center; gap: 3px; padding: 8px 2px; cursor: pointer;
  font-family: inherit; border-radius: 11px; color: #cdd6f4;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14); transition: .2s;
}
.mood span { font-size: 20px; line-height: 1; }
.mood small { font-size: 10px; }
.mood:hover:not(:disabled) { border-color: var(--cyan); transform: translateY(-2px); }
.mood.on { border-color: var(--cyan); background: rgba(45, 226, 230, .16); box-shadow: 0 0 14px rgba(45, 226, 230, .3); }
.mood:disabled { cursor: default; }
</style>
