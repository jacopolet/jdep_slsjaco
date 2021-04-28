/**
* Class Name   : APTS_DeleteOpenOrdersBatch_Test 
* Description  : Test class for APTS_DeleteOpenOrdersBatch
* Author       : Hariharan
* Date Created : 02/20/2018
**/
@isTest
private class APTS_DeleteOpenOrdersBatch_Test{

    
    private static testMethod void testOrderDeletion(){     
        string acctName = 'Test'+ string.valueOf(Math.random());
        Account testAccount = APTS_TestDataFactory.createAccount(acctName);
        Database.insert(testAccount, false); 
        
        Apttus_Config2__PriceList__c  testPriceList = APTS_TestDataFactory.createPriceList('Test JDE PriceList');
        Database.insert(testPriceList, false);  
        
        Contact testContact = APTS_TestDataFactory.createContact(testAccount ,'9999912345');
        Database.insert(testContact, false);
        
        Apttus_Config2__Order__c  testOrder = APTS_TestDataFactory.createOrder(testAccount.Id, testPriceList.Id, testContact.Id);      
        testOrder.APTS_Requested_Installation_Date__c = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7)); 
        Database.insert(testOrder);
     
        test.startTest();
        APTS_DeleteOpenOrdersBatch batch = new APTS_DeleteOpenOrdersBatch();
        Database.executeBatch(batch, 200);
        test.stopTest();
        
        Apttus_Config2__Order__c deletedOrder = [SELECT Id, IsDeleted FROM Apttus_Config2__Order__c 
                                                      WHERE LastModifiedDate >=LAST_N_DAYS :90 LIMIT 1 ALL ROWS][0];
         //Apttus_Config2__Order__c deletedOrder = [SELECT Id, IsDeleted FROM Apttus_Config2__Order__c 
                                                     // WHERE id= 'a3G4E0000001YC7'];
        System.AssertEquals(deletedOrder.IsDeleted, true);
    }      
}