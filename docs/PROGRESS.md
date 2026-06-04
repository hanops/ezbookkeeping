# Development Progress

Last updated: 2026-06-04

## Current State

- **Branch**: `dev`
- **Latest release**: `v1.6.0-han.3`
- **Upstream sync**: up to date (2026-06-03, merged upstream/main with 1.6.0 code bump)

## Completed Features

- [x] Transaction text recognition — mobile (`v1.5.1-han.1`) + desktop (`v1.5.1-han.2`) + locale补全 + UX优化 (`v1.6.0-han.2`) + 独立LLM配置 (`v1.6.0-han.3`)
  - 用户可粘贴或从剪贴板读取交易文本，LLM识别后预览确认再保存
  - 文本识别与图片识别完全独立：独立配置、独立provider、独立权限位
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

- 文本识别与图片识别完全独立：各自有独立的 LLM 配置、provider 实例、feature toggle 和权限位
- 不配 `[llm_text_recognition]` 时，文本识别走规则回退（不借用图像的 LLM）
- Desktop 文本识别按钮始终显示（与 mobile 一致），权限由后端 feature restriction 控制
- Locale 策略：全部 19 种语言完整翻译（en, zh_Hans, zh_Hant, de, es, fr, it, ja, kn, ko, nl, pt_BR, ru, sl, ta, th, tr, uk, vi）
- `RecognizedReceiptImageResponse` 和 `parseRecognizedReceiptImageResponse` 共用（保持上游兼容，不重命名）
- 取消操作复用 `cancelRecognizeReceiptImage()` 方法

## Procedures

- Fork 工作流、同步、PR：`docs/fork-maintenance.md`
- 发版流程：`docs/self-hosted-release.md`
