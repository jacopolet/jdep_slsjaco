/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Mock Callout for GetAvailableSlot
* @revision(s)
*/
@isTest
global class GetAvailableSlotsMock  implements WebServiceMock {
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
            GetAvailableSlots.SXPExtendedTaskGetAppointmentsEx2Response_element  response_x = new  GetAvailableSlots.SXPExtendedTaskGetAppointmentsEx2Response_element();
            GetAvailableSlots.TimeIntervalTypeList OptionalAppointments = new GetAvailableSlots.TimeIntervalTypeList();
            List<GetAvailableSlots.TimeIntervalType> TimeInterval = new List<GetAvailableSlots.TimeIntervalType>();
            GetAvailableSlots.TimeIntervalType TimeIntervalType = new GetAvailableSlots.TimeIntervalType();
            TimeIntervalType.Start = '2015-05-03T10:00';
            TimeIntervalType.Finish = '2015-05-03T12:00';
            TimeInterval.add(TimeIntervalType);

            TimeIntervalType = new GetAvailableSlots.TimeIntervalType();
            TimeIntervalType.Start = '2015-05-03T12:00';
            TimeIntervalType.Finish = '2015-05-03T14:00';
            TimeInterval.add(TimeIntervalType);
            
            OptionalAppointments.TimeInterval = TimeInterval;
            response_x.OptionalAppointments = OptionalAppointments;
            
            // end
            response.put('response_x', response_x); 
        }

}