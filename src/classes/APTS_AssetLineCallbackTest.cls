/************************************************************* 
@Name: APTS_AssetLineCallbackTest 
@Author: Santosh Kumar
@CreateDate: 19th July, 2018
@Description: Test Class of APTS_AssetLineCallback.
******************************************************************/ 

@isTest
private class APTS_AssetLineCallbackTest {
    
    public static Account oTestAccount;
    public static Contact oTestContact;
    public static Opportunity oTestOpp;
    public static Product2 oproduct; 
    public static Apttus_Config2__PriceList__c oTestPricelist;
    public static Apttus_Config2__PriceListItem__c opriceListItem;
    public static Apttus_Config2__BillingPreference__c oBillPref;
    public static Apttus__APTS_Agreement__c oAggremt;
    public static Apttus_Config2__Order__c order;
    public static Apttus_Config2__Order__c orderxb23;
    public static Apttus_Config2__ProductConfiguration__c oProdconfig;
    public static Apttus_Config2__ProductConfiguration__c ordProdconfig;
    public static List<Apttus_Config2__AssetLineItem__c> oAssetLIList = new List<Apttus_Config2__AssetLineItem__c>();
    public static Boolean Trial=false;

    public static void init() {

        oTestAccount = APTS_TestUtils.createOrganisation();
        insert oTestAccount;

        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        oTestOpp = APTS_TestUtils.createOpportunity(oTestAccount.Id);
        insert oTestOpp;

        oproduct = APTS_TestUtils.createProduct('Test Package Cafitesse 50', '26940997', 'Machines');   
        insert oproduct;

        oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;

        opriceListItem = APTS_TestUtils.createPriceListItem(oTestPricelist.id, oproduct.id);
        insert opriceListItem;


        oBillPref = APTS_TestUtils.createBillingPrefrence();
        insert oBillPref;

        oAggremt = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccount.Id);
        oAggremt.Apttus__Contract_Start_Date__c = System.Today();
        oAggremt.Apttus__Agreement_Category__c = 'In Effect';
        oAggremt.Apttus__Contract_End_Date__c = System.Today().adddays(60);
        insert oAggremt;

        orderxb23 = APTS_TestUtils.createOrder('New', oTestPricelist.Id, oTestAccount.Id, oBillPref.Id);
        orderxb23.Apttus_CMConfig__AgreementId__c = oAggremt.Id;
        orderxb23.APTS_SAP_OrderType__c= 'XB23';
        insert orderxb23;
        
        order = APTS_TestUtils.createOrder('New', oTestPricelist.Id, oTestAccount.Id, oBillPref.Id);
        order.Apttus_CMConfig__AgreementId__c = oAggremt.Id;
        insert order;

        oProdconfig = APTS_TestUtils.getProductConfiguration2('Test config', 1, null, 'Agreement', 'Category' ,oTestPricelist.Id, 'Finalized', System.Today(), System.Today(), true);
        oProdconfig.Apttus_Config2__OrderId__c = order.Id;
        oProdconfig.Apttus_CMConfig__AgreementId__c = oAggremt.Id;
        oProdconfig.Apttus_Config2__BusinessObjectId__c = oAggremt.Id;
        oProdconfig.Apttus_Config2__AccountId__c=oTestAccount.Id;
        insert oProdconfig;
        
        ordProdconfig = APTS_TestUtils.getProductConfiguration2('Test config', 1, null, 'Agreement', 'Category' ,oTestPricelist.Id, 'Finalized', System.Today(), System.Today(), true);
        ordProdconfig.Apttus_Config2__OrderId__c = orderxb23.Id;
        ordProdconfig.Apttus_CMConfig__AgreementId__c = oAggremt.Id;
        ordProdconfig.Apttus_Config2__BusinessObjectId__c = oAggremt.Id;
        ordProdconfig.Apttus_Config2__AccountId__c=oTestAccount.Id;
        insert ordProdconfig;
        
        for(integer count=0;count<5;count++) {
            Apttus_Config2__AssetLineItem__c oAssetlineItem = APTS_TestUtils.createAssetLineItem(oTestAccount.Id, oproduct.Id, oTestPricelist.Id, opriceListItem.Id, oBillPref.Id, order.Id);
            if(math.mod(count,2) == 0 ) {
                oAssetlineItem.Apttus_CMConfig__AgreementId__c = oAggremt.Id;
            }
            oAssetLIList.add(oAssetlineItem);
        }
        insert oAssetLIList;

    }

    public static testMethod void filtermethodtest() {

        init();

        Test.startTest();
    
        APTS_AssetLineCallBack assetLineItemCallback = new APTS_AssetLineCallBack();
         assetLineItemCallback.isTrialOrder=true;
        Apttus_Config2.CustomClass.ActionParams params = new Apttus_Config2.CustomClass.ActionParams() ;
        params.AccountId = oTestAccount.Id;
    
       if(assetLineItemCallback.isTrialOrder) {
       Apttus_Config2.CallbackTester.testAssetLineItemCallback(ordProdconfig.Id, null, null, assetLineItemCallback, params);
       }
       

        List<Apttus_Config2__AssetLineItem__c> oALIList = [select id from Apttus_Config2__AssetLineItem__c where Apttus_CMConfig__AgreementId__c =: oAggremt.Id];
        system.assertNotEquals(oALIList.size(), 0);

        Test.stopTest();

    }
    
    public static testMethod void filtermethodtest1() {

        init();

        Test.startTest();
    
        APTS_AssetLineCallBack assetLineItemCallback = new APTS_AssetLineCallBack();
        Apttus_Config2.CustomClass.ActionParams params = new Apttus_Config2.CustomClass.ActionParams() ;
        params.AccountId = oTestAccount.Id;
    
       if(assetLineItemCallback.isTrialOrder) {
            Apttus_Config2.CallbackTester.testAssetLineItemCallback(oProdconfig.Id, null, null, assetLineItemCallback, params);
       }
      
        List<Apttus_Config2__AssetLineItem__c> oALIList = [select id from Apttus_Config2__AssetLineItem__c where Apttus_CMConfig__AgreementId__c =: oAggremt.Id];
        system.assertNotEquals(oALIList.size(), 0);

        Test.stopTest();

    }
    
    
}