@isTest
private  with sharing class APTS_CreateConversionOrderCtrl_Test {
    public APTS_CreateConversionOrderCtrl_Test() {
    }
    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Account acct= APTS_TestUtils.createOrganisationproduct();
        insert acct;
        Case cs = APTS_TestUtils.createcase(acct.Id);
        insert cs;
        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;
        Apttus_Config2__AccountLocation__c olocation = APTS_TestUtils.createAccountLocation(acct.Id);
        insert olocation;
        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;
        Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
        oAggreement.Apttus__Status_Category__c = 'In Effect';
        oAggreement.Apttus__Status__c = 'Activated';
        oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        insert oAggreement;
        Product2 prod = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod;
        Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod1;
        
        Apttus_Config2__Order__c oOrder=APTS_TestUtils.createOrder(null,oTestPricelist.Id,acct.Id,null);
        oOrder.Apttus_Config2__PriceListId__c=oTestPricelist.Id;
        oOrder.Apttus_Config2__BillToAccountId__c=acct.Id;
        oOrder.APTS_Payer__c=acct.Id;
        oOrder.Apttus_Config2__Status__c='Pending';
        oOrder.Apttus_Config2__SoldToAccountId__c=acct.Id;
        oOrder.Apttus_Config2__LocationId__c=olocation.Id;
        oOrder.APTS_SAP_OrderType__c ='XA23';
        oOrder.APTS_Order_Sub_Type__c='Installation';
        insert oOrder;
         system.debug('Order==='+oOrder);
        oOrder=[select id, Name from Apttus_Config2__Order__c where id=:oOrder.id limit 1];
        system.debug('Order==='+oOrder);

        Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem.Apttus_Config2__Frequency__c='Monthly';
        alineItem.Apttus_Config2__PriceType__c='Recurring';
        alineItem.APTS_Type_Of_Contract__c = 'Rent';
        alineItem.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem.Apttus_Config2__AccountId__c = acct.id;
        alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem.APTS_Is_Primary_L1_Line__c = true;
        alineItem.Apttus_Config2__HasOptions__c = true;
        alineItem.Apttus_Config2__BusinessObjectId__c= oOrder.id;
        insert alineItem;

        Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem2.Apttus_Config2__Frequency__c='Monthly';
        alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Type_Of_Contract__c = 'Rent';
        alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
        alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
        alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        alineItem2.Apttus_Config2__LineType__c='Option';
        alineItem2.Apttus_Config2__AccountId__c = acct.id;
        alineItem2.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem2;

        Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem1.Apttus_Config2__Frequency__c='Monthly';
        alineItem1.Apttus_Config2__PriceType__c='Renewed';
        alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
        alineItem1.Apttus_Config2__OptionId__c = prod1.id;
        alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem1.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem1;

        Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem3.Apttus_Config2__Frequency__c='Monthly';
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Type_Of_Contract__c = 'Rent';
        alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem3.Apttus_Config2__AccountId__c = acct.id;
        alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem3.APTS_Is_Primary_L1_Line__c = true;
        alineItem3.Apttus_Config2__HasOptions__c = true;
        insert alineItem3;
        
       Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAggreement.Id,
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__OrderId__c = oOrder.id,
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                Apttus_Config2__AssetLineItemId__c=alineItem.Id);
        insert orderLineItem1;

        Test.startTest();
        APTS_CreateConversionOrderController.getAssetOptions(alineItem.id);
        APTS_CreateConversionOrderController.getConversionOrdersForMachine(alineItem.id);
        APTS_CreateConversionOrderController.getOptionLines(alineItem.id);
        APTS_CreateConversionOrderController.getOptionLinesForTermination(alineItem.id);
        APTS_CreateConversionOrderController.getOptionLinesForRenewal(alineItem.id);
        APTS_CreateConversionOrderController.getOrderStatus(alineItem.id);
        APTS_CreateConversionOrderController.cancelOrderStatus(oOrder.Name);

        String subType='Discounts',orderInput='[{"basePrice":29,"basePriceOverride":22,"chargeType":"Service Fee","discountPercentage":"0","endDate":"2024-02-01","id":"'+alineItem.id+'","name":"ALL-IN COVERAGE","netUnitPrice":22,"nextInvoiceDate":"2020-07-29","originalStartDate":"2019-09-16","startDate":"2020-07-28","subType":"ZP06"}]';
        APTS_CreateConversionOrderController.createConversionOrder(alineItem.id,subType,orderInput,Date.today(),null,false,'Test',cs);

        // Test.startTest();
        subType='Billing Settings';orderInput='[{"Id":"'+alineItem3.id+'","startDate":"2028-01-01","billingPreferenceId":"a2s1v000000KOF9AAO","billingFrequency":"Half Yearly"}]';
        APTS_CreateConversionOrderController.createConversionOrder(alineItem.id,subType,orderInput,Date.today(),null,false,'Test',cs);

        subType='Termination';orderInput='';
        APTS_CreateConversionOrderController.createConversionOrder(alineItem.id,subType,orderInput,Date.today(),null,false,'Test',cs);
        subType='Renewal';orderInput='';
        APTS_CreateConversionOrderController.createConversionOrder(alineItem.id,subType,orderInput,Date.today(),null,false,'Test',cs);
        Test.stopTest();
    }
    @isTest static void test_getWrapperClasses() {
        APTS_CreateConversionOrderController.AssetLineItem asl=new APTS_CreateConversionOrderController.AssetLineItem(null,null);
        APTS_CreateConversionOrderController.ReturnWrapper rw=new APTS_CreateConversionOrderController.ReturnWrapper(null,null,null);
        APTS_CreateConversionOrderController.DiscountWrapper dw=new APTS_CreateConversionOrderController.DiscountWrapper();
        dw.id =null;
        dw.name =null;
        dw.nextInvoiceDate =null;
        dw.originalStartDate =null;
        dw.startDate =null;
        dw.endDate =null;
        dw.chargeType =null;
        dw.basePrice =null;
        dw.basePriceOverride =null;
        dw.subType =null;
        dw.discountAmount =null;
        dw.discountPercentage =null;
        dw.netUnitPrice =null;
        APTS_CreateConversionOrderController.TerminationWrapper tw=new APTS_CreateConversionOrderController.TerminationWrapper();
        tw.id=null;
        tw.name=null;
        tw.chargeType=null;
        tw.originalStartDate=null;
        tw.assetEndDate=null;
        tw.lastInvoicedPeriod=null;
        tw.nextInvoiceDate=null;
        APTS_CreateConversionOrderController.RenewalWrapper rew=new APTS_CreateConversionOrderController.RenewalWrapper();
        rew.id  = null;
        rew.name  = null;
        rew.chargeType  = null;
        rew.billingCycleStart  = null;
        rew.billingDayOfMonth  = null;
        rew.assetStartDate  = null;
        rew.assetEndDate  = null;
        rew.nextInvoiceDate  = null;
        rew.billingRule  = null;
        APTS_CreateConversionOrderController.OrderStatusWrapper osw=new APTS_CreateConversionOrderController.OrderStatusWrapper();
        osw.id = null;
        osw.subType  = null;
        osw.action  = null;
        osw.name = null;
        osw.createdDate = null;
        osw.createdBy = null;
        osw.status = null;
        osw.errorId = null;
        osw.errorName  = null;

    }
    @isTest static void test_getConversionOrderOptions() {
        Test.startTest();
        APTS_CreateConversionOrderController.getConversionOrderOptions();
        List<APTS_CreateConversionOrderController.DiscountWrapper> discountwrapperList = new List<APTS_CreateConversionOrderController.DiscountWrapper>();
        APTS_CreateConversionOrderController.DiscountWrapper discWrappObj = new APTS_CreateConversionOrderController.DiscountWrapper();
        discWrappObj.startDateModified='test1';
        discWrappObj.startDate=system.today();
        discWrappObj.endDate=system.today().addMonths(12);
        discountwrapperList.add(discWrappObj);
        APTS_CreateConversionOrderController.reCalculateSellingTermForOptions(discountwrapperList);
        Test.stopTest();
    }
}