package api

import (
	"testing"
	"time"

	"github.com/mayswind/ezbookkeeping/pkg/errs"
	"github.com/mayswind/ezbookkeeping/pkg/models"
)

func TestParseTransactionTextByRules(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	result, err := api.parseTransactionTextByRules(nil, time.Local, "招商银行您尾号1234账户于2026年05月28日 12:34消费人民币88.60元，商户：测试商户")

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result.Type != models.TRANSACTION_TYPE_EXPENSE {
		t.Fatalf("expected expense type, got %d", result.Type)
	}

	if result.SourceAmount != 8860 {
		t.Fatalf("expected source amount 8860, got %d", result.SourceAmount)
	}

	if result.Time == 0 {
		t.Fatal("expected parsed transaction time")
	}

	if result.Comment == "" {
		t.Fatal("expected fallback comment")
	}
}

func TestParseTransactionTextByRulesWithoutAmount(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	_, err := api.parseTransactionTextByRules(nil, time.Local, "这是一条没有金额的普通短信")

	if err != errs.ErrNoTransactionInformationInText {
		t.Fatalf("expected ErrNoTransactionInformationInText, got %v", err)
	}
}

func TestParseTransactionTextByRulesIncome(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	result, err := api.parseTransactionTextByRules(nil, time.Local, "您尾号5678账户于2026年05月28日 09:15收到转账收入100.00元")

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result.Type != models.TRANSACTION_TYPE_INCOME {
		t.Fatalf("expected income type, got %d", result.Type)
	}

	if result.SourceAmount != 10000 {
		t.Fatalf("expected source amount 10000, got %d", result.SourceAmount)
	}
}

func TestParseTransactionTextByRulesWithChineseDate(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	result, err := api.parseTransactionTextByRules(nil, time.Local, "2026年5月28日 12:34消费人民币50.00元")

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result.Time == 0 {
		t.Fatal("expected parsed transaction time from Chinese date")
	}

	if result.SourceAmount != 5000 {
		t.Fatalf("expected source amount 5000, got %d", result.SourceAmount)
	}
}

func TestParseTransactionTextByRulesAmountWithComma(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	result, err := api.parseTransactionTextByRules(nil, time.Local, "消费人民币1,234.56元")

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result.SourceAmount != 123456 {
		t.Fatalf("expected source amount 123456, got %d", result.SourceAmount)
	}
}

func TestParseTransactionTextByRulesWithSecondPattern(t *testing.T) {
	api := &LargeLanguageModelsApi{}
	result, err := api.parseTransactionTextByRules(nil, time.Local, "金额88.60元已扣款")

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if result.SourceAmount != 8860 {
		t.Fatalf("expected source amount 8860, got %d", result.SourceAmount)
	}
}
