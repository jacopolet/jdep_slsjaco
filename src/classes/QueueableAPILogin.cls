//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 21, 2017
// Usage        :   Apex Class to queu sending of session Id to click software, schedule job cannot directly use call out
//-------------------------------------------------------------------------------------------//
public class QueueableAPILogin implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        CustomLogging.push('QueueableAPILogin', 'API Callout');

        String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/';
        String NS_SF = 'urn:enterprise.soap.sforce.com'; 
        String user = IntegrationUserAndProfile__c.getInstance().Click_Username__c; //'capiuser@jde.com.tsdev'; //'sapintegrationuser@jdecoffee.com.dsg';
        string password = IntegrationUserAndProfile__c.getInstance().Click_Password__c; //'clicksalesforce123KoMTJNX7G12Z9PdaT8M4DImAT'; //'1qaz@WSXrC6tbCnrbFwWDVPg7ADd6ho3w';
        HttpRequest req = new HttpRequest();

        req.setMethod('POST');   
        req.setTimeout(60000);
        req.setEndpoint(IntegrationUserAndProfile__c.getInstance().Click_Endpoint_URL__c);//https://test.salesforce.com/services/Soap/c/39.0/0DF9E0000004CHR');
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');        
        req.setHeader('SOAPAction', '""');
        req.setBody('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Header/><Body><login xmlns="urn:enterprise.soap.sforce.com"><username>' +user+ '</username><password>' + password + '</password></login></Body></Envelope>');        
        system.debug('Click user name: ' +user);
        system.debug('Click password: ' +password);
        HttpResponse res =  new Http().send(req);
        if(res.getStatusCode() != 200)
        {
            Dom.Document responseDocument = res.getBodyDocument();
            Dom.Xmlnode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
            Dom.Xmlnode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body 
            Dom.Xmlnode faultElm = bodyElm.getChildElement('Fault', NS_SOAP); // soapenv:Fault
            Dom.Xmlnode faultStringElm = faultElm.getChildElement('faultstring', null); // faultstring 
            CustomLogging.debugException(faultStringElm.getText());
            CustomLogging.pop();     

            system.debug(faultStringElm.getText()); 
        } else {
            // As per http://wiki.developerforce.com/page/Enterprise_Login
            Dom.Document responseDocument = res.getBodyDocument();
            Dom.Xmlnode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
            Dom.Xmlnode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body 
            Dom.Xmlnode loginResponseElm = bodyElm.getChildElement('loginResponse', NS_SF); // loginResponse
            
            Dom.Xmlnode resultElm = loginResponseElm.getChildElement('result', NS_SF); // result
            Dom.Xmlnode sessionIdElm = resultElm.getChildElement('sessionId', NS_SF); // sessionId
            
            system.debug('user info ' + sessionIdElm.getText());
            Integration_Log__c integ = new Integration_Log__c();
            integ.Object__c = INT_Constants.CLICK_SESSIONID;
            integ.Object_Id__c = sessionIdElm.getText().substring(0,15);
            integ.Integration_Status__c = INT_Constants.INITIAL;
            integ.Triggered_Timestamp__c = Datetime.now();
            integ.SessionID__c = sessionIdElm.getText();
            try {
                insert integ;
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }

        CustomLogging.pop();
    }
    
}