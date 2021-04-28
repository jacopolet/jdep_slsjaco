/*************************************************************
@Name: APTS_LegalEntityChangeBatchTest
@Author: Pranjal Mittal
@CreateDate: 04-06-2018
@Description: Test clas for APTS_LegalEntityChangeBatch
@UsedBy: APTS_LegalEntityChangeBatch
******************************************************************/
@isTest
private class APTS_LegalEntityChangeBatchTest{

    @isTest
    static void testLegalEntityBatch(){
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact,false);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList,false);
        
        Account account = APTS_TestUtils.createaccount();
        Database.insert(account,false);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        Database.insert(agreement,false);
 
        Map<Id, Id> agreementMap = new Map<Id, Id>();
        agreementMap.put(agreement.Id, agreement.Id);
        
        Test.startTest();
            APTS_LegalEntityChangeBatch batch = new APTS_LegalEntityChangeBatch(agreementMap);
            Database.executeBatch(batch, 200);
        Test.stopTest();
        
        Apttus__APTS_Agreement__c agr=[SELECT Id,Name,Apttus__Agreement_Category__c FROM Apttus__APTS_Agreement__c WHERE Id =:agreement.Id];
        System.assertEquals('Agreement',agr.Name);
        System.assertEquals('Standard',agr.Apttus__Agreement_Category__c);
    }
}