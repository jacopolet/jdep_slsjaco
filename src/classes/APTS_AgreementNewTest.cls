/*****************************************************************************
@Name: APTS_AgreementNewTest
@Author: V. Shankaranarayanan
@CreateDate: 08-09-2018
@Description: Test class for APTS_AgreementNew class
*****************************************************************************/
@isTest
private class APTS_AgreementNewTest{
    
    /*
    @Name: testData
    @Description: Method to create test data
    @Parameters: None
    @Returns: void
    */
    @testSetup
    static void testData(){
        Account testAccount = APTS_TestUtils.createAccount();
        insert testAccount;
        
        Opportunity testOpp = APTS_TestUtils.createOpportunity(testAccount.Id);
        insert testOpp;
    }
    
    /*
    @Name: testCreation
    @Description: Method to test Agreement creation from Opportunity
    @Parameters: None
    @Returns: void
    */
    @isTest
    static void testCreation(){
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1][0];
        
        Test.StartTest(); 
            ApexPages.currentPage().getParameters().put('RecordType', recTypeId);
            ApexPages.currentPage().getParameters().put(Label.APTS_RelatedOpportunity, testOpp.Id);
            APTS_AgreementNew controller = new APTS_AgreementNew(new ApexPages.StandardController(new Apttus__APTS_Agreement__c()));
            controller.createAgreement();
        Test.StopTest();
        
        List<Apttus__APTS_Agreement__c> createdAgreementList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        system.assertEquals(createdAgreementList.size(), 1);
        
    }
    
    /*
    @Name: testCreationNotFromOpp
    @Description: Method to test Agreement is not created 
                   when not created from Opportunity
    @Parameters: None
    @Returns: void
    */
    @isTest
    static void testCreationNotFromOpp(){
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        Test.StartTest(); 
            ApexPages.currentPage().getParameters().put('RecordType', recTypeId);
            ApexPages.currentPage().getParameters().put(Label.APTS_RelatedOpportunity, null);
            APTS_AgreementNew controller = new APTS_AgreementNew(new ApexPages.StandardController(new Apttus__APTS_Agreement__c()));
            controller.createAgreement();
        Test.StopTest();
        
        List<Apttus__APTS_Agreement__c> createdAgreementList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        system.assertEquals(createdAgreementList.size(), 0);
    }
    
    /*
    @Name: testCreationException
    @Description: Method to test Agreement is not created 
                   when an exception occurs
    @Parameters: None
    @Returns: void
    */
    @isTest
    static void testCreationException(){
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        Test.StartTest(); 
            ApexPages.currentPage().getParameters().put('RecordType', recTypeId);
            ApexPages.currentPage().getParameters().put(Label.APTS_RelatedOpportunity, '123');
            APTS_AgreementNew controller = new APTS_AgreementNew(new ApexPages.StandardController(new Apttus__APTS_Agreement__c()));
            controller.createAgreement();
        Test.StopTest();
        
        /*List<Apttus__APTS_Agreement__c> createdAgreementList = [SELECT Id FROM Apttus__APTS_Agreement__c];
        system.assertEquals(createdAgreementList.size(), 0);*/
    }
    
    
}