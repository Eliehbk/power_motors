public class OpportunityPDFEmailer {

    @InvocableMethod(label='Send Opportunity PDF to Representatives' description='Generates a PDF summary and emails it to all related opportunity contacts.')
    public static void sendOpportunityPDF(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;
    
        
        Id oppId = opportunityIds[0]; // Flow processes records individually when triggered
        List<OpportunityContactRole> contactRoles = [
            SELECT Contact.Email, Contact.Name 
            FROM OpportunityContactRole 
            WHERE OpportunityId = :oppId AND Contact.Email != null
        ];
        
        if (contactRoles.isEmpty()) {
            System.debug('No contacts with emails found for this Opportunity.');
            return; 
        }
        
        // 1. Query the Opportunity and parent Account fields
        Opportunity opp = [
            SELECT Name, CloseDate, Amount, StageName, IsWon, IsClosed,Account.Name
            FROM Opportunity 
            WHERE Id = :oppId 
            LIMIT 1
        ];

        // 2. Prepare dynamic values for the HTML
        
        // Determine the Document Type based on Opportunity Status
        String docType = '';
        if (opp.IsWon == true) {
            docType = 'Order Summary';
        } else if (opp.IsClosed == true) {
            docType = 'Project Closure Summary';
        }

        // Format Date (MMMM d, yyyy)
        String formattedDate = '';
        if (opp.CloseDate != null) {
            DateTime dt = DateTime.newInstance(opp.CloseDate.year(), opp.CloseDate.month(), opp.CloseDate.day());
            formattedDate = dt.format('MMMM d, yyyy');
        }

        // Format Currency 
        String formattedAmount = '$0.00';
        if (opp.Amount != null) {
            formattedAmount = '$' + opp.Amount.setScale(2).format();
        }

        // 4. Gather Recipient Email Addresses
        List<String> toAddresses = new List<String>();
        for (OpportunityContactRole ocr : contactRoles) {
            toAddresses.add(ocr.Contact.Email);
        }

     String htmlContent = 
            '<html>' +
            '<head>' +
            '    <style>' +
            '        body { font-family: "Arial Unicode MS", sans-serif; font-size: 14px; color: #333; line-height: 1.5; }' +
            '        .header-table { width: 100%; border-bottom: 3px solid #005A9C; padding-bottom: 15px; margin-bottom: 30px; }' +
            '        .company-title { font-size: 26px; font-weight: bold; color: #005A9C; }' +
            '        .doc-type { font-size: 18px; text-align: right; color: #555; text-transform: uppercase; letter-spacing: 1px; font-weight: bold; }' +
            '        .summary-table { width: 100%; border-collapse: collapse; margin-top: 20px; }' +
            '        .summary-table td { padding: 12px 15px; border-bottom: 1px solid #E0E0E0; }' +
            '        .label-col { font-weight: bold; color: #555; width: 35%; }' +
            '        .footer { margin-top: 60px; text-align: center; font-size: 11px; color: #777; border-top: 1px solid #E0E0E0; padding-top: 15px; }' +
            '    </style>' +
            '</head>' +
            '<body>' +
            '    <table class="header-table">' +
            '        <tr>' +
            '            <td class="company-title">Power-Motors</td>' +
            '            <td class="doc-type">' + docType + '</td>' +
            '        </tr>' +
            '    </table>' +
            '    <p>Dear Valued Partner,</p>' +
            '    <p>Please find the finalized details regarding our recent business engagement outlined below.</p>' +
            '    <table class="summary-table">' +
            '        <tr>' +
            '            <td class="label-col">Project / Order Name</td>' +
            '            <td>' + opp.Name + '</td>' +
            '        </tr>' +
            '        <tr>' +
            '            <td class="label-col">Company</td>' +
            '            <td>' + opp.Account.Name+ '</td>' +
            '        </tr>' +
            '        <tr>' +
            '            <td class="label-col">Date Finalized</td>' +
            '            <td>' + formattedDate + '</td>' +
            '        </tr>' +
            '        <tr>' +
            '            <td class="label-col">Total Investment</td>' +
            '            <td style="font-size: 15px; font-weight: bold; color: #005A9C;">' + formattedAmount + '</td>' +
            '        </tr>' +
            '        <tr>' +
            '            <td class="label-col">Current Status</td>' +
            '            <td>' + opp.StageName + '</td>' +
            '        </tr>' +
            '    </table>' +
            '    <div class="footer">' +
            '        Power-Motors Quality and Innovation — Ensuring your comfort and peace of mind.<br/>' +
            '        If you have any questions regarding this document summary, please get in touch with your account manager.' +
            '    </div>' +
            '</body>' +
            '</html>';

    Blob pdfBlob = Blob.toPdf(htmlContent);

   Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Opportunity_Detail.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject('Power-Motors: Your Opportunity Details Summary');
        email.setPlainTextBody('Dear Partner,\n\nPlease find attached the finalized details regarding your recent opportunity with Power-Motors.\n\nBest regards,\nPower-Motors Team');
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    
    }

}