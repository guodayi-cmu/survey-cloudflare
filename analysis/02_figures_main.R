# 02_figures_main.R — 图2至图8
source("/Users/dayi/survey-cloudflare/analysis/00_setup.R")
suppressPackageStartupMessages({ library(ggalluvial); library(ggrepel); library(forcats) })

ORD3 <- c(毫无影响 = "#86b6ef", 轻微影响 = "#2a78d6", 严重影响 = "#104281")

## ---------- 图2 样本画像 ----------
p_age <- own |> count(年龄段) |> mutate(年龄段 = fct_reorder(年龄段, n)) |>
  ggplot(aes(n, 年龄段)) +
  geom_col(fill = PAL$blue, width = 0.62) +
  geom_text(aes(label = sprintf("%d (%.1f%%)", n, n/N_OWN*100)),
            hjust = -0.08, family = "cnfont", size = 3, colour = PAL$ink2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.30))) +
  labs(title = "年龄段", x = NULL, y = NULL) + theme_survey() +
  theme(panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11.5))

p_edu <- own |> mutate(阶段 = case_when(
    教育阶段 == "本科一年级 / 大一" ~ "大一",
    教育阶段 == "本科二年级 / 大二" ~ "大二",
    教育阶段 == "本科三年级 / 大三" ~ "大三",
    TRUE ~ "其他")) |>
  count(阶段) |> mutate(阶段 = fct_relevel(阶段, "其他", "大三", "大二", "大一")) |>
  ggplot(aes(n, 阶段)) +
  geom_col(fill = PAL$blue, width = 0.62) +
  geom_text(aes(label = sprintf("%d (%.1f%%)", n, n/N_OWN*100)),
            hjust = -0.08, family = "cnfont", size = 3, colour = PAL$ink2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.30))) +
  labs(title = "教育阶段", x = NULL, y = NULL) + theme_survey() +
  theme(panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11.5))

p_major <- own |> mutate(专业 = fct_lump_n(专业大类, 4, other_level = "其他")) |>
  count(专业) |> mutate(专业 = fct_reorder(专业, n) |> fct_relevel("其他", after = 0)) |>
  ggplot(aes(n, 专业)) +
  geom_col(fill = PAL$blue, width = 0.62) +
  geom_text(aes(label = sprintf("%d (%.1f%%)", n, n/N_OWN*100)),
            hjust = -0.08, family = "cnfont", size = 3, colour = PAL$ink2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.30))) +
  labs(title = "专业大类", x = NULL, y = NULL) + theme_survey() +
  theme(panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11.5))

fig02 <- (p_age / p_edu / p_major) +
  plot_annotation(
    title = "自建问卷受访者画像(n = 95)",
    subtitle = "样本以 18–20 岁、本科一年级、医药卫生类专业为主体,属探索性便利样本",
    caption = "数据:自建 Cloudflare 匿名问卷系统在线回收 | 括号内为占全体 95 人的比例",
    theme = theme_survey())
save_fig(fig02, "fig02_sample_profile.png", 7.2, 7.8)

## ---------- 图3 恋爱状态 → 恋爱意愿 冲积图 ----------
al <- own |> transmute(
  状态 = case_when(
    恋爱状态 == "从未恋爱过" ~ "从未恋爱",
    恋爱状态 == "曾经恋爱，目前单身" ~ "曾恋爱·现单身",
    恋爱状态 == "正在恋爱中" ~ "正在恋爱",
    恋爱状态 == "处于暧昧或非正式关系中" ~ "暧昧关系",
    TRUE ~ "其他/未答"),
  意愿 = case_when(
    恋爱意愿 == "顺其自然" ~ "顺其自然",
    恋爱意愿 == "比较希望恋爱" ~ "比较希望恋爱",
    恋爱意愿 == "很希望恋爱" ~ "很希望恋爱",
    恋爱意愿 %in% c("暂时不想恋爱", "明确不想恋爱") ~ "不想恋爱",
    TRUE ~ "其他/未答")) |>
  count(状态, 意愿) |>
  mutate(状态 = fct_relevel(状态, "从未恋爱", "曾恋爱·现单身", "正在恋爱", "暧昧关系", "其他/未答"),
         意愿 = fct_relevel(意愿, "很希望恋爱", "比较希望恋爱", "顺其自然", "不想恋爱", "其他/未答"))

fig03 <- ggplot(al, aes(axis1 = 状态, axis2 = 意愿, y = n)) +
  geom_alluvium(aes(fill = 状态), width = 1/9, alpha = 0.72, knot.pos = 0.38) +
  geom_stratum(width = 1/9, fill = PAL$surface, colour = PAL$axis, linewidth = 0.4) +
  geom_text(stat = "stratum",
            aes(label = after_stat(ifelse(count >= 10, paste0(stratum, "\n", count, "人"), ""))),
            family = "cnfont", size = 2.9, lineheight = 0.95, colour = PAL$ink) +
  geom_text(stat = "stratum",
            aes(label = after_stat(ifelse(count < 10 & x == 1, paste0(stratum, " ", count, "人"), ""))),
            nudge_x = -0.07, hjust = 1, family = "cnfont", size = 2.8, colour = PAL$ink2) +
  geom_text(stat = "stratum",
            aes(label = after_stat(ifelse(count < 10 & x == 2, paste0(stratum, " ", count, "人"), ""))),
            nudge_x = 0.07, hjust = 0, family = "cnfont", size = 2.8, colour = PAL$ink2) +
  scale_x_discrete(limits = c("恋爱状态", "恋爱意愿"), expand = c(0.08, 0.08),
                   position = "top") +
  scale_fill_manual(values = c(从未恋爱 = PAL$blue, `曾恋爱·现单身` = PAL$orange,
                               正在恋爱 = PAL$aqua, 暧昧关系 = PAL$yellow,
                               `其他/未答` = PAL$muted), guide = "none") +
  labs(title = "从恋爱状态到恋爱意愿:单身不等于急于脱单",
       subtitle = "自建问卷 n = 95 | 流带宽度 = 人数;近半数受访者不论状态如何均选择「顺其自然」",
       caption = "数据:自建 Cloudflare 匿名问卷系统 | 「不想恋爱」合并「暂时不想」与「明确不想」",
       y = NULL) +
  theme_survey() +
  theme(axis.text.y = element_blank(), panel.grid = element_blank(),
        axis.text.x = element_text(colour = PAL$ink, face = "bold", size = 11))
save_fig(fig03, "fig03_status_willingness_alluvial.png", 7.6, 6.4)

## ---------- 图4 六项态度 发散堆叠 Likert ----------
lik_def <- list(
  list(var = "边界意识", disp = "亲密关系中边界意识的重要性",
       lv = c("完全不重要", "不太重要", NA, "比较重要", "非常重要")),
  list(var = "恋爱教育需求", disp = "学校开展恋爱/情感教育的需要",
       lv = c("完全不需要", "不太需要", "一般", "比较需要", "非常需要")),
  list(var = "对学业的影响", disp = "恋爱对学业的影响",
       lv = c("非常消极", "比较消极", "没有明显影响", "比较积极", "非常积极")),
  list(var = "恋爱重要性", disp = "恋爱在大学生活中的重要性",
       lv = c("完全不重要", "不太重要", "一般", "比较重要", "非常重要")),
  list(var = "恋爱压力", disp = "当前感受到的恋爱压力(反向:无压力为正)",
       lv = c("压力很大", "有一定压力", NA, "没有压力", NA)),
  list(var = "情感支持评价", disp = "学校/校园情感支持的充足程度",
       lv = c("非常不足", "不太充足", NA, "比较充足", "非常充足"))
)
slot_cols <- c(neg2 = DIV5[["neg2"]], neg1 = DIV5[["neg1"]],
               midL = DIV5[["mid"]], midR = DIV5[["mid"]],
               pos1 = DIV5[["pos1"]], pos2 = DIV5[["pos2"]])
lik <- bind_rows(lapply(lik_def, function(d) {
  x <- own[[d$var]]; x <- x[x %in% na.omit(d$lv)]
  nv <- length(x)
  shares <- sapply(d$lv, function(l) if (is.na(l)) 0 else sum(x == l) / nv * 100)
  tibble(item = sprintf("%s\n(有效 n=%d)", d$disp, nv),
         slot = c("neg2", "neg1", "mid", "pos1", "pos2"),
         level = ifelse(is.na(d$lv), "", d$lv), share = as.numeric(shares))
}))
lik_seg <- lik |> group_by(item) |> group_modify(~{
  s <- setNames(.x$share, .x$slot); l <- setNames(.x$level, .x$slot)
  tibble(slot = c("neg2","neg1","midL","midR","pos1","pos2"),
         level = c(l[["neg2"]], l[["neg1"]], l[["mid"]], l[["mid"]], l[["pos1"]], l[["pos2"]]),
         share = c(s[["neg2"]], s[["neg1"]], s[["mid"]]/2, s[["mid"]]/2, s[["pos1"]], s[["pos2"]]),
         side  = c(-1, -1, -1, 1, 1, 1))
}) |> ungroup() |>
  mutate(slot = factor(slot, c("pos2","pos1","midR","neg2","neg1","midL")),
         signed = share * side)
pos_order <- lik_seg |> filter(side > 0) |> group_by(item) |>
  summarise(p = sum(signed)) |> arrange(p) |> pull(item)
lik_seg$item <- factor(lik_seg$item, levels = pos_order)
lab_df <- lik |> filter(share >= 7, slot != "mid") |> group_by(item) |> group_modify(~{
  s <- setNames(lik$share[lik$item == .y$item], lik$slot[lik$item == .y$item])
  .x |> rowwise() |> mutate(centre = {
    m <- s[["mid"]]/2
    switch(slot,
      neg2 = -(m + s[["neg1"]] + s[["neg2"]]/2), neg1 = -(m + s[["neg1"]]/2),
      pos1 = m + s[["pos1"]]/2, pos2 = m + s[["pos1"]] + s[["pos2"]]/2)
  }) |> ungroup()
}) |> ungroup() |>
  mutate(item = factor(item, levels = pos_order),
         dark = slot %in% c("neg2", "pos2"),
         lab = ifelse(dark & share < 20,
                      sprintf("%s\n%.0f%%", level, share),
                      sprintf("%s %.0f%%", level, share)))
mid_lab <- lik |> filter(slot == "mid", share >= 7) |>
  mutate(item = factor(item, levels = pos_order))

fig04 <- ggplot(lik_seg, aes(y = item)) +
  geom_col(aes(x = signed, fill = slot), width = 0.6) +
  geom_vline(xintercept = 0, colour = PAL$ink2, linewidth = 0.45) +
  geom_text(data = lab_df, aes(x = centre, label = lab, colour = dark),
            family = "cnfont", size = 2.7, lineheight = 0.92, show.legend = FALSE) +
  geom_text(data = mid_lab, aes(x = 0, label = sprintf("%s %.0f%%", level, share)),
            family = "cnfont", size = 2.75, colour = PAL$ink2) +
  scale_fill_manual(values = slot_cols, guide = "none") +
  scale_colour_manual(values = c(`TRUE` = "#ffffff", `FALSE` = PAL$ink)) +
  scale_x_continuous(labels = \(v) paste0(abs(v), "%"), limits = c(-62, 100),
                     breaks = seq(-50, 100, 25)) +
  labs(title = "六项态度的分布:边界意识是全卷共识度最高的题目",
       subtitle = "自建问卷 | 左侧红色 = 消极/不足/压力方向,右侧蓝色 = 积极/重要/充足方向,中性项以灰色居中摆放",
       caption = "百分比基于各题有效作答(排除「不愿透露」「未填写」,每题 0–11 人) | 段内标注 ≥7% 的选项",
       x = "占有效作答比例", y = NULL) +
  theme_survey() + theme(panel.grid.major.y = element_blank())
save_fig(fig04, "fig04_likert_diverging.png", 8.6, 6.2)

## ---------- 图5 边界梯度哑铃图 ----------
db <- tribble(
  ~行为, ~认为过度, ~实际做过,
  "深吻",       96.9, 1.8,
  "坐对方腿上", 89.4, 2.2,
  "轻吻",       44.7, 11.5,
  "互相投喂",   37.2, 8.4,
  "搂肩搂腰",   19.9, 14.6,
  "拥抱",       18.1, 12.8,
  "牵手",       6.2,  23.5) |>
  mutate(行为 = fct_reorder(行为, 认为过度))
db_long <- db |> pivot_longer(-行为, names_to = "类型", values_to = "pct")

fig05 <- ggplot(db, aes(y = 行为)) +
  geom_segment(aes(x = 实际做过, xend = 认为过度, yend = 行为),
               colour = PAL$axis, linewidth = 0.7) +
  geom_point(data = db_long, aes(x = pct, colour = 类型), size = 3.4) +
  geom_text(data = db_long |> filter(类型 == "认为过度"),
            aes(x = pct, label = sprintf("%.1f%%", pct)),
            hjust = -0.35, family = "cnfont", size = 3, colour = PAL$blue) +
  geom_text(data = db_long |> filter(类型 == "实际做过"),
            aes(x = pct, label = sprintf("%.1f%%", pct)),
            hjust = 1.4, family = "cnfont", size = 3, colour = PAL$orange) +
  scale_colour_manual(NULL, values = c(认为过度 = PAL$blue, 实际做过 = PAL$orange),
                      labels = c(认为过度 = "认为该行为在公共场合「亲密过度」",
                                 实际做过 = "自己实际做过该行为")) +
  scale_x_continuous(labels = \(v) paste0(v, "%"), limits = c(-2, 107),
                     breaks = seq(0, 100, 25)) +
  labs(title = "公共亲密行为的「边界梯度」:观念与行为高度一致",
       subtitle = "共享探索性数据 n = 226(多选) | 唯一交叉项是牵手:做过的人(23.5%)远多于认为过度的人(6.2%)",
       caption = "「实际做过」以全体 226 人为基数,其中 39.4% 未在校园公共场合有过亲密行为或跳过该题;\n「深吻」在行为题中的原选项为「长时间深吻」",
       x = "占受访者比例", y = NULL) +
  theme_survey() +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.major.y = element_blank())
save_fig(fig05, "fig05_boundary_gradient_dumbbell.png", 8.2, 5.6)

## ---------- 图6 线下 vs 线上 配对流动 ----------
lv <- c("严重影响", "轻微影响", "毫无影响")
pf <- shared |> count(off = factor(offline_mood, lv), on = factor(online_mood, lv))
fig06 <- ggplot(pf, aes(axis1 = off, axis2 = on, y = n)) +
  geom_alluvium(aes(fill = off), width = 1/8, alpha = 0.75, knot.pos = 0.38) +
  geom_stratum(width = 1/8, fill = PAL$surface, colour = PAL$axis, linewidth = 0.4) +
  geom_text(stat = "stratum",
            aes(label = after_stat(sprintf("%s\n%d人 (%.1f%%)", stratum, count, count/226*100))),
            family = "cnfont", size = 2.9, lineheight = 0.98, colour = PAL$ink) +
  scale_x_discrete(limits = c("线下反复偶遇", "线上频繁刷到"), expand = c(0.10, 0.10),
                   position = "top") +
  scale_fill_manual(values = ORD3, guide = "none") +
  annotate("text", x = 1.5, y = 236, family = "cnfont", size = 3.1, colour = PAL$ink2,
           label = "同一批 226 人对两种情境的配对回答\nMcNemar 检验 卡方 = 35.6, p < 0.001:线下情绪影响显著重于线上") +
  labs(title = "同样是「秀恩爱」,线下比线上更影响心情",
       subtitle = "55 人从「线下有影响」转为「线上毫无影响」,反向仅 2 人;严重影响占比 21.7% → 7.5%",
       caption = "数据:共享探索性数据 | 线下:多次偶遇情侣过度亲密;线上:频繁刷到他人亲密恋爱日常",
       y = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.10))) +
  theme_survey() +
  theme(axis.text.y = element_blank(), panel.grid = element_blank(),
        axis.text.x = element_text(colour = PAL$ink, face = "bold", size = 11))
save_fig(fig06, "fig06_offline_online_paired.png", 7.6, 6.6)

## ---------- 图7 分组差异 ----------
t5 <- shared |> count(gender, mood = factor(offline_mood, rev(lv))) |>
  group_by(gender) |> mutate(pct = n / sum(n) * 100) |> ungroup()
p7a <- ggplot(t5, aes(pct, gender, fill = mood)) +
  geom_col(width = 0.55, colour = PAL$surface, linewidth = 0.6) +
  geom_text(aes(label = ifelse(pct >= 8, sprintf("%.0f%%", pct), "")),
            position = position_stack(vjust = 0.5), family = "cnfont",
            size = 2.9, colour = PAL$ink) +
  scale_fill_manual(NULL, values = ORD3, breaks = lv) +
  scale_x_continuous(labels = \(v) paste0(v, "%"), expand = c(0.01, 0)) +
  labs(title = "性别差异显著",
       subtitle = "卡方检验(df=2) = 22.7, p < 0.001, Cramér's V = 0.32",
       x = "占该性别受访者比例", y = NULL) +
  theme_survey() +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.major.y = element_blank())

sv <- shared |> mutate(rel3 = dplyr::recode(rel_status,
    "从来没谈过（如果和暧昧对象有关肢体接触的不选这一项）" = "从未恋爱",
    "恋爱状态" = "正在恋爱", "谈过但目前单身" = "曾恋爱·现单身")) |>
  group_by(rel3) |>
  summarise(k = sum(offline_mood == "严重影响"), n = n()) |>
  rowwise() |>
  mutate(p = k/n*100,
         lo = prop.test(k, n, correct = FALSE)$conf.int[1]*100,
         hi = prop.test(k, n, correct = FALSE)$conf.int[2]*100) |>
  ungroup() |> mutate(rel3 = fct_reorder(rel3, p))
p7b <- ggplot(sv, aes(p, rel3)) +
  geom_linerange(aes(xmin = lo, xmax = hi), colour = PAL$axis, linewidth = 0.8) +
  geom_point(colour = PAL$blue, size = 3.4) +
  geom_text(aes(label = sprintf("%.1f%%", p)), vjust = -1.1,
            family = "cnfont", size = 3, colour = PAL$ink2) +
  scale_x_continuous(labels = \(v) paste0(v, "%"), limits = c(0, 45)) +
  labs(title = "恋爱经历差异未达显著",
       subtitle = "报告「严重影响」比例(点)及 95% CI(线) | 卡方检验(df=4) = 7.5, p = 0.112",
       x = "线下偶遇时报告「严重影响」的比例", y = NULL) +
  theme_survey() + theme(panel.grid.major.y = element_blank())

fig07 <- (p7a | p7b) +
  plot_annotation(
    title = "谁更受「线下秀恩爱」影响:女性显著更受影响,恋爱经历仅呈趋势",
    subtitle = "共享探索性数据 n = 226 | 线下反复偶遇情侣过度亲密行为的情绪反应",
    caption = "左:各性别内三类反应构成;右:各恋爱经历组「严重影响」比例,置信区间按 Wilson 方法计算",
    theme = theme_survey())
save_fig(fig07, "fig07_group_differences.png", 10.2, 5.0)

## ---------- 图8 有序题相关热图 ----------
cm <- readRDS("/Users/dayi/survey-cloudflare/analysis/cor_matrix.rds")
ord <- hclust(dist(cm))$order
cml <- as.data.frame(as.table(cm[ord, ord])) |>
  setNames(c("x", "y", "r"))
fig08 <- ggplot(cml, aes(x, y, fill = r)) +
  geom_tile(colour = PAL$surface, linewidth = 1.2) +
  geom_text(aes(label = sprintf("%.2f", r),
                fontface = ifelse(abs(r) >= 0.3 & x != y, "bold", "plain")),
            family = "cnfont", size = 2.7,
            colour = ifelse(abs(cml$r) >= 0.45 & cml$x != cml$y, "#ffffff", PAL$ink)) +
  scale_fill_gradient2(low = PAL$red, mid = PAL$divmid, high = PAL$blue,
                       midpoint = 0, limits = c(-0.7, 0.7),
                       name = "Spearman ρ") +
  coord_fixed() +
  labs(title = "自建问卷八个有序题之间的相关结构",
       subtitle = "Spearman 相关,成对完整观测 n = 84–95 | 蓝 = 正相关,红 = 负相关;|ρ|≥0.30 加粗",
       caption = "行列顺序由层次聚类确定 | 「恋爱重要性—恋爱意愿—学业影响」聚成一簇,而「边界意识」与其近乎独立",
       x = NULL, y = NULL) +
  theme_survey() +
  theme(axis.text.x = element_text(angle = 32, hjust = 1, colour = PAL$ink2),
        axis.text.y = element_text(colour = PAL$ink2),
        panel.grid = element_blank(),
        legend.position = "right")
save_fig(fig08, "fig08_correlation_heatmap.png", 7.8, 6.6)

cat("main figures done\n")
