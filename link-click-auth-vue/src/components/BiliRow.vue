<script setup>
/**
 * B 站 · 时光代理人 视频入口：严格一行 4 个，不多不少。
 */
const videos = [
  { title: '时光代理人 · 官方番剧总览', desc: '第一季 / 第二季 / 英都篇 / 第三季 全集', cover: '/img/bili/overview.png', url: 'https://www.bilibili.com/bangumi/media/md28230742/', tag: '番剧总览' },
  { title: '时光代理人 第一季', desc: '2021 · 全12话 · 9.8 分', cover: '/img/bili/s1.png', url: 'https://bilibili.com/bangumi/play/ep411221', tag: '第一季' },
  { title: '时光代理人 第二季', desc: '2023 · 全12话 · 热播完结', cover: '/img/bili/s2.png', url: 'https://www.bilibili.com/bangumi/play/ss39666', tag: '第二季' },
  { title: '时光代理人 第三季', desc: '2026 · 英都新篇章 · 更新中', cover: '/img/bili/s3.png', url: 'https://www.bilibili.com/bangumi/play/ss105212', tag: '第三季' }
]
</script>

<template>
  <section class="bili">
    <div class="bili-head">
      <span class="bili-badge">bilibili</span>
      <div class="bili-hd-text">
        <h2 class="bili-title">B 站 · 时光代理人</h2>
        <p class="bili-sub">官方番剧 4 部 · 整整齐齐一行，点击直达哔哩哔哩观看</p>
      </div>
    </div>

    <div class="bili-track">
      <a
        v-for="v in videos"
        :key="v.url"
        class="bili-card"
        :href="v.url"
        target="_blank"
        rel="noopener noreferrer"
      >
        <div class="bili-cover" :style="{ backgroundImage: `url('${v.cover}')` }">
          <span class="bili-play">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
          </span>
          <span class="bili-tag">{{ v.tag }}</span>
        </div>
        <div class="bili-info">
          <h3 class="bili-name">{{ v.title }}</h3>
          <p class="bili-desc">{{ v.desc }}</p>
        </div>
      </a>
    </div>
  </section>
</template>

<style scoped>
.bili { width: 100%; }
.bili-head { display: flex; align-items: center; gap: 14px; margin-bottom: 16px; }
.bili-badge {
  flex-shrink: 0; font-size: 13px; font-weight: 700; letter-spacing: .5px; color: #fff;
  background: #fb7299; padding: 7px 12px; border-radius: 10px; box-shadow: 0 8px 20px rgba(251, 114, 153, .42);
}
.bili-hd-text { min-width: 0; }
.bili-title { font-size: 20px; font-weight: 600; letter-spacing: 1px; color: #eef2ff; }
.bili-sub { font-size: 12.5px; color: #9fb0d8; margin-top: 3px; }
/* 关键：固定 4 列，恰好一行 4 个，不会多出落单的一张 */
.bili-track {
  display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 16px;
}

.bili-card {
  min-width: 0;
  display: block; text-decoration: none; color: inherit; border-radius: 16px; overflow: hidden;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
  transition: transform .3s, border-color .3s, box-shadow .3s;
}
.bili-card:hover { transform: translateY(-5px); border-color: #fb7299; box-shadow: 0 22px 52px rgba(251, 114, 153, .32); }
.bili-cover { position: relative; height: 126px; background-size: cover; background-position: center; background-color: #0a0e27; }
.bili-cover::after {
  content: ""; position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(10, 14, 39, .1) 0%, rgba(10, 14, 39, .72) 100%);
}
.bili-play {
  position: absolute; inset: 0; margin: auto; width: 44px; height: 44px; z-index: 2;
  display: grid; place-items: center; border-radius: 50%; color: #fff;
  background: rgba(251, 114, 153, .92); box-shadow: 0 6px 18px rgba(0, 0, 0, .4); transition: transform .3s;
}
.bili-card:hover .bili-play { transform: scale(1.1); }
.bili-play svg { width: 21px; height: 21px; margin-left: 2px; }
.bili-tag {
  position: absolute; left: 10px; bottom: 10px; z-index: 2; font-size: 11px; padding: 3px 10px;
  border-radius: 999px; color: #fff; background: rgba(10, 14, 39, .6);
  border: 1px solid rgba(255, 255, 255, .28); backdrop-filter: blur(4px);
}
.bili-info { padding: 12px 13px 14px; }
.bili-name { font-size: 14.5px; font-weight: 600; color: #eef2ff; line-height: 1.35; }
.bili-desc { font-size: 12px; color: #9fb0d8; margin-top: 5px; line-height: 1.5; }

@media (max-width: 720px) {
  .bili-track { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 420px) {
  .bili-track { grid-template-columns: 1fr; }
}
</style>
