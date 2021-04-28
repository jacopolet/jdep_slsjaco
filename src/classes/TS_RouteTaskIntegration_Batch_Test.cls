/*
* @author        Francis Alindogan
* @date          01.15.2020
* @description   Test class for TS_RouteTaskIntegration_Batch
* @revision(s)
*/


@isTest
public class TS_RouteTaskIntegration_Batch_Test {
    
    private static List<WorkOrder> woList = new List<WorkOrder>();
    private static List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
    
    @TestSetup
    public static void dataSetup() {

        String recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO).getRecordTypeId();

        List<WorkOrder> woListCreated = TS_TestDataFactory.createWorkOrderList(1);
        for(WorkOrder wo : woListCreated){
            wo.RecordtypeId = recordTypeId;
            wo.Status = 'Open';
            wo.WorkOrderType__c = 'S20';
            wo.SalesOrganization__c = 'SAP_0111';
            wo.SLA_Date__c = Date.today();
            woList.add(wo);
        }   
        insert woList;            
        
        String recordTypeIdWoli = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        
        List<WorkOrderLineItem> woliListCreated = TS_TestDataFactory.createWorkOrderLineItemList(5, null);
        for(WorkOrderLineItem woli : woliListCreated){
            woli.WorkOrderId = woList[0].Id;
            woli.RecordtypeId = recordTypeIdWoli;
            woli.Status = 'Open';
            woli.WorkOrderType__c = 'S20';
            woli.SLADate__c = Date.today();
            woli.isFromRoute__c = true;
            woliList.add(woli);
        }
        
        insert woliListCreated;
    }
    
    @isTest
    private static void batchTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            dataSetup();
            Test.startTest();
            	Date dateToday = Date.today();           
                TS_RouteTaskIntegration_Batch batch = new TS_RouteTaskIntegration_Batch(dateToday,true,1);
                DataBase.executeBatch(batch);
            Test.stopTest();
        }
        
        system.assertNotEquals(NULL, [select Id from WorkOrder].size());
    }       
    
}