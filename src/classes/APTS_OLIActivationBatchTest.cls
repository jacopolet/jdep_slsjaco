@isTest
private with sharing class APTS_OLIActivationBatchTest {
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }
        
    @isTest static void test_OLIActivationBatch() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        
                
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        APTS_Asset_Correction_Configuration__c acc = new APTS_Asset_Correction_Configuration__c();
        for(Apttus_Config2__OrderLineItem__c oli:orderLineItemList){
            oli.APTS_Status__c= 'Fulfilled';
            oli.Apttus_Config2__ActivatedDate__c=null;
            oli.Apttus_Config2__ReadyForBillingDate__c=null;
            
            acc.APTS_Is_Updated__c = false;
            acc.name = oli.id;
            acc.APTS_Asset_Line_Item__c = oli.id;
       
        }
        
        insert acc;
        update orderLineItemList;
        
       

       Test.startTest();
         
        System.runAs(oTestUser) {
        
        APTS_OLIActivationBatch cb = New APTS_OLIActivationBatch();
        Database.QueryLocator ql = cb.start(null);
        cb.execute(null,orderLineItemList);
        cb.Finish(null);
            
        }
        
       Test.stopTest();
   }
}