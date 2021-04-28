/*************************************************************
@Name: APTS_CLMUtilTest
@Author: Pranjal Mittal
@CreateDate: 12-05-2018
@Description: Test class for APTS_CLMUtil class
@UsedBy: APTS_CLMUtil
******************************************************************/
@isTest
private class APTS_CLMUtilTest {
    

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(otestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        List<TriggerSettings__c> triggerSetting = [select id from TriggerSettings__c];
        Delete triggerSetting;
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
        
        Apttus_Config2__AssetLineItem__c assetLineItemrent = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        assetLineItemrent.Apttus_Config2__ChargeType__c = 'Rental Fee';
        assetLineItemrent.Apttus_Config2__HasOptions__c = true;
        assetLineItemrent.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItemrent.APTS_Is_Primary_L1_Asset__c =null;
        Database.insert(assetLineItemrent, false);
        
        Apttus_Config2__AssetLineItem__c assetLineItemrentservhead = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        assetLineItemrentservhead.Apttus_Config2__ChargeType__c = 'Service Fee';
        assetLineItemrentservhead.Apttus_Config2__HasOptions__c = true;
        assetLineItemrentservhead.Apttus_Config2__BundleAssetId__c = assetLineItemrent.Id;
        assetLineItemrentservhead.APTS_Is_Primary_L1_Asset__c = assetLineItemrent.Id;
        assetLineItemrentservhead.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItemrentservhead.Apttus_Config2__ChargeType__c = 'Service Fee';
        Database.insert(assetLineItemrentservhead, false);
        
        Apttus_Config2__AssetLineItem__c optionassetLineItemrent = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        optionassetLineItemrent.Apttus_Config2__BundleAssetId__c = assetLineItemrent.Id;
        optionassetLineItemrent.APTS_Is_Primary_L1_Asset__c = assetLineItemrent.Id;
        optionassetLineItemrent.Apttus_Config2__ChargeType__c = 'Rental Fee';
        optionassetLineItemrent.Apttus_Config2__LineType__c = 'Option';
        optionassetLineItemrent.APTS_MigrationDate__c = System.Today();
        Database.insert(optionassetLineItemrent, false);
        
        Apttus_Config2__AssetLineItem__c optionassetLineItemrentserv = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        optionassetLineItemrentserv.Apttus_Config2__BundleAssetId__c = assetLineItemrent.Id;
        optionassetLineItemrentserv.APTS_Is_Primary_L1_Asset__c = assetLineItemrent.Id;
        optionassetLineItemrentserv.Apttus_Config2__ChargeType__c = 'Rental Fee';
        optionassetLineItemrentserv.Apttus_Config2__LineType__c = 'Option';
        optionassetLineItemrentserv.APTS_MigrationDate__c = System.Today();
        Database.insert(optionassetLineItemrentserv, false);

        Apttus_Config2__AssetLineItem__c optionassetLineItem = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        optionassetLineItem.Apttus_Config2__BundleAssetId__c = assetLineItem.Id;
        optionassetLineItem.APTS_Is_Primary_L1_Asset__c = assetLineItem.Id;
        optionassetLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        optionassetLineItem.Apttus_Config2__LineType__c = 'Option';
        optionassetLineItem.APTS_MigrationDate__c = System.Today();
        Database.insert(optionassetLineItem, false);
        
        Apttus_Config2__AssetLineItem__c optionassetLineItem3 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        optionassetLineItem3.Apttus_Config2__BundleAssetId__c = assetLineItem.Id;
        optionassetLineItem3.APTS_Is_Primary_L1_Asset__c = assetLineItem.Id;
        optionassetLineItem3.Apttus_Config2__ChargeType__c = 'Service Fee';
        optionassetLineItem3.Apttus_Config2__LineType__c = 'Option';
        optionassetLineItem3.APTS_MigrationDate__c = System.Today();
        Database.insert(optionassetLineItem3, false);

        Apttus_Config2__AssetLineItem__c serviceassetLineItem = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        serviceassetLineItem.Apttus_Config2__ChargeType__c = 'Service Fee';
        serviceassetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        serviceassetLineItem.Apttus_Config2__BundleAssetId__c = null;
        serviceassetLineItem.APTS_Is_Primary_L1_Asset__c = null;
        serviceassetLineItem.Apttus_Config2__HasOptions__c = true;
        Database.insert(serviceassetLineItem, false);
        
        Apttus_Config2__AssetLineItem__c optionassetLineItem1 = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        optionassetLineItem1.Apttus_Config2__BundleAssetId__c = serviceassetLineItem.Id;
        optionassetLineItem1.APTS_Is_Primary_L1_Asset__c = serviceassetLineItem.Id;
        optionassetLineItem1.Apttus_Config2__ChargeType__c = 'Service Fee';
        optionassetLineItem1.Apttus_Config2__LineType__c = 'Product/Service';
        optionassetLineItem1.Apttus_Config2__SellingFrequency__c = 'Monthly';
        optionassetLineItem1.APTS_MigrationDate__c = System.Today();
        Database.insert(optionassetLineItem1, false);

        /*Apttus_Config2__AssetTransactionHistory__c tstHistory = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory.Apttus_Config2__Action__c = 'New';
        tstHistory.Apttus_Config2__AssetLineItemId__c = assetLineItem.Id;
        insert tstHistory;
        
                Apttus_Config2__AssetTransactionHistory__c tstHistory11 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory11.Apttus_Config2__Action__c = 'New';
        tstHistory11.Apttus_Config2__AssetLineItemId__c = optionassetLineItem1.Id;
        insert tstHistory11;
        
                Apttus_Config2__AssetTransactionHistory__c tstHistory1 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory1.Apttus_Config2__Action__c = 'New';
        tstHistory1.Apttus_Config2__AssetLineItemId__c = optionassetLineItemrent.Id;
        insert tstHistory1;
        
                Apttus_Config2__AssetTransactionHistory__c tstHistory2 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory2.Apttus_Config2__Action__c = 'New';
        tstHistory2.Apttus_Config2__AssetLineItemId__c = optionassetLineItemrentserv.Id;
        insert tstHistory2;
        
                Apttus_Config2__AssetTransactionHistory__c tstHistory3 = new Apttus_Config2__AssetTransactionHistory__c();
        tstHistory3.Apttus_Config2__Action__c = 'New';
        tstHistory3.Apttus_Config2__AssetLineItemId__c = assetLineItemrentservhead.Id;
        insert tstHistory3;
        Map<Id, String> mapHistory = new Map<Id, String>();
        mapHistory.put(assetLineItem.id,'New');*/
        
        List<Apttus_Config2__AssetLineItem__c> aliList=new List<Apttus_Config2__AssetLineItem__c>();
        aliList.add(assetLineItem);
        aliList.add(assetLineItemrent);
        aliList.add(optionassetLineItem);
        aliList.add(optionassetLineItemrent);
        aliList.add(optionassetLineItemrentserv);
        aliList.add(assetLineItemrentservhead);
        aliList.add(optionassetLineItem1);
        aliList.add(serviceassetLineItem);
        
        Map<Id,Apttus_Config2__AssetLineItem__c> oldAliMap= new Map<Id,Apttus_Config2__AssetLineItem__c>();
        oldAliMap.put(serviceassetLineItem.id,serviceassetLineItem);
        
        agreement.Apttus__Status__c = Label.Apttus.Activated;
        agreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        Database.Update(agreement,false);

        APTS_CLMUtil.calculateBaseExtendedPrice(aliList);
        
        

        List<Apttus_Config2__AssetLineItem__c> allParentAssets = APTS_CLMUtil.calculateAssetBaseExtendedPrice(aliList,oldAliMap);

        APTS_CLMUtil.calculateBaseExtendedPrice(optionassetLineItem);     
        update optionassetLineItem;

        APTS_CLMUtil.calculateBaseExtendedPrice(assetLineItem);           
        update assetLineItem;
       
       
        Apttus_Config2__OrderLineItem__c orderLineItem = APTS_TestUtils.createOrderLineItem(product.Id, order.Id, assetLineItem.Id, billingPreference.Id, priceList.Id, priceListItem.Id);
        orderLineItem.Apttus_Config2__Status__c = 'Activated';
        insert orderLineItem;
        
        assetLineItem.Apttus_Config2__BusinessLineItemId__c = orderLineItem.id;
        Update assetLineItem;
        
        Apttus_Config2__OrderAdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__OrderAdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1.0;
        adjustmentLineItem.Apttus_Config2__IsModifiable__c = true;
        adjustmentLineItem.Apttus_Config2__LineItemId__c = orderLineItem.Id;
        Database.insert(adjustmentLineItem, false);
        
        Set<Id> oLIIdSet = new Set<Id>{orderLineItem.Id};
        Map<Id, Apttus_Config2__OrderLineItem__c>  oLIMap = APTS_CLMUtil.OrderLineItemData(oLIIdSet);
        test.startTest();
        System.debug('******oLIIdSet=====>'+oLIIdSet);
        //APTS_CLMUtil.populateURL(new List<Apttus__APTS_Agreement__c>(), new Map<Id, Apttus__APTS_Agreement__c>(), new List<Apttus__APTS_Agreement__c>(), new Map<Id, Apttus__APTS_Agreement__c>());
        APTS_CLMUtil.manageAssetAdjLineItemData(oLIIdSet);
        
        Id cartId = APTS_OrderUtils.createCart(order.Id);
        try{
            APTS_CLMUtil.finalizeCart(cartId);
        }catch(Exception ex){}
        try{
            APTS_CLMUtil.updatePricing(cartId);
        }catch(Exception ex){}
        
        try{
            APTS_CLMUtil.syncCart(cartId);
        }catch(Exception ex){}
        try{
            Apttus_Config2.CPQStruct.AcceptOrderResponseDO response = APTS_CLMUtil.acceptorder(order.Id);
        }catch(Exception ex){}
        test.stopTest();
    }
    
    
    @isTest
    static void testUtility(){
        
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);

        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        oAgreement.APTS_Is_Admin_Order_Needed__c = true;
        oAgreement.Apttus__Status__c = Label.Apttus.Activated;
        oAgreement.Apttus__Status_Category__c = Label.APTS_In_Effect;
        update oAgreement;

        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        Database.insert(product, false);
        
        Apttus_Config2__ProductConfiguration__c ProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(ProductConfiguration);

         
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        oOrder.Apttus_CMConfig__AgreementId__c = oAgreement.id;
        oOrder.APTS_Requested_Installation_Date__c=null;
        update oOrder;

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        Id cartId = APTS_OrderUtils.createCart(oOrder.Id);
        

        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.id);
        Apttus__AgreementLineItem__c agmtLiItem = agreementLineItemList[0];

        Id optionRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();
        
        PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
        testphAsset.Name = 'Test Option Physical Asset';
        testphAsset.RecordTypeId = optionRecId;
        testphAsset.SerialNumber__c = 'RJ213456234';
        testphAsset.PONumberServices__c = '123567';
        testphAsset.PONumberRequiredServices__c = 'Yes';
        testphAsset.PONumberTypeServices__c = 'Variable';
        insert testphAsset;

        Apttus_Config2__AssetLineItem__c assetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem1.Name = 'Test Machine Asset Line Item';
        assetLineItem1.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        assetLineItem1.APTS_Physical_Asset__c = testphAsset.Id;
        insert assetLineItem1;

        Apttus__AgreementLineItem__c agmntlineitem1 = new Apttus__AgreementLineItem__c();
        agmntlineitem1.Apttus__AgreementId__c = oAgreement.id;
        agmntlineitem1.Apttus_CMConfig__AssetLineItemId__c = assetLineItem1.id;
        agmntlineitem1.Apttus_CMConfig__IsPrimaryLine__c = true;
        //agmntlineitem1.APTS_Serial_Number__c = 'RJ213456234';
        agmntlineitem1.APTS_Asset_Change_type__c = 'Non-Physical movement';
        agmntlineitem1.Apttus__ProductId__c = product.id;
        Database.insert(agmntlineitem1,false);

        Account oAccount=APTS_TestFacade.getAccount();
        Apttus__APTS_Agreement__c oAgreementNew = APTS_TestFacade.getAgreement('Agreement');
        oAgreementNew.Apttus__Status_Category__c = 'In Effect'; 
        oAgreementNew.Apttus__Status__c = 'Activated';
        update oAgreementNew;

        Apttus__APTS_Agreement__c machineTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'Test Agreement',RecordTypeId = recordtype,Apttus__Agreement_Number__c = '00016186',
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Effect', Apttus__Status__c = 'Activated',APTS_Is_Admin_Order_Needed__c = true);
        Database.insert(machineTestAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.id;
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineitem  = new Apttus_Config2__LineItem__c();
        lineitem.APTS_Serial_Number2__c = '9983829';
        lineitem.Apttus_Config2__LineType__c =  'Product/Service';
        lineitem.Apttus_Config2__ProductId__c = product.ID;
        lineitem.Apttus_Config2__ConfigurationId__c = oProductConfiguration.ID;
        lineitem.Apttus_Config2__ItemSequence__c=123;
        lineitem.Apttus_Config2__LineNumber__c=234;
        lineitem.Apttus_Config2__IsPrimaryLine__c = true; 
        insert lineitem;

        Apttus_Config2__AssetLineItem__c aLI = new Apttus_Config2__AssetLineItem__c();
        aLI.Name = 'Test Machine Asset Line Item';
        aLI.Apttus_CMConfig__AgreementId__c = machineTestAgreement.Id;
        aLI.APTS_Physical_Asset__c = testphAsset.Id;
        aLI.Apttus_Config2__IsPrimaryLine__c = true;
        aLI.Apttus_Config2__LineType__c = 'Product/Service';
        aLI.APTS_Type_Of_Contract__c = 'Sales';
        Database.insert (aLI,false);
        
        aLI.APTS_OrgnlBillingDate__c = Date.newInstance(2022, 12, 9);
        update aLI;
        
        Apttus_Config2__AssetLineItem__c aLI3 = new Apttus_Config2__AssetLineItem__c();
        aLI3.Name = 'Test Machine Asset Line Item';
        aLI3.Apttus_CMConfig__AgreementId__c = machineTestAgreement.Id;
        aLI3.Apttus_Config2__BundleAssetId__c = aLI.ID;
        aLI3.APTS_Physical_Asset__c = testphAsset.Id;
        aLI3.Apttus_Config2__IsPrimaryLine__c = true;
        aLI3.Apttus_Config2__LineType__c = 'Product/Service';
        aLI3.APTS_Type_Of_Contract__c = 'Sales';
        //aLI3.APTS_Serial_Number__c = 'Test114919123';
        Database.insert (aLI3,false);
        
        aLI3.APTS_OrgnlBillingDate__c = Date.newInstance(2022, 12, 9);
        update aLI3;

        Apttus_Config2__AssetLineItem__c aLI2= new Apttus_Config2__AssetLineItem__c();
        aLI2.Name = 'Test Machine Asset Line Item';
        aLI2.Apttus_CMConfig__AgreementId__c = machineTestAgreement.Id;
        aLI2.APTS_Physical_Asset__c = testphAsset.Id;
        aLI2.Apttus_Config2__IsPrimaryLine__c = true;
        aLI2.Apttus_Config2__LineType__c = 'Option';
        aLI2.APTS_Type_Of_Contract__c = 'Sales';
        aLI2.Apttus_Config2__BundleAssetId__c = aLI.id;
        Database.insert(aLI2,false);
        
        aLI2.APTS_OrgnlBillingDate__c = Date.newInstance(2022, 12, 9);
        update aLI3;
        
        Apttus__AgreementLineItem__c aLi1 = new Apttus__AgreementLineItem__c();
        aLi1.Apttus__AgreementId__c = machineTestAgreement.id;
        aLi1.Apttus_CMConfig__AssetLineItemId__c = aLI2.id;
        aLi1.Apttus_CMConfig__IsPrimaryLine__c = true;
        //aLi1.APTS_Serial_Number__c = 'RJ213456234';
        aLi1.APTS_Asset_Change_type__c = 'Non-Physical movement';
        aLi1.Apttus__ProductId__c = product.id;
        Database.insert(aLi1,false);

        List<Apttus_Config2__AssetLineItem__c> aLIList = new List<Apttus_Config2__AssetLineItem__c>();
        aLIList.add(new Apttus_Config2__AssetLineItem__c(Apttus_CMConfig__AgreementId__c=oAgreement.Id, APTS_relatedlist_agreement__c=oAgreementNew.Id));

        List<ID>aLIIDs = new List<ID>();
        aLIIDs.add(aLIList[0].id);
        
        Apttus_Billing__BillingSchedule__c billingSchedule = new Apttus_Billing__BillingSchedule__c();
        billingSchedule.Apttus_Billing__AssetLineItemId__c = aLI3.Id;
        insert billingSchedule;
        

        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
        billingPreference.name='Test Preference';
        billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
        billingPreference.APTS_Invoice_Type__c ='Single Invoice';
        billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        Database.Insert(billingPreference);        

        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        Database.insert(priceListItem, false);

        test.startTest();
        Apttus_Config2__OrderLineItem__c oLI = APTS_TestUtils.createOrderLineItem(product.Id, oOrder.Id, assetLineItem1.Id, billingPreference.Id, priceList.Id, priceListItem.Id);
        oLI.Apttus_Config2__LineType__c = 'Product/Service';
        oLI.APTS_Item_Relevant_for_SAP__c = false;
        oLI.Apttus_Config2__ActivatedDate__c = System.Today();
        oLI.Apttus_Config2__ReadyForBillingDate__c = System.Today();
        //oLI.APTS_Is_Primary_L1_Parent__c = userinfo.getuserid();
        oLI.APTS_Serial_Number__c = 'Test123114919';
        //oLI.APTS_Is_Primary_L1_Line__c  = True;
        Database.insert(oLI);

        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        agreementList.add(oAgreementNew);
        agreementList.add(machineTestAgreement);
        agreementList.add(oAgreement);        
        
        Map<Id, Apttus__APTS_Agreement__c> activatedAgreementMap= new Map<Id, Apttus__APTS_Agreement__c> ();
        activatedAgreementMap.put(agreementList[1].id,agreementList[1]);
        
        APTS_CLMUtil.mapAgreementFieldInALI(aLIList);
        APTS_CLMUtil.populateAgreementInALI(agreementList);
        //APTS_CLMUtil.amendPhysicalAssetUpdate(activatedAgreementMap);
        //APTS_CLMUtil.addBundleProductToCart(agreementLineItemList[0],cartId);   
        //APTS_CLMUtil.submitadminorder(oOrder.id);
        APTS_CLMUtil.processAdminOrder(oAgreement,oOrder);
        APTS_CLMUtil.createAdminOrder(oAgreement,oAccount,'Standard Order');
        APTS_CLMUtil.createAdminOrder(oAgreement,oAccount);
        APTS_CLMUtil.agreementAdminChanges(machineTestAgreement,oAccount);
        APTS_CLMUtil.activateOrder(cartId,aLIIDs,oOrder.id);
        APTS_CLMUtil.adminOrderPAUpdate(oOrder.id);
        APTS_CLMUtil.adminOrderCreationForAgg(oAgreement,oAccount,aLIIDs);
        //APTS_CLMUtil.activateOrder(cartId,oOrder.id,true);
        //APTS_CLMUtil.updateReadyForBillingDateOnAsset(machineTestAgreement);
        //APTS_CLMUtil.updateReadyForBillingDateOnOrderLineItems(orderLineItemList);
        test.stopTest(); 
       
    }
    
    @isTest
    static void testvalidatelock(){
        
        Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);

        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();

        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Id cartId = APTS_OrderUtils.createCart(oOrder.Id);
        Apttus__APTS_Agreement__c oAgreement = APTS_TestFacade.getAgreement('Cancelled Agreement');
        Database.insert(oAgreement, false);

        List<Apttus__AgreementLineItem__c> agreementLineItemList = APTS_TestFacade.getAgreementLineItem(oAgreement.id);
        Apttus__AgreementLineItem__c agmtLiItem = agreementLineItemList[0];
        Account oAccount=APTS_TestFacade.getAccount();
        Apttus__APTS_Agreement__c oAgreementNew = APTS_TestFacade.getAgreement('Agreement');
        Apttus__APTS_Agreement__c oTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'Test Agreement',RecordTypeId = recordtype,Apttus__Agreement_Number__c = '00016186',
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Fully Signed',Apttus_CMConfig__ConfigurationFinalizedDate__c = System.today()-1);
        
        Database.Insert(oTestAgreement);
        
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Fully Signed');
        Database.Insert(testAgreement);
        
        List<Apttus_Config2__AssetLineItem__c> aLIList = new List<Apttus_Config2__AssetLineItem__c>();
        aLIList.add(new Apttus_Config2__AssetLineItem__c(Apttus_CMConfig__AgreementId__c=oAgreement.Id, APTS_relatedlist_agreement__c=oAgreementNew.Id));
        
        List<Apttus_Config2__AssetLineItem__c> aLIList1 = new List<Apttus_Config2__AssetLineItem__c>();
        aLIList.add(new Apttus_Config2__AssetLineItem__c(Apttus_CMConfig__AgreementId__c=testAgreement.Id, APTS_relatedlist_agreement__c=oAgreementNew.Id));

        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        agreementList.add(oTestAgreement);
        //Database.insert(agreementList);*/
               
        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        insert product;
        
        Apttus_Config2__ProductConfiguration__c ProductConfiguration = APTS_TestDataFactory.createProductConfig(testAgreement);
        Database.insert(ProductConfiguration);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oTestAgreement);
        insert oProductConfiguration;

        Apttus_Config2__LineItem__c lineitem  = new Apttus_Config2__LineItem__c();
        lineitem.APTS_Serial_Number2__c = '1234556';
        lineitem.Apttus_Config2__LineType__c =  'Product/Service';
        lineitem.Apttus_Config2__ProductId__c = product.ID;
        lineitem.Apttus_Config2__ConfigurationId__c = oProductConfiguration.ID;
        lineitem.Apttus_Config2__ItemSequence__c=123;
        lineitem.Apttus_Config2__LineNumber__c=234;
        insert lineitem;
        
        Apttus_Config2__LineItem__c lineitem1  = new Apttus_Config2__LineItem__c();
        lineitem1.APTS_Serial_Number2__c = '1234556';
        lineitem1.Apttus_Config2__LineType__c =  'Product/Service';
        lineitem1.Apttus_Config2__ProductId__c = product.ID;
        lineitem1.Apttus_Config2__ConfigurationId__c = ProductConfiguration.ID;
        lineitem1.Apttus_Config2__ItemSequence__c=123;
        lineitem1.Apttus_Config2__LineNumber__c=234;
        insert lineitem1;
        
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
        billingPreference.name='Test Preference';
        billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
        billingPreference.APTS_Invoice_Type__c ='Single Invoice';
        billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        Database.Insert(billingPreference);
        
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        Database.Insert(paymentMethod);
        
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        paymentTerm.Apttus_Config2__Sequence__c = 5;
        paymentTerm.APTS_Ext_ID__c ='SAP_0211';
        Database.Insert(paymentTerm);

        APTS_Agreement_PO_Details__c optionAgreementPODetails = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails.APTS_PO_Number__c = '123567';
        optionAgreementPODetails.APTS_Agreement__c = oTestAgreement.Id;
        insert optionAgreementPODetails;
        
        APTS_Agreement_PO_Details__c optionAgreementPODetails1 = new APTS_Agreement_PO_Details__c();
        optionAgreementPODetails1.APTS_PO_Number_Required__c = 'Yes';
        optionAgreementPODetails1.APTS_PO_Number_Type__c = 'Variable';
        optionAgreementPODetails1.APTS_PO_Number__c = '123567';
        optionAgreementPODetails1.APTS_Agreement__c = testAgreement.Id;
        insert optionAgreementPODetails1;

        Id optionRecId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Option').getRecordTypeId();
        

        PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
        testphAsset.Name = 'Test Option Physical Asset';
        testphAsset.RecordTypeId = optionRecId;
        testphAsset.PONumberServices__c = '123567';
        testphAsset.PONumberRequiredServices__c = 'Yes';
        testphAsset.PONumberTypeServices__c = 'Variable';
        insert testphAsset;

        Apttus_Config2__AssetLineItem__c machineAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        machineAssetLineItem.Name = 'Test Machine Asset Line Item';
        machineAssetLineItem.Apttus_CMConfig__AgreementId__c = oTestAgreement.Id;
        machineAssetLineItem.APTS_Physical_Asset__c = testphAsset.Id;
        insert machineAssetLineItem;
        
        Apttus_Config2__AssetLineItem__c machineAssetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        machineAssetLineItem1.Name = 'Test Machine Asset Line Item';
        machineAssetLineItem1.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
        machineAssetLineItem1.APTS_Physical_Asset__c = testphAsset.Id;
        insert machineAssetLineItem1;
        
        APTS_Billing_Settings__c billsetting = APTS_TestUtils.createBillingSetting(oTestAgreement.Id,oTestAgreement.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
        billsetting.APTS_Agreement_Billing_Type__c ='Machine';
        billsetting.APTS_Invoice_Delivery_Preference__c='P001';
        billsetting.APTS_Billing_Rule_Contract__c = 'Bill in Arrears';
        Database.Insert(billsetting);
            
        billsetting.APTS_Invoice_Delivery_Preference__c = 'P002';
        Database.Update(billsetting);
            
        Contracted_kpi_sla__c monthlyKPISLA = new Contracted_kpi_sla__c(kpi_contract__c = oTestAgreement.Id, KPI_type__c = 'Availability % per machine', kpi_frequency__c = 'Monthly');
        Database.Insert(monthlyKPISLA);
        
        monthlyKPISLA.kpi_frequency__c = 'Quarterly';
        Database.Update(monthlyKPISLA);
        
        APTS_Index_Contract__c oindexcon = new APTS_Index_Contract__c();
        oindexcon.APTS_Index_Type__c = 'Non-Standard Indexation';
        oindexcon.APTS_Indexation_Category__c = 'Technical Services';
        oindexcon.APTS_Contract__c = oTestAgreement.Id;
        oindexcon.APTS_Communication_Needed__c = true;
        oindexcon.APTS_Start_Date__c = Date.today();
        oindexcon.APTS_Communication_Deadline__c = '1';
        oindexcon.APTS_Frequency__c = 'Yearly';
        Database.Insert(oindexcon);
        
        oindexcon.APTS_Indexation_Category__c = 'Consumption Pricing';
        Database.Update(oindexcon);

        APTS_Agreement_Budget__c budget = new APTS_Agreement_Budget__c();
        budget.Agreement__c = oTestAgreement.id;
        Database.Insert(budget);

        budget.APTS_Start_Date__c = oTestAgreement.Apttus__Contract_Start_Date__c;
        Database.Update(budget);

        list<APTS_Agreement_Budget__c>budgetlist = new list<APTS_Agreement_Budget__c>();
        budgetlist.add(budget);

        list<APTS_Index_Contract__c>contractlist = new list<APTS_Index_Contract__c>();
        contractlist.add(oindexcon);

        list<Contracted_kpi_sla__c>kpilist = new list<Contracted_kpi_sla__c>();
        kpilist.add(monthlyKPISLA);

        list<APTS_Billing_Settings__c>billinglist = new list<APTS_Billing_Settings__c>();
        billinglist.add(billsetting);

        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreements = new  Map<Id, Apttus__APTS_Agreement__c>();
        mapOldAgreements.put(oTestAgreement.id,oTestAgreement);

        oTestAgreement.APTS_Lock_Agreement__c = true;
        oTestAgreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = System.today();
        oTestAgreement.Apttus__Status_Category__c = 'In Effect';
        oTestAgreement.Apttus__Status__c = 'Activated';
        Database.Update(oTestAgreement);

        Map<Id, Apttus__APTS_Agreement__c> mapAgreements = new Map<Id, Apttus__APTS_Agreement__c>();
        mapAgreements.put(oTestAgreement.id,oTestAgreement);
        
        list<Apttus__APTS_Agreement__c>aggrlist = new  list<Apttus__APTS_Agreement__c>();
        aggrlist.add(oTestAgreement);
        
        Map<Id, Apttus__APTS_Agreement__c> agreementsOldMap = new  Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agreementOldList = new List<Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> agreementsNewMap = new  Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> agreementNewList = new List<Apttus__APTS_Agreement__c>();
        testAgreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = (DateTime)system.today();
        agreementOldList.add(testAgreement);
        update agreementOldList;
        mapOldAgreements.put(testAgreement.Id,testAgreement);
        testAgreement.Apttus__Status_Category__c = 'In Effect';
        testAgreement.Apttus__Status__c = 'Activated';
        testAgreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = (DateTime)system.today();
        agreementList.add(testAgreement);
        try{
            update agreementList;
        }catch(Exception ex){}
        mapAgreements.put(testAgreement.Id,testAgreement);

        test.startTest();
        APTS_CLMUtil.amendPhysicalAssetUpdate(mapAgreements);
        APTS_CLMUtil.mapAgreementFieldInALI(aLIList);
        APTS_CLMUtil.validateLock(contractlist,'APTS_Index_Contract__c');
        APTS_CLMUtil.validateLock(kpilist,'Contracted_kpi_sla__c');
        APTS_CLMUtil.validateLock(billinglist,'APTS_Billing_Settings__c');
        APTS_CLMUtil.validateLock(budgetlist,'APTS_Agreement_Budget__c');
        APTS_CLMUtil.populateURL(agreementNewList,agreementsNewMap ,agreementOldList,agreementsOldMap);           
    }
    @isTest
    static void testCMRDMRPenaltyCalculation(){
        
        Account account = APTS_TestUtils.createaccount();
        insert account;
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.insert(priceList, false);
        
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
        Database.insert(billingPreference, false);
        
        Product2 product = APTS_TestUtils.createProduct('Test Product', '123', 'Machines');
        Database.insert(product, false);
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.Id, product.Id);
        Database.insert(priceListItem, false);
        
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        Date myDate = Date.today().addDays(15);
        Date weekStart = myDate.toStartofWeek().addDays(1);
        
        Apttus__APTS_Agreement__c testAgreement4 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', Apttus__Status__c = 'Fully Signed');
        Database.Insert(testAgreement4);
            
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('New', priceList.Id, account.Id, billingPreference.Id);
        order.APTS_Requested_Movement_Date__c = weekStart;
        order.APTS_Requested_Installation_Date__c=null;
        insert order;
        order.APTS_SAP_OrderType__c = 'XD01';
        order.Apttus_CMConfig__AgreementId__c = testAgreement4.id;
        if(order.ID != null ){
         update order;
         }
                
        Apttus_Config2__AssetLineItem__c assetLineItem = APTS_TestUtils.createAssetLineItem(account.Id, product.Id, priceList.Id, priceListItem.Id, billingPreference.Id, order.Id);
        assetLineItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem.Apttus_Config2__HasOptions__c = true;
        Database.insert(assetLineItem, false);
        
        
        test.startTest();
        Apttus_Config2__OrderLineItem__c orderLineItem1 = APTS_TestUtils.createOrderLineItem(product.Id, order.Id, assetLineItem.Id, billingPreference.Id, priceList.Id, priceListItem.Id);
        orderLineItem1.Apttus_Config2__OrderId__c = order.Id;
        orderLineItem1.Apttus_Config2__LineType__c = 'Option';
        orderLineItem1.APTS_Item_Relevant_for_SAP__c = true;
        Database.insert(orderLineItem1);
        
        
        Apttus_Config2__OrderLineItem__c orderLineItem = APTS_TestUtils.createOrderLineItem(product.Id, order.Id, assetLineItem.Id, billingPreference.Id, priceList.Id, priceListItem.Id);
        //Apttus_Config2__Order__c orderSO = [Select ID from Apttus_Config2__Order__c  LIMIT 1];
        orderLineItem.Apttus_Config2__OrderId__c = order.Id;
        orderLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        orderLineItem.APTS_Item_Relevant_for_SAP__c = true;
        Database.insert(orderLineItem);


        APTS_CLMUtil.CMRDMRPenaltyCalculation(order.Id);
        List<Apttus_Config2__OrderLineItem__c> oliList = new List<Apttus_Config2__OrderLineItem__c>();
        oliList.add(orderLineItem);
        APTS_CLMUtil.updateReadyForBillingDateOnOrderLineItems(oliList);
        APTS_CLMUtil.invokeCERRecordsBatch(null);
        test.stopTest();        
        }

    @isTest
    static void testNewMethods(){
        APTS_CLMUtil.updateAssetsOnAgreementActivation(null,null,null,null);
       // List<Apttus__APTS_Agreement__c> agrList = new List<Apttus__APTS_Agreement__c>();
        //APTS_CLMUtil.invokeCERRecordsBatch(agrList);
        
    }
}