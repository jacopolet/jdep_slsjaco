/**
* Class Name :  APTS_BillingScheduleTriggerHandlerTest
* Description : Apex Class to test APTS_BillingScheduleTriggerHandler Class
* Code Coverage : 100% for APTS_BillingScheduleTriggerHandler & APTS_BillingScheduleTrigger
* Author : Monika Jayachamaraja
* Date Created : 11/04/2019
**/
@isTest
public class  APTS_BillingScheduleTriggerHandlerTest { 
         
        static testMethod void Logic1() {
         Test.startTest();
        insert new TriggerSettings__c(APTS_BillingScheduleTrigger__c = true);
        
        Account account = APTS_TestUtils.createaccount();
        account.Duplicate_Reason__c = 'Office building';
        Database.insert(account);
        
        Account account0 = APTS_TestUtils.createaccount();
        account0.Duplicate_Reason__c = 'Caterer Location';
        account0.Main_House_Number__c='test number 2';
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
        
        /*Apttus_Config2__AssetLineItem__c assLI = APTS_TestUtils.createAssetLineItem(account.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI.Apttus_Config2__ListPrice__c = 200; 
        assLI.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI.Apttus_Config2__ProductId__c = prod.Id;
        assLI.Apttus_Config2__OptionId__c = prod.Id;
        assLI.Apttus_Config2__AccountId__c = account.Id;
        assLI.Apttus_Config2__IsOptionRollupLine__c = True;
        Database.insert(assLI);
        
        Apttus_Config2__AssetLineItem__c assLI0 = APTS_TestUtils.createAssetLineItem(account0.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI0.Apttus_Config2__ListPrice__c = 200; 
        assLI0.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI0.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI0.Apttus_Config2__ProductId__c = prod.Id;
        assLI0.Apttus_Config2__OptionId__c = prod.Id;
        assLI0.Apttus_Config2__AccountId__c = account0.Id;
        assLI0.Apttus_Config2__IsOptionRollupLine__c = True;
        Database.insert(assLI0);*/
            
            Apttus_Config2__AssetLineItem__c assetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem1.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        assetLineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        assetLineItem1.Apttus_Config2__HasOptions__c = true;
        assetLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem1.Apttus_CMConfig__AgreementId__c = agmt.id; 
        assetLineItem1.Apttus_Config2__ItemSequence__c = 2;
        assetLineItem1.Apttus_Config2__Quantity__c = 2;
        assetLineItem1.Apttus_Config2__BaseExtendedPrice__c = 1234;
        assetLineItem1.Apttus_Config2__SellingTerm__c =1;
        assetLineItem1.Apttus_Config2__BillingPreferenceId__c = billPrf.id;
        assetLineItem1.APTS_MigrationDate__c = System.Today();
        insert assetLineItem1;
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prod.Id, ord.Id, assetLineItem1.Id, billPrf.Id, prcLst.Id, pLI.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        //oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli.Apttus_Config2__OrderId__c = ord.Id;
        //oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.Apttus_Config2__AssetLineItemId__c = assetLineItem1.Id;
        oli.Apttus_CMConfig__AgreementId__c = agmt.Id;
        oli.Apttus_Config2__ProductId__c = prod.Id;
        oli.Apttus_Config2__ShipToAccountId__c = account.Id;
        oli.APTS_Serial_Number__c = '123';
        //oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        Database.insert(oli);
        
       List <Apttus_Billing__BillingSchedule__c>bs= new List<Apttus_Billing__BillingSchedule__c>();
        Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
        bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__AssetLineItemId__c = assetLineItem1.Id;
        bilScdl.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl.Apttus_Billing__FeeAmount__c = 250;
        bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__Type__c = 'Contracted';
        bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        insert bilScdl;
       // bs.add(bilScdl);
        
        Apttus_Billing__BillingSchedule__c bilScdl1 = new Apttus_Billing__BillingSchedule__c ();
        bilScdl1.Apttus_Billing__BillToAccountId__c = account0.Id;
        bilScdl1.Apttus_Billing__AssetLineItemId__c = assetLineItem1.Id;
        bilScdl1.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl1.Apttus_Billing__FeeAmount__c = 250;
        bilScdl1.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl1.Apttus_Billing__Type__c = 'Contracted';
        bilScdl1.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl1.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl1.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        insert bilScdl1;
       // bs.add(bilScdl1);
        //insert bs;
        list<Apttus_Billing__BillingSchedule__c> bstest = [select id,Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c  from Apttus_Billing__BillingSchedule__c];
        system.debug('bstest----- '+bstest);
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        update assetLineItem1;
        bilScdl1.Apttus_Billing__FeeAmount__c = 350; 
        update bilScdl1;
        //bs[1].Apttus_Billing__FeeAmount__c = 350;
       // bs[1].Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c = true;
       // update bs[1];
        
        // APTS_BillingScheduleTriggerHandler bh = new APTS_BillingScheduleTriggerHandler ();  
        // bh.beforeInsert(bs); 
         test.stopTest();
        }
        static testMethod void Logic3() {
         Test.startTest();
        try {
           
            List<SObject> newItems;
        List<SObject> oldList;
        Map<Id, SObject> oldItems;
        List<SObject> newList;
        Map<Id, SObject> newItemsMap;
         APTS_BillingScheduleTriggerHandler bh = new APTS_BillingScheduleTriggerHandler ();  
        bh.AfterInsert(newList,newItemsMap);
        bh.AfterUpdate(newList,newItemsMap,oldList, oldItems);
        bh.BeforeDelete(oldList, oldItems);
        bh.AfterDelete(oldList, oldItems);
        bh.AfterUndelete(newList, newItemsMap);
         bh.beforeInsert(null); 
         bh.beforeUpdate(null,null,null,null);
        } 
        catch (Exception e) {
        System.debug ('Exception'+e);
        return;
        }
        test.stopTest();
        }
          static testMethod void LogicApttusWorkaround() {
         Test.startTest();
        insert new TriggerSettings__c(APTS_BillingScheduleTrigger__c = true);
        
        Account account = APTS_TestUtils.createaccount();
        account.Duplicate_Reason__c = 'Office building';
        Database.insert(account);
        
        Account account0 = APTS_TestUtils.createaccount();
        account0.Duplicate_Reason__c = 'Caterer Location';
        account0.Main_House_Number__c='test number 2';
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
        
        /*Apttus_Config2__AssetLineItem__c assLI = APTS_TestUtils.createAssetLineItem(account.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI.Apttus_Config2__ListPrice__c = 200; 
        assLI.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI.Apttus_Config2__ProductId__c = prod.Id;
        assLI.Apttus_Config2__OptionId__c = prod.Id;
        assLI.Apttus_Config2__AccountId__c = account.Id;
        assLI.Apttus_Config2__IsOptionRollupLine__c = True;
        Database.insert(assLI);
        
        Apttus_Config2__AssetLineItem__c assLI0 = APTS_TestUtils.createAssetLineItem(account0.Id, prod.Id, prcLst.Id, pLI.Id, billPrf.Id, ord.Id);
        assLI0.Apttus_Config2__ListPrice__c = 200; 
        assLI0.Apttus_Config2__NetUnitPrice__c = 200; 
        assLI0.Apttus_CMConfig__AgreementId__c = agmt.Id; 
        assLI0.Apttus_Config2__ProductId__c = prod.Id;
        assLI0.Apttus_Config2__OptionId__c = prod.Id;
        assLI0.Apttus_Config2__AccountId__c = account0.Id;
        assLI0.Apttus_Config2__IsOptionRollupLine__c = True;
        Database.insert(assLI0);*/
            
            Apttus_Config2__AssetLineItem__c assetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem1.Apttus_Config2__LineType__c = 'Option';
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        assetLineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        assetLineItem1.Apttus_Config2__HasOptions__c = true;
        assetLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem1.Apttus_CMConfig__AgreementId__c = agmt.id; 
        assetLineItem1.Apttus_Config2__ItemSequence__c = 2;
        assetLineItem1.Apttus_Config2__Quantity__c = 2;
        assetLineItem1.Apttus_Config2__BaseExtendedPrice__c = 1234;
        assetLineItem1.Apttus_Config2__SellingTerm__c =1;
        assetLineItem1.Apttus_Config2__AdjustedPrice__c=0;
        assetLineItem1.Apttus_Config2__StartDate__c=System.today();
        assetLineItem1.Apttus_Config2__OriginalStartDate__c =System.today().addDays(-12);
        assetLineItem1.Apttus_Config2__EndDate__c = System.today().addDays(30);
        assetLineItem1.Apttus_Config2__BillingPreferenceId__c = billPrf.id;
        assetLineItem1.APTS_MigrationDate__c = System.Today();
        insert assetLineItem1;
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prod.Id, ord.Id, assetLineItem1.Id, billPrf.Id, prcLst.Id, pLI.Id);
        oli.Apttus_Config2__Status__c = 'Activated';
        //oli.APTS_Order_LSP_Detail__c = ordrLspDetails.Id;
        oli.Apttus_Config2__OrderId__c = ord.Id;
        //oli.Apttus_Config2__AttributeValueId__c = prdAttValue.Id;
        oli.Apttus_Config2__AssetLineItemId__c = assetLineItem1.Id;
        oli.Apttus_CMConfig__AgreementId__c = agmt.Id;
        oli.Apttus_Config2__ProductId__c = prod.Id;
        oli.Apttus_Config2__ShipToAccountId__c = account.Id;
        oli.APTS_Serial_Number__c = '123';
        //oli.APTS_Installation_Date__c = system.today();
        oli.APTS_Goods_Issue_Date__c = system.today().adddays(1);
        oli.APTS_RefurbishedMachine__c = true;
        Database.insert(oli);
        
       List <Apttus_Billing__BillingSchedule__c>bs= new List<Apttus_Billing__BillingSchedule__c>();
        Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
        bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__AssetLineItemId__c = assetLineItem1.Id;
        bilScdl.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl.Apttus_Billing__FeeAmount__c = 250;
        bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__Type__c = 'Contracted';
        bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        insert bilScdl;
       // bs.add(bilScdl);
        
        Apttus_Billing__BillingSchedule__c bilScdl1 = new Apttus_Billing__BillingSchedule__c ();
        bilScdl1.Apttus_Billing__BillToAccountId__c = account0.Id;
        bilScdl1.Apttus_Billing__AssetLineItemId__c = assetLineItem1.Id;
        bilScdl1.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl1.Apttus_Billing__FeeAmount__c = 0.012;
        bilScdl1.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl1.Apttus_Billing__Type__c = 'Contracted';
        bilScdl1.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl1.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl1.Apttus_Billing__PeriodEndDate__c = System.today().addDays(30);
        insert bilScdl1;
       // bs.add(bilScdl1);
        //insert bs;
        list<Apttus_Billing__BillingSchedule__c> bstest = [select id,Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c  from Apttus_Billing__BillingSchedule__c];
        system.debug('bstest----- '+bstest);
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        update assetLineItem1;
        bilScdl1.Apttus_Billing__FeeAmount__c = 350; 
        update bilScdl1;
        //bs[1].Apttus_Billing__FeeAmount__c = 350;
       // bs[1].Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsOptionRollupLine__c = true;
       // update bs[1];
        
        // APTS_BillingScheduleTriggerHandler bh = new APTS_BillingScheduleTriggerHandler ();  
        // bh.beforeInsert(bs); 
         test.stopTest();
        }
}