/**
 * @description       : 
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 01-04-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   01-04-2021   Karan Khatri   Initial Version
**/
@isTest
private with sharing class APTS_AssetAutoRenewalPageCtrlTest{
    
    @testSetup static void testDataSetup(){
    
        Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClassesProperty.Name = 'Config Custom Classes';
        configCustomClassesProperty.Apttus_Config2__AdjustmentLineItemCallbackClass__c = 'APTS_AdjustmentLineItemCallback';
        insert configCustomClassesProperty;
        
        TriggerSettings__c triggerSettings = new TriggerSettings__c();
        triggerSettings.APTS_Order_Trigger__c=false;
        triggerSettings.APTS_OrderLineItemTrigger__c=false;
        triggerSettings.AdjustmentLineItemTrigger__c=false;
        insert triggerSettings;

        Account acc = APTS_TestUtils.createGrandParentAccount();
        Database.insert(acc,false);
        
        Contact cont = APTS_TestUtils.createContact();
        Database.insert(cont,false);
        
        Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Product2 bundleProd = APTS_TestDataFactory.createProduct('BundleProd','1122','Machine','Bundle',false,true);
        bundleProd.APTS_Sales_Catalog__c='0401'; 
        insert bundleProd;
        
        Product2 optionProd1 = APTS_TestDataFactory.createProduct('optionProd','1121','Machine','Option',false,false);
        insert optionProd1;
        
        Product2 optionProd2 = APTS_TestDataFactory.createProduct('optionProd2','1123','Machine','Option',false,false);
        insert optionProd2;
        
        Product2 optionProd3 = APTS_TestDataFactory.createProduct('optionProd3','11224','Machine','Option',false,false);
        insert optionProd3;
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(cont.Id,null,plist.Id,acc.Id);
        aggr.Apttus__Contract_End_Date__c = System.today()-1;
        aggr.Apttus__Account__c = acc.Id;
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Contract_Start_Date__c = System.today()-50;
        aggr.Apttus__Auto_Renewal__c = true;
        insert aggr;
        
        Apttus_Config2__AssetLineItem__c tstAsset = new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__LineNumber__c = 1;
        tstAsset.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Old_Net_Price__c = 100;
        //tstAsset.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.APTS_Is_Primary_L1_Line__c = true;
        tstAsset.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset.Apttus_CMConfig__AgreementId__c = aggr.Id;
        tstAsset.APTS_relatedlist_agreement__c = aggr.Id;
        tstAsset.Apttus_Config2__AccountId__c = acc.Id;
        tstAsset.APTS_Option_Group_Text__c = 'Technical Service';
        tstAsset.APTS_Is_Indexation_Executed__c = false;
        tstAsset.Apttus_Config2__EndDate__c = Date.today();
        tstAsset.Apttus_Config2__RenewalFrequency__c = 'Yearly';
        tstAsset.Apttus_Config2__PriceType__c = 'Recurring';
        tstAsset.Apttus_Config2__AutoRenew__c = true;
        tstAsset.Apttus_Config2__ProductId__c=bundleProd.id;
        tstAsset.Apttus_Config2__Quantity__c=1;
        tstAsset.Name='LaterForDeinstall';
        insert tstAsset;

        Apttus_Config2__AssetLineItem__c tstAsset1 = new Apttus_Config2__AssetLineItem__c();
        tstAsset1.Apttus_Config2__LineNumber__c = 1;
        tstAsset1.Apttus_Config2__PrimaryLineNumber__c = 1;
        tstAsset1.Apttus_Config2__NetPrice__c = 100;
        tstAsset1.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset1.APTS_Old_Net_Price__c = 100;
        //tstAsset1.APTS_Is_Primary_L1_Asset__r.name = asset.Name;
        tstAsset1.Apttus_Config2__HasOptions__c = true;
        tstAsset1.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset1.Apttus_Config2__ChargeType__c = 'Sales Price';
        tstAsset1.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset1.APTS_Is_Primary_L1_Line__c = true;
        tstAsset1.Apttus_Config2__IsPrimaryLine__c = true;
        tstAsset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        tstAsset1.APTS_relatedlist_agreement__c = aggr.Id;
        tstAsset1.Apttus_Config2__AccountId__c = acc.Id;
        tstAsset1.APTS_Option_Group_Text__c = 'Technical Service';
        tstAsset1.APTS_Is_Indexation_Executed__c = false;
        tstAsset1.Apttus_Config2__EndDate__c = Date.today();
        tstAsset1.Apttus_Config2__RenewalFrequency__c = 'Yearly';
        tstAsset1.Apttus_Config2__PriceType__c = 'Recurring';
        tstAsset1.Apttus_Config2__AutoRenew__c = true;
        tstAsset1.Apttus_Config2__ProductId__c=bundleProd.id;
        tstAsset1.Apttus_Config2__Quantity__c=1;
        insert tstAsset1;
        
        List<Apttus_Config2__AssetLineItem__c> assetlst = new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2_AssetAdjustItem__c> assetAdjlst = new List<Apttus_Config2_AssetAdjustItem__c>();
        Apttus_Config2__AssetLineItem__c asset = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset.Apttus_Config2__AssetStatus__c = 'Activated';
        asset.APTS_Old_Net_Price__c = 100;
        asset.Apttus_Config2__LineType__c = 'option';
        asset.Apttus_Config2__ChargeType__c = 'Sales Price';
        asset.APTS_Type_Of_Contract__c = 'Sales';
        asset.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset.APTS_relatedlist_agreement__c = aggr.Id;
        asset.Apttus_Config2__AccountId__c = acc.Id;
        asset.APTS_Option_Group_Text__c = 'Technical Service';
        asset.APTS_Is_Indexation_Executed__c = false;
        asset.Apttus_Config2__EndDate__c = Date.today();
        asset.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        asset.Apttus_Config2__RenewalFrequency__c = 'Yearly';
        asset.Apttus_Config2__PriceType__c = 'Recurring';
        asset.Apttus_Config2__AutoRenew__c = true;
        asset.Apttus_Config2__ProductId__c=bundleProd.id;
        asset.Apttus_Config2__Quantity__c=1;
        asset.Apttus_Config2__OptionId__c = optionProd1.id;
        
        assetlst.add(asset);   
        
        Apttus_Config2__AssetLineItem__c asset1 = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset1.Apttus_Config2__AssetStatus__c = 'Activated';
        asset1.APTS_Old_Net_Price__c = 100;
        asset1.Apttus_Config2__LineType__c = 'option';
        asset.Apttus_Config2__ChargeType__c = 'Service Fee';
        asset.APTS_Type_Of_Contract__c = 'Rent';
        asset1.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset1.APTS_relatedlist_agreement__c = aggr.Id;
        asset1.Apttus_Config2__AccountId__c = acc.Id;
        asset1.APTS_Option_Group_Text__c = 'Machine Care';
        asset1.APTS_Is_Indexation_Executed__c = false;
        asset1.Apttus_Config2__EndDate__c = Date.today();
        asset1.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset1.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        asset1.Apttus_Config2__RenewalFrequency__c = 'Yearly';
        asset1.Apttus_Config2__PriceType__c = 'Recurring';
        asset1.Apttus_Config2__AutoRenew__c = true;
        asset1.Apttus_Config2__ProductId__c=bundleProd.id;
        asset1.Apttus_Config2__Quantity__c=1; 
        asset.Apttus_Config2__OptionId__c = optionProd2.id;
        assetlst.add(asset1);
        
        Apttus_Config2__AssetLineItem__c asset2 = new Apttus_Config2__AssetLineItem__c();
        //asset.Name = 'Test Asset';
        asset2.Apttus_Config2__AssetStatus__c = 'Activated';
        asset2.APTS_Old_Net_Price__c = 100;
        asset2.Apttus_Config2__LineType__c = 'option';
        asset2.Apttus_Config2__ChargeType__c = 'Sales Price';
        asset2.APTS_Type_Of_Contract__c = 'Sales';
        asset2.Apttus_CMConfig__AgreementId__c = aggr.Id;
        asset2.APTS_relatedlist_agreement__c = aggr.Id;
        asset2.Apttus_Config2__AccountId__c = acc.Id;
        asset2.APTS_Option_Group_Text__c = 'Value Added Machine Care';
        asset2.APTS_Is_Indexation_Executed__c = false;
        asset2.Apttus_Config2__EndDate__c = Date.today().addDays(100);
        asset2.APTS_Is_Primary_L1_Asset__c = tstAsset.Id;
        asset2.Apttus_Config2__BundleAssetId__c = tstAsset.Id;
        asset2.Apttus_Config2__RenewalFrequency__c = 'Yearly';
        asset2.Apttus_Config2__PriceType__c = 'Recurring';
        asset2.Apttus_Config2__AutoRenew__c = true;
        asset2.Apttus_Config2__ProductId__c=bundleProd.id;
        asset2.Apttus_Config2__Quantity__c=1;
        asset2.Apttus_Config2__OptionId__c = optionProd3.id;   
        assetlst.add(asset2);
        Database.insert(assetlst,false);
        
        
        For(Apttus_Config2__AssetLineItem__c tempAsset : assetlst){
        
            Apttus_Config2_AssetAdjustItem__c astAdjustment2 = new Apttus_Config2_AssetAdjustItem__c();
            astAdjustment2.Apttus_Config2_AssetAdjustType__c = '% Markup';
            //astAdjustment.Apttus_Config2_SubType__c = 'Z099';
            astAdjustment2.Apttus_Config2_SubType__c = 'ZP02';
            astAdjustment2.Apttus_Config2_Type__c = 'Inflation';
            astAdjustment2.Apttus_Config2_Bucket__c = 'Bucket 2';
            astAdjustment2.Apttus_Config2_AssetLineItemId__c = tempAsset.Id;
            assetAdjlst.add(astAdjustment2);
        }
        Database.insert(assetAdjlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> AssetList = [SELECT id, Apttus_Config2__HasOptions__c, Apttus_Config2__LineType__c,APTS_Option_Group_Text__c, Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c,Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,Apttus_Config2__BundleAssetId__c
                                                            from Apttus_Config2__AssetLineItem__c 
                                                            where Apttus_Config2__AutoRenew__c = true 
                                                            and Apttus_Config2__EndDate__c <= TODAY 
                                                            and Apttus_Config2__AssetStatus__c ='Activated' 
                                                            and Apttus_Config2__RenewalFrequency__c = 'Yearly' 
                                                            and Apttus_Config2__PriceType__c = 'Recurring' 
                                                            and (Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c like '04%' or Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c = '0701')  
                                                            and Apttus_Config2__LineType__c = 'Option' 
                                                            and Apttus_Config2__BundleAssetId__r.Apttus_Config2__IsPrimaryLine__c=true];
        System.debug('****AssetList==========>'+AssetList);

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence('testPref1');
        insert billPref;
        Apttus_Config2__PriceListItem__c pli = APTS_TestDataFactory.createPriceListItem(plist.Id, optionProd1.Id);
        insert pli;

        List<Account> accList = [select id from Account limit 1];
        List<Apttus_Config2__PriceList__c> priceList  = [select id from Apttus_Config2__PriceList__c limit 1];
        List<Contact> primaryContact =  [select id from Contact limit 1];

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
        order.APTS_Order_Sub_Type__c ='De-Installation';
        order.APTS_Requested_Installation_Date__c = NULL;
        insert order;

        Apttus_Config2__OrderLineItem__c orderline = APTS_TestDataFactory.createOrderLineItem(order, pli.Id, null, optionProd1.Id, null,null, null, 1, 1, 1, 'Product/Service', billPref.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        //orderline.Apttus_Config2__AssetLineItemId__c = tstAsset.Id;
        orderline.Apttus_Config2__OrderId__c=order.Id;
        orderline.APTS_Status__c ='Draft';
        orderline.Apttus_Config2__Description__c='LaterForDeinstall';
        insert orderline;
        
    }
    private static testMethod void test_logicDeInstall() {
        test.startTest(); 
        List<Apttus_Config2__AssetLineItem__c> listOfAssetLine = [select id from Apttus_Config2__AssetLineItem__c where name='LaterForDeinstall'];

        List<Apttus_Config2__OrderLineItem__c> orderlineItem = [select id,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Apttus_Config2__Description__c='LaterForDeinstall'];

        orderlineItem[0].Apttus_Config2__AssetLineItemId__c=listOfAssetLine[0].id;
        update orderlineItem[0];


        Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),200);
        test.stopTest();
    }
    private static testMethod void test_logic1() {
        test.startTest();
        APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
        batchJobCtrl.initiateAutoRenewalBatch();
        batchJobCtrl.batchComponentLabel='ABC';
        batchJobCtrl.getBatchJobs();
        test.stopTest();
   }
   
   private static testMethod void test_logic1_1() {
        test.startTest();
        User otestuser = APTS_TestDataFactory.createUser();
        System.runAs(oTestUser) {
            APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
            batchJobCtrl.initiateAutoRenewalBatch();
            batchJobCtrl.batchComponentLabel='ABC';
            batchJobCtrl.getBatchJobs();
        }
        test.stopTest();
   }
   
    private static testMethod void test_logic2() {
        test.startTest();
        User otestuser = APTS_TestDataFactory.createUser();
        System.runAs(oTestUser) {
            APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
            batchJobCtrl.initiateAutoRenewalBatch();
            batchJobCtrl.getJobPercentage(1,1,'Completed');
            batchJobCtrl.getJobPercentage(0,0,'Completed');
        }
        test.stopTest();
   }
   private static testMethod void test_logic2_1() {
        test.startTest();
        APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
        batchJobCtrl.initiateAutoRenewalBatch();
        batchJobCtrl.getJobPercentage(1,1,'Completed');
        batchJobCtrl.getJobPercentage(0,0,'Completed');
        test.stopTest();
   }
   
   private static testMethod void test_logic3() {
        test.startTest(); 
        List<Account> accList = [select id from Account limit 1];
        List<Apttus_Config2__PriceList__c> priceList  = [select id from Apttus_Config2__PriceList__c limit 1];
        List<Contact> primaryContact =  [select id from Contact limit 1];
        List<Apttus_Config2__AssetLineItem__c> primaryBundleAsset = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__IsPrimaryLine__c = true limit 2];
        
        Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
        Database.insert(oOrderSystemProperties);

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
        order.APTS_Requested_Installation_Date__c = NULL;
        insert order;
        Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
        order1.Apttus_Config2__Status__c = 'Activated';
        order1.APTS_Requested_Installation_Date__c = NULL;
        insert order1;
        
        APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[0].id;
        autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c = System.NOW(); 
        autoRenewalStaging.APTS_Comments__c = null;
        autoRenewalStaging.APTS_Associated_order__c = order.id;
        insert autoRenewalStaging;

        APTS_Auto_renewal_staging__c autoRenewalStaging1 = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging1.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[1].id;
        autoRenewalStaging1.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging1.APTS_Phase_1_date_and_time_for_Rollback__c = System.NOW(); 
        autoRenewalStaging1.APTS_Comments__c = null;
        autoRenewalStaging1.APTS_Associated_order__c = order1.id;
        insert autoRenewalStaging1;
        
        List<APTS_Auto_renewal_staging__c> autoList = [select id,APTS_Affected_Asset_Line_Item__c,
                                                       APTS_Process_status__c,APTS_Comments__c,APTS_Associated_order__c,CreatedDate,CreatedById from APTS_Auto_renewal_staging__c];

        System.debug('*******autoList===========>'+autoList);                                               
        Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),200);
        test.stopTest();
   }
    private static testMethod void test_logic3_1() {
        test.startTest();
        User otestuser = APTS_TestDataFactory.createUser();
        System.runAs(oTestUser) {       
            List<Account> accList = [select id from Account limit 1];
            List<Apttus_Config2__PriceList__c> priceList  = [select id from Apttus_Config2__PriceList__c limit 1];
            List<Contact> primaryContact =  [select id from Contact limit 1];
            List<Apttus_Config2__AssetLineItem__c> primaryBundleAsset = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__IsPrimaryLine__c = true limit 2];
            
            Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
            Database.insert(oOrderSystemProperties);

            Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
            order.APTS_Requested_Installation_Date__c = NULL;
            insert order;
            Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
            order1.Apttus_Config2__Status__c = 'Activated';
            order1.APTS_Requested_Installation_Date__c = NULL;
            insert order1;
            
            APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
            autoRenewalStaging.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[0].id;
            autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
            autoRenewalStaging.APTS_Comments__c = null;
            autoRenewalStaging.APTS_Associated_order__c = order.id;
            insert autoRenewalStaging;

            APTS_Auto_renewal_staging__c autoRenewalStaging1 = new APTS_Auto_renewal_staging__c();
            autoRenewalStaging1.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[1].id;
            autoRenewalStaging1.APTS_Process_status__c = 'Unprocessed';
            autoRenewalStaging1.APTS_Comments__c = null;
            autoRenewalStaging1.APTS_Associated_order__c = order1.id;
            insert autoRenewalStaging1;
            
            List<APTS_Auto_renewal_staging__c> autoList = [select id,APTS_Affected_Asset_Line_Item__c,
                                                           APTS_Process_status__c,APTS_Comments__c,APTS_Associated_order__c,CreatedDate,CreatedById from APTS_Auto_renewal_staging__c];

            System.debug('*******autoList===========>'+autoList);                                               
            Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),200);
        }
        test.stopTest();
   }

   private static testMethod void test_logic5() {
        test.startTest(); 
        List<Account> accList = [select id from Account limit 1];
        List<Apttus_Config2__PriceList__c> priceList  = [select id from Apttus_Config2__PriceList__c limit 1];
        List<Contact> primaryContact =  [select id from Contact limit 1];
        List<Apttus_Config2__AssetLineItem__c> primaryBundleAsset = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__IsPrimaryLine__c = true limit 2];
        
        Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
        Database.insert(oOrderSystemProperties);

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
        order.APTS_Requested_Installation_Date__c = NULL;
        insert order;
        Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
        order1.Apttus_Config2__Status__c = 'Activated';
        order1.APTS_Requested_Installation_Date__c = NULL;
        insert order1;
        
        APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[0].id;
        autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging.APTS_Comments__c = null;
        autoRenewalStaging.APTS_Associated_order__c = order.id;
        insert autoRenewalStaging;

        APTS_Auto_renewal_staging__c autoRenewalStaging1 = new APTS_Auto_renewal_staging__c();
        autoRenewalStaging1.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[1].id;
        autoRenewalStaging1.APTS_Process_status__c = 'Unprocessed';
        autoRenewalStaging1.APTS_Comments__c = null;
        autoRenewalStaging1.APTS_Associated_order__c = order1.id;
        insert autoRenewalStaging1;
        
        List<APTS_Auto_renewal_staging__c> autoList = [select id,APTS_Affected_Asset_Line_Item__c,
                                                       APTS_Process_status__c,APTS_Comments__c,APTS_Associated_order__c,CreatedDate,CreatedById from APTS_Auto_renewal_staging__c];

        TriggerSettings__c triggerSettings = new TriggerSettings__c();
        triggerSettings.SetupOwnerId = UserInfo.getUserId();
        Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
        for(Schema.SObjectField field : m.values()){
            if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
               triggerSettings.put(field,false);
            }
        }
        insert triggerSettings;

        Map<String, Schema.SObjectField> m1 = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
        ProcessBuilderSettings__c PBSettings = new ProcessBuilderSettings__c();
        PBSettings.SetupOwnerId = UserInfo.getUserId();
        for(Schema.SObjectField field : m1.values()){
            System.debug('***FIELD==4===>'+String.valueOf(field.getDescribe().getType()));
            if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
               PBSettings.put(field,false);
            }
        }
        insert PBSettings;

        System.debug('*******autoList===========>'+autoList);                                               
        Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),200);
        test.stopTest();
   }
    private static testMethod void test_logic5_1() {
        test.startTest(); 
        User otestuser = APTS_TestDataFactory.createUser();
        System.runAs(oTestUser) {       
            List<Account> accList = [select id from Account limit 1];
            List<Apttus_Config2__PriceList__c> priceList  = [select id from Apttus_Config2__PriceList__c limit 1];
            List<Contact> primaryContact =  [select id from Contact limit 1];
            List<Apttus_Config2__AssetLineItem__c> primaryBundleAsset = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__IsPrimaryLine__c = true limit 2];
            
            Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
            Database.insert(oOrderSystemProperties);

            Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
            order.APTS_Requested_Installation_Date__c = NULL;
            insert order;
            Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(accList[0].id,priceList[0].id,primaryContact[0].id);
            order1.Apttus_Config2__Status__c = 'Activated';
            order1.APTS_Requested_Installation_Date__c = NULL;
            insert order1;
            
            APTS_Auto_renewal_staging__c autoRenewalStaging = new APTS_Auto_renewal_staging__c();
            autoRenewalStaging.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[0].id;
            autoRenewalStaging.APTS_Process_status__c = 'Unprocessed';
            autoRenewalStaging.APTS_Comments__c = null;
            autoRenewalStaging.APTS_Associated_order__c = order.id;
            autoRenewalStaging.APTS_Phase_1_date_and_time_for_Rollback__c=System.NOW();
            insert autoRenewalStaging;

            APTS_Auto_renewal_staging__c autoRenewalStaging1 = new APTS_Auto_renewal_staging__c();
            autoRenewalStaging1.APTS_Affected_Asset_Line_Item__c = primaryBundleAsset[1].id;
            autoRenewalStaging1.APTS_Process_status__c = 'Unprocessed';
            autoRenewalStaging1.APTS_Comments__c = null;
            autoRenewalStaging1.APTS_Associated_order__c = order1.id;
            autoRenewalStaging1.APTS_Phase_1_date_and_time_for_Rollback__c=System.NOW();
            insert autoRenewalStaging1;
            
            List<APTS_Auto_renewal_staging__c> autoList = [select id,APTS_Affected_Asset_Line_Item__c,
                                                           APTS_Process_status__c,APTS_Comments__c,APTS_Associated_order__c,CreatedDate,CreatedById from APTS_Auto_renewal_staging__c];

            TriggerSettings__c triggerSettings = new TriggerSettings__c();
            triggerSettings.SetupOwnerId = UserInfo.getUserId();
            Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
            for(Schema.SObjectField field : m.values()){
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   triggerSettings.put(field,false);
                }
            }
            insert triggerSettings;

            Map<String, Schema.SObjectField> m1 = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
            ProcessBuilderSettings__c PBSettings = new ProcessBuilderSettings__c();
            PBSettings.SetupOwnerId = UserInfo.getUserId();
            for(Schema.SObjectField field : m1.values()){
                System.debug('***FIELD==4===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   PBSettings.put(field,false);
                }
            }
            insert PBSettings;

            System.debug('*******autoList===========>'+autoList);                                               
            Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),200);
        }
        test.stopTest();
   }
   private static testMethod void test_logic6() {
        test.startTest();
        //create user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' Limit 1];

        User testuser = new User();
        testuser.Alias = 'tstUsr';
        testuser.Email = 'testUser@apttusdemo.com';
        testuser.EmailEncodingKey = 'ISO-8859-1';
        testuser.LastName = 'testUserForTestClasses';
        testuser.LanguageLocaleKey = 'en_US';
        testuser.ProfileId = p.Id;
        testuser.TimeZoneSidKey = 'Europe/Amsterdam';
        testuser.LocaleSidKey = 'en_GB';
        testuser.UserName = 'testuser123@jdecoffee.com';
        //added due to custom validation rule on User
        //VR_Elevated_Access_Reason
        testuser.Elevated_Access_Reason__c = 'Authorization Issue';
        testuser.Elevated_Access_Reference__c = 'Authorization Issue';
        insert testuser;
        
        System.runAs(testuser){
        
            APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
            batchJobCtrl.initiateAutoRenewalBatch();
            batchJobCtrl.batchComponentLabel='ABC';
            batchJobCtrl.getBatchJobs();
           
            TriggerSettings__c triggerSettings = new TriggerSettings__c();
            triggerSettings.SetupOwnerId = UserInfo.getUserId();
            Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
            for(Schema.SObjectField field : m.values()){
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   triggerSettings.put(field,false);
                }
            }
            insert triggerSettings;
        
            Map<String, Schema.SObjectField> m1 = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
            ProcessBuilderSettings__c PBSettings = new ProcessBuilderSettings__c();
            PBSettings.SetupOwnerId = UserInfo.getUserId();
            for(Schema.SObjectField field : m1.values()){
                System.debug('***FIELD==4===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   PBSettings.put(field,false);
                }
            }
            insert PBSettings;
            String jobId = System.schedule('ActivateJob30MinTest', '0 15 * * * ?', new APTS_AutoAssetRenewalScheduler());
        }
        test.stopTest();
   }
    private static testMethod void test_logic6_1() {
        test.startTest();
        DateTime createdDate;
        User otestuser = APTS_TestDataFactory.createUser();
        System.runAs(oTestUser) {   
            APTS_AssetAutoRenewalPageCtrl batchJobCtrl = new APTS_AssetAutoRenewalPageCtrl();
            batchJobCtrl.initiateAutoRenewalBatch();
            batchJobCtrl.batchComponentLabel='ABC';
            batchJobCtrl.getBatchJobs();
            TriggerSettings__c triggerSettings = new TriggerSettings__c();
            triggerSettings.SetupOwnerId = UserInfo.getUserId();
            Map<String, Schema.SObjectField> m = Schema.SObjectType.TriggerSettings__c.fields.getMap();
            for(Schema.SObjectField field : m.values()){
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   triggerSettings.put(field,false);
                }
            }
            insert triggerSettings;
        
            Map<String, Schema.SObjectField> m1 = Schema.SObjectType.ProcessBuilderSettings__c.fields.getMap();
            ProcessBuilderSettings__c PBSettings = new ProcessBuilderSettings__c();
            PBSettings.SetupOwnerId = UserInfo.getUserId();
            for(Schema.SObjectField field : m1.values()){
                System.debug('***FIELD==4===>'+String.valueOf(field.getDescribe().getType()));
                if(String.valueOf(field.getDescribe().getType())=='BOOLEAN' && (!String.valueOf(field).equalsIgnoreCase('IsDeleted'))){
                   PBSettings.put(field,false);
                }
            }
            insert PBSettings;
            System.schedule('ActivateJob30MinTest', '0 15 * * * ?', new APTS_AutoAssetRenewalScheduler());
        }
        test.stopTest();
   }
}