/**
 * @description       : APTS_InitiateAgreementController Test class for APTS_InitiateAgreementController
 * @author            : Renuka Ganesan
 * @group             : 
 * @last modified on  : 20-04-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   10-04-2020  Renuka Ganesan   Initial Version
 * 2.0   12.04.2021  Karan Khatri  Added Catalaog Changes
**/

@isTest
public with sharing class APTS_InitiateAgreementControllerTest{
    @TestSetup
    private static void createTestData(){
        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
            Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            
            TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
            objTriggerSettings.AccountTrigger__c = false;
            objTriggerSettings.Agreement__c = false;
            //objTriggerSettings.APTS_Order_Trigger__c = false;
            Database.insert(objTriggerSettings, false);
            
            //create Billing Preference
            Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
            Database.Insert(billingPreference);
            // Create Payment Term
            Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
            //Create Account
            Account account = APTS_TestUtils.createGrandParentAccount();
            //Update Billing Key Fields
            account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
            account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
            account.SAP_Customer_ID__c = null;
            account.Commercial_Register_Number__c = '1234';
            account.BillingCountry = 'Netherlands';
            account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
            Database.Insert(account);
            
            Account acc2 = APTS_TestUtils.createParentAccount(account);
            insert acc2;
            Account acc3 = APTS_TestUtils.createChildAccount(acc2);
            insert acc3;
            
            //Create Contact
            Contact oContact = APTS_TestUtils.createContact();
            oContact.Authorized_Signer__c = true;
            oContact.Main_Commercial_Person__c = true;
            oContact.AccountId = acc3.Id;
            insert oContact;
            
            Id oppStandardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();

            List<Apttus_Config2__PriceList__c> plList = new List<Apttus_Config2__PriceList__c>();
            Apttus_Config2__PriceList__c directPriceList = new Apttus_Config2__PriceList__c(Name = 'General Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Direct');
            Apttus_Config2__PriceList__c indirectPriceList = new Apttus_Config2__PriceList__c(Name = 'Indirect Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Indirect');
            Apttus_Config2__PriceList__c routesalesPriceList = new Apttus_Config2__PriceList__c(Name = 'Routesales Price List', Apttus_Config2__Active__c = true, CurrencyIsoCode = 'EUR', APTS_Region__c = 'SAP_0111', APTS_SalesOrg__c = '0111', APTS_PriceList_Type__c = 'Routesales');
            plList.add(directPriceList);
            plList.add(indirectPriceList);
            plList.add(routesalesPriceList);
            insert plList;

            List<Opportunity> oppList = new List<Opportunity>();
            for (Account acc : [SELECT Id, Name, Partner__c, Sales_Organization__c FROM Account Where Parent.ParentId != null]) {
                Opportunity opp = new Opportunity();
                opp.AccountID = acc.id;
                opp.Name = 'Test';
                opp.RecordTypeId = oppStandardRecordTypeId;
                opp.StageName = 'Develop Proposal / Presentation';
                opp.CloseDate = Date.today().addMonths(3);
                opp.CurrencyIsoCode = 'EUR';
                opplist.add(opp);
            }
            insert opplist;
        	
            //2.0 version
            //insert pricelist
            Apttus_Config2__PriceList__c plist = APTS_TestUtils.createPriceList();
            plist.Apttus_Config2__BasedOnPriceListId__c = null;
            plist.name = 'Category Price List test';
            insert plist;

            Apttus_Config2__PriceList__c plist1 = APTS_TestUtils.createPriceList();
            plist1.Apttus_Config2__BasedOnPriceListId__c = plist.id;
            plist1.name = 'Category Price List test CSP';
            insert plist1;

            //insert products
            List<Product2> productList = new  List<Product2>();
            for(Integer i=0;i<=10;i++){
                Product2 prod1 = APTS_TestDataFactory.createProduct('Prod'+i,'1122'+i,'Machine','Bundle',false,true); 
                prod1.APTS_Replaced_by__c='9825'+i;
                productList.add(prod1);
            }
            insert productList;

            List<Product2> teaproductList = new  List<Product2>();
            for(Integer i=0;i<=10;i++){
                Product2 prod1 = APTS_TestDataFactory.createProduct('TeaProd'+i,'1221'+i,'Machine','Bundle',false,true); 
                prod1.APTS_Replaced_by__c='9829'+i;
                teaproductList.add(prod1);
            }
            insert teaproductList;

            //Spare Parts Category
            Apttus_Config2__ClassificationName__c sparePartsCategory = APTS_TestDataFactory.createCategory();
            sparePartsCategory.name='Spare Parts';
            sparePartsCategory.Apttus_Config2__HierarchyLabel__c='Spare Parts';
            insert sparePartsCategory;
    
            Apttus_Config2__PriceListCategory__c pricelistSPCat = new Apttus_Config2__PriceListCategory__c();
            pricelistSPCat.Apttus_Config2__HierarchyId__c=sparePartsCategory.id;
            pricelistSPCat.Apttus_Config2__PriceListId__c=plist.id;
            pricelistSPCat.Apttus_Config2__Sequence__c=1;
            insert pricelistSPCat;
    
            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel0SPHierarchy = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c spCategoryHierarchyL0 = APTS_TestDataFactory.createCategoryHierarchy(sparePartsCategory.id,'Spare Parts L1');
                //spCategoryHierarchyL0.Apttus_Config2__AncestorId__c=listofLevel0Hierarchy[i].id;
                spCategoryHierarchyL0.Apttus_Config2__Level__c = 0;
                listofLevel0SPHierarchy.add(spCategoryHierarchyL0);
            }
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c spCategoryHierarchyL0 = APTS_TestDataFactory.createCategoryHierarchy(sparePartsCategory.id,'Spare Parts L1');
                //spCategoryHierarchyL0.Apttus_Config2__HierarchyId__c=listofLevel0Hierarchy[i].id;
                spCategoryHierarchyL0.Apttus_Config2__Level__c = 0;
                listofLevel0SPHierarchy.add(spCategoryHierarchyL0);
            }
            insert listofLevel0SPHierarchy;
    
            List<Apttus_Config2__ProductClassification__c> prodClassListsp = new List<Apttus_Config2__ProductClassification__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel0SPHierarchy[i].id,productList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassListsp.add(prodClass);
            }
            for(Integer i=0;i<=5;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel0SPHierarchy[1].id,productList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassListsp.add(prodClass);
            }
            insert prodClassListsp;

            //Coffee Category
            Apttus_Config2__ClassificationName__c coffeeCategory = APTS_TestDataFactory.createCategory();
            coffeeCategory.name='Coffee';
            coffeeCategory.Apttus_Config2__HierarchyLabel__c='Coffee';
            insert coffeeCategory;

            Apttus_Config2__PriceListCategory__c pricelistCoffeeCat = new Apttus_Config2__PriceListCategory__c();
            pricelistCoffeeCat.Apttus_Config2__HierarchyId__c=coffeeCategory.id;
            pricelistCoffeeCat.Apttus_Config2__PriceListId__c=plist.id;
            pricelistCoffeeCat.Apttus_Config2__Sequence__c=1;
            insert pricelistCoffeeCat;

            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel0Hierarchy = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c coffeeCategoryHierarchyL0a = APTS_TestDataFactory.createCategoryHierarchy(coffeeCategory.id,'Coffee L'+i);
                //coffeeCategoryHierarchyL2.Apttus_Config2__AncestorId__c=coffeeCategoryHierarchyL1.id;
                coffeeCategoryHierarchyL0a.Apttus_Config2__Level__c = 0;
                listofLevel0Hierarchy.add(coffeeCategoryHierarchyL0a);
            }
            insert listofLevel0Hierarchy;

            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel1Hierarchy = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c coffeeCategoryHierarchyL1 = APTS_TestDataFactory.createCategoryHierarchy(coffeeCategory.id,'Coffee L1');
                coffeeCategoryHierarchyL1.Apttus_Config2__AncestorId__c=listofLevel0Hierarchy[i].id;
                coffeeCategoryHierarchyL1.Apttus_Config2__Level__c = 1;
                listofLevel1Hierarchy.add(coffeeCategoryHierarchyL1);
            }
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c coffeeCategoryHierarchyL1 = APTS_TestDataFactory.createCategoryHierarchy(coffeeCategory.id,'Coffee L1');
                coffeeCategoryHierarchyL1.Apttus_Config2__AncestorId__c=listofLevel0Hierarchy[i].id;
                coffeeCategoryHierarchyL1.Apttus_Config2__Level__c = 1;
                listofLevel1Hierarchy.add(coffeeCategoryHierarchyL1);
            }
            insert listofLevel1Hierarchy;

            List<Apttus_Config2__ProductClassification__c> prodClassList = new List<Apttus_Config2__ProductClassification__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel1Hierarchy[i].id,productList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassList.add(prodClass);
            }
            for(Integer i=0;i<=5;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel1Hierarchy[1].id,productList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassList.add(prodClass);
            }
            insert prodClassList;

            //Coffee Category
            Apttus_Config2__ClassificationName__c teaCategory = APTS_TestDataFactory.createCategory();
            teaCategory.name='Coffee';
            teaCategory.Apttus_Config2__HierarchyLabel__c='Coffee';
            insert teaCategory;
    
            Apttus_Config2__PriceListCategory__c pricelistteaCat = new Apttus_Config2__PriceListCategory__c();
            pricelistteaCat.Apttus_Config2__HierarchyId__c=teaCategory.id;
            pricelistteaCat.Apttus_Config2__PriceListId__c=plist.id;
            pricelistteaCat.Apttus_Config2__Sequence__c=1;
            insert pricelistteaCat;
    
            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel0HierarchyTea = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c teaCategoryHierarchyL0a = APTS_TestDataFactory.createCategoryHierarchy(teaCategory.id,'Tea L0'+i);
                //coffeeCategoryHierarchyL2.Apttus_Config2__AncestorId__c=coffeeCategoryHierarchyL1.id;
                teaCategoryHierarchyL0a.Apttus_Config2__Level__c = 0;
                listofLevel0HierarchyTea.add(teaCategoryHierarchyL0a);
            }
            insert listofLevel0HierarchyTea;
    
            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel1Hierarchytea = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c teaCategoryHierarchyL1 = APTS_TestDataFactory.createCategoryHierarchy(teaCategory.id,'Tea L1a'+i);
                teaCategoryHierarchyL1.Apttus_Config2__AncestorId__c=listofLevel0HierarchyTea[i].id;
                teaCategoryHierarchyL1.Apttus_Config2__Level__c = 1;
                listofLevel1Hierarchytea.add(teaCategoryHierarchyL1);
            }
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c teaCategoryHierarchyL1 = APTS_TestDataFactory.createCategoryHierarchy(teaCategory.id,'Coffee L1b'+i);
                teaCategoryHierarchyL1.Apttus_Config2__AncestorId__c=listofLevel0HierarchyTea[i].id;
                teaCategoryHierarchyL1.Apttus_Config2__Level__c = 1;
                listofLevel1Hierarchytea.add(teaCategoryHierarchyL1);
            }
            insert listofLevel1Hierarchytea;
    
            List<Apttus_Config2__ClassificationHierarchy__c> listofLevel2HierarchyTea = new List<Apttus_Config2__ClassificationHierarchy__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c teaCategoryHierarchyL2 = APTS_TestDataFactory.createCategoryHierarchy(teaCategory.id,'Coffee L2a'+i);
                teaCategoryHierarchyL2.Apttus_Config2__AncestorId__c=listofLevel1Hierarchy[i].id;
                teaCategoryHierarchyL2.Apttus_Config2__Level__c = 2;
                listofLevel2HierarchyTea.add(teaCategoryHierarchyL2);
            }
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ClassificationHierarchy__c teaCategoryHierarchyL2 = APTS_TestDataFactory.createCategoryHierarchy(teaCategory.id,'Coffee L2b'+i);
                teaCategoryHierarchyL2.Apttus_Config2__AncestorId__c=listofLevel1Hierarchy[i].id;
                teaCategoryHierarchyL2.Apttus_Config2__Level__c = 2;
                listofLevel2HierarchyTea.add(teaCategoryHierarchyL2);
            }
            insert listofLevel2HierarchyTea;
    
            List<Apttus_Config2__ProductClassification__c> prodClassListTea = new List<Apttus_Config2__ProductClassification__c>();
            for(Integer i=0;i<=10;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel2HierarchyTea[i].id,teaproductList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassListTea.add(prodClass);
            }
            for(Integer i=0;i<=5;i++){
                Apttus_Config2__ProductClassification__c prodClass = APTS_TestDataFactory.createProductClassification(listofLevel2HierarchyTea[1].id,teaproductList[i].id);
                prodClass.Apttus_Config2__Sequence__c=i;
                prodClassListTea.add(prodClass);
            }
            insert prodClassListTea;
        }
    }
    private static testMethod void initiateAgreementFirstPage() {
        Account acc = new Account();
        Opportunity opp = [Select Id,AccountID  From Opportunity Where AccountID != null];
        Apttus_Config2__PriceList__c direct = [Select Id From Apttus_Config2__PriceList__c Where Name = 'General Price List'];
        Apttus_Config2__PriceList__c indirect = [Select Id From Apttus_Config2__PriceList__c Where Name = 'Indirect Price List'];
        Contact con = [Select Id From Contact];
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));
        Date expectedStartDate = Date.newInstance(2021, 04, 01);
        Date expectedEndDate = Date.newInstance(2029, 02, 07);
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper1 = APTS_InitiateAgreementController.getDuration(String.valueOf(expectedStartDate),String.valueOf(expectedEndDate),60.00,'EndDate'); 
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper2 = APTS_InitiateAgreementController.getDuration(String.valueOf(expectedStartDate),String.valueOf(expectedEndDate),60.00,'Duration'); 
        String agreementInputJSON = '{"accId":"0011q00000ciGSL","autoRenew":true,"contractPeriod":60,"dealType":"Standard","delivery":"","endDate":"2026-04-10","oppId":"0061q000009lD1W","ordering":"","priceListId":"a4m0Q0000001V03QAE","routeSales":false,"startDate":"2021-04-10","subType":"Regular"}'; 
        APTS_InitiateAgreementController.setAgreementfields(agreementInputJSON);
        
        acc = [Select Id,ParentId,APTS_Price_List__c,Partner__c From Account Where Id =: opp.AccountId];
        acc.ParentId = null;
        update acc;
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper3 = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));        
        
        acc.Partner__c = true;
        update acc;
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper5 = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));        
        system.assertEquals(agrWrapper5.priceListId,String.valueOf(indirect.Id));
        
        acc.APTS_Price_List__c = direct.Id;
        update acc;
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper4 = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));        
        system.assertEquals(agrWrapper4.priceListId,String.valueOf(direct.Id));
        system.assertEquals(agrWrapper4.conId,String.valueOf(con.Id));
    }
    private static testMethod void defaultDirectPriceList() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Account> accList = [SELECT Id, Partner__c FROM Account Where Parent.ParentId != null];
        Apttus_Config2__PriceList__c direct = [Select Id From Apttus_Config2__PriceList__c Where Name = 'General Price List'];
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Opportunity opp = [SELECT Id, AccountId, Account.Name FROM Opportunity ];
        Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
        agg.Name = opp.Account.Name + ' Agreement';
        agg.Apttus__Account__c = opp.AccountId;
        agg.RecordTypeId = standardDealRT;
        agg.Apttus__Related_Opportunity__c = opp.id;
        agg.Apttus__Status_Category__c = 'In Effect';
        agg.Apttus__Status__c = 'Activated' ;
        agg.Apttus_CMConfig__PriceListId__c = direct.Id;
        agg.Apttus__Contract_Start_Date__c = Date.today();
        agg.Apttus__Contract_End_Date__c = Date.today().addYears(5);
            
        test.startTest();
        database.insert(agg);
        test.stopTest();
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));
        
        system.assertEquals(agrWrapper.priceListId,String.valueOf(agg.Apttus_CMConfig__PriceListId__c));
    }
    private static testMethod void defaultCSPPriceList() {
        Id standardDealRT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        List<Account> accList = [SELECT Id, Partner__c FROM Account Where Parent.ParentId != null];
        Apttus_Config2__PriceList__c direct = [Select Id From Apttus_Config2__PriceList__c Where Name = 'Category Price List test CSP'];
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Opportunity opp = [SELECT Id, AccountId, Account.Name FROM Opportunity ];
        Apttus__APTS_Agreement__c agg = new Apttus__APTS_Agreement__c();
        agg.Name = opp.Account.Name + ' Agreement';
        agg.Apttus__Account__c = opp.AccountId;
        agg.RecordTypeId = standardDealRT;
        agg.Apttus__Related_Opportunity__c = opp.id;
        agg.Apttus__Status_Category__c = 'In Effect';
        agg.Apttus__Status__c = 'Activated' ;
        agg.Apttus_CMConfig__PriceListId__c = direct.Id;
        agg.Apttus__Contract_Start_Date__c = Date.today();
        agg.Apttus__Contract_End_Date__c = Date.today().addYears(5);
            
        test.startTest();
        database.insert(agg);
        test.stopTest();
        APTS_InitiateAgreementController.AgreementWrapper agrWrapper = APTS_InitiateAgreementController.getAgreementfields(String.valueOf(opp.Id),String.valueOf(opp.AccountID));
        
        system.assertEquals(agrWrapper.priceListId,String.valueOf(agg.Apttus_CMConfig__PriceListId__c));
    }
     //2.0 version
    private static testMethod void test_logicCategoryPage() {
        List<Apttus_Config2__PriceListCategory__c> pricelistCategoryList = new List<Apttus_Config2__PriceListCategory__c>();
        Apttus_Config2__PriceList__c pricelist = [select id from Apttus_Config2__PriceList__c where name='Category Price List test'];
        String agreementwrapper = '{"priceListId":"'+pricelist.id+'","parentPriceListId":null}';
        test.startTest();
        List<APTS_InitiateAgreementController.Categories> categoryWrapper= APTS_InitiateAgreementController.getAllCategoryDetails(agreementwrapper);
        system.assertEquals(4, categoryWrapper.size());

        Apttus_Config2__PriceList__c pricelistCSP = [select id,Apttus_Config2__BasedOnPriceListId__c from Apttus_Config2__PriceList__c where name='Category Price List test CSP'];
        String agreementwrapper1 = '{"priceListId":"'+pricelistCSP.id+'","parentPriceListId":"'+pricelist.id+'"}';
        List<APTS_InitiateAgreementController.Categories> categoryWrapper1= APTS_InitiateAgreementController.getAllCategoryDetails(agreementwrapper1);
        system.assertEquals(4, categoryWrapper.size());
        test.stopTest();

    }
}