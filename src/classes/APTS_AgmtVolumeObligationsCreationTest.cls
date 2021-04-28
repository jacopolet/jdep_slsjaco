/*******************************************************************************************
Name            : APTS_AgmtVolumeObligationsCreationTest
Created By      : Beulah Ann Thomas
Created Date    : 07/18/2018
Description     : Test class written for 'APTS_AgmtVolumeObligationsCreation'.
Version history : v1.0 - Created - Beulah Ann Thomas
Classes Covered : APTS_AgmtVolumeObligationsCreation(% code coverage)  
*********************************************************************************************/
@isTest(SeeAllData=false)
private class APTS_AgmtVolumeObligationsCreationTest
{

    /* create test data */
    @TestSetup
    private static void createTestData()
    {

        User usr = APTS_TestUtils.createUser();
        
        //create Billing Preference
        Apttus_Config2__BillingPreference__c billingPreference = APTS_TestUtils.createBillingPrefrence('January');
        Database.Insert(billingPreference);
        // create Payment Method
        APTS_Payment_Method__c paymentMethod = APTS_TestUtils.paymentMethod();
        // Create Payment Term
        Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
        //Create Account
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        //Update Billing Key Fields
        account.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
        account.Apttus_Config2__PaymentTermId__c = paymentTerm.Id;
        account.APTS_Payment_Method__c = paymentMethod.Id;
        account.SAP_Customer_ID__c = null;
        account.Commercial_Register_Number__c = '1234';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
        Database.Insert(account);
         
        Product2 product = APTS_TestUtils.createProduct('Dummy High Tax', '26940998', 'Coffee');
        Database.Insert(product);
                        
        Product2 product2 = APTS_TestUtils.createProduct('Dummy Low Tax', '26940992', 'Coffee');
        Database.Insert(product2); 
        
        Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
        Database.Insert(category);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = 
            APTS_TestUtils.createCategoryHierarchy(category.Id);
        Database.Insert(categoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        Database.Insert(subCategoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = 
            APTS_TestUtils.createSubCategory(category.Id, categoryHierarchy.Id);
        Database.Insert(subSubCategoryHierarchy);      
        
        Apttus_Config2__ProductClassification__c productClassification = 
            APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        Database.Insert(productClassification);
        
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
               
        APTS_Fixed_Term_Dummy_Product__c dummyProduct = new APTS_Fixed_Term_Dummy_Product__c(name= 'High tax',
            Product_Name__c='Dummy High Tax');
        Database.Insert(dummyProduct);
        insert new TriggerSettings__c(Agreement__c = true);

        Id recId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        Apttus__APTS_Agreement__c   testAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                        Name = 'Test Agreement',RecordTypeId = recId,
                        Apttus__Contract_Start_Date__c = Date.today(), 
                        Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,
                        Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', 
                        Apttus__Status__c = 'Internal Signatures',Apttus__Version_Number__c=0,Apttus__Agreement_Number__c='00281226');
        
        Apttus__APTS_Agreement__c   testAgreement1 = new Apttus__APTS_Agreement__c(Apttus__Account__c = account.Id, 
                        Name = 'Test Agreement1',RecordTypeId = recId,
                        Apttus__Contract_Start_Date__c = Date.today(), 
                        Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,
                        Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'In Signatures', 
                        Apttus__Status__c = 'Internal Signatures',Apttus__Agreement_Number__c='00281226',
                        Apttus__Version_Number__c=1);
        
        List<Apttus__APTS_Agreement__c> insertAgrList = new List<Apttus__APTS_Agreement__c>{testAgreement,testAgreement1};
        Database.insert(insertAgrList);

        Apttus__APTS_Related_Agreement__c relAgr = new Apttus__APTS_Related_Agreement__c();
        relAgr.Apttus__APTS_Contract_From__c = testAgreement.id;
        relAgr.Apttus__APTS_Contract_To__c = testAgreement1.Id;
        Database.insert(relAgr);
        
        Apttus__AgreementLineItem__c agreementLineItem = new Apttus__AgreementLineItem__c();
        agreementLineItem.Apttus__ProductId__c = product.Id;
        agreementLineItem.Apttus__AgreementId__c = testAgreement.Id;
        agreementLineItem.Apttus__Quantity__c = 1;
        Database.Insert(agreementLineItem);
        
        Apttus__AgreementLineItem__c agreementLineItem2 = new Apttus__AgreementLineItem__c();
        agreementLineItem2.Apttus__ProductId__c = product2.Id;
        agreementLineItem2.Apttus__AgreementId__c = testAgreement.Id;
        agreementLineItem2.Apttus__Quantity__c = 1;
        Database.Insert(agreementLineItem2);
    
        
        List<APTS_AgreementTotalVolumeObligation__c> lstVolumeObligation = 
        new List<APTS_AgreementTotalVolumeObligation__c>();
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = 
        APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='SubCategory';
        agmtVolumeObligation.APTS_Value__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        lstVolumeObligation.add(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = 
        APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        lstVolumeObligation.add(agmtVolumeObligation1);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = 
        APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement1.id);
        agmtVolumeObligation2.APTS_Type__c='SubCategory';
        agmtVolumeObligation2.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100; 
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=500;
        lstVolumeObligation.add(agmtVolumeObligation2);

        INSERT lstVolumeObligation;
        
    }
        private static testMethod void activeAgreement()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
        List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstAgreementupdate = new List<Apttus__APTS_Agreement__c>();
        /*Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%Test %' LIMIT 1];
                
        testAgreement.Apttus__Status_Category__c = 'In Effect';
        testAgreement.Apttus__Status__c = 'Activated';
        lstAgreement.add(testAgreement);
        mapAgreement.put(testAgreement.Id, testAgreement);*/

        /*Activate first version Agreement*/
        for(Apttus__APTS_Agreement__c testAgreement : [SELECT Id,Name,APTS_Country__c,recordtype.name,Apttus__Contract_Start_Date__c,Apttus__Contract_End_Date__c FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name = 'Test Agreement']){
             testAgreement.Apttus__Status_Category__c = 'In Effect';
             testAgreement.Apttus__Status__c = 'Activated';  
             lstAgreement.add(testAgreement); 
             lstAgreementupdate.add(testAgreement);                                    
        }
        
        test.startTest();
        System.runAs(testUser) 
        {
           Database.Update(lstAgreementupdate);
        }
        APTS_AgreementVolumeObligation__c sched = [Select Id From APTS_AgreementVolumeObligation__c where APTS_Agreement__c=:lstAgreement[0].Id Limit 1];
        APTS_Agreement_Volume_Obligation_Line__c voliLine = new APTS_Agreement_Volume_Obligation_Line__c();
        voliLine.APTS_Agreement__c=lstAgreement[0].id;
        voliLine.APTS_Agreement_Volume_Obligation__c=sched.Id;
        voliLine.APTS_Ordered_Quantity__c=10;
        voliLine.APTS_Inactive__c=false;
        insert voliLine;
        lstAgreementupdate.clear();
        for(Apttus__APTS_Agreement__c testAgreement : [SELECT Id,Name,APTS_Country__c,recordtype.name,Apttus__Contract_Start_Date__c,Apttus__Contract_End_Date__c FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name = 'Test Agreement1']){
             testAgreement.Apttus__Status_Category__c = 'In Effect';
             testAgreement.Apttus__Status__c = 'Activated';  
             lstAgreement.add(testAgreement);
             lstAgreementupdate.add(testAgreement);                                     
        }
        
        System.runAs(testUser) 
        {
            Database.Update(lstAgreementupdate);
        }
        Apttus__APTS_Related_Agreement__c relagr = [Select Id,Apttus__APTS_Contract_To__c,Apttus__APTS_Contract_From__c From Apttus__APTS_Related_Agreement__c Where Apttus__APTS_Contract_To__c =: lstAgreement[1].Id];
        //System.assert(lstAgreement != null);
        test.stopTest();
        List<APTS_AgreementVolumeObligation__c> agreementVolumeObligationlst = [Select id,APTS_Start_Date__c,APTS_End_Date__c from APTS_AgreementVolumeObligation__c];
         /* ---------- Start of PI fix # 918050----------------------- */
        system.assertequals(agreementVolumeObligationlst[0].APTS_Start_Date__c,lstAgreement[0].Apttus__Contract_Start_Date__c);
        system.assertequals(agreementVolumeObligationlst[11].APTS_End_Date__c,lstAgreement[0].Apttus__Contract_End_Date__c); 
        system.assertequals(14,agreementVolumeObligationlst.size());
        /* ---------- End of PI fix # 918050 ----------------------- */


    }
    /* ---------- Start of PI fix # 918050----------------------- */
    private static testMethod void inActiveAgreement()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Account> accountList = [SELECT Id FROM Account LIMIT 1];
        List<Apttus__APTS_Agreement__c> lstAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE '%Test %']; 
        Map<Id, Apttus__APTS_Agreement__c> mapAgreement = new Map<Id, Apttus__APTS_Agreement__c>();
        mapAgreement.put(lstAgreement[0].Id, lstAgreement[0]);
        APTS_AgreementTriggerHandler agreementHandler = new APTS_AgreementTriggerHandler();
        test.startTest();
        System.runAs(testUser) 
        {
            Database.Update(lstAgreement);
        }
        System.assert(lstAgreement != null);
        test.stopTest();
        List<APTS_AgreementVolumeObligation__c> agreementVolumeObligationlst = [Select id from APTS_AgreementVolumeObligation__c];
        system.assertequals(0,agreementVolumeObligationlst.size());
    }
    /* ---------- End of PI fix # 918050 ----------------------- */
}