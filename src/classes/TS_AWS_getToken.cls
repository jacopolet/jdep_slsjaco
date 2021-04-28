public class TS_AWS_getToken {
    
    /*
Author:			Archi Delphinanto / Harold Marilag
Created date:	06-07-2017
Objective:		Get a necessary information (see AWSTokenResult) from ClickSoftware, as an input to get file in AWS S3
Input:			(to use: call gettoken) user name, password, and end-point
output:			AWSTokenResult
*/
    
    
    private HttpResponse callAWSToken(String lusername, String lpassword, String lendpoint) {
        CustomLogging.push('callAWSToken', 'TS_AWS_getToken');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        
        try{
            request.setEndpoint(lendpoint); 
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            Blob headerValue = Blob.valueOf(lusername + ':' + lpassword);
            String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
            response = http.send(request);		
            
        }
        catch(Exception e){
            system.debug('TS_AWS_getToken - callAWSToken, response error: ' + e.getMessage());
        }
        CustomLogging.pop();
        return response;   
    }
    
    public AWSTokenResult parseTokenResult (HttpResponse lresponse){
        CustomLogging.push('parseTokenResult', 'TS_AWS_getToken');
        AWSTokenResult tokenresult = new AWSTokenResult();
        
        // Parse the JSON response
        if (lresponse.getStatusCode() != 200) {
            System.debug('TS_AWS_getToken - parseTokenResult, the status code returned was not expected: ' +
                         lresponse.getStatusCode() + ' ' + lresponse.getStatus());
        } else {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(lresponse.getBody());
            tokenresult.awsaccesskeyid =  string.valueOf(results.get('AccessKeyId'));
            tokenresult.awssecretAccessKey = String.valueOf(results.get('SecretAccessKey'));
            tokenresult.awstoken=string.valueOf(results.get('Token'));
            tokenresult.awsregion=String.valueOf(results.get('AWSRegion'));
            //  System.debug('Click Token: ' + tokenresult.awstoken);
        }
        CustomLogging.pop();
        return tokenresult;
    }
    
    public AWSTokenResult gettoken(String luser, String lpassword, String lendpoint){
        CustomLogging.push('gettoken', 'TS_AWS_getToken');
        HttpResponse tk =callAWSToken(luser, lpassword, lendpoint);
        AWSTokenResult tr = parseTokenResult(tk);
        CustomLogging.pop();
        return tr;
    }
    
    public class AWSTokenResult {
        public String awsaccesskeyid {get; set;}
        public String awssecretaccesskey {get; set;}
        public String awstoken{get;set;}
        public String awsregion{get;set;}
        
    }
    
}