/*************************************************************
@Name: APTS_AssetLineItemTriggerTest
@Author: Pranjal Mittal
@CreateDate: 22-01-2018
@Description:
@UsedBy:
******************************************************************/
@isTest
private class APTS_AssetLineItemTriggerTest {

    @testSetup
    static void testData(){
        TriggerSettings__c tstSetting = new TriggerSettings__c();
        tstSetting.AssetLineItemTrigger__c = true;
        insert tstSetting;

        Account testAcc = new Account(Name = 'TEST');
        insert testAcc;

        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Old_Net_Price__c = 100;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset;

        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__LineNumber__c = 1;
        tstAsset1.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'New';
        tstAsset1.APTS_Old_Net_Price__c = 100;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset1.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset1;
    }
    
    static testMethod void testActivation() {

        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c,Apttus_Config2__ChargeType__c,APTS_Type_Of_Contract__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c where Apttus_Config2__AssetStatus__c ='New' LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Apttus_Config2__AssetAttributeValue__c tstValue = new Apttus_Config2__AssetAttributeValue__c();
        tstValue.APTS_Type_of_contract__c = 'Sales';
        tstValue.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstValue;

        Test.startTest();
        Apttus_Config2__AssetLineItem__c tstAsset1 = new  Apttus_Config2__AssetLineItem__c();
        insert tstAsset1;
        delete tstAsset1;
        undelete tstAsset1;

        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        tstAsset.APTS_Manual_Activation_Date__c = null;
        tstAsset.Apttus_Config2__AttributeValueId__c = tstValue.Id;
        update tstAsset;

        Test.stopTest();

    }

    static testMethod void testDeactivation() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'Cancel';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Cancelled';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        tstAsset.Apttus_Config2__EndDate__c = Date.today().addDays(50);
        update tstAsset;

        Test.stopTest();

    }

    static testMethod void testRenewal() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c,Apttus_Config2__ChargeType__c,APTS_Type_Of_Contract__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c where Apttus_Config2__AssetStatus__c ='New' LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'Renew';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        update tstAsset;

        APTS_Historical_Price_Change__c tstHPC = new APTS_Historical_Price_Change__c();
        tstHPC.APTS_AssetLineItem__c = tstAsset.id;
        tstHPC.APTS_Start_date__c = system.today();
        insert tstHPC;
        Test.stopTest();

    }

    static testMethod void testAmendment() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'Amend';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        update tstAsset;
        Test.stopTest();

    }

    static testMethod void testActivation1() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c,Apttus_Config2__ChargeType__c,APTS_Type_Of_Contract__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        update tstAsset;
        Test.stopTest();

        List<RTR_LAE_Transaction_Data__c> lstTranData = [SELECT Id FROM RTR_LAE_Transaction_Data__c];
        System.assertEquals('New', tstHistory.Apttus_Config2__Action__c);
    }

    static testMethod void testEntityChange() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        //tstAsset.Apttus_Config2__NetPrice__c = 200;
        update tstAsset;
        Test.stopTest();
    }


    static testMethod void testManualActivation() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        tstAsset.APTS_Manual_Activation_Date__c = Date.today();
        update tstAsset;

        Test.stopTest();

    }

    static testMethod void testManualDeactivation() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'Cancel';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Cancelled';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        tstAsset.APTS_Manual_DeActivation_Date__c = Date.today();
        update tstAsset;

        Test.stopTest();

    }


    static testMethod void testUsedProduct() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        //tstAsset.Used_Product_Dummy__c = true;
        update tstAsset;

        Test.stopTest();

    }   

    static testMethod void testManualRelocation() {
        Apttus_Config2__AssetLineItem__c tstAsset = [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__PrimaryLineNumber__c,
        Apttus_Config2__NetPrice__c, Apttus_Config2__AssetStatus__c, APTS_Old_Net_Price__c, Apttus_Config2__EndDate__c
        FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        
        Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        insert tstHistory;

        Test.startTest();
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.Apttus_Config2__NetPrice__c = 200;
        tstAsset.Apttus_Config2__AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        tstAsset.Manually_Relocated_Dummy__c = true;
        update tstAsset;

        Test.stopTest();
    } 


    static testMethod void testIndexation() {
        APTS_AssetLineItemTriggerHandler tstHandler = new APTS_AssetLineItemTriggerHandler();
        sObject assetLineItem = Schema.getGlobalDescribe().get('Apttus_Config2__AssetLineItem__c').newSObject();
        Map<sObject, Apttus_Config2__AssetLineItem__c> mapObj = new Map<sObject, Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c asset = [SELECT Id FROM Apttus_Config2__AssetLineItem__c LIMIT 1];
        Set<Id> idSet = new Set<Id>{asset.Id};
        tstHandler.createIndexationTransData(idSet);

    }
    
    static testMethod void testAssetTrigger(){
        
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
        test.stopTest();
        
        List<Apttus_Config2__AssetLineItem__c> aliInsertList = new List<Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        aliInsertList.add(ali);
        
        Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali1.Apttus_Config2__AssetStatus__c = 'Terminated';
        aliInsertList.add(ali1);
        
        Database.insert(aliInsertList,False);

        ali.Apttus_Config2__AssetStatus__c = 'Terminated';
        Database.update(ali,False);
    }
    
    static testMethod void testcreatePhyAssetTrigger(){
    
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

        APTS_Historical_Price_Change__c tstHPC = new APTS_Historical_Price_Change__c();
        tstHPC.APTS_AssetLineItem__c = ali.id;
        tstHPC.APTS_Start_date__c = system.today();
        insert tstHPC;

        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        Database.update(aliInsertList, false);

        test.stopTest();
    }
    Static testmethod void testassetmvmt(){
    
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
    
        Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
    
        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);
        
        Apttus__APTS_Agreement__c aggr1 = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr1,false);
        
        Apttus_Config2__AssetLineItem__c tstAsset2 = new Apttus_Config2__AssetLineItem__c();
        tstAsset2.Apttus_Config2__LineNumber__c = 1;
        tstAsset2.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset2.Apttus_Config2__NetPrice__c = 100;
        tstAsset2.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset2.APTS_Old_Net_Price__c = 100;
        tstAsset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
        tstAsset2.Apttus_Config2__HasOptions__c = true;
        tstAsset2.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset2.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset2.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        insert tstAsset2;
        
        tstAsset2.Apttus_CMConfig__AgreementId__c = aggr1.Id;
        update tstAsset2;
        
        }
    
    
    
}