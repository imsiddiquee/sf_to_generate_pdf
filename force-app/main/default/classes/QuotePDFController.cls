//https://creative-otter-a28e1k-dev-ed.trailblaze.lightning.force.com//apex/QuotePDF?id=0Q0dL000000799pSAA
public class QuotePDFController {
    public Quote quote { get; set; }

    public QuotePDFController() {
        // Fetch the quote data
        quote = [SELECT Id, Opportunity.Name, Account.Name, Subtotal, Discount, TotalPrice, GrandTotal 
                 FROM Quote 
                 WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }


    @AuraEnabled
    public static void generatePdfAndSave(Id quoteId) {
        Quote quote = [SELECT Id, Name, Opportunity.Name, Account.Name, Subtotal, Discount, TotalPrice, GrandTotal 
                       FROM Quote WHERE Id = :quoteId];

        // Generate the PDF
        PageReference pdfPage = Page.QuotePDF;
        pdfPage.getParameters().put('id', quoteId);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Save the PDF as a ContentDocument
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Quote PDF - ' + quote.Name;
        contentVersion.PathOnClient = 'Quote.pdf';
        contentVersion.VersionData = pdfBlob;
        contentVersion.FirstPublishLocationId = quote.Id;
        insert contentVersion;
    }


    @AuraEnabled
    public static void generatePdfAndSendEmail(Id quoteId) {
        createPdfAndSendEmail(quoteId);
    }

    @Future(callout=true)
    public static void createPdfAndSendEmail(Id quoteId) {
        // Query the Quote and associated Contact's email
        Quote quote = [SELECT Id, Name, Opportunity.Name, Account.Name, Subtotal, Discount, TotalPrice, GrandTotal, Contact.Email 
                       FROM Quote WHERE Id = :quoteId];
        
        // Generate the PDF
        PageReference pdfPage = Page.QuotePDF;
        pdfPage.getParameters().put('id', quoteId);
        Blob pdfBlob = pdfPage.getContentAsPDF();
        
        // Send email with the PDF attached
        sendEmailWithAttachment(quote.Contact.Email, pdfBlob, quote.Name);
    }
    
    public static void sendEmailWithAttachment(String emailAddress, Blob pdfBlob, String quoteName) {
        System.debug('emailAddress-->'+emailAddress);
        // Create the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { emailAddress });
        email.setSubject('Quote PDF: ' + quoteName);
        email.setPlainTextBody('Please find the attached Quote PDF.');
        
        // Create the email attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Quote.pdf');
        attachment.setBody(pdfBlob);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        
        // Send the email
        // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        // Send the email
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        // Check the result
        for (Messaging.SendEmailResult result : results) {
            if (result.isSuccess()) {
                System.debug('Email sent successfully to ' + emailAddress);
            } else {
                System.debug('Failed to send email to ' + emailAddress + '. Error: ' + result.getErrors()[0].getMessage());
            }
        }
    }


    @AuraEnabled
    public static void uploadPdfToSlack(String slackMessage, String selectedChannel,Id quoteId) {
        try {
            // Generate PDF content from Visualforce page
            PageReference pdfPage = Page.QuotePDF;
            pdfPage.getParameters().put('id', quoteId);
            Blob pdfBody = pdfPage.getContentAsPDF();
            Integer pdfLength = pdfBody.size();
            String filename = 'Quote.pdf';
           

            // Step 1: Get Upload URL from Slack
            String uploadUrlResponse = SlackFileUploadController2.getUploadUrl(filename, pdfLength);
            Map<String, Object> uploadUrlMap = (Map<String, Object>) JSON.deserializeUntyped(uploadUrlResponse);
            String uploadUrl = (String) uploadUrlMap.get('uploadUrl');
            String fileId = (String) uploadUrlMap.get('fileId');

            // Step 2: Upload file to Slack
            String pdfBase64 = EncodingUtil.base64Encode(pdfBody);
            SlackFileUploadController2.uploadFileToSlack(uploadUrl, pdfBase64, filename);

            // Step 3: Complete the upload and send the message
            SlackFileUploadController2.completeUpload(fileId, slackMessage, selectedChannel);
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading PDF to Slack: ' + e.getMessage());
        }
    }
}
