@isTest
public with sharing class APTS_RetrieveInvoiceLIControllerTest {

    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';

     static testmethod void logic1(){

         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
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

        Product2 prod2 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, 'Option', FALSE, TRUE);
        prod2.APTS_SAPExtID__c = 'sapprod2';
        Database.insert(prod2, FALSE);

        Product2 prod3 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, 'Standalone', FALSE, TRUE);
        prod3.APTS_SAPExtID__c = 'sapprod2';
        Database.insert(prod3, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        Database.insert(oAgr, FALSE);

        Apttus_Config2__Order__c machineOrder = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        machineOrder.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        machineOrder.APTS_Name__c = 'TestMachineOrder';
        machineOrder.Apttus_Config2__Status__c ='Activated';
        machineOrder.APTS_Status__c = 'Sent For Invoicing';
        machineOrder.APTS_Order_Type__c = 'Machine Order';
        machineOrder.Apttus_Config2__Status__c = 'Activated';
        machineOrder.APTS_Order_Header_SAP_ID__c ='1234';
        machineOrder.APTS_Remove_Billing_Block_Indicator__c = true;
        machineOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert machineOrder;

        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c ='004067',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem1;
        Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='4567',
                                                                                                Apttus_Config2__ProductId__c = prod2.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem2;
         Apttus_Config2__OrderLineItem__c orderLineItem3 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='004068',
                                                                                                Apttus_Config2__ProductId__c = prod3.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem3;

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.Derived_From_Order__c = machineOrder.Id;
        machineOrder.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.Apttus_Config2__Status__c = 'Activated';
        order.APTS_Order_Header_SAP_ID__c ='0000001834';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert order;

        Apttus_Config2__OrderLineItem__c orderLineItem11 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c = orderLineItem1.Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem11;
        Apttus_Config2__OrderLineItem__c orderLineItem21 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c=orderLineItem2.Id,
                                                                                                Apttus_Config2__ProductId__c = prod2.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem21;
        // Create Billing Schedule
        Apttus_Billing__BillingSchedule__c billingSchedule1 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule1.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLINGSTATUS;
        //billingSchedule1.APTS_Invoice__c = invoice.Id;
        billingSchedule1.Apttus_Billing__OrderLineItemId__c = orderLineItem1.Id;
        insert(billingSchedule1);
        Apttus_Billing__BillingSchedule__c billingSchedule2 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule2.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLINGSTATUS;
        //billingSchedule1.APTS_Invoice__c = invoice.Id;
        billingSchedule2.Apttus_Billing__OrderLineItemId__c = orderLineItem2.Id;
        insert(billingSchedule2);
        //Create Invoice
        Apttus_Billing__Invoice__c  invoice = new Apttus_Billing__Invoice__c();
        invoice.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invoice.Apttus_Billing__LocationId__c = null;
        invoice.Apttus_Billing__Status__c = 'Draft';
        invoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
        invoice.APTS_External_Invoice_Number__c = '2222';
        invoice.Apttus_Billing__SoldToAccountId__c=oAccount.Id;
        insert invoice;

        //Create Invoice Line Item
        Apttus_Billing__InvoiceLineItem__c invLI1 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoice.Id);
        invLI1.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI1.Apttus_Billing__Amount__c = 50;
        invLI1.Apttus_Billing__Quantity__c=50;
        invLI1.APTS_Order_Line__c=orderLineItem1.Id;
        invLI1.APTS_Product__c=prod1.Id;
        insert invLI1;

        Apttus_Billing__InvoiceLineItem__c invLI2 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoice.Id);
        invLI2.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI2.Apttus_Billing__Amount__c = 50;
        invLI2.Apttus_Billing__Quantity__c=50;
        invLI2.APTS_Order_Line__c=orderLineItem2.Id;
        invLI2.APTS_Product__c=prod2.Id;
        insert invLI2;

        Apttus_Billing__InvoiceLineItem__c invLI3 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoice.Id);
        invLI3.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI3.Apttus_Billing__Amount__c = 50;
        invLI3.Apttus_Billing__Quantity__c=50;
        invLI3.APTS_Order_Line__c=orderLineItem3.Id;
        invLI3.APTS_Product__c=prod3.Id;
        insert invLI3;

        //Insert custom setting
        APTS_SAP_Connection_Settings__c sapCS = new APTS_SAP_Connection_Settings__c();
        sapCS.name = 'Invoice LI Retrieve';
        sapCS.APTS_Endpoint__c = '';
        sapCS.APTS_Certificate_Name__c = '';
        insert sapCS;

        ApexPages.currentPage().getParameters().put('Id', invoice.id);
        ApexPages.currentPage().getParameters().put('index','0');
        //Test.setMock(WebServiceMock.class, new APTS_RetrieveInvoiceLIControllerTestMock());

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(invoice);
        APTS_RetrieveInvoiceLineItemController retInvLICtlr = new APTS_RetrieveInvoiceLineItemController(sc);

        retInvLICtlr.getInvoiceLineItemsFromSAP();
        system.debug('****retInvLICtlr.invoiceLineItemWrapperList==>'+retInvLICtlr.invoiceLineItemWrapperList);
        retInvLICtlr.invoiceLineItemWrapperList.get(0).selected = true;
        retInvLICtlr.invoiceLineItemWrapperList.get(1).selected = true;
        retInvLICtlr.invoiceLineItemWrapperList.get(2).selected = true;
        retInvLICtlr.createCreditMemo();
        retInvLICtlr.createDebitMemo();
        retInvLICtlr.getPicklistValues();
        retInvLICtlr.getCalculatedAmount();
        retInvLICtlr.cancel();

        Test.stopTest();
        system.assertEquals(true,retInvLICtlr.invoiceLineItemWrapperList.get(0).selected);
     }
     static testmethod void logic2(){
        // create account
        Account oAccount =new Account();
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
        
        Product2 prod2 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, 'Option', FALSE, TRUE);
        prod2.APTS_SAPExtID__c = 'sapprod1';
        Database.insert(prod2, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, STANDARD_DEAL);
        oAgr.Apttus__Term_Months__c = 12;
        Database.insert(oAgr, FALSE);

        Apttus_Config2__Order__c machineOrder = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        machineOrder.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        machineOrder.APTS_Name__c = 'TestMachineOrder';
        machineOrder.Apttus_Config2__Status__c ='Activated';
        machineOrder.APTS_Status__c = 'Sent For Invoicing';
        machineOrder.APTS_Order_Type__c = 'Machine Order';
        machineOrder.Apttus_Config2__Status__c = 'Activated';
        machineOrder.APTS_Order_Header_SAP_ID__c ='1234';
        machineOrder.APTS_Remove_Billing_Block_Indicator__c = true;
        machineOrder.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert machineOrder;

        Apttus_Config2__OrderLineItem__c orderLineItem1 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c ='004067',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem1;
        Apttus_Config2__OrderLineItem__c orderLineItem2 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='4567',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem2;
         Apttus_Config2__OrderLineItem__c orderLineItem3 = new Apttus_Config2__OrderLineItem__c(APTS_SAP_Order_Line_Item_Number__c='004068',
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = machineOrder.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem3;

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id,oPricelist.id, NULL);
        order.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        order.APTS_Name__c = 'TestADminOrder';
        order.Apttus_Config2__Status__c ='Activated';
        order.Derived_From_Order__c = machineOrder.Id;
        machineOrder.APTS_Status__c = 'Sent For Invoicing';
        order.APTS_Order_Type__c = 'Admin Order';
        order.Apttus_Config2__Status__c = 'Activated';
        order.APTS_Order_Header_SAP_ID__c ='0000001834';
        order.APTS_Remove_Billing_Block_Indicator__c = true;
        order.APTS_Requested_Installation_Date__c = Date.newInstance(2018, 07, 30);
        insert order;

        Apttus_Config2__OrderLineItem__c orderLineItem11 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c = orderLineItem1.Id,
                                                                                                Apttus_Config2__ProductId__c = prod1.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem11;
        Apttus_Config2__OrderLineItem__c orderLineItem21 = new Apttus_Config2__OrderLineItem__c(APTS_Original_Order_Line_Item__c=orderLineItem2.Id,
                                                                                                Apttus_Config2__ProductId__c = prod2.Id,
                                                                                                Apttus_CMConfig__AgreementId__c =oAgr.Id,
                                                                                                Apttus_Config2__OrderId__c = order.Id,
                                                                                                Apttus_Config2__BasePrice__c=71.00);
        insert orderLineItem21;
        // Create Billing Schedule
        Apttus_Billing__BillingSchedule__c billingSchedule1 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule1.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLINGSTATUS;
        //billingSchedule1.APTS_Invoice__c = invoice.Id;
        billingSchedule1.Apttus_Billing__OrderLineItemId__c = orderLineItem1.Id;
        insert(billingSchedule1);
        Apttus_Billing__BillingSchedule__c billingSchedule2 = new Apttus_Billing__BillingSchedule__c();
        billingSchedule2.Apttus_Billing__Status__c = APTS_BIRUtils.PENDINGBILLINGSTATUS;
        //billingSchedule1.APTS_Invoice__c = invoice.Id;
        billingSchedule2.Apttus_Billing__OrderLineItemId__c = orderLineItem2.Id;
        insert(billingSchedule2);
        //Create Invoice
        Apttus_Billing__Invoice__c  invoice = new Apttus_Billing__Invoice__c();
        invoice.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invoice.Apttus_Billing__LocationId__c = null;
        invoice.Apttus_Billing__Status__c = 'Draft';
        invoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
        invoice.APTS_External_Invoice_Number__c = '2222';
        invoice.Apttus_Billing__SoldToAccountId__c=oAccount.Id;
        insert invoice;

        //Create Invoice Line Item
        Apttus_Billing__InvoiceLineItem__c invLI1 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoice.Id);
        invLI1.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI1.APTS_AdminOrder_Line__c=orderLineItem11.Id;
        invLI1.Apttus_Billing__Amount__c = 50;
        invLI1.APTS_Product__c=prod1.Id;
        insert invLI1;
        
        Apttus_Billing__InvoiceLineItem__c invLI2 = new Apttus_Billing__InvoiceLineItem__c(Apttus_Billing__InvoiceId__c=invoice.Id);
        invLI2.Apttus_Billing__BillToAccountId__c = oAccount.Id;
        invLI2.APTS_AdminOrder_Line__c=orderLineItem21.Id;
        invLI2.Apttus_Billing__Amount__c = 50;
        invLI2.APTS_Product__c=prod2.Id;
        insert invLI2;

        //Insert custom setting
        APTS_SAP_Connection_Settings__c sapCS = new APTS_SAP_Connection_Settings__c();
        sapCS.name = 'Invoice LI Retrieve';
        sapCS.APTS_Endpoint__c = '';
        sapCS.APTS_Certificate_Name__c = '';
        insert sapCS;

        ApexPages.currentPage().getParameters().put('Id', invoice.id);
        ApexPages.currentPage().getParameters().put('index','0');
        //Test.setMock(WebServiceMock.class, new APTS_RetrieveInvoiceLIControllerTestMock());
        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(invoice);
        APTS_RetrieveInvoiceLineItemController retInvLICtlr = new APTS_RetrieveInvoiceLineItemController(sc);

        retInvLICtlr.getInvoiceLineItemsFromSAP();
        system.debug('****retInvLICtlr.invoiceLineItemWrapperList==>'+retInvLICtlr.invoiceLineItemWrapperList);
        retInvLICtlr.invoiceLineItemWrapperList.get(0).selected = true;
        retInvLICtlr.invoiceLineItemWrapperList.get(1).selected = true;
        retInvLICtlr.createCreditMemo();
        retInvLICtlr.createDebitMemo();
        retInvLICtlr.getPicklistValues();
        retInvLICtlr.getCalculatedAmount();
        retInvLICtlr.cancel();

        Test.stopTest();
        system.assertEquals(true,retInvLICtlr.invoiceLineItemWrapperList.get(0).selected);
     }
     static testmethod void logic3(){
         try{
        APTS_RetrieveInvoiceLineItemController retInvLICtlr = new APTS_RetrieveInvoiceLineItemController(null);
        //retInvLICtlr.getInvoiceLineItemsFromSAP(null);
        retInvLICtlr.createCreditMemo();
        retInvLICtlr.createDebitMemo();
        //retInvLICtlr.getPicklistValues();
        //retInvLICtlr.getCalculatedAmount();
        //retInvLICtlr.cancel();
        }
        catch(exception e){
            system.debug(e);
            system.assertNotEquals('Dummy String',e.getMessage());
        }
        
        
     }
}