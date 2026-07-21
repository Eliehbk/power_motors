/** 
@author                       Elie Habka
@date                         7/21/2026
@description                   This class fetches active B2C product pricing details for display in Lightning Web Components and creates a "Closed Won" Opportunity with associated line items for walk-in sales.
*/
public with sharing class B2CProductController {
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getPriceBookItem(){
    String targetPricebook = System.Label.B2C_Pricebook_Name;
 return [
           SELECT Id, Pricebook2Id, UnitPrice, Product2Id,
                   Product2.Name, Product2.Description, Product2.ProductCode,
                   Product2.Family, Product2.Country_of_Origin__c, Product2.Average_Life_Expectancy__c,
                   Product2.Size__c, Product2.Weight_kg__c, Product2.Phase__c, 
                   Product2.Power_Generated_KVA__c, Product2.Engine_Type__c, Product2.Image_URL__c,
                   Product2.RecordType.DeveloperName
            FROM PricebookEntry 
            WHERE Pricebook2.Name = :targetPricebook AND IsActive = true
        ];
    }
@AuraEnabled
    public static ID createWonOpportunity(Id accountId, List<Id> pbeIds){
String targetPricebook = System.Label.B2C_Pricebook_Name;
pricebook2 b2cPricebook = [SELECT Id FROM Pricebook2 WHERE Name = :targetPricebook LIMIT 1];

Opportunity opp = new Opportunity(
                Name = 'B2C Walk-In Sale - ' + System.today().format(),
                AccountId = accountId,
                StageName = 'Closed Won',
                CloseDate = System.today(),
                Pricebook2Id = b2cPricebook.Id
            );

            insert opp;
List<PricebookEntry> PbeList=[SELECT Id,UnitPrice,Product2Id FROM PricebookEntry where Id IN :pbeIds];

List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

for(PricebookEntry pbe : PbeList){
    olis.add(new OpportunityLineItem(
    OpportunityId = opp.Id,
    PricebookEntryId = pbe.Id,
    Quantity = 1,
    UnitPrice = pbe.UnitPrice
     )
        );
            }
 insert olis;
return opp.ID;
    }

        }



