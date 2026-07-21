/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class copies the parsed company details (logo, employee count, bio, street, and foundation date) directly onto a Lead record.
*/
public class LeadLookupMapper {

    public static void mapToLead(Lead ld, LeadLookupWrapper.AccountRecord record) {
        ld.Logo_URL__c = record.logoUrl;
        ld.NumberOfEmployees = record.numberOfEmployees;
        ld.Company_Bio__c = record.description;
        ld.Street = record.street;

        if (record.foundationDate != null) {
            ld.Foundation_Date__c = Date.valueOf(record.foundationDate);
        }
    }
}