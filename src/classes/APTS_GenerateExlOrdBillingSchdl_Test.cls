/**
* Class Name : APTS_GenerateExlOrdBillingSchdl_Test
* Description : Apex Class to test APTS_GenerateExtnlOrderBillingSchedule Class
* Code Coverage : APTS_GenerateExtnlOrderBillingSchedule(94% Code Coverage)     
* Author : Kiruthika Pachaimaal
* Date Created : 18/04/2018
**/
@isTest
private class APTS_GenerateExlOrdBillingSchdl_Test {
 @testSetup
    //Test Data Setup Method to create all test Data to test "APTS_GenerateExtnlOrderBillingSchedule" Class
    static void setupTestData(){ 

        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
        
        Account account = APTS_TestUtils.createGrandParentAccount();
        Database.insert(account);
        
        Account account0 = APTS_TestUtils.createGrandParentAccount();
        Database.insert(account0);
        
        Contact con = APTS_TestUtils.createContact();
        Database.insert(con);       
       
        Product2 prod = APTS_TestUtils.createProduct('Test Product', 'P-0001', 'SAP_01');
        Database.insert(prod);

        Apttus_Config2__PriceList__c prcLst = APTS_TestUtils.createPriceList(); 
        Database.insert(prcLst);
        
        Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
        category.Name = 'Coffee';
        Database.Insert(category);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = 
            APTS_TestUtils.createCategoryHierarchy(category.Id);
        categoryHierarchy.APTS_CategoryHierarchyOfferingExtId__c = 'TestABC000';
        categoryHierarchy.Apttus_Config2__Label__c = 'Coffee';
        Database.Insert(categoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        subCategoryHierarchy.Name = 'Liquid';  
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Liquid';
        subCategoryHierarchy.APTS_CategoryHierarchyOfferingExtId__c = 'TestABC111';          
        Database.Insert(subCategoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        subsubCategoryHierarchy.APTS_CategoryHierarchyOfferingExtId__c = 'TestABC123';
        subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
        subSubCategoryHierarchy.Name = 'Cafitesse';
        Database.Insert(subSubCategoryHierarchy);      
        
        Apttus_Config2__ProductClassification__c productClassification = 
            APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, prod.id);
        Database.Insert(productClassification);
        
        Apttus__APTS_Agreement__c agmt = APTS_TestUtils.createAgreement(con.Id, null, prcLst.Id, account.Id);
        agmt.RecordtypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();       
        Database.insert(agmt);
        
        Apttus_Config2__PriceListItem__c pLI = APTS_TestUtils.createPriceListItem(prcLst.Id, prod.Id); 
        Database.insert(pLI);

        Apttus_Config2__BillingPreference__c billPrf = APTS_TestUtils.createBillingPrefrence('January');
        Database.insert(billPrf);

        Apttus_Config2__Order__c ord = APTS_TestUtils.createOrder('New', prcLst.Id, account.Id, billPrf.Id);
        Database.insert(ord);
        
        Apttus_Config2__AssetLineItem__c assLI = APTS_TestUtils.createAssetLineItem(account.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI.Apttus_Config2__ListPrice__c = 200; 
        assLI.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI.Apttus_Config2__ProductId__c = prod.Id;
        assLI.Apttus_Config2__OptionId__c = prod.Id;
        assLI.Apttus_Config2__AccountId__c = account.Id;

        Database.insert(assLI);
        
        Apttus_Config2__AssetLineItem__c assLI0 = APTS_TestUtils.createAssetLineItem(account0.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI0.Apttus_Config2__ListPrice__c = 200; 
        assLI0.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI0.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI0.Apttus_Config2__ProductId__c = prod.Id;
        assLI0.Apttus_Config2__OptionId__c = prod.Id;
        assLI0.Apttus_Config2__AccountId__c = account0.Id;
        Database.insert(assLI0);
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prod.Id, ord.Id, assLI.Id, billPrf.Id, prcLst.Id, pLI.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        //oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli.Apttus_Config2__OrderId__c = ord.Id;
        //oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.Apttus_Config2__AssetLineItemId__c = assLI.Id;
        oli.Apttus_CMConfig__AgreementId__c = agmt.Id;
        oli.Apttus_Config2__ProductId__c = prod.Id;
        oli.Apttus_Config2__ShipToAccountId__c = account.Id;
        oli.APTS_Serial_Number__c = '123';
        //oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        Database.insert(oli);
        
        Apttus_Config2__ExternalOrderSummary__c extOrdSmry = new Apttus_Config2__ExternalOrderSummary__c();
        extOrdSmry.Apttus_Config2__AccountId__c = account.Id;
        extOrdSmry.Apttus_Config2__Status__c = 'Ready for Incentive Processing';
        extOrdSmry.Apttus_Config2__Type__c = 'Sales Data';
        extOrdSmry.Apttus_Config2__PeriodStartDate2__c = Date.today();
        extOrdSmry.Apttus_Config2__PeriodEndDate__c = Date.today().addYears(1);
        Database.insert(extOrdSmry);
        
       /* Apttus_Config2__ExternalOrderSummary__c extOrdSmry1 = new Apttus_Config2__ExternalOrderSummary__c();
        //extOrdSmry1.Apttus_Config2__AccountId__c = account.Id;
        extOrdSmry1.Apttus_Config2__Status__c = 'Ready for Incentive Processing';
        extOrdSmry1.Apttus_Config2__Type__c = 'Sales Data';
        Database.insert(extOrdSmry1); */
        
        
        Apttus_Config2__ExternalOrderSummaryItem__c extOrdSmryI = new Apttus_Config2__ExternalOrderSummaryItem__c();
        extOrdSmryI.Apttus_Config2__BillToAccountId__c = account.Id;
        extOrdSmryI.Apttus_Config2__LineNumber__c = 0;
        extOrdSmryI.Apttus_Config2__ListPrice__c = 200;
        extOrdSmryI.Apttus_Config2__NetPrice__c = 200;
        extOrdSmryI.Apttus_Config2__NetUnitPrice__c = 200;
        extOrdSmryI.Apttus_Config2__OrderSummaryId__c = extOrdSmry.Id;
        extOrdSmryI.Apttus_Config2__Quantity__c = 5;
        Database.insert(extOrdSmryI);
        
        Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c();
        bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__AssetLineItemId__c = assLI0.Id;
        bilScdl.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl.Apttus_Billing__FeeAmount__c = 250;
        bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__Type__c = 'Contracted';
        bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        Database.insert(bilScdl);
        
        Apttus_Billing__BillingSchedule__c bilScdl0 = new Apttus_Billing__BillingSchedule__c();
        bilScdl0.Apttus_Billing__BillToAccountId__c = account.Id;
        bilScdl0.Apttus_Billing__AssetLineItemId__c = assLI.Id;
        bilScdl0.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl0.Apttus_Billing__FeeAmount__c = 300;
        bilScdl0.Apttus_Billing__ShipToAccountId__c = account.Id;
        bilScdl0.Apttus_Billing__Type__c = 'Contracted';
        bilScdl0.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl0.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl0.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        Database.insert(bilScdl0);
        
        Apttus_Billing__UsageSchedule__c usgscd = new Apttus_Billing__UsageSchedule__c();
        usgscd.Apttus_Billing__BillingScheduleId__c = bilScdl.Id; 
        usgscd.Apttus_Billing__IncludedQuantity__c = 5;
        usgscd.Apttus_Billing__ActualOverageQuantity__c = 5;
        usgscd.Apttus_Billing__ActualIncludedQuantity__c = 5;
        usgscd.Apttus_Billing__Status__c = 'Pending Billing';
        usgscd.Apttus_Billing__Type__c = 'Included Usage';
        usgscd.Apttus_Billing__AssetLineItemId__c = assLI.Id;
        Database.insert(usgscd);
        
        Apttus_Billing__UsageSchedule__c usgscd0 = new Apttus_Billing__UsageSchedule__c();
        usgscd0.Apttus_Billing__BillingScheduleId__c = bilScdl0.Id; 
        usgscd0.Apttus_Billing__IncludedQuantity__c = 5;
        usgscd0.Apttus_Billing__ActualOverageQuantity__c = 5;
        usgscd0.Apttus_Billing__ActualIncludedQuantity__c = 5;
        usgscd0.Apttus_Billing__Status__c = 'Pending Billing';
        usgscd0.Apttus_Billing__Type__c = 'Included Usage';
        usgscd0.Apttus_Billing__AssetLineItemId__c = assLI0.Id;
        Database.insert(usgscd0);

        Apttus_Billing__UsageInput__c usageInput = new Apttus_Billing__UsageInput__c();
        usageInput.Apttus_Billing__AssetLineItemId__c = assLI.Id;
        usageInput.Apttus_Billing__StartDate__c = system.today();
        usageInput.Apttus_Billing__RatedAmount__c = 100;
        usageInput.Apttus_Billing__Quantity__c = 10;
        usageInput.APTS_Price_Type__c = 'Paid';
        usageInput.Apttus_Billing__Status__c = 'Rated';
        usageInput.Apttus_Billing__UsageDate__c = System.today() + 1;
        Database.insert(usageInput);

        Apttus_Billing__UsageInput__c usageInput1 = new Apttus_Billing__UsageInput__c();
        usageInput1.Apttus_Billing__AssetLineItemId__c = assLI0.Id;
        usageInput1.Apttus_Billing__StartDate__c = system.today();
        usageInput1.Apttus_Billing__RatedAmount__c = 100;
        usageInput1.Apttus_Billing__Quantity__c = 10;
        usageInput1.APTS_Price_Type__c = 'Paid';
        usageInput1.Apttus_Billing__Status__c = 'Rated';
        usageInput1.Apttus_Billing__UsageDate__c = System.today() + 1;
        Database.insert(usageInput1);
    }
    }
     //Test Method to test the "APTS_GenerateExtnlOrderBillingSchedule" Class
    @isTest
    static void testGenerateExternalOrderBillingSchedule(){
        Test.startTest();
        APTS_GenerateExtnlOrderBillingSchedule extOrdSchl = new APTS_GenerateExtnlOrderBillingSchedule();
        DataBase.executeBatch(extOrdSchl); 
        List<Apttus_Billing__UsageSchedule__c> uschlst = [Select id from Apttus_Billing__UsageSchedule__c];
        delete uschlst;
        APTS_GenerateExtnlOrderBillingSchedule extOrdSchl1 = new APTS_GenerateExtnlOrderBillingSchedule();
        DataBase.executeBatch(extOrdSchl1);
        List<Apttus_Billing__BillingSchedule__c >Blist = [Select id from Apttus_Billing__BillingSchedule__c];
        System.debug('Blist size'+Blist.size());
        System.assert(Blist.size() > 0);
        Test.stopTest();       
    }
    //Test Method to test the "APTS_GenerateExtnlOrdBillingScheduler" Class
    static testMethod void testSchedular() {

        test.startTest();
            APTS_GenerateExtnlOrdBillingScheduler sch = new APTS_GenerateExtnlOrdBillingScheduler();
            string s = '0 0 15 ? * * *';
            String jobId = system.schedule('Test Run'+system.now(),s,sch);
        test.stopTest();
        }
}