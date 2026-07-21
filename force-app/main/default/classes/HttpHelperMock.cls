/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This mock class simulates fake HTTP responses for both OAuth authentication and REST API queries during unit tests.
*/

@isTest
public class HttpHelperMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        // 1. Mock the OAuth Token request
        if (req.getEndpoint().contains('oauth2/token')) {
            res.setBody('{"access_token": "mock_token_12345"}');
        } 
        // 2. Mock the Account Query request with realistic field values
        else {
            String queryResponseBody = '{' +
                '"totalSize": 1,' +
                '"done": true,' +
                '"records": [{' +
                    '"logoUrl__c": "https://example.com/logo.png",' +
                    '"NumberOfEmployees": 250,' +
                    '"Foundation_date__c": "2015-08-20",' +
                    '"BillingAddress": {' +
                        '"city": "San Francisco",' +
                        '"state": "CA",' +
                        '"country": "USA"' +
                    '},' +
                    '"Description": "Acme Tech Solutions"' +
                '}]' +
            '}';
            
            res.setBody(queryResponseBody);
        }

        return res;
    }
}