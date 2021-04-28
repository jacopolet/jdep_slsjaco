/**
* Class Name : APTS_DeleteFireAndForgetIntLogBatch_Test
* Description :  Apex Class to test APTS_DeleteFireAndForgetIntLogsBatch class
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 07-05-2018
**/
@isTest
private class APTS_DeleteFireAndForgetIntLogBatch_Test{
    
    private static String status = 'Outbound Message Triggered';
    
    /**Method Name : testData
    * Description : Method used to create test data
    **/
    @testSetup
    static void testData(){
        IntegrationUserAndProfile__c custSetting = APTS_TestDataFactory.createIntegrationUserAndProfile();
        Database.insert(custSetting, false);
        
        List<APTS_IntegrationLogFireForgetInterfaces__c> interfaceSetting = APTS_TestDataFactory.createFandFInterfaces();
        Database.insert(interfaceSetting, false);
        
        List<Integration_Log__c> logList = APTS_TestDataFactory.createIntegrationLog(200, status);
        Database.insert(logList, false);
    }
    
    /**Method Name : testRelatedInvoiceDeletion
    * Description : Method used to test whether the old Integration Log records
    * related to 'RelatedInvoice__c' Fire and Forget interface are deleted properly
    **/
    @isTest
    static void testRelatedInvoiceDeletion(){
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id, Object__c FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = 'RelatedInvoice__c';
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        test.startTest();
        APTS_DeleteFireAndForgetIntLogsBatch batch = new APTS_DeleteFireAndForgetIntLogsBatch();
        Database.executeBatch(batch, 200);
        test.stopTest();
        
        List<Integration_Log__c> deletedLogList = new List<Integration_Log__c>();
        for(Integration_Log__c deletedLog : [SELECT Id, IsDeleted FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000 ALL ROWS]){
            if(deletedLog.IsDeleted){
                deletedLogList.add(deletedLog);
            }
        }
        
        System.AssertEquals(200, deletedLogList.size());
    }
    
    /**Method Name : testAccountHierarchyDeletion
    * Description : Method used to test whether the old Integration Log records
    * related to 'Account Hierarchy' Fire and Forget interface are deleted properly
    **/
    @isTest
    static void testAccountHierarchyDeletion(){
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id, Object__c FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = 'Account Hierarchy';
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        test.startTest();
        APTS_DeleteFireAndForgetIntLogsBatch batch = new APTS_DeleteFireAndForgetIntLogsBatch();
        Database.executeBatch(batch, 200);
        test.stopTest();
        
        List<Integration_Log__c> deletedLogList = new List<Integration_Log__c>();
        for(Integration_Log__c deletedLog : [SELECT Id, IsDeleted FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000 ALL ROWS]){
            if(deletedLog.IsDeleted){
                deletedLogList.add(deletedLog);
            }
        }
        
        System.AssertEquals(200, deletedLogList.size());
    }
    
    /**Method Name : testWOLICatsRecordDeletion
    * Description : Method used to test whether the old Integration Log records
    * related to 'Work Order Line Item - CATS-record' Fire and Forget interface are deleted properly
    **/
    @isTest
    static void testWOLICatsRecordDeletion(){
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id, Object__c FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = 'Work Order Line Item - CATS-record';
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        test.startTest();
        APTS_DeleteFireAndForgetIntLogsBatch batch = new APTS_DeleteFireAndForgetIntLogsBatch();
        Database.executeBatch(batch, 200);
        test.stopTest();
        
        List<Integration_Log__c> deletedLogList = new List<Integration_Log__c>();
        for(Integration_Log__c deletedLog : [SELECT Id, IsDeleted FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000 ALL ROWS]){
            if(deletedLog.IsDeleted){
                deletedLogList.add(deletedLog);
            }
        }

        System.AssertEquals(200, deletedLogList.size());
    }
    
    /**Method Name : testNonFandFNonDeletion
    * Description : Method used to test whether the old Integration Log records not
    * related to Fire and Forget interfaces are not deleted
    **/
    @isTest
    static void testNonFandFNonDeletion(){
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id, Object__c FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = status;//Outbound Message Triggered
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        test.startTest();
        APTS_DeleteFireAndForgetIntLogsBatch batch = new APTS_DeleteFireAndForgetIntLogsBatch();
        Database.executeBatch(batch, 200);
        test.stopTest();
        
        List<Integration_Log__c> deletedLogList = new List<Integration_Log__c>();
        for(Integration_Log__c deletedLog : [SELECT Id, IsDeleted FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000 ALL ROWS]){
            if(deletedLog.IsDeleted){
                deletedLogList.add(deletedLog);
            }
        }

        System.AssertEquals(0, deletedLogList.size());
    }
}