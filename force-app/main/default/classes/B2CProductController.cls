public with sharing class B2CProductController {
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getPriceBookItem(){
 return [
           SELECT Id, Pricebook2Id, UnitPrice, Product2Id,
                   Product2.Name, Product2.Description, Product2.ProductCode,
                   Product2.Family, Product2.Country_of_Origin__c, Product2.Average_Life_Expectancy__c,
                   Product2.Size__c, Product2.Weight_kg__c, Product2.Phase__c, 
                   Product2.Power_Generated_KVA__c, Product2.Engine_Type__c, Product2.Image_URL__c,
                   Product2.RecordType.DeveloperName
            FROM PricebookEntry 
            WHERE Pricebook2.Name = 'B2C Pricebook' AND IsActive = true
        ];
    }
}



