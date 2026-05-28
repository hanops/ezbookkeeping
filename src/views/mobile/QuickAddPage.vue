<template>
    <f7-page @page:afterin="onPageAfterIn">
        <f7-navbar>
            <f7-nav-left :class="{ 'disabled': recognizing }" :back-link="tt('Back')"></f7-nav-left>
            <f7-nav-title :title="tt('Quick Add')"></f7-nav-title>
        </f7-navbar>

        <f7-block strong inset>
            <p>{{ tt('Import transaction text from clipboard or Shortcuts, then review it before saving.') }}</p>
        </f7-block>

        <f7-list strong inset dividers>
            <f7-list-input type="textarea" :placeholder="tt('Enter or paste transaction text here')"
                           :value="textareaText" @input="textareaText = $event.target.value"
                           :disabled="recognizing" style="height: 160px"></f7-list-input>
        </f7-list>

        <f7-list strong inset dividers>
            <f7-list-button :class="{ 'disabled': recognizing || !isSupportClipboard }"
                            :text="tt('Read Clipboard and Recognize')"
                            @click="readClipboard"></f7-list-button>
            <f7-list-button :class="{ 'disabled': recognizing || !textareaText.trim() }"
                            :text="tt('Recognize')"
                            @click="recognizeFromTextarea"></f7-list-button>
        </f7-list>
    </f7-page>
</template>

<script setup lang="ts">
import type { Router } from 'framework7/types';
import { ref } from 'vue';

import { useI18n } from '@/locales/helpers.ts';
import { useI18nUIComponents, closeAllDialog } from '@/lib/ui/mobile.ts';

import { useTransactionsStore } from '@/stores/transaction.ts';

import { getTransactionAddUrlFromRecognizedResult } from '@/lib/quick_transaction.ts';
import { generateRandomUUID } from '@/lib/misc.ts';
import logger from '@/lib/logger.ts';

const props = defineProps<{
    f7route: Router.Route;
    f7router: Router.Router;
}>();

const { tt } = useI18n();
const { showToast, showCancelableLoading } = useI18nUIComponents();

const transactionsStore = useTransactionsStore();

const query = props.f7route.query;
const isSupportClipboard = !!navigator.clipboard;

const textareaText = ref<string>('');
const recognizing = ref<boolean>(false);
const cancelRecognizingUuid = ref<string | undefined>(undefined);
let initialized = false;

function recognize(text: string): void {
    const transactionText = text.trim();

    if (!transactionText) {
        showToast('Transaction text is empty');
        return;
    }

    cancelRecognizingUuid.value = generateRandomUUID();
    recognizing.value = true;
    showCancelableLoading('Recognizing', 'AI can make mistakes. Check important info.', 'Cancel Recognition', cancelRecognize);

    transactionsStore.recognizeTransactionText({
        text: transactionText,
        cancelableUuid: cancelRecognizingUuid.value
    }).then(result => {
        recognizing.value = false;
        cancelRecognizingUuid.value = undefined;
        closeAllDialog();
        props.f7router.navigate(getTransactionAddUrlFromRecognizedResult(result));
    }).catch(error => {
        if (error.canceled) {
            return;
        }

        recognizing.value = false;
        cancelRecognizingUuid.value = undefined;
        closeAllDialog();

        if (!error.processed) {
            showToast(error.message || error || 'Unable to recognize transaction text');
        }
    });
}

function cancelRecognize(): void {
    if (!cancelRecognizingUuid.value) {
        return;
    }

    transactionsStore.cancelRecognizeReceiptImage(cancelRecognizingUuid.value);
    recognizing.value = false;
    cancelRecognizingUuid.value = undefined;
    closeAllDialog();

    showToast('User Canceled');
}

function recognizeFromTextarea(): void {
    if (recognizing.value || !textareaText.value.trim()) {
        return;
    }

    recognize(textareaText.value);
}

function readClipboard(): void {
    if (recognizing.value || !isSupportClipboard) {
        return;
    }

    navigator.clipboard.readText().then(text => {
        textareaText.value = text;
        recognize(text);
    }).catch(error => {
        logger.error('failed to read clipboard text for quick add', error);
        showToast('Unable to read clipboard text');
    });
}

function onPageAfterIn(): void {
    if (initialized) {
        return;
    }

    initialized = true;

    const text = query['text'];

    if (typeof text === 'string' && text) {
        textareaText.value = text;
        recognize(text);
        return;
    }

    const source = query['source'];

    if (source === 'clipboard' && isSupportClipboard) {
        navigator.clipboard.readText().then(text => {
            textareaText.value = text;
            recognize(text);
        }).catch(() => {
            // Silent fail on auto-trigger (iOS permission); user can tap button
        });
    }
}
</script>
