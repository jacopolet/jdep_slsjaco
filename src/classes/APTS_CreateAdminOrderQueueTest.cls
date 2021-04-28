@isTest
private class APTS_CreateAdminOrderQueueTest {
    
    @testSetup
    static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }

    @isTest
    static void testUtil(){
        Contact contact = APTS_TestUtils.createContact();
        Database.insert(contact, false);

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        List<Account> childAccountList = new List<Account>();

        Account account = APTS_TestUtils.createaccount();
        insert account;

        Account childAccount = APTS_TestUtils.createChildAccount(account);
        insert childAccount;

        childAccountList.add(childAccount);

        Apttus__APTS_Agreement__c agreement = APTS_TestUtils.createAgreement(contact.Id, null, priceList.Id, account.Id);
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        agreement.Apttus__Auto_Renewal__c = false;
        agreement.Apttus__Contract_End_Date__c = System.Today() - 1;
        agreement.APTS_Order_Non_Contracted_Products__c = true;
        Database.insert(agreement, false);

        APTS_CLMUtil.setContractedProductsOnly(childAccountList, null);

        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
        Database.insert(billingPreference, false);
                        
        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        Database.insert(product, false);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        Database.insert(priceListItem, false);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(agreement);
        Database.insert(oProductConfiguration);
               
        test.startTest();
        System.enqueueJob(new APTS_CreateAdminOrderQueue(agreement));
        test.stopTest();
             
    }

}