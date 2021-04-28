/**
* @author        Adrian Reyes
* @date          4.18.2018
* @description   Test class for GetAvailableSlots
* @revision(s)
*/

@isTest
private class GetAvailableSlots_Test {
    static testMethod void testGetAvailableSlots(){
        Test.startTest();
        //Create instances of inner classes
        GetAvailableSlots.MachineList_element MachineList_element = new GetAvailableSlots.MachineList_element();
        GetAvailableSlots.ExcludedEngineers_element ExcludedEngineers_element = new GetAvailableSlots.ExcludedEngineers_element();
        GetAvailableSlots.TimeIntervalTypeList TimeIntervalTypeList = new GetAvailableSlots.TimeIntervalTypeList();
        GetAvailableSlots.OptionalParameters_element OptionalParameters_element = new GetAvailableSlots.OptionalParameters_element();
        GetAvailableSlots.TimeInterval_element TimeInterval_element = new GetAvailableSlots.TimeInterval_element();
        GetAvailableSlots.RequiredEngineers_element RequiredEngineers_element = new GetAvailableSlots.RequiredEngineers_element();
        GetAvailableSlots.GetSlotsTaskType GetSlotsTaskType = new GetAvailableSlots.GetSlotsTaskType();
        GetAvailableSlots.Machine_element Machine_element = new GetAvailableSlots.Machine_element();
        GetAvailableSlots.TimeIntervalType TimeIntervalType = new GetAvailableSlots.TimeIntervalType();
        GetAvailableSlots.GetAvailableSlots_element GetAvailableSlots_element = new GetAvailableSlots.GetAvailableSlots_element();
        GetAvailableSlots.SXPExtendedTaskGetAppointmentsEx2Response_element SXPExtendedTaskGetAppointmentsEx2Response_element = new GetAvailableSlots.SXPExtendedTaskGetAppointmentsEx2Response_element();
        GetAvailableSlots.ProcessSlot_element ProcessSlot_element = new GetAvailableSlots.ProcessSlot_element();
        GetAvailableSlots.ProcessSlotResponse_element ProcessSlotResponse_element = new GetAvailableSlots.ProcessSlotResponse_element();
        GetAvailableSlots.SlotResponse SlotResponse = new GetAvailableSlots.SlotResponse();
        GetAvailableSlots.Tasks Tasks = new GetAvailableSlots.Tasks();
        Test.stopTest();
        
        //Verify results
        System.assertNotEquals(null, MachineList_element);
        System.assertNotEquals(null, ExcludedEngineers_element);
        System.assertNotEquals(null, TimeIntervalTypeList);
        System.assertNotEquals(null, OptionalParameters_element);
        System.assertNotEquals(null, TimeInterval_element);
        System.assertNotEquals(null, RequiredEngineers_element);
        System.assertNotEquals(null, GetSlotsTaskType);
        System.assertNotEquals(null, Machine_element);
        System.assertNotEquals(null, TimeIntervalType);
        System.assertNotEquals(null, GetAvailableSlots_element);
        System.assertNotEquals(null, SXPExtendedTaskGetAppointmentsEx2Response_element);
        System.assertNotEquals(null, ProcessSlot_element);
        System.assertNotEquals(null, ProcessSlotResponse_element);
        System.assertNotEquals(null, SlotResponse);
        System.assertNotEquals(null, Tasks);
    }
}