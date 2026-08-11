# 高校大学生恋爱现状与公共亲密边界认知调查
# 核心分析代码(脱敏版)
# 说明:原始数据文件名为本地真实路径,这里已替换为占位符。
# 运行前请把两个 read_excel 的路径改成你自己的数据文件位置。

suppressPackageStartupMessages({
  library(readxl)      # 读取 Excel
  library(dplyr)       # 数据整理
  library(ggplot2)     # 绘图
})

# ============ 1. 读取数据(路径按实际修改) ============
own    <- read_excel("自建问卷导出.xlsx")    # 自建 Cloudflare 问卷,95 份
shared <- read_excel("共享问卷导出.xlsx")    # 独立共享探索数据,226 份

# ============ 2. Wilson 95% 置信区间 ============
wilson <- function(k, n) prop.test(k, n, correct = FALSE)$conf.int

# 自建问卷关键比例(n = 95)
props <- c(
  从未恋爱      = sum(own$恋爱状态 == "从未恋爱过", na.rm = TRUE),
  重视边界意识  = sum(own$边界意识 %in% c("比较重要", "非常重要")),
  恋爱顺其自然  = sum(own$恋爱意愿 == "顺其自然", na.rm = TRUE),
  有一定恋爱压力 = sum(own$恋爱压力 %in% c("有一定压力", "压力很大"))
)
for (nm in names(props)) {
  ci <- wilson(props[[nm]], nrow(own))
  cat(sprintf("%s: %.1f%% [95%%CI %.1f%%, %.1f%%]\n",
              nm, 100 * props[[nm]] / nrow(own), 100 * ci[1], 100 * ci[2]))
}

# ============ 3. 线上线下情绪影响,配对 McNemar 检验 ============
# 同一批 226 人分别报告"线下偶遇"与"线上刷到"两类情境的感受
lv <- c("毫无影响", "轻微影响", "严重影响")
pt <- table(factor(shared$线下情绪, levels = lv),
            factor(shared$线上情绪, levels = lv))
mcnemar.test(pt)          # 三分类对称性检验
# 二分类(有影响 vs 无影响)
off <- shared$线下情绪 != "毫无影响"
on  <- shared$线上情绪 != "毫无影响"
mcnemar.test(table(off, on))

# ============ 4. 性别 × 线下影响,卡方 + Cramér's V ============
tab <- table(shared$性别, factor(shared$线下情绪, levels = lv))
chi <- chisq.test(tab)
cramers_v <- sqrt(as.numeric(chi$statistic) / (sum(tab) * (min(dim(tab)) - 1)))

# ============ 5. 有序题 Spearman 相关 ============
ord <- data.frame(
  恋爱重要性 = as.numeric(factor(own$恋爱重要性,
                    levels = c("完全不重要", "不太重要", "一般", "比较重要", "非常重要"))),
  恋爱意愿   = as.numeric(factor(own$恋爱意愿,
                    levels = c("明确不想恋爱", "暂时不想恋爱", "顺其自然", "比较希望恋爱", "很希望恋爱"))),
  边界意识   = as.numeric(factor(own$边界意识,
                    levels = c("完全不重要", "不太重要", "比较重要", "非常重要")))
)
cor(ord, method = "spearman", use = "pairwise.complete.obs")

# ============ 6. 公共亲密行为边界梯度(哑铃图) ============
gradient <- data.frame(
  行为     = c("深吻", "坐对方腿上", "轻吻", "互相投喂", "搂肩搂腰", "拥抱", "牵手"),
  认为过度 = c(96.9, 89.4, 44.7, 37.2, 19.9, 18.1, 6.2),
  实际做过 = c(1.8,  2.2, 11.5, 8.4, 14.6, 12.8, 23.5)
)
gradient$行为 <- factor(gradient$行为, levels = gradient$行为)

ggplot(gradient, aes(y = 行为)) +
  geom_segment(aes(x = 实际做过, xend = 认为过度, yend = 行为), color = "#c3c2b7") +
  geom_point(aes(x = 认为过度), color = "#2a78d6", size = 3) +
  geom_point(aes(x = 实际做过), color = "#eb6834", size = 3) +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  labs(x = "占受访者比例", y = NULL,
       title = "公共亲密行为的边界梯度:观念 vs 行为") +
  theme_minimal()
