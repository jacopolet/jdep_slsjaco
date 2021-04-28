@isTest
private with sharing class APTS_ReturnOrderBatchTest{
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }
    
    @isTest static void test_ReturnOrderBatch() {
        
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_Config2__Status__c ='Activated';
        oOrder.APTS_SAP_OrderType__c ='XB13';
        update oOrder;
        
        
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        List<Apttus_Config2__OrderLineItem__c> oliList= new List<Apttus_Config2__OrderLineItem__c>();
        
        for(Apttus_Config2__OrderLineItem__c oli:orderLineItemList){
        oli.APTS_SAP_OrderType__c ='XB13';
        oli.Apttus_Config2__LineType__c='Product/Service';
        oli.APTS_Type_of_Contract__c='Sales';
        oli.Apttus_Config2__ChargeType__c='Sales Price';
        oli.Apttus_Config2__Status__c = 'Activated';
        oliList.add(oli);
        }
        update oliList;
        
        Apttus_Config2__OrderFulfillment__c orderfull= new  Apttus_Config2__OrderFulfillment__c(
        );
        insert orderfull;
        
        Apttus_Config2__OrderFulfillmentLineItem__c  ofli= new Apttus_Config2__OrderFulfillmentLineItem__c (
            Apttus_Config2__LineNumber__c=1,
            APTS_GoodsIssue_Status__c='Completely Processed',
            Apttus_Config2__OrderLineItemId__c=oliList[1].id,
            APTS_Material_Number_SAP__c='101',
            APTS_Fulfilled_Quantity__c=1 ,Apttus_Config2__OrderFulfillmentId__c=orderfull.id,Apttus_Config2__OrderId__c=oOrder.Id);
        insert ofli;
        
        Test.startTest();
        System.runAs(oTestUser) {
            
            APTS_ReturnOrderBatch cb = New APTS_ReturnOrderBatch();
            Database.QueryLocator ql = cb.start(null);
            cb.execute(null,orderLineItemList);
            cb.Finish(null);
            
        }
        Test.stopTest();
    }
}