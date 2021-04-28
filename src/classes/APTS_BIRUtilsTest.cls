/*************************************************************
@Name: APTS_BIRUtilsTest
@Author: Balashanthi A 
@CreateDate: 11-04-2018
@Description: BIRUtils Test
@UsedBy: APTS_BIRUtils
******************************************************************/

@isTest
public with sharing class APTS_BIRUtilsTest{

    public static List<Apttus_Config2__LineItem__c> lineItemListForAgreement = new List<Apttus_Config2__LineItem__c>();
    public static List<Apttus_Config2__LineItem__c> lineItemListForOrder = new List<Apttus_Config2__LineItem__c>();
        
      @TestSetup
      private static void createTestData()
      {
        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
            Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            insert priceList;
            Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('June');
            billingPreference.name='Test Preference';
            billingPreference.APTS_Invoice_Delivery_Preference__c ='P001';
            billingPreference.APTS_Invoice_Type__c ='Single Invoice';
            billingPreference.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
            billingPreference.Apttus_Config2__BillingInterval__c = 'Monthly';
            billingPreference.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
            billingPreference.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
            insert billingPreference;

            Apttus_Config2__BillingPreference__c billingPreference1 = APTS_TestUtils.createBillingPrefrence('June');
            billingPreference1.name='Test Preference';
            billingPreference1.APTS_Invoice_Delivery_Preference__c ='P001';
            billingPreference1.APTS_Invoice_Type__c ='Single Invoice';
            billingPreference1.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
            billingPreference1.Apttus_Config2__BillingInterval__c = 'Monthly';
            billingPreference1.Apttus_Config2__BillingCycleStart__c = 'Ready for Billing Date';
            billingPreference1.Apttus_Config2__BillingDayOfMonth2__c = 'End of Month';
            insert billingPreference1;

            Apttus_Config2__BillingPreference__c billingPreference2 = APTS_TestUtils.createBillingPrefrence('June');
            billingPreference2.name='Test Preference';
            billingPreference2.APTS_Invoice_Delivery_Preference__c ='P001';
            billingPreference2.APTS_Invoice_Type__c ='Single Invoice';
            billingPreference2.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
            billingPreference2.Apttus_Config2__BillingInterval__c = 'Monthly';
            billingPreference2.Apttus_Config2__BillingCycleStart__c = 'Period Start Date';
            billingPreference2.Apttus_Config2__BillingDayOfMonth2__c = 'End of Month';
            insert billingPreference2;

            TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
            objTriggerSettings.AccountTrigger__c = false;
            objTriggerSettings.Agreement__c = false;
            objTriggerSettings.APTS_Order_Trigger__c = false;
            Database.insert(objTriggerSettings, false);
            
            List<APTS_AgreementBillingManual__c> listBilling = New List<APTS_AgreementBillingManual__c>();
            APTS_AgreementBillingManual__c billingData = new APTS_AgreementBillingManual__c();
            billingData.name = 'Mute Billing';
            billingData.fullLogicDisabledFlag__c = false;
            listBilling.add(billingData);
            insert listBilling;
            system.debug(listBilling[0].fullLogicDisabledFlag__c);
            APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
            insert paymentMethod;
            
            Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
            paymentTerm.Apttus_Config2__Sequence__c = 5;
            insert paymentTerm;
            List<Account> accountList = new List<Account>();
            Account account = APTS_TestUtils.createGrandParentAccount();
            account.name= 'Test';
            //Update Billing Key Fields
            account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
            account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            account.APTS_Payment_Method__c = paymentMethod.Id;
            account.Sales_Organization__c = 'SAP_0333';
            accountList.add(account);
            //insert account;
    
            Account account1 = APTS_TestUtils.createGrandParentAccount();
            account1.Name = 'Test1';
            //Update Billing Key Fields
            account1.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
            account1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            account1.APTS_Payment_Method__c = paymentMethod.Id;
            account1.Sales_Organization__c = 'SAP_0333';
            accountList.add(account1);
            insert accountList;
            List<Account> accountList1 = new List<Account>();
            /*Account acct1ToUpdate = new Account();
            acct1ToUpdate.Id = accountList[0].id;
            acct1ToUpdate.Related_Bill_to_Machines_Services__c = accountList[0].id;
            acct1ToUpdate.Related_Payer_Machines_Services__c = accountList[0].id;
            acct1ToUpdate.Bill_To_Payer_Account__c = accountList[0].id;
            acct1ToUpdate.Bill_To_Payer_Account__c = accountList[0].id;
            accountList1.add(acct1ToUpdate);*/
            Account acct1ToUpdate2 = new Account();
            acct1ToUpdate2.Id = accountList[0].id;
            acct1ToUpdate2.Related_Bill_to_Machines_Services__c = accountList[1].id;
            acct1ToUpdate2.Related_Payer_Machines_Services__c = accountList[1].id;
            acct1ToUpdate2.Bill_To_Payer_Account__c = accountList[1].id;
            acct1ToUpdate2.Bill_To_Payer_Account__c = accountList[1].id;
            accountList1.add(acct1ToUpdate2);
            update accountList1;
            
            Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
            Apttus__APTS_Agreement__c   testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                        Name = 'Test Agreement',
                                                                                        RecordTypeId = RecId,
                                                                                        Apttus__Contract_Start_Date__c = Date.today(), 
                                                                                        Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                        Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                        Apttus__Agreement_Number__c = '0001',
                                                                                        Apttus__Version_Number__c = 831.0,
                                                                                        APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                        Apttus__Subtype__c ='Default');
            insert testAgreement;
    
            Apttus__APTS_Agreement__c   agreementWithBillTo = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                    Name = 'AgreementWithBillTo',
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                    Apttus__Version_Number__c = 832.0,
                                                                                    APTS_Bill_to_Party_MachServ__c = account.Id);
            insert agreementWithBillTo;
            // Associate Billing setting
            APTS_Billing_Settings__c billsetting = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting.APTS_Agreement_Billing_Type__c ='Machine';
            billsetting.APTS_Invoice_Delivery_Preference__c = 'P001';
            insert billsetting;
            APTS_Billing_Settings__c billsetting1 = APTS_TestUtils.createBillingSetting(agreementWithBillTo.Id,agreementWithBillTo.APTS_Bill_to_Party_MachServ__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting1.APTS_Agreement_Billing_Type__c ='Ingredients';
            billsetting1.APTS_Invoice_Delivery_Preference__c = 'P001';
            insert billsetting1;
            // Data for Scenario 6
            Apttus__APTS_Agreement__c   billToDiffAccount = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                    Name = 'AgreementWithBillToDiffAccount',
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                    Apttus__Version_Number__c = 431.0,
                                                                                    APTS_Bill_to_Party_MachServ__c = account1.Id);
            insert billToDiffAccount;
            // Associate Billing setting
            APTS_Billing_Settings__c billsetting2 = APTS_TestUtils.createBillingSetting(billToDiffAccount.Id,billToDiffAccount.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting2.APTS_Agreement_Billing_Type__c ='Machine';
            billsetting2.APTS_Invoice_Delivery_Preference__c ='P001';
            insert billsetting2;
            APTS_Billing_Settings__c billsetting3 = APTS_TestUtils.createBillingSetting(billToDiffAccount.Id,billToDiffAccount.APTS_Bill_to_Party_MachServ__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting3.APTS_Agreement_Billing_Type__c ='Ingredients';
            billsetting3.APTS_Invoice_Delivery_Preference__c ='P001';
            insert billsetting3;
            // Hierarchy Account with same account
            Apttus__APTS_Agreement__c   hierarchyAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                    Name = 'HierarchyAgreement',
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                    Apttus__Version_Number__c = 731.0,
                                                                                    APTS_Bill_to_Party_MachServ__c = account.Id);
            insert hierarchyAgreement;
            // Hierarchy Account with diff account
            Apttus__APTS_Agreement__c   hierarchyAcctAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                    Name = 'hierarchyAcctAgreement',
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                    Apttus__Version_Number__c = 771.0,
                                                                                    APTS_Bill_to_Party_MachServ__c = account1.Id);
            insert hierarchyAcctAgreement;
            //Create Products
            List<Product2> prodList = new List<Product2>();
            Product2 oStandaloneProduct = APTS_TestDataFactory.createProduct('Standalone', '104', 'MA', 'Standalone', FALSE, FALSE);
            Product2 oBundleProduct = APTS_TestDataFactory.createProduct('Bundle', '101', 'MA', 'Bundle', FALSE, TRUE);
            Product2 oOptionProduct = APTS_TestDataFactory.createProduct('Option', '102', 'MA', 'Option', FALSE, FALSE);
            prodList.add(oStandaloneProduct);
            prodList.add(oBundleProduct);
            prodList.add(oOptionProduct);
            insert prodList;
            //Create Price List Items
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(priceList.Id, oStandaloneProduct.Id);
            priceListItemList.add(oPriceListItemStandalone);
            Apttus_Config2__PriceListItem__c oPriceListItemBundle = APTS_TestDataFactory.createPriceListItem(priceList.Id, oBundleProduct.Id);
            priceListItemList.add(oPriceListItemBundle);
            Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestDataFactory.createPriceListItem(priceList.Id, oOptionProduct.Id);
            priceListItemList.add(oPriceListItemOption);
            insert priceListItemList;
            Apttus_Config2__ClassificationName__c categoryMachines = APTS_TestDataFactory.createCategory();
            categoryMachines.Name ='Machines';
            insert categoryMachines;
            Apttus_Config2__ClassificationName__c categoryServices = APTS_TestDataFactory.createCategory();
            categoryMachines.Name ='Services';
            insert categoryServices;
            Apttus_Config2__ClassificationName__c categoryIngredients = APTS_TestDataFactory.createCategory();
            insert categoryIngredients;
            List<Apttus_Config2__ClassificationHierarchy__c> categoryHierarchyList = new List<Apttus_Config2__ClassificationHierarchy__c>();
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyMachine = APTS_TestDataFactory.createCategoryHierarchy(categoryMachines.Id, 'Machines');
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyService = APTS_TestDataFactory.createCategoryHierarchy(categoryServices.Id, 'Services');
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyIngre = APTS_TestDataFactory.createCategoryHierarchy(categoryIngredients.Id, 'Coffee');
            categoryHierarchyList.add(categoryHierarchyMachine);
            categoryHierarchyList.add(categoryHierarchyService);
            categoryHierarchyList.add(categoryHierarchyIngre);
            insert categoryHierarchyList;
            // Data for Scenario 6
            Apttus__APTS_Agreement__c   lineItemTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                                                                                    Name = 'LineItemTestAgreement',
                                                                                    RecordTypeId = RecId,
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    Apttus__Version_Number__c = 931.0,
                                                                                    APTS_Bill_to_Party_Ingredients__c = account.Id,
                                                                                    APTS_Bill_to_Party_MachServ__c = account1.Id,
                                                                                    APTS_Check_on_Account_Ingredients__c=true,
                                                                                    APTS_Check_on_Account_Machines__c=true);
            insert lineItemTestAgreement;
            // Associate Billing setting
            APTS_Billing_Settings__c billsetting4 = APTS_TestUtils.createBillingSetting(lineItemTestAgreement.Id,lineItemTestAgreement.APTS_Bill_to_Party_Ingredients__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting4.APTS_Invoice_Type__c =  'Invoice List – With Summary Page';
            billsetting4.APTS_Agreement_Billing_Type__c ='Machine';
            billsetting4.APTS_Invoice_Delivery_Preference__c ='P001';
            insert billsetting4;
            APTS_Billing_Settings__c billsetting5 = APTS_TestUtils.createBillingSetting(lineItemTestAgreement.Id,lineItemTestAgreement.APTS_Bill_to_Party_MachServ__c,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting5.APTS_Invoice_Type__c = 'Collective Invoice';
            billsetting5.APTS_Agreement_Billing_Type__c ='Ingredients';
            billsetting5.APTS_Invoice_Delivery_Preference__c ='P001';
            insert billsetting5;
        
            // Create Order
            Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
            order1.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement.Id;
            order1.APTS_Name__c = 'TestOrder1';
            order1.Apttus_Config2__Status__c ='Draft';
            order1.APTS_Order_Type__c = 'Standard Order';
            order1.APTS_Remove_Billing_Block_Indicator__c = false;
            insert order1;
            // Create Standard Order for invoice
            Apttus_Config2__Order__c standardOrder = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
            standardOrder.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement.Id;
            standardOrder.APTS_Name__c = 'TestOrderStandard';
            standardOrder.APTS_Order_Type__c = 'Standard Order';
            standardOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            standardOrder.APTS_InvoiceType__c = 'Single Invoice';
            standardOrder.APTS_Invoice_List_Indicator__c = 'No';
            standardOrder.Apttus_Config2__ActivatedDate__c = System.today();
            standardOrder.APTS_Collective_Billing_Indicator__c = false;
            standardOrder.Apttus_Config2__SoldToAccountId__c = account.Id;
            insert standardOrder;
            // Create Machine Order for invoice
            Apttus_Config2__Order__c machineOrder = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
            machineOrder.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement.Id;
            machineOrder.Apttus_Config2__PriceListId__c = priceList.Id;
            machineOrder.APTS_Name__c = 'TestOrderMachine';
            machineOrder.APTS_InvoiceType__c = 'Collective Invoice';
            machineOrder.APTS_Order_Type__c = 'Machine Order';
            machineOrder.APTS_Order_Sub_Type__c = 'Installation';
            machineOrder.APTS_Invoice_List_Indicator__c = 'No';
            machineOrder.APTS_Order_Header_SAP_ID__c ='1234';
            machineOrder.Apttus_Config2__Status__c ='Activated';
            machineOrder.APTS_Status__c = 'Sent For Invoicing';
            machineOrder.APTS_Collective_Billing_Indicator__c = false;
            machineOrder.Apttus_Config2__ActivatedDate__c = System.today();
            machineOrder.APTS_SAP_OrderType__c = 'XA13';
            machineOrder.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
            machineOrder.Apttus_Config2__SoldToAccountId__c = account.Id;
            insert machineOrder;
    
            Apttus_Config2__Order__c orderForInsert = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
            orderForInsert.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement.Id;
            orderForInsert.APTS_Name__c = 'TestOrderForInsert';
            orderForInsert.Apttus_Config2__Status__c ='Draft';
            orderForInsert.APTS_Order_Type__c = 'Standard Order';
            orderForInsert.APTS_Status__c = 'Sent For Invoicing';
            orderForInsert.APTS_Remove_Billing_Block_Indicator__c = false;
            orderForInsert.APTS_Order_Header_SAP_ID__c ='000018374';
            orderForInsert.APTS_Distribution_Channel__c = 'SAP_20';
            insert orderForInsert;
    
            // Create Admin Order
            Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
            order.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement.Id;
            order.APTS_Name__c = 'TestOrder';
            order.Apttus_Config2__Status__c ='Activated';
            order.Derived_From_Order__c = machineOrder.Id;
            order.APTS_Fix_Term_Billing_Flag__c = 'Z';
            order.APTS_Order_Type__c = 'Admin Order';
            order.APTS_Status__c = 'Sent For Invoicing';
            order.APTS_Order_Header_SAP_ID__c ='0000001834';
            order.APTS_Remove_Billing_Block_Indicator__c = false;
            order.Apttus_Config2__ActivatedDate__c = System.today();
            insert order;
    
            //Create Invoice
            Apttus_Billing__Invoice__c  invoice = new Apttus_Billing__Invoice__c();
            invoice.Apttus_Billing__BillToAccountId__c = account.Id;
            invoice.Apttus_Billing__LocationId__c = null;
            invoice.Apttus_Billing__Status__c = 'Draft';
            invoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
            invoice.APTS_External_Invoice_Number__c = '2222';
            insert invoice;
        }
    }

      //Test method for creation of BillingSetting --- After Update --- Same Account
      static testMethod void createBillingSettingonUpdateWithSameAcount(){
    
        List<Apttus__APTS_Agreement__c> lstOldAgreement = new List<Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c
                                        FROM Account 
                                        LIMIT 2];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,RecordTypeId,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%Test %' LIMIT 1];
        lstOldAgreement.add(testAgreement);
        mapOldAgreement.put(testAgreement.Id,testAgreement);

        Apttus__APTS_Agreement__c testNewAgreement = [SELECT Id,RecordTypeId,
                                                            Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                            APTS_Bill_to_Party_Ingredients__c,
                                                            APTS_Bill_to_Party_MachServ__c,
                                                            Apttus__Agreement_Number__c,
                                                            Apttus__Version_Number__c  
                                                        FROM Apttus__APTS_Agreement__c 
                                                        WHERE Name LIKE '%Test %' LIMIT 1];
        testNewAgreement.APTS_Bill_to_Party_Ingredients__c=accountList[1].Id;
        testNewAgreement.APTS_Bill_to_Party_MachServ__c=accountList[1].Id;
        testNewAgreement.Apttus__Status__c='Activated';
        Database.Update(testNewAgreement);
        lstNewAgreement.add(testNewAgreement);
        mapNewAgreement.put(testNewAgreement.Id, testNewAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,true); 
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);  
        accountList[0].Apttus_Config2__BillingPreferenceId__c = null;
        APTS_BIRUtils.setBillingSettingData(testAgreement,accountList[0],'Ingredients');
        Test.stopTest();
    }

    //Test method for creation of BillingSetting --- After Update --- Same Account
    static testMethod void createBillingSettingonUpdateWithDifferentAcount(){
    
        List<Apttus__APTS_Agreement__c> lstOldAgreement = new List<Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c 
                                        FROM Account 
                                        LIMIT 2];                                       
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%Test %' LIMIT 1];
        lstOldAgreement.add(testAgreement);
        mapOldAgreement.put(testAgreement.Id,testAgreement);

        Apttus__APTS_Agreement__c testNewAgreement = [SELECT Id,
                                                            Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                            APTS_Bill_to_Party_Ingredients__c,
                                                            APTS_Bill_to_Party_MachServ__c,
                                                            Apttus__Agreement_Number__c,
                                                            Apttus__Version_Number__c  
                                                        FROM Apttus__APTS_Agreement__c 
                                                        WHERE Name LIKE '%Test %' LIMIT 1];
        testNewAgreement.APTS_Bill_to_Party_Ingredients__c=accountList[0].Id;
        testNewAgreement.APTS_Bill_to_Party_MachServ__c=accountList[1].Id;
        testNewAgreement.Apttus__Status__c='Activated';
        Database.Update(testNewAgreement);
        lstNewAgreement.add(testNewAgreement);
        mapNewAgreement.put(testNewAgreement.Id, testNewAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,true); 
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);
        Test.stopTest();
    }

    //Test method for creation of BillingSetting --- After Update --- Same Bill To Account Removal
    static testMethod void billToAccountRemovalForSameAccount(){
    
        List<Apttus__APTS_Agreement__c> lstOldAgreement = new List<Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c
                                        FROM Account 
                                        LIMIT 2];                                       
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,RecordTypeId,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%AgreementWithBillTo%' LIMIT 1];
        lstOldAgreement.add(testAgreement);
        mapOldAgreement.put(testAgreement.Id,testAgreement);

        Apttus__APTS_Agreement__c testNewAgreement = [SELECT Id,
                                                            Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                            APTS_Bill_to_Party_Ingredients__c,
                                                            APTS_Bill_to_Party_MachServ__c,
                                                            Apttus__Version_Number__c  
                                                        FROM Apttus__APTS_Agreement__c 
                                                        WHERE Name LIKE '%AgreementWithBillTo%' LIMIT 1];
        testNewAgreement.APTS_Bill_to_Party_Ingredients__c= null;
        testNewAgreement.APTS_Bill_to_Party_MachServ__c= null;
        testNewAgreement.Apttus__Status__c='Activated';
        Database.Update(testNewAgreement);
        accountList[0].Related_Bill_to_Machines_Services__c=null;
        Database.Update(accountList[0]);
        lstNewAgreement.add(testNewAgreement);
        mapNewAgreement.put(testNewAgreement.Id, testNewAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,true);
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);
        Test.stopTest();
    }

    //Test method for creation of BillingSetting --- After Update --- Diff Bill To Account Removal
    static testMethod void billToAccountRemovalForDiffAccount(){
    
        List<Apttus__APTS_Agreement__c> lstOldAgreement = new List<Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstNewAgreement = new List<Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c
                                        FROM Account 
                                        LIMIT 2];                                       
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%AgreementWithBillToDiffAccount%' LIMIT 1];
        lstOldAgreement.add(testAgreement);
        mapOldAgreement.put(testAgreement.Id,testAgreement);

        Apttus__APTS_Agreement__c testNewAgreement = [SELECT Id,
                                                            Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                            APTS_Bill_to_Party_Ingredients__c,
                                                            APTS_Bill_to_Party_MachServ__c,
                                                            Apttus__Version_Number__c  
                                                        FROM Apttus__APTS_Agreement__c 
                                                        WHERE Name LIKE '%AgreementWithBillToDiffAccount%' LIMIT 1];
        testNewAgreement.APTS_Bill_to_Party_Ingredients__c= null;
        testNewAgreement.APTS_Bill_to_Party_MachServ__c= null;
        testNewAgreement.Apttus__Status__c='Activated';
        Database.Update(testNewAgreement);
        lstNewAgreement.add(testNewAgreement);
        mapNewAgreement.put(testNewAgreement.Id, testNewAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,true); 
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);
        Test.stopTest();
    }

    //Test method for creation of BillingSetting --- After Insert----Same Account Data
    static testMethod void createBillingSettingonInsertion(){ 
        
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c
                                        FROM Account 
                                        LIMIT 1];                                       
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%HierarchyAgreement%' LIMIT 1];
        //lstOldAgreement.add(testAgreement);
        mapNewAgreement.put(testAgreement.Id,testAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,false);
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);     
        Test.stopTest();
    }
    //Test method for creation of BillingSetting --- After Insert----different Account Data
    static testMethod void createBillingSettingonInsertion1(){
    
        Map<Id, Apttus__APTS_Agreement__c> mapNewAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus__APTS_Agreement__c> mapOldAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        List<Account> accountList = [SELECT Id,Related_Bill_to_Machines_Services__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                          Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                          Related_Bill_to_Machines_Services__r.Sales_Organization__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Apttus_Config2__BillingPreferenceId__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                          Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                          Sales_Organization__c,Apttus_Config2__PaymentTermId__c,APTS_Payment_Method__c
                                        FROM Account 
                                        LIMIT 1];                                       
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,Apttus__FF_Agreement_Number__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%hierarchyAcctAgreement%' LIMIT 1];
        testAgreement.Apttus__Status__c='Activated';
        Database.Update(testAgreement);
        mapNewAgreement.put(testAgreement.Id,testAgreement);
        Test.startTest();  
        APTS_BIRUtils.createBillingSetting(mapNewAgreement,mapOldAgreement,false); 
        Set<Id> agreementIds = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c]).keySet();
        List<APTS_Billing_Settings__c>Billdata = [select id,APTS_Agreement_ID__c FROM APTS_Billing_Settings__c WHERE APTS_Agreement_ID__c IN:agreementIds];
        System.debug('billing size'+Billdata.size());
        system.assert(Billdata.size() > 0);     
        Test.stopTest();                                  
    }
    //Test method for setting Billing Key fields for creation of setBillingKeyFieldsOnLineItem 
    static testMethod void overrideBillingFieldsOnLineItem_Test(){
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        List<Id> configId = new List<Id>();
        Product2 oStandaloneProduct = APTS_TestFacade.getStandaloneProduct();
        Product2 oBundleProduct = APTS_TestFacade.getBundleProduct();
        Product2 oOptionProduct = APTS_TestFacade.getOptionProduct();
        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestFacade.getPriceListItem(oStandaloneProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemBundle = APTS_TestFacade.getPriceListItem(oBundleProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestFacade.getPriceListItem(oOptionProduct.Id);
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id,
                                                        Name,
                                                        Apttus__Account__c,
                                                        Apttus__Contract_Start_Date__c,
                                                        Apttus__Contract_End_Date__c,
                                                        Apttus_CMConfig__PriceListId__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%LineItemTestAgreement%' LIMIT 1];
        Apttus_Config2__BillingPreference__c billpref = [SELECT Id,
                                                                Name,
                                                                Apttus_Config2__BillingInterval__c
                                                    FROM Apttus_Config2__BillingPreference__c 
                                                    WHERE Name LIKE '%Test Preference%' LIMIT 1];                                                                       
        Apttus_Config2__ProductConfiguration__c oMachineProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        oMachineProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        insert oMachineProductConfiguration;
        configId.add(oMachineProductConfiguration.Id);
        // Machines
        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchy = [SELECT Id,
                                                                            Name
                                                                        FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                        WHERE Name LIKE '%Machines%'LIMIT 1];
        oMachineLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchy.Id;
        oMachineLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oMachineLineItemBundle.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        oMachineLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oMachineLineItemBundle;
        // Services
        Apttus_Config2__LineItem__c oServicesLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Yearly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchyService = [SELECT Id,
                                                                            Name
                                                                        FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                        WHERE Name LIKE '%Services%'LIMIT 1];
        oServicesLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchy.Id;
        oServicesLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oServicesLineItemBundle.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        oServicesLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oServicesLineItemBundle;
        // Options
        Apttus_Config2__LineItem__c oMachineLineItemOption = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Option', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        oMachineLineItemOption.Apttus_Config2__ClassificationId__c = classHierarchy.Id;
        oMachineLineItemOption.Apttus_Config2__LineStatus__c = 'New';
        oMachineLineItemOption.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oMachineLineItemOption.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        insert oMachineLineItemOption;
        // Ingredients
        Apttus_Config2__LineItem__c oIngredientsLineItemBundle = APTS_TestDataFactory.createLineItem(oMachineProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Yearly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchyIngredients = [SELECT Id,
                                                                                    Name
                                                                                FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                                WHERE Name LIKE '%Coffee%'LIMIT 1];
        oIngredientsLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchyIngredients.Id;
        oIngredientsLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oIngredientsLineItemBundle.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        oIngredientsLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oIngredientsLineItemBundle;
        for(Apttus_Config2__LineItem__c lineItem : [SELECT Id,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,
                                                            Apttus_Config2__ClassificationId__c,
                                                            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
                                                            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name,
                                                            Apttus_Config2__LineType__c,
                                                            Apttus_Config2__LineStatus__c,
                                                            Apttus_Config2__BillingPreferenceId__c,
                                                            Apttus_Config2__BillingFrequency__c,
                                                            Apttus_Config2__ProductId__c
                                                            FROM Apttus_Config2__LineItem__c
                                                            WHERE Apttus_Config2__ConfigurationId__c IN: configId]){
                    
            lineItemList.add(lineItem);
        }
            //Map<Id,Map<String,APTS_Billing_Settings__c>> agreementBillingSettingMap = new Map<Id,Map<String,APTS_Billing_Settings__c>>();
            Test.startTest();
            Map<Id,Map<String,APTS_Billing_Settings__c>> agreementBillingSettingMap = APTS_BIRUtils.retrieveBillingSetting(oAgreement.Id);
            for(Apttus_Config2__LineItem__c lineItem : lineItemList){
                  APTS_BIRUtils.overrideBillingFieldsOnLineItem(lineItem,agreementBillingSettingMap);
            }
            Test.StopTest();
    }
     //Test method for setting Billing Key fields for creation of setBillingKeyFieldsOnOrderLineItem 
    static testMethod void overrideBillingFieldsOnLineItem_Order_Test(){
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        List<Id> configId = new List<Id>();
        Product2 oStandaloneProduct = APTS_TestFacade.getStandaloneProduct();
        Product2 oBundleProduct = APTS_TestFacade.getBundleProduct();
        Product2 oOptionProduct = APTS_TestFacade.getOptionProduct();
        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestFacade.getPriceListItem(oStandaloneProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemBundle = APTS_TestFacade.getPriceListItem(oBundleProduct.Id);
        Apttus_Config2__PriceListItem__c oPriceListItemOption = APTS_TestFacade.getPriceListItem(oOptionProduct.Id);
        Apttus_Config2__Order__c oOrder = [SELECT Id,
                                                  Apttus_CMConfig__AgreementId__c,
                                                  Apttus_Config2__BillToAccountId__c,
                                                  Apttus_Config2__PriceListId__c,
                                                  Apttus_Config2__OrderStartDate__c,
                                                  Apttus_Config2__OrderEndDate__c,
                                                  Apttus_Config2__SoldToAccountId__c
                                                FROM Apttus_Config2__Order__c 
                                                WHERE APTS_Name__c LIKE '%TestOrder%' LIMIT 1];  
        Apttus_Config2__BillingPreference__c billpref = [SELECT Id,
                                                            Name,
                                                            Apttus_Config2__BillingInterval__c
                                                        FROM Apttus_Config2__BillingPreference__c 
                                                        WHERE Name LIKE '%Test Preference%' LIMIT 1];                          
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oOrder);
        oProductConfiguration.Apttus_Config2__BusinessObjectType__c = 'Order';
        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oOrder.Apttus_CMConfig__AgreementId__c;
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.Id;
        insert oProductConfiguration;
        configId.add(oProductConfiguration.Id);
        
        // Machines
        Apttus_Config2__LineItem__c oMachineLineItemBundle = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemBundle.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchy = [SELECT Id,
                                                                            Name
                                                                        FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                        WHERE Name LIKE '%Machines%'LIMIT 1];
        oMachineLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchy.Id;
        oMachineLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oMachineLineItemBundle.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        oMachineLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oMachineLineItemBundle;
        
        // Services
        Apttus_Config2__LineItem__c oServicesLineItemBundle = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Yearly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchyService = [SELECT Id,
                                                                            Name
                                                                        FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                        WHERE Name LIKE '%Services%'LIMIT 1];
        oServicesLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchy.Id;
        oServicesLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oServicesLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oServicesLineItemBundle;
        
        // Options
        Apttus_Config2__LineItem__c oMachineLineItemOption = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemOption.Id, NULL, oBundleProduct.Id, NULL, NULL, 1, 1, 2, 'Option', NULL, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        insert oMachineLineItemOption;
        // Ingredients
        Apttus_Config2__LineItem__c oIngredientsLineItemBundle = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 2, 'Product/Service', NULL, 'Yearly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        Apttus_Config2__ClassificationHierarchy__c classHierarchyIngredients = [SELECT Id,
                                                                                    Name
                                                                                FROM Apttus_Config2__ClassificationHierarchy__c 
                                                                                WHERE Name LIKE '%Coffee%'LIMIT 1];
        oIngredientsLineItemBundle.Apttus_Config2__ClassificationId__c = classHierarchyIngredients.Id;
        oIngredientsLineItemBundle.Apttus_Config2__BillingPreferenceId__c = billpref.Id;
        oIngredientsLineItemBundle.Apttus_Config2__BillingFrequency__c = billpref.Apttus_Config2__BillingInterval__c;
        oIngredientsLineItemBundle.Apttus_Config2__LineStatus__c = 'New';
        insert oIngredientsLineItemBundle;
        for(Apttus_Config2__LineItem__c lineItem : [SELECT Id,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,
                                                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,
                                                            Apttus_Config2__ClassificationId__c,
                                                            Apttus_Config2__LineStatus__c,
                                                            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
                                                            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name,
                                                            Apttus_Config2__BillingPreferenceId__c,
                                                            Apttus_Config2__BillingFrequency__c,
                                                            Apttus_Config2__LineType__c,
                                                            Apttus_Config2__ProductId__c
                                                            FROM Apttus_Config2__LineItem__c
                                                            WHERE Apttus_Config2__ConfigurationId__c IN: configId]){
                    
            lineItemList.add(lineItem);
        }
        Test.startTest();
        Map<Id,Apttus_Config2__Order__c> orderAgreementMap = APTS_BIRUtils.retrieveAgreement(oOrder.Id);
        Map<Id,Map<String,APTS_Billing_Settings__c>> agreementBillingSettingMap = APTS_BIRUtils.retrieveBillingSetting(orderAgreementMap.get(oOrder.Id).Id);
        for(Apttus_Config2__LineItem__c lineItem : lineItemList){
            APTS_BIRUtils.overrideBillingFieldsOnLineItem(lineItem,agreementBillingSettingMap);
        }
        APTS_BIRUtils.retrieveBillingSetting(null);
        Test.StopTest();
    }
    // Test Method for Standard Order
    static testMethod void setInvoiceDataStandardOrder() {

        Apttus_Config2__Order__c oOrder = [SELECT Id,
                                                APTS_Order_Type__c,APTS_Order_Sub_Type__c,
                                                APTS_InvoiceType__c,
                                                Apttus_CMConfig__AgreementId__c,
                                                Apttus_Config2__BillToAccountId__c,
                                                Apttus_Config2__PriceListId__c,
                                                Apttus_Config2__OrderStartDate__c,
                                                Apttus_Config2__OrderEndDate__c,
                                                APTS_Invoice_List_Indicator__c,
                                                APTS_Collective_Billing_Indicator__c,
                                                Apttus_Config2__ActivatedDate__c,APTS_Boomerang_Invoicing__c,
                                                Apttus_Config2__SoldToAccountId__c
                                            FROM Apttus_Config2__Order__c 
                                            WHERE APTS_Name__c LIKE '%TestOrderStandard%' LIMIT 1]; 
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,
                                                        Apttus__Account__c,
                                                        Apttus__Contract_Start_Date__c,
                                                        Apttus__Contract_End_Date__c,
                                                        Apttus_CMConfig__PriceListId__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c,
                                                        APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%LineItemTestAgreement%' LIMIT 1];
        Test.startTest();
        APTS_BIRUtils.setInvoiceData(oAgreement,oOrder);
        APTS_BIRUtils.setInvoiceDataForDB(oAgreement,oOrder);
        Test.stopTest();
    }
    // Test Method for Machine Order
    static testMethod void setInvoiceDataMachineOrder() {
        Apttus_Config2__Order__c oOrder = [SELECT Id,
                                                APTS_Order_Type__c,APTS_Order_Sub_Type__c,APTS_Boomerang_Invoicing__c,
                                                APTS_InvoiceType__c,
                                                Apttus_CMConfig__AgreementId__c,
                                                Apttus_Config2__BillToAccountId__c,
                                                Apttus_Config2__PriceListId__c,
                                                Apttus_Config2__OrderStartDate__c,
                                                Apttus_Config2__OrderEndDate__c,
                                                APTS_Invoice_List_Indicator__c,
                                                APTS_Collective_Billing_Indicator__c,
                                                Apttus_Config2__SoldToAccountId__c
                                                FROM Apttus_Config2__Order__c 
                                                WHERE APTS_Name__c LIKE '%TestOrderMachine%' LIMIT 1];
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id,
                                                        Name,Apttus__Status__c,
                                                        Apttus__Account__c,
                                                        Apttus__Contract_Start_Date__c,
                                                        Apttus__Contract_End_Date__c,
                                                        Apttus_CMConfig__PriceListId__c,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c,APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%LineItemTestAgreement%' LIMIT 1];
        Test.startTest();
        APTS_BIRUtils.setInvoiceData(oAgreement,oOrder);
        APTS_BIRUtils.setInvoiceDataForDB(oAgreement,oOrder);
        Test.stopTest();
    }
    /// Test Method for Machine Order
    static testMethod void setInvoiceDataWithoutAgreement() {
        Apttus_Config2__Order__c oOrder = [SELECT Id,
                                                APTS_Order_Type__c,
                                                Apttus_Config2__BillToAccountId__c,
                                                Apttus_Config2__PriceListId__c,
                                                Apttus_Config2__OrderStartDate__c,
                                                Apttus_Config2__OrderEndDate__c,
                                                Apttus_Config2__ActivatedDate__c,
                                                Apttus_Config2__SoldToAccountId__c
                                                //APTS_Invoice_List_Indicator__c,
                                                //APTS_Collective_Billing_Indicator__c
                                                FROM Apttus_Config2__Order__c 
                                                WHERE APTS_Name__c LIKE 'TestOrderStandard' LIMIT 1];
        Account oAccount = [SELECT Id,
                                    Apttus_Config2__BillingPreferenceId__c,
                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                    Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Apttus_Config2__PaymentTermId__c,
                                    APTS_Payment_Method__c,
                                    Related_Bill_to_Machines_Services__c,Related_Payer_Machines_Services__c,
                                    Bill_To_Payer_Account__c,Related_Payer_Account__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__PaymentTermId__c,
                                    Related_Bill_to_Machines_Services__r.APTS_Payment_Method__c,
                                    Related_Bill_to_Machines_Services__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Related_Bill_to_Machines_Services__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c,
                                    Bill_To_Payer_Account__r.APTS_Payment_Method__c,
                                    Bill_To_Payer_Account__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,
                                    Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c
                            FROM Account 
                            WHERE Name LIKE '%Test%' LIMIT 1];
        Test.startTest();
        APTS_BIRUtils.setInvoiceData(oAccount,oOrder);
        Test.stopTest();
    }

    static testMethod void assignBillingDateToOrderTestMethod(){
      Map<Id, Apttus_Config2__BillingPreference__c> billPrefMap = new Map<Id, Apttus_Config2__BillingPreference__c>();
      List<Apttus_Config2__BillingPreference__c> billPref = [SELECT Id,
                                                                Name,
                                                                Apttus_Config2__BillingInterval__c,
                                                                Apttus_Config2__BillingCycleStart__c,
                                                                Apttus_Config2__BillingDayOfMonth2__c 
                                                    FROM Apttus_Config2__BillingPreference__c 
                                                    WHERE Name LIKE '%Test Preference%' LIMIT 1];
      for(Apttus_Config2__BillingPreference__c billprf : billPref){
            billPrefMap.put(billprf.Id,billprf);
      }                                                    
      Apttus_Config2__Order__c oOrder = [SELECT Id,
                                                APTS_Order_Type__c,
                                                APTS_InvoiceType__c,
                                                Apttus_CMConfig__AgreementId__c,
                                                Apttus_Config2__BillToAccountId__c,
                                                Apttus_Config2__PriceListId__c,
                                                Apttus_Config2__OrderStartDate__c,
                                                Apttus_Config2__OrderEndDate__c,
                                                APTS_Invoice_List_Indicator__c,
                                                APTS_Order_Sub_Type__c,
                                                APTS_Collective_Billing_Indicator__c,
                                                Apttus_Config2__ActivatedDate__c,
                                                Apttus_Config2__BillingPreferenceId__c,
                                                APTS_SAP_OrderType__c
                                                FROM Apttus_Config2__Order__c 
                                                WHERE APTS_Name__c LIKE '%TestOrderMachine%' LIMIT 1];                                              
      Test.startTest();
        APTS_BIRUtils.assignBillingDateToOrder(billPrefMap,oOrder);
        oOrder.APTS_SAP_OrderType__c = 'XC01';
        Database.update(oOrder);
        APTS_BIRUtils.assignBillingDateToOrder(billPrefMap,oOrder);
        Test.stopTest();
    }
    // Test Method for Fixed Order
    static testMethod void removeBillingBlockForStandardOrdersTestMethod(){
    List<Apttus_Config2__Order__c> lstOldOrder = new List<Apttus_Config2__Order__c>();
    Map<Id, Apttus_Config2__Order__c> mapNewOrder = new Map<Id, Apttus_Config2__Order__c>();
    Map<Id, Apttus_Config2__Order__c> mapOldOrder = new Map<Id, Apttus_Config2__Order__c>();
    List<Apttus_Config2__Order__c> lstNewOrder = new List<Apttus_Config2__Order__c>();
    Apttus__APTS_Agreement__c testAgreement = [SELECT Id,
                                                        Name,
                                                        APTS_Bill_to_Party_Ingredients__c,
                                                        APTS_Bill_to_Party_MachServ__c 
                                                    FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%Test %' LIMIT 1];
    testAgreement.APTS_Fixed_Term_Type__c = 'Fixed Cost';
    Database.update(testAgreement); 
    List<Apttus_Config2__BillingPreference__c> billPref = [SELECT Id,
                                                                Name,
                                                                Apttus_Config2__BillingInterval__c,
                                                                Apttus_Config2__BillingCycleStart__c,
                                                                Apttus_Config2__BillingDayOfMonth2__c 
                                                    FROM Apttus_Config2__BillingPreference__c 
                                                    WHERE Name LIKE '%Test Preference%' LIMIT 2];                                                      
    Apttus_Config2__Order__c oOrder = [SELECT Id,
                                        APTS_Order_Type__c,
                                        Apttus_Config2__BillToAccountId__c,
                                        Apttus_Config2__PriceListId__c,
                                        Apttus_Config2__OrderStartDate__c,
                                        Apttus_Config2__OrderEndDate__c,
                                        Apttus_Config2__Status__c,
                                        APTS_Fix_Term_Billing_Flag__c,
                                        APTS_Remove_Billing_Block_Indicator__c
                                        FROM Apttus_Config2__Order__c 
                                        WHERE APTS_Name__c LIKE '%TestOrder%' LIMIT 1];
        lstOldOrder.add(oOrder);
        mapOldOrder.put(oOrder.Id,oOrder);
        Apttus_Config2__Order__c oOrderNew = [SELECT Id,
                                                    APTS_Order_Type__c,
                                                    Apttus_Config2__BillToAccountId__c,
                                                    Apttus_Config2__PriceListId__c,
                                                    Apttus_Config2__OrderStartDate__c,
                                                    Apttus_Config2__OrderEndDate__c,
                                                    Apttus_Config2__Status__c,
                                                    APTS_Fix_Term_Billing_Flag__c,
                                                    APTS_Remove_Billing_Block_Indicator__c,
                                                    APTS_SAP_OrderType__c,
                                                    Apttus_Config2__BillingPreferenceId__c
                                                    FROM Apttus_Config2__Order__c 
                                                    WHERE APTS_Name__c LIKE '%TestOrder%' LIMIT 1];
        oOrderNew.Apttus_Config2__Status__c = 'Activated';
        oOrderNew.Apttus_Config2__ActivatedDate__c = System.today();
        oOrderNew.APTS_SAP_OrderType__c = 'XD01';
        oOrderNew.Apttus_Config2__BillingPreferenceId__c = billPref[0].Id;
        Database.Update(oOrderNew);
        lstNewOrder.add(oOrderNew);
        mapNewOrder.put(oOrderNew.Id, oOrderNew);
        Test.startTest();
        APTS_BIRUtils.removeBillingBlockForStandardOrders(lstNewOrder,mapNewOrder,lstOldOrder,mapOldOrder);
        oOrderNew.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
        Database.Update(oOrderNew);
        update lstNewOrder;
        update mapNewOrder.values();
        APTS_BIRUtils.removeBillingBlockForStandardOrders(lstNewOrder,mapNewOrder,lstOldOrder,mapOldOrder);
        Test.stopTest();
    }
    // Test Method for Standard/Machine Order
    static testMethod void removeBillingBlockForStandardOrdersTestMethod1(){
    List<Apttus_Config2__Order__c> lstOldOrder = new List<Apttus_Config2__Order__c>();
    Map<Id, Apttus_Config2__Order__c> mapNewOrder = new Map<Id, Apttus_Config2__Order__c>();
    Map<Id, Apttus_Config2__Order__c> mapOldOrder = new Map<Id, Apttus_Config2__Order__c>();
    List<Apttus_Config2__Order__c> lstNewOrder = new List<Apttus_Config2__Order__c>();
    Apttus_Config2__Order__c oOrder = [SELECT Id,
                                        APTS_Order_Type__c,
                                        Apttus_Config2__BillToAccountId__c,
                                        Apttus_Config2__PriceListId__c,
                                        Apttus_Config2__OrderStartDate__c,
                                        Apttus_Config2__OrderEndDate__c,
                                        Apttus_Config2__Status__c,
                                        APTS_Fix_Term_Billing_Flag__c,
                                        APTS_Remove_Billing_Block_Indicator__c
                                        FROM Apttus_Config2__Order__c 
                                        WHERE APTS_Name__c LIKE '%TestOrder1%' LIMIT 1];
        lstOldOrder.add(oOrder);
        mapOldOrder.put(oOrder.Id,oOrder);
        Apttus_Config2__Order__c oOrderNew = [SELECT Id,
                                                    APTS_Order_Type__c,
                                                    Apttus_Config2__BillToAccountId__c,
                                                    Apttus_Config2__PriceListId__c,
                                                    Apttus_Config2__OrderStartDate__c,
                                                    Apttus_Config2__OrderEndDate__c,
                                                    Apttus_Config2__Status__c,
                                                    APTS_Fix_Term_Billing_Flag__c,
                                                    APTS_Remove_Billing_Block_Indicator__c
                                                    FROM Apttus_Config2__Order__c 
                                                    WHERE APTS_Name__c LIKE '%TestOrder1%' LIMIT 1];
        oOrderNew.Apttus_Config2__Status__c = 'Activated';
        oOrderNew.APTS_SAP_OrderType__c = 'XC01';
        Database.Update(oOrderNew);
        lstNewOrder.add(oOrderNew);
        mapNewOrder.put(oOrderNew.Id, oOrderNew);
        Test.startTest();
        APTS_BIRUtils.removeBillingBlockForStandardOrders(lstNewOrder,mapNewOrder,lstOldOrder,mapOldOrder);
        Test.stopTest();
    }
    static testMethod void logErrorTestMethodForInsert(){
    Test.startTest();
    List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
    Apttus_Config2__Order__c oOrderNew = [SELECT Id,
                                                    APTS_Order_Type__c,
                                                    Apttus_Config2__BillToAccountId__c,
                                                    Apttus_Config2__PriceListId__c,
                                                    Apttus_Config2__OrderStartDate__c,
                                                    Apttus_Config2__OrderEndDate__c,
                                                    Apttus_Config2__Status__c,
                                                    APTS_Fix_Term_Billing_Flag__c,
                                                    APTS_Distribution_Channel__c,
                                                    APTS_Remove_Billing_Block_Indicator__c
                                                    FROM Apttus_Config2__Order__c 
                                                    WHERE APTS_Name__c LIKE '%TestOrderForInsert%' LIMIT 1];
    oOrderNew.APTS_Distribution_Channel__c = 'SAP_40';  
    orderList.add(oOrderNew);                                             
    Database.SaveResult[] insertedList = Database.update(orderList,false);
    APTS_BIRUtils.logError(null,insertedList,null,null,APTS_BIRUtils.APEX,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
    Test.stopTest();
    }
    
    
    
    static testMethod void logErrorTestMethodForUpsert(){
    Test.startTest();
    List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
    Apttus_Config2__PriceList__c priceList = [SELECT Id
                                                    FROM Apttus_Config2__PriceList__c 
                                                    WHERE Name LIKE '%JDE Price List%' LIMIT 1];
    Account account = [SELECT Id
                                FROM Account 
                                WHERE Name LIKE '%Test%' LIMIT 1];
    Apttus__APTS_Agreement__c lineItemTestAgreement1 = [SELECT Id
                                                            FROM Apttus__APTS_Agreement__c 
                                                            WHERE Name LIKE '%LineItemTestAgreement%' LIMIT 1];
    Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(account.Id,priceList.id, NULL);
    order.Apttus_CMConfig__AgreementId__c = lineItemTestAgreement1.Id;
    order.APTS_Name__c = 'TestOrderForInsert';
    order.Apttus_Config2__Status__c ='Draft';
    order.APTS_Order_Type__c = 'Standard Order';
    order.APTS_Remove_Billing_Block_Indicator__c = false;
    order.APTS_Distribution_Channel__c = 'SAP_90';
    orderList.add(order);
    Apttus_Config2__Order__c oOrderNew = [SELECT Id,
                                                    APTS_Order_Type__c,
                                                    Apttus_Config2__BillToAccountId__c,
                                                    Apttus_Config2__PriceListId__c,
                                                    Apttus_Config2__OrderStartDate__c,
                                                    Apttus_Config2__OrderEndDate__c,
                                                    Apttus_Config2__Status__c,
                                                    APTS_Fix_Term_Billing_Flag__c,
                                                    APTS_Distribution_Channel__c,
                                                    APTS_Remove_Billing_Block_Indicator__c
                                                    FROM Apttus_Config2__Order__c 
                                                    WHERE APTS_Name__c LIKE '%TestOrderForInsert%' LIMIT 1];
    oOrderNew.APTS_Distribution_Channel__c = 'SAP_40';
    orderList.add(oOrderNew);                                               
    Database.UpsertResult[] upsertList = Database.Upsert(orderList,false);
    APTS_BIRUtils.logError(null,null,upsertList,null,APTS_BIRUtils.APEX,APTS_BIRUtils.SUBMITORDER,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
    Test.stopTest();
    }

    static testMethod void addLeadingZerosTestMethod(){

        String salesDocumentNumber ='1234';
        Integer maxlength = 10;
        Test.startTest();
        APTS_BIRUtils.addLeadingZeros(salesDocumentNumber,maxLength);
        Test.stopTest();
    }
    }