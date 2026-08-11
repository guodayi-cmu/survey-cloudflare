# 00_setup.R — 共享设置:数据载入、字体、配色(dataviz 规范)、主题
suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(stringr)
  library(ggplot2); library(scales); library(patchwork)
  library(showtext); library(sysfonts)
})

ROOT <- "/Users/dayi/survey-cloudflare"
FIG  <- file.path(ROOT, "figures")

# ---- 中文字体 ----
if (file.exists("/System/Library/Fonts/PingFang.ttc")) {
  font_add("cnfont", "/System/Library/Fonts/PingFang.ttc")
} else {
  font_add("cnfont", "/System/Library/Fonts/Hiragino Sans GB.ttc")
}
showtext_auto()
showtext_opts(dpi = 300)

# ---- dataviz 调色板(light mode) ----
PAL <- list(
  blue    = "#2a78d6", orange = "#eb6834", aqua   = "#1baf7a",
  yellow  = "#eda100", magenta= "#e87ba4", green  = "#008300",
  violet  = "#4a3aa7", red    = "#e34948",
  surface = "#fcfcfb", page   = "#f9f9f7",
  ink     = "#0b0b0b", ink2   = "#52514e", muted  = "#898781",
  grid    = "#e1e0d9", axis   = "#c3c2b7", divmid = "#f0efec"
)
SEQ_BLUE <- c("#cde2fb","#b7d3f6","#9ec5f4","#86b6ef","#6da7ec","#5598e7",
              "#3987e5","#2a78d6","#256abf","#1c5cab","#184f95","#104281","#0d366b")
# 发散五档:红(消极)↔灰(中性)↔蓝(积极)
DIV5 <- c(neg2="#e34948", neg1="#f0a9a8", mid="#f0efec", pos1="#9ec5f4", pos2="#2a78d6")

theme_survey <- function(base_size = 11) {
  theme_minimal(base_family = "cnfont", base_size = base_size) +
    theme(
      plot.background   = element_rect(fill = PAL$surface, colour = NA),
      panel.background  = element_rect(fill = PAL$surface, colour = NA),
      panel.grid.minor  = element_blank(),
      panel.grid.major  = element_line(colour = PAL$grid, linewidth = 0.3),
      axis.text  = element_text(colour = PAL$muted, size = base_size * 0.82),
      axis.title = element_text(colour = PAL$ink2, size = base_size * 0.9),
      plot.title = element_text(colour = PAL$ink,  face = "bold",
                                size = base_size * 1.25, lineheight = 1.15),
      plot.subtitle = element_text(colour = PAL$ink2, size = base_size * 0.92,
                                   margin = margin(b = 8)),
      plot.caption  = element_text(colour = PAL$muted, size = base_size * 0.7,
                                   hjust = 0, margin = margin(t = 8)),
      legend.text  = element_text(colour = PAL$ink2, size = base_size * 0.82),
      legend.title = element_text(colour = PAL$ink2, size = base_size * 0.85),
      strip.text = element_text(colour = PAL$ink, face = "bold", size = base_size * 0.95),
      plot.title.position = "plot", plot.caption.position = "plot",
      plot.margin = margin(14, 16, 10, 14)
    )
}

save_fig <- function(p, name, w, h) {
  ggsave(file.path(FIG, name), p, width = w, height = h, dpi = 300,
         bg = PAL$surface, limitsize = FALSE)
  cat("saved:", name, "\n")
}

# ---- 数据 ----
own    <- read_excel(file.path(ROOT, "survey-responses (5).zh-readable(1).xlsx"))
shared <- read_excel(file.path(ROOT,
  "366937356_按文本_公共场合中情侣过分亲密行为：心理动机与大众观感（俗称：为啥你们要当我面亲）_226_226.xlsx"))
names(shared) <- c("seq","time","dur","src","src_detail","ip","gender","rel_status",
                   "did_intimate","did_acts","reasons","excessive","offline_mood",
                   "online_feel","online_mood","open_text")
N_OWN <- nrow(own); N_SH <- nrow(shared)

# 多选题拆分
split_multi <- function(x) str_split(x, "┋")
excessive_counts <- shared$excessive |> split_multi() |> unlist() |>
  trimws() |> (\(v) v[v != "" & v != "(跳过)"])() |> table() |> sort(decreasing = TRUE)
acts_counts <- shared$did_acts |> split_multi() |> unlist() |>
  trimws() |> (\(v) v[v != "" & v != "(跳过)"])() |> table() |> sort(decreasing = TRUE)

wilson <- function(k, n) {
  ci <- prop.test(k, n, correct = FALSE)$conf.int
  sprintf("%.1f%% [95%%CI %.1f–%.1f]", 100*k/n, 100*ci[1], 100*ci[2])
}
