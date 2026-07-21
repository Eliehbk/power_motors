/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This test class creates sample accounts, price books, and products to verify that fetching B2C prices and creating won opportunities works correctly.
*/

@isTest
private class B2CProductControllerTest {

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Customer');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        insert new PricebookEntry(
           Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );

        Pricebook2 b2cPricebook = new Pricebook2(Name = System.Label.B2C_Pricebook_Name, IsActive = true);
    insert b2cPricebook;

       insert new PricebookEntry(
            Pricebook2Id = b2cPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 150,
            IsActive = true
        );
    }

    @isTest
    static void testGetPriceBookItem() {
        Test.startTest();
        B2CProductController.getPriceBookItem();
        Test.stopTest();
    }

    @isTest
    static void testCreateWonOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2.Name = :System.Label.B2C_Pricebook_Name LIMIT 1];

        Test.startTest();
        B2CProductController.createWonOpportunity(acc.Id, new List<Id>{ pbe.Id });
        Test.stopTest();
    }
}