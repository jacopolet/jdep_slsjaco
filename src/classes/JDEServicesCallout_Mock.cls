/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Mock Callout for TaskCreateOrUpdate
* @revision(s)
*/
@isTest
global class JDEServicesCallout_Mock  implements WebServiceMock {
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
            JDEServicesCallout.TaskResponse response_x = new JDEServicesCallout.TaskResponse();
            response_x.CallID = '123';
            response_x.Status = 'Complete';
            response_x.Team = 'Salesforce';
            // end
            
            //4.6.2018: Added by Adrian to handle multiple methods
            if(requestName == 'TaskCreateOrUpdate')
            	response.put('response_x', response_x);
            else if(requestName == 'UserCreate')
                response.put('response_x', new JDEServicesCallout.UserResponse());
            else if(requestName == 'SyncMasterData' && responseName == 'SessionID')
                response.put('response_x', 'Test String');
            else if(requestName == 'SyncMasterData' && responseName == 'PartTypes')
                response.put('response_x', new JDEServicesCallout.PartTypeResponse());
            else if(requestName == 'NotifyUpdate')
                response.put('response_x', new JDEServicesCallout.NotifyUpdateResponse_element());
        }
}