/** 
@author                       Elie Habka
@date                         7/20/2026 
@description                  This class tests HttpHelper.  
*/
@isTest
private class HttpHelperTest {

    @isTest
    static void testGetAccountDataSuccess() {
        // Register the standalone mock
        Test.setMock(HttpCalloutMock.class, new HttpHelperMock());

        Test.startTest();
        String jsonResult = HttpHelper.getAccountData('acme.com');
        Test.stopTest();

        // Deserialize the response JSON to inspect specific field values
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResult);
        List<Object> records = (List<Object>) responseMap.get('records');
        Map<String, Object> accountData = (Map<String, Object>) records[0];

        // Assert realistic record values returned by the API mock
        System.assertEquals(250, (Integer) accountData.get('NumberOfEmployees'), 'Number of employees should be 250');
        System.assertEquals('Acme Tech Solutions', (String) accountData.get('Description'), 'Description should match');
        System.assertEquals('https://example.com/logo.png', (String) accountData.get('logoUrl__c'), 'Logo URL should match');
    }

    @isTest
    static void testGetAccountDataFailure() {
        // Mock an authentication failure (HTTP 401)
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        try {
            HttpHelper.getAccountData('acme.com');
            System.assert(false, 'Expected CalloutException was not thrown');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Token request failed'), 'Should catch token failure exception');
        }
        Test.stopTest();
    }

    // Helper mock to test exception handling for failed callouts
    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error": "invalid_grant"}');
            return res;
        }
    }
}