/** 
@author                       Elie Habka
@date                         7/21/2026
@description                  This class handles authentication via OAuth to obtain an access token and uses it to query Account details by website from another Salesforce environment.
*/

public class HttpHelper {

    public static String getAccountData(String website) {

        HttpRequest tokenReq = new HttpRequest();
        tokenReq.setEndpoint('callout:SF_Login/services/oauth2/token');
        tokenReq.setMethod('POST');
        tokenReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'grant_type=password'
            + '&username={!$Credential.SF_Login_ExtCred.username}'
            + '&password={!$Credential.SF_Login_ExtCred.password}'
            + '&client_id={!$Credential.SF_Login_ExtCred.client_id}'
            + '&client_secret={!$Credential.SF_Login_ExtCred.client_secret}';

        tokenReq.setBody(body);

        Http http = new Http();
        HttpResponse tokenRes = http.send(tokenReq);

        if (tokenRes.getStatusCode() != 200) {
            throw new CalloutException('Token request failed: ' + tokenRes.getBody());
        }

        Map<String, Object> tokenJson = (Map<String, Object>) JSON.deserializeUntyped(tokenRes.getBody());
        String accessToken = (String) tokenJson.get('access_token');

        
        HttpRequest apiReq = new HttpRequest();
        String query = 'SELECT logoUrl__c, NumberOfEmployees, Foundation_date__c, BillingAddress, Description '
                      + 'FROM Account WHERE Website = \'' + website + '\'';
        String endpoint = 'callout:SF_API/services/data/v54.0/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');

        apiReq.setEndpoint(endpoint);
        apiReq.setMethod('GET');
        apiReq.setHeader('Authorization', 'Bearer ' + accessToken);
        apiReq.setHeader('Content-Type', 'application/json');

        HttpResponse apiRes = http.send(apiReq);

        if (apiRes.getStatusCode() != 200) {
            throw new CalloutException('Query request failed: ' + apiRes.getBody());
        }

        return apiRes.getBody();
    }
}
