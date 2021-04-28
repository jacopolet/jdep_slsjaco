@isTest
private with sharing class APTS_MyFavouritesCtrlTest{
    private static testMethod void test_redirect(){
        
        Account acc = APTS_TestUtils.createOrganisationproduct();
        acc.Name = 'Test Asset Acct';
        Database.insert(acc);
        
        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;
        
        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;
        
        Apttus__APTS_Agreement__c oAggremt1 = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acc.id);
        insert oAggremt1;
        
        Apttus_Config2__ProductConfiguration__c testProdConfig = APTS_TestDataFactory.createProductConfig(oAggremt1 );
        //testProdConfig.Apttus_Config2__CouponCodes__c = 'TEST';
        Database.insert(testProdConfig);
        ApexPages.currentPage().getParameters().put('id', testProdConfig.Id);
        ApexPages.currentPage().getParameters().put('flow', 'flow');
        ApexPages.currentPage().getParameters().put('icode', 'None');
        ApexPages.currentPage().getParameters().put('configRequestId', 'configRequestId');
        APTS_MyFavouritesCtrl myfavt = new APTS_MyFavouritesCtrl();
        PageReference  pageRef = myfavt.redirectToFavoritePage();
    }
}