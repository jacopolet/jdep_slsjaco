/*************************************************************
@Name: APTS_OrderLineItemTriggerHandlerTest
@Author: Galin Georgiev
@CreateDate: 14-03-2018
@Description: Order Line Item Trigger Handler Test
@UsedBy: APTS_OrderLineItemTriggerHandler
******************************************************************/
//v100 14-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
@isTest
private with sharing class APTS_OrderLineItemUtilsTest {

    @testSetup
    static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
         
    }
    
    @isTest
    static void test_OrderLineItemUtils() {

        User oTestUser = APTS_TestFacade.getTestUser();
        
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Set<Id> oLIIdSet = new Set<Id>(new Map<Id, Apttus_Config2__OrderLineItem__c>(orderLineItemList).keySet());

        Test.startTest();
        //System.runAs(oTestUser) {
            APTS_OrderLineItemUtils.getOrderLineItemAdditionalData((new Map<Id, SObject>(orderLineItemList)).keySet());
            List<PhysicalAsset__c> physicalAssetList = [SELECT Id FROM PhysicalAsset__c];
            //System.assertEquals([Select id from Apttus__APTS_Agreement__c].size(), 1);
            APTS_Agreement_PO_Details__c machinePODetail = APTS_TestDataFactory.createAgreementPOdetails([Select id from Apttus__APTS_Agreement__c limit 1].Id);
            insert machinePODetail;
            List<APTS_Agreement_PO_Details__c> POAgg = [SELECT Id, APTS_PO_Category__c, APTS_PO_Number_Required__c, APTS_PO_Number_Type__c, APTS_PO_Number__c FROM APTS_Agreement_PO_Details__c];
            //System.assertEquals(POAgg.size(),1);
            Map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            Map<Id, List<APTS_Agreement_PO_Details__c>> agreementPOMap = new Map<Id, List<APTS_Agreement_PO_Details__c>>();
            agreementPOMap.put(orderLineItemList[0].Id, new List<APTS_Agreement_PO_Details__c>{POAgg[0]});
            physicalAssetIdToOLIMap.put(physicalAssetList[0].Id, orderLineItemList[0]);
            APTS_OrderLineItemUtils.updatePhysicalAssetOnOLIUpdate(physicalAssetIdToOLIMap, agreementPOMap);
        //}
        Test.stopTest();
    } 
    
    @isTest
    static void test_createPhysicalAsset() {
          
        User oTestUser = APTS_TestFacade.getTestUser();
     
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        
        List<Apttus_Config2__OrderLineItem__c> oLIList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        
        Apttus_Config2__OrderProductAttributeValue__c attribute = new Apttus_Config2__OrderProductAttributeValue__c(
        Apttus_Config2__LineItemId__c = oLIList[0].Id,
        APTS_Type_of_contract__c = 'Sales',
        APTS_Call_Out_Coverage_Percent__c = 100.0,
        APTS_Labour_Coverage_Percent__c = 100.0,
        APTS_Spare_Parts_Coverage_Percent__c = 100.0,
        APTS_Number_of_hours_per_month__c = 10.0,
        APTS_First_Line_Response_Time__c = 2.0,
        APTS_Response_Profile__c = 'Response time 2 hours'
        );
        insert attribute;
        
        Test.startTest();
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Material_Type__c = 'ZCMA';
            orderLineItemList[0].Apttus_Config2__HasOptions__c  = true;
            orderLineItemList[0].Apttus_Config2__LineType__c = 'OPTION';
            Database.update(orderLineItemList);
                
            oPhysicalAsset.AssetStatus__c = 'Pending Activation';
            oPhysicalAsset.SerialNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Vendor_Code__c = 'BBN';
            oPhysicalAsset.UniqueNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            Database.update(orderLineItemList);
           
            orderLineItemList[0].APTS_Option_Group_Text__c = 'Text';
            orderLineItemList[0].Apttus_Config2__AttributeValueId__c = attribute.Id;
            Database.update(orderLineItemList);
            
            Set<Id> oliIdSet = new Set<Id>{orderLineItemList[0].Id};
            Map<Id, Apttus_Config2__OrderLineItem__c> oLIMap = APTS_OrderLineItemUtils.getOrderLineItemAdditionalData(oliIdSet);
            
            Apttus_Config2__OrderLineItem__c oLI = oLIMap.get(orderLineItemList[0].Id);
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'Comfort Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Co Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Semi Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'ALL-IN COVERAGE';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Service Window';
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Extended Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);

            oLI.Apttus_Config2__Description__c = 'Extended Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
        Test.stopTest();
    }
    
    @isTest
    static void test_agreementPOdetails() {

        PhysicalAsset__c oPhysicalasset = [SELECT Id FROM PhysicalAsset__c][0];
        List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        
        APTS_Agreement_PO_Details__c agreementPO = new APTS_Agreement_PO_Details__c ();
        agreementPO.APTS_PO_Category__c = 'Machine';
        agreementPO.APTS_PO_Number_Required__c = 'YES';
        agreementPO.APTS_PO_Number_Type__c = 'Fixed';
        agreementPO.APTS_PO_Number__c = '5645';
        poList.add(agreementPO);
        
        APTS_Agreement_PO_Details__c agreementPOservices = new APTS_Agreement_PO_Details__c ();
        agreementPOservices.APTS_PO_Category__c = 'Services';
        agreementPOservices.APTS_PO_Number_Required__c = 'YES';
        agreementPOservices.APTS_PO_Number_Type__c = 'Fixed';
        agreementPOservices.APTS_PO_Number__c = '65354';
        poList.add(agreementPOservices);
        
        APTS_OrderLineItemUtils.setAgreementPODetails(oPhysicalasset, poList);
    }
    
    @isTest
    static void test_PhysicalAssetUpdate(){
        
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Set<Id> parentOLISet = new Set<Id>{oOrder.Id};
        Map<String, Apttus_Config2__OrderLineItem__c> childOLIMap = APTS_OrderLineItemUtils.getChildOLIFromParentOLI(parentOLISet);
        
        PhysicalAsset__c oPhysicalasset = [SELECT Id FROM PhysicalAsset__c][0];
        
        Apttus_Config2__OrderLineItem__c oLI = new Apttus_Config2__OrderLineItem__c();
        oLI.Apttus_Config2__Description__c = 'Full Operating';
        
        PhysicalAsset__c updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Preventive Maintenance';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.APTS_Option_Group_Text__c = 'Machine Care';
        oLI.Apttus_Config2__Description__c = 'Comfort Operating';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        system.assertEquals('Comfort Operating',updatedAsset.Machine_Care__c);
        
        oLI.APTS_Option_Group_Text__c = 'Response Time';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Full Co Operating';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Full Operating';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Semi Operating';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);

        oLI.Apttus_Config2__Description__c = 'Connectivity';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Payment Module';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'ALL-IN COVERAGE'; 
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.APTS_Option_Group_Text__c = 'Service Window';
        oLI.Apttus_Config2__Description__c = 'Standard Weekdays';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Extended Weekdays';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
        
        oLI.Apttus_Config2__Description__c = 'Standard Weekdays & Weekend';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);

        oLI.Apttus_Config2__Description__c = 'Extended Weekdays & Weekend';
        updatedAsset = APTS_OrderLineItemUtils.populatePhysicalAssetFields(oLI, oPhysicalAsset);
		map<Id, Apttus_Config2__OrderLineItem__c> physicalAssetIdToOLIMap = new map<Id, Apttus_Config2__OrderLineItem__c>();
       // Map<Id, List<APTS_Agreement_PO_Details__c>> agreementPOMap, 
       Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c ol: childOLIMap.values()){
            if(ol.Apttus_Config2__OptionId__c != null){
                 ol.APTS_Option_Group_Text__c = 'Preventive Maintenance';
                 ol.Apttus_Config2__OptionId__r.Name = 'PREV. MAIIN 2X YEAR';
                 APTS_OrderLineItemUtils.populatePhysicalAssetFields(ol, oPhysicalAsset);
                if(ol.APTS_Physical_Asset__c != null)
                {
                    physicalAssetIdToOLIMap.put(ol.APTS_Physical_Asset__c, ol);
                    idToAllOrderLineItemMap.put(ol.Id, ol);
                }
        }
        }
        APTS_OrderLineItemUtils.updatePhAOnMovements(physicalAssetIdToOLIMap, null, idToAllOrderLineItemMap);
   
       
        
    }
     
    @isTest
    static void test_updatePhysicalAssetOnALIUpdate(){
    
        Map<Id, Apttus_Config2__AssetLineItem__c> oldAstMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
         
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
        List<Apttus_Config2__AssetLineItem__c> aliUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
    
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        Database.insert(aggr,false);
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        Database.insert(oPhysicalAsset, false);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AccountId__c = acc2.Id;
        ali.APTS_RefurbishedMachine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'New';
        ali.Apttus_Config2__StartDate__c = system.today();
        ali.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali.APTS_RefurbishedMachine__c = true;
        ali.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        aliInsertList.add(ali);
        
        Apttus_Config2__AssetLineItem__c ali2 = APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali2.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali2.Apttus_Config2__AccountId__c = acc2.Id;
        ali2.APTS_RefurbishedMachine__c = true;
        ali2.Apttus_Config2__AssetStatus__c = 'New';
        ali2.Apttus_Config2__StartDate__c = system.today();
        ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
        ali2.APTS_RefurbishedMachine__c = true;
        ali2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        aliInsertList.add(ali2);        
        Database.insert(aliInsertList, false);        
        ali2.APTS_Is_Primary_L1_Asset__c = ali.Id;
        ali2.Apttus_Config2__AssetStatus__c= 'New';
        Database.update(new list<Apttus_Config2__AssetLineItem__c>{ali2}, false);
        oldAstMap.put(ali2.Id, ali2);
        oldAstMap.put(ali.Id, ali);
                
        Apttus_Config2__AssetLineItem__c newALI1 = new Apttus_Config2__AssetLineItem__c();
        newALI1.Id = ali.Id;
        newALI1.APTS_Type_Of_Contract__c = 'Sales';
        newALI1.Apttus_Config2__AssetStatus__c = 'Pending Activation';
        newALI1.Apttus_Config2__StartDate__c = System.today();
        newALI1.APTS_Type_Of_Contract__c = 'Sales';
        newALI1.Apttus_Config2__LineType__c = 'Product/Service';
        newALI1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        Apttus_Config2__AssetLineItem__c newALI2 = new Apttus_Config2__AssetLineItem__c();
        newALI2.Id = ali2.Id;
        newALI2.APTS_Type_Of_Contract__c = 'Sales';
        newALI2.Apttus_Config2__LineType__c = 'Product/Service';
        newALI2.APTS_Is_Primary_L1_Asset__c = newALI1.Id;       
        newALI2.Apttus_Config2__AssetStatus__c = 'Pending Activation';
        newALI2.Apttus_Config2__IsPrimaryLine__c = true;
        newALI2.Apttus_Config2__StartDate__c = System.today();

        Database.update(new List<Apttus_Config2__AssetLineItem__c>{newALI1,newALI2});
        Test.startTest();       
        APTS_OrderLineItemUtils.updatePhysicalAssetOnALIUpdate(new List<Apttus_Config2__AssetLineItem__c>{newALI1,newALI2}, oldAstMap);
        APTS_OrderLineItemUtils.updatePhysicalAssetOnALIUpdate(new List<Apttus_Config2__AssetLineItem__c>{newALI1,newALI2}, oldAstMap);
        
        Test.stopTest();
    }
    
     @isTest
    static void test_ContractChange() {
          
        User oTestUser = APTS_TestFacade.getTestUser();
     
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.APTS_Contract_Change__c = 'No';
        update oOrder;
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        
        List<Apttus_Config2__OrderLineItem__c> oLIList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        
        Apttus_Config2__OrderProductAttributeValue__c attribute = new Apttus_Config2__OrderProductAttributeValue__c(
        Apttus_Config2__LineItemId__c = oLIList[0].Id,
        APTS_Type_of_contract__c = 'Sales',
        APTS_Call_Out_Coverage_Percent__c = 100.0,
        APTS_Labour_Coverage_Percent__c = 100.0,
        APTS_Spare_Parts_Coverage_Percent__c = 100.0,
        APTS_Number_of_hours_per_month__c = 10.0,
        APTS_First_Line_Response_Time__c = 2.0,
        APTS_Response_Profile__c = 'Response time 2 hours'
        );
        insert attribute;
        
        Test.startTest();
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Material_Type__c = 'ZCMA';
            orderLineItemList[0].Apttus_Config2__HasOptions__c  = true;
            orderLineItemList[0].Apttus_Config2__LineType__c = 'OPTION';
            Database.update(orderLineItemList);
                
            oPhysicalAsset.AssetStatus__c = 'Activated';
            oPhysicalAsset.SerialNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Vendor_Code__c = 'BBN';
            oPhysicalAsset.UniqueNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            Database.update(orderLineItemList);
           
            orderLineItemList[0].APTS_Option_Group_Text__c = 'Text';
            orderLineItemList[0].Apttus_Config2__AttributeValueId__c = attribute.Id;
            Database.update(orderLineItemList);
            
            Set<Id> oliIdSet = new Set<Id>{orderLineItemList[0].Id};
            Map<Id, Apttus_Config2__OrderLineItem__c> oLIMap = APTS_OrderLineItemUtils.getOrderLineItemAdditionalData(oliIdSet);
            
            Apttus_Config2__OrderLineItem__c oLI = oLIMap.get(orderLineItemList[0].Id);
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'Comfort Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Co Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Semi Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'ALL-IN COVERAGE';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Service Window';
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Extended Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);

            oLI.Apttus_Config2__Description__c = 'Extended Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
        Test.stopTest();
    }
    
     @isTest
    static void test_ContractChange_Yes() {
          
        User oTestUser = APTS_TestFacade.getTestUser();
     
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.APTS_Contract_Change__c = 'Yes';
        update oOrder;
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        
        List<Apttus_Config2__OrderLineItem__c> oLIList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        
        Apttus_Config2__OrderProductAttributeValue__c attribute = new Apttus_Config2__OrderProductAttributeValue__c(
        Apttus_Config2__LineItemId__c = oLIList[0].Id,
        APTS_Type_of_contract__c = 'Sales',
        APTS_Call_Out_Coverage_Percent__c = 100.0,
        APTS_Labour_Coverage_Percent__c = 100.0,
        APTS_Spare_Parts_Coverage_Percent__c = 100.0,
        APTS_Number_of_hours_per_month__c = 10.0,
        APTS_First_Line_Response_Time__c = 2.0,
        APTS_Response_Profile__c = 'Response time 2 hours'
        );
        insert attribute;
        
        Test.startTest();
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Material_Type__c = 'ZCMA';
            orderLineItemList[0].Apttus_Config2__HasOptions__c  = true;
            orderLineItemList[0].Apttus_Config2__LineType__c = 'OPTION';
            Database.update(orderLineItemList);
                
            oPhysicalAsset.AssetStatus__c = 'Activated';
            oPhysicalAsset.SerialNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            orderLineItemList[0].Apttus_Config2__ProductId__r.APTS_Vendor_Code__c = 'BBN';
            oPhysicalAsset.UniqueNumber__c = OrderLineItemList[0].APTS_Serial_Number__c;
            Database.update(orderLineItemList);
           
            orderLineItemList[0].APTS_Option_Group_Text__c = 'Text';
            orderLineItemList[0].Apttus_Config2__AttributeValueId__c = attribute.Id;
            Database.update(orderLineItemList);
            
            Set<Id> oliIdSet = new Set<Id>{orderLineItemList[0].Id};
            Map<Id, Apttus_Config2__OrderLineItem__c> oLIMap = APTS_OrderLineItemUtils.getOrderLineItemAdditionalData(oliIdSet);
            
            Apttus_Config2__OrderLineItem__c oLI = oLIMap.get(orderLineItemList[0].Id);
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'Comfort Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Co Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Full Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Semi Operating';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Machine Care';
            oLI.Apttus_Config2__Description__c = 'ALL-IN COVERAGE';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.APTS_Option_Group_Text__c = 'Service Window';
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Extended Weekdays';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
            oLI.Apttus_Config2__Description__c = 'Standard Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);

            oLI.Apttus_Config2__Description__c = 'Extended Weekdays & Weekend';
            APTS_OrderLineItemUtils.createPhysicalAsset(oLI);
            
        Test.stopTest();
    }
    
    
}