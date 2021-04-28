/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Mock Callout for sending Session Id to Click
* @revision(s)
*/
@isTest
global class JDEServicesCallout_SessionMock  implements WebServiceMock {
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
            // start - specify the response you want to send
            JDEServicesCallout.SyncMasterDataSessionIdResponse_element response_x = new JDEServicesCallout.SyncMasterDataSessionIdResponse_element();
            response_x.Name = 'Done';
            // end
            response.put('response_x', response_x); 
        }
}