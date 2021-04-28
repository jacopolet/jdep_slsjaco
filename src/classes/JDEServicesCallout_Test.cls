/**
* @author        Adrian Reyes
* @date          4.6.2018
* @description   Test class for JDEServicesCallout
* @revision(s)
*/

@isTest
private class JDEServicesCallout_Test {
    static testMethod void testJDEServicesCallout(){
        Test.setMock(WebServiceMock.class, new JDEServicesCallout_Mock());
        
        //Create instances of inner classes
        JDEServicesCallout.History_element History_element = new JDEServicesCallout.History_element();
        JDEServicesCallout.RequiredParts_element RequiredParts_element = new JDEServicesCallout.RequiredParts_element();
        JDEServicesCallout.Part_element Part_element = new JDEServicesCallout.Part_element();
        JDEServicesCallout.Actions_element Actions_element = new JDEServicesCallout.Actions_element();
        JDEServicesCallout.ServiceOrderNotes_element ServiceOrderNotes_element = new JDEServicesCallout.ServiceOrderNotes_element();
        JDEServicesCallout.UserCreateResponse_element UserCreateResponse_element = new JDEServicesCallout.UserCreateResponse_element();
        JDEServicesCallout.SyncMasterDataSessionIdResponse_element SyncMasterDataSessionIdResponse_element = new JDEServicesCallout.SyncMasterDataSessionIdResponse_element();
        JDEServicesCallout.Ingredients_element Ingredients_element = new JDEServicesCallout.Ingredients_element();
        JDEServicesCallout.Activities_element Activities_element = new JDEServicesCallout.Activities_element();
        JDEServicesCallout.CounterReading_element CounterReading_element = new JDEServicesCallout.CounterReading_element();
        JDEServicesCallout.CounterReadings_element CounterReadings_element = new JDEServicesCallout.CounterReadings_element();
        JDEServicesCallout.Machine_element Machine_element = new JDEServicesCallout.Machine_element();
        JDEServicesCallout.NotifyUpdate_element NotifyUpdate_element = new JDEServicesCallout.NotifyUpdate_element();
        JDEServicesCallout.IngredientItem_element IngredientItem_element = new JDEServicesCallout.IngredientItem_element();
        JDEServicesCallout.TaskCreateOrUpdate_element TaskCreateOrUpdate_element = new JDEServicesCallout.TaskCreateOrUpdate_element();
        JDEServicesCallout.SafetyChecks_element SafetyChecks_element = new JDEServicesCallout.SafetyChecks_element();
        JDEServicesCallout.MachineList_element MachineList_element = new JDEServicesCallout.MachineList_element();
        JDEServicesCallout.NotifyUpdateResponse_element NotifyUpdateResponse_element = new JDEServicesCallout.NotifyUpdateResponse_element();
        JDEServicesCallout.ServiceMaterials_element ServiceMaterials_element = new JDEServicesCallout.ServiceMaterials_element();
        JDEServicesCallout.UserCreate_element UserCreate_element = new JDEServicesCallout.UserCreate_element();
        JDEServicesCallout.SyncMasterData_element SyncMasterData_element = new JDEServicesCallout.SyncMasterData_element();
        JDEServicesCallout.TaskResponse TaskResponse = new JDEServicesCallout.TaskResponse();
        JDEServicesCallout.Configurations_element Configurations_element = new JDEServicesCallout.Configurations_element();
        JDEServicesCallout.WarehouseIngredients_element WarehouseIngredients_element = new JDEServicesCallout.WarehouseIngredients_element();
        JDEServicesCallout.WarehouseItem_element WarehouseItem_element = new JDEServicesCallout.WarehouseItem_element();
        JDEServicesCallout.PartTypes PartTypes = new JDEServicesCallout.PartTypes();
        JDEServicesCallout.Sessions Sessions = new JDEServicesCallout.Sessions();
        JDEServicesCallout.TaskCreateOrUpdateResponse_element TaskCreateOrUpdateResponse_element = new JDEServicesCallout.TaskCreateOrUpdateResponse_element();
        JDEServicesCallout.PreferredEngineers_element PreferredEngineers_element = new JDEServicesCallout.PreferredEngineers_element();
        JDEServicesCallout.Parts_element Parts_element = new JDEServicesCallout.Parts_element();
        JDEServicesCallout.RequiredPart_element RequiredPart_element = new JDEServicesCallout.RequiredPart_element();
        JDEServicesCallout.ServiceOrderNote_element ServiceOrderNote_element = new JDEServicesCallout.ServiceOrderNote_element();
        JDEServicesCallout.UserResponse UserResponse = new JDEServicesCallout.UserResponse();
        JDEServicesCallout.ExcludedEngineers_element ExcludedEngineers_element = new JDEServicesCallout.ExcludedEngineers_element();
        JDEServicesCallout.HistoryItem_element HistoryItem_element = new JDEServicesCallout.HistoryItem_element();
        JDEServicesCallout.OptionalParameters_element OptionalParameters_element = new JDEServicesCallout.OptionalParameters_element();
        JDEServicesCallout.RequiredEngineers_element RequiredEngineers_element = new JDEServicesCallout.RequiredEngineers_element();
        JDEServicesCallout.ServiceMaterial_element ServiceMaterial_element = new JDEServicesCallout.ServiceMaterial_element();
        JDEServicesCallout.TaskCreateOrUpdateElement_element TaskCreateOrUpdateElement_element = new JDEServicesCallout.TaskCreateOrUpdateElement_element();
        JDEServicesCallout.SyncMasterDataResponse_element SyncMasterDataResponse_element = new JDEServicesCallout.SyncMasterDataResponse_element();
        JDEServicesCallout.PartTypeResponse PartTypeResponse = new JDEServicesCallout.PartTypeResponse();
        JDEServicesCallout.JDEServiceOptimizationPort JDEServiceOptimizationPort = new JDEServicesCallout.JDEServiceOptimizationPort();
        
        Test.startTest();
        //UserResponse = JDEServiceOptimizationPort.UserCreate('UserID', 'UserFullName', 1, 'UserEmail', 'Profile', 'Country', 'UserType', 'UserHRID', false);
        //String syncMasterDataResponse = JDEServiceOptimizationPort.SyncMasterData(new List<JDEServicesCallout.PartTypes>{PartTypes}, new List<JDEServicesCallout.Sessions>{Sessions});
        //PartTypeResponse = JDEServiceOptimizationPort.SyncMasterData(new List<JDEServicesCallout.PartTypes>{PartTypes});
        TaskResponse = JDEServiceOptimizationPort.TaskCreateOrUpdate(TaskCreateOrUpdate_element);
        NotifyUpdateResponse_element = JDEServiceOptimizationPort.NotifyUpdate('CallID', 1);
        Test.stopTest();
        
        //Verify results
        //System.assertNotEquals(null, userResponse);
        //System.assertNotEquals(null, syncMasterDataResponse);
        //System.assertNotEquals(null, PartTypeResponse);
        System.assertNotEquals(null, TaskResponse);
        System.assertNotEquals(null, NotifyUpdateResponse_element);
    }
}