@isTest
private class APTS_TriangularRepriceFinializeQueueTest {

    
    /*@isTest static void testRepriceQueue() {
        // create billingprefrence
        Test.startTest();
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence('TestBillingPrefrence');
        insert billPref;

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount('TestAccount');

        oAccount.SAP_Customer_ID__c = '12321222';
        insert oAccount;

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        insert oContact;

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity('TestOpportunity', oAccount.Id);
        insert opportunityObj;

        //create price list
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('Test Price List');
        insert pricelist;

        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('PICKW SLWT ROYAL ENGLISH 25X3G X3 INT', '4014979', 'Coffee', 'Standalone', FALSE, FALSE);
        insert prod1;

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod1.Id);
        insert pli1;

        APTS_TriangleInvoiceOrders__c currentOrder0 =  new APTS_TriangleInvoiceOrders__c();
        currentOrder0.SAP_OrderType__c = 'XA06';
        currentOrder0.Account__c = 'BoomOrdr422';
        currentOrder0.SellingUom__c = 'Piece';
        currentOrder0.ProductId__c = '4014979';
        currentOrder0.Quantity__c =  50;
        currentOrder0.OrderReference__c = '1';
        currentOrder0.Order_Sub_Type__c = 'Consignment Issue for FSD';
        currentOrder0.AccountLocationSapId__c = '12321222';
        currentOrder0.Invoice_Remarks__c = 'AL00276479';
        currentOrder0.Pricing_Date__c = String.valueOf(System.today());
        currentOrder0.APTS_Stock_Partner__c = '12321222';
        currentOrder0.Requested_Delivery_Date__c = String.valueOf(System.today());
        currentOrder0.Cart_Id__c = null;
        currentOrder0.Order_Name__c = null;
        currentOrder0.Order__c = null;
        insert currentOrder0;

        APTS_TriangleInvoiceOrders__c currentOrder1 =  new APTS_TriangleInvoiceOrders__c();
        currentOrder1.SAP_OrderType__c = 'XA06';
        currentOrder1.Account__c  = 'BoomOrdr422';
        currentOrder1.SellingUom__c  = 'Piece';
        currentOrder1.ProductId__c  = '4014979';
        currentOrder1.Quantity__c  =  50;
        currentOrder1.OrderReference__c  = '1';
        currentOrder1.Order_Sub_Type__c  = 'Consignment Issue for FSD';
        currentOrder1.AccountLocationSapId__c  = '12321222';
        currentOrder1.Invoice_Remarks__c = 'AL00276479';
        currentOrder1.Pricing_Date__c = String.valueOf(System.today());
        currentOrder1.APTS_Stock_Partner__c = '12321222';
        currentOrder1.Requested_Delivery_Date__c = String.valueOf(System.today());
        insert currentOrder1;

        APTS_TriangleInvoiceOrders__c currentOrder2 =  new APTS_TriangleInvoiceOrders__c();
        currentOrder2.SAP_OrderType__c = 'XA06';
        currentOrder2.Account__c = 'BoomOrdr422';
        currentOrder2.SellingUom__c = 'Piece';
        currentOrder2.ProductId__c = '4014979';
        currentOrder2.Quantity__c =  50;
        currentOrder2.OrderReference__c = '1';
        currentOrder2.Order_Sub_Type__c = 'Consignment Issue for FSD';
        currentOrder2.AccountLocationSapId__c = '12321222';
        currentOrder2.Invoice_Remarks__c = 'AL00276479';
        currentOrder2.Pricing_Date__c = String.valueOf(System.today());
        currentOrder2.APTS_Stock_Partner__c = '12321222';
        currentOrder2.Requested_Delivery_Date__c = String.valueOf(System.today());
        insert currentOrder2;

        Apttus_Config2__Order__c oOrder  = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        oOrder.APTS_Order_Sub_Type__c  = 'Consignment Issue for FSD';
        oOrder.APTS_Order_Type__c = 'Standard Order';
        oOrder.APTS_SAP_OrderType__c = 'XA06';
        oOrder.APTS_Boomerang_Invoicing__c = true;
        insert oOrder;

        Id cartId =  APTS_OrderUtils.createCart(oOrder.id);
        currentOrder0.Cart_Id__c = cartId;
        currentOrder0.Order_Name__c = oOrder.Name;
        currentOrder0.Order__c = oOrder.id;
        update currentOrder0;

        Apttus_Config2__ProductConfiguration__c cart = APTS_OrderUtils.saveCart(cartId);
        //APTS_TriangularInvoicebatchHandler.updateError(orderList[0],orderList[0], null, false, null);
        System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, 'Triangular Invoicing Order', 'Submit', currentOrder0));
        System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId,'Triangular Invoicing Order', 'Pricing', currentOrder0));
        
        Test.stopTest();
    }*/
@isTest static void testRepriceQueue_Finalize() {
        // create billingprefrence
        Test.startTest();
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence('TestBillingPrefrence');
        insert billPref;

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount('TestAccount');

        oAccount.SAP_Customer_ID__c = '12321222';
        insert oAccount;

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        insert oContact;

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity('TestOpportunity', oAccount.Id);
        insert opportunityObj;

        //create price list
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('Test Price List');
        insert pricelist;

        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('PICKW SLWT ROYAL ENGLISH 25X3G X3 INT', '4014979', 'Coffee', 'Standalone', FALSE, FALSE);
        insert prod1;

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod1.Id);
        insert pli1;
        
        Apttus_Config2__Order__c oOrder  = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        oOrder.APTS_Order_Sub_Type__c  = 'Consignment Issue for FSD';
        oOrder.APTS_Order_Type__c = 'Standard Order';
        oOrder.APTS_SAP_OrderType__c = 'XA06';
        oOrder.APTS_Boomerang_Invoicing__c = true;
        insert oOrder;

        APTS_TriangleInvoiceOrders__c currentOrder0 =  new APTS_TriangleInvoiceOrders__c();
        currentOrder0.SAP_OrderType__c = 'XA06';
        currentOrder0.Account__c = 'BoomOrdr422';
        currentOrder0.SellingUom__c = 'Piece';
        currentOrder0.ProductId__c = '4014979';
        currentOrder0.Quantity__c =  50;
        currentOrder0.OrderReference__c = '1';
        currentOrder0.Order_Sub_Type__c = 'Consignment Issue for FSD';
        currentOrder0.AccountLocationSapId__c = '12321222';
        currentOrder0.Invoice_Remarks__c = 'AL00276479';
        currentOrder0.Pricing_Date__c = String.valueOf(System.today());
        currentOrder0.APTS_Stock_Partner__c = '12321222';
        currentOrder0.Requested_Delivery_Date__c = String.valueOf(System.today());
        currentOrder0.Cart_Id__c = null;
        currentOrder0.Order_Name__c = null;
        currentOrder0.Order__c = oOrder.id;
        insert currentOrder0;

        Id cartId =  APTS_OrderUtils.createCart(oOrder.id);
        currentOrder0.Cart_Id__c = cartId;
        currentOrder0.Order_Name__c = oOrder.Name;
        currentOrder0.Order__c = oOrder.id;
        update currentOrder0;

        Apttus_Config2__ProductConfiguration__c cart = APTS_OrderUtils.saveCart(cartId);
        //APTS_TriangularInvoicebatchHandler.updateError(orderList[0],orderList[0], null, false, null);
        System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, 'Triangular Invoicing Order', 'Finalize', currentOrder0));
        
        Test.stopTest();
    }
    @isTest static void testRepriceQueue_1() {
        // create billingprefrence
        Test.startTest();
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence('TestBillingPrefrence');
        insert billPref;

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount('TestAccount');

        oAccount.SAP_Customer_ID__c = '12321222';
        insert oAccount;

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        insert oContact;

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity('TestOpportunity', oAccount.Id);
        insert opportunityObj;

        //create price list
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('Test Price List');
        insert pricelist;

        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('PICKW SLWT ROYAL ENGLISH 25X3G X3 INT', '4014979', 'Coffee', 'Standalone', FALSE, FALSE);
        insert prod1;

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod1.Id);
        insert pli1;
        
        Apttus_Config2__Order__c oOrder  = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        oOrder.APTS_Order_Sub_Type__c  = 'Consignment Issue for FSD';
        oOrder.APTS_Order_Type__c = 'Standard Order';
        oOrder.APTS_SAP_OrderType__c = 'XA06';
        oOrder.APTS_Boomerang_Invoicing__c = true;
        insert oOrder;
        
        APTS_TriangleInvoiceOrders__c currentOrder0 =  new APTS_TriangleInvoiceOrders__c();
        currentOrder0.SAP_OrderType__c = 'XA06';
        currentOrder0.Account__c = 'BoomOrdr422';
        currentOrder0.SellingUom__c = 'Piece';
        currentOrder0.ProductId__c = '4014979';
        currentOrder0.Quantity__c =  50;
        currentOrder0.OrderReference__c = '1';
        currentOrder0.Order_Sub_Type__c = 'Consignment Issue for FSD';
        currentOrder0.AccountLocationSapId__c = '12321222';
        currentOrder0.Invoice_Remarks__c = 'AL00276479';
        currentOrder0.Pricing_Date__c = String.valueOf(System.today());
        currentOrder0.APTS_Stock_Partner__c = '12321222';
        currentOrder0.Requested_Delivery_Date__c = String.valueOf(System.today());
        currentOrder0.Cart_Id__c = null;
        currentOrder0.Order_Name__c = null;
        currentOrder0.Order__c = oOrder.id;
        insert currentOrder0;

       system.debug('currentOrder0--------'+currentOrder0.Order__c);

        Id cartId =  APTS_OrderUtils.createCart(oOrder.id);
        currentOrder0.Cart_Id__c = cartId;
        currentOrder0.Order_Name__c = oOrder.Name;
        currentOrder0.Order__c = oOrder.id;
        update currentOrder0;

        Apttus_Config2__ProductConfiguration__c cart = APTS_OrderUtils.saveCart(cartId);
        //APTS_TriangularInvoicebatchHandler.updateError(orderList[0],orderList[0], null, false, null);
        System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, 'Triangular Invoicing Order', 'Submit', currentOrder0));
        System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId,'Triangular Invoicing Order', 'Pricing', currentOrder0));
        
        Test.stopTest();



    }


}