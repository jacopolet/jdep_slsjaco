/*************************************************************
@Name: APTS_AssetPricingCorrectionBatchTest
@UsedBy: APTS_AssetPricingCorrectionBatch
******************************************************************/
//v100 26-04-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_AssetPricingCorrectionBatchTest {

   @isTest static void test_OrderFLITriggerHandler() {
       
       
       //create account
        Account acc1 = APTS_TestUtils.createaccount();
        acc1.ShippingCountry = 'Shipping Country';
        acc1.WSONE_DATA__ShippingAddressCountryISO__c = 'Country ISO';
        acc1.ShippingPostalCode = '123345';
        acc1.ShippingStreet = 'Street';
        acc1.WSONE_DATA__ShippingAddressHouseNumber__c = '123';
        acc1.ShippingCity = 'City';
        Database.insert(acc1,false);
        
        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        
        //create product
        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        prd.Name = 'Product Name';
        prd.Description = 'Product Description';
        prd.ProductCode = '2345';
        Database.insert(prd,false);
        
        // create priceList
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        //create pricelist item
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);
        
        //create billing preference
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
        
        //create order
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc1.Id,plist.Id,billpre.Id);
        Database.insert(order,false);
        
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc1.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        Database.insert(oPhysicalAsset, false);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(acc1.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AccountId__c = acc1.Id;
        ali.APTS_RefurbishedMachine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'New';
        ali.Apttus_Config2__StartDate__c = system.today();
        ali.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali.APTS_RefurbishedMachine__c = true;
        ali.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        Database.insert(ali, false);
        
        /*
       Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset.APTS_Old_Net_Price__c = 100;
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset;*/
       
       APTS_Asset_Correction_Configuration__c acc = new APTS_Asset_Correction_Configuration__c();
       acc.APTS_Is_Updated__c = false;
       acc.name = ali.id;
       acc.APTS_Asset_Line_Item__c = ali.id;
       insert acc;
       
       APTS_AssetPricingCorrectionBatch objbatch = new APTS_AssetPricingCorrectionBatch();
       Database.executeBatch(objbatch, 200);
       
   }


}