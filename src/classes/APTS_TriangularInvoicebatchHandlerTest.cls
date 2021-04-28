@isTest
private class APTS_TriangularInvoicebatchHandlerTest {
    // Generate test data for the test methods 
    @testSetup static void setup() {


        // account data
        List<Account> testAccount = new List<Account>();
        testAccount.add(new Account(Name = 'AccHiertest', SAP_Customer_ID__c = '12321222', Sales_Organization__c = 'SAP_0333'));
        testAccount.add(new Account(Name = 'India Port', SAP_Customer_ID__c  = '999', Sales_Organization__c = 'SAP_0111'));
        insert testAccount;
        //List<Account> accId = [SELECT Id, Name FROM Account WHERE Name = 'AccHiertest'];
        // account location data
        List<Apttus_Config2__AccountLocation__c> testAccLocation = new List<Apttus_Config2__AccountLocation__c>();
        testAccLocation.add(new Apttus_Config2__AccountLocation__c(SAP_Customer_ID__c = '12321222', Apttus_Config2__AccountId__c = testAccount[0].Id));
        insert testAccLocation;
        // SELECT Id, SAP_Customer_ID__c FROM Apttus_Config2__AccountLocation__c WHERE SAP_Customer_ID__c IN:acctLocSet]
        // contact data
        List<Contact> testContact = new List<Contact>();
        testContact.add(new Contact(AccountId = testAccount[0].Id, Function__c = 'Buyer Ingredients', Main_Commercial_Person__c = true, Main_Service_Person__c = false));
        // select Id, AccountId, Function__c,Main_Commercial_Person__c, Main_Service_Person__c from Contact where AccountId = :mapAccountSapIdwithAccountId.values() 

        // product data
        List<Product2> testProduct = new List<Product2>();
        testProduct.add(new Product2(ProductCode = '4016617', Name = 'PICKW TMS GT  LEMON ISE 25X1.5GX3    INT'));
        insert testProduct;
        // price list data
        List<Apttus_Config2__PriceList__c> testPriceList = new List<Apttus_Config2__PriceList__c>();
        testPriceList.add(new Apttus_Config2__PriceList__c(Name = 'JDE Price List - Draft', APTS_PriceList_Type__c = 'Direct', APTS_SalesOrg__c = '0333'));
        insert testPriceList;
    }
    // good case 
    @isTest static void testControllerGood(){
        string jsondata = '{ "Order Export Tab": [ { "orderReference": "1", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        // Test.startTest();
        APTS_TriangularInvoiceUpload.parseData(jsondata);
        APTS_TriangularInvoiceUpload.getLimits();
        //integer orderCount= database.countQuery('select count() from Apttus_Config2__Order__c');
        //integer cartCount = database.countQuery('select count() from Apttus_Config2__ProductConfiguration__c');
        //list<APTS_TriangleInvoiceOrders__c> createdOrders = new list<APTS_TriangleInvoiceOrders__c>();
        //list<Apttus_Config2__ProductConfiguration__c> createdCarts = new List<Apttus_Config2__ProductConfiguration__c>();
        //createdOrders = [select id, Name,Order__c from APTS_TriangleInvoiceOrders__c];
        ////createdCarts  = [select id, Name from Apttus_Config2__ProductConfiguration__c];
        //integer orderCount;
        ////integer cartCount;
        //orderCount = createdOrders.size();
        ////cartCount  = createdCarts.size();
        //boolean hasOrder = createdOrders[0].Order__c != null ? true: false;

        //System.assertEquals(true,hasOrder);
        //System.assertEquals(cartCount,1);
        // Test.stopTest();
    }
    // bad customer id case 
    @isTest static void testController1(){
        // string jsondata1 = '{ "Order Export Tab": [ { "orderReference": "2", "account": "AccHiertest", "sapCustomerId": "12321222000", "sapOrderType": "XA01", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222", "product": "4016617", "quantity": "3", "sellingUom": "Piece" } ] }';
         string jsondata1 = '{ "Order Export Tab": [ { "orderReference": "2", "account": "AccHiertest", "sapCustomerId": "1232122200", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        // Test.startTest();
        APTS_TriangularInvoiceUpload.parseData(jsondata1);
        // Test.stopTest();
    }
    // bad product case
    @isTest static void testController2(){
        //string jsondata2 = '{ "Order Export Tab": [ { "orderReference": "3", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222", "product": "4016617000", "quantity": "2", "sellingUom": "Piece" } ] }';
        string jsondata2 = '{ "Order Export Tab": [ { "orderReference": "3", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "401661700", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        // Test.startTest();
        APTS_TriangularInvoiceUpload.parseData(jsondata2);
        // Test.stopTest();
    }
    // negative quantity case 
    @isTest static void testController3(){
        // string jsondata3 = '{ "Order Export Tab": [ { "orderReference": "4", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222", "product": "4016617", "quantity": "-5", "sellingUom": "Piece" } ] }';
         string jsondata3 = '{ "Order Export Tab": [ { "orderReference": "4", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "-2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        // Test.startTest();
        APTS_TriangularInvoiceUpload.parseData(jsondata3);
        // Test.stopTest();
    }
        // bad cust ID on second line item 
    @isTest static void testController4(){
        // string jsondata4 = '{ "Order Export Tab": [ { "orderReference": "5", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222", "product": "4016617", "quantity": "-5", "sellingUom": "Piece" }, { "orderReference": "5", "account": "AccHiertest", "sapCustomerId": "12321222000", "sapOrderType": "testBadProd", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222", "product": "4016617", "quantity": "-5", "sellingUom": "Piece" } ] }';
         string jsondata4 = '{ "Order Export Tab": [ { "orderReference": "5", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece" }, {"orderReference": "5", "account": "AccHiertest", "sapCustomerId": "1232122200", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ]}'; 
        // Test.startTest();
        APTS_TriangularInvoiceUpload.parseData(jsondata4);
        integer orderCount= database.countQuery('select count() from Apttus_Config2__Order__c');
        integer cartCount = database.countQuery('select count() from Apttus_Config2__ProductConfiguration__c');
        System.assertEquals(orderCount,0);
        System.assertEquals(cartCount,0);
        // Test.stopTest();
        //integer orderCount= database.countQuery('select count(id) from Apttus_Config2__Order__c');
        //integer cartCount = database.countQuery('select count(id) from Apttus_Config2__ProductConfiguration__c');
        //System.assertEquals(database.countQuery('select count(id) from Apttus_Config2__Order__c'),1);
        //System.assertEquals(cartCount,1);
    }
    // test bad soldTo customer id 
    @isTest static void testController5(){
    string jsondata5 = '{ "Order Export Tab": [ { "orderReference": "6", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222000", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
    APTS_TriangularInvoiceUpload.parseData(jsondata5);
    }
    //test bad billTo customer Id
    @isTest static void testController6(){
    string jsondata6 ='{ "Order Export Tab": [ { "orderReference": "7", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222000", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
    APTS_TriangularInvoiceUpload.parseData(jsondata6);
    }
    // test bad payer customer Id
    @isTest static void testController7(){
    string jsondata7 = '{ "Order Export Tab": [ { "orderReference": "8", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222000","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
    APTS_TriangularInvoiceUpload.parseData(jsondata7);
    }

    @isTest static void testController8(){
    string jsondata7 = '{ "Order Export Tab": [ { "orderReference": "8", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01/09//2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222000","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
    APTS_TriangularInvoiceUpload.parseData(jsondata7);
    }
    
    @isTest static void testmethod9() {
        string jsondata = '{ "Order Export Tab": [ { "orderReference": "1", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        APTS_TriangularInvoiceUpload.parseData(jsondata);
        Set<Id> orderIdSet = new Set<Id>();
        List<APTS_TriangleInvoiceOrders__c> orderList = new List<APTS_TriangleInvoiceOrders__c>([Select id,OrderReference__c from APTS_TriangleInvoiceOrders__c limit 1]);
        APTS_TriangularInvoicebatchHandler.updatesObject(orderList);
        for (APTS_TriangleInvoiceOrders__c orderP : orderList) {
            orderIdSet.add(orderP.Id);
    
        }
        //APTS_TriangularInvoicebatchHandler.SubmitOrders(orderIdSet);
        
        Apttus_Config2__Order__c invoiceOrder = new Apttus_Config2__Order__c();
        invoiceOrder.APTS_Way_Of_Delivery__c = 'Indirect channel';
        invoiceOrder.APTS_Way_Of_Ordering__c = 'Indirect channel';   
        list<Apttus_Config2__Order__c> orderList2 = new list<Apttus_Config2__Order__c>();
        orderList2.add(invoiceOrder);
        APTS_TriangularInvoicebatchHandler.insertObject(orderList2);
        APTS_TriangularInvoicebatchHandler.updateError(orderList[0],orderList[0], null, false, null);
        
        
    }
    
    @isTest static void testmethod10() {
        
        APTS_TriangleInvoiceOrders__c a = new APTS_TriangleInvoiceOrders__c();
        a.Order_Name__c = 'Order Failed';
        insert a;
        Set<String> badOrders =  new Set<String>();
        Set<String> badCarts = new Set<String>();
        badOrders.add(a.Order__c);
        badCarts.add(a.Cart_Id__c);
        APTS_TriangularInvoicebatchHandler.DeleteBadOrdersAndCarts(badOrders,badCarts);
        
    }
    
    @isTest static void testmethod11() {
        
        Apttus_Config2__PriceList__c testPriceList2 = new Apttus_Config2__PriceList__c(Name = 'JDE Price List - Draft', APTS_PriceList_Type__c = 'Direct', APTS_SalesOrg__c = '0333');
        insert testPriceList2;
        List<Account> testAccount = new List<Account>();
        testAccount.add(new Account(Name = 'AccHiertest', SAP_Customer_ID__c = '12321222', Sales_Organization__c = 'SAP_0333',APTS_Price_List__c = testPriceList2.Id));
        Contact oContact = APTS_TestDataFactory.createContact(testAccount[0], '1010101011');
        oContact.Function__c = 'Buyer Ingredients';
        oContact.Main_Service_Person__c = true;
        insert oContact;
        List<String> sendTo = new List<String>();
        String sendEmail = 'rajesh.patel@accenture.com';
        sendTo.add(sendEmail);
        string jsondata = '{ "Order Export Tab": [ { "orderReference": "1", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        APTS_TriangularInvoiceUpload.parseData(jsondata);
        APTS_TriangleInvoiceOrders__c orderL = [Select id,OrderReference__c,ErrorMessage__c,SAP_Customer_ID__c,SAP_OrderType__c,Requested_Delivery_Date__c,SoldTo__c,BillTo__c,Payer__c,AccountLocationSapId__c,ProductId__c,Quantity__c,SellingUom__c,Order_Name__c,Pricing_Date__c,Invoice_Remarks__c,PO__c,HasError__c,APTS_Stock_Partner__c from APTS_TriangleInvoiceOrders__c limit 1];
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(testAccount[0].Id,testPriceList2.Id, oContact.Id);
        oOrder.APTS_Order_Type__c = 'Standard Order';
        oOrder.APTS_Requested_Installation_Date__c = null;
        insert oOrder;
        Set<String> testEm = new Set<String>();
        String failOrder = oOrder.id;
        testEm.add(failOrder);
        List<APTS_TriangleInvoiceOrders__c> currentOrderList = new List<APTS_TriangleInvoiceOrders__c>();
        currentOrderList.add(orderL);
        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(oOrder);
        insert config;
        Map<String,string> mapSapIdWithSalesOrg = new Map<String,string>();
        mapSapIdWithSalesOrg.put('12321222','SAP_0333');
        Map<String,string> mapOfProductCodeAndID = new Map<String,string>();
        APTS_TriangularInvoicebatchHandler ps = new APTS_TriangularInvoicebatchHandler();
        APTS_TriangularInvoicebatchHandler.removeNull('test');
        APTS_TriangularInvoicebatchHandler.sendOrderConfirmationMail(sendTo,testEm,currentOrderList );
        try {ps.addProductsToCart(string.valueof(config.Id), orderL, currentOrderList,mapSapIdWithSalesOrg, mapOfProductCodeAndID);}catch(Exception e){}
        try {APTS_TriangularInvoicebatchHandler.updatePricing(config.Id,orderL,true);}catch(Exception e){}   
    }

    @isTest static void testmethod131() {
        
        Apttus_Config2__PriceList__c testPriceList2 = new Apttus_Config2__PriceList__c(Name = 'JDE Price List - Draft', APTS_PriceList_Type__c = 'Direct', APTS_SalesOrg__c = '0333');
        insert testPriceList2;
        List<Account> testAccount = new List<Account>();
        testAccount.add(new Account(Name = 'AccHiertest', SAP_Customer_ID__c = '12321222', Sales_Organization__c = 'SAP_0333',APTS_Price_List__c = testPriceList2.Id));
        Contact oContact = APTS_TestDataFactory.createContact(testAccount[0], '1010101011');
        oContact.Function__c = 'Buyer Ingredients';
        oContact.Main_Service_Person__c = true;
        insert oContact;
        List<String> sendTo = new List<String>();
        String sendEmail = 'rajesh.patel@accenture.com';
        sendTo.add(sendEmail);
        string jsondata = '{ "Order Export Tab": [ { "orderReference": "1", "account": "AccHiertest", "sapCustomerId": "12321222", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01-09-2018", "soldTo": "12321222", "billTo": "12321222", "payer": "12321222","accountLocation": "12321222", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "12321222" } ] }';
        APTS_TriangularInvoiceUpload.parseData(jsondata);
        APTS_TriangleInvoiceOrders__c orderL = [Select id,OrderReference__c,ErrorMessage__c,SAP_Customer_ID__c,SAP_OrderType__c,Requested_Delivery_Date__c,SoldTo__c,BillTo__c,Payer__c,AccountLocationSapId__c,ProductId__c,Quantity__c,SellingUom__c,Order_Name__c,Pricing_Date__c,Invoice_Remarks__c,PO__c,HasError__c,APTS_Stock_Partner__c from APTS_TriangleInvoiceOrders__c limit 1];
        Apttus_Config2__Order__c oOrder = APTS_TestDataFactory.createOrder(testAccount[0].Id,testPriceList2.Id, oContact.Id);
        oOrder.APTS_Order_Type__c = 'Standard Order';
        oOrder.APTS_Requested_Installation_Date__c = null;
        insert oOrder;
        Set<String> testEm = new Set<String>();
        String failOrder = oOrder.id;
        testEm.add(failOrder);
        List<APTS_TriangleInvoiceOrders__c> currentOrderList = new List<APTS_TriangleInvoiceOrders__c>();
        currentOrderList.add(orderL);
        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(oOrder);
        insert config;
        Map<String,string> mapSapIdWithSalesOrg = new Map<String,string>();
        mapSapIdWithSalesOrg.put('12321222','SAP_0333');
        Map<String,string> mapOfProductCodeAndID = new Map<String,string>();
        APTS_TriangularInvoicebatchHandler ps = new APTS_TriangularInvoicebatchHandler();
        APTS_TriangularInvoicebatchHandler.removeNull('test');
        APTS_TriangularInvoicebatchHandler.sendOrderConfirmationMail(sendTo,testEm,currentOrderList );
        try {ps.addProductsToCart(string.valueof(config.Id), orderL, currentOrderList,mapSapIdWithSalesOrg, mapOfProductCodeAndID);}catch(Exception e){}
        try {APTS_TriangularInvoicebatchHandler.updatePricing(config.Id,orderL,false);}catch(Exception e){}   
    }
    @isTest static void testSubmitOrderQueueable12(){
    string jsondata12 = '{ "Order Export Tab": [ { "orderReference": "8", "account": "Acc", "sapCustomerId": "", "sapOrderType": "XA01","orderSubType": "Standard Order", "reqDelivDate": "01/09//2018", "soldTo": "", "billTo": "", "payer": "","accountLocation": "", "product": "4016617", "quantity": "2", "sellingUom": "Piece", "PO": "BL-43456", "Invoice remarks": "Traingular Invoice", "Pricing date": "12-07-2018", "Stock Partner": "" } ] }';
    APTS_TriangularInvoiceUpload.parseData(jsondata12);
    }
}