# 01_stats.R — 全部统计检验,输出到 analysis/stats_output.txt
source("/Users/dayi/survey-cloudflare/analysis/00_setup.R")
suppressPackageStartupMessages(library(vcd))
sink("/Users/dayi/survey-cloudflare/analysis/stats_output.txt")

cat("================ 自建问卷 n =", N_OWN, " 共享数据 n =", N_SH, "================\n\n")

cat("---- [1] 自建问卷关键比例 + Wilson 95% CI ----\n")
key_props <- list(
  c("从未恋爱", sum(own$恋爱状态 == "从未恋爱过", na.rm = TRUE)),
  c("边界意识(比较+非常重要)", sum(own$边界意识 %in% c("比较重要","非常重要"))),
  c("恋爱意愿顺其自然", sum(own$恋爱意愿 == "顺其自然", na.rm = TRUE)),
  c("希望恋爱(比较+很)", sum(own$恋爱意愿 %in% c("比较希望恋爱","很希望恋爱"))),
  c("有恋爱压力(一定+很大)", sum(own$恋爱压力 %in% c("有一定压力","压力很大"))),
  c("需要恋爱教育(比较+非常)", sum(own$恋爱教育需求 %in% c("比较需要","非常需要"))),
  c("情感支持不足(不太+非常)", sum(own$情感支持评价 %in% c("不太充足","非常不足")))
)
for (kp in key_props) cat(sprintf("  %-28s %s\n", kp[1], wilson(as.numeric(kp[2]), N_OWN)))

cat("\n---- [2] 恋爱状态 × 恋爱压力 (Fisher 精确检验, 模拟p) ----\n")
sub <- own |> filter(恋爱状态 %in% c("从未恋爱过","曾经恋爱，目前单身","正在恋爱中"),
                     恋爱压力 %in% c("没有压力","有一定压力","压力很大")) |>
  mutate(压力 = ifelse(恋爱压力 == "没有压力", "无压力", "有压力"))
t2 <- table(sub$恋爱状态, sub$压力)
print(t2); print(round(prop.table(t2, 1)*100, 1))
print(fisher.test(t2))

cat("\n---- [3] 共享数据: 各行为'认为过度'比例 + Wilson CI ----\n")
for (nm in names(excessive_counts)) cat(sprintf("  %-10s %s\n", nm, wilson(excessive_counts[[nm]], N_SH)))
cat("\n实际做过(占全体):\n")
for (nm in names(acts_counts)) cat(sprintf("  %-10s %s\n", nm, wilson(acts_counts[[nm]], N_SH)))

cat("\n---- [4] 线下 vs 线上 情绪影响(同批 226 人配对) ----\n")
lv <- c("毫无影响","轻微影响","严重影响")
pt <- table(factor(shared$offline_mood, lv), factor(shared$online_mood, lv))
cat("配对表(行=线下, 列=线上):\n"); print(pt)
cat("\nMcNemar-Bowker 对称性检验(3x3):\n"); print(mcnemar.test(pt))
off_b <- shared$offline_mood != "毫无影响"; on_b <- shared$online_mood != "毫无影响"
cat("二分类(有影响 vs 无影响) McNemar:\n"); print(mcnemar.test(table(off_b, on_b)))
cat(sprintf("线下有影响 %s | 线上有影响 %s\n", wilson(sum(off_b), N_SH), wilson(sum(on_b), N_SH)))
cat(sprintf("线下严重 %s | 线上严重 %s\n",
    wilson(sum(shared$offline_mood == "严重影响"), N_SH),
    wilson(sum(shared$online_mood == "严重影响"), N_SH)))

cat("\n---- [5] 性别 × 线下影响 (卡方 + Cramér's V) ----\n")
t5 <- table(shared$gender, factor(shared$offline_mood, lv))
print(t5); print(round(prop.table(t5, 1)*100, 1))
print(chisq.test(t5)); print(assocstats(t5)$cramer)

cat("\n---- [6] 情感状况 × 线下影响 (卡方) ----\n")
shared$rel3 <- dplyr::recode(shared$rel_status,
  "从来没谈过（如果和暧昧对象有关肢体接触的不选这一项）" = "从未恋爱",
  "恋爱状态" = "正在恋爱", "谈过但目前单身" = "曾恋爱现单身")
t6 <- table(shared$rel3, factor(shared$offline_mood, lv))
print(t6); print(round(prop.table(t6, 1)*100, 1)); print(chisq.test(t6))

cat("\n---- [7] 自建问卷有序题 Spearman 相关(供热图) ----\n")
ord_map <- list(
  恋爱重要性 = c("完全不重要"=1,"不太重要"=2,"一般"=3,"比较重要"=4,"非常重要"=5),
  对学业的影响 = c("非常消极"=1,"比较消极"=2,"没有明显影响"=3,"比较积极"=4,"非常积极"=5),
  恋爱压力 = c("没有压力"=1,"有一定压力"=2,"压力很大"=3),
  边界意识 = c("完全不重要"=1,"不太重要"=2,"比较重要"=3,"非常重要"=4),
  恋爱教育需求 = c("完全不需要"=1,"不太需要"=2,"一般"=3,"比较需要"=4,"非常需要"=5),
  情感支持评价 = c("非常不足"=1,"不太充足"=2,"比较充足"=3,"非常充足"=4),
  恋爱意愿 = c("明确不想恋爱"=1,"暂时不想恋爱"=2,"顺其自然"=3,"比较希望恋爱"=4,"很希望恋爱"=5),
  求助意愿 = c("从不"=1,"很少"=2,"有时会"=3,"总是寻求帮助"=4)
)
ord_df <- as.data.frame(lapply(names(ord_map), function(v) unname(ord_map[[v]][own[[v]]])))
names(ord_df) <- names(ord_map)
cm <- cor(ord_df, method = "spearman", use = "pairwise.complete.obs")
print(round(cm, 2))
saveRDS(cm, "/Users/dayi/survey-cloudflare/analysis/cor_matrix.rds")

cat("\n---- [8] 开放题词频(jieba, 供词云) ----\n")
writeLines(shared$open_text[!is.na(shared$open_text)], "/Users/dayi/survey-cloudflare/analysis/open_text.txt")
cat("open_text.txt 已导出,", sum(!is.na(shared$open_text)), "条\n")
sink()
cat("stats done\n")
