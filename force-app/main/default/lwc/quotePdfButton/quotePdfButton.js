import { LightningElement, api } from 'lwc';
import generatePdfAndSave from '@salesforce/apex/QuotePDFController.generatePdfAndSave';
import generatePdfAndSendEmail from '@salesforce/apex/QuotePDFController.generatePdfAndSendEmail';
import uploadPdfToSlack from '@salesforce/apex/QuotePDFController.uploadPdfToSlack';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuotePdfButton extends LightningElement {
    @api recordId;

    generatePdf() {
        const vfPageUrl = `/apex/QuotePDF?id=${this.recordId}`;
        window.open(vfPageUrl, '_blank');
    }


    async handleGeneratePdfAndSave() {
        try {
            await generatePdfAndSave({ quoteId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'PDF generation initiated successfully',
                    variant: 'success',
                }),
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }
    
    async handleGeneratePdfAndSendEmail() {
        try {
            await generatePdfAndSendEmail({ quoteId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'PDF generation initiated successfully',
                    variant: 'success',
                }),
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }

    async handleUploadPdfToSlack() {
        try {
            await uploadPdfToSlack({ quoteId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'PDF generation initiated successfully',
                    variant: 'success',
                }),
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        }
    }
}




