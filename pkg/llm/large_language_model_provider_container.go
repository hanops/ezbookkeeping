package llm

import (
	"github.com/mayswind/ezbookkeeping/pkg/core"
	"github.com/mayswind/ezbookkeeping/pkg/errs"
	"github.com/mayswind/ezbookkeeping/pkg/llm/data"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider/anthropic"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider/googleai"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider/lmstudio"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider/ollama"
	"github.com/mayswind/ezbookkeeping/pkg/llm/provider/openai"
	"github.com/mayswind/ezbookkeeping/pkg/settings"
)

// LargeLanguageModelProviderContainer contains the current large language model provider
type LargeLanguageModelProviderContainer struct {
	receiptImageRecognitionCurrentProvider provider.LargeLanguageModelProvider
	receiptTextRecognitionCurrentProvider  provider.LargeLanguageModelProvider
}

// Initialize a large language model provider container singleton instance
var (
	Container = &LargeLanguageModelProviderContainer{}
)

// InitializeLargeLanguageModelProvider initializes the current large language model provider according to the config
func InitializeLargeLanguageModelProvider(config *settings.Config) error {
	var err error = nil

	if config.ReceiptImageRecognitionLLMConfig != nil {
		Container.receiptImageRecognitionCurrentProvider, err = initializeLargeLanguageModelProvider(config.ReceiptImageRecognitionLLMConfig, config.EnableDebugLog)

		if err != nil {
			return err
		}
	}

	if config.ReceiptTextRecognitionLLMConfig != nil {
		Container.receiptTextRecognitionCurrentProvider, err = initializeLargeLanguageModelProvider(config.ReceiptTextRecognitionLLMConfig, config.EnableDebugLog)

		if err != nil {
			return err
		}
	}

	return nil
}

func initializeLargeLanguageModelProvider(llmConfig *settings.LLMConfig, enableResponseLog bool) (provider.LargeLanguageModelProvider, error) {
	if llmConfig.LLMProvider == settings.OpenAILLMProvider {
		return openai.NewOpenAILargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.OpenAICompatibleLLMProvider {
		return openai.NewOpenAICompatibleLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.AnthropicLLMProvider {
		return anthropic.NewAnthropicLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.AnthropicCompatibleLLMProvider {
		return anthropic.NewAnthropicCompatibleLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.OpenRouterLLMProvider {
		return openai.NewOpenRouterLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.OllamaLLMProvider {
		return ollama.NewOllamaLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.LMStudioLLMProvider {
		return lmstudio.NewLMStudioLargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == settings.GoogleAILLMProvider {
		return googleai.NewGoogleAILargeLanguageModelProvider(llmConfig, enableResponseLog), nil
	} else if llmConfig.LLMProvider == "" {
		return nil, nil
	}

	return nil, errs.ErrInvalidLLMProvider
}

// GetJsonResponseByReceiptImageRecognitionModel returns the json response from the current large language model provider by receipt image recognition model
func (l *LargeLanguageModelProviderContainer) GetJsonResponseByReceiptImageRecognitionModel(c core.Context, uid int64, currentConfig *settings.Config, request *data.LargeLanguageModelRequest) (*data.LargeLanguageModelTextualResponse, error) {
	if currentConfig.ReceiptImageRecognitionLLMConfig == nil || Container.receiptImageRecognitionCurrentProvider == nil {
		return nil, errs.ErrInvalidLLMProvider
	}

	return l.receiptImageRecognitionCurrentProvider.GetJsonResponse(c, uid, currentConfig.ReceiptImageRecognitionLLMConfig, request)
}

// GetJsonResponseByReceiptTextRecognitionModel returns the json response from the current large language model provider by receipt text recognition model
func (l *LargeLanguageModelProviderContainer) GetJsonResponseByReceiptTextRecognitionModel(c core.Context, uid int64, currentConfig *settings.Config, request *data.LargeLanguageModelRequest) (*data.LargeLanguageModelTextualResponse, error) {
	if currentConfig.ReceiptTextRecognitionLLMConfig == nil || Container.receiptTextRecognitionCurrentProvider == nil {
		return nil, errs.ErrInvalidLLMProvider
	}

	return l.receiptTextRecognitionCurrentProvider.GetJsonResponse(c, uid, currentConfig.ReceiptTextRecognitionLLMConfig, request)
}
