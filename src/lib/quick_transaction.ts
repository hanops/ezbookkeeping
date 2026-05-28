import type { RecognizedReceiptImageResponse } from '@/models/large_language_model.ts';

export function getTransactionAddUrlFromRecognizedResult(result: RecognizedReceiptImageResponse): string {
    const params: string[] = [];

    if (result.type) {
        params.push(`type=${result.type}`);
    }

    if (result.time) {
        params.push(`time=${result.time}`);
    }

    if (result.categoryId) {
        params.push(`categoryId=${result.categoryId}`);
    }

    if (result.sourceAccountId) {
        params.push(`accountId=${result.sourceAccountId}`);
    }

    if (result.destinationAccountId) {
        params.push(`destinationAccountId=${result.destinationAccountId}`);
    }

    if (result.sourceAmount) {
        params.push(`amount=${result.sourceAmount}`);
    }

    if (result.destinationAmount) {
        params.push(`destinationAmount=${result.destinationAmount}`);
    }

    if (result.tagIds) {
        params.push(`tagIds=${result.tagIds.join(',')}`);
    }

    if (result.comment) {
        params.push(`comment=${encodeURIComponent(result.comment)}`);
    }

    params.push('noTransactionDraft=true');

    return `/transaction/add?${params.join('&')}`;
}
