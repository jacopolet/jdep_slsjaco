@isTest
public with sharing class APTS_InstalledAssetsControllerTest {

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(otestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        List<TriggerSettings__c> triggerSetting = [select id from TriggerSettings__c];
        Delete triggerSetting;
    }       


    @isTest
    static void testGetAssets(){
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
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('New', priceList.Id, account.Id, billingPreference.Id);
        order.Apttus_CMConfig__AgreementId__c = agreement.id;
        order.APTS_Requested_Installation_Date__c=null;
        insert order;
        
        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        Database.insert(product, false);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        Database.insert(priceListItem, false);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(agreement);
        Database.insert(oProductConfiguration);
        
        Apttus_Config2__AssetLineItem__c assetLineItem = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        assetLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem.Apttus_Config2__BundleAssetId__c = null;
        assetLineItem.APTS_Is_Primary_L1_Asset__c = null;
        assetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem.Apttus_Config2__HasOptions__c = true;
        Database.insert(assetLineItem, false);
        
        test.startTest();
            APTS_InstalledAssetsController.getAssetsRelatedToAccount(account.Id);
        test.stopTest();
    }    

}