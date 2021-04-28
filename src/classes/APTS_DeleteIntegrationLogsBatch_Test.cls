/**
* Class Name : APTS_DeleteIntegrationLogsBatch_Test
* Description :  Apex Class to test APTS_DeleteIntegrationLogsBatch class
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 01/31/2018
**/
@isTest
private class APTS_DeleteIntegrationLogsBatch_Test{
    
    private static String status = 'Target System Success';
    
    /**Method Name : testData
    * Description : Method used to create test data
    **/
    @testSetup
    static void testData(){
        IntegrationUserAndProfile__c custSetting = APTS_TestDataFactory.createIntegrationUserAndProfile();
        Database.insert(custSetting, false);
        
        List<Integration_Log__c> logList = APTS_TestDataFactory.createIntegrationLog(200, status);
        Database.insert(logList, false);
    }
    
    /**Method Name : testSAPDeletion
    * Description : Method used to test whether old SAP Integration Log records are deleted properly
    **/
    @isTest
    static void testSAPDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c 
                                        WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchTypeSAP;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeSAP, Integer.valueOf(custSetting.SAP_Deletion_Day__c));
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
    
    
    /**Method Name : testNonSAPNonDeletion
    * Description : Method used to test whether Non-SAP Integration Log records are not deleted when interface is given as SAP
    **/
    @isTest
    static void testNonSAPNonDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchLimit;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeSAP, Integer.valueOf(custSetting.SAP_Deletion_Day__c));
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

    /**Method Name : testClickDeletion
    * Description : Method used to test whether old Click Integration Log records are deleted properly
    **/
    @isTest
    static void testClickDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchTypeClick;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeClick, Integer.valueOf(custSetting.Click_Deletion_Day__c));
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
    
    /**Method Name : testNonClickNonDeletion
    * Description : Method used to test whether Non-Click Integration Log records are not deleted when interface is given as Click
    **/
    @isTest
    static void testNonClickNonDeletion(){
               
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchLimit;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeClick, Integer.valueOf(custSetting.Click_Deletion_Day__c));
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
    
    /**Method Name : testDigitalDeletion
    * Description : Method used to test whether old Digital Integration Log records are deleted properly
    **/
    @isTest
    static void testDigitalDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchTypeDigital;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeDigital, Integer.valueOf(custSetting.Digital_Deletion_Day__c));
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
    
    /**Method Name : testNonDigitalNonDeletion
    * Description : Method used to test whether Non-Digital Integration Log records are not deleted when interface is given as Digital
    **/
    @isTest
    static void testNonDigitalNonDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchLimit;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeDigital, Integer.valueOf(custSetting.Digital_Deletion_Day__c));
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
    
    /**Method Name : testAllDeletion
    * Description : Method used to test whether All old Integration Log records are deleted properly
    **/
    @isTest
    static void testAllDeletion(){
        
        List<Integration_Log__c> logUpdateList = new List<Integration_Log__c>();
        for(Integration_Log__c log : [SELECT Id FROM Integration_Log__c WHERE Integration_Status__c =: status LIMIT 50000]){
            log.Object__c = Label.APTS_IntegrationLogBatchTypeAll;
            logUpdateList.add(log);
        }
        Database.update(logUpdateList, false);
        
        IntegrationUserAndProfile__c custSetting =  IntegrationUserAndProfile__c.getOrgDefaults();
        
        test.startTest();
        APTS_DeleteIntegrationLogsBatch batch = new APTS_DeleteIntegrationLogsBatch(Label.APTS_IntegrationLogBatchTypeAll, Integer.valueOf(custSetting.All_Deletion_Day__c));
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
}