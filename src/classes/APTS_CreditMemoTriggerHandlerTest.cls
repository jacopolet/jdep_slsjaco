/******************************************************************************************************
Name            : APTS_CreditMemoTriggerHandlerTest
Created By      : Balashanthi A
Created Date    : 03.03.2018
Description     : Class which will create test data and will test APTS_CreditMemoTriggerHandler Class
Version history : v1.0 
Classes Covered : APTS_CreditMemoTriggerHandler (92% code coverage)
********************************************************************************************************/
@isTest
public with sharing class APTS_CreditMemoTriggerHandlerTest {

    public static List<Apttus_Billing__CreditMemo__c> creditMemoList = new List<Apttus_Billing__CreditMemo__c>();
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    @testSetup
    static void setupTestData(){
        // Trigger Settings
        TriggerSettings__c oTriggerSettings = new TriggerSettings__c(APTS_Credit_Memo_Trigger__c = false);
        Database.insert(oTriggerSettings);

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
        Database.Insert(paymentTerm);
        // Create Account - Test Data 1
        Account testAccount = APTS_TestDataFactory.createAccount('Test Account');
        testAccount.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        testAccount.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        testAccount.APTS_Payment_Method__c = paymentMethod.Id;
        testAccount.Sales_Organization__c = 'SAP_0333';
        testAccount.Division__c = 'SAP_20';
        testAccount.Distribution_Channel__c = 'SAP_10';
        Database.insert(testAccount, false);
        // Create Contact
        Contact contact = new Contact(FirstName = 'Test1',
                                    LastName ='UUUU',
                                    AccountId = testAccount.Id,
                                    Main_Service_Person__c = true,
                                    Main_Commercial_Person__c = true);
        insert contact;
        // Create Account Location
        Apttus_Config2__AccountLocation__c accountLocation = new Apttus_Config2__AccountLocation__c(Name='Test Loc', Apttus_Config2__AccountId__c = testAccount.id, Customer_calendar_key__c = 'SAP_01');
        Database.insert(accountLocation);
        //Create Product
        Product2 prod = APTS_TestDataFactory.createProduct('TestCoffee', '123', 'Machines', 'Standalone', true, false);
        Database.Insert(prod, false);
        // Create PriceList
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
        oPricelist.APTS_PriceList_Type__c ='Direct';
        oPricelist.APTS_Region__c = 'SAP_0333';
        Database.insert(oPricelist, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod.Id);
        //pli1.APTS_Sales_Org__c = 'SAP_0333';
        pli1.Apttus_Config2__ChargeType__c = 'Sales Price';
        Database.insert(pli1, FALSE);

        // Create Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(contact.Id, oPricelist.Id, testAccount.Id, 'Standard Deal');
        oAgr.Apttus__Term_Months__c = 12;
        oAgr.APTS_Fixed_Term_Type__c = 'Fixed Cost';
        oAgr.Apttus_CMConfig__PONumber__c ='456734';
        oAgr.Apttus__Status_Category__c = IN_EFFECT;
        oAgr.Apttus__Status__c = ACTIVATED;
        oAgr.Apttus__Version_Number__c = 1;
        Database.insert(oAgr, FALSE);
        
        APTS_Billing_Settings__c billsetting1 = APTS_TestUtils.createBillingSetting(oAgr.Id,testAccount.Id,billingPreference.Id,paymentMethod.Id,paymentTerm.Id);
            billsetting1.APTS_Agreement_Billing_Type__c ='Ingredients';
            billsetting1.APTS_Invoice_Delivery_Preference__c = 'P001';
            insert billsetting1;
            
        // Create invoice
        List<Apttus_Billing__Invoice__c> bill = new List<Apttus_Billing__Invoice__c>();
        Apttus_Billing__Invoice__c invoice = APTS_TestUtils.createInvoice(testAccount.id);
        invoice.APTS_External_Invoice_Number__c = '123490999';
        bill.add(invoice); 
        Apttus_Billing__Invoice__c invoice1 = APTS_TestUtils.createInvoice(testAccount.id);
        invoice1.APTS_External_Invoice_Number__c = '9876543422';
        bill.add(invoice1);
        insert bill;        
       
        // Create Admin Order
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(testAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.APTS_InvoiceDeliveryPreference__c = 'Email';
        order.APTS_Invoice_List_Indicator__c =' No';
        order.APTS_Order_Sub_Type__c = 'Billing Schedule';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.Apttus_Config2__PrimaryContactId__c = contact.Id;
        order.APTS_InvoiceType__c = 'Single Invoice';
        order.APTS_Collective_Billing_Indicator__c = false;
        order.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.APTS_Payment_Method__c = paymentMethod.Id;
        order.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        order.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        order.Apttus_Config2__PriceListId__c = oPricelist.Id;
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.Apttus_Config2__SoldToAccountId__c = testAccount.Id;
        order.Apttus_Config2__BillToAccountId__c = testAccount.Id;
        order.APTS_Bill_to_Party_Ingredients_and_Payer__c = testAccount.Id;
        order.APTS_Bill_to_Party_Machines_Services__c = testAccount.Id;
        order.APTS_Payer__c = testAccount.Id;
        order.APTS_PayerIngredients__c = testAccount.Id;
        order.APTS_PayerMachinesServices__c = testAccount.Id;
        order.APTS_Order_Header_SAP_ID__c = '6543829812';
        order.Apttus_Config2__OrderStartDate__c = system.today();
        order.Apttus_Config2__PricingDate__c = system.today();
        order.APTS_Fix_Term_Billing_Flag__c = 'Z';
        order.Apttus_Config2__PONumber__c= '12345';
        order.APTS_Sales_Organization__c = 'SAP_0333';
        order.APTS_Distribution_Channel__c = 'SAP_10';
        order.APTS_Division__c = 'SAP_20';
        order.APTS_SAP_OrderType__c = 'XD09';
        order.Apttus_Config2__Description__c = 'Test CMR';
        //order.APTS_Order_Reason__c = 'X00';
        order.APTS_Invoice__c = invoice.Id;
        order.Apttus_Config2__SoldToAccountId__c = testAccount.Id;
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert order;
        // Create Standard Order
        Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(testAccount.Id,oPricelist.id, NULL);
        order1.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order1.APTS_Name__c = 'TestADminOrder';
        order1.Apttus_Config2__Status__c ='Activated';
        order1.APTS_InvoiceDeliveryPreference__c = 'Email';
        order1.APTS_Invoice_List_Indicator__c =' No';
        order1.APTS_Order_Sub_Type__c = 'Billing Schedule';
        order1.APTS_Remove_Billing_Block_Indicator__c = true;
        order1.Apttus_Config2__PrimaryContactId__c = contact.Id;
        order1.APTS_InvoiceType__c = 'Single Invoice';
        order1.APTS_Collective_Billing_Indicator__c = false;
        order1.APTS_Status__c = 'Sent For Invoicing';
        order1.APTS_Order_Type__c = 'Standard Order';
        order1.APTS_Payment_Method__c = paymentMethod.Id;
        order1.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        order1.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        order1.Apttus_Config2__PriceListId__c = oPricelist.Id;
        order1.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order1.Apttus_Config2__SoldToAccountId__c = testAccount.Id;
        order1.Apttus_Config2__BillToAccountId__c = testAccount.Id;
        order1.APTS_Bill_to_Party_Ingredients_and_Payer__c = testAccount.Id;
        order1.APTS_Bill_to_Party_Machines_Services__c = testAccount.Id;
        order1.APTS_Payer__c = testAccount.Id;
        order1.APTS_PayerIngredients__c = testAccount.Id;
        order1.APTS_PayerMachinesServices__c = testAccount.Id;
        order1.APTS_Order_Header_SAP_ID__c = '6543829815';
        order1.Apttus_Config2__OrderStartDate__c = system.today();
        order1.Apttus_Config2__PricingDate__c = system.today();
        order1.APTS_Fix_Term_Billing_Flag__c = 'Z';
        order1.Apttus_Config2__PONumber__c= '12345';
        order1.APTS_Sales_Organization__c = 'SAP_0333';
        order1.APTS_Distribution_Channel__c = 'SAP_10';
        order1.APTS_Division__c = 'SAP_20';
        order1.APTS_SAP_OrderType__c = 'XA13';
        order1.Apttus_Config2__Description__c = 'Test CMR';
        //order.APTS_Order_Reason__c = 'X00';
        order1.APTS_Invoice__c = invoice1.Id;
        order1.Apttus_Config2__SoldToAccountId__c = testAccount.Id;
        order1.APTS_Remove_Billing_Block_Indicator__c = true;
        order1.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        
        insert order1;
        
        
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c ='000010',
                                                                                                Apttus_Config2__ProductId__c = prod.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id);
        orderLineItemList.add(orderLineItem1);
        Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod.Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c ='000020',
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id);
        orderLineItemList.add(orderLineItem2);
        Apttus_Config2__OrderLineItem__c orderLineItem3 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c ='000030',
                                                                                                Apttus_Config2__ProductId__c = prod.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order1.Id);
        orderLineItemList.add(orderLineItem3);
        Apttus_Config2__OrderLineItem__c orderLineItem4 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod.Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c ='000040',
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order1.Id);
        orderLineItemList.add(orderLineItem4);
        insert orderLineItemList;
        

        // Asset Adjustment Line Item creation
        List<Apttus_Config2__OrderAdjustmentLineItem__c> orderAdjustmentList = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
        for(Integer i = 0; i < 2; i++){
        Apttus_Config2__OrderAdjustmentLineItem__c orderAdjustment = new Apttus_Config2__OrderAdjustmentLineItem__c(Apttus_Config2__AdjustmentAmount__c = 40.00,
                                                                                                Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1',
                                                                                                Apttus_Config2__AdjustmentType__c = '% Discount',
                                                                                                Apttus_Config2__AdjustmentUom__c = 'SAP_PCE',
                                                                                                Apttus_Config2__BenefitQuantity__c = 1,
                                                                                                Apttus_Config2__Bucket__c = 'Bucket 1',
                                                                                                Apttus_Config2__CouponCode__c = 'CXPW',
                                                                                                Apttus_Config2__IncentiveCode__c = 'VWPSK',
                                                                                                Apttus_Config2__LineType__c = 'Manual',
                                                                                                Apttus_Config2__LineItemId__c = orderLineItemList[i].Id,
                                                                                                Apttus_Config2__IncentiveAdjustmentAmount__c = 10.00,
                                                                                                Apttus_Config2__LineNumber__c = i,
                                                                                                Apttus_Config2__SubType__c = 'ZP06',
                                                                                                Apttus_Config2__Type__c = 'PPR'
                                                                                                );
        orderAdjustmentList.add(orderAdjustment);
        }
        insert orderAdjustmentList;
   
        //Create Invoice Line Item for admin order
        Apttus_Billing__InvoiceLineItem__c invoiceLineItem1 = APTS_TestUtils.createInvoiceLineItem(invoice.Id);
        invoiceLineItem1.APTS_AdminOrder_Line__c = orderLineItemList[0].id;
        invoiceLineItem1.APTS_RefOrderNumber__c ='6543829812';
        invoiceLineItem1.APTS_RefOrderLineNumber__c = '000010';
        Database.insert(invoiceLineItem1);
        Apttus_Billing__InvoiceLineItem__c invoiceLineItem2 = APTS_TestUtils.createInvoiceLineItem(invoice.Id);
        invoiceLineItem2.APTS_AdminOrder_Line__c = orderLineItemList[1].id;
        invoiceLineItem2.APTS_RefOrderNumber__c ='6543829812';
        invoiceLineItem2.APTS_RefOrderLineNumber__c = '000020';
        Database.insert(invoiceLineItem2);
        
        //Create Invoice Line Item for standard order
        Apttus_Billing__InvoiceLineItem__c invoiceLineItem3 = APTS_TestUtils.createInvoiceLineItem(invoice1.Id);
        invoiceLineItem3.APTS_Order_Line__c= orderLineItemList[2].id;
        invoiceLineItem3.APTS_RefOrderNumber__c ='6543829815';
        invoiceLineItem3.APTS_RefOrderLineNumber__c = '000030';
        Database.insert(invoiceLineItem3);
        Apttus_Billing__InvoiceLineItem__c invoiceLineItem4 = APTS_TestUtils.createInvoiceLineItem(invoice1.Id);
        invoiceLineItem4.APTS_Order_Line__c = orderLineItemList[3].id;
        invoiceLineItem4.APTS_RefOrderNumber__c ='6543829815';
        invoiceLineItem4.APTS_RefOrderLineNumber__c = '000040';
        Database.insert(invoiceLineItem4);
        
        
        
        // Create Case
        Case casecreation = APTS_TestUtils.createcase(testAccount.id);
        Database.insert(casecreation);
        // Create Credit Memo
        Apttus_Billing__CreditMemo__c creditMemo = APTS_TestUtils.createCreditMemo(testAccount.Id, invoice.Id, accountLocation.id, null);
        creditMemo.APTS_Sold_To_Account__c = testAccount.Id;
        creditMemo.APTS_Credit_Contract__c = oAgr.Id; 
        creditMemoList.add(creditMemo);
        Apttus_Billing__CreditMemo__c creditMemo1 = APTS_TestUtils.createCreditMemo(testAccount.Id, null, accountLocation.id,casecreation.id);
        creditMemoList.add(creditMemo1);
        Apttus_Billing__CreditMemo__c creditMemo2 = APTS_TestUtils.createCreditMemo(testAccount.Id, null, accountLocation.id,casecreation.id);
        creditMemo2.APTS_Sold_To_Account__c = testAccount.Id;
        creditMemoList.add(creditMemo2);
        Apttus_Billing__CreditMemo__c creditMemo3 = APTS_TestUtils.createCreditMemo(testAccount.Id, invoice1.Id, accountLocation.id, null);
        creditMemo3.APTS_Sold_To_Account__c = testAccount.Id;
        creditMemo3.APTS_Credit_Contract__c = oAgr.Id; 
        creditMemoList.add(creditMemo3);
        Database.insert(creditMemoList);
        //Create Credit Memo Line Item
        List<Apttus_Billing__CreditMemoLineItem__c> creditMemoLineList = new List<Apttus_Billing__CreditMemoLineItem__c>();
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem = APTS_TestUtils.createcreditMemoLineItem(creditMemo.Id,prod.id);
        creditMemoLineItem.Apttus_Billing__InvoiceLineItemId__c= invoiceLineItem1.Id;
        creditMemoLineList.add(creditMemoLineItem);
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem1 = APTS_TestUtils.createcreditMemoLineItem(creditMemo1.Id,prod.id);
        creditMemoLineList.add(creditMemoLineItem1);
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem2 = APTS_TestUtils.createcreditMemoLineItem(creditMemo2.Id,prod.id);
        creditMemoLineList.add(creditMemoLineItem2);
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem3 = APTS_TestUtils.createcreditMemoLineItem(creditMemo3.Id,prod.id);
        creditMemoLineItem3.Apttus_Billing__InvoiceLineItemId__c=invoiceLineItem3.Id;
        creditMemoLineList.add(creditMemoLineItem3);
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem4 = APTS_TestUtils.createcreditMemoLineItem(creditMemo3.Id,prod.id);
        creditMemoLineItem4.Apttus_Billing__InvoiceLineItemId__c=invoiceLineItem3.Id;
        creditMemoLineItem4.APTS_BPO__c=true;
        creditMemoLineList.add(creditMemoLineItem4);
        Database.insert(creditMemoLineList);
    }
    /*Test Method to test the classes*/
    @isTest
    private static void creditMemoTriggerHandlerMethods() {
        Test.startTest();
        APTS_CreditMemoTriggerHandler creditMemoTriggerHandler = new APTS_CreditMemoTriggerHandler();
        creditMemoTriggerHandler.isDisabled();
        Account oAccount = [SELECT Id
                                    FROM Account 
                                    WHERE Name LIKE '%Test Account%' LIMIT 1];
        Product2 prod = [SELECT Id
                                    FROM Product2 
                                    WHERE Name LIKE '%TestCoffee%' LIMIT 1];
        List<Apttus_Billing__CreditMemo__c> creditMemoList = new List<Apttus_Billing__CreditMemo__c>();
        for (Apttus_Billing__CreditMemo__c creditMemo : [SELECT Id,
                                                                Apttus_Billing__BillToAccountId__c,
                                                                Apttus_Billing__InvoiceID__c,
                                                                Apttus_Billing__Description__c,
                                                                CurrencyIsoCode,
                                                                Apttus_Billing__LocationId__c,
                                                                Apttus_Billing__CreditMemoDate__c,
                                                                Apttus_Billing__CreditAmount__c,
                                                                Apttus_Billing__ReasonCode__c,
                                                                Apttus_Billing__Status__c,
                                                                Case__c
                                                            FROM Apttus_Billing__CreditMemo__c 
                                                            WHERE Apttus_Billing__BillToAccountId__c =: oAccount.Id ]){
            creditMemo.APTS_Approval_Status__c = 'Approved';
            creditMemoList.add(creditMemo);
        }
       
        Database.update(creditMemoList);
        Test.stopTest();
        List<Apttus_Config2__Order__c> orders = [select id,APTS_SAP_OrderType__c from Apttus_Config2__Order__c where APTS_SAP_OrderType__c='XC01'];
        system.assertEquals(3,orders.size());
    }

    /*Test Method to test the classes*/
    @isTest
    private static void beforeUpdateTestMethod() {
        Apttus_Billing__CreditMemo__c crmemo = [Select id, APTS_LockCreditMemo__c, APTS_Approval_Status__c from Apttus_Billing__CreditMemo__c limit 1][0];
        crmemo.APTS_LockCreditMemo__c = true;
        crmemo.APTS_Approval_Status__c = 'Approval Pending';
        update crmemo;

        Test.startTest();

        crmemo.Apttus_Billing__Description__c = 'Test';
        update crmemo;

        system.assertEquals(crmemo.APTS_LockCreditMemo__c, true);

        Test.stopTest();
    }
}