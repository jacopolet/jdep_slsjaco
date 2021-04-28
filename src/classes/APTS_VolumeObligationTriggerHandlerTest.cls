@isTest
private class APTS_VolumeObligationTriggerHandlerTest {
    
    public static Account oTestAccount;
    public static Contact oTestContact;
    public static Apttus_Config2__PriceList__c oTestPricelist;
    public static Apttus__APTS_Agreement__c oAggremt;
    public static List<APTS_AgreementTotalVolumeObligation__c> volobllist = new List<APTS_AgreementTotalVolumeObligation__c>();

    public static void init() {

        oTestAccount = APTS_TestUtils.createGrandParentAccount();
        Database.Insert(oTestAccount);
        
        Apttus_Config2__PriceList__c oPL = APTS_TestUtils.createPriceList();
        oPL.APTS_Region__c = 'SAP_0111';
        insert oPL;
        
        Apttus_Config2__ClassificationName__c coffeeOffering = APTS_TestUtils.createCategory();
        coffeeOffering.Name = 'Coffee';
        coffeeOffering.Apttus_Config2__HierarchyLabel__c = 'Coffee';
        insert coffeeOffering;
        
        Apttus_Config2__ClassificationName__c teaOffering = APTS_TestUtils.createCategory();
        teaOffering.Name = 'Tea';
        teaOffering.Apttus_Config2__HierarchyLabel__c = 'Tea';
        insert teaOffering;
        
        Apttus_Config2__ClassificationHierarchy__c coffeeCategory = APTS_TestUtils.createCategoryHierarchy(coffeeOffering.Id);
        coffeeCategory.Apttus_Config2__Label__c = 'Coffee';
        coffeeCategory.Name = 'Coffee';
        coffeeCategory.APTS_CategoryHierarchyOfferingExtId__c = '01';
        insert coffeeCategory;
        
        Apttus_Config2__ClassificationHierarchy__c teaCategory = APTS_TestUtils.createCategoryHierarchy(coffeeOffering.Id);
        teaCategory.Apttus_Config2__Label__c = 'Tea';
        teaCategory.Name = 'Tea';
        teaCategory.APTS_CategoryHierarchyOfferingExtId__c = '02';
        insert teaCategory;        
        
        Apttus_Config2__ClassificationHierarchy__c beansSubCat = APTS_TestUtils.createSubCategory(coffeeOffering.Id,coffeeCategory.Id);
        beansSubCat.Apttus_Config2__Label__c = 'Coffee|Beans';
        beansSubCat.Name = 'Beans';
        beansSubCat.APTS_CategoryHierarchyOfferingExtId__c = '0101';
        insert beansSubCat;
        
        Apttus_Config2__ClassificationHierarchy__c pickwickprofSubCat = APTS_TestUtils.createSubCategory(coffeeOffering.Id,coffeeCategory.Id);
        pickwickprofSubCat.Apttus_Config2__Label__c = 'Tea|Pickwick Professional';
        pickwickprofSubCat.Name = 'Pickwick Professional';
        pickwickprofSubCat.APTS_CategoryHierarchyOfferingExtId__c = '0201';
        insert pickwickprofSubCat;
        
        Apttus_Config2__ClassificationHierarchy__c cafeNoirSubSubCat = APTS_TestUtils.createSubSubCategory(coffeeOffering.Id,coffeeCategory.Id, beansSubCat.Id);
        cafeNoirSubSubCat.Apttus_Config2__Label__c = 'Coffee|Beans|Cafe Noir';
        cafeNoirSubSubCat.Name = 'Cafe Noir';
        cafeNoirSubSubCat.APTS_CategoryHierarchyOfferingExtId__c = '010101';
        insert cafeNoirSubSubCat;
        
        oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;        

        oAggremt = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, oTestAccount.Id);
        oAggremt.APTS_Region__c = 'SAP_0111';
        oAggremt.APTS_PricingDate__c = date.today().addDays(1);
        oAggremt.Apttus_CMConfig__PriceListId__c = oPL.id;
        insert oAggremt;

        insert new TriggerSettings__c(APTS_VolumeObligationTrigger__c = true);

        
        APTS_AgreementTotalVolumeObligation__c volobl = APTS_TestUtils.createTotalAgreementVolumeObligation(oAggremt.Id);
        volobl.APTS_Action__c = 'Invoice Customer';
        volobl.APTS_IncludeSelloutData__c = true;
        volobllist.add(volobl);

        volobl = APTS_TestUtils.createTotalAgreementVolumeObligation(oAggremt.Id);
        volobl.APTS_Action__c = 'Paid Service Fee';
        volobllist.add(volobl);

        volobl = APTS_TestUtils.createTotalAgreementVolumeObligation(oAggremt.Id);
        volobl.APTS_Action__c = 'Renegotiate Contract';
        volobllist.add(volobl);
        
        List<APTS_AverageListPriceCostPrice__c> oALCPList  =  new List<APTS_AverageListPriceCostPrice__c>();
        APTS_AverageListPriceCostPrice__c oALCP  =  new APTS_AverageListPriceCostPrice__c();
        oALCP.APTS_ALPCP_Category__c = 'SAP_01';
        oALCP.APTS_ALPCP_Subcategory__c = 'SAP_0101';
        oALCP.APTS_ALPCP_Subsubcat__c = 'SAP_010101';
        oALCP.APTS_ALPCP_SalesOrg__c = 'SAP_0111';
        oALCP.APTS_ALPCP_UnitOfMeasure__c = 'SAP_KGM';
        oALCP.APTS_Start_Date__c = system.today();
        oALCP.APTS_End_Date__c = system.today().addMonths(1);
        oALCPList.add(oALCP);
        
        APTS_AverageListPriceCostPrice__c oALCP2  =  new APTS_AverageListPriceCostPrice__c();
        oALCP2.APTS_ALPCP_Category__c = 'SAP_02';
        oALCP2.APTS_ALPCP_Subcategory__c = 'SAP_0201';
        oALCP2.APTS_ALPCP_SalesOrg__c = 'SAP_0111';
        oALCP2.APTS_ALPCP_UnitOfMeasure__c = 'SAP_KGM';
        oALCP2.APTS_Start_Date__c = system.today();
        oALCP2.APTS_End_Date__c = system.today().addMonths(1);
        oALCPList.add(oALCP2);
        insert oALCPList;

    }

    public static testMethod void createaggtest() {

        init();
        Test.startTest();
            
            insert volobllist;
            volobllist[1].APTS_Action__c = 'Invoice Customer';
            volobllist[0].APTS_Action__c = 'Paid Service Fee';
            update volobllist;

            delete volobllist[1];

            Apttus__APTS_Agreement__c oagg = [select id,APTS_VolumeObligationRelatedDetails__c from Apttus__APTS_Agreement__c where id=:oAggremt.Id];
            system.assertNotEquals(oagg.APTS_VolumeObligationRelatedDetails__c,null);           

        Test.stopTest();
    }
    
    public static testMethod void getALCPTest() {

        init();
        Test.startTest();
            
            volobllist[0].APTS_CategoryName__c = 'Coffee';
            volobllist[0].APTS_Categoryvalue__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Coffee' LIMIT 1].Id;
            volobllist[0].APTS_SubCategoryName__c = 'Beans';
            volobllist[0].APTS_SubCategoryValue__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Beans' LIMIT 1].Id;
            volobllist[0].APTS_Value_Name__c = 'Cafe Noir';
            volobllist[0].APTS_Value__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Cafe Noir' LIMIT 1].Id;
            volobllist[0].APTS_Type__c = 'SubSubCategory';
            volobllist[0].APTS_Unit_of_Measure__c = 'SAP_KGM';
            
            volobllist[1].APTS_CategoryName__c = 'Tea';
            volobllist[1].APTS_Categoryvalue__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea' LIMIT 1].Id;
            volobllist[1].APTS_SubCategoryName__c = 'Pickwick Professional';
            volobllist[1].APTS_SubCategoryValue__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Pickwick Professional' LIMIT 1].Id;
            volobllist[1].APTS_Value_Name__c = 'Pickwick Professional';
            volobllist[1].APTS_Value__c = [SELECT ID FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Pickwick Professional' LIMIT 1].Id;
            volobllist[1].APTS_Type__c = 'SubCategory';
            volobllist[1].APTS_Unit_of_Measure__c = 'SAP_KGM';
            //system.assertEquals('CAT: '+volobllist[1].APTS_Categoryvalue__c + ' SUBCAT: ' + volobllist[1].APTS_SubCategoryValue__c + ' VALUE: '+volobllist[1].APTS_Value__c, 'TEST');
            
            insert volobllist;
            update volobllist;
            
            APTS_AgreementTotalVolumeObligation__c oVAOSubCat = [SELECT ID,APTS_AverageListPriceCostPrice__c FROM APTS_AgreementTotalVolumeObligation__c WHERE Id =: volobllist[1].id];
            APTS_AgreementTotalVolumeObligation__c oVAOCat = [SELECT ID,APTS_AverageListPriceCostPrice__c FROM APTS_AgreementTotalVolumeObligation__c WHERE Id =: volobllist[0].id];
            
            //system.assert(oVAOCat.APTS_AverageListPriceCostPrice__c!=null);
            //system.assert(oVAOSubCat.APTS_AverageListPriceCostPrice__c!=null);
            
            

        Test.stopTest();
        

    } 
    
}