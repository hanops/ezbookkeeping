<template>
    <v-dialog width="600" :persistent="recognizing" v-model="showState">
        <v-card class="pa-sm-1 pa-md-2">
            <template #title>
                <h4 class="text-h4">{{ tt('Quick Add') }}</h4>
            </template>

            <v-card-text>
                <p class="mb-4">{{ tt('Import transaction text from clipboard or Shortcuts, then review it before saving.') }}</p>
                <v-textarea
                    :label="tt('Enter or paste transaction text here')"
                    v-model="textareaText"
                    :disabled="recognizing"
                    rows="6"
                    auto-grow
                    autofocus
                />
            </v-card-text>

            <v-card-text>
                <div class="w-100 d-flex justify-center flex-wrap mt-sm-1 mt-md-2 gap-4">
                    <v-btn :disabled="recognizing || !isSupportClipboard" @click="readClipboard">
                        {{ tt('Import from Clipboard') }}
                        <v-progress-circular indeterminate size="22" class="ms-2" v-if="recognizing"></v-progress-circular>
                    </v-btn>
                    <v-btn :disabled="recognizing || !textareaText.trim()" @click="recognize">
                        {{ tt('Recognize') }}
                        <v-progress-circular indeterminate size="22" class="ms-2" v-if="recognizing"></v-progress-circular>
                    </v-btn>
                    <v-btn color="secondary" variant="tonal" :disabled="recognizing"
                           @click="cancelRecognize" v-if="recognizing && cancelRecognizingUuid">{{ tt('Cancel Recognition') }}</v-btn>
                    <v-btn color="secondary" variant="tonal" :disabled="recognizing"
                           @click="cancel" v-if="!recognizing || !cancelRecognizingUuid">{{ tt('Cancel') }}</v-btn>
                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <snack-bar ref="snackbar" />
</template>

<script setup lang="ts">
import SnackBar from '@/components/desktop/SnackBar.vue';

import { ref, useTemplateRef } from 'vue';

import { useI18n } from '@/locales/helpers.ts';

import { useTransactionsStore } from '@/stores/transaction.ts';

import type { RecognizedReceiptImageResponse } from '@/models/large_language_model.ts';

import { generateRandomUUID } from '@/lib/misc.ts';
import logger from '@/lib/logger.ts';

type SnackBarType = InstanceType<typeof SnackBar>;

const { tt } = useI18n();

const transactionsStore = useTransactionsStore();

const snackbar = useTemplateRef<SnackBarType>('snackbar');

let resolveFunc: ((response: RecognizedReceiptImageResponse) => void) | null = null;
let rejectFunc: ((reason?: unknown) => void) | null = null;

const isSupportClipboard = !!navigator.clipboard;
const showState = ref<boolean>(false);
const recognizing = ref<boolean>(false);
const cancelRecognizingUuid = ref<string | undefined>(undefined);
const textareaText = ref<string>('');

function open(): Promise<RecognizedReceiptImageResponse> {
    showState.value = true;
    recognizing.value = false;
    cancelRecognizingUuid.value = undefined;
    textareaText.value = '';

    return new Promise((resolve, reject) => {
        resolveFunc = resolve;
        rejectFunc = reject;
    });
}

function recognize(): void {
    if (recognizing.value || !textareaText.value.trim()) {
        return;
    }

    cancelRecognizingUuid.value = generateRandomUUID();
    recognizing.value = true;

    transactionsStore.recognizeTransactionText({
        text: textareaText.value.trim(),
        cancelableUuid: cancelRecognizingUuid.value
    }).then(response => {
        resolveFunc?.(response);
        showState.value = false;
        recognizing.value = false;
        cancelRecognizingUuid.value = undefined;
    }).catch(error => {
        if (error.canceled) {
            return;
        }

        recognizing.value = false;
        cancelRecognizingUuid.value = undefined;

        if (!error.processed) {
            snackbar.value?.showError(error);
        }
    });
}

function readClipboard(): void {
    if (recognizing.value || !isSupportClipboard) {
        return;
    }

    navigator.clipboard.readText().then(text => {
        textareaText.value = text;
    }).catch(error => {
        logger.error('failed to read clipboard text', error);
        snackbar.value?.showError('Unable to read clipboard text');
    });
}

function cancelRecognize(): void {
    if (!cancelRecognizingUuid.value) {
        return;
    }

    transactionsStore.cancelRecognizeReceiptImage(cancelRecognizingUuid.value);
    recognizing.value = false;
    cancelRecognizingUuid.value = undefined;

    snackbar.value?.showMessage('User Canceled');
}

function cancel(): void {
    rejectFunc?.();
    showState.value = false;
    recognizing.value = false;
    cancelRecognizingUuid.value = undefined;
    textareaText.value = '';
}

defineExpose({
    open
});
</script>
