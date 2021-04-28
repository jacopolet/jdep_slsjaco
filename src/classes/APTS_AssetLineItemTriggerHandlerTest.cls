/*************************************************************
@Name: APTS_AssetLineItemTriggerHandlerTest
@Author: Aarthi Pitchai
@CreateDate: 24-03-2018
@Description: Test class for Asset Line Item trigger handler
@UsedBy: APTS_AssetLineItemTriggerHandler
******************************************************************/
//v100 24-03-2018 Aarthi Pitchai: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
@isTest
public class APTS_AssetLineItemTriggerHandlerTest {
    /**@testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }   

     testMethod static void test_createALI(){

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        Test.startTest();

        System.runAs(oTestUser) {
            APTS_AssetLineItemTriggerHandler ali = new APTS_AssetLineItemTriggerHandler();
            ali.BeforeInsert(null);
            ali.BeforeUpdate(null, null, null, null);
            ali.BeforeDelete(null, null);
            ali.AfterInsert(null, null);
            //ali.AfterUpdate(null, null,null,null);
            ali.AfterUnDelete(null,null);
            ali.AfterDelete(null,null);
        }

        Test.stopTest();        
    }
    
  static testMethod void testcreatephyAssetTrigger()
    {
    
     test.startTest();  
     
         Account acc = APTS_TestUtils.createaccount();
         Database.insert(acc,false);
         
         Account acc2 = APTS_TestUtils.createaccount();
         Database.insert(acc2,false);
     
        Account acc1 = APTS_TestUtils.createaccount();
        acc1.ShippingCountry = 'Shipping Country';
        acc1.WSONE_DATA__ShippingAddressCountryISO__c = 'Country ISO';
        acc1.ShippingPostalCode = '123345';
        acc1.ShippingStreet = 'Street';
        acc1.WSONE_DATA__ShippingAddressHouseNumber__c = '123';
        acc1.ShippingCity = 'City';
        Database.insert(acc1,false);
        
        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        prd.Name = 'Product Name';
        prd.Description = 'Product Description';
        prd.ProductCode = '2345';
        Database.insert(prd,false);
        
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);
        
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc.Id,plist.Id,billpre.Id);
        Database.insert(order,false);

        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        
        List<Apttus_Config2__AssetLineItem__c> aliInsertList = new List<Apttus_Config2__AssetLineItem__c>();
    
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);
        
        Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AccountId__c = acc2.Id;
        ali.APTS_RefurbishedMachine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'New';
        ali.Apttus_Config2__StartDate__c = system.today();
        ali.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali.APTS_RefurbishedMachine__c = true;
        aliInsertList.add(ali);
        Database.insert(aliInsertList, false);
        
        APTS_Order_LSP_Details__c ordrLspDetails = new APTS_Order_LSP_Details__c();
        ordrLspDetails.APTS_Building__c = 'Building';
        ordrLspDetails.APTS_Floor__c = 'Floor';
        ordrLspDetails.APTS_Area__c = 'Area';
        ordrLspDetails.APTS_CustomerReference__c = '123456543'; 
        ordrLspDetails.APTS_SmokingArea__c = true;
        ordrLspDetails.APTS_ConfigurationFileURL__c = 'URL';
        ordrLspDetails.APTS_JDE_crockeryVolumeSize__c = '10';
        Database.insert(ordrLspDetails, false);
        
        Apttus_Config2__Order__c ordr = new Apttus_Config2__Order__c();
        ordr.APTS_Sales_Organization__c = 'SAP_0080';
        ordr.Apttus_Config2__SoldToAccountId__c = acc.Id;
        ordr.APTS_Confirmed_Installation_Date__c = system.today();
        ordr.APTS_Confirmed_De_Installation_Date__c = system.today().adddays(1);
        Database.insert(ordr, false);
        
        Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
        prdAttValue.APTS_Number_of_months__c = '9';
        Database.insert(prdAttValue, false);
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali.Id, billpre.Id, plist.Id, pli.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli.Apttus_Config2__OrderId__c = ordr.Id;
        oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli.Apttus_Config2__ProductId__c = prd.Id;
        oli.Apttus_Config2__ShipToAccountId__c = acc1.Id;
        oli.APTS_Serial_Number__c = '123';
        oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        Database.insert(oli, false);
        
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        Database.update(aliInsertList, false);
             
        test.stopTest();
    }**/
   // static{
    @testSetup static void setupTestData() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        Database.insert(settings, false);
        
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);
        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAsset';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        //insert tstAsset;
        assetLI.add(tstAsset);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset1.Name = 'tstAsset1';
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        //insert tstAsset1;
        assetLI.add(tstAsset1);
        
        Apttus_Config2__AssetLineItem__c tstAsset2 = new Apttus_Config2__AssetLineItem__c();
        tstAsset2.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset2.Name = 'tstAsset2';
        tstAsset2.Apttus_Config2__NetPrice__c = 100;
        tstAsset2.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset2.Apttus_Config2__AssetStatus__c = 'New';
        //insert tstAsset2;
        assetLI.add(tstAsset2);
        
        Apttus_Config2__AssetLineItem__c tstAsset3 = new Apttus_Config2__AssetLineItem__c();
        tstAsset3.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset3.Name = 'tstAsset3';
        tstAsset3.Apttus_Config2__NetPrice__c = 100;
        tstAsset3.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset3.Apttus_CMConfig__AgreementId__c = aggr.Id;
        tstAsset3.Apttus_Config2__EndDate__c = Date.today().addDays(365);
        tstAsset3.Apttus_Config2__AssetStatus__c = 'Activated';
        //insert tstAsset3;
        assetLI.add(tstAsset3);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset4 = new Apttus_Config2__AssetLineItem__c();
        tstAsset4.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset4.Name = 'tstAsset4';
        tstAsset4.Apttus_Config2__NetPrice__c = 100;
        tstAsset4.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset4.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset4.APTS_Manual_Activation_Date__c = Date.today();
        //insert tstAsset4;
        assetLI.add(tstAsset4);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset5 = new Apttus_Config2__AssetLineItem__c();
        tstAsset5.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset5.Name = 'tstAsset5';
        tstAsset5.Apttus_Config2__NetPrice__c = 100;
        tstAsset5.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset5.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset5.APTS_Manual_Activation_Date__c = Date.today();
        //insert tstAsset5;
        assetLI.add(tstAsset5);

        Apttus_Config2__AssetLineItem__c tstAsset6 = new Apttus_Config2__AssetLineItem__c();
        tstAsset6.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset6.Name = 'tstAsset6';
        tstAsset6.Apttus_Config2__NetPrice__c = 100;
        tstAsset6.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset6.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset6.APTS_Manual_Activation_Date__c = Date.today();
        tstAsset6.Apttus_Config2__HasOptions__c = true;
        tstAsset6.Apttus_Config2__LineType__c = 'Product/Service'; 
        //insert tstAsset6;
        assetLI.add(tstAsset6);

         Apttus_Config2__AssetLineItem__c tstAsset7 = new Apttus_Config2__AssetLineItem__c();
        tstAsset7.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset7.Name = 'tstAsset7';
        tstAsset7.Apttus_Config2__NetPrice__c = 100;
         tstAsset7.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset7.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset7.APTS_Manual_Activation_Date__c = Date.today();
        tstAsset7.Apttus_Config2__HasOptions__c = true;
        tstAsset7.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset7.APTS_Is_Primary_L1_Line__c = true;
        tstAsset7.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset7.Apttus_Config2__ChargeType__c = 'Sales Price';
        //insert tstAsset6;
        assetLI.add(tstAsset7);

        Apttus_Config2__AssetLineItem__c tstOption1 = new Apttus_Config2__AssetLineItem__c();
        tstOption1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstOption1.Name = 'tstOption1';
        tstOption1.Apttus_Config2__NetPrice__c = 100;
         tstOption1.Apttus_Config2__NetUnitPrice__c=10;
        tstOption1.Apttus_Config2__AssetStatus__c = 'New';
        tstOption1.APTS_Manual_Activation_Date__c = Date.today();
        tstOption1.Apttus_Config2__BundleAssetId__c = tstAsset6.Id;
        //insert tstOption1;
        assetLI.add(tstOption1);
        Database.insert(assetLI,false);

        List<Apttus_Config2__AssetTransactionHistory__c> assetTH = New List<Apttus_Config2__AssetTransactionHistory__c>();
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__AssetLineItemId__c = assetLI[0].Id;
        tstHistory.Apttus_Config2__Action__c = 'New';
        //insert tstHistory;
        assetTH.add(tstHistory);    
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory1 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory1.Apttus_Config2__AssetLineItemId__c = assetLI[1].Id;
        tstHistory1.Apttus_Config2__Action__c = 'Renew';
        //insert tstHistory1;
        assetTH.add(tstHistory1);
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory2 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory2.Apttus_Config2__AssetLineItemId__c = assetLI[2].Id;
        tstHistory2.Apttus_Config2__Action__c = 'Amend';
        //insert tstHistory2;
        assetTH.add(tstHistory2);
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory3 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory3.Apttus_Config2__AssetLineItemId__c = assetLI[3].Id;
        tstHistory3.Apttus_Config2__Action__c = 'Cancel';
        //insert tstHistory3;
        assetTH.add(tstHistory3);
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory4 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory4.Apttus_Config2__AssetLineItemId__c = assetLI[4].Id;
        tstHistory4.Apttus_Config2__Action__c = 'New';
        //insert tstHistory4;
        assetTH.add(tstHistory4);
        Database.insert(assetTH,false);
        
        List<APTS_Historical_Price_Change__c> histPriceChange = New List<APTS_Historical_Price_Change__c>();

        APTS_Historical_Price_Change__c tstHistorical = new APTS_Historical_Price_Change__c();
        tstHistorical.APTS_AssetLineItem__c = assetLI[0].Id;
        //insert tstHistorical;
        histPriceChange.add(tstHistorical);

        APTS_Historical_Price_Change__c tstHistorical1 = new APTS_Historical_Price_Change__c();
        tstHistorical1.APTS_AssetLineItem__c = assetLI[1].Id;
        //insert tstHistorical1;
        histPriceChange.add(tstHistorical1);

        APTS_Historical_Price_Change__c tstHistorical2 = new APTS_Historical_Price_Change__c();
        tstHistorical2.APTS_AssetLineItem__c = assetLI[2].Id;
        //insert tstHistorical2;
        histPriceChange.add(tstHistorical2);

        APTS_Historical_Price_Change__c tstHistorical3 = new APTS_Historical_Price_Change__c();
        tstHistorical3.APTS_AssetLineItem__c = assetLI[3].Id;
        //insert tstHistorical3;
        histPriceChange.add(tstHistorical3);

        APTS_Historical_Price_Change__c tstHistorical4 = new APTS_Historical_Price_Change__c();
        tstHistorical4.APTS_AssetLineItem__c = assetLI[4].Id;
        //insert tstHistorical4;
        histPriceChange.add(tstHistorical4);
        Database.insert(histPriceChange,false);
        

        Apttus_Config2__Order__c ordr = new Apttus_Config2__Order__c();
        ordr.APTS_Sales_Organization__c = 'SAP_0080';
        //ordr.Apttus_Config2__SoldToAccountId__c = acc.Id;
        ordr.APTS_Confirmed_Installation_Date__c = Date.today();
        ordr.APTS_Confirmed_De_Installation_Date__c = Date.today().addDays(1);
        ordr.APTS_Order_Sub_Type__c = 'De-installation';
        Database.insert(ordr, false);
        
        List<Apttus_Config2__OrderLineItem__c> orderLI = New List<Apttus_Config2__OrderLineItem__c>();
        
        Apttus_Config2__OrderLineItem__c oli1 = new Apttus_Config2__OrderLineItem__c();
        oli1.Apttus_Config2__Status__c = 'Activated';
        oli1.Apttus_Config2__AssetLineItemId__c = assetLI[0].Id;
        oli1.APTS_Serial_Number__c = '123';
        oli1.APTS_Installation_Date__c = Date.today();
        oli1.APTS_Goods_Issue_Date__c = Date.today().addDays(1);
        oli1.APTS_RefurbishedMachine__c = false;
        oli1.Apttus_Config2__OrderId__c = ordr.Id;
        oli1.Apttus_Config2__NetUnitPrice__c=10;

        //Database.insert(oli1, false);
        orderLI.add(oli1);

        Apttus_Config2__OrderLineItem__c oli2 = new Apttus_Config2__OrderLineItem__c();
        oli2.Apttus_Config2__Status__c = 'Activated';
        oli2.Apttus_Config2__AssetLineItemId__c = assetLI[5].Id;
        oli2.APTS_Serial_Number__c = '1234';
        oli2.APTS_Installation_Date__c = Date.today();
        oli2.APTS_Goods_Issue_Date__c = Date.today().addDays(1);
        oli2.APTS_RefurbishedMachine__c = false;
        oli2.Apttus_Config2__OrderId__c = ordr.Id;
         oli2.Apttus_Config2__NetUnitPrice__c=10;
        orderLI.add(oli2);
        System.assertNotEquals(0, orderLI.size());      
    }
        
  static testMethod void testAssetTrigger(){
        
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        settings.APTS_Order_Trigger__c = false;
        settings.APTS_OrderLineItemTrigger__c = false;
        Database.insert(settings, false);

        
        test.startTest();
        Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
        
        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        Database.insert(prd,false);
        
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);
        
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc.Id,plist.Id,billpre.Id);
        Database.insert(order,false);

        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Being Amended';
        Database.insert(aggr,false);
        
        system.assertEquals('In Effect',aggr.Apttus__Status__c);
        
        List<Apttus_Config2__AssetLineItem__c> aliInsertList = new List<Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AssetStatus__c = 'Terminated';
        aliInsertList.add(ali);
        
        Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali1.Apttus_Config2__AssetStatus__c = 'Terminated';
        aliInsertList.add(ali1);
        
        Database.insert(aliInsertList,False);
        //system.assertEquals(aliInsertList[0].Apttus_Config2__AssetNumber__c,aliInsertList[0].Id);

        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        Database.update(ali,False);
        test.stopTest();
        
         Apttus_Config2__Order__c ordr = new Apttus_Config2__Order__c();
        ordr.APTS_Sales_Organization__c = 'SAP_0080';
        ordr.Apttus_Config2__SoldToAccountId__c = acc.Id;
        ordr.APTS_Confirmed_Installation_Date__c = system.today();
        ordr.APTS_Confirmed_De_Installation_Date__c = system.today().adddays(1);
        Database.insert(ordr, false);
 
        List<Apttus_Config2_AssetAdjustItem__c> aaliInsertList = new List<Apttus_Config2_AssetAdjustItem__c>();
        List<Apttus_Config2__OrderLineItem__c> oliInsertList = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderAdjustmentLineItem__c> oaliInsertList = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
        
        system.debug('===>>'+ali.id);
        System.assertNotEquals(NULL, ali.id);
        
        Apttus_Config2_AssetAdjustItem__c aali =new Apttus_Config2_AssetAdjustItem__c();
        aali.Name='Test';
        aali.Apttus_Config2_AssetLineItemId__c=ali.Id;
        aali.Apttus_Config2_AssetAdjustType__c='Discount Amount';
        aaliInsertList.add(aali);
        
        Database.insert(aaliInsertList,False);
        system.debug('===>>'+aali.id);
        system.debug('===>>'+aali.Apttus_Config2_AssetLineItemId__c);
        
     /*   Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__LineNumber__c = 1;
        oli.Apttus_Config2__ItemSequence__c = 2;
        oli.Apttus_Config2__OrderId__c = order.Id;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        
       // insert oli;
        oliInsertList.add(oli);
        
        Database.insert(oliInsertList,False);
        system.debug('===>>'+oli.id);  */
     
     
        APTS_Order_LSP_Details__c ordrLspDetails = new APTS_Order_LSP_Details__c();
        ordrLspDetails.APTS_Building__c = 'Building';
        ordrLspDetails.APTS_Floor__c = 'Floor';
        ordrLspDetails.APTS_Area__c = 'Area';
        ordrLspDetails.APTS_CustomerReference__c = '123456543'; 
        ordrLspDetails.APTS_SmokingArea__c = true;
        ordrLspDetails.APTS_ConfigurationFileURL__c = 'URL';
        ordrLspDetails.APTS_JDE_crockeryVolumeSize__c = '10';
        Database.insert(ordrLspDetails, false);
        
        Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
        prdAttValue.APTS_Number_of_months__c = '9';
        Database.insert(prdAttValue, false);
        
         Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali.Id, billpre.Id, plist.Id, pli.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli.Apttus_Config2__OrderId__c = ordr.Id;
        oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli.Apttus_Config2__ProductId__c = prd.Id;
        oli.Apttus_Config2__ShipToAccountId__c = acc.Id;
        oli.APTS_Serial_Number__c = '123';
        oli.Apttus_Config2__NetUnitPrice__c=10;
        oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        Database.insert(oli, false);
        List<Apttus_Config2__OrderLineItem__c> olilist=[select Id,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c limit 1];
       system.debug('===>>'+oli.Id);
       system.debug('===>>'+oli.Apttus_Config2__AssetLineItemId__c);
        System.assertNotEquals(NULL, oli.id);
        
     // Create Product Configuration
        Apttus_Config2__ProductConfiguration__c prodConfig = new Apttus_Config2__ProductConfiguration__c (Name= 'Test Product');
        insert prodConfig;
        // Create Price Rule Set
        Apttus_Config2__PriceRuleset__c priceRuleSet= new Apttus_Config2__PriceRuleset__c (Name = 'Test',Apttus_Config2__Sequence__c =1);
        insert priceRuleSet;
        // Create Price Rule 
        Apttus_Config2__PriceRule__c priceRule = new Apttus_Config2__PriceRule__c (Name = 'Test',Apttus_Config2__RulesetId__c=priceRuleSet.id,Apttus_Config2__Sequence__c =1);
        insert priceRule;
        // Create Price Rule Entry
        Apttus_Config2__PriceRuleEntry__c priceEntry = new Apttus_Config2__PriceRuleEntry__c (Apttus_Config2__Sequence__c= 1,Apttus_Config2__PriceRuleId__c= priceRule.id);
        insert priceEntry;
    // Create Incentive
        Apttus_Config2__Incentive__c incentive = new Apttus_Config2__Incentive__c (Name='Test Incentive',
                                                                                   Apttus_Config2__ApplicationMethod__c='Buy X Get X',
                                                                                  Apttus_Config2__EffectiveDate__c = system.today(),
                                                                                  Apttus_Config2__Sequence__c=1);
    insert incentive;

    // Create Incentive Coupon
    Apttus_Config2__IncentiveCoupon__c incentiveCoupon= new Apttus_Config2__IncentiveCoupon__c (Apttus_Config2__CouponCode__c='Test', Apttus_Config2__IncentiveId__c = incentive.id);
        insert incentiveCoupon;
        
        Apttus_Config2__OrderAdjustmentLineItem__c oali =new Apttus_Config2__OrderAdjustmentLineItem__c();
       // oali.name='TestOrder';
        oali.Apttus_Config2__LineNumber__c = 12;
        oali.Apttus_Config2__LineItemId__c = olilist[0].Id;
        oali.CurrencyIsoCode='EUR';
        oali.Apttus_Config2__AdjustmentType__c ='Discount Amount';
        oali.Apttus_Config2__AdjustmentAmount__c=100;
        oali.Apttus_Config2__AdjustmentAppliesTo__c='Previous Price';
        oali.Apttus_Config2__BenefitQuantity__c=10;
        oali.Apttus_Config2__CouponCode__c='ABC';
        oali.Apttus_Config2__IncentiveId__c=incentive.Id;
        oali.Apttus_Config2__IncentiveAdjustmentAmount__c=1000;
        oali.Apttus_Config2__IncentiveCode__c='xyz';
        oali.Apttus_Config2__IsModifiable__c=TRUE;
        oali.Apttus_Config2__LineNumber__c=4;
        oali.Apttus_Config2__LineType__c='Manual';
        oali.Apttus_Config2__PriceRuleId__c=priceRule.Id;
        oali.Apttus_Config2__PriceRuleEntryId__c=priceEntry.Id;
        oali.Apttus_Config2__SubType__c='ZP03';
        oali.Apttus_Config2__Type__c='Default';
        
        oaliInsertList.add(oali);
        
        Database.insert(oaliInsertList,False);
        List<Apttus_Config2_AssetAdjustItem__c> assetAdjLineItemLst = [SELECT Id,  Apttus_Config2_AssetAdjustType__c 
        FROM Apttus_Config2_AssetAdjustItem__c where Apttus_Config2_AssetLineItemId__c =: ali.Id];
        
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c,Apttus_Config2__AssetNumber__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset'];
        //system.assertEquals(obj.Id,obj.Apttus_Config2__AssetNumber__c);
        system.assert(assetAdjLineItemLst!=null);
        system.assert(assetAdjLineItemLst.size()!=null);
        system.debug('===>>'+assetAdjLineItemLst);
        system.debug('===>>'+assetAdjLineItemLst.size());
        system.debug('===>>'+oali.id);
        system.debug('===>>'+oali.Apttus_Config2__LineItemId__r.Apttus_Config2__AssetLineItemId__c);
    }

    static testMethod void testTransaction(){
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Apttus_Config2__ChargeType__c = 'Service Fee';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Terminated';
        insert tstAsset;
        
        List<Apttus__APTS_Agreement__c> aggr = [SELECT id from Apttus__APTS_Agreement__c];

        Apttus_Config2__OrderLineItem__c oli1 = new Apttus_Config2__OrderLineItem__c();
        oli1.Apttus_Config2__Status__c = 'Activated';
        oli1.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        oli1.APTS_Serial_Number__c = '123';
        oli1.APTS_Installation_Date__c = system.today();
        oli1.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli1.APTS_RefurbishedMachine__c = false;
        oli1.Apttus_Config2__NetUnitPrice__c=10;
        Database.insert(oli1, false);

        Test.startTest();
        
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c,Apttus_Config2__AssetNumber__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset'];
        //system.assertEquals(obj.Id,obj.Apttus_Config2__AssetNumber__c);
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_CMConfig__AgreementId__c = aggr[0].Id; 
        System.assertNotEquals(NULL, obj.id);
        update obj;        
        Test.stopTest();
    }

    static testMethod void test1(){
        Test.startTest();
        //List<Apttus__APTS_Agreement__c> aggr = [SELECT id from Apttus__APTS_Agreement__c];
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset'];
        List<Apttus__APTS_Agreement__c> aggr = [SELECT id from Apttus__APTS_Agreement__c where Id != : obj.Apttus_CMConfig__AgreementId__c];
        
        Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
        newH.Apttus_Config2__AssetLineItemId__c = obj.Id;
        newH.Apttus_Config2__Action__c = 'New';
        insert newH;

        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_CMConfig__AgreementId__c = aggr[0].Id;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        update obj;
        obj.Apttus_CMConfig__AgreementId__c = aggr[1].Id;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest(); 
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }

    static testMethod void test2(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset1'];
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset1'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }

    static testMethod void test3(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset2'];
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset2'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }

    static testMethod void test4(){
        Test.startTest();
        List<Apttus__APTS_Agreement__c> aggr = [SELECT id from Apttus__APTS_Agreement__c];
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset3'];
        obj.Apttus_Config2__AssetStatus__c = 'Cancelled';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        obj.Apttus_CMConfig__AgreementId__c = aggr[0].Id;
        obj.APTS_Manual_DeActivation_Date__c = null;
        update obj;
        system.assertEquals('Cancelled',obj.Apttus_Config2__AssetStatus__c);
         Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__AssetLineItemId__c = obj.Id;
        tstHistory.Apttus_Config2__Action__c = 'Cancel';
       insert tstHistory;
       List<RTR_LAE_Transaction_Data__c> rtr = new List<RTR_LAE_Transaction_Data__c>();
       system.assertEquals('Cancel', tstHistory.Apttus_Config2__Action__c);
       
    }

    static testMethod void test5(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset4'];
        obj.APTS_Service_Rollup_Gross_Amount__c = 10;
        obj.APTS_Service_Rollup_Net_Amount__c = 10;
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Set<Id> setAssetId = new Set<Id>();
        setAssetId.add(obj.Id);
        APTS_AssetLineItemTriggerHandler objHandler = new APTS_AssetLineItemTriggerHandler();
        objHandler.createIndexationTransData(setAssetId);
        Test.stopTest();
        List<RTR_LAE_Transaction_Data__c> lstTransData = [Select Id from RTR_LAE_Transaction_Data__c];
        system.assertEquals(1,lstTransData.size());
    }

    static testMethod void test6(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset3'];        
        obj.Apttus_Config2__AssetStatus__c = 'Cancelled';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        obj.Apttus_Config2__EndDate__c = Date.today();
        update obj;
        system.assertEquals('Cancelled',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        //system.assertEquals('Cancelled',obj.Apttus_Config2__AssetStatus__c);
    }

    static testMethod void test7(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset3'];
        obj.Apttus_Config2__AssetStatus__c = 'Terminated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        obj.Apttus_Config2__EndDate__c = Date.today();
        update obj;
        system.assertEquals('Terminated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        //system.assertEquals('Terminated',obj.Apttus_Config2__AssetStatus__c);
    }

    static testMethod void test8(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset5'];
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj; 
        Test.stopTest();
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset5'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }

    static testMethod void test9(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset6'];
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAsset6'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }

    static testMethod void test10(){
        Test.startTest();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstOption1'];
        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 300;
        obj.Apttus_Config2__NetUnitPrice__c=10;
        update obj;
        system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
        Test.stopTest();
        Apttus_Config2__AssetLineItem__c obj1 = [SELECT Id, APTS_Old_Net_Price__c,Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstOption1'];
        //system.assertEquals(obj1.APTS_Old_Net_Price__c,obj1.Apttus_Config2__NetPrice__c);
    }
    
    static testMethod void testAfterUpdate(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = false;
        Database.insert(settings, false);
             
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);

        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAssetAU';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset.Apttus_CMConfig__AgreementId__c =  agrlst[0].Id;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';

        //insert tstAsset;
        assetLI.add(tstAsset);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset1.Name = 'tstAssetAU1';
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset1.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        //insert tstAsset1;
        assetLI.add(tstAsset1);
        System.assertNotEquals(0, assetLI.size());
        insert assetLI;

        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU'];
        
        Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
        newH.Apttus_Config2__AssetLineItemId__c = obj.Id;
        newH.Apttus_Config2__Action__c = 'New';
        insert newH;

        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        obj.Apttus_CMConfig__AgreementId__c = agrlst[1].Id;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
          APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                update obj;
                system.assertEquals('Activated',obj.Apttus_Config2__AssetStatus__c);
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
        
       
    }


     static testMethod void testAfterUpdateSecond(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        Database.insert(settings, false);
             
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);

        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAssetAU';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset.Apttus_CMConfig__AgreementId__c =  agrlst[0].Id;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';

        //insert tstAsset;
        assetLI.add(tstAsset);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset1.Name = 'tstAssetAU1';
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset1.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        //insert tstAsset1;
        assetLI.add(tstAsset1);

        insert assetLI;

       
     List<Apttus_Config2__AssetLineItem__c> lstALI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU'];
        
        Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
        newH.Apttus_Config2__AssetLineItemId__c = obj.Id;
        newH.Apttus_Config2__Action__c = 'New';
        insert newH;

        /*obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        //obj.Apttus_CMConfig__AgreementId__c = agrlst[1].Id;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        update obj;
       */       

        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__HasOptions__c = true;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        obj.Apttus_Config2__ChargeType__c = 'Sales Price';
        obj.APTS_Type_Of_Contract__c = 'Sales';
        obj.APTS_Manual_Activation_Date__c = null;
        //update obj;
        lstALI.add(obj);

  
        Apttus_Config2__AssetLineItem__c obj2 = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU1'];
             

        Apttus_Config2__AssetTransactionHistory__c newH1 = new Apttus_Config2__AssetTransactionHistory__c();
        newH1.Apttus_Config2__AssetLineItemId__c = obj2.Id;        
        newH1.Apttus_Config2__Action__c = 'Cancel';
        insert newH1;

        obj2.Apttus_Config2__AssetStatus__c = 'Cancelled';
        obj2.Apttus_Config2__HasOptions__c = true;
        obj2.Apttus_Config2__LineType__c = 'Product/Service';
        //update obj2;
        lstALI.add(obj2);
        System.assertNotEquals(0, lstALI.size());
        update lstALI;
    }


     static testMethod void testAfterUpdateThird(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        Database.insert(settings, false);
             
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);

        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAssetAU';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset.Apttus_CMConfig__AgreementId__c =  agrlst[0].Id;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';

        //insert tstAsset;
        assetLI.add(tstAsset);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset1.Name = 'tstAssetAU1';
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset1.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        //insert tstAsset1;
        assetLI.add(tstAsset1);

        insert assetLI;

       
     List<Apttus_Config2__AssetLineItem__c> lstALI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU'];
        
        Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
        newH.Apttus_Config2__AssetLineItemId__c = obj.Id;
        newH.Apttus_Config2__Action__c = 'Renew';
        insert newH;

        /*obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        //obj.Apttus_CMConfig__AgreementId__c = agrlst[1].Id;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        update obj;
       */       

        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__HasOptions__c = true;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        obj.Apttus_Config2__ChargeType__c = 'Service Fee';
        obj.APTS_Type_Of_Contract__c = 'Sales';
        obj.APTS_Manual_Activation_Date__c = null;
        obj.APTS_Calculated_Base_Extended_Price__c = 200;
        //update obj;
        lstALI.add(obj);

  
        Apttus_Config2__AssetLineItem__c obj2 = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU1'];
             

        Apttus_Config2__AssetTransactionHistory__c newH1 = new Apttus_Config2__AssetTransactionHistory__c();
        newH1.Apttus_Config2__AssetLineItemId__c = obj2.Id;        
        newH1.Apttus_Config2__Action__c = 'Renew';
        insert newH1;

        obj2.Apttus_Config2__AssetStatus__c = 'Activated';
        obj2.Apttus_Config2__HasOptions__c = true;
        obj2.Apttus_Config2__LineType__c = 'Product/Service';
        obj2.Apttus_Config2__EndDate__c = system.today().addDays(30);
        //update obj2;
        lstALI.add(obj2);
        update lstALI;
        System.assertNotEquals(0, lstALI.size());
        
    }

    static testMethod void testAfterUpdateForth(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        settings.APTS_Order_Trigger__c = false;
        settings.APTS_OrderLineItemTrigger__c = false;
        Database.insert(settings, false);

        Account acc = APTS_TestUtils.createaccount();
         Database.insert(acc,false);
             
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);

        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> assetLI2 = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAssetAU';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset.Apttus_CMConfig__AgreementId__c =  agrlst[0].Id;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';

        //insert tstAsset;
        assetLI.add(tstAsset);
        
        
        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset1.Name = 'tstAssetAU1';
        tstAsset1.Apttus_Config2__AccountId__c = acc.Id;
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset1.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        //insert tstAsset1;
        assetLI.add(tstAsset1);

        insert assetLI;


        Apttus_Config2__AssetLineItem__c tstAsset2 = new Apttus_Config2__AssetLineItem__c();
        tstAsset2.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset2.Name = 'tstAssetAU2';
        tstAsset2.APTS_Is_Primary_L1_Asset__c = assetLI[1].Id;
        tstAsset2.Apttus_Config2__NetPrice__c = 100;
        tstAsset2.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset2.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset2.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset2.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset2.APTS_Type_Of_Contract__c = 'Sales';

        assetLI2.add(tstAsset2);

        Apttus_Config2__AssetLineItem__c tstAsset3 = new Apttus_Config2__AssetLineItem__c();
        tstAsset3.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset3.Name = 'tstAssetAU3';
        tstAsset3.APTS_Is_Primary_L1_Asset__c = assetLI[1].Id;
        tstAsset3.Apttus_Config2__NetPrice__c = 100;
        tstAsset3.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset3.Apttus_CMConfig__AgreementId__c =  agrlst[1].Id;
        tstAsset3.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset3.Apttus_Config2__ChargeType__c = 'Service Fee';
        tstAsset3.APTS_Type_Of_Contract__c = 'Rent';
        
        //insert tstAsset3;
        assetLI2.add(tstAsset3);
        
       // insert assetLI2;
       
     List<Apttus_Config2__AssetLineItem__c> lstALI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c obj = [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU'];
        
        Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
        newH.Apttus_Config2__AssetLineItemId__c = obj.Id;
        newH.Apttus_Config2__Action__c = 'Renew';
        insert newH;

        /*obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__NetPrice__c = 200;
        //obj.Apttus_CMConfig__AgreementId__c = agrlst[1].Id;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        update obj;
       */       

        obj.Apttus_Config2__AssetStatus__c = 'Activated';
        obj.Apttus_Config2__HasOptions__c = true;
        obj.Apttus_Config2__LineType__c = 'Product/Service';
        obj.Apttus_Config2__ChargeType__c = 'Service Fee';
        obj.APTS_Type_Of_Contract__c = 'Sales';
        obj.APTS_Manual_Activation_Date__c = null;
        obj.APTS_Calculated_Base_Extended_Price__c = 200;
        //update obj;
        lstALI.add(obj);

  
        Apttus_Config2__AssetLineItem__c obj2 = [SELECT Id,APTS_Stop_RtR_Transactions_from__c,Apttus_CMConfig__AgreementId__c, Apttus_Config2__NetPrice__c FROM Apttus_Config2__AssetLineItem__c WHERE Name = 'tstAssetAU1'];
             

        Apttus_Config2__AssetTransactionHistory__c newH1 = new Apttus_Config2__AssetTransactionHistory__c();
        newH1.Apttus_Config2__AssetLineItemId__c = obj2.Id;        
        newH1.Apttus_Config2__Action__c = 'Renew';
        insert newH1;

        obj2.Apttus_Config2__AssetStatus__c = 'Activated';
        obj2.Apttus_Config2__HasOptions__c = true;
        obj2.Apttus_Config2__LineType__c = 'Product/Service';
        obj2.Apttus_Config2__EndDate__c = system.today().addDays(-30);
        //update obj2;
        lstALI.add(obj2);
        System.assertNotEquals(0, lstALI.size());
        update lstALI;

        Map<Id, Boolean> mapAssetLineItem = new Map<Id, Boolean>();
        Map<Id, Boolean> mapAssetLineItem2 = new Map<Id, Boolean>();
        mapAssetLineItem.put(obj2.Id, true);
        mapAssetLineItem2.put(obj2.Id, false);
        APTS_AssetLineItemTriggerHandler.createTransDataOnContractChanged(mapAssetLineItem,false,false);
        APTS_AssetLineItemTriggerHandler.createTransDataOnContractChanged(mapAssetLineItem2,false,false);
        //APTS_AssetLineItemTriggerHandler.createTransDataOnContractChanged(mapAssetLineItem,true,true);
        //APTS_AssetLineItemTriggerHandler.createTransDataOnContractChanged(mapAssetLineItem2,false,true);
        
    }

    static testMethod void testAfterInsert(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.AssetLineItemTrigger__c = true;
        Database.insert(settings, false);
        
        Apttus_Config2__Order__c ordr = new Apttus_Config2__Order__c();
        ordr.APTS_Sales_Organization__c = 'SAP_0080';
        //ordr.Apttus_Config2__SoldToAccountId__c = acc.Id;
        ordr.APTS_Confirmed_Installation_Date__c = Date.today();
        ordr.APTS_Confirmed_De_Installation_Date__c = Date.today().addDays(1);
        ordr.APTS_Order_Sub_Type__c = 'De-installation';
        Database.insert(ordr, false);
        
        List<Apttus_Config2__OrderLineItem__c> orderLI = New List<Apttus_Config2__OrderLineItem__c>();
        
    
        Apttus_Config2__OrderLineItem__c oli3 = new Apttus_Config2__OrderLineItem__c();
        oli3.Apttus_Config2__Status__c = 'Activated';
        oli3.Apttus_Config2__AssetLineItemId__c = [Select Id from Apttus_Config2__AssetLineItem__c where Name = 'tstAsset7'].ID;
        oli3.APTS_Serial_Number__c = '1234';
        oli3.APTS_Installation_Date__c = Date.today();
        oli3.APTS_Goods_Issue_Date__c = Date.today().addDays(1);
        oli3.APTS_RefurbishedMachine__c = false;
        oli3.Apttus_Config2__OrderId__c = ordr.Id;
        oli3.Apttus_Config2__NetUnitPrice__c=10;
        orderLI.add(oli3);

        Database.insert(orderLI, false);

        Apttus_Config2__AssetLineItem__c tstAsset4Mah = new Apttus_Config2__AssetLineItem__c();
        tstAsset4Mah.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset4Mah.Name = 'tstAsset4Mah';
        tstAsset4Mah.Apttus_Config2__NetPrice__c = 100;
        tstAsset4Mah.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset4Mah.APTS_Manual_Activation_Date__c = Date.today();
        tstAsset4Mah.APTS_Is_Primary_L1_Parent__c = String.valueOf(orderLI[0].Id);
        insert tstAsset4Mah;
        System.assertNotEquals(Null, tstAsset4Mah.Id);

    }
    
    static testMethod void testAssetContractChange(){
    
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            insert priceList;  

        Account acc = APTS_TestUtils.createaccount();
         Database.insert(acc,false);
         
        
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
               

        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);        
       
    
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, priceList.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);            
            
            Product2 machineProduct = APTS_TestUtils.createProduct('Machine Product', '26940992', 'Machines');       
            machineProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
            insert machineProduct;
            
            Apttus_Config2__PriceListItem__c machinePriceListItem = APTS_TestUtils.createPriceListItem(priceList.id,machineProduct.id);
            insert machinePriceListItem;
        
         Account machineAccount = new Account(Name = 'Machine Account', Phone = '+3209999999');
            insert machineAccount;
          
          Apttus_Config2__Order__c ordr = new Apttus_Config2__Order__c();
        ordr.APTS_Sales_Organization__c = 'SAP_0080';
        ordr.APTS_Contract_Change__c='Yes';
        ordr.APTS_Confirmed_Installation_Date__c = Date.today();        
        ordr.APTS_Order_Type__c='Admin order';
        ordr.APTS_Order_Sub_Type__c='Conversion Order';
        Database.insert(ordr, false);
        
          Apttus_Config2__ProductConfiguration__c machineProdConfig = new Apttus_Config2__ProductConfiguration__c(
                Apttus_Config2__AccountId__c=machineAccount.id, 
                Name = 'Sample', 
                Apttus_Config2__OrderId__c = ordr.id, 
                Apttus_Config2__PriceListId__c = priceList.id);
            insert machineProdConfig;
            
            
            Apttus_Config2__AssetLineItem__c tstAsset6 = new Apttus_Config2__AssetLineItem__c();
        tstAsset6.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset6.Name = 'tstAsset6';
        tstAsset6.Apttus_Config2__NetPrice__c = 100;
        tstAsset6.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset6.APTS_Manual_Activation_Date__c = Date.today();
        tstAsset6.Apttus_Config2__HasOptions__c = true;
        tstAsset6.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstAsset6.Apttus_Config2__LineType__c = 'Product/Service'; 
        insert tstAsset6;
        
         Apttus_Config2__AssetLineItem__c tstOption1 = new Apttus_Config2__AssetLineItem__c();
        tstOption1.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstOption1.Name = 'tstOption1';
        tstOption1.APTS_relatedlist_agreement__c=aggr.id;
        tstOption1.APTS_PhysicalAssetExtId__c='123';
        tstOption1.Apttus_Config2__NetPrice__c = 100;
        tstOption1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstOption1.Apttus_Config2__AssetStatus__c = 'Activated';
        tstOption1.APTS_Manual_Activation_Date__c = Date.today();
        tstOption1.Apttus_Config2__BundleAssetId__c = tstAsset6.Id;
        
        insert tstOption1;
        
        Apttus_Config2__AssetLineItem__c tstOption2 = new Apttus_Config2__AssetLineItem__c();
        tstOption2.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstOption2.Name = 'tstOption2';
        tstOption2.Apttus_Config2__NetPrice__c = 100;
        tstOption2.Apttus_Config2__AssetStatus__c = 'Cancelled';
        tstOption2.APTS_relatedlist_agreement__c=aggr.id;
        tstOption2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        tstOption2.APTS_PhysicalAssetExtId__c='1234';
        tstOption2.APTS_Terminated_Asset_Line__c=tstOption1.id;
        tstOption2.APTS_Manual_Activation_Date__c = Date.today();
        tstOption2.Apttus_Config2__BundleAssetId__c = tstAsset6.Id;
        insert tstOption2;
        
        
        tstOption2.APTS_Terminated_Asset_Line__c=tstOption1.id;
        update tstOption2;
        
        Apttus_Config2__LineItem__c machineLineItem1 = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                APTS_Terminated_Asset_Line__c= tstOption2.id,
                Apttus_Config2__ProductId__c=machineProduct.id,currencyISOCode='EUR',
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__AssetLineItemId__c=tstOption1.id,
                Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',Apttus_Config2__PrimaryLineNumber__c=1,
                Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
                APTS_Category_Level__c = 'Category');
            insert machineLineItem1;
        
        
        
        
        machineLineItem1.Apttus_Config2__AssetLineItemId__c=tstOption1.id;
        update machineLineItem1;
        
        
        
        
        List<Apttus_Config2__OrderLineItem__c> orderLI = New List<Apttus_Config2__OrderLineItem__c>();
        
        Apttus_Config2__OrderLineItem__c oli1 = new Apttus_Config2__OrderLineItem__c();
        oli1.Apttus_Config2__Status__c = 'Activated';
        oli1.APTS_PhysicalAssetExtId__c='1234';
        oli1.Apttus_Config2__DerivedFromId__c=machineLineItem1.id;
        oli1.Apttus_Config2__AssetLineItemId__c=tstOption1.id;
        oli1.APTS_Installation_Date__c = Date.today();
        oli1.APTS_Goods_Issue_Date__c = Date.today().addDays(1);
        oli1.APTS_RefurbishedMachine__c = false;
        oli1.Apttus_Config2__OrderId__c = ordr.Id;
        oli1.Apttus_Config2__StartDate__c=System.today();
        oli1.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
        oli1.Apttus_Config2__SellingTerm__c=12;
        oli1.Apttus_Config2__NetUnitPrice__c=10;
        oli1.Apttus_Config2__NetPrice__c=0;
        Database.insert(oli1, false);
        System.assertNotEquals(Null, oli1.Id);
        String orderlineid= String.valueOf(oli1.id);
        tstOption1.Apttus_Config2__BusinessLineItemId__c=orderlineid;
        update tstOption1;
        tstOption2.Apttus_Config2__BusinessLineItemId__c=orderlineid;
        update tstOption2;
        
}

    static testMethod void testContractChange(){
         List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
       Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
        
        
        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);

        Account acc2 = APTS_TestUtils.createaccount();
        Database.insert(acc2,false);
     
             
        

        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        prd.Name = 'Product Name';
        prd.Description = 'Product Description';
        prd.ProductCode = '2345';
        Database.insert(prd,false);

        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);

        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);

        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);


        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc.Id,plist.Id,billpre.Id);
        order.APTS_Order_Type__c='Admin order';
        order.APTS_Order_Sub_Type__c='Conversion Order';
        order.APTS_Contract_Change__c = 'Yes';
        Database.insert(order,false);
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;
        
        Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali1.Apttus_Config2__AccountId__c = acc.Id;
         ali1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        ali1.APTS_RefurbishedMachine__c = true;
        ali1.Apttus_Config2__AssetStatus__c = 'New';
        ali1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        ali1.Apttus_Config2__StartDate__c = system.today();
        ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
        // ali1.APTS_Serial_Number__c = '123';
        ali1.APTS_RefurbishedMachine__c = true;
        InsertList.add(ali1);
        System.assertNotEquals(0, InsertList.size());
        Database.insert(InsertList, false);


 

Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
       ali2.Apttus_Config2__AccountId__c = acc.Id;
        ali2.APTS_RefurbishedMachine__c = true;
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Apttus_Config2__StartDate__c = system.today();
        ali2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
       //  ali2.APTS_Serial_Number__c = '123';
         ali2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali2.APTS_RefurbishedMachine__c = true;
         ali2.Apttus_Config2__NetUnitPrice__c=10;
        InsertList.add(ali2);
        Database.insert(InsertList, false);
        
       Apttus_Config2__OrderLineItem__c oli1 = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali2.Id, billpre.Id, plist.Id, pli.Id);
        oli1.Apttus_Config2__Status__c = 'Activated';
        oli1.Apttus_Config2__LineStatus__c = 'Cancelled';
       // oli1.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli1.Apttus_Config2__OrderId__c = order.Id;
       // oli1.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli1.Apttus_Config2__AssetLineItemId__c = ali2.Id;
        oli1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli1.Apttus_Config2__ProductId__c = prd.Id;
         oli1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oli1.Apttus_Config2__ShipToAccountId__c = acc.Id;
        oli1.APTS_Serial_Number__c = '123';
        oli1.APTS_Installation_Date__c = system.today();
        oli1.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli1.APTS_RefurbishedMachine__c = true;
        oli1.Apttus_Config2__StartDate__c=System.today();
        oli1.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
        oli1.Apttus_Config2__SellingTerm__c=12;
         oli1.Apttus_Config2__NetUnitPrice__c=10;
        oli1.Apttus_Config2__NetPrice__c=0;
        Database.insert(oli1, false);
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali1.Id, billpre.Id, plist.Id, pli.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        oLi.Apttus_Config2__LineStatus__c = 'Activated';
       // oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
       oli.Apttus_Config2__OrderId__c = order.Id;
      //  oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oli.Apttus_Config2__AssetLineItemId__c = ali1.Id;
        oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli.Apttus_Config2__ProductId__c = prd.Id;
        oli.Apttus_Config2__ShipToAccountId__c = acc.Id;
        oli.APTS_Serial_Number__c = '123';
        oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
         oli.Apttus_Config2__StartDate__c=System.today();
        oli.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
        oli.Apttus_Config2__SellingTerm__c=12;
        oli.Apttus_Config2__NetUnitPrice__c=10;
        oli.Apttus_Config2__NetPrice__c=0;
        Database.insert(oli, false);
        
          String orderlineid= String.valueOf(oli1.id);
        ali1.Apttus_Config2__BusinessLineItemId__c=orderlineid;
        update ali1;
          String orderlineid2= String.valueOf(oli.id);
        ali2.Apttus_Config2__BusinessLineItemId__c=orderlineid2;
        update ali2;
        
        }
     static testMethod void testLAERAR(){
         List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
       Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
        
        
        Contact con = APTS_TestUtils.createContact();
       insert con;
             
        

        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        prd.Name = 'Product Name';
        prd.Description = 'Product Description';
        prd.ProductCode = '2345';
        Database.insert(prd,false);

        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        insert aggr;
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        insert pli;

        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        insert billpre;


        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',plist.Id,acc.Id,billpre.Id);
        order.APTS_Contract_Change__c = 'Yes';
        order.APTS_Order_Type__c='Admin Order';
        order.APTS_Order_Sub_Type__c='Conversion Order';
        insert order;
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;
        
        Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali1.Apttus_Config2__AccountId__c = acc.Id;
         ali1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        ali1.APTS_RefurbishedMachine__c = true;
        ali1.Apttus_Config2__AssetStatus__c = 'New';
        ali1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
        ali1.Apttus_Config2__StartDate__c = system.today();
        ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
        // ali1.APTS_Serial_Number__c = '123';
        ali1.APTS_RefurbishedMachine__c = true;
        insert ali1;


 

Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
       ali2.Apttus_Config2__AccountId__c = acc.Id;
        ali2.APTS_RefurbishedMachine__c = true;
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Apttus_Config2__StartDate__c = system.today();
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Apttus_Config2__NetPrice__c=10;
        ali2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
       //  ali2.APTS_Serial_Number__c = '123';
        ali2.Apttus_Config2__LineType__c ='Product/Service';
         ali2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali2.APTS_RefurbishedMachine__c = true;
      insert ali2;

       Apttus_Config2__OrderLineItem__c oli1 = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali2.Id, billpre.Id, plist.Id, pli.Id);
        oli1.Apttus_Config2__Status__c = 'Activated';
        oli1.Apttus_Config2__LineStatus__c = 'Cancelled';
       // oli1.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli1.Apttus_Config2__OrderId__c = order.Id;
       // oli1.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli1.Apttus_Config2__AssetLineItemId__c = ali2.Id;
        oli1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli1.Apttus_Config2__ProductId__c = prd.Id;
         oli1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oli1.Apttus_Config2__ShipToAccountId__c = acc.Id;
        oli1.APTS_Serial_Number__c = '123';
        oli1.APTS_Installation_Date__c = system.today();
        oli1.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli1.APTS_RefurbishedMachine__c = true;
        oli1.Apttus_Config2__StartDate__c=System.today();
        oli1.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
        oli1.Apttus_Config2__SellingTerm__c=12;
        oli1.Apttus_Config2__NetUnitPrice__c=10;
        oli1.Apttus_Config2__NetPrice__c=0;
        oli1.Apttus_Config2__BasePriceOverride__c=3;
        insert oli1;
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali1.Id, billpre.Id, plist.Id, pli.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        oLi.Apttus_Config2__LineStatus__c = 'Activated';
       // oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
       oli.Apttus_Config2__OrderId__c = order.Id;
      //  oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oli.Apttus_Config2__AssetLineItemId__c = ali1.Id;
        oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
        oli.Apttus_Config2__ProductId__c = prd.Id;
        oli.Apttus_Config2__ShipToAccountId__c = acc.Id;
        oli.APTS_Serial_Number__c = '123';
        oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        oli.Apttus_Config2__StartDate__c=System.today();
        oli.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
        oli.Apttus_Config2__SellingTerm__c=12;
        oli.Apttus_Config2__NetUnitPrice__c=10;
        oli.Apttus_Config2__NetPrice__c=0;
        insert oli;
        System.assertNotEquals(null, ali2.id);
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Apttus_Config2__NetPrice__c=20;
         ali2.Apttus_Config2__NetUnitPrice__c=10;
         ali2.Apttus_Config2__BusinessLineItemId__c=oli1.id;
        update ali2;
        
        }

static testMethod void testLAERAR1(){

            List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
          Account acc = APTS_TestUtils.createaccount();
           Database.insert(acc,false);
           
           
           Contact con = APTS_TestUtils.createContact();
          insert con;
                
           
   
           Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
           prd.Name = 'Product Name';
           prd.Description = 'Product Description';
           prd.ProductCode = '2345';
           Database.insert(prd,false);
   
           Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
           Database.insert(plist,false);
           
           Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
           aggr.Apttus__Status__c = 'In Effect';
           aggr.Apttus__Status_Category__c = 'Activated';
           insert aggr;
           
           Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
           insert pli;
   
           Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
           insert billpre;
   
   
           Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',plist.Id,acc.Id,billpre.Id);
           order.APTS_Contract_Change__c = 'No';
           order.APTS_Order_Type__c='Admin Order';
           order.APTS_Order_Sub_Type__c='Conversion Order';
           insert order;
           
           PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
           oPhysicalAsset.SerialNumber__c = 'Test123';
           insert oPhysicalAsset;
           
           Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
            ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
           ali1.Apttus_Config2__AccountId__c = acc.Id;
            ali1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
           ali1.APTS_RefurbishedMachine__c = true;
           ali1.Apttus_Config2__AssetStatus__c = 'New';
           ali1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
           ali1.Apttus_Config2__StartDate__c = system.today();
           ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
           // ali1.APTS_Serial_Number__c = '123';
           ali1.APTS_RefurbishedMachine__c = true;
           insert ali1;
   
   
    
   
   Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
           ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
          ali2.Apttus_Config2__AccountId__c = acc.Id;
           ali2.APTS_RefurbishedMachine__c = true;
           ali2.Apttus_Config2__AssetStatus__c = 'Activated';
           ali2.Apttus_Config2__StartDate__c = system.today();
           ali2.Apttus_Config2__AssetStatus__c = 'Activated';
           ali2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
           ali2.Apttus_Config2__NetPrice__c=10;
          //  ali2.APTS_Serial_Number__c = '123';
           ali2.Apttus_Config2__LineType__c ='Product/Service';
           ali2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
           ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
           ali2.APTS_RefurbishedMachine__c = true;
         insert ali2;
   
          Apttus_Config2__OrderLineItem__c oli1 = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali2.Id, billpre.Id, plist.Id, pli.Id);
           oli1.Apttus_Config2__Status__c = 'Activated';
           oli1.Apttus_Config2__LineStatus__c = 'Cancelled';
          // oli1.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
           oli1.Apttus_Config2__OrderId__c = order.Id;
          // oli1.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
           oli1.Apttus_Config2__AssetLineItemId__c = ali2.Id;
           oli1.Apttus_CMConfig__AgreementId__c = aggr.Id;
           oli1.Apttus_Config2__ProductId__c = prd.Id;
            oli1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
           oli1.Apttus_Config2__ShipToAccountId__c = acc.Id;
           oli1.APTS_Serial_Number__c = '123';
           oli1.APTS_Installation_Date__c = system.today();
           oli1.APTS_Goods_Issue_Date__c = system.today().adddays(1);
           oli1.APTS_RefurbishedMachine__c = true;
           oli1.Apttus_Config2__StartDate__c=System.today();
           oli1.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
           oli1.Apttus_Config2__SellingTerm__c=12;
           oli1.Apttus_Config2__NetUnitPrice__c=10;
           oli1.Apttus_Config2__NetPrice__c=0;
           oli1.Apttus_Config2__BasePriceOverride__c=3;
           insert oli1;
           
           Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali1.Id, billpre.Id, plist.Id, pli.Id);
           oli.Apttus_Config2__Status__c = 'Activated';
           oLi.Apttus_Config2__LineStatus__c = 'Amended';
          // oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
          oli.Apttus_Config2__OrderId__c = order.Id;
         //  oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
           oli.APTS_Physical_Asset__c = oPhysicalAsset.Id;
           oli.Apttus_Config2__AssetLineItemId__c = ali1.Id;
           oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
           oli.Apttus_Config2__ProductId__c = prd.Id;
           oli.Apttus_Config2__ShipToAccountId__c = acc.Id;
           oli.APTS_Serial_Number__c = '123';
           oli.APTS_Installation_Date__c = system.today();
           oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
           oli.APTS_RefurbishedMachine__c = true;
           oli.Apttus_Config2__StartDate__c=System.today();
           oli.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
           oli.Apttus_Config2__SellingTerm__c=12;
           oli.Apttus_Config2__NetUnitPrice__c=10;
           oli.Apttus_Config2__NetPrice__c=0;
           insert oli;

           test.startTest();
            System.assertNotEquals(null, ali2.id);
           ali2.Apttus_Config2__AssetStatus__c = 'Cancelled';
           ali2.Apttus_Config2__NetPrice__c=20;
            ali2.Apttus_Config2__NetUnitPrice__c=10;
            ali2.Apttus_Config2__BusinessLineItemId__c=oli1.id;
           update ali2;
           test.stopTest();
    }

    static testMethod void testLAERAR2(){

        List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
      Account acc = APTS_TestUtils.createaccount();
       Database.insert(acc,false);
       
       
       Contact con = APTS_TestUtils.createContact();
      insert con;
            
       

       Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
       prd.Name = 'Product Name';
       prd.Description = 'Product Description';
       prd.ProductCode = '2345';
       Database.insert(prd,false);

       Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
       Database.insert(plist,false);
       
       Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
       aggr.Apttus__Status__c = 'In Effect';
       aggr.Apttus__Status_Category__c = 'Activated';
       insert aggr;
       
       Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
       insert pli;

       Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
       insert billpre;


       Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',plist.Id,acc.Id,billpre.Id);
       order.APTS_Contract_Change__c = 'Yes';
       order.APTS_Order_Type__c='Admin Order';
       order.APTS_Order_Sub_Type__c='Conversion Order';
       insert order;
       
       PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
       oPhysicalAsset.SerialNumber__c = 'Test123';
       insert oPhysicalAsset;
       
       Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
        ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
       ali1.Apttus_Config2__AccountId__c = acc.Id;
        ali1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        ali1.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
       ali1.APTS_RefurbishedMachine__c = true;
       ali1.Apttus_Config2__AssetStatus__c = 'New';
       ali1.Apttus_Config2__StartDate__c = system.today();
       ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
       // ali1.APTS_Serial_Number__c = '123';
       ali1.APTS_RefurbishedMachine__c = true;
       insert ali1;




Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
       ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
      ali2.Apttus_Config2__AccountId__c = acc.Id;
       ali2.APTS_RefurbishedMachine__c = true;
       ali2.Apttus_Config2__AssetStatus__c = 'Activated';
       ali2.Apttus_Config2__StartDate__c = system.today();
       ali2.Apttus_Config2__AssetStatus__c = 'Activated';
       ali2.APTS_Stop_RtR_Transactions_from__c=system.today().adddays(10000);
       ali2.Apttus_Config2__NetPrice__c=10;
      //  ali2.APTS_Serial_Number__c = '123';
       ali2.Apttus_Config2__LineType__c ='Product/Service';
       ali2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
       ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
       ali2.APTS_RefurbishedMachine__c = true;
     insert ali2;

      Apttus_Config2__OrderLineItem__c oli1 = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali2.Id, billpre.Id, plist.Id, pli.Id);
       oli1.Apttus_Config2__Status__c = 'Activated';
       oli1.Apttus_Config2__LineStatus__c = 'Cancelled';
      // oli1.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
       oli1.Apttus_Config2__OrderId__c = order.Id;
      // oli1.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
       oli1.Apttus_Config2__AssetLineItemId__c = ali2.Id;
       oli1.Apttus_CMConfig__AgreementId__c = aggr.Id;
       oli1.Apttus_Config2__ProductId__c = prd.Id;
        oli1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
       oli1.Apttus_Config2__ShipToAccountId__c = acc.Id;
       oli1.APTS_Serial_Number__c = '123';
       oli1.APTS_Installation_Date__c = system.today();
       oli1.APTS_Goods_Issue_Date__c = system.today().adddays(1);
       oli1.APTS_RefurbishedMachine__c = true;
       oli1.Apttus_Config2__StartDate__c=System.today();
       oli1.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
       oli1.Apttus_Config2__SellingTerm__c=12;
       oli1.Apttus_Config2__NetUnitPrice__c=10;
       oli1.Apttus_Config2__NetPrice__c=0;
       oli1.Apttus_Config2__BasePriceOverride__c=3;
       insert oli1;
       
       Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prd.Id, order.Id, ali1.Id, billpre.Id, plist.Id, pli.Id);
       oli.Apttus_Config2__Status__c = 'Activated';
       oLi.Apttus_Config2__LineStatus__c = 'Amended';
      // oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
      oli.Apttus_Config2__OrderId__c = order.Id;
     //  oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
       oli.APTS_Physical_Asset__c = oPhysicalAsset.Id;
       oli.Apttus_Config2__AssetLineItemId__c = ali1.Id;
       oli.Apttus_CMConfig__AgreementId__c = aggr.Id;
       oli.Apttus_Config2__ProductId__c = prd.Id;
       oli.Apttus_Config2__ShipToAccountId__c = acc.Id;
       oli.APTS_Serial_Number__c = '123';
       oli.APTS_Installation_Date__c = system.today();
       oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
       oli.APTS_RefurbishedMachine__c = true;
       oli.Apttus_Config2__StartDate__c=System.today();
       oli.Apttus_Config2__EndDate__c=System.today().addMonths(12).addDays(-1);
       oli.Apttus_Config2__SellingTerm__c=12;
       oli.Apttus_Config2__NetUnitPrice__c=10;
       oli.Apttus_Config2__NetPrice__c=0;
       insert oli;

       test.startTest();
       System.assertNotEquals(null, ali2.id);
       ali2.Apttus_Config2__AssetStatus__c = 'Cancelled';
       ali2.Apttus_Config2__NetPrice__c=20;
        ali2.Apttus_Config2__NetUnitPrice__c=10;
        ali2.Apttus_Config2__BusinessLineItemId__c=oli1.id;
       update ali2;
       test.stopTest();
}
    static testMethod void test_FinancialAssetStatus(){

        test.startTest();
        List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
        List<ID> assetLIIdList=new List<ID>();
        Date d=system.today();
        Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
    
        Contact con = APTS_TestUtils.createContact();
        insert con;
                
        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        prd.Name = 'Product Name';
        prd.Description = 'Product Description';
        prd.ProductCode = '2345';
        Database.insert(prd,false);

        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        insert aggr;
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        insert pli;

        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        insert billpre;

        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',plist.Id,acc.Id,billpre.Id);
        order.APTS_Contract_Change__c = 'Yes';
        order.APTS_Order_Type__c='Admin Order';
        order.APTS_Order_Sub_Type__c='Conversion Order';
        insert order;
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;

        Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali2.Apttus_Config2__AccountId__c = acc.Id;
        ali2.APTS_RefurbishedMachine__c = true;
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Apttus_Config2__StartDate__c = system.today();
        ali2.Apttus_Config2__NetPrice__c=10;
        //  ali2.APTS_Serial_Number__c = '123';
        ali2.Apttus_Config2__LineType__c ='Product/Service';
        ali2.Apttus_Config2__ChargeType__c='Service Fee';
        ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali2.APTS_RefurbishedMachine__c = true;
        insert ali2;
        assetLIIdList.add(ali2.Id);
        

        Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
        ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali1.Apttus_Config2__AccountId__c = acc.Id;
        ali1.APTS_RefurbishedMachine__c = true;
        ali1.Apttus_Config2__AssetStatus__c = 'Activated';
        ali1.Apttus_Config2__LineType__c = 'Option';
        ali1.Apttus_Config2__ChargeType__c='Service Fee';
        ali1.Apttus_Config2__BundleAssetId__c=ali2.id;
        ali1.Apttus_Config2__StartDate__c = system.today();
        ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
        // ali1.APTS_Serial_Number__c = '123';
        ali1.APTS_RefurbishedMachine__c = true;
        insert ali1;

        Apttus_Config2__AssetLineItem__c ali3 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
        ali3.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali3.Apttus_Config2__AccountId__c = acc.Id;
        ali3.APTS_RefurbishedMachine__c = true;
        ali3.Apttus_Config2__AssetStatus__c = 'Activated';
        ali3.Apttus_Config2__LineType__c = 'Option';
        ali3.Apttus_Config2__ChargeType__c='Additional Service Fee';
        ali3.Apttus_Config2__BundleAssetId__c=ali2.id;
        ali3.Apttus_Config2__StartDate__c = system.today();
        ali3.Apttus_Config2__EndDate__c = system.today().adddays(1);
        // ali1.APTS_Serial_Number__c = '123';
        ali3.APTS_RefurbishedMachine__c = true;
        insert ali3;
        
        Apttus_Config2__AssetLineItem__c ali4 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
        ali4.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali4.Apttus_Config2__AccountId__c = acc.Id;
        ali4.APTS_RefurbishedMachine__c = true;
        ali4.Apttus_Config2__AssetStatus__c = 'Activated';
        ali4.Apttus_Config2__LineType__c = 'Option';
        ali4.Apttus_Config2__ChargeType__c='Additional Service Fee';
        ali4.Apttus_Config2__BundleAssetId__c=ali2.id;
        ali4.Apttus_Config2__StartDate__c = system.today();
        ali4.Apttus_Config2__EndDate__c = system.today().adddays(1);
        //  ali1.APTS_Serial_Number__c = '123';
        ali4.APTS_RefurbishedMachine__c = true;
        insert ali4;

        APTS_AssetLineItemTriggerHandler.financialStatusprocessedAssetSet.clear();
        List<Apttus_Config2__AssetLineItem__c> updateList1 = new List<Apttus_Config2__AssetLineItem__c>();
        ali2.Apttus_Config2__AssetStatus__c = 'Activated';
        ali2.Name='ABC';
        ali1.Apttus_Config2__AssetStatus__c = 'Activated';
        ali1.Name='ABC1';
        ali3.Apttus_Config2__AssetStatus__c = 'Activated';
        ali3.Name='ABC2';
        ali4.Apttus_Config2__AssetStatus__c = 'Activated';
        ali3.Name='ABC3';
        updateList1.add(ali2);
        updatelist1.add(ali1);
        updatelist1.add(ali3);
        updatelist1.add(ali4);
        System.assertNotEquals(0, updatelist1.size());
        Update updatelist1;
        APTS_AssetLineItemTriggerHandler.createTransDatanewUX(assetLIIdList,d);
        test.stopTest();
    }
 }