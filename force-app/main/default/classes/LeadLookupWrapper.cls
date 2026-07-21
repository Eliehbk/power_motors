/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class converts a raw JSON string into Apex objects containing company details like
                                 logo, employee count, foundation date, description, and street address. 
*/
public class LeadLookupWrapper {
    public List<AccountRecord> records;

    public class AccountRecord {
        public String logoUrl;
        public Integer numberOfEmployees;
        public String foundationDate;
        public String description;
        public String street;
    }

    public static LeadLookupWrapper parse(String jsonString) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        LeadLookupWrapper wrapper = new LeadLookupWrapper();
        wrapper.records = new List<AccountRecord>();

        List<Object> rawRecords = (List<Object>) root.get('records');
        if (rawRecords != null) {
            for (Object o : rawRecords) {
                Map<String, Object> rec = (Map<String, Object>) o;

                AccountRecord ar = new AccountRecord();
                ar.logoUrl = (String) rec.get('logoUrl__c');
                ar.numberOfEmployees = (Integer) rec.get('NumberOfEmployees');
                ar.foundationDate = (String) rec.get('Foundation_date__c');
                ar.description = (String) rec.get('Description');

                Map<String, Object> addr = (Map<String, Object>) rec.get('BillingAddress');
                if (addr != null) {
                    ar.street = (String) addr.get('street');
                }
                
                wrapper.records.add(ar);
            }
        }

        return wrapper;
    }
}