@isTest
private class APTS_DigitalOrderFinalizeBatchTest {
    @testSetup static void setupTestData() {
        Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
        order.APTS_Order_Sub_Type__c = 'Digital Order';
        order.APTS_Source_Order_Number__c = 'sn1232';
        insert order;

        Apttus_Config2__ProductConfiguration__c oConfig = new Apttus_Config2__ProductConfiguration__c();
        oConfig.Apttus_Config2__OrderId__c = order.id;
        oConfig.Apttus_Config2__BusinessObjectType__c = 'Order';
        oConfig.Apttus_Config2__Status__c = 'New';
        insert oConfig;

        APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
        oLog.APTS_Message__c = 'sJSONClass';
        oLog.APTS_SourceOrderNumber__c = 'sn1232';
        oLog.APTS_Status__c = 'New';
        insert oLog;
        
        Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__OrderId__c = order.id;
        insert oli;
        
        APTS_Order_Error_Log__c oErrorlog = new APTS_Order_Error_Log__c();
        oErrorlog.APTS_Source_Order_Number__c = oLog.id;
        oErrorlog.APTS_Status__c = 'New';
        insert oErrorlog;
        
    }

    @isTest static void test_method_one() {
        Set<Id> setOrderID = new Set<Id>();
        Set<Id> setInterface = new Set<Id>();
        for(Apttus_Config2__Order__c order :  [select id from Apttus_Config2__Order__c limit 1]){
            setOrderID.add(order.Id);
        }

        for(APTS_Order_Interface_Log__c olog : [select id from APTS_Order_Interface_Log__c limit 1]){
            setInterface.add(olog.Id);
        }
        
        test.startTest();
        APTS_DigitalOrderFinalizeBatch batch = new APTS_DigitalOrderFinalizeBatch(setOrderID, setInterface, null);
        Database.executeBatch(batch, 200);
        test.stopTest();
    }
    
}