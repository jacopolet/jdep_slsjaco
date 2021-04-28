/*************************************************************
@Name: APTS_OrderLineItemTriggerHandlerTest
@Author: Galin Georgiev
@CreateDate: 14-03-2018
@Description: Order Line Item Trigger Handler Test 
@UsedBy: APTS_OrderLineItemTriggerHandler
*****************************************************************/
//v100 14-03-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private class APTS_OrderLineItemTriggerHandlerTest {

    private static final String DRAFT = System.Label.APTS_Draft;
    private static final String PENDING = System.Label.APTS_Pending;
    private static final String FULFILLED = System.Label.APTS_Fulfilled;
    private static final String PASS= System.Label.APTS_Pass;
    private static final String FAIL= System.Label.APTS_Fail;
    private static final String DEBIT_MEMO = System.Label.APTS_DebitMemo;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String STANDARD_DEAL = System.Label.APTS_Standard_Deal;
    private static final String XD01 = System.Label.APTS_XD01;

    @testSetup static void setupTestData() {

        APTS_TestFacade.createTestUser();
        User oTestUser = APTS_TestFacade.getTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_OrderUtils.stopOrderLineItemTrigger();         
        test.startTest();       
        APTS_TestFacade.createMachineAmendOrder(oTestUser);
        test.stopTest();
        APTS_OrderUtils.startOrderLineItemTrigger();
        System.assert(oTestUser != null);
    }
    
    @isTest static void test_BeforeInsert() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        System.assert(oTestUser != null);

        Test.startTest();
        APTS_OrderUtils.stopOrderTrigger();
        System.runAs(oTestUser) {

            APTS_TestFacade.createSimpleOrderWithAgreement(oTestUser, oAgreement.Id);
            Apttus_Config2__OrderLineItem__c oTrailOrderLineItem = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__OrderId__c = oOrder.Id, APTS_Type_of_contract__c = 'Trial');
            Database.insert(oTrailOrderLineItem); 
        }
         APTS_OrderUtils.startOrderTrigger();
        Test.stopTest();
    }      
       
        @isTest static void test_BeforeInsert1() {
        Test.startTest();
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Agreement');
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.APTS_Order_Sub_Type__c =  System.Label.APTS_Commercial_Swap;  
        oOrder.APTS_SAP_OrderType__c = 'XA13';    
        update oOrder;
        
        System.assert(oTestUser != null);
        System.runAs(oTestUser) {

            APTS_TestFacade.createSimpleOrderWithAgreement(oTestUser, oAgreement.Id);

            Apttus_Config2__OrderLineItem__c oTrailOrderLineItem = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__OrderId__c = oOrder.Id, APTS_Type_of_contract__c = 'Trial');
            oTrailOrderLineItem.APTS_Serial_Number2__c = 'ValidationCallbacknotfound' ;
            Database.insert(oTrailOrderLineItem);          
            
        }
        Test.stopTest();
    }
    @isTest static void test_OrderLineItemTriggerHandler() {

        
        Test.startTest();
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        Apttus_Config2__Order__c oStandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        oStandardOrder.APTS_Order_Sub_Type__c = 'Standard Return';
        Database.Update(oStandardOrder,false);            
        List<Apttus_Config2__OrderLineItem__c> standardOrderLineItemList = APTS_TestFacade.getOrderLineItemList(oStandardOrder.Id);

        Apttus_Config2__Order__c oMachineOrder = APTS_TestFacade.getOrder('MachineOrder');
        List<Apttus_Config2__OrderLineItem__c> machineOrderLineItemList = APTS_TestFacade.getOrderLineItemList(oMachineOrder.Id);

        System.runAs(oTestUser) {

            APTS_OrderLineItemTriggerHandler oOrderLineItemTriggerHandler = new APTS_OrderLineItemTriggerHandler();
            oOrderLineItemTriggerHandler.isDisabled();

            Apttus_Config2__OrderLineItem__c oOrderLineItem = orderLineItemList.get(0);
            Apttus_Config2__OrderLineItem__c oStandardOrderLineItem = standardOrderLineItemList.get(0);
            Apttus_Config2__OrderLineItem__c oMachineOrderLineItem = machineOrderLineItemList.get(0);

            oOrderLineItem.Apttus_Config2__Status__c = DRAFT;
            oOrderLineItem.APTS_Serial_Number__c = null;
            Database.update(oOrderLineItem,false);

            oOrderLineItem.Apttus_Config2__Status__c = PENDING;
            Database.update(oOrderLineItem,false);
            
            oOrderLineItem.APTS_ATP_Cleared__c = true;
            Database.update(oOrderLineItem,false);
                
            oOrderLineItem.Apttus_Config2__ActivatedDate__c = Date.today();
            oOrderLineItem.Apttus_Config2__Status__c = 'Activated';
            oOrderLineItem.APTS_Status__c = 'Activated';            
            oOrderLineItem.APTS_Expected_Delivery_Quantity__c = 1;
            Database.update(oOrderLineItem,false);

            System.assertEquals(1, oOrderLineItem.APTS_Expected_Delivery_Quantity__c);
            
            oMachineOrderLineItem.APTS_Expected_Delivery_Quantity__c = 1;
            Database.update(oMachineOrderLineItem,false);
            
            oMachineOrderLineItem.Apttus_Config2__IsPrimaryLine__c = true;
            oMachineOrderLineItem.Apttus_Config2__HasOptions__c = true;
            //oMachineOrderLineItem.APTS_Is_Primary_L1_Line__c = true;
            oMachineOrderLineItem.APTS_Installation_Date_Authorized__c = Date.today();
            oMachineOrderLineItem.APTS_De_installation_Date_Authorized__c = Date.today();
            Database.update(oMachineOrderLineItem,false);
            
            oStandardOrderLineItem.APTS_Requested_Delivery_Date__c=  Date.today();
            oStandardOrderLineItem.APTS_Expected_Delivery_Date__c= Date.today();
            oStandardOrderLineItem.Apttus_Config2__DeltaQuantity__c = -1;
            Database.update(oStandardOrderLineItem,false);       
        }

        Test.stopTest();
    }   

    @isTest static void test_AssetLineItemData() {
        Test.startTest();
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        Apttus_Config2__Order__c oStandardOrder = APTS_TestFacade.getOrder('StandardOrder');
        List<Apttus_Config2__OrderLineItem__c> standardOrderLineItemList = APTS_TestFacade.getOrderLineItemList(oStandardOrder.Id);
        List<Apttus_Config2__AssetLineItem__c> assetLineItemList = APTS_TestFacade.getAssetLineItem();

        System.runAs(oTestUser) {
            oOrder.Apttus_Config2__Status__c = 'Draft';
            oOrder.APTS_ATP_Check_Status__c = FAIL;
            oOrder.APTS_Status__c = PENDING;
            Database.update(oOrder);

            oOrder.APTS_ATP_Check_Status__c = PASS;
            oOrder.APTS_Status__c = PENDING;
            Database.update(oOrder);
            
            oOrder.APTS_Order_Type__c = DEBIT_MEMO;
            oOrder.APTS_SAP_OrderType__c = XD01;
            oOrder.Apttus_Config2__Status__c = DRAFT;
            oOrder.APTS_Remove_Billing_Block_Indicator__c = true;
            oOrder.APTS_Billing_Date__c = system.today();
            Database.update(oOrder);
                
            APTS_OrderLineItemTriggerHandler oOrderLineItemTriggerHandler = new APTS_OrderLineItemTriggerHandler();
            oOrderLineItemTriggerHandler.isDisabled();

            Apttus_Config2__OrderLineItem__c oOrderLineItem = orderLineItemList.get(0);
            Apttus_Config2__OrderLineItem__c oStandardOrderLineItem = standardOrderLineItemList.get(0);
            Apttus_Config2__AssetLineItem__c oAssetLineItem = assetLineItemList.get(0);

            oStandardOrderLineItem.APTS_Expected_Delivery_Quantity__c = 1;
            Database.update(oStandardOrderLineItem,false);
            
            Database.update(oOrderLineItem,false);
            
            oAssetLineItem = new Apttus_Config2__AssetLineItem__c();
            oAssetLineItem.Id = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
            oAssetLineItem.Apttus_Config2__LocationId__c = oOrderLineItem.Apttus_Config2__LocationId__c;
            oAssetLineItem.Apttus_CMConfig__AgreementId__c = oOrderLineItem.Apttus_CMConfig__AgreementId__c;
            oAssetLineItem.Apttus_CMConfig__AgreementLineItemId__c = oOrderLineItem.Apttus_CMConfig__AgreementLineItemId__c;
            oAssetLineItem.APTS_Physical_Asset__c = oOrderLineItem.APTS_Physical_Asset__c;
            oAssetLineItem.APTS_Installation_Sales_Order_Item__c = oOrderLineItem.APTS_SAP_Order_Line_Item_Number__c; 
            //oAssetLineItem.APTS_Installation_Sales_Order_Id__c = idToOrderLineItemMap.get(oOrderLineItem.Id).Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c;
            Database.update(oAssetLineItem);
            
            oAssetLineItem.Id = oOrderLineItem.Apttus_Config2__AssetLineItemId__c;
            oAssetLineItem.Apttus_Config2__EndDate__c = oOrderLineItem.Apttus_Config2__EndDate__c;
            oAssetLineItem.Apttus_Config2__SellingTerm__c = oOrderLineItem.Apttus_Config2__SellingTerm__c;

            Database.update(oAssetLineItem); 
        }
        Test.stopTest();
    }
     @isTest static void test_OrderLineItemTriggerHandler_AdminOrder() {

        Test.startTest();
        User oTestUser = APTS_TestFacade.getTestUser();
        
         // create account
        Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
        oAccount.SAP_Customer_ID__c = '12345';
        Database.insert(oAccount, FALSE);
        
         //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('JDETestAccount','JDETestAccount', 'MA', 'Bundle', FALSE, TRUE);
        prod1.APTS_SAPExtID__c = 'sapprod1';
        prod1.APTS_Plug_and_Play_Indicator__c = true;
        Database.insert(prod1, FALSE);
        
         // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        oContact.MobilePhone = '986789876668';
        Database.insert(oContact, FALSE);
        
        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
        Database.insert(oPricelist, FALSE);
        
        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Subtype__c  = 'Fixed End Date';
        oAgr.Apttus__Term_Months__c = 12;
        oAgr.Apttus__Contract_End_Date__c = System.today().addMonths(111);
        Database.insert(oAgr, FALSE);

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Contract_Change__c='No';
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.APTS_SAP_OrderType__c = 'XD09';
        order.APTS_Order_Header_SAP_ID__c ='0000001834';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert order;
   
        // Below line will be billed as Original Order Lines
        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                APTS_SAP_OrderType__c = 'XD09',APTS_Installation_Contact__c = oContact.id);
        insert orderLineItem1;
        
        // Admin Order Lines Starts
        Apttus_Config2__OrderLineItem__c orderLineItem11 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c = orderLineItem1.Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c='000030',
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                APTS_SAP_OrderType__c = 'XD09',APTS_Installation_Contact__c = oContact.id);
         insert orderLineItem11;
        Test.stopTest();
    }
     @isTest static void test_ContractChange() {

        Test.startTest();
        User oTestUser = APTS_TestFacade.getTestUser();
        
         // create account
        Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
        oAccount.SAP_Customer_ID__c = '12345';
        Database.insert(oAccount, FALSE);
        
         //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('JDETestAccount','JDETestAccount', 'MA', 'Bundle', FALSE, TRUE);
        prod1.APTS_SAPExtID__c = 'sapprod1';
        prod1.APTS_Plug_and_Play_Indicator__c = true;
        Database.insert(prod1, FALSE);
        
         // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        oContact.MobilePhone = '986789876668';
        Database.insert(oContact, FALSE);
        
        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
        Database.insert(oPricelist, FALSE);
        
        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Subtype__c  = 'Fixed End Date';
        oAgr.Apttus__Term_Months__c = 12;
        oAgr.Apttus__Contract_End_Date__c = System.today().addMonths(111);
        Database.insert(oAgr, FALSE);

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Contract_Change__c='Yes';
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.APTS_SAP_OrderType__c = 'XA13';
        order.APTS_Order_Header_SAP_ID__c ='0000001834';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert order;
   
        // Below line will be billed as Original Order Lines
        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                APTS_SAP_OrderType__c = 'XA13',APTS_Installation_Contact__c = oContact.id);
        insert orderLineItem1;
        
        // Admin Order Lines Starts
        Apttus_Config2__OrderLineItem__c orderLineItem11 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c = orderLineItem1.Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c='000030',
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                APTS_SAP_OrderType__c = 'XA13',APTS_Installation_Contact__c = oContact.id);
         insert orderLineItem11;
        Test.stopTest();
 }
    @isTest static void test_Delete() {

        User oTestUser = APTS_TestFacade.getTestUser();
        System.assert(oTestUser != null);

        Test.startTest();

        APTS_OrderLineItemTriggerHandler oOrderLineItemTriggerHandler = new APTS_OrderLineItemTriggerHandler();
        oOrderLineItemTriggerHandler.afterDelete(null, null);
        oOrderLineItemTriggerHandler.afterUndelete(null, null);
        oOrderLineItemTriggerHandler.beforeDelete(null, null);
        Test.stopTest();
    }

 @isTest static void Test_runATPCheck() {

        //User oTestUser = APTS_TestDataFactory.createUser();
        Test.startTest();
        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');
        oAcc.SAP_Customer_ID__c = '9876543234';
        insert oAcc;

        Apttus_Config2__AccountLocation__c oAccLoc = new Apttus_Config2__AccountLocation__c();
        oAccLoc.Apttus_Config2__AccountId__c = oAcc.id;
        oAccLoc.SAP_Customer_ID__c = '9876543234';
        insert oAccLoc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '87688945678');
        oCon.MobilePhone = null;
        oCon.Email = 'test@xyzSalesforce.org';
        
        oCon.Phone = '45678987654';
        insert oCon;
        
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Contract_Change__c='No';
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Installation';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        insert oOrder;

        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);
        
         List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
        machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        machineAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(optionAgreementPODetails);
        Database.Insert(poList);
        

        // Create Order Line Item for the Order
        
        List<Apttus_Config2__OrderLineItem__c> listOLI = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> mapOLI = new Map<Id,Apttus_Config2__OrderLineItem__c>();

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI.Apttus_Config2__Status__c = 'Draft';
        oOLI.APTS_Status__c= 'Draft';
        oOLI.APTS_Serial_Number__c = '123456789';
        oOLI.Apttus_Config2__LineNumber__c= 1;  
        oOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI.Apttus_Config2__PriceType__c='One Time';
        oOLI.Apttus_Config2__LocationId__c = oAccLoc.id;
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.APTS_Installation_Contact__c = oCon.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__SellingFrequency__c = 'Hourly';
        oOLI.APTS_Item_Relevant_for_SAP__c = true;
        oOLI.APTS_Option_Group_Text__c = 'Machine';
        oOLI.APTS_Item_Category__c = 'A04';
        listOLI.add(oOLI);
        Database.insert(listOLI,false);
        
        oOrder.Apttus_Config2__Status__c = 'pending';
        oOrder.APTS_Status__c  = 'pending';
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        oOrder.APTS_Requested_Movement_Date__c= Date.newInstance(2018, 07, 30);
        update oOrder;
     
     Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
            prdAttValue.APTS_Type_of_Consumption__c = 'Both';
            prdAttValue.APTS_Number_of_months__c = '9';
            prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
            prdAttValue.APTS_Refurbished__c = 'Yes';
            Database.insert(prdAttValue, false);
     
     
    
        
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        
        oOLI.APTS_Requested_Installation_Date__c = System.today().addDays(5);
        oOLI.APTS_Expected_Delivery_Date__c = System.today().addDays(5);
        oOLI.APTS_Status__c = 'Pending';
        oOLI.Apttus_Config2__Status__c = 'Pending';
        oOLI.APTS_Material_Availability_Date__c = System.today().addDays(2);
        oOLI.APTS_SAP_Order_Line_Item_Number__c = '1';
        oOLI.APTS_ATP_Cleared__c = true;
        oOLI.APTS_Installation_Required__c = true;
        oOLI.APTS_Installation_Date_Authorized__c =  oOLI.APTS_Requested_Installation_Date__c;
        oLIUpdateList.add(oOLI);
     Apttus_Config2__OrderLineItem__c oOLI2 = new Apttus_Config2__OrderLineItem__c();
        oOLI2.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI2.Apttus_Config2__Status__c = 'Draft';
        oOLI2.APTS_Status__c= 'Draft';
        oOLI2.APTS_Serial_Number__c = '123456789';
        oOLI2.Apttus_Config2__LineNumber__c= 1;  
        oOLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI2.Apttus_Config2__PriceType__c='One Time';
        oOLI2.Apttus_Config2__LocationId__c = oAccLoc.id;
        oLIUpdateList.add(oOLI2);
        Database.update(oLIUpdateList, false);
        
        system.debug('---------oLIUpdateList'+oLIUpdateList[0]);
        
        mapOLI.put(listOLI[0].id,listOLI[0]);

        APTS_OrderLineItemTriggerHandler.updateAsset(listOLI,mapOLI);
        APTS_OrderLineItemTriggerHandler oOLIcall = new APTS_OrderLineItemTriggerHandler();
        oOLIcall.recalculateSellingTerm(listOLI[0]);   
        oOLIcall.checkIfDeliveryOnlyForOptions (oOlI,oOli,null); 
        oOlI.APTS_SAP_OrderType__c = 'XA13';
     oOlI.APTS_Option_Group_Text__c = 'Technical Services';
     oOlI.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
     oOlI.APTS_Type_of_contract__c = 'Sales';
                 
     oOLIcall.checkIfWarrantyExists(oOlI);
     oOlI.Apttus_Config2__PreviousVersion__c = oOLI2.Id;
     oOlI.Apttus_Config2__Status__c = 'Pending Cancellation';
     oOlI.Apttus_Config2__ActivatedDate__c = system.today();
     oOlI.Apttus_Config2__ReadyForBillingDate__c = system.today();
     oOLI.Apttus_Config2__OriginalLineNumber__c = '099890';
     Database.Update(oOlI, false); 
     
     Test.stopTest();
 }
 @isTest static void Test_autoRenewals() {

        //User oTestUser = APTS_TestDataFactory.createUser();
        
        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');
        oAcc.SAP_Customer_ID__c = '9876543234';
        insert oAcc;

        Apttus_Config2__AccountLocation__c oAccLoc = new Apttus_Config2__AccountLocation__c();
        oAccLoc.Apttus_Config2__AccountId__c = oAcc.id;
        oAccLoc.SAP_Customer_ID__c = '9876543234';
        insert oAccLoc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '87688945678');
        oCon.MobilePhone = null;
        oCon.Email = 'test@xyzSalesforce.org';
        
        oCon.Phone = '45678987654';
        insert oCon;
        
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;
        
        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);
        
         List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
        machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        machineAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(optionAgreementPODetails);
        Database.Insert(poList);
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_Contract_Change__c='No';
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Type__c = 'Admin Order';
        oOrder.APTS_Order_Sub_Type__c = 'Renewal';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        Test.startTest();
        insert oOrder;

        // Create Order Line Item for the Order
        
        List<Apttus_Config2__OrderLineItem__c> listOLI = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> mapOLI = new Map<Id,Apttus_Config2__OrderLineItem__c>();

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI.Apttus_Config2__Status__c = 'Draft';
        oOLI.APTS_Status__c= 'Draft';
        oOLI.APTS_Serial_Number__c = '123456789';
        oOLI.Apttus_Config2__LineNumber__c= 1;  
        oOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI.Apttus_Config2__PriceType__c='One Time';
        oOLI.Apttus_Config2__LocationId__c = oAccLoc.id;
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.APTS_Installation_Contact__c = oCon.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__SellingFrequency__c = 'Hourly';
        oOLI.APTS_Item_Relevant_for_SAP__c = true;
        oOLI.APTS_Option_Group_Text__c = 'Machine';
        oOLI.APTS_Item_Category__c = 'A04';
        listOLI.add(oOLI);
        Database.insert(listOLI,false);
        
        
        APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c = System.NOW(); 
        autoRenewalStaging.APTS_Comments__c = null;
        autoRenewalStaging.APTS_Associated_order__c = oOrder.id;
        insert autoRenewalStaging;
        
        oOrder.Apttus_Config2__Status__c = 'pending';
        oOrder.APTS_Status__c  = 'pending';
        oOrder.APTS_Auto_renewal_staging_source_id__c=autoRenewalStaging.id;
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        oOrder.APTS_Requested_Movement_Date__c= Date.newInstance(2018, 07, 30);
        update oOrder;
     
        Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
        prdAttValue.APTS_Type_of_Consumption__c = 'Both';
        prdAttValue.APTS_Number_of_months__c = '9';
        prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
        prdAttValue.APTS_Refurbished__c = 'Yes';
        Database.insert(prdAttValue, false);
     
     
    
        
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        
        oOLI.APTS_Requested_Installation_Date__c = System.today().addDays(5);
        oOLI.APTS_Expected_Delivery_Date__c = System.today().addDays(5);
        oOLI.APTS_Status__c = 'Pending';
        oOLI.Apttus_Config2__Status__c = 'Pending';
        oOLI.APTS_Material_Availability_Date__c = System.today().addDays(2);
        oOLI.APTS_SAP_Order_Line_Item_Number__c = '1';
        oOLI.APTS_ATP_Cleared__c = true;
        oOLI.APTS_Installation_Required__c = true;
        oOLI.APTS_Installation_Date_Authorized__c =  oOLI.APTS_Requested_Installation_Date__c;
        oLIUpdateList.add(oOLI);
     Apttus_Config2__OrderLineItem__c oOLI2 = new Apttus_Config2__OrderLineItem__c();
        oOLI2.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI2.Apttus_Config2__Status__c = 'Draft';
        oOLI2.APTS_Status__c= 'Draft';
        oOLI2.APTS_Serial_Number__c = '123456789';
        oOLI2.Apttus_Config2__LineNumber__c= 1;  
        oOLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI2.Apttus_Config2__PriceType__c='One Time';
        oOLI2.Apttus_Config2__LocationId__c = oAccLoc.id;
        oLIUpdateList.add(oOLI2);
        Database.update(oLIUpdateList, false);
        
        system.debug('---------oLIUpdateList'+oLIUpdateList[0]);
        
        mapOLI.put(listOLI[0].id,listOLI[0]);

        APTS_OrderLineItemTriggerHandler.updateAsset(listOLI,mapOLI);
        APTS_OrderLineItemTriggerHandler oOLIcall = new APTS_OrderLineItemTriggerHandler();
        oOLIcall.recalculateSellingTerm(listOLI[0]);   
        oOLIcall.checkIfDeliveryOnlyForOptions (oOlI,oOli,null); 
        oOlI.APTS_SAP_OrderType__c = 'XA13';
     oOlI.APTS_Option_Group_Text__c = 'Technical Services';
     oOlI.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
     oOlI.APTS_Type_of_contract__c = 'Sales';
                 
     oOLIcall.checkIfWarrantyExists(oOlI);
     oOlI.Apttus_Config2__PreviousVersion__c = oOLI2.Id;
     oOlI.Apttus_Config2__Status__c = 'Pending Cancellation';
     oOlI.Apttus_Config2__ActivatedDate__c = system.today();
     oOlI.Apttus_Config2__ReadyForBillingDate__c = system.today();
     oOLI.Apttus_Config2__OriginalLineNumber__c = '099890';
     Database.Update(oOlI, false); 
     
     Test.stopTest();
 }
 
  @isTest static void Test_indexation() {

        //User oTestUser = APTS_TestDataFactory.createUser();
        Test.startTest();
        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');
        oAcc.SAP_Customer_ID__c = '9876543234';
        insert oAcc;

        Apttus_Config2__AccountLocation__c oAccLoc = new Apttus_Config2__AccountLocation__c();
        oAccLoc.Apttus_Config2__AccountId__c = oAcc.id;
        oAccLoc.SAP_Customer_ID__c = '9876543234';
        insert oAccLoc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '87688945678');
        oCon.MobilePhone = null;
        oCon.Email = 'test@xyzSalesforce.org';
        
        oCon.Phone = '45678987654';
        insert oCon;
        
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_Contract_Change__c='No';
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Type__c = 'Machine Order';
        oOrder.APTS_Order_Sub_Type__c = 'Installation';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        insert oOrder;

        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        prod1.APTS_Vendor_Code__c='WIR';
        prod1.APTS_Material_Type__c = 'ZCMA';
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);
        
         List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
        machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        machineAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(optionAgreementPODetails);
        Database.Insert(poList);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(oAcc.Id, prod1.Id, oPricelist.Id, pli1.Id , null , oOrder.Id);
        insert ali;

        // Create Order Line Item for the Order
        
        List<Apttus_Config2__OrderLineItem__c> listOLI = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> mapOLI = new Map<Id,Apttus_Config2__OrderLineItem__c>();

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI.Apttus_Config2__Status__c = 'Draft';
        oOLI.APTS_Status__c= 'Draft';
        oOLI.APTS_Serial_Number__c = '123456789';
        oOLI.Apttus_Config2__LineNumber__c= 1;  
        oOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI.Apttus_Config2__PriceType__c='One Time';
        oOLI.Apttus_Config2__LocationId__c = oAccLoc.id;
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.APTS_Installation_Contact__c = oCon.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__SellingFrequency__c = 'Hourly';
        oOLI.APTS_Item_Relevant_for_SAP__c = true;
        oOLI.APTS_Option_Group_Text__c = 'Machine';
        oOLI.APTS_Item_Category__c = 'A04';
        oOLI.Apttus_Config2__AssetLineItemId__c=ali.id;
        oOLI.Apttus_Config2__ProductId__c = prod1.Id;
        oOLI.Apttus_Config2__HasOptions__c = true;
        listOLI.add(oOLI);
        Database.insert(listOLI,false);
        
        
        APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c = System.NOW(); 
        autoRenewalStaging.APTS_Comments__c = null;
        autoRenewalStaging.APTS_Associated_order__c = oOrder.id;
        insert autoRenewalStaging;
        
        oOrder.Apttus_Config2__Status__c = 'pending';
        oOrder.APTS_Status__c  = 'pending';
        oOrder.APTS_Auto_renewal_staging_source_id__c=autoRenewalStaging.id;
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        oOrder.APTS_Requested_Movement_Date__c= Date.newInstance(2018, 07, 30);
        update oOrder;
     
        Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
        prdAttValue.APTS_Type_of_Consumption__c = 'Both';
        prdAttValue.APTS_Number_of_months__c = '9';
        prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
        prdAttValue.APTS_Refurbished__c = 'Yes';
        Database.insert(prdAttValue, false);       
        
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        
        oOLI.APTS_Requested_Installation_Date__c = System.today().addDays(5);
        oOLI.APTS_Expected_Delivery_Date__c = System.today().addDays(5);
        oOLI.APTS_Status__c = 'Pending';
        oOLI.Apttus_Config2__Status__c = 'Pending';
        oOLI.APTS_Material_Availability_Date__c = System.today().addDays(2);
        oOLI.APTS_SAP_Order_Line_Item_Number__c = '1';
        oOLI.APTS_ATP_Cleared__c = true;
        oOLI.APTS_Installation_Required__c = true;
        oOLI.APTS_Installation_Date_Authorized__c =  oOLI.APTS_Requested_Installation_Date__c;
        oLIUpdateList.add(oOLI);
        
        Apttus_Config2__OrderLineItem__c oOLI2 = new Apttus_Config2__OrderLineItem__c();
        oOLI2.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI2.Apttus_Config2__Status__c = 'Draft';
        oOLI2.APTS_Status__c= 'Draft';
        oOLI2.APTS_Serial_Number__c = '123456789';
        oOLI2.Apttus_Config2__LineNumber__c= 1;  
        oOLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI2.Apttus_Config2__PriceType__c='One Time';
        oOLI2.Apttus_Config2__LocationId__c = oAccLoc.id;
        oLIUpdateList.add(oOLI2);
        Database.update(oLIUpdateList, false);
        
        system.debug('---------oLIUpdateList'+oLIUpdateList[0]);
        
        mapOLI.put(listOLI[0].id,listOLI[0]);

    Set<id> oset = new set<Id>();
    
      oSet.add(oOlI.Id);
        APTS_OrderLineItemTriggerHandler.updateAsset(listOLI,mapOLI);
        APTS_OrderLineItemTriggerHandler oOLIcall = new APTS_OrderLineItemTriggerHandler();
        oOLIcall.recalculateSellingTerm(listOLI[0]);   
        oOLIcall.checkIfDeliveryOnlyForOptions (oOlI,oOli,null); 
      oOLICall.setMovementBillingDate(oSet, mapOLI, mapOLI);
        oOlI.APTS_SAP_OrderType__c = 'XA13';
     oOlI.APTS_Option_Group_Text__c = 'Technical Services';
     oOlI.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
     oOlI.APTS_Type_of_contract__c = 'Sales';
                 
     oOLIcall.checkIfWarrantyExists(oOlI);
     oOlI.Apttus_Config2__PreviousVersion__c = oOLI2.Id;
     oOlI.Apttus_Config2__Status__c = 'Pending Cancellation';
     oOlI.Apttus_Config2__ActivatedDate__c = system.today();
     oOlI.Apttus_Config2__ReadyForBillingDate__c = system.today();
     oOLI.Apttus_Config2__OriginalLineNumber__c = '099890';
     Database.Update(oOlI, false); 
     
     Test.stopTest();
 }
 
 @isTest static void Test_indexation1() {

        //User oTestUser = APTS_TestDataFactory.createUser();
        Test.startTest();
        Account oAcc = APTS_TestDataFactory.createAccount('Account_Spain');
        oAcc.SAP_Customer_ID__c = '9876543234';
        insert oAcc;

        Apttus_Config2__AccountLocation__c oAccLoc = new Apttus_Config2__AccountLocation__c();
        oAccLoc.Apttus_Config2__AccountId__c = oAcc.id;
        oAccLoc.SAP_Customer_ID__c = '9876543234';
        insert oAccLoc;

        Contact oCon = APTS_TestDataFactory.createContact(oAcc , '87688945678');
        oCon.MobilePhone = null;
        oCon.Email = 'test@xyzSalesforce.org';
        
        oCon.Phone = '45678987654';
        insert oCon;
        
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('myPriceList');
        insert oPriceList;

        Apttus__APTS_Agreement__c oAgree = APTS_TestDataFactory.createAgreement(oCon.id, oPricelist.id, oAcc.id, 'Consumption Model');
        oAgree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAgree;
        
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(oAcc.id, oPricelist.Id, oCon.Id);
        oOrder.Apttus_CMConfig__AgreementId__c = oAgree.id;
        oOrder.Apttus_Config2__SoldToAccountId__c = oAcc.id;
        oOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oOrder.Apttus_Config2__ShipToAccountId__c = oAcc.id;
        oOrder.APTS_Payer__c = oAcc.id;
        oOrder.APTS_Contract_Change__c='No';
        oOrder.APTS_SAP_OrderType__c = 'XA13';
        oOrder.APTS_Order_Type__c = 'Admin Order';
        oOrder.APTS_Order_Sub_Type__c = 'Indexation';
        oOrder.Apttus_Config2__Status__c = 'Draft';
        oOrder.APTS_Status__c  = 'Draft';
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        insert oOrder;

        Product2 prod1 = APTS_TestDataFactory.createProduct(oAcc.Name, oAcc.Name, null, null, FALSE, FALSE);
        prod1.APTS_Vendor_Code__c='WIR';
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id = :oAgree.Id LIMIT 1];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgree.Id, oAcc.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);
        
         List<APTS_Agreement_PO_Details__c> poList = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c machineAgreementPODetails = new APTS_Agreement_PO_Details__c();
        machineAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        machineAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        machineAgreementPODetails.APTS_PO_Number__c = '123567';
        machineAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(machineAgreementPODetails);
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = oAgr1.Id;
        poList.add(optionAgreementPODetails);
        Database.Insert(poList);
        
        Apttus_Config2__AssetLineItem__c ali = APTS_TestUtils.createAssetLineItem(oAcc.Id, prod1.Id, oPricelist.Id, pli1.Id , null , oOrder.Id);
        insert ali;

        // Create Order Line Item for the Order
        
        List<Apttus_Config2__OrderLineItem__c> listOLI = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> mapOLI = new Map<Id,Apttus_Config2__OrderLineItem__c>();

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI.Apttus_Config2__Status__c = 'Draft';
        oOLI.APTS_Status__c= 'Draft';
        oOLI.APTS_Serial_Number__c = '123456789';
        oOLI.Apttus_Config2__LineNumber__c= 1;  
        oOLI.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI.Apttus_Config2__PriceType__c='One Time';
        oOLI.Apttus_Config2__LocationId__c = oAccLoc.id;
        oOLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.id;
        oOLI.APTS_Installation_Contact__c = oCon.id;
        oOLI.Apttus_Config2__OrderId__c = oOrder.id;
        oOLI.Apttus_Config2__SellingFrequency__c = 'Hourly';
        oOLI.APTS_Item_Relevant_for_SAP__c = true;
        oOLI.APTS_Option_Group_Text__c = 'Machine';
        oOLI.APTS_Item_Category__c = 'A04';
        oOLI.Apttus_Config2__AssetLineItemId__c=ali.id;
        oOLI.Apttus_Config2__ProductId__c = prod1.Id;
        oOLI.APTS_RefurbishedMachine__c = True;

        listOLI.add(oOLI);
        Database.insert(listOLI,false);
        
        
        APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c = System.NOW(); 
        autoRenewalStaging.APTS_Comments__c = null;
        autoRenewalStaging.APTS_Associated_order__c = oOrder.id;
        insert autoRenewalStaging;
        
        oOrder.Apttus_Config2__Status__c = 'pending';
        oOrder.APTS_Status__c  = 'pending';
        oOrder.APTS_Auto_renewal_staging_source_id__c=autoRenewalStaging.id;
        oOrder.APTS_Requested_Installation_Date__c= Date.newInstance(2018, 07, 30);
        oOrder.APTS_Requested_Movement_Date__c= Date.newInstance(2018, 07, 30);
        update oOrder;
     
        Apttus_Config2__ProductAttributeValue__c prdAttValue = new Apttus_Config2__ProductAttributeValue__c();
        prdAttValue.APTS_Type_of_Consumption__c = 'Both';
        prdAttValue.APTS_Number_of_months__c = '9';
        prdAttValue.APTS_WTS_Changed_By__c = 'Customer';
        prdAttValue.APTS_Refurbished__c = 'Yes';
        Database.insert(prdAttValue, false);
     
     
        
        
        List<Apttus_Config2__OrderLineItem__c> oLIUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        
        oOLI.APTS_Requested_Installation_Date__c = System.today().addDays(5);
        oOLI.APTS_Expected_Delivery_Date__c = System.today().addDays(5);
        oOLI.APTS_Status__c = 'Pending';
        oOLI.Apttus_Config2__Status__c = 'Pending';
        oOLI.APTS_Material_Availability_Date__c = System.today().addDays(2);
        oOLI.APTS_SAP_Order_Line_Item_Number__c = '1';
        oOLI.APTS_ATP_Cleared__c = true;
        oOLI.APTS_Installation_Required__c = true;
        oOLI.APTS_Installation_Date_Authorized__c =  oOLI.APTS_Requested_Installation_Date__c;
        oLIUpdateList.add(oOLI);
        
        Apttus_Config2__OrderLineItem__c oOLI2 = new Apttus_Config2__OrderLineItem__c();
        oOLI2.Apttus_Config2__LineType__c = 'Product/Service';
        oOLI2.Apttus_Config2__Status__c = 'Draft';
        oOLI2.APTS_Status__c= 'Draft';
        oOLI2.APTS_Serial_Number__c = '123456789';
        oOLI2.Apttus_Config2__LineNumber__c= 1;  
        oOLI2.Apttus_Config2__ChargeType__c = 'Sales Price';
        oOLI2.Apttus_Config2__PriceType__c='One Time';
        oOLI2.Apttus_Config2__LocationId__c = oAccLoc.id;
        oLIUpdateList.add(oOLI2);
        Database.update(oLIUpdateList, false);        
        
        mapOLI.put(listOLI[0].id,listOLI[0]);

        APTS_OrderLineItemTriggerHandler.updateAsset(listOLI,mapOLI);
        APTS_OrderLineItemTriggerHandler oOLIcall = new APTS_OrderLineItemTriggerHandler();
        oOLIcall.recalculateSellingTerm(listOLI[0]);   
        oOLIcall.checkIfDeliveryOnlyForOptions (oOlI,oOli,null); 
        oOlI.APTS_SAP_OrderType__c = 'XA13';
     oOlI.APTS_Option_Group_Text__c = 'Technical Services';
     oOlI.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
     oOlI.APTS_Type_of_contract__c = 'Sales';
                 
     oOLIcall.checkIfWarrantyExists(oOlI);
     oOlI.Apttus_Config2__PreviousVersion__c = oOLI2.Id;
     oOlI.Apttus_Config2__Status__c = 'Cancelled';
     oOlI.Apttus_Config2__ActivatedDate__c = system.today();
     oOlI.Apttus_Config2__ReadyForBillingDate__c = system.today();
     oOLI.Apttus_Config2__OriginalLineNumber__c = '099890';
     Database.Update(oOlI, false); 
     
     Test.stopTest();
 }
}