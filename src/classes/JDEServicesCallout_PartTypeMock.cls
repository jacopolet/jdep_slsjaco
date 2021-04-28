/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Mock Callout for Sync Master Data
* @revision(s)
*/
@isTest
global class JDEServicesCallout_PartTypeMock  implements WebServiceMock {
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
            JDEServicesCallout.SyncMasterDataResponse_element response_x = new JDEServicesCallout.SyncMasterDataResponse_element();
            List<JDEServicesCallout.PartTypeResponse> PartType = new List<JDEServicesCallout.PartTypeResponse>();
            JDEServicesCallout.PartTypeResponse part = new JDEServicesCallout.PartTypeResponse();
            part.Name = 'ProdName';
            part.PartID = '123456';
            PartType.add(part);            
             
            response_x.PartType = part;
            // end
            response.put('response_x', response_x); 
        }
}