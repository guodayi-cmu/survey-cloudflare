# 03_figures_advanced.R — 图9 MCA 双标图 + 图10 开放题词云
source("/Users/dayi/survey-cloudflare/analysis/00_setup.R")
suppressPackageStartupMessages({
  library(FactoMineR); library(factoextra)
  library(ggwordcloud); library(ggrepel)
})

## ---------- 图9 对应分析:恋爱与边界态度的结构 ----------
mca_dat <- own |>
  mutate(
    性别分组 = factor(性别认同分组),
    性取向分组 = factor(性取向分组),
    恋爱状态 = factor(恋爱状态),
    恋爱意愿 = factor(恋爱意愿),
    恋爱重要性 = factor(恋爱重要性, levels = c("完全不重要","不太重要","一般","比较重要","非常重要")),
    恋爱压力 = factor(恋爱压力, levels = c("没有压力","有一定压力","压力很大")),
    边界意识 = factor(边界意识, levels = c("完全不重要","不太重要","比较重要","非常重要")),
    恋爱教育需求 = factor(恋爱教育需求, levels = c("完全不需要","不太需要","一般","比较需要","非常需要")),
    情感支持评价 = factor(情感支持评价, levels = c("非常不足","不太充足","比较充足","非常充足")),
    对学业的影响 = factor(对学业的影响, levels = c("非常消极","比较消极","没有明显影响","比较积极","非常积极"))
  ) |>
  select(性别分组, 性取向分组, 恋爱状态, 恋爱意愿, 恋爱重要性,
         恋爱压力, 边界意识, 恋爱教育需求, 情感支持评价, 对学业的影响)
# 丢弃因子中只有单一水平的行(个别"不愿透露")
lvl1 <- sapply(mca_dat, function(v) length(unique(v)) == 1)
mca_dat <- mca_dat[complete.cases(mca_dat), ]
res <- MCA(mca_dat, graph = FALSE, ncp = 5)
saveRDS(res, "/Users/dayi/survey-cloudflare/analysis/mca.rds")

eig <- res$eig
dim1 <- eig[1, 1]; dim2 <- eig[2, 1]
vr <- as.data.frame(res$var$coord[, 1:2])
names(vr) <- c("d1", "d2"); vr$cos2 <- res$var$cos2[, 1]
vr$var <- rownames(vr)
vr$var_short <- sub("(男|女|.*)_(.*)", "\\2", vr$var)
vr$group <- sub("_", "\n", sub("^(.*?)_.*$", "\\1", vr$var))
vr$group[grepl("^\\s*$", vr$group)] <- "其他"
sup <- res$ind

fig09 <- ggplot(vr, aes(d1, d2)) +
  geom_hline(yintercept = 0, colour = PAL$axis, linewidth = 0.4) +
  geom_vline(xintercept = 0, colour = PAL$axis, linewidth = 0.4) +
  geom_point(aes(colour = cos2, shape = group), size = 2.8) +
  geom_text_repel(aes(label = var_short, colour = cos2),
                  family = "cnfont", size = 2.8, seed = 7,
                  max.overlaps = 40, min.segment.length = 0.3) +
  scale_colour_gradient(low = PAL$yellow, high = PAL$red, name = "贡献度 cos²") +
  scale_shape_manual(NULL, values = c(16, 17, 15, 8, 18, 6, 12, 10, 4, 3)[1:length(unique(vr$group))]) +
  labs(title = "十项变量的对应分析:哪些观念彼此「抱团」",
       subtitle = sprintf("MCA  | 第一维解释方差 %s,第二维 %s",
                          percent(dim1/sum(eig[, 1]), accuracy = 0.1),
                          percent(dim2/sum(eig[, 1]), accuracy = 0.1)),
       caption = "自建问卷 n = 95 | 点色按贡献度 cos² 由黄到红;形状区分题目 | 离原点越远、方向越接近的类别越倾向共同出现") +
  theme_survey() +
  theme(legend.position = "right",
        legend.box = "vertical",
        axis.text = element_text(colour = PAL$muted))
save_fig(fig09, "fig09_mca_biplot.png", 9.2, 6.8)

## ---------- 图10 开放题词云 ----------
wf <- read.csv("/Users/dayi/survey-cloudflare/analysis/word_freq.csv", stringsAsFactors = FALSE) |>
  slice_max(n, n = 45)
set.seed(42)
fig10 <- ggplot(wf, aes(label = word, size = n, colour = n)) +
  geom_text_wordcloud_area(seed = 42, area_corr_power = 1,
                           family = "cnfont", max_grid_size = 8) +
  scale_size_area(max_size = 16) +
  scale_colour_gradient(low = PAL$blue, high = PAL$red) +
  labs(title = "「关于当众亲密,你还有什么想法?」高频词",
       subtitle = "共享数据开放题 226 条 · jieba 分词后按词频缩放(仅展示前 45 词)",
       caption = "「大床房」= 网友对把公共场所当私人空间的自嘲式批评;「公序良俗」「注意场合」「适度」构成开放题的三大主题") +
  theme_void(base_family = "cnfont") +
  theme(plot.title = element_text(colour = PAL$ink, face = "bold", size = 14, margin = margin(b = 6)),
        plot.subtitle = element_text(colour = PAL$ink2, size = 10.5, margin = margin(b = 12)),
        plot.caption = element_text(colour = PAL$muted, size = 8.5, hjust = 0, margin = margin(t = 10)),
        plot.margin = margin(16, 18, 10, 18))
save_fig(fig10, "fig10_open_text_wordcloud.png", 8.2, 7.0)

cat("advanced figures done\n")
