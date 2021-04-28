/**
* Class Name : APTS_OrdUsagPricTierTrgrHandlerTest
* Description :  Test class for APTS_OrderUsagePriceTierTriggerHandler
* Author : Karan Khatri
* Date Created : 14/10/2019
**/
@isTest
public class APTS_OrdUsagPricTierTrgrHandlerTest{
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    private static testMethod void updateAgrFieldTestMethod() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.APTS_OrderUsagePriceTierTrigger__c = true;
        insert settings;
        
        Account testAccount = APTS_TestDataFactory.createAccount('JDE Test Account');
        Database.insert(testAccount);
        System.assert(testAccount != Null);
        
        
        Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('JDE Test PriceList');
        Database.insert(testPriceList);
        
        Contact testPrimaryContact = APTS_TestDataFactory.createContact(testAccount, '+1235678993');
        Database.insert(testPrimaryContact);
        
        Apttus_Config2__Order__c testOrder = APTS_TestDataFactory.createOrder(testAccount.Id, testPriceList.Id, testPrimaryContact.Id);
        testOrder.APTS_Requested_Installation_Date__c=null;
        testOrder.APTS_Order_Type__c=APTS_OrderConstants.ADMIN_ORDER;
        testOrder.APTS_Order_Sub_Type__c='Conversion order';
        Database.insert(testOrder);
        
        Apttus_Config2__ProductConfiguration__c testProdConfig = APTS_TestDataFactory.createProductConfig(testOrder);
        //testProdConfig.Apttus_Config2__CouponCodes__c = 'TEST';
        Database.insert(testProdConfig);

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(testProdConfig,pli1.id , NULL, prod1.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, NULL,NULL, 'One Time', 'Per Unit', 'Each', 100, 2);
        oMachineLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
        oMachineLineItemBundle.Apttus_Config2__ClassificationHierarchy__c = 'Machines';
        Database.insert(oMachineLineItemBundle, FALSE);
        
        Apttus_Config2__ProductAttributeValue__c prodAttribValue = new Apttus_Config2__ProductAttributeValue__c();
        prodAttribValue.Apttus_Config2__LineItemId__c= oMachineLineItemBundle.id;
        prodAttribValue.APTS_Base_Price_Override_per_cup_FV__c=10;
        prodAttribValue.APTS_Base_Price_Override_per_cup__c=20;
        prodAttribValue.APTS_List_Price_per_cup_FV__c=30;
        prodAttribValue.APTS_List_Price_per_cup__c=40;
        prodAttribValue.APTS_Type_of_Consumption__c='Free Vend';
        Database.insert(prodAttribValue, FALSE);
        
        oMachineLineItemBundle.Apttus_Config2__AttributeValueId__c=prodAttribValue.id;
        Database.update(oMachineLineItemBundle,false);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(testAccount.Id, prod1.Id, oPricelist.Id, pli1.Id , null , testOrder.Id);
        insert ali;
        
        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOLI.Apttus_Config2__OrderId__c = testOrder.id;
        oOLI.Apttus_Config2__AssetLineItemId__c=ali.id;
        oOLI.Apttus_Config2__DerivedFromId__c=oMachineLineItemBundle.id;
        insert oOLI;
        
        Apttus_Config2__AssetUsagePriceTier__c assetusage = new Apttus_Config2__AssetUsagePriceTier__c();
        assetusage.Apttus_Config2__AssetLineItemId__c=ali.id;
        assetusage.Apttus_Config2__TierStartValue__c=0;
        assetusage.Apttus_Config2__TierEndValue__c=99999;
        assetusage.Apttus_Config2__Dimension1Value__c='Free Vend';
        assetusage.Apttus_Config2__Sequence__c=1;
        insert assetusage;
        
        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Free Vend';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier, FALSE);
        
    }
    
     private static testMethod void updateAgrFieldTestMethod2() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.APTS_OrderUsagePriceTierTrigger__c = true;
        insert settings;
        
        Account testAccount = APTS_TestDataFactory.createAccount('JDE Test Account');
        Database.insert(testAccount);
        System.assert(testAccount != Null);
        
        
        Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('JDE Test PriceList');
        Database.insert(testPriceList);
        
        Contact testPrimaryContact = APTS_TestDataFactory.createContact(testAccount, '+1235678993');
        Database.insert(testPrimaryContact);
        
        Apttus_Config2__Order__c testOrder = APTS_TestDataFactory.createOrder(testAccount.Id, testPriceList.Id, testPrimaryContact.Id);
        testOrder.APTS_Requested_Installation_Date__c=null;
        testOrder.APTS_Order_Type__c=APTS_OrderConstants.ADMIN_ORDER;
        testOrder.APTS_Order_Sub_Type__c='Conversion order';
        Database.insert(testOrder);
        
        Apttus_Config2__ProductConfiguration__c testProdConfig = APTS_TestDataFactory.createProductConfig(testOrder);
        //testProdConfig.Apttus_Config2__CouponCodes__c = 'TEST';
        Database.insert(testProdConfig);

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(testProdConfig,pli1.id , NULL, prod1.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, NULL,NULL, 'One Time', 'Per Unit', 'Each', 100, 2);
        oMachineLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
        oMachineLineItemBundle.Apttus_Config2__ClassificationHierarchy__c = 'Machines';
        Database.insert(oMachineLineItemBundle, FALSE);
        
        Apttus_Config2__ProductAttributeValue__c prodAttribValue = new Apttus_Config2__ProductAttributeValue__c();
        prodAttribValue.Apttus_Config2__LineItemId__c= oMachineLineItemBundle.id;
        prodAttribValue.APTS_Base_Price_Override_per_cup_FV__c=10;
        prodAttribValue.APTS_Base_Price_Override_per_cup__c=20;
        prodAttribValue.APTS_List_Price_per_cup_FV__c=30;
        prodAttribValue.APTS_List_Price_per_cup__c=40;
        prodAttribValue.APTS_Type_of_Consumption__c='Paid';
        Database.insert(prodAttribValue, FALSE);
        
        oMachineLineItemBundle.Apttus_Config2__AttributeValueId__c=prodAttribValue.id;
        Database.update(oMachineLineItemBundle,false);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(testAccount.Id, prod1.Id, oPricelist.Id, pli1.Id , null , testOrder.Id);
        insert ali;
        
        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOLI.Apttus_Config2__OrderId__c = testOrder.id;
        oOLI.Apttus_Config2__AssetLineItemId__c=ali.id;
        oOLI.Apttus_Config2__DerivedFromId__c=oMachineLineItemBundle.id;
        insert oOLI;
        
        Apttus_Config2__AssetUsagePriceTier__c assetusage = new Apttus_Config2__AssetUsagePriceTier__c();
        assetusage.Apttus_Config2__AssetLineItemId__c=ali.id;
        assetusage.Apttus_Config2__TierStartValue__c=0;
        assetusage.Apttus_Config2__TierEndValue__c=99999;
        assetusage.Apttus_Config2__Dimension1Value__c='Paid';
        assetusage.Apttus_Config2__Sequence__c=1;
        insert assetusage;
        
        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier, FALSE);
        
    }
    
    private static testMethod void updateAgrFieldTestMethod3() {
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.APTS_OrderUsagePriceTierTrigger__c = true;
        insert settings;
        
        Account testAccount = APTS_TestDataFactory.createAccount('JDE Test Account');
        Database.insert(testAccount);
        System.assert(testAccount != Null);
        
        
        Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('JDE Test PriceList');
        Database.insert(testPriceList);
        
        Contact testPrimaryContact = APTS_TestDataFactory.createContact(testAccount, '+1235678993');
        Database.insert(testPrimaryContact);
        
        Apttus_Config2__Order__c testOrder = APTS_TestDataFactory.createOrder(testAccount.Id, testPriceList.Id, testPrimaryContact.Id);
        testOrder.APTS_Requested_Installation_Date__c=null;
        testOrder.APTS_Order_Type__c=APTS_OrderConstants.ADMIN_ORDER;
        testOrder.APTS_Order_Sub_Type__c='Conversion order';
        Database.insert(testOrder);
        
        Apttus_Config2__ProductConfiguration__c testProdConfig = APTS_TestDataFactory.createProductConfig(testOrder);
        //testProdConfig.Apttus_Config2__CouponCodes__c = 'TEST';
        Database.insert(testProdConfig);

        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(testProdConfig,pli1.id , NULL, prod1.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, NULL,NULL, 'One Time', 'Per Unit', 'Each', 100, 2);
        oMachineLineItemBundle.Apttus_Config2__IsPrimaryLine__c = true;
        oMachineLineItemBundle.Apttus_Config2__ClassificationHierarchy__c = 'Machines';
        Database.insert(oMachineLineItemBundle, FALSE);
        
        Apttus_Config2__ProductAttributeValue__c prodAttribValue = new Apttus_Config2__ProductAttributeValue__c();
        prodAttribValue.Apttus_Config2__LineItemId__c= oMachineLineItemBundle.id;
        prodAttribValue.APTS_Base_Price_Override_per_cup_FV__c=10;
        prodAttribValue.APTS_Base_Price_Override_per_cup__c=20;
        prodAttribValue.APTS_List_Price_per_cup_FV__c=30;
        prodAttribValue.APTS_List_Price_per_cup__c=40;
        prodAttribValue.APTS_Type_of_Consumption__c='Both';
        Database.insert(prodAttribValue, FALSE);
        
        oMachineLineItemBundle.Apttus_Config2__AttributeValueId__c=prodAttribValue.id;
        Database.update(oMachineLineItemBundle,false);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(testAccount.Id, prod1.Id, oPricelist.Id, pli1.Id , null , testOrder.Id);
        insert ali;
        
        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOLI.Apttus_Config2__OrderId__c = testOrder.id;
        oOLI.Apttus_Config2__AssetLineItemId__c=ali.id;
        oOLI.Apttus_Config2__DerivedFromId__c=oMachineLineItemBundle.id;
        insert oOLI;
        
        Apttus_Config2__AssetUsagePriceTier__c assetusage1 = new Apttus_Config2__AssetUsagePriceTier__c();
        assetusage1.Apttus_Config2__AssetLineItemId__c=ali.id;
        assetusage1.Apttus_Config2__TierStartValue__c=0;
        assetusage1.Apttus_Config2__TierEndValue__c=99999;
        assetusage1.Apttus_Config2__Dimension1Value__c='Free Vend';
        assetusage1.Apttus_Config2__Sequence__c=1;
        insert assetusage1;
        
        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier1 = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier1.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier1.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier1.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier1.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier1, FALSE);
        
         Apttus_Config2__AssetUsagePriceTier__c assetusage = new Apttus_Config2__AssetUsagePriceTier__c();
        assetusage.Apttus_Config2__AssetLineItemId__c=ali.id;
        assetusage.Apttus_Config2__TierStartValue__c=0;
        assetusage.Apttus_Config2__TierEndValue__c=99999;
        assetusage.Apttus_Config2__Dimension1Value__c='Paid';
        assetusage.Apttus_Config2__Sequence__c=1;
        insert assetusage;
        
        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c = 1;
        Database.insert(oOrderUsagePriceTier, FALSE);
        
    }
}