/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class fetches active B2C product pricing details for display in Lightning Web Components and creates a "Closed Won" Opportunity with associated line items for walk-in sales.
*/
public with sharing class B2CProductController {

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getB2CProductsPaged(Integer pageNumber, Integer pageSize, String category, String country) {

        String targetPricebook = System.Label.B2C_Pricebook_Name;
        String whereClause = ' WHERE Pricebook2.Name = :targetPricebook AND IsActive = true';

        if (category != null && category != 'All') {
            whereClause += ' AND Product2.RecordType.DeveloperName = :category';}

        if (country != null && country != 'All') {
            whereClause += ' AND Product2.Country_of_Origin__c = :country';}

        Integer offsetValue = (pageNumber - 1) * pageSize;
        Integer queryLimit = pageSize + 1;

        String recordsQuery =
            'SELECT Id, Pricebook2Id, UnitPrice, Product2Id, ' +
            'Product2.Name, Product2.Description, Product2.ProductCode, ' +
            'Product2.Family, Product2.Country_of_Origin__c, Product2.Average_Life_Expectancy__c, ' +
            'Product2.Size__c, Product2.Weight_kg__c, Product2.Phase__c, ' +
            'Product2.Power_Generated_KVA__c, Product2.Engine_Type__c, Product2.Image_URL__c, ' +
            'Product2.RecordType.DeveloperName ' +
            'FROM PricebookEntry' + whereClause +
            ' ORDER BY Product2.Name ASC' +
            ' LIMIT :queryLimit OFFSET :offsetValue';

        return Database.query(recordsQuery);
    }

    @AuraEnabled
    public static ID createWonOpportunity(Id accountId, List<Id> pbeIds) {

        String targetPricebook = System.Label.B2C_Pricebook_Name;
        Pricebook2 b2cPricebook = [SELECT Id FROM Pricebook2 WHERE Name = :targetPricebook LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'B2C Walk-In Sale - ' + System.today().format(),
            AccountId = accountId,
            StageName = 'Closed Won',
            CloseDate = System.today(),
            Pricebook2Id = b2cPricebook.Id
        );
        insert opp;

        List<PricebookEntry> pbeList = [SELECT Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Id IN :pbeIds];

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (PricebookEntry pbe : pbeList) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            oli.PricebookEntryId = pbe.Id;
            oli.Quantity = 1;
            oli.UnitPrice = pbe.UnitPrice;
            oli.ServiceDate=System.Today();
            olis.add(oli);
            
        }

        insert olis;

        return opp.Id;
    }
}