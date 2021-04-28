/**
 * Karen Hung 14.9.2020
 * DOO-4684 test class for TS_CancelWOLIController
 */
@isTest
private with sharing class TS_CancelWOLIController_Test {
    
    static PhysicalAsset__c pa;
    static WorkOrder wo1;
    static WorkOrder wo2;
    static WorkOrderLineItem woli1;
    static WorkOrderLineItem woli2;
    static Case caseRec;

    @TestSetup
    static void dataSetup() {

        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = false;
        trg.CaseTrigger__c =  false;
        trg.WorkOrderTrigger__c = false;
        upsert trg;
        
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = false;
        pb.WorkOrderLineItemPBFlows__c = false;
        insert pb;

        ValidationRulesSettings__c vrSetting = new ValidationRulesSettings__c();
        vrSetting.WorkOrderLineItemValidationRules__c = false;
        vrSetting.CaseValidationRules__c = false;
        insert vrSetting;

    }

    /*method to create test data*/
    static void setupTestData(){
        
        List<WorkOrderLineItem> woliforInsert =  new List<WorkOrderLineItem>();
        List<WorkOrder> woforInsert = new List<WorkOrder>();

        caseRec = TS_TestDataFactory.createCase('Test case Subject');

        wo1 =  TS_TestDataFactory.createWorkOrder();
        woforInsert.add(wo1);
        wo2 = TS_TestDataFactory.createWorkOrder();
        woforInsert.add(wo2);
        insert(woforInsert);

        woli1 = TS_TestDataFactory.createWorkOrderLineItem(wo1.Id);
        woli1.Case__c = caseRec.Id;
        woliforInsert.add(woli1);
        woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo2.Id);
        woli2.Case__c = caseRec.Id;
        woliforInsert.add(woli2);
        insert(woliforInsert);

    }

    /*test method for hasCompletedTask method*/
    static testMethod void hasCompletedTask_Test(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u){
            setupTestData();
            test.startTest();
            woli1.Status = 'Completed';
            update woli1;
            Boolean hasCompleted = TS_CancelWOLIController.hasCompletedTask(woli2.Id);
            test.stopTest();
            System.assertEquals(hasCompleted, true);
        }

    }

    /*test method for cancelAndCompleteCase*/
    static testMethod void cancelAndCompleteCase_Test(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u){
            setupTestData();
            test.startTest();
            woli1.Status = 'Completed';
            update woli1;
            TS_CancelWOLIController.hasException = false;
            String returnVal = TS_CancelWOLIController.cancelAndCompleteCase(woli2.Id,caseRec.Id,'Cancelation Reason');
            test.stopTest();
            System.assert(woli2.Status != null);
            
        }
    }

    /*test method for cancelAndCompleteCase with exception*/
    static testMethod void cancelAndCompleteCaseEx_Test(){
         User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
         System.RunAs(u){
            setupTestData(); 
            test.startTest();
            TS_CancelWOLIController.hasException = true;
            String returnVal = TS_CancelWOLIController.cancelAndCompleteCase(woli2.Id,caseRec.Id,'Cancelation Reason');
            test.stopTest();
            System.assert(caseRec.Status != 'Closed');
        }
    }

}