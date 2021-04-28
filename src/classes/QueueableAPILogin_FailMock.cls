/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Fail Mock Callout for QueueableAPILogin
* @revision(s)
*/
@isTest
global class QueueableAPILogin_FailMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        response.setBody('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"> <soapenv:Body> <soapenv:Fault> <faultcode>soapenv:Client</faultcode> <faultstring>Invalid error</faultstring> </soapenv:Fault> </soapenv:Body> </soapenv:Envelope>');
        response.setStatusCode(201);
        return response; 
    }
}