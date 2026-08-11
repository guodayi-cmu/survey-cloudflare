# 高校大学生恋爱现状调研问卷

**[English](README.en.md)**

> 课程作业用匿名问卷系统，基于 Cloudflare Pages + D1 + Functions 构建。

**在线地址**：`https://surveycmu.66110721.xyz`

---


## 实践报告

**[高校大学生恋爱现状与公共亲密边界认知调查](社会实践报告.md)** —— 基于自建隐私友好型问卷系统的混合调查与分析(含摘要、方法、统计结论与脱敏分析代码)。

## 项目结构

```text
survey-cloudflare/
├── public/                         # 静态前端（Pages 托管）
│   ├── index.html                  # 主问卷（在线填写）
│   ├── paper.html                  # 纸质问卷打印版（A4 空白表格）
│   ├── paper-encrypt.html          # 端到端加密纸质问卷（浏览器本地 AES-256-GCM）
│   ├── paper-decode.html           # 加密问卷解密演示页
│   ├── js/
│   │   └── i18n.js                 # 零依赖国际化引擎
│   └── locales/                    # 6 语言翻译文件
│       ├── zh-CN.json
│       ├── zh-TW.json
│       ├── zh-HK.json
│       ├── en.json
│       ├── ja.json
│       └── ko.json
│
├── functions/api/                  # Pages Functions（后端接口）
│   ├── submit.js                   # 问卷提交接口
│   └── export.csv.js               # CSV 数据导出接口
│
├── migrations/                     # D1 数据库迁移脚本
│   ├── 0001_create_responses.sql
│   ├── 0002_expand_fields.sql
│   ├── 0003_add_request_headers.sql
│   └── 0004_add_device_info.sql
│
├── wrangler.toml                   # Cloudflare 配置
└── README.md                       # 本文件
```

---

## 功能特性

| 功能 | 说明 |
|------|------|
| **6 语言切换** | 简中 / 繁中（台湾）/ 繁中（香港）/ English / 日本語 / 한국어 |
| **匿名填写** | 不收集姓名、学号、手机号、身份证号等 PII |
| **年龄筛查** | 未满 18 周岁自动拦截 |
| **性别认同** | 158 个选项，含 10 个分组，支持搜索 |
| **国家选择器** | 非中国大陆户籍时自动弹出国家/地区选择 |
| **纸质问卷** | 支持打印空白表格邮寄，或浏览器端加密后打印密文邮寄 |
| **端到端加密** | paper-encrypt 页面在浏览器内完成 AES-256-GCM 加密，服务器不接触明文 |
| **CSV 导出** | 带 token 鉴权的导出接口，UTF-8 BOM 格式 |
| **设备信息采集** | 仅收集平台、屏幕尺寸、时区、网络类型等匿名元数据，IP 经过 SHA-256 哈希 |

---

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 登录 Cloudflare

```bash
npx wrangler login
```

### 3. 创建 D1 数据库

```bash
npx wrangler d1 create survey-db
```

把输出的 `database_id` 填入 `wrangler.toml`。

### 4. 执行迁移

```bash
npx wrangler d1 migrations apply survey-db --remote
```

### 5. 设置环境变量

```bash
# CSV 导出鉴权 token（自行生成一个长随机字符串）
npx wrangler pages secret put EXPORT_TOKEN
```

### 6. 部署

```bash
npx wrangler pages deploy public --project-name survey-cloudflare
```

或在 Cloudflare Dashboard 中连接 GitHub 仓库自动部署。

---

## 数据导出

浏览器访问：

```
https://你的域名/api/export.csv?token=你的EXPORT_TOKEN
```

---

## 隐私声明

- 0 AI 接触数据，所有结果不会经由任何 AI 处理
- 不保存明文 IP 地址。服务器只保留由「IP + 当天日期」计算出的 SHA-256 摘要，用途只有一个：拦截同一天的重复提交。摘要不可逆、推不回原始 IP，且因每天混入的日期不同，不同日期的记录之间也无法互相关联。请求头等元数据中同样不含任何 IP 字段
- 开放题中请勿填写可识别个人身份的内容
- 所有数据仅用于课程作业统计分析
- 基础设施选用 Cloudflare（其信息安全与隐私管理体系公开接受独立第三方审计，覆盖 ISO 27001 / ISO 27701 / ISO 27018 / SOC 2 Type II 等框架）

---

## 技术栈

| 组件 | 用途 |
|------|------|
| Cloudflare Pages | 静态页面托管 |
| Pages Functions | Serverless 后端接口 |
| D1 | Serverless SQLite 数据库 |
| Turnstile | 人机验证（当前已关闭，可按需开启） |
