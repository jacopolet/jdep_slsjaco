/*
* @author        Francis Alindogan
* @date          01.30.2020
* @description   Test class for TS_RouteTaskIntegrationRoute_Batch
* @revision(s)
*/

@isTest
public with sharing class TS_RouteTaskIntegrationRoute_BatchTest {
     static List<WorkOrder> woList = new List<WorkOrder>();
    

    
    @TestSetup
    public static void dataSetup() {

        String recordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO).getRecordTypeId();

        List<WorkOrder> woListCreated = TS_TestDataFactory.createWorkOrderList(5);
        for(WorkOrder wo : woListCreated){
            wo.RecordtypeId = recordTypeId;
            wo.Status = 'Open';
            wo.WorkOrderType__c = 'S20';
            wo.SalesOrganization__c = 'SAP_0111';
            wo.SLA_Date__c = DateTime.now();
            woList.add(wo);
        }   
        insert woList;            
    }
    
    @isTest
    private static void batchTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            dataSetup();
            Test.startTest();
            	Date dateToday = date.today();
            Set<Id> woIds = new Set<Id>();
            for(WorkOrder wo: woList){
               woIds.add(wo.Id);
            }
            TS_RouteTaskIntegrationRoute_Batch batch = new TS_RouteTaskIntegrationRoute_Batch(dateToday, true, 1, woIds);
            DataBase.executeBatch(batch);
            Test.stopTest();
        }
        system.assertNotEquals(NULL, [select Id from WorkOrder].size());
    }       
}