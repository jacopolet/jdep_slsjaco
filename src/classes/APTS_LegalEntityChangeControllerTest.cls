/*************************************************************
@Name: APTS_LegalEntityChangeControllerTest
@Author: Pranjal Mittal
@CreateDate: 29-05-2018
@Description: Test clas for APTS_LegalEntityChangeController
@UsedBy: APTS_LegalEntityChangeController
******************************************************************/
@isTest
private class APTS_LegalEntityChangeControllerTest{

    @isTest
    static void testLegalEntityController(){
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact,false);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList,false);
        
        List<Account> accountList = new List<Account>();
        Account account = APTS_TestUtils.createaccount();
        accountList.add(account);
        
        Account account2 = APTS_TestUtils.createaccount();
        account2.Name = 'Test Account';
        accountList.add(account2);
        Database.insert(accountList,false);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        agreement.Apttus__Contract_End_Date__c = System.Today();
        agreement.Apttus__Auto_Renewal__c = false;
        Database.insert(agreement, false);
        
        Test.startTest();
        APTS_LegalEntityChangeController.getClonedAgreement(agreement.Id, account2.Id);
        Test.stopTest();
        
        Apttus__APTS_Agreement__c oAggr = [SELECT Id, Name, Apttus__Account__c, Apttus__Status__c,
                    Apttus__FF_Agreement_Number__c, RecordType.Name
                    FROM Apttus__APTS_Agreement__c
                    WHERE Id = :agreement.Id];
        System.AssertNotEquals(account2.Id,oAggr.Apttus__Account__c);
        System.assertEquals(agreement.Id,oAggr.Id);     
        
    }
}