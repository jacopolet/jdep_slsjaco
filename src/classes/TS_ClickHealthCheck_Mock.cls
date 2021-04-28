/**
* @author        Abram Vixen Reyes
* @date          Feb 2, 2019
* @description   Mock Web Service for TS_ClickHealthCheck
* @revision(s)
*/
@isTest
global class TS_ClickHealthCheck_Mock implements WebServiceMock {
    
    global Boolean hasException = false;
    
	global void doInvoke(
		Object stub,
		Object request,
		Map<String, Object> response,
		String endpoint,
		String soapAction,
		String requestName,
		String responseNS,
		String responseName,
		String responseType) {

            //START - SPECIFY THE RESPONSE YOU WANT TO SEND
            TS_ClickHealthCheck.CheckServerHealthResponse_element response_x = new TS_ClickHealthCheck.CheckServerHealthResponse_element();
            response_x.ReturnCode = 'Success';
            response_x.TestNumber = 0;
            //END
            
            //IF-ELSE TO HANDLE MULTIPLE METHODS
            if(requestName == 'CheckServerHealth' && !hasException){
            	response.put('response_x', response_x);
            } else {
                CalloutException e = new CalloutException();
                e.setMessage('This is a force exception for test class');
                throw e;
            }
    }
}