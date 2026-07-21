/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class runs in the background to fetch company data for Leads via API, parse the results,
                                 map them back to the Lead fields, and save the updates to Salesforce.
*/
public class LeadLookupManager {

    @future(callout=true)
    public static void lookupLeadsAsync(List<Id> leadIds) {
        lookupLeads(leadIds);
    }

    public static void lookupLeads(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) { return; }

        List<Lead> leads = [
            SELECT Id, Website
            FROM Lead
            WHERE Id IN :leadIds AND Website != null
        ];

        List<Lead> leadsToUpdate = new List<Lead>();
        system.debug('leadss: '+leads);
        for (Lead ld : leads) {
            String json = HttpHelper.getAccountData(ld.Website);
            if (String.isBlank(json)) { continue; }

            LeadLookupWrapper result = LeadLookupWrapper.parse(json);
            if (result.records.isEmpty()) { continue; }

            LeadLookupMapper.mapToLead(ld, result.records[0]);
            leadsToUpdate.add(ld);
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}