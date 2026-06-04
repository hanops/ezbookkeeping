# Development Progress

Last updated: 2026-06-04

## Current State

- **Branch**: `dev`
- **Latest release**: `v1.5.1-han.20260604.1`
- **Upstream sync**: up to date (2026-06-03, merged upstream/main with 1.6.0 code bump)

## Completed Features

- [x] Transaction text recognition — mobile (`v1.5.1-han.20260528.1`) + desktop (`v1.5.1-han.20260530.1`) + locale补全 + UX优化 (`v1.5.1-han.20260604.1`)
  - 用户可粘贴或从剪贴板读取交易文本，LLM识别后预览确认再保存
  - Key files:
    - Desktop: `src/views/desktop/transactions/list/dialogs/TextRecognitionDialog.vue`, `src/views/desktop/transactions/ListPage.vue`
    - Mobile: `src/views/mobile/QuickAddPage.vue`
    - Backend: `pkg/api/large_language_models.go` (`RecognizeTransactionTextHandler`)
    - Route: `cmd/webserver.go` (`POST /v1/llm/transactions/recognize_transaction_text.json`)
    - Store: `src/stores/transaction.ts` (`recognizeTransactionText()`)
    - Prompt: `templates/prompt/transaction_text_recognition.tmpl`

## In Progress

- (none)

## Planned / Backlog

- [ ] 上游PR — 如需将文本识别功能提交到 upstream，创建 `pr/text-recognition` 分支

## Key Decisions

- 文本识别与图片识别共享 feature flag `isTransactionFromAIImageRecognitionEnabled()`
- Locale 策略：全部 19 种语言完整翻译（en, zh_Hans, zh_Hant, de, es, fr, it, ja, kn, ko, nl, pt_BR, ru, sl, ta, th, tr, uk, vi）
- `RecognizedReceiptImageResponse` 类型同时用于图片识别和文本识别的响应
- 取消操作复用 `cancelRecognizeReceiptImage()` 方法

## Procedures

- Fork 工作流、同步、PR：`docs/fork-maintenance.md`
- 发版流程：`docs/self-hosted-release.md`
