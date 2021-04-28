/*************************************************************
@Name: APTS_OrderUtilsTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Order Utils Test
@UsedBy: APTS_OrderUtils
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_OrderUtilsTest {

    private static final String FULFILLED = System.Label.APTS_Fulfilled;
    private static final String ACTIVATED = System.Label.APTS_Activated;

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        
        String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Default Business Hours').getRecordTypeId();
        List<CountrySetting__c> cset = new List<CountrySetting__c>();
        CountrySetting__c cset1 = new CountrySetting__c();
        CountrySetting__c cset2 = new CountrySetting__c();
        cset1.Country__c = 'SAP_0111';
        cset1.RecordTypeId = recordTypeId;
        cset1.Active__c = true;
        cset1.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault=true limit 1].id;
        
        String recordTypeId1 = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Scheduling Rules (Ingredients)').getRecordTypeId();
        cset2.Country__c = 'SAP_0111';
        cset2.RecordTypeId = recordTypeId1;
        cset2.Active__c = true;
        cset2.AdditionalOffset__c = 1;
        //cset2.Additional_Offset_Time__c = 1 ;
        cset2.PickupOffset__c = 1;
        cset2.DeliveryOffset__c = 1;
        
        cset.add(cset1);
        cset.add(cset2);
        insert cset;
    }

     @isTest static void test_MachineOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('AgreementCM');
        Account oAccount = APTS_TestFacade.getAccount();
        Map<Id, Contact> idToContactMap = APTS_TestFacade.getContacts(oAccount.Id);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();

        Test.startTest();

        //System.runAs(oTestUser) {

        Set<Id> lineItemIdSet = new Set<Id>();
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            lineItemIdSet.add(oOrderLineItem.Apttus_Config2__DerivedFromId__c);
        }

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = APTS_OrderUtils.getLineItemDataAll(lineItemIdSet);

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = APTS_OrderUtils.prepareOptionsList(idToLineItemMap);
        Id deriverdId = orderLineItemList[0].Apttus_Config2__DerivedFromId__c;

        Apttus_Config2__LineItem__c oBundleLineItem = idToLineItemMap.get(orderLineItemList[0].Apttus_Config2__DerivedFromId__c);

        APTS_OrderUtils.addBundleWithOptions(oProductConfiguration.Id, oBundleLineItem, 1, bundelLineNumberToOptionListMap);
        APTS_OrderUtils.updateCart(oProductConfiguration.Id, oAgreement.Id, null);

        APTS_OrderUtils.createReturnOrder(oOrder);
        APTS_OrderUtils.submitOrder(oOrder.Id);
        APTS_OrderUtils.acceptOrder(oOrder.Id);
        APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, 'machine');
        APTS_OrderUtils.getPrimaryContactId(idToContactMap, 'machine');
        //APTS_OrderUtils.getTaskList(new List<Apttus_Config2__Order__c> {oOrder});

        APTS_OrderUtils.cloneLSPDetails(orderLineItemList[0].APTS_Order_LSP_Detail__c);
        Map<String, Id> productIdAndLineNumberAndChargeTypeToLIIdMap = new Map<String, Id>();
        productIdAndLineNumberAndChargeTypeToLIIdMap.put('Test', oBundleLineItem.Id);
        APTS_OrderUtils.fixNonPrimaryLines(oProductConfiguration.Id, productIdAndLineNumberAndChargeTypeToLIIdMap);

        APTS_OrderUtils.cloneOrderHeader(oOrder);
        Set<Id> setOrderId = new Set<Id> {oOrder.Id};
        APTS_OrderUtils.clearATPResultsMultiOrders(setOrderId);
        APTS_OrderUtils.createIntegrationLog(oOrder);

        oOrder.Apttus_Config2__Status__c = 'Pending';
        Database.update(oOrder);
        APTS_OrderUtils.amendOrder(oOrder.Id);
        //}

        Test.stopTest();
    }

    @isTest static void test_ConversionOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();

        Test.startTest();

        //  System.runAs(oTestUser) {

        Set<Id> lineItemIdSet = new Set<Id>();
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            lineItemIdSet.add(oOrderLineItem.Apttus_Config2__DerivedFromId__c);
        }

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = APTS_OrderUtils.getLineItemDataAll(lineItemIdSet);

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = APTS_OrderUtils.prepareOptionsList(idToLineItemMap);
        Id deriverdId = orderLineItemList[0].Apttus_Config2__DerivedFromId__c;

        Apttus_Config2__LineItem__c oBundleLineItem = idToLineItemMap.get(orderLineItemList[0].Apttus_Config2__DerivedFromId__c);

        APTS_OrderUtils.prepareOptionsListAll(idToLineItemMap);
        APTS_OrderUtils.addBundleWithOptionsAll(oProductConfiguration.Id, oBundleLineItem, 1, bundelLineNumberToOptionListMap);

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemNewMap = new Map<Id, Apttus_Config2__LineItem__c>([
                    SELECT Id, Apttus_Config2__AttributeValueId__c, Apttus_Config2__DerivedFromId__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__ConfigurationId__c = :oProductConfiguration.Id]);

        APTS_OrderUtils.updateProductAttributeValues(idToLineItemNewMap, idToLineItemMap);
        // }

        Test.stopTest();
    }

    @isTest static void test_StandardOrder() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        Account oAccount = APTS_TestFacade.getAccount();
        Map<Id, Contact> idToContactMap = APTS_TestFacade.getContacts(oAccount.Id);
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getMachineProductConfiguration();

        Test.startTest();

        //System.runAs(oTestUser) {

        Set<Id> lineItemIdSet = new Set<Id>();
        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
            lineItemIdSet.add(oOrderLineItem.Apttus_Config2__DerivedFromId__c);
        }

        Map<Id, Apttus_Config2__LineItem__c> idToLineItemMap = APTS_OrderUtils.getLineItemDataAll(lineItemIdSet);

        Map<Decimal, List<Apttus_CPQApi.CPQ.SelectedOptionDO>> bundelLineNumberToOptionListMap = APTS_OrderUtils.prepareOptionsList(idToLineItemMap);
        Id deriverdId = orderLineItemList[0].Apttus_Config2__DerivedFromId__c;

        Apttus_Config2__LineItem__c oBundleLineItem = idToLineItemMap.get(orderLineItemList[0].Apttus_Config2__DerivedFromId__c);
        APTS_OrderUtils.addStandaloneProductWithQuantity(oBundleLineItem, 1);
        APTS_OrderUtils.createReturnOrder(oOrder);
        APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, 'standard');
        APTS_OrderUtils.getPrimaryContactId(idToContactMap, 'standard');
        // }

        Test.stopTest();
    }

    @isTest static void test_setOrderHeader() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
        Set<Id> sAccount = new Set<Id>();
        sAccount.add(oAccount.id);

        Test.startTest();

        // System.runAs(oTestUser) {
        APTS_OrderUtils.getAllContacts(oAccount.Id);
        APTS_OrderUtils.getPrimaryContactsRSO('Standard', sAccount);
        APTS_OrderUtils.getAccountLocation(sAccount);
        APTS_OrderUtils.getTriggerSettings();
        APTS_OrderUtils.setOrderHeader(oOrder, oAgreement, oAccount);
        APTS_OrderUtils.setOrderHeader(oOrder, oAccount);
        APTS_OrderUtils.startOrderTrigger();
        APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.startOrderLineItemTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_OrderUtils.startAssetLineItemTrigger();
        APTS_OrderUtils.stopAssetLineItemTrigger();
        // }

        Test.stopTest();
    }

    @isTest static void test_Cart() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();

        Test.startTest();

        //System.runAs(oTestUser) {

        ID cartId = APTS_OrderUtils.createCart(oOrder.Id);
        APTS_OrderUtils.repriceCart(cartId);
        APTS_OrderUtils.saveCart(cartId);
        APTS_OrderUtils.finalizeCart(cartId);
        APTS_OrderUtils.syncCart(cartId);
        APTS_OrderUtils.checkfreefreight(cartId);
        

        Test.stopTest();
    } 

   @isTest static void test_RDD() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.APTS_Sales_Organization__c = 'SAP_0111';
        oOrder.APTS_SAP_OrderType__c = 'XA01';
        update oOrder;
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Apttus_Config2__OrderLineItem__c oLI = orderLineItemList[0];
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('AgreementCM');
        Account oAccount = APTS_TestFacade.getAccount();
        Map<Id, Contact> idToContactMap = APTS_TestFacade.getContacts(oAccount.Id);
        Test.startTest();
            
        //System.runAs(oTestUser) {

        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>();
        idToOrderMap.put(oOrder.Id, oOrder);

        Map<Id, List<CountrySetting__c>> orderIdToCountrySettingListMap = APTS_OrderUtils.prepareOrderIdToCountrySettingListMap(idToOrderMap);
        List<CountrySetting__c> countrySettingList = orderIdToCountrySettingListMap.get(oOrder.Id);
        
        Date dtRequestedDeliveryDateResult1 = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, Date.today());
        
        List<CountrySetting__c> csSet = [select id,RecordType.DeveloperName, RecordType.Name,PickupOffset__c,Additional_Offset_Time__c,DeliveryOffset__c,AdditionalOffset__c,Business_Hours__c  from CountrySetting__c where  (RecordType.DeveloperName = 'APTS_Country_Scheduling_Rules_Ingredients' or RecordType.DeveloperName = 'CountryDefaultBusinessHours')];
        Date dtRequestedDeliveryDateResult2 = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder,csSet, Date.today());
       try{
        Boolean bDateCheck = APTS_OrderUtils.checkWithIBusinessHoursRDD(system.now());
       }
       catch(Exception ex){}
        
        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = oAccount.Id;
        loc.Account_Location_Status__c  = 'Valid';
        insert loc;

        oLI.Apttus_Config2__LocationId__c = loc.id;
        oLI.APTS_Requested_Delivery_Date__c = system.today();
       oLI.APTS_SAP_OrderType__c = 'XB13';
        upsert oLI;

        APTS_OrderUtils.getDeliveryTimeframes(oli,loc);
       APTS_OrderUtils.APTS_AdjustmentLIWrapper adjLIW = new APTS_OrderUtils.APTS_AdjustmentLIWrapper();
       adjLIW.itemID = null;
    adjLIW.subType = 'ZX10';
    adjLIW.lineNumber = 1;   
    adjLIW.lineItemID = oLI.id;
       List<APTS_OrderUtils.APTS_AdjustmentLIWrapper> adjList = new List<APTS_OrderUtils.APTS_AdjustmentLIWrapper>();
       adjList.add(adjLIW);
       APTS_OrderUtils.checkIfAdjustmentValueIsZX10(oLI,adjList);
        Test.stopTest();
    }

    @isTest static void test_Asset() {

        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();

        List<Id> assetIdList = new List<Id>();
        for (Apttus_Config2__AssetLineItem__c oAssetLineItem : assetLineItemList) {
            assetIdList.add(oAssetLineItem.Id);
        }

        Test.startTest();

        // System.runAs(oTestUser) {
        APTS_OrderUtils.changeAssets(oProductConfiguration.Id, assetIdList);
        APTS_OrderUtils.cancelAssets(oProductConfiguration.Id, assetIdList);
        // }

        Test.stopTest();
    }

    @isTest static void test_AgLine() {

        User oTUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestFacade.getProductConfiguration();
        List<Apttus__AgreementLineItem__c> lBundleAgLI = APTS_TestFacade.getProductAgLineItem('Bundle');
        List<Apttus__AgreementLineItem__c> lStandaloneAgLI = APTS_TestFacade.getProductAgLineItem('Standalone');
        List<Apttus__AgreementLineItem__c> lOptionAgLI = APTS_TestFacade.getOptionAgLineItem();

        Test.startTest();

        //System.runAs(oTUser) {
        Decimal dcLineNumber = APTS_OrderUtils.addAgreementLineItemToCart(oProductConfiguration.Id, lBundleAgLI[0], lOptionAgLI);
        System.assertNotEquals(null, dcLineNumber);
        dcLineNumber = APTS_OrderUtils.addAgreementLineItemToCart(oProductConfiguration.Id, lStandaloneAgLI[0], null);
        System.assertNotEquals(null, dcLineNumber);
        //}

        Test.stopTest();
    }
    
   
}