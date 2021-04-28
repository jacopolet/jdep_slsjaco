/**
* @author        Balashanthi A
* @date          07.07.2018           
* @description   Test class for APTS_InvoiceLineItemTriggerHandler class
* @revision(s)
*/
@isTest
private class APTS_InvoiceLineItemTriggerHandler_Test{
    
    /** Method Name  : testData
    * Description : Test setup method to create test data
    **/
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';
    
    @testSetup
    static void testData(){
        // Trigger Settings
        Database.insert(new TriggerSettings__c(APTS_InvoiceLineItemTrigger__c=false), false);
        
        // Create Order and OLI
        User testUser = APTS_TestFacade.createTestUser();
        //APTS_TestFacade.createMandatoryRecords(testUser);
        //APTS_TestFacade.createAndConfigureOrder(testUser);
        
         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        oAccount.SAP_Customer_ID__c = '12345';
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        prod1.APTS_SAPExtID__c = 'sapprod1';
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        Database.insert(oAgr, FALSE);

        List<Apttus_Config2__Order__c> orderLists = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c machineOrder = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        machineOrder.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        machineOrder.APTS_Name__c = 'TestMachineOrder';
        machineOrder.Apttus_Config2__Status__c ='Activated';
        machineOrder.APTS_Status__c = 'Sent For Invoicing';
        machineOrder.APTS_Order_Type__c = 'Machine Order';
        machineOrder.Apttus_Config2__Status__c = 'Activated';
        machineOrder.APTS_Order_Header_SAP_ID__c ='1234';
        machineOrder.APTS_SAP_OrderType__c = 'XA13';
        machineOrder.APTS_Remove_Billing_Block_Indicator__c = true;
        machineOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        orderLists.add(machineOrder);
       
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.APTS_SAP_OrderType__c = 'XD09';
        order.APTS_Order_Header_SAP_ID__c ='0000001834';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        orderLists.add(order);

        Apttus_Config2__Order__c standardOrder = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        standardOrder.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        standardOrder.APTS_Name__c = 'TestStandardOrder';
        standardOrder.Apttus_Config2__Status__c ='Activated';
        standardOrder.APTS_Status__c = 'Sent For Invoicing';
        standardOrder.APTS_Order_Type__c = 'Standard Order';
        machineOrder.APTS_SAP_OrderType__c = 'XA01';
        standardOrder.APTS_Order_Header_SAP_ID__c ='11291733';
        standardOrder.APTS_Remove_Billing_Block_Indicator__c = true;
        orderLists.add(standardOrder);

        insert orderLists;

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
        // Machine Order Line Starts
        Apttus_Config2__OrderLineItem__c orderLineItem3 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='000010',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(0).Id,
                                                                                                Apttus_Config2__PriceType__c = 'One Time',
                                                                                                Apttus_Config2__BillingFrequency__c = 'One Time');
        orderLineItemList.add(orderLineItem3);
         Apttus_Config2__OrderLineItem__c orderLineItem4 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='20',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(0).Id,
                                                                                                Apttus_Config2__PriceType__c = 'One Time',
                                                                                                Apttus_Config2__BillingFrequency__c = 'One Time');
        orderLineItemList.add(orderLineItem4);

        // Below line will be billed as Original Order Lines
        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(0).Id,
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly');
        orderLineItemList.add(orderLineItem1);
        Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c( Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(0).Id,
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly');
        orderLineItemList.add(orderLineItem2);

        Apttus_Config2__OrderLineItem__c stdOrderLineItem = new Apttus_Config2__OrderLineItem__c(
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(2).Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c='21',
                                                                                                Apttus_Config2__PriceType__c = 'One Time',
                                                                                                Apttus_Config2__BillingFrequency__c = 'One Time');
        orderLineItemList.add(stdOrderLineItem);
       
        insert orderLineItemList;
       // Admin Order Lines Starts
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList1 = new List<Apttus_Config2__OrderLineItem__c>();
        Apttus_Config2__OrderLineItem__c orderLineItem11 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c = orderLineItemList.get(2).Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(1).Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c='000030',
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly');
        orderLineItemList1.add(orderLineItem11);
        Apttus_Config2__OrderLineItem__c orderLineItem21 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c=orderLineItemList.get(3).Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = orderLists.get(1).Id,
                                                                                                APTS_SAP_Order_Line_Item_Number__c='000040',
                                                                                                Apttus_Config2__PriceType__c = 'Recurring',
                                                                                                Apttus_Config2__BillingFrequency__c = 'Monthly');
        orderLineItemList1.add(orderLineItem21);
         insert orderLineItemList1;

        // Billing Schedules
        List< Apttus_Billing__BillingSchedule__c> billingScheduleToinsert = new List<Apttus_Billing__BillingSchedule__c>();

        Apttus_Billing__BillingSchedule__c billingSchedule1 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule1.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLING;
        billingSchedule1.Apttus_Billing__OrderLineItemId__c = orderLineItemList.get(0).Id;
        billingSchedule1.Apttus_Billing__ReadyForInvoiceDate__c = system.today();
        billingScheduleToinsert.add(billingSchedule1);

        Apttus_Billing__BillingSchedule__c billingSchedule2 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule2.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLING;
        billingSchedule2.Apttus_Billing__OrderLineItemId__c = orderLineItemList.get(1).Id;
        billingSchedule2.Apttus_Billing__ReadyForInvoiceDate__c = system.today();
        billingScheduleToinsert.add(billingSchedule2);

        // Admin Order Original Lines =====> Starts
        Apttus_Billing__BillingSchedule__c bilingSch = new Apttus_Billing__BillingSchedule__c();
        bilingSch.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGINVOICED;
        bilingSch.Apttus_Billing__OrderLineItemId__c = orderLineItemList.get(2).Id;
        bilingSch.Apttus_Billing__ReadyForInvoiceDate__c = system.today();
        bilingSch.APTS_Admin_Order_Line__c = orderLineItemList1.get(0).Id;
        billingScheduleToinsert.add(bilingSch);

        Apttus_Billing__BillingSchedule__c billingSchedule3 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule3.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGINVOICED;
        billingSchedule3.Apttus_Billing__OrderLineItemId__c = orderLineItemList.get(3).Id;
        billingSchedule3.Apttus_Billing__ReadyForInvoiceDate__c = system.today();
        billingSchedule3.APTS_Admin_Order_Line__c = orderLineItemList1.get(1).Id;
        billingScheduleToinsert.add(billingSchedule3);
        // Admin Order Original Lines =====> ENDS

        // Standard Order Line item
        Apttus_Billing__BillingSchedule__c billingSchedule5 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule5.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLING;
        billingSchedule5.Apttus_Billing__OrderLineItemId__c = orderLineItemList.get(4).Id;
        billingSchedule5.Apttus_Billing__ReadyForInvoiceDate__c = system.today();
        billingScheduleToinsert.add(billingSchedule5);
        insert billingScheduleToinsert;

        List< Apttus_Billing__Invoice__c> invoiceList = new List<Apttus_Billing__Invoice__c>();
        // Machine Order
        Apttus_Billing__Invoice__c  invoice1 = new Apttus_Billing__Invoice__c();
        invoice1.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invoice1.Apttus_Billing__TotalInvoiceAmount__c = 100;
        invoice1.APTS_External_Invoice_Number__c = '111111';
        invoiceList.add(invoice1); 
        // Admin Order
        Apttus_Billing__Invoice__c  invoice = new Apttus_Billing__Invoice__c();
        invoice.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
        invoice.APTS_External_Invoice_Number__c = '2222';
        invoiceList.add(invoice);

        // standard Order
        Apttus_Billing__Invoice__c  standardOrderInvoice = new Apttus_Billing__Invoice__c();
        standardOrderInvoice.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        standardOrderInvoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
        standardOrderInvoice.APTS_External_Invoice_Number__c = '33333';
        invoiceList.add(standardOrderInvoice);

        insert invoiceList;
        
        //Create Invoice Line Item
        List< Apttus_Billing__InvoiceLineItem__c> invoiceLineList = new List<Apttus_Billing__InvoiceLineItem__c>();
        // invoice for Machcine Order
        Apttus_Billing__InvoiceLineItem__c invLI2 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoiceList.get(0).Id);
        invLI2.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI2.APTS_External_Invoice_Line_Number__c = '111111';
        invLI2.Apttus_Billing__Amount__c = 50;
        invLI2.APTS_RefOrderLineNumber__c = '10';
        invLI2.APTS_Product_SAP_External_Id__c = 'sapprod1';
        invLI2.APTS_RefOrderNumber__c = '1234';
        invLI2.Apttus_Billing__BillingScheduleId__c = billingScheduleToinsert.get(0).Id;
        invLI2.Apttus_Billing__ShipToAccountId__c  = oAccount.Id;
        invoiceLineList.add(invLI2);
        Apttus_Billing__InvoiceLineItem__c invLI3 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoiceList.get(0).Id);
        invLI3.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI3.APTS_External_Invoice_Line_Number__c = '111111';
        invLI3.Apttus_Billing__Amount__c = 50;
        invLI3.APTS_RefOrderLineNumber__c = '20';
        invLI3.APTS_Product_SAP_External_Id__c = 'sapprod1';
        invLI3.Apttus_Billing__BillingScheduleId__c = billingScheduleToinsert.get(1).Id;
        invLI3.APTS_RefOrderNumber__c = '1234';
        invLI3.Apttus_Billing__ShipToAccountId__c  = oAccount.Id;
        invoiceLineList.add(invLI3);

        // Invoice for Admin order
        Apttus_Billing__InvoiceLineItem__c invLI1 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoiceList.get(1).Id);
        invLI1.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI1.APTS_External_Invoice_Line_Number__c = '2222';
        invLI1.Apttus_Billing__Amount__c = 50;
        invLI1.APTS_RefOrderLineNumber__c = '000030';
        invLI1.APTS_RefOrderNumber__c = '1834';
        invLI1.APTS_Product_SAP_External_Id__c = 'sapprod1';
        invLI1.Apttus_Billing__BillingScheduleId__c = billingScheduleToinsert.get(2).Id;
        invLI1.Apttus_Billing__ShipToAccountId__c  = oAccount.Id;
        invoiceLineList.add(invLI1);
        //Create Invoice Line Item
        Apttus_Billing__InvoiceLineItem__c invLI4 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoiceList.get(1).Id);
        invLI4.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI4.APTS_External_Invoice_Line_Number__c = '2222';
        invLI4.Apttus_Billing__Amount__c = 50;
        invLI4.APTS_RefOrderLineNumber__c = '40';
        invLI4.APTS_RefOrderNumber__c = '1834';
        invLI4.APTS_Product_SAP_External_Id__c = 'sapprod1';
        invLI4.Apttus_Billing__BillingScheduleId__c = billingScheduleToinsert.get(3).Id;
        invLI4.Apttus_Billing__ShipToAccountId__c  = oAccount.Id;
        invoiceLineList.add(invLI4);

         //Create Invoice Line Item
        Apttus_Billing__InvoiceLineItem__c invLI5 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c= invoiceList.get(2).Id);
        invLI5.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI5.APTS_External_Invoice_Line_Number__c = '33333';
        invLI5.Apttus_Billing__Amount__c = 50;
        invLI5.APTS_RefOrderLineNumber__c = '21';
        invLI5.APTS_RefOrderNumber__c = '11291733';
        invLI5.APTS_Product_SAP_External_Id__c = 'sapprod1';
        invLI5.Apttus_Billing__BillingScheduleId__c = billingScheduleToinsert.get(4).Id;
        invLI5.Apttus_Billing__ShipToAccountId__c  = oAccount.Id;
        invoiceLineList.add(invLI5);
        insert invoiceLineList;
    }
    
    /** Method Name  : testHandler
    * Description : Test method to test Invoice Line Item Trigger Handler
    **/
    @isTest
    static void testHandler(){
        Test.startTest();
        APTS_InvoiceLineItemTriggerHandler handler = new APTS_InvoiceLineItemTriggerHandler();
        handler.beforeInsert(null);
        handler.beforeUpdate(null, null, null, null);
        handler.beforeDelete(null, null);
        handler.afterUpdate(null, null, null, null);
        handler.afterDelete(null, null);
        handler.afterUndelete(null, null);
        Test.stopTest();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemListtest = new List<Apttus_Config2__OrderLineItem__c>([Select Id from Apttus_Config2__OrderLineItem__c]);
        List<Apttus_Billing__InvoiceLineItem__c>  invoiceLineItemList = [Select Id,APTS_Order_Line__c,Apttus_Billing__InvoiceId__c from Apttus_Billing__InvoiceLineItem__c];
        system.assertEquals(invoiceLineItemList[0].APTS_Order_Line__c ,orderLineItemListtest[0].id);
        /* ---------- Start of PI fix # 918007----------------------- */
        List< Apttus_Billing__BillingSchedule__c> billingScheduletest = new List<Apttus_Billing__BillingSchedule__c>([select id,APTS_Invoice__c from Apttus_Billing__BillingSchedule__c]);
        system.assertEquals(invoiceLineItemList[0].Apttus_Billing__InvoiceId__c,billingScheduletest[0].APTS_Invoice__c);
        /* ---------- End of PI fix # 918007----------------------- */
    }

}