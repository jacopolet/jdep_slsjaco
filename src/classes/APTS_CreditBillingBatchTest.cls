/*************************************************************
@Name: APTS_CreditBillingBatchTest
@Author: Balashanthi A 
@CreateDate: 06-07-2018
@Description: APTS_CreditBillingBatchHelper Test class
@UsedBy: APTS_CreditBillingBatchHelper
******************************************************************/
@isTest
public class APTS_CreditBillingBatchTest {
    private static String MACHINE = 'Machine';
    
    @TestSetup
    public static void setupData(){
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        insert objTriggerSettings;

        //Insert custom setting 
        List<APTS_Credit_Batch_Countries__c> rcbList= new List<APTS_Credit_Batch_Countries__c>();
        APTS_Credit_Batch_Countries__c rcb1 = new APTS_Credit_Batch_Countries__c(name='test1',APTS_Sales_Org__c='SAP_0111',APTS_Sequence__c=1);
        rcbList.add(rcb1);
        APTS_Credit_Batch_Countries__c rcb2 = new APTS_Credit_Batch_Countries__c(name='test2',APTS_Sales_Org__c='SAP2',APTS_Sequence__c=2);
        rcbList.add(rcb2);
        APTS_Credit_Batch_Countries__c rcb3 = new APTS_Credit_Batch_Countries__c(name='test3',APTS_Sales_Org__c='SAP3',APTS_Sequence__c=3);
        rcbList.add(rcb3);
        insert rcbList;
        
        // Product Insert
        List<Product2> prodList = new List<Product2>();
        Product2 oStandaloneProduct = APTS_TestDataFactory.createProduct('Standalone', '104', 'MA', 'Standalone', FALSE, FALSE);
        Product2 oBundleProduct = APTS_TestDataFactory.createProduct('Bundle', '101', 'MA', 'Bundle', FALSE, TRUE);
        Product2 oOptionProduct = APTS_TestDataFactory.createProduct('Option', '102', 'MA', 'Option', FALSE, FALSE);
        prodList.add(oStandaloneProduct);
        prodList.add(oBundleProduct);
        prodList.add(oOptionProduct);
        Database.insert(prodList);
        APTS_MuteCreditSAPSubmission__c mutesapset = new APTS_MuteCreditSAPSubmission__c();
        mutesapset.Name = 'Mute SAP Call';
        mutesapset.APTS_ISSAPCallDisabled__c = false;
        insert mutesapset;
 
        APTS_Fixed_Term_Dummy_Product__c dummyProduct = new APTS_Fixed_Term_Dummy_Product__c(name= 'HIGHTAX',
            Product_Name__c='Dummy High Tax');
        Database.Insert(dummyProduct);
                
        Product2 oStandaloneProduct2 = APTS_TestDataFactory.createProduct('Standalone', '104', 'MA', 'Standalone', FALSE, FALSE);
        oStandaloneProduct2.Name='HIGHTAX';
        insert oStandaloneProduct2;
        // price list
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        // Billing Preference
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
        billingPreference.name='Test Preference';
        billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
        billingPreference.APTS_Invoice_Type__c ='Single Invoice';
        billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        billingPreference.Apttus_Config2__DoNotCreateInformational__c  = TRUE;
        billingPreference.Apttus_Config2__HideInformational__c = TRUE;
        Database.Insert(billingPreference);
        // Payment Method
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        Database.Insert(paymentMethod);
        // payment Term
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        paymentTerm.Apttus_Config2__Sequence__c = 5;
        Database.Insert(paymentTerm);
        //Account creation
        List<Account> accountList = new List<Account>();
        for(Integer i = 0; i < 5; i++){
            Account account = new Account(name = 'Test'+i,
                                        Apttus_Config2__BillingPreferenceId__c = billingPreference.Id,
                                        Apttus_Config2__PaymentTermId__c = paymentTerm.Id,
                                        APTS_Payment_Method__c = paymentMethod.Id,
                                        Sales_Organization__c = 'SAP_0111',
                                        Division__c = 'SAP_20',
                                        Distribution_Channel__c = 'SAP_10');
            accountList.add(account);
        }
        insert accountList;
        // Contact Creation
        List<Contact> contactList = new List<Contact>();
        for(Integer i = 0; i < 5; i++){
            Contact contact = new Contact(FirstName = 'Test'+String.valueOf(i),
                                        LastName ='UUUU',
                                        AccountId = accountList[i].Id);
            contactList.add(contact);
        }
        insert contactList;
        // Agreement Creation
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        Id ConsumtpionRecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        for(Integer i = 0; i < 5; i++){
            Apttus__APTS_Agreement__c   agreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = accountList[i].Id, 
                                                                                    Name = 'Test Agreement'+String.valueOf(i),
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(), 
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Payer_Machines_Services__c = accountList[i].Id,
                                                                                    Apttus__Primary_Contact__c = contactList[i].Id,
                                                                                    APTS_Payer_Ingredients__c = accountList[i].Id);
            if(i==0){
                agreement.APTS_Fixed_Term_Type__c ='Fixed Cost';
            }
            if(i==1){
                agreement.RecordTypeId = ConsumtpionRecId;
                
            }
            if(i==3){
                agreement.RecordTypeId = ConsumtpionRecId;
                agreement.APTS_Fixed_Term_Type__c ='Fixed Cost';
            }
            agreementList.add(agreement);

        }
        insert(agreementList);
        Apttus__AgreementLineItem__c agreementLineItem1 = new Apttus__AgreementLineItem__c();
        agreementLineItem1.Apttus__ProductId__c = prodList[0].Id;
        agreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        //agreementLineItem1.Apttus_CMConfig__DerivedFromId__c = li1.Id;
        agreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        agreementLineItem1.Apttus__AgreementId__c = agreementList[1].Id;
        agreementLineItem1.Apttus_CMConfig__BasePriceOverride__c = 90.00;
       
        agreementLineItem1.CurrencyIsoCode = 'EUR';
        insert agreementLineItem1;
        // Agrement Po Details creation
        List<APTS_Agreement_PO_Details__c> agreementPoDetailsList = new List<APTS_Agreement_PO_Details__c>();
        for(Integer i = 0; i < 5; i++){
            APTS_Agreement_PO_Details__c  agreementPoDetails = new APTS_Agreement_PO_Details__c(APTS_Agreement__c = agreementList[i].Id, 
                                                                                                APTS_PO_Category__c = 'Machine',
                                                                                                APTS_PO_Number__c = '1221'+String.valueOf(i),
                                                                                                APTS_PO_Number_Required__c = 'Yes', 
                                                                                                APTS_PO_Number_Type__c  = 'Fixed');
            agreementPoDetailsList.add(agreementPoDetails);

        }
        insert agreementPoDetailsList;
        APTS_Agreement_PO_Details__c  agreementPoDetails1 = new APTS_Agreement_PO_Details__c(APTS_Agreement__c = agreementList[0].Id, 
                                                                                                APTS_PO_Category__c = 'Machine',
                                                                                                APTS_PO_Number__c = '122139',
                                                                                                APTS_PO_Number_Required__c = 'Yes', 
                                                                                                APTS_PO_Number_Type__c  = 'Fixed');
        insert agreementPoDetails1;
        // Billing Settings
        APTS_Billing_Settings__c  billingSetting = new APTS_Billing_Settings__c(APTS_Agreement_ID__c = agreementList[2].Id, 
                                                                                                APTS_Agreement_Billing_Type__c = 'Machine',
                                                                                                APTS_Billing_Preference_Setting__c = billingPreference.Id,
                                                                                                APTS_Billing_Rule_Contract__c = 'Bill in Advance', 
                                                                                                APTS_Bill_To_ID__c  = accountList[2].Id,
                                                                                                APTS_Invoice_Delivery_Preference__c ='P001',
                                                                                                APTS_Invoice_Type__c ='Collective Invoice',
                                                                                                APTS_Payment_Method__c =paymentMethod.Id,
                                                                                                APTS_Payment_Term_Setting__c =paymentTerm.Id
                                                                                                 );
        insert billingSetting;
        // Billing Settings
        APTS_Billing_Settings__c  billingSetting1 = new APTS_Billing_Settings__c(APTS_Agreement_ID__c = agreementList[0].Id, 
                                                                                                APTS_Agreement_Billing_Type__c = 'Machine',
                                                                                                APTS_Billing_Preference_Setting__c = billingPreference.Id,
                                                                                                APTS_Billing_Rule_Contract__c = 'Bill in Advance', 
                                                                                                APTS_Bill_To_ID__c  = accountList[2].Id,
                                                                                                APTS_Invoice_Delivery_Preference__c ='P001',
                                                                                                APTS_Invoice_Type__c ='Invoice List – With Summary Page',
                                                                                                APTS_Payment_Method__c =paymentMethod.Id,
                                                                                                APTS_Payment_Term_Setting__c =paymentTerm.Id
                                                                                                 );
        insert billingSetting1;
        PhysicalAsset__c phyAst = new PhysicalAsset__c();
        Id machineRecTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(MACHINE).getRecordTypeId();
        phyAst.RecordTypeId = machineRecTypeId;
        phyAst.UniqueNumber__c = 'BAS102';
        phyAst.Product__c = prodList[0].Id;
        phyAst.AssetStatus__c = 'Pending Activation';
        phyAst.Building__c = 'Block-A';
        phyAst.PostalCode__c = '6000345';
        phyAst.Country__c = 'India';
        phyAst.Connected__c = 'Yes';
        Database.insert(phyAst);
        
        //Machine Order Creation in Account. 
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('New', priceList.Id, accountList[3].Id, billingPreference.Id);
        order.APTS_Order_Type__c='Machine Order';
        order.APTS_Order_Sub_Type__c='Installation';
        order.Apttus_CMConfig__AgreementId__c = agreementList[3].Id;
        order.APTS_Fix_Term_Billing_Flag__c = 'Z';
        Database.insert(order, false);
        
        //Order Line Item Creation.
        List<Apttus_Config2__OrderLineItem__c> oLIList = new List<Apttus_Config2__OrderLineItem__c>();
        Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
        orderLineItem.Apttus_Config2__Status__c = 'Activated';
        orderLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        orderLineItem.APTS_Serial_Number__c = '2186451249';
        orderLineItem.APTS_Physical_Asset__c = phyAst.ID;
        orderLineItem.Apttus_Config2__OrderId__c = order.id;
        oLIList.add(orderLineItem);
        
        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c();
        orderLineItem1.Apttus_Config2__Status__c = 'Activated';
        orderLineItem1.Apttus_Config2__LineType__c = 'Option';
        orderLineItem1.APTS_Serial_Number__c = '2186451249';
        orderLineItem1.Apttus_Config2__OrderId__c = order.id;
        oLIList.add(orderLineItem1);
        
        Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c();
        orderLineItem2.Apttus_Config2__Status__c = 'Activated';
        orderLineItem2.Apttus_Config2__LineType__c = 'Option';
        orderLineItem2.Apttus_Config2__NetPrice__c = 19889;
        orderLineItem2.Apttus_Config2__OrderId__c = order.id;
        oLIList.add(orderLineItem2);
        
        Database.insert(oLIList, false);
        
        //  Asset Line item Creation
        List<Apttus_Config2__AssetLineItem__c> assetLineItems = new List<Apttus_Config2__AssetLineItem__c>();
        for(Integer i = 0; i <= 13; i++){
            Apttus_Config2__AssetLineItem__c assetLineItem = new Apttus_Config2__AssetLineItem__c(Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                    Apttus_Config2__Frequency__c = 'Recurring',
                                                                                                    Apttus_Config2__BasePrice__c = 299.00,
                                                                                                    Apttus_Config2__PaymentTermId__c = paymentTerm.Id,
                                                                                                    APTS_Payment_Method__c = paymentMethod.Id,
                                                                                                    Apttus_Config2__BillingPreferenceId__c = billingPreference.Id,
                                                                                                    Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                    Apttus_Config2__BillingRule__c = 'Bill In Advance',
                                                                                                    Apttus_Config2__NetPrice__c = 90.00,
                                                                                                    Apttus_Config2__EndDate__c = Date.today()+365,
                                                                                                    Apttus_Config2__PriceListId__c = priceList.Id,
                                                                                                    Apttus_Config2__ListPrice__c = 90.00,
                                                                                                    Apttus_Config2__NetUnitPrice__c = 90.00,
                                                                                                    Apttus_Config2__OptionId__c= prodList[0].Id,
                                                                                                    Apttus_Config2__PricingDate__c = system.today(),
                                                                                                    Apttus_Config2__PriceUom__c = 'SAP_BX',
                                                                                                    Apttus_Config2__PrimaryLineNumber__c = 1,
                                                                                                    Apttus_Config2__ProductId__c = prodList[0].Id,
                                                                                                    Apttus_Config2__Quantity__c = 1,
                                                                                                    APTS_RefurbishedMachine__c  = true,
                                                                                                    Apttus_Config2__SellingFrequency__c ='Monthly',
                                                                                                    Apttus_Config2__SellingTerm__c = 1,
                                                                                                    Apttus_Config2__SellingUom__c = 'SAP_PCE',
                                                                                                    Apttus_Config2__LineType__c ='Option',
                                                                                                    Apttus_Config2__ChargeType__c ='Rental Fee',
                                                                                                    Apttus_Config2__ExtendedPrice__c = 2880,
                                                                                                    Apttus_Config2__LineNumber__c = 1.0,
                                                                                                    APTS_Option_Group_Text__c = 'Technical Service',
                                                                                                    APTS_Cumulative_Call_Out_Coverage__c = 20.00,
                                                                                                    APTS_Cumulative_Labour_coverage__c = 20.00,
                                                                                                    APTS_Cumulative_Spare_Parts_Coverage__c = 20.00,
                                                                                                    Apttus_Config2__HasOptions__c = true,
                                                                                                    APTS_Type_of_Contract__c ='Rent',
                                                                                                    APTS_Physical_Asset__c = phyAst.id,
                                                                                                    Apttus_CMConfig__AgreementId__c = agreementList[2].Id,
                                                                                                    APTS_relatedlist_agreement__c = agreementList[2].Id,
                                                                                                    Apttus_Config2__BaseExtendedPrice__c = 90.00);
            if(i == 0){
                assetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                assetLineItem.Apttus_Config2__ItemSequence__c = 1;
                assetLineItem.APTS_Is_Primary_L1_Line__c = true;
                assetLineItem.Apttus_Config2__LineNumber__c = 1;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[0].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[0].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[0].Id;
                assetLineItem.APTS_Payer__c = accountList[0].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[0].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[0].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[0].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[0].Id;
            }
             if(i == 1){
                assetLineItem.Apttus_Config2__ItemSequence__c = 1;
                assetLineItem.Apttus_CMConfig__AgreementLineItemId__c = agreementLineItem1.Id;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[0].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[0].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[0].Id;
                assetLineItem.APTS_Payer__c = accountList[0].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[0].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[0].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[0].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[0].Id;
            }
            // consumtion Model
            if(i == 2){

                assetLineItem.APTS_Type_Of_Contract__c= 'Consumption';
                assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.APTS_Is_Primary_L1_Line__c = true;
                assetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                assetLineItem.Apttus_Config2__ItemSequence__c = 1;
                assetLineItem.Apttus_Config2__LineNumber__c = 1;
                assetLineItem.Apttus_Config2__BillingFrequency__c = 'Quarterly';
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[1].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[1].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[1].Id;
                assetLineItem.APTS_Payer__c = accountList[1].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[1].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[1].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[1].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[1].Id;
            }
            if(i == 3){
                assetLineItem.APTS_Type_Of_Contract__c= 'Consumption';
                assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.Apttus_Config2__ItemSequence__c = 1;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[1].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[1].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[1].Id;
                assetLineItem.APTS_Payer__c = accountList[1].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[1].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[1].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[1].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[1].Id;
            }
            if(i == 4 || i == 5){
                if(i == 4){
                    assetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                    assetLineItem.APTS_Is_Primary_L1_Line__c = true;
                }
                assetLineItem.Apttus_Config2__NetPrice__c = 0.00;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[2].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[2].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[2].Id;
                assetLineItem.APTS_Payer__c = accountList[2].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[2].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[2].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[2].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[2].Id;
            }
            if(i == 6){
                //assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                //assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.APTS_Type_Of_Contract__c = 'Consumption';
                assetLineItem.Apttus_Config2__LineType__c = 'Product/Service';
                assetLineItem.APTS_Is_Primary_L1_Line__c = true;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[3].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
                assetLineItem.APTS_Payer__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
            }
            if(i == 7){
                assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.APTS_Type_Of_Contract__c = 'Consumption';
                assetLineItem.APTS_RefurbishedMachine__c = false;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[3].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
                assetLineItem.APTS_Payer__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
            }
            if(i == 12){
                //assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                //assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.APTS_Type_Of_Contract__c = 'Consumption';
                assetLineItem.APTS_RefurbishedMachine__c = false;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[3].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
                assetLineItem.APTS_Payer__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
            }
            if(i == 13){
                //assetLineItem.Apttus_Config2__PriceType__c = 'Usage';
                //assetLineItem.Apttus_Config2__ChargeType__c = 'Usage Fee';
                assetLineItem.APTS_Type_Of_Contract__c = 'Consumption';
                assetLineItem.APTS_RefurbishedMachine__c = false;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[3].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
                assetLineItem.APTS_Payer__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[3].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[3].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[3].Id;
            }
            if(i == 8 || i == 9 ||i == 10 ||i==11){
                assetLineItem.Apttus_Config2__NetPrice__c = 0.00;
                assetLineItem.Apttus_CMConfig__AgreementId__c = agreementList[2].Id;
                assetLineItem.APTS_relatedlist_agreement__c = agreementList[2].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[2].Id;
                assetLineItem.APTS_Payer__c = accountList[2].Id;
                assetLineItem.Apttus_Config2__BillToAccountId__c = accountList[2].Id;
                assetLineItem.APTS_Bill_to_Party_Ingredients_and_Payer__c = accountList[2].Id;
                assetLineItem.APTS_Bill_to_Party_Machines_Services__c = accountList[2].Id;
                assetLineItem.Apttus_Config2__AccountId__c = accountList[2].Id;
            }
            assetLineItems.add(assetLineItem);
        }
        Apttus_Config2__AssetLineItem__c assetLineItem2 = new Apttus_Config2__AssetLineItem__c(Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                    Apttus_Config2__Frequency__c = 'Recurring',
                                                                                                    Apttus_Config2__BasePrice__c = 299.00,
                                                                                                    Apttus_Config2__PaymentTermId__c = paymentTerm.Id,
                                                                                                    APTS_Payment_Method__c = paymentMethod.Id,
                                                                                                    Apttus_Config2__BillingPreferenceId__c = billingPreference.Id,
                                                                                                    Apttus_Config2__BillingFrequency__c = 'Monthly',
                                                                                                    Apttus_Config2__BillingRule__c = 'Bill In Advance',
                                                                                                    Apttus_Config2__NetPrice__c = 90.00,
                                                                                                    Apttus_Config2__EndDate__c = Date.today()+365,
                                                                                                    Apttus_Config2__PriceListId__c = priceList.Id,
                                                                                                    Apttus_Config2__ListPrice__c = 90.00,
                                                                                                    Apttus_Config2__NetUnitPrice__c = 90.00,
                                                                                                    Apttus_Config2__OptionId__c= prodList[0].Id,
                                                                                                    Apttus_Config2__PricingDate__c = system.today(),
                                                                                                    Apttus_Config2__PriceUom__c = 'SAP_BX',
                                                                                                    Apttus_Config2__PrimaryLineNumber__c = 1,
                                                                                                    Apttus_Config2__ProductId__c = oStandaloneProduct2.Id,
                                                                                                    Apttus_Config2__Quantity__c = 1,
                                                                                                    APTS_RefurbishedMachine__c  = true,
                                                                                                    Apttus_Config2__SellingFrequency__c ='Monthly',
                                                                                                    Apttus_Config2__SellingTerm__c = 1,
                                                                                                    Apttus_Config2__SellingUom__c = 'SAP_PCE',
                                                                                                    Apttus_Config2__LineType__c ='Misc',
                                                                                                    Apttus_Config2__ChargeType__c ='Rental Fee',
                                                                                                    Apttus_Config2__ExtendedPrice__c = 2880,
                                                                                                    Apttus_Config2__LineNumber__c = 1.0,
                                                                                                    APTS_Option_Group_Text__c = 'Technical Service',
                                                                                                    APTS_Cumulative_Call_Out_Coverage__c = 20.00,
                                                                                                    APTS_Cumulative_Labour_coverage__c = 20.00,
                                                                                                    APTS_Cumulative_Spare_Parts_Coverage__c = 20.00,
                                                                                                    Apttus_Config2__HasOptions__c = true,
                                                                                                    APTS_Type_of_Contract__c ='Rent',
                                                                                                    APTS_Physical_Asset__c = phyAst.id,
                                                                                                    Apttus_CMConfig__AgreementId__c = agreementList[2].Id,
                                                                                                    Apttus_Config2__BaseExtendedPrice__c = 90.00);
        
        
        insert assetLineItem2;
        insert assetLineItems;

        List<Apttus_Config2__AssetAttributeValue__c> productAttributeList = new  List<Apttus_Config2__AssetAttributeValue__c>();
        Apttus_Config2__AssetAttributeValue__c productAtt1 = new Apttus_Config2__AssetAttributeValue__c();
        productAtt1.APTS_Type_of_contract__c = 'Consumption';
        productAtt1.APTS_Type_of_Consumption__c = 'Paid';
        productAtt1.Apttus_Config2__AssetLineItemId__c = assetLineItems.get(3).Id;
        productAtt1.APTS_Base_Price_Override_per_cup__c = 10.00;
        productAtt1.APTS_List_Price_per_cup__c  = 10.00;
        productAtt1.APTS_Base_Price_Override_per_cup_FV__c = 10.00;
        productAtt1.APTS_List_Price_per_cup_FV__c =10.00;
        productAttributeList.add(productAtt1);

        Apttus_Config2__AssetAttributeValue__c productAtt2 = new Apttus_Config2__AssetAttributeValue__c();
        productAtt2.APTS_Type_of_contract__c = 'Consumption';
        productAtt2.APTS_Type_of_Consumption__c = 'Free Vend';
        productAtt2.Apttus_Config2__AssetLineItemId__c = assetLineItems.get(7).Id;
        productAtt2.APTS_Base_Price_Override_per_cup__c = 10.00;
        productAtt2.APTS_List_Price_per_cup__c  = 10.00;
        productAtt2.APTS_Base_Price_Override_per_cup_FV__c = 10.00;
        productAtt2.APTS_List_Price_per_cup_FV__c =10.00;
        productAttributeList.add(productAtt2);

        Apttus_Config2__AssetAttributeValue__c productAtt3 = new Apttus_Config2__AssetAttributeValue__c();
        productAtt3.APTS_Type_of_contract__c = 'Consumption';
        productAtt3.APTS_Type_of_Consumption__c = 'Both';
        productAtt3.Apttus_Config2__AssetLineItemId__c = assetLineItems.get(13).Id;
        productAtt3.APTS_Base_Price_Override_per_cup__c = 10.00;
        productAtt3.APTS_List_Price_per_cup__c  = 10.00;
        productAtt3.APTS_Base_Price_Override_per_cup_FV__c = 10.00;
        productAtt3.APTS_List_Price_per_cup_FV__c =10.00;
        productAttributeList.add(productAtt3);

        insert productAttributeList;


        List<Apttus_Config2__AssetLineItem__c> assetLineItemList1 = new List<Apttus_Config2__AssetLineItem__c>();
        Integer j = 0;
        if(!assetLineItems.isEmpty()){
            Apttus_Config2__AssetLineItem__c assetLine = new Apttus_Config2__AssetLineItem__c();
            assetLine.Id = assetLineItems.get(1).id;
            assetLine.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(0).Id;
            assetLine.Apttus_Config2__LineType__c = 'Option';
            assetLine.Apttus_Config2__LineNumber__c = 1;
            assetLine.Apttus_Config2__BillingFrequency__c = 'Monthly';
            assetLineItemList1.add(assetLine);
            
            Apttus_Config2__AssetLineItem__c assetLine1 = new Apttus_Config2__AssetLineItem__c();
            assetLine1.Id = assetLineItems.get(3).id;
            assetLine1.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(2).Id;
            assetLine1.Apttus_Config2__AttributeValueId__c =  productAttributeList.get(0).Id;
            assetLine1.Apttus_Config2__LineType__c = 'Option';
            assetLine1.Apttus_Config2__LineNumber__c = 1.0;
            assetLine1.Apttus_Config2__BillingFrequency__c = 'Quarterly';
            assetLineItemList1.add(assetLine1);

            Apttus_Config2__AssetLineItem__c assetLine2 = new Apttus_Config2__AssetLineItem__c();
            assetLine2.Id = assetLineItems.get(5).id;
            assetLine2.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(4).Id;
            assetLine2.Apttus_Config2__LineNumber__c = 2;
            assetLine2.Apttus_Config2__LineType__c = 'Option';
            assetLine2.Apttus_Config2__BillingFrequency__c = 'Half Yearly';
            assetLineItemList1.add(assetLine2);
            // 100 % discount Lines
            Apttus_Config2__AssetLineItem__c assetLine5 = new Apttus_Config2__AssetLineItem__c();
            assetLine5.Id = assetLineItems.get(7).id;
            assetLine5.Apttus_Config2__AttributeValueId__c =  productAttributeList.get(1).Id;
            assetLine5.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(6).Id;
            assetLine5.Apttus_Config2__LineNumber__c = 1;
            assetLine5.Apttus_Config2__LineType__c = 'Option';
            assetLine5.Apttus_Config2__BillingFrequency__c = 'Yearly';
            assetLineItemList1.add(assetLine5);

            Apttus_Config2__AssetLineItem__c assetLine12 = new Apttus_Config2__AssetLineItem__c();
            assetLine12.Id = assetLineItems.get(12).id;
            assetLine12.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(6).Id;
            assetLine12.Apttus_Config2__LineNumber__c = 1;
            assetLine12.Apttus_Config2__LineType__c = 'Option';
            assetLine12.Apttus_Config2__BillingFrequency__c = 'Yearly';
            assetLineItemList1.add(assetLine12);

            Apttus_Config2__AssetLineItem__c assetLine13 = new Apttus_Config2__AssetLineItem__c();
            assetLine13.Id = assetLineItems.get(13).id;
            assetLine13.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(2).Id;
            assetLine13.Apttus_Config2__AttributeValueId__c =  productAttributeList.get(2).Id;
            assetLine13.Apttus_Config2__LineNumber__c = 1;
            assetLine13.Apttus_Config2__LineType__c = 'Option';
            assetLine13.Apttus_Config2__BillingFrequency__c = 'Yearly';
            assetLineItemList1.add(assetLine13);

            Apttus_Config2__AssetLineItem__c assetLine6 = new Apttus_Config2__AssetLineItem__c();
            assetLine6.Id = assetLineItems.get(8).id;
            assetLine6.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(4).Id;
            assetLine6.Apttus_Config2__LineNumber__c = 1.0;
            assetLine6.Apttus_Config2__LineType__c = 'Option';
            assetLine6.Apttus_Config2__BillingFrequency__c = 'Yearly';
            assetLineItemList1.add(assetLine6);

            Apttus_Config2__AssetLineItem__c assetLine7 = new Apttus_Config2__AssetLineItem__c();
            assetLine7.Id = assetLineItems.get(9).id;
            assetLine7.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(4).Id;
            assetLine7.Apttus_Config2__LineNumber__c = 1.0;
            assetLine7.Apttus_Config2__LineType__c = 'Option';
            assetLine7.Apttus_Config2__BillingFrequency__c = 'Half Yearly';
            assetLineItemList1.add(assetLine7);

            Apttus_Config2__AssetLineItem__c assetLine8 = new Apttus_Config2__AssetLineItem__c();
            assetLine8.Id = assetLineItems.get(10).id;
            assetLine8.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(4).Id;
            assetLine8.Apttus_Config2__LineNumber__c = 1.0;
            assetLine8.Apttus_Config2__LineType__c = 'Option';
            assetLine8.Apttus_Config2__BillingFrequency__c = 'Monthly';
            assetLineItemList1.add(assetLine8);

            Apttus_Config2__AssetLineItem__c assetLine9 = new Apttus_Config2__AssetLineItem__c();
            assetLine9.Id = assetLineItems.get(11).id;
            assetLine9.APTS_Is_Primary_L1_Asset__c =  assetLineItems.get(4).Id;
            assetLine9.Apttus_Config2__LineNumber__c = 1.0;
            assetLine9.Apttus_Config2__LineType__c = 'Option';
            assetLine9.Apttus_Config2__BillingFrequency__c = 'Quarterly';
            assetLineItemList1.add(assetLine9);

        }
        if(!assetLineItemList1.isEmpty()){
            update assetLineItemList1;
        }
        // Asset Adjustment Line Item creation
         List<Apttus_Config2_AssetAdjustItem__c> assetLineItemsAdjustmentList = new List<Apttus_Config2_AssetAdjustItem__c>();
        
       
         Apttus_Config2_AssetAdjustItem__c assetLineItemAdjustment1 = new Apttus_Config2_AssetAdjustItem__c(Apttus_Config2_AssetAdjustAmount__c = 40.00,
                                                                                                    Apttus_Config2_AssetAdjustAppliesTo__c = '  Bucket 1',
                                                                                                    Apttus_Config2_AssetAdjustType__c = '% Discount',
                                                                                                    Apttus_Config2_Adjustment_Uom__c = 'Piece',
                                                                                                    Apttus_Config2_BenefitQuantity__c = 1,
                                                                                                    Apttus_Config2_Bucket__c = 'Bucket 1',
                                                                                                    Apttus_Config2_CouponCode__c = 'CXPW',
                                                                                                    Apttus_Config2_IncentiveCode__c = 'VWPSK',
                                                                                                    Apttus_Config2_LineType__c = 'Manual',
                                                                                                    Apttus_Config2_AssetLineItemId__c = assetLineItems[8].Id,
                                                                                                    Apttus_Config2_IncentiveAsetAdjustAmount__c = 10.00,
                                                                                                    Apttus_Config2_SubType__c = 'ZP06',
                                                                                                    Apttus_Config2_Type__c = 'PPR',
                                                                                                     RunningTotalAdjustedPrice__c = 1000.00
                                                                                                    );
        assetLineItemsAdjustmentList.add(assetLineItemAdjustment1);
        Apttus_Config2_AssetAdjustItem__c assetLineItemAdjustment2 = new Apttus_Config2_AssetAdjustItem__c(Apttus_Config2_AssetAdjustAmount__c = 40.00,
                                                                                                    Apttus_Config2_AssetAdjustAppliesTo__c = '  Bucket 1',
                                                                                                    Apttus_Config2_AssetAdjustType__c = '% Discount',
                                                                                                    Apttus_Config2_Adjustment_Uom__c = 'Piece',
                                                                                                    Apttus_Config2_BenefitQuantity__c = 1,
                                                                                                    Apttus_Config2_Bucket__c = 'Bucket 1',
                                                                                                    Apttus_Config2_CouponCode__c = 'CXPW',
                                                                                                    Apttus_Config2_IncentiveCode__c = 'VWPSK',
                                                                                                    Apttus_Config2_LineType__c = 'Manual',
                                                                                                    Apttus_Config2_AssetLineItemId__c = assetLineItems[9].Id,
                                                                                                    Apttus_Config2_IncentiveAsetAdjustAmount__c = 10.00,
                                                                                                    Apttus_Config2_SubType__c = 'ZP06',
                                                                                                    Apttus_Config2_Type__c = 'PPR',
                                                                                                    RunningTotalAdjustedPrice__c = 1000.00
                                                                                                    );
        assetLineItemsAdjustmentList.add(assetLineItemAdjustment2);
        Apttus_Config2_AssetAdjustItem__c assetLineItemAdjustment4 = new Apttus_Config2_AssetAdjustItem__c(Apttus_Config2_AssetAdjustAmount__c = 40.00,
                                                                                                    Apttus_Config2_AssetAdjustAppliesTo__c = '  Bucket 1',
                                                                                                    Apttus_Config2_AssetAdjustType__c = '% Discount',
                                                                                                    Apttus_Config2_Adjustment_Uom__c = 'Piece',
                                                                                                    Apttus_Config2_BenefitQuantity__c = 1,
                                                                                                    Apttus_Config2_Bucket__c = 'Bucket 1',
                                                                                                    Apttus_Config2_CouponCode__c = 'CXPW',
                                                                                                    Apttus_Config2_IncentiveCode__c = 'VWPSK',
                                                                                                    Apttus_Config2_LineType__c = 'Manual',
                                                                                                    Apttus_Config2_AssetLineItemId__c = assetLineItems[10].Id,
                                                                                                    Apttus_Config2_IncentiveAsetAdjustAmount__c = 10.00,
                                                                                                    Apttus_Config2_SubType__c = 'ZP06',
                                                                                                    Apttus_Config2_Type__c = 'PPR',
                                                                                                    RunningTotalAdjustedPrice__c = 1000.00
                                                                                                    );
        
        assetLineItemsAdjustmentList.add(assetLineItemAdjustment4);
        insert assetLineItemsAdjustmentList;
        
        Apttus_Billing__Invoice__c invoiceObj = new Apttus_Billing__Invoice__c();
        invoiceObj.APTS_External_Invoice_Number__c='4192932389';
        insert invoiceObj;
        
        // Billing schedule creation
        Apttus_Billing__BillingSchedule__c billingSchedules2 = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today(),
                                                                                                        Apttus_Billing__AssetLineItemId__c = assetLineItem2.Id,
                                                                                                        Apttus_Billing__BillToAccountId__c = accountList[0].Id,
                                                                                                        Apttus_Billing__Status__c ='Pending Billing',
                                                                                                        Apttus_Billing__IsSuperseded__c = false,
                                                                                                        Apttus_Billing__PeriodEndDate__c = Date.today()+30,
                                                                                                        Apttus_Billing__PeriodStartDate__c = Date.today(),
                                                                                                        Apttus_Billing__FeeAmount__c = -90.00,
                                                                                                        Apttus_Billing__Type__c = 'Contracted',
                                                                                                        Apttus_Billing__OrderLineItemId__c=oLIList[0].id,
                                                                                                        APTS_Invoice__c = invoiceObj.Id
                                                                                                        );
        
        
        insert billingSchedules2;
        List<Apttus_Billing__BillingSchedule__c> billingSchedulesList = new List<Apttus_Billing__BillingSchedule__c>();
        for(Integer i = 0; i < =13; i++){
            Apttus_Billing__BillingSchedule__c billingSchedules = new Apttus_Billing__BillingSchedule__c(Apttus_Billing__ReadyForInvoiceDate__c = Date.today(),
                                                                                                        Apttus_Billing__AssetLineItemId__c = assetLineItems.get(i).Id,
                                                                                                        Apttus_Billing__BillToAccountId__c = accountList[0].Id,
                                                                                                        Apttus_Billing__Status__c ='Pending Billing',
                                                                                                        Apttus_Billing__IsSuperseded__c = false,
                                                                                                        Apttus_Billing__PeriodEndDate__c = Date.today()+30,
                                                                                                        Apttus_Billing__PeriodStartDate__c = Date.today(),
                                                                                                        Apttus_Billing__FeeAmount__c = -90.00,
                                                                                                        Apttus_Billing__Type__c = 'Contracted',
                                                                                                        Apttus_Billing__OrderLineItemId__c=oLIList[0].id,
                                                                                                        Apttus_Billing__InvoicedScheduleId__c = billingSchedules2.Id);
            
            
            if(i == 4 || i == 5 || i == 8 || i == 9 || i == 10 || i ==11){
                billingSchedules.Apttus_Billing__FeeAmount__c = 0.00;
                billingSchedules.Apttus_Billing__InvoicedScheduleId__c = null;
            }
            billingSchedulesList.add(billingSchedules);
        }
        insert billingSchedulesList;
        
       system.debug(+billingSchedules2.Apttus_Billing__InvoicedScheduleId__c+' , '+billingSchedules2.Id);
       for(Integer i = 0; i < =13; i++){
           system.debug('i: '+i+', '+billingSchedulesList[i].APTS_Invoice__c+ ', '+billingSchedulesList[i].Id);
       }
       // Usage schedules
       Apttus_Billing__UsageSchedule__c usageSchedules = new Apttus_Billing__UsageSchedule__c(Apttus_Billing__Type__c = 'Usage',
                                                                                                        Apttus_Billing__AssetLineItemId__c = assetLineItems.get(3).Id,
                                                                                                        Apttus_Billing__Uom__c = 'SAP_PCE',
                                                                                                        Apttus_Billing__Status__c ='Pending Billing',
                                                                                                        Apttus_Billing__BillingScheduleId__c = billingSchedulesList.get(3).Id,
                                                                                                        Apttus_Billing__PeriodStartDate__c = Date.today(),
                                                                                                        Apttus_Billing__PeriodEndDate__c = Date.today()+30);
       insert usageSchedules;
       // Usage Input
       Apttus_Billing__UsageInput__c usageInput = new Apttus_Billing__UsageInput__c(Apttus_Billing__AssetLineItemId__c = assetLineItems.get(3).Id,
                                                                                                        Apttus_Billing__AssetNumber__c = String.valueOf(assetLineItems.get(3).Id),
                                                                                                        Apttus_Billing__UsageDate__c = system.today()+11,
                                                                                                        Apttus_Billing__Status__c ='Rated',
                                                                                                        Apttus_Billing__Quantity__c = 33);
       insert usageInput;

    }
    // Test method for Recurring Batch 
    public static testmethod void testBatch() {
        //Apttus_Config2__Order__c order = [Select Id,Apttus_Config2__Status__c,Apttus_Config2__ActivatedDate__c From Apttus_Config2__Order__c ];
        //order.Apttus_Config2__Status__c='Pending';
        //order.Apttus_Config2__ActivatedDate__c = system.today();
        //update order;
        APTS_CreditBillingBatch b = new APTS_CreditBillingBatch('SAP_0111');
        Test.startTest();
        Database.executeBatch(b);
        Test.stopTest();

    }
    // Test method for Recurring Batch 
    public static testmethod void testBatch1() {
        Apttus_Config2__Order__c order = [Select Id,Apttus_Config2__Status__c,Apttus_Config2__ActivatedDate__c From Apttus_Config2__Order__c ];
        order.APTS_Fix_Term_Billing_Flag__c ='Y';
        update order;
        
        APTS_CreditBillingBatch b = new APTS_CreditBillingBatch('SAP_0111');
        Test.startTest();
        //Database.executeBatch(b);
        
        
        Apttus_Billing__BillingSchedule__c schdl = [Select Id,Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__r.Id, 
                                 Apttus_Billing__AssetLineItemId__r.Id from Apttus_Billing__BillingSchedule__c where 
                                Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c =: order.Id Limit 1];
        Id pdId = schdl.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__r.Id;
        Id assetId = schdl.Apttus_Billing__AssetLineItemId__r.Id;
        Apttus_Config2__AssetLineItem__c asset = [Select Id,Apttus_Config2__LineType__c From Apttus_Config2__AssetLineItem__c Where Id=:assetId];
        asset.Apttus_Config2__LineType__c ='Misc';
        update asset;
        Product2 pd = [Select Id, Name From Product2 Where Id=: pdId];
        pd.Name='HIGHTAX';
        update pd;
        Database.executeBatch(new APTS_CreditBillingBatch('SAP_0111'));
        
        Test.stopTest();

    }
}