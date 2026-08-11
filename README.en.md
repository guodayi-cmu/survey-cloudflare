# College Students' Love Life Survey

> An anonymous survey system for a course assignment, built on Cloudflare Pages + D1 + Functions.

**Live URL**: `https://surveycmu.66110721.xyz`

---

## Practice Report

**[Love Life and Public Intimacy Boundaries Among College Students](社会实践报告.md)** — a mixed-method survey based on a self-built, privacy-friendly questionnaire system (in Chinese; includes abstract, methodology, statistical conclusions, and desensitized analysis code as an appendix).

## Project Structure

```text
survey-cloudflare/
├── public/                         # Static frontend (hosted on Pages)
│   ├── index.html                  # Main questionnaire (online)
│   ├── paper.html                  # Printable paper questionnaire (A4 blank form)
│   ├── paper-encrypt.html          # End-to-end encrypted paper questionnaire (client-side AES-256-GCM)
│   ├── paper-decode.html           # Decryption demo page for the encrypted questionnaire
│   ├── js/
│   │   └── i18n.js                 # Zero-dependency i18n engine
│   └── locales/                    # 6 locale files
│       ├── zh-CN.json
│       ├── zh-TW.json
│       ├── zh-HK.json
│       ├── en.json
│       ├── ja.json
│       └── ko.json
│
├── functions/api/                  # Pages Functions (backend)
│   ├── submit.js                   # Submission endpoint
│   └── export.csv.js               # CSV export endpoint
│
├── migrations/                     # D1 database migrations
│   ├── 0001_create_responses.sql
│   ├── 0002_expand_fields.sql
│   ├── 0003_add_request_headers.sql
│   └── 0004_add_device_info.sql
│
├── wrangler.toml                   # Cloudflare configuration
└── README.md                       # This file
```

---

## Features

| Feature | Description |
|---------|-------------|
| **6-language UI** | Simplified Chinese / Traditional Chinese (TW) / Traditional Chinese (HK) / English / 日本語 / 한국어 |
| **Anonymous** | No name, student ID, phone number, ID number, or other PII collected |
| **Age gate** | Respondents under 18 are blocked automatically |
| **Gender identity** | 158 options across 10 groups, with search support |
| **Country selector** | Shows country/region picker automatically for non-mainland-China residency |
| **Paper questionnaire** | Printable blank form by mail, or client-side encrypted ciphertext by mail |
| **End-to-end encryption** | paper-encrypt page encrypts with AES-256-GCM in the browser; the server never sees plaintext |
| **CSV export** | Token-authenticated export endpoint, UTF-8 BOM format |
| **Device metadata** | Only anonymous metadata (platform, screen size, timezone, network type); IP is SHA-256 hashed |

---

## Quick Start

### 1. Install dependencies

```bash
npm install
```

### 2. Log in to Cloudflare

```bash
npx wrangler login
```

### 3. Create the D1 database

```bash
npx wrangler d1 create survey-db
```

Copy the printed `database_id` into `wrangler.toml`.

### 4. Apply migrations

```bash
npx wrangler d1 migrations apply survey-db --remote
```

### 5. Set environment variables

```bash
# CSV export auth token (generate a long random string)
npx wrangler pages secret put EXPORT_TOKEN
```

### 6. Deploy

```bash
npx wrangler pages deploy public --project-name survey-cloudflare
```

Or connect this GitHub repository to Cloudflare Dashboard for automatic deployment.

---

## Data Export

Visit in the browser:

```
https://your-domain/api/export.csv?token=YOUR_EXPORT_TOKEN
```

---

## Privacy Statement

- 0 AI touches the data; no result is processed by any AI
- No plaintext IP addresses are stored. The server keeps only a SHA-256 digest of `IP + date of day`, used solely to block duplicate submissions on the same day. The digest cannot be reversed to the original IP, and because the date mixed in changes daily, records from different days cannot be linked. Request-header metadata contains no IP fields either
- Do not enter personally identifiable content in open-ended questions
- All data is used only for course-assignment statistical analysis
- Infrastructure runs on Cloudflare (whose information-security and privacy management systems are subject to independent third-party audits, covering frameworks such as ISO 27001 / ISO 27701 / ISO 27018 / SOC 2 Type II)

---

## Tech Stack

| Component | Purpose |
|-----------|---------|
| Cloudflare Pages | Static hosting |
| Pages Functions | Serverless backend endpoints |
| D1 | Serverless SQLite database |
| Turnstile | Human verification (currently disabled; can be enabled as needed) |
