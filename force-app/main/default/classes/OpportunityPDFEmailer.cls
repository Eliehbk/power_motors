public with sharing class OpportunityPDFEmailer {

    @InvocableMethod(label='Send Opportunity PDF to Representatives')
    public static void sendOpportunityPDF(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;
        Id oppId = opportunityIds[0];
        
        // 1. Retrieve the Opportunity details
        Opportunity opp = [
            SELECT Name, CloseDate, Amount, StageName, Account.Name 
            FROM Opportunity 
            WHERE Id = :oppId 
            LIMIT 1
        ];
        
        // 2. Collect recipient emails
        List<String> toAddresses = new List<String>();
        for (OpportunityContactRole ocr : [SELECT Contact.Email FROM OpportunityContactRole WHERE OpportunityId = :oppId AND Contact.Email != null]) {
            toAddresses.add(ocr.Contact.Email);
        }
        if (toAddresses.isEmpty()) return;
        
        string docType='';
        if(opp.StageName == 'Closed Won'){docType ='Order Summary';}
        else{docType='Project Closure Summary';}
        String rawHtml = '';
        
        List<HTML_File__mdt> metadataRecords = [
            SELECT HTML_Body__c FROM HTML_File__mdt WHERE Opportunity_Stage__c = :opp.StageName LIMIT 1
        ];
        if (!metadataRecords.isEmpty()) {
            rawHtml = metadataRecords[0].HTML_Body__c;
        }
        if (String.isBlank(rawHtml)) return;

        String formattedDate = '';
        if (opp.CloseDate != null) {
            DateTime closeDateTime = DateTime.newInstance(opp.CloseDate, Time.newInstance(0, 0, 0, 0));
            formattedDate = closeDateTime.format('MMMM d, yyyy');
        }

        String formattedAmount = '$0.00';
        if (opp.Amount != null) {
            formattedAmount = '$' + opp.Amount.setScale(2).format();
        }

        String safeOppName = '';
        if (opp.Name != null) {
            safeOppName = opp.Name.escapeXml();
        }

        String safeAccountName = '';
        if (opp.Account != null && opp.Account.Name != null) {
            safeAccountName = opp.Account.Name.escapeXml();
        }

        String safeStageName = '';
        if (opp.StageName != null) {
            safeStageName = opp.StageName.escapeXml();
        }

        rawHtml = rawHtml.replace('{{docType}}', docType)
                         .replace('{{oppName}}', safeOppName)
                         .replace('{{accountName}}', safeAccountName)
                         .replace('{{formattedDate}}', formattedDate)
                         .replace('{{formattedAmount}}', formattedAmount)
                         .replace('{{stageName}}', safeStageName);

        // 6. Generate the PDF Blob
        Blob pdfBlob = Blob.toPdf(rawHtml);

        // 7. Assemble and send the Email
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(opp.Name.replaceAll('[^a-zA-Z0-9]', '_') + '_' + docType.replaceAll(' ', '_') + '.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject('Power-Motors: ' + docType);
        email.setPlainTextBody('Dear Partner,\n\nPlease find attached your ' + docType + ' details.\n\nBest regards,\nPower-Motors Team');
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}