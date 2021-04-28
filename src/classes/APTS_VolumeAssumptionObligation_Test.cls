/**
* Class Name : APTS_VolumeAssumptionObligation_Test
* Description :  Apex Class to test APTS_VolumeAssumptionObligation Class
* Author : Vigitha
* Date Created : 04/23/2018
**/
@isTest
private class APTS_VolumeAssumptionObligation_Test{

     /* Test Method which is used to create all test data */
        @TestSetup
    private static void createTestData()
    {
        User usr = APTS_TestUtils.createUser();
        
        /*Create Account*/
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        /*create Agreement */             
        Apttus__APTS_Agreement__c testAgreement= APTS_TestUtils.createconsumptionAgreement(null,null,null,account.Id);
        testAgreement.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement.APTS_Bill_to_Party_MachServ__c=null;
        testAgreement.Name='Agreement1';
        testAgreement.APTS_Language__c ='SAP_NL';
        testAgreement.APTS_Preferred_way_of_ingredient_deliver__c = 'RouteSales';
        
        /*create Agreement*/               
        Apttus__APTS_Agreement__c testAgreement4= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement4.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement4.APTS_Bill_to_Party_MachServ__c=null;
        testAgreement4.APTS_Language__c ='SAP_FR';
        testAgreement.APTS_Preferred_way_of_ingredient_deliver__c = 'RouteSales';
        testAgreement.Apttus__Version_Number__c=0;
        testAgreement.Apttus__Agreement_Number__c='00281226';
        
        /*Amended Agreement*/
        Apttus__APTS_Agreement__c testAgreement5= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement5.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement5.APTS_Bill_to_Party_MachServ__c=null;
        testAgreement5.APTS_Language__c ='SAP_FR';
        testAgreement5.APTS_Preferred_way_of_ingredient_deliver__c = 'RouteSales';
        testAgreement5.Apttus__Version_Number__c=1;
        testAgreement5.Apttus__Agreement_Number__c='00281226';
        testAgreement5.Name = 'Agreement12';

        List<Apttus__APTS_Agreement__c> insertAgrList = new List<Apttus__APTS_Agreement__c>{testAgreement,testAgreement4,testAgreement5};
        Database.insert(insertAgrList);

        /*Related Agreement for Amended Agreement*/
        Apttus__APTS_Related_Agreement__c relAgr = new Apttus__APTS_Related_Agreement__c();
        relAgr.Apttus__APTS_Contract_From__c = testAgreement4.id;
        relAgr.Apttus__APTS_Contract_To__c = testAgreement5.Id;
        Database.insert(relAgr);

      /*                
        Apttus__APTS_Agreement__c testAgreement1= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement1.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement1.APTS_Bill_to_Party_MachServ__c=null;
        testAgreement1.Name='Agreement1';
        testAgreement1.APTS_Language__c ='SAP_SV';
        testAgreement1.APTS_Preferred_way_of_ingredient_deliver__c = 'RouteSales';
        Database.insert(testAgreement1);
*/

        /*create category*/
        Apttus_Config2__ClassificationName__c category = APTS_TestUtils.createCategory();
        category.Name = '&More';
        category.Apttus_Config2__HierarchyLabel__c = '&More';
        category.Apttus_Config2__Type__c = 'Offering';
        Database.insert(category);   
        
        /* create category hierarchy */
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id);
        categoryHierarchy.Name = '& More|Accessoires';
        categoryHierarchy.Apttus_Config2__Label__c = '& More|Accessoires';
        Database.insert(categoryHierarchy);
         
        /* create sub-category */    
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id); 
        subCategoryHierarchy.Name = 'Milk';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Milk';
        subCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__Right__c = 3;
        Database.insert(subCategoryHierarchy);
        
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy2 = APTS_TestUtils.createCategoryHierarchy(category.Id);
        subCategoryHierarchy2.Name = 'Sugar';
        subCategoryHierarchy2.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy2.Apttus_Config2__HierarchyId__c = category.Id;
        subCategoryHierarchy2.Apttus_Config2__AncestorId__c = categoryHierarchy.Id;
        subCategoryHierarchy2.Apttus_Config2__Label__c = 'Sugar';
        subCategoryHierarchy2.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy2.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy2.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchy2.Apttus_Config2__Right__c = 3;
        Database.insert(subCategoryHierarchy2);
            
        /*create subsub-category*/
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy2 = APTS_TestUtils.createCategoryHierarchy(category.Id); 
        subSubCategoryHierarchy2.Name = 'Machines';
        subSubCategoryHierarchy2.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy2.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchy2.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;           
        subSubCategoryHierarchy2.Apttus_Config2__Label__c = 'Machines';
        subSubCategoryHierarchy2.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy2.Apttus_Config2__Level__c = 2;
        subSubCategoryHierarchy2.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subSubCategoryHierarchy2.Apttus_Config2__Right__c = 3;
        Database.insert(subSubCategoryHierarchy2);
        
        /*create subsub-category*/
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy3 = APTS_TestUtils.createCategoryHierarchy(category.Id); 
        subSubCategoryHierarchy3.Name = 'Espresso';
        subSubCategoryHierarchy3.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy3.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchy3.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;           
        subSubCategoryHierarchy3.Apttus_Config2__Label__c = 'Espresso';
        subSubCategoryHierarchy3.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy3.Apttus_Config2__Level__c = 2;
        subSubCategoryHierarchy3.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subSubCategoryHierarchy3.Apttus_Config2__Right__c = 3;
        Database.insert(subSubCategoryHierarchy3);
        
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id); 
        subSubCategoryHierarchy.Name = 'Chocolate Milk';
        subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';    
        subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Chocolate Milk';
        subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;  
        subSubCategoryHierarchy.Apttus_Config2__Level__c = 2;       
        subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;       
        subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
        Database.insert(subSubCategoryHierarchy);

        }
        
     /* Test Method which is used to calculate RebatePayout for Revenue with Highest Tier*/
    private static testMethod void calRebateForRevenueWithHighTier()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                    
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+') OR (Category = '+subCategoryHierarchy.id+') OR (Category = '+subSubCategoryHierarchy.id+')';
        instanceParse.fields= field;
        //instanceParse.filter=Filter:[childFilter=null, condExpr=1 OR 2 OR 3, hasRHSFields=false, predicates=(Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXYtQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=1], Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXZrQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=2], Predicates:[BoolOper=null, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXd5QAG, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=3])];
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=300;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM1 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM1.Apttus_Config2__ConversionFactor__c=4;
        testUOM1.CurrencyIsoCode='';
        testUOM1.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM1.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM1.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM1);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM2 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM2.Apttus_Config2__ConversionFactor__c=4;
        testUOM2.CurrencyIsoCode='';
        testUOM2.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM2.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM2.APTS_Product_Family2__c='Chocolate Milk';
        Database.insert(testUOM2);
                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        //agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        Database.insert(agmtVolumeObligation1);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation2); 

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation4 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation4.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation4.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation4.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation4.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation4.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation4.APTS_NumberofDrinks__c=null;
        agmtVolumeObligation4.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation4.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation4.APTS_GrossSale__c=200; 
        agmtVolumeObligation4.APTS_NetSale__c=100;
        agmtVolumeObligation4.APTS_VolumeObligationPercentage__c=null;  
        Database.insert(agmtVolumeObligation4); 
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c='Machines';
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation3);

               
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('index','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_KGM');
        ApexPages.currentPage().getParameters().put('selValue',categoryHierarchy.Id);
        
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machines');
        //volAss.getVolumeAssumptiocategory();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.getVolumeAssumptioproduct();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        system.assertEquals(updatedVolOblig.APTS_Rebate_Payout__c,Null);
        volAss.getDependentsubcat();
        volAss.getDependentsubcatsec();
        volAss.getSubObligation();
        ApexPages.currentPage().getParameters().put('selValue',subCategoryHierarchy.Id);
        volAss.getDependentsubsubcat();
        ApexPages.currentPage().getParameters().put('percent','4');
        //volAss.getSubsubObligation();
        //volAss.addNewRowTocatList();
        volAss.addNewRowTosubCatList();
        volAss.addNewRowTosubsubList();
        volAss.addNewRowToPrdList();
        volAss.rowToRemove=0;
        volAss.getremoveRowFromsubCatList();
        volAss.getremoveRowFromsubList();
        volAss.getremoveRowFromsubsubList();
        volAss.getremoveRowFromPrdList();
        volAss.saveasmpObj();
        volAss.cancelSave();
        volAss.saveClose();
    }
    /* method to cover the else part*/
 
   
    
    /* Test Method which is used to calculate RebatePayout for Revenue with Highest Tier*/
    private static testMethod void calRebateForRevenueWithHighTier7()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='300';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
                                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_NumberofDrinks__c=250;
        Database.insert(agmtVolumeObligation);
                               
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');

        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
        //volAss.getVolumeAssumptiocategory();
        volAss.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
    }
    
    /* Test Method which is used to calculate RebatePayout for Volume of Consumption Model*/
    private static testMethod void calConsRebateForVolume()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement1' LIMIT 1];
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Volume';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry1 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry1.Apttus_Config2__Dimension4Value__c='200';
        testPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c=6;
        testPriceRuleEntry1.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry2 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry2.Apttus_Config2__Dimension4Value__c='300';
        testPriceRuleEntry2.Apttus_Config2__AdjustmentAmount__c=9;
        testPriceRuleEntry2.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry2);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=3;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=250;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        //ApexPages.currentPage().getParameters().put('index','0');

        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        //volAss.getVolumeAssumptiocategory();
        volAss.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        volAss.cancelSave();
        volAss.saveClose();
        
    }
    
    /* Test Method which is used to calculate RebatePayout for Revenue with Rate per each Tier*/
    private static testMethod void calRebateForVolumeWithRateTier()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name,Apttus__FF_Agreement_Number__c FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Volume';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM);
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        agmtVolumeObligation2.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        agmtVolumeObligation2.APTS_VolumeAssumption__c=100;  
        Database.insert(agmtVolumeObligation2); 

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation3.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation3.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        agmtVolumeObligation3.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation3.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10;  
        agmtVolumeObligation3.APTS_VolumeAssumption__c=null;  
        Database.insert(agmtVolumeObligation3); 
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        ApexPages.currentPage().getParameters().put('index','');
        
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation2.Id];
        volAss.cancelSave();
        volAss.saveClose();
        volAss.getSubsubObligation();

        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        ApexPages.currentPage().getParameters().put('index','0');
        
        /*Activate the Agreement*/
        testAgreement.Apttus__Status_Category__c='In Effect';
        testAgreement.Apttus__Status__c='Activated';
        testAgreement.Apttus__Contract_Start_Date__c = system.today();
        testAgreement.Apttus__Contract_End_Date__c=system.today()+365;
        insert new TriggerSettings__c(APTS_IndexContractTrigger__c = true, Agreement__c = true, APTS_AgreementPODetails__c = true);
        update testAgreement;
        APTS_AgreementVolumeObligation__c sched = [Select Id From APTS_AgreementVolumeObligation__c where APTS_Agreement__c=:testAgreement.Id Limit 1];
        APTS_Agreement_Volume_Obligation_Line__c voliLine = new APTS_Agreement_Volume_Obligation_Line__c();
        voliLine.APTS_Agreement__c=testAgreement.id;
        voliLine.APTS_Agreement_Volume_Obligation__c=sched.Id;
        voliLine.APTS_Ordered_Quantity__c=10;
        voliLine.APTS_Inactive__c=false;
        insert voliLine;
        
        APTS_VolumeAssumptionObligation volAss1 = new APTS_VolumeAssumptionObligation();
        volAss1.getVolumeAssumptiosubsubcategory();
        volAss1.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig1 = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation2.Id];
        volAss1.cancelSave();
        volAss1.saveClose();
        volAss1.getSubsubObligation();

        Apttus__APTS_Agreement__c testAgreement1 = [SELECT Id,Name,APTS_Country__c,recordtype.name,Apttus__FF_Agreement_Number__c FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement12' LIMIT 1];

        PageReference pageRef1 = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('id',testAgreement1.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        ApexPages.currentPage().getParameters().put('index','');
        APTS_VolumeAssumptionObligation volAss2 = new APTS_VolumeAssumptionObligation();
        volAss2.getVolumeAssumptiosubsubcategory();
        volAss2.saveasmpObj();
        volAss2.getSubsubObligation();
        volAss2.cancelSave();
        volAss2.saveClose();
        
    }
    
    /* Test Method which is used to calculate RebatePayout for Revenue with Rate per each Tier*/
    private static testMethod void calRebateForRevenueWithRateTier()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        testAgreement.APTS_Language__c = 'SAP_DK';
        Database.update(testAgreement);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry1 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry1.Apttus_Config2__Dimension4Value__c='200';
        testPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c=6;
        testPriceRuleEntry1.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry11 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry11.Apttus_Config2__Dimension4Value__c='300';
        testPriceRuleEntry11.Apttus_Config2__AdjustmentAmount__c=9;
        testPriceRuleEntry11.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry11);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=280; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=1000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        //ApexPages.currentPage().getParameters().put('index','0');

        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        //volAss.getVolumeAssumptiocategory();
        volAss.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        volAss.cancelSave();
        volAss.saveClose();
        volAss.getcatObligation();
        
    }

    /* Test Method which is used to calculate RebatePayout for Revenue with Rate per each Tier*/
    private static testMethod void calRebateForRevenueWithRateTierHigherPercentage()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        testAgreement.APTS_Language__c = 'SAP_FR';
        Database.update(testAgreement);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry1 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry1.Apttus_Config2__Dimension4Value__c='200';
        testPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c=6;
        testPriceRuleEntry1.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry11 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry11.Apttus_Config2__Dimension4Value__c='300';
        testPriceRuleEntry11.Apttus_Config2__AdjustmentAmount__c=9;
        testPriceRuleEntry11.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry11);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=280; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=1000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=110;
        Database.insert(agmtVolumeObligation);
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        //ApexPages.currentPage().getParameters().put('index','0');

        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        //volAss.getVolumeAssumptiocategory();
        volAss.saveasmpObj();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        volAss.cancelSave();
        volAss.saveClose();
        volAss.getcatObligation();
        
    }

    
    /* Test Method which is used to calculate RebatePayout for Revenue with Rate per each Tier*/
    private static testMethod void calRebateForRevenueWithRateTier1()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        testAgreement.APTS_Language__c = 'SAP_SV';
        Database.update(testAgreement);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__Incentive__c testIncentive1 = APTS_TestUtils.createIncentive(Null);
        testIncentive1.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive1.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive1);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRuleset__c testPriceRuleSet1 = APTS_TestUtils.createPriceRuleSet(testIncentive1.Id);
        testPriceRuleSet1.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet1);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRule__c testPriceRule1 = APTS_TestUtils.createPriceRule(testPriceRuleSet1.Id);
        testPriceRule1.Apttus_Config2__TierMetricType__c='Volume';
        testPriceRule1.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule1.Apttus_Config2__Dimension4ValueType__c='Rate Per Each Tier';
        Database.insert(testPriceRule1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry1 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry1.Apttus_Config2__Dimension4Value__c='200';
        testPriceRuleEntry1.Apttus_Config2__AdjustmentAmount__c=6;
        testPriceRuleEntry1.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry11 = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry11.Apttus_Config2__Dimension4Value__c='300';
        testPriceRuleEntry11.Apttus_Config2__AdjustmentAmount__c=9;
        testPriceRuleEntry11.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry11);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry2 = APTS_TestUtils.createPriceRuleEntry(testPriceRule1.Id);
        testPriceRuleEntry2.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry2.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry2.Apttus_Config2__AdjustmentType__c='Benefit Per Unit';
        Database.insert(testPriceRuleEntry2);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry22 = APTS_TestUtils.createPriceRuleEntry(testPriceRule1.Id);
        testPriceRuleEntry22.Apttus_Config2__Dimension4Value__c='200';
        testPriceRuleEntry22.Apttus_Config2__AdjustmentAmount__c=4;
        testPriceRuleEntry22.Apttus_Config2__AdjustmentType__c='Benefit Per Unit';
        Database.insert(testPriceRuleEntry22);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_NumberofDrinks__c=1000;
        agmtVolumeObligation.APTS_GrossSale__c=250; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        //ApexPages.currentPage().getParameters().put('index','0');

        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        //volAss.getVolumeAssumptiocategory();
        volAss.saveasmpObj();
        volAss.getcatObligation();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        volAss.cancelSave();
        volAss.saveClose();
        
    }
    
    /* Test Method which is used to calculate RebatePayout for Product based*/
    private static testMethod void calRebateForProduct()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Apttus__APTS_Agreement__c testAgreement = [SELECT Id,Name,APTS_Country__c,recordtype.name FROM Apttus__APTS_Agreement__c 
                                                    WHERE Name LIKE 'Agreement' LIMIT 1];
        testAgreement.APTS_Language__c = 'SAP_FR';
        Database.update(testAgreement);
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Espresso' LIMIT 1];
                                                            
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__Incentive__c testIncentive1 = APTS_TestUtils.createIncentive(Null);
        testIncentive1.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive1.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive1);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+')';
        instanceParse.fields= field;
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRuleset__c testPriceRuleSet1 = APTS_TestUtils.createPriceRuleSet(testIncentive1.Id);
        testPriceRuleSet1.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet1);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Volume';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__ListPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        insert testPriceRule;
        
        Apttus_Config2__PriceRule__c testPriceRule1 = APTS_TestUtils.createPriceRule(testPriceRuleSet1.Id);
        testPriceRule1.Apttus_Config2__TierMetricType__c='Volume';
        testPriceRule1.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule1.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule1);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='Benefit Per Unit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry2 = APTS_TestUtils.createPriceRuleEntry(testPriceRule1.Id);
        testPriceRuleEntry2.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry2.Apttus_Config2__AdjustmentAmount__c=3;
        testPriceRuleEntry2.Apttus_Config2__AdjustmentType__c='Benefit Amount';
        Database.insert(testPriceRuleEntry2);
        
        Product2 prd=APTS_TestUtils.createProduct('Machine Tea','81001244','Machines');
        prd.APTS_Product_Family2__c='Machines|Espresso';
        prd.Family = 'SAP_01';
        Database.insert(prd);

        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_CC';
        testUOM.APTS_Product_Family2__c='Espresso';
        Database.insert(testUOM);
        
        Apttus__AgreementLineItem__c testagreeItem= new Apttus__AgreementLineItem__c ();
        testagreeItem.Apttus_CMConfig__ItemSequence__c=0;
        testagreeItem.Apttus_CMConfig__LineNumber__c=0;
        testagreeItem.Apttus__AgreementId__c=testAgreement.id;
        testagreeItem.Apttus__ProductId__c =prd.id;
        testagreeItem.Apttus_CMConfig__ClassificationId__c =categoryHierarchy.Id;
        testagreeItem.CurrencyIsoCode='';
        //APTS_TestUtils.createAgreementLineItem(prd.id,testAgreement.id,Null,Null,Null,categoryHierarchy.Id);
        insert testagreeItem;
        
        Apttus__AgreementLineItem__c testagreeItem1= new Apttus__AgreementLineItem__c ();
        testagreeItem1.Apttus_CMConfig__ItemSequence__c=0;
        testagreeItem1.Apttus_CMConfig__LineNumber__c=0;
        testagreeItem1.Apttus__AgreementId__c=testAgreement.id;
        testagreeItem1.Apttus__ProductId__c =prd.id;
        testagreeItem1.Apttus_CMConfig__ClassificationId__c =categoryHierarchy.Id;
        testagreeItem1.CurrencyIsoCode='';
        //APTS_TestUtils.createAgreementLineItem(prd.id,testAgreement.id,Null,Null,Null,categoryHierarchy.Id);
        insert testagreeItem1;

        Apttus__AgreementLineItem__c testagreeItem2= new Apttus__AgreementLineItem__c ();
        testagreeItem2.Apttus_CMConfig__ItemSequence__c=0;
        testagreeItem2.Apttus_CMConfig__LineNumber__c=0;
        testagreeItem2.Apttus__AgreementId__c=testAgreement.id;
        testagreeItem2.Apttus__ProductId__c =prd.id;
        testagreeItem2.Apttus_CMConfig__ClassificationId__c =categoryHierarchy.Id;
        testagreeItem2.CurrencyIsoCode='';
        //APTS_TestUtils.createAgreementLineItem(prd.id,testAgreement.id,Null,Null,Null,categoryHierarchy.Id);
        insert testagreeItem2;
        
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c=prd.Id;
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation3);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation4 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation4.APTS_Type__c='Product';
        agmtVolumeObligation4.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation4.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation4.APTS_Value__c=prd.Id;
        agmtVolumeObligation4.APTS_GrossSale__c=200; 
        agmtVolumeObligation4.APTS_NetSale__c=100;
        agmtVolumeObligation4.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation4.APTS_VolumeObligationPercentage__c=101;
        agmtVolumeObligation4.APTS_Action__c ='Invoice Customer';
        Database.insert(agmtVolumeObligation4);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation5 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation5.APTS_Type__c='Product';
        agmtVolumeObligation5.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation5.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation5.APTS_Value__c=prd.Id;
        agmtVolumeObligation5.APTS_GrossSale__c=200; 
        agmtVolumeObligation5.APTS_NetSale__c=100;
        agmtVolumeObligation5.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation5.APTS_VolumeObligationPercentage__c=Null;
        agmtVolumeObligation5.APTS_VolumeAssumption__c=0;
        Database.insert(agmtVolumeObligation5);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation6 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation6.APTS_Type__c='Product';
        agmtVolumeObligation6.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation6.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation6.APTS_Value__c=Null;
        agmtVolumeObligation6.APTS_GrossSale__c=200; 
        agmtVolumeObligation6.APTS_NetSale__c=100;
        agmtVolumeObligation6.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation6.APTS_VolumeObligationPercentage__c=Null;
        agmtVolumeObligation6.APTS_VolumeAssumption__c=10;
        Database.insert(agmtVolumeObligation6);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation7 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation7.APTS_Type__c='Product';
        agmtVolumeObligation7.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation7.APTS_Malus_per_Unit__c=Null;
        agmtVolumeObligation7.APTS_Value__c=prd.Id;
        agmtVolumeObligation7.APTS_GrossSale__c=200; 
        agmtVolumeObligation7.APTS_NetSale__c=100;
        agmtVolumeObligation7.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation7.APTS_VolumeObligationPercentage__c=Null;
        agmtVolumeObligation7.APTS_VolumeAssumption__c=10;
        agmtVolumeObligation7.APTS_Action__c ='Invoice Customer';
        Database.insert(agmtVolumeObligation7);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation8 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation8.APTS_Type__c='Product';
        agmtVolumeObligation8.APTS_Unit_of_Measure__c='SAP_LTR';
        agmtVolumeObligation8.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation8.APTS_Value__c=prd.Id;
        agmtVolumeObligation8.APTS_GrossSale__c=200; 
        agmtVolumeObligation8.APTS_NetSale__c=100;
        agmtVolumeObligation8.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation8.APTS_VolumeObligationPercentage__c=Null;
        agmtVolumeObligation8.APTS_VolumeAssumption__c=10;
        agmtVolumeObligation8.APTS_Action__c ='Invoice Customer';
        Database.insert(agmtVolumeObligation8);
       
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machine Tea');
                      
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('firstParam',prd.id);
        ApexPages.currentPage().getParameters().put('secondParam','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_LTR');
        ApexPages.currentPage().getParameters().put('index','0');
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        volAss.getVolumeAssumptioproduct();
        volAss.getDrinksProduct();
       
        volAss.doSelectProduct();
        volAss.saveasmpObj();
        volAss.getprdObligation();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation3.Id];
        volAss.cancelSave();
        volAss.saveClose();
        
    }

    private static testMethod void calRebateForRevenueWithHighTierConsumptionNL()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        Apttus__APTS_Agreement__c testAgreement= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement.APTS_Bill_to_Party_MachServ__c=null; 
        testAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        testAgreement.APTS_Language__c = 'SAP_NL';
        Database.insert(testAgreement);       
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                    
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+') OR (Category = '+subCategoryHierarchy.id+') OR (Category = '+subSubCategoryHierarchy.id+')';
        instanceParse.fields= field;
        //instanceParse.filter=Filter:[childFilter=null, condExpr=1 OR 2 OR 3, hasRHSFields=false, predicates=(Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXYtQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=1], Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXZrQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=2], Predicates:[BoolOper=null, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXd5QAG, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=3])];
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=300;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM1 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM1.Apttus_Config2__ConversionFactor__c=4;
        testUOM1.CurrencyIsoCode='';
        testUOM1.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM1.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM1.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM1);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM2 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM2.Apttus_Config2__ConversionFactor__c=4;
        testUOM2.CurrencyIsoCode='';
        testUOM2.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM2.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM2.APTS_Product_Family2__c='Chocolate Milk';
        Database.insert(testUOM2);
                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        //agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        Database.insert(agmtVolumeObligation1);
       
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_Categoryvalue__c =Null; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation2); 
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c='Machines';
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10; 
        Database.insert(agmtVolumeObligation3);
               
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('index','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_KGM');
        ApexPages.currentPage().getParameters().put('selValue',categoryHierarchy.Id);
        
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machines');
        //volAss.getVolumeAssumptiocategory();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.getVolumeAssumptioproduct();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        system.assertEquals(updatedVolOblig.APTS_Rebate_Payout__c,Null);
        volAss.getDependentsubcat();
        volAss.getDependentsubcatsec();
        volAss.getSubObligation();
        ApexPages.currentPage().getParameters().put('selValue',subCategoryHierarchy.Id);
        volAss.getDependentsubsubcat();
        ApexPages.currentPage().getParameters().put('percent','4');
        //volAss.getSubsubObligation();
        //volAss.addNewRowTocatList();
        volAss.addNewRowTosubCatList();
        volAss.addNewRowTosubsubList();
        volAss.addNewRowToPrdList();
        volAss.rowToRemove=0;
        volAss.getremoveRowFromsubCatList();
        volAss.getremoveRowFromsubList();
        volAss.getremoveRowFromsubsubList();
        volAss.getremoveRowFromPrdList();
        ApexPages.currentPage().getParameters().put('index','0'); 
        volAss.disableSub();
        volAss.disableSubSub();
        volAss.disablePrd();
        volAss.saveasmpObj();
        volAss.cancelSave();
        volAss.saveClose();
    }

    private static testMethod void calRebateForRevenueWithHighTierConsumptionEN()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        Apttus__APTS_Agreement__c testAgreement= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement.APTS_Bill_to_Party_MachServ__c=null; 
        testAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        testAgreement.APTS_Language__c = 'SAP_EN';
        Database.insert(testAgreement);       
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                    
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+') OR (Category = '+subCategoryHierarchy.id+') OR (Category = '+subSubCategoryHierarchy.id+')';
        instanceParse.fields= field;
        //instanceParse.filter=Filter:[childFilter=null, condExpr=1 OR 2 OR 3, hasRHSFields=false, predicates=(Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXYtQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=1], Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXZrQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=2], Predicates:[BoolOper=null, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXd5QAG, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=3])];
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=300;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM1 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM1.Apttus_Config2__ConversionFactor__c=4;
        testUOM1.CurrencyIsoCode='';
        testUOM1.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM1.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM1.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM1);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM2 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM2.Apttus_Config2__ConversionFactor__c=4;
        testUOM2.CurrencyIsoCode='';
        testUOM2.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM2.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM2.APTS_Product_Family2__c='Chocolate Milk';
        Database.insert(testUOM2);
                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        //agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        Database.insert(agmtVolumeObligation1);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation2); 
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c='Machines';
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10; 
        Database.insert(agmtVolumeObligation3);
               
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('index','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_KGM');
        ApexPages.currentPage().getParameters().put('selValue',categoryHierarchy.Id);
        
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machines');
        //volAss.getVolumeAssumptiocategory();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.getVolumeAssumptioproduct();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        system.assertEquals(updatedVolOblig.APTS_Rebate_Payout__c,Null);
        volAss.getDependentsubcat();
        volAss.getDependentsubcatsec();
        volAss.getSubObligation();
        ApexPages.currentPage().getParameters().put('selValue',subCategoryHierarchy.Id);
        volAss.getDependentsubsubcat();
        ApexPages.currentPage().getParameters().put('percent','4');
        //volAss.getSubsubObligation();
        //volAss.addNewRowTocatList();
        volAss.addNewRowTosubCatList();
        volAss.addNewRowTosubsubList();
        volAss.addNewRowToPrdList();
        volAss.rowToRemove=0;
        volAss.getremoveRowFromsubCatList();
        volAss.getremoveRowFromsubList();
        volAss.getremoveRowFromsubsubList();
        volAss.getremoveRowFromPrdList();        
        volAss.saveasmpObj();
        volAss.cancelSave();
        volAss.saveClose();
    }
    private static testMethod void calRebateForRevenueWithHighTierConsumptionES()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        Apttus__APTS_Agreement__c testAgreement= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement.APTS_Bill_to_Party_MachServ__c=null; 
        testAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        testAgreement.APTS_Language__c = 'SAP_ES';
        Database.insert(testAgreement);       
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                    
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+') OR (Category = '+subCategoryHierarchy.id+') OR (Category = '+subSubCategoryHierarchy.id+')';
        instanceParse.fields= field;
        //instanceParse.filter=Filter:[childFilter=null, condExpr=1 OR 2 OR 3, hasRHSFields=false, predicates=(Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXYtQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=1], Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXZrQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=2], Predicates:[BoolOper=null, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXd5QAG, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=3])];
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=300;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM1 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM1.Apttus_Config2__ConversionFactor__c=4;
        testUOM1.CurrencyIsoCode='';
        testUOM1.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM1.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM1.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM1);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM2 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM2.Apttus_Config2__ConversionFactor__c=4;
        testUOM2.CurrencyIsoCode='';
        testUOM2.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM2.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM2.APTS_Product_Family2__c='Chocolate Milk';
        Database.insert(testUOM2);
                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        //agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        Database.insert(agmtVolumeObligation1);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation2); 
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c='Machines';
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10; 
        Database.insert(agmtVolumeObligation3);
               
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('index','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_KGM');
        ApexPages.currentPage().getParameters().put('selValue',categoryHierarchy.Id);
        
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
       //APTS_VolumeAssumptionObligation.categoryWrapper catWrap = new APTS_VolumeAssumptionObligation.categoryWrapper(1,categoryOption,agmtVolumeObligation);
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machines');
        //volAss.getVolumeAssumptiocategory();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.getVolumeAssumptioproduct();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        system.assertEquals(updatedVolOblig.APTS_Rebate_Payout__c,Null);
        volAss.getDependentsubcat();
        volAss.getDependentsubcatsec();
        volAss.getSubObligation();
        ApexPages.currentPage().getParameters().put('selValue',subCategoryHierarchy.Id);
        volAss.getDependentsubsubcat();
        ApexPages.currentPage().getParameters().put('percent','4');
        //volAss.getSubsubObligation();
        //volAss.addNewRowTocatList();
        volAss.addNewRowTosubCatList();
        volAss.addNewRowTosubsubList();
        volAss.addNewRowToPrdList();
        volAss.rowToRemove=0;
        volAss.getremoveRowFromsubCatList();
        volAss.getremoveRowFromsubList();
        volAss.getremoveRowFromsubsubList();
        volAss.getremoveRowFromPrdList();        
        volAss.saveasmpObj();
        volAss.cancelSave();
        volAss.saveClose();
    }
    private static testMethod void calRebateForRevenueWithHighTierConsumptionDE()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Account account = APTS_TestUtils.createGrandParentAccount();
        
        Apttus__APTS_Agreement__c testAgreement= APTS_TestUtils.createAgreement(null,null,null,account.Id);
        testAgreement.APTS_Bill_to_Party_Ingredients__c=null;
        testAgreement.APTS_Bill_to_Party_MachServ__c=null; 
        testAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        testAgreement.APTS_Language__c = 'SAP_DE';
        testAgreement.APTS_Preferred_way_of_ingredient_deliver__c = 'RouteSales';
        Database.insert(testAgreement);       
        
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='& More|Accessoires' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Milk' LIMIT 1];
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy=[SELECT id,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where Name='Chocolate Milk' LIMIT 1];
                                                    
        Apttus_Config2__Incentive__c testIncentive = APTS_TestUtils.createIncentive(Null);
        testIncentive.Apttus_CMConfig__AgreementId__c=testAgreement.id;
        testIncentive.Apttus_Config2__Active__c=TRUE;
        Database.insert(testIncentive);
        
        Apttus_Config2__OrderLineItem__c instance = new Apttus_Config2__OrderLineItem__c();
        //instance.id = prId;
        instance.Apttus_Config2__ClassificationId__c= categoryHierarchy.Id;
        String myJSON = JSON.serialize(instance);
        List<String> field=new List<String>();
        field.add('Apttus_Config2__ClassificationId__c');
        
        APTS_CategoryCriteriaParse instanceParse = new APTS_CategoryCriteriaParse();
        instanceParse.exprStr='(Category = '+categoryHierarchy.id+') OR (Category = '+subCategoryHierarchy.id+') OR (Category = '+subSubCategoryHierarchy.id+')';
        instanceParse.fields= field;
        //instanceParse.filter=Filter:[childFilter=null, condExpr=1 OR 2 OR 3, hasRHSFields=false, predicates=(Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXYtQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=1], Predicates:[BoolOper=AND, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXZrQAO, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=2], Predicates:[BoolOper=null, CompOper=equal to, FieldLabel=Category, FieldName=Apttus_Config2__ClassificationId__c, FieldType=REFERENCE, FieldValue=a1n4E000001MXd5QAG, LHSChildFilterName=null, LHSSObjectName=Apttus_Config2__OrderLineItem__c, OffsetValue=null, RHSChildFilterName=, RHSFieldLabel=null, RHSFieldName= , RHSFieldType=null, RHSSObjectName=null, RefFieldName=null, RowNum=3])];
        instanceParse.sObjectLabel='Apttus_Config2__OrderLineItem__c';
        instanceParse.sObjectName='Apttus_Config2__OrderLineItem__c';
        instanceParse.searchText=Null;
        String myJSONValue=JSON.serialize(instanceParse);

        Apttus_Config2__PriceRuleset__c testPriceRuleSet = APTS_TestUtils.createPriceRuleSet(testIncentive.Id);
        testPriceRuleSet.Apttus_Config2__Criteria__c= myJSONValue;
        Database.insert(testPriceRuleSet);
        
        Apttus_Config2__PriceRule__c testPriceRule = APTS_TestUtils.createPriceRule(testPriceRuleSet.Id);
        testPriceRule.Apttus_Config2__TierMetricType__c='Revenue';
        testPriceRule.Apttus_Config2__MetricValueSource__c='Apttus_Config2__NetPrice__c';
        testPriceRule.Apttus_Config2__Dimension4ValueType__c='Highest Tier Rate';
        Database.insert(testPriceRule);
        
        Apttus_Config2__PriceRuleEntry__c testPriceRuleEntry = APTS_TestUtils.createPriceRuleEntry(testPriceRule.Id);
        testPriceRuleEntry.Apttus_Config2__Dimension4Value__c='100';
        testPriceRuleEntry.Apttus_Config2__AdjustmentAmount__c=300;
        testPriceRuleEntry.Apttus_Config2__AdjustmentType__c='% Benefit';
        Database.insert(testPriceRuleEntry);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM.Apttus_Config2__ConversionFactor__c=4;
        testUOM.CurrencyIsoCode='';
        testUOM.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM.APTS_Product_Family2__c='& More|Accessoires';
        Database.insert(testUOM);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM1 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM1.Apttus_Config2__ConversionFactor__c=4;
        testUOM1.CurrencyIsoCode='';
        testUOM1.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM1.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM1.APTS_Product_Family2__c='Milk';
        Database.insert(testUOM1);
        
        Apttus_Config2__FrequencyConversionRate__c testUOM2 = new Apttus_Config2__FrequencyConversionRate__c();
        testUOM2.Apttus_Config2__ConversionFactor__c=4;
        testUOM2.CurrencyIsoCode='';
        testUOM2.Apttus_Config2__FromUom__c='SAP_DRKS';
        testUOM2.Apttus_Config2__ToUom__c ='SAP_GRM';
        testUOM2.APTS_Product_Family2__c='Chocolate Milk';
        Database.insert(testUOM2);
                       
        PageReference pageRef = Page.APTS_VolumeAssumptionObligation;
        Test.setCurrentPage(pageRef);
                    
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation.APTS_Type__c='Category';
        agmtVolumeObligation.APTS_Value__c = categoryHierarchy.Id; 
        agmtVolumeObligation.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation.APTS_Malus_per_Unit__c=12.0;
        //agmtVolumeObligation.APTS_Volume_Obligation__c=1;
        agmtVolumeObligation.APTS_GrossSale__c=200; 
        agmtVolumeObligation.APTS_NetSale__c=100;
        agmtVolumeObligation.APTS_NumberofDrinks__c=10000;
        agmtVolumeObligation.APTS_VolumeObligationPercentage__c=10;
        Database.insert(agmtVolumeObligation);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation1 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation1.APTS_Type__c='SubCategory';
        agmtVolumeObligation1.APTS_Value__c = subCategoryHierarchy.Id;
        agmtVolumeObligation1.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation1.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation1.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation1.APTS_GrossSale__c=200; 
        agmtVolumeObligation1.APTS_NetSale__c=100; 
        agmtVolumeObligation1.APTS_VolumeObligationPercentage__c=10;
        agmtVolumeObligation1.APTS_NumberofDrinks__c=500;
        Database.insert(agmtVolumeObligation1);
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation2 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation2.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation2.APTS_Value__c = subSubCategoryHierarchy.Id;
        agmtVolumeObligation2.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation2.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation2.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation2.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation2.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation2.APTS_GrossSale__c=200; 
        agmtVolumeObligation2.APTS_NetSale__c=100;
        
        agmtVolumeObligation2.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation2); 
        
        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation3 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation3.APTS_Type__c='Product';
        agmtVolumeObligation3.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation3.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation3.APTS_Value__c='Machines';
        agmtVolumeObligation3.APTS_GrossSale__c=200; 
        agmtVolumeObligation3.APTS_NetSale__c=100;
        //agmtVolumeObligation3.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation3.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation3.APTS_VolumeObligationPercentage__c=10; 
        Database.insert(agmtVolumeObligation3);

        APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation5= APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);          
        agmtVolumeObligation5.APTS_Type__c='SubSubCategory';
        agmtVolumeObligation5.APTS_Value__c = '--None--';
        agmtVolumeObligation5.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation5.APTS_Malus_per_Unit__c=12.0;   
        //agmtVolumeObligation5.APTS_Volume_Obligation__c=10;
        agmtVolumeObligation5.APTS_NumberofDrinks__c=1500;
        agmtVolumeObligation5.APTS_Categoryvalue__c = categoryHierarchy.Id; 
        agmtVolumeObligation5.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        agmtVolumeObligation5.APTS_GrossSale__c=200; 
        agmtVolumeObligation5.APTS_NetSale__c=100;
        agmtVolumeObligation5.APTS_VolumeObligationPercentage__c=10;  
        Database.insert(agmtVolumeObligation5); 
        
        
         APTS_AgreementTotalVolumeObligation__c agmtVolumeObligation4 = APTS_TestUtils.createTotalAgreementVolumeObligation(testAgreement.id);
        agmtVolumeObligation4.APTS_Type__c='SubCategory';
        agmtVolumeObligation4.APTS_Unit_of_Measure__c='SAP_KGM';
        agmtVolumeObligation4.APTS_Malus_per_Unit__c=12.0;
        agmtVolumeObligation4.APTS_Value__c= subCategoryHierarchy.Id; 
        agmtVolumeObligation4.APTS_GrossSale__c=200; 
        agmtVolumeObligation4.APTS_NetSale__c=100;
        //agmtVolumeObligation4.APTS_Volume_Obligation__c=10; 
        agmtVolumeObligation4.APTS_NumberofDrinks__c=800;  
        agmtVolumeObligation4.APTS_VolumeObligationPercentage__c=10; 
        agmtVolumeObligation4.APTS_SubCategoryValue__c = subCategoryHierarchy.Id; 
        Database.insert(agmtVolumeObligation4);
        
        ApexPages.currentPage().getParameters().put('id',testAgreement.id);
        ApexPages.currentPage().getParameters().put('indexcat','0');
        ApexPages.currentPage().getParameters().put('index','0');
        ApexPages.currentPage().getParameters().put('selValuecat','SAP_KGM');
        ApexPages.currentPage().getParameters().put('selValue',categoryHierarchy.Id);
        
        List<SelectOption> categoryOption =new List<SelectOption>(); 
        categoryOption.add(new SelectOption(categoryHierarchy.Id,categoryHierarchy.Apttus_Config2__Label__c)); 
        
        APTS_VolumeAssumptionObligation volAss = new APTS_VolumeAssumptionObligation();
        list<product2> prodList=APTS_VolumeAssumptionObligation.populateProductByName('Machines');
        volAss.getUOMs();
        volAss.getProductUOMs();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getVolumeAssumptiosubsubcategory();
        volAss.getVolumeAssumptioproduct();
        APTS_AgreementTotalVolumeObligation__c  updatedVolOblig = [SELECT Id, APTS_Rebate_Payout__c FROM APTS_AgreementTotalVolumeObligation__c  WHERE Id =: agmtVolumeObligation.Id];
        system.assertEquals(updatedVolOblig.APTS_Rebate_Payout__c,Null);
        volAss.getDependentsubcat();
        volAss.getDependentsubcatsec();
        volAss.getSubObligation();
        ApexPages.currentPage().getParameters().put('selValue',subCategoryHierarchy.Id);
        volAss.getDependentsubsubcat();
        volAss.getVolumeAssumptiosubcategory();
        volAss.getDrinksSubcategory();
        volAss.getDrinksSubSubcategory();
        ApexPages.currentPage().getParameters().put('percent','4');
        volAss.getSubsubObligation();
        volAss.addNewRowTosubCatList();
        volAss.addNewRowTosubsubList();
        volAss.addNewRowToPrdList();
        volAss.rowToRemove=0;
        volAss.getremoveRowFromsubCatList();
        volAss.getremoveRowFromsubList();
        volAss.getremoveRowFromsubsubList();
        volAss.getremoveRowFromPrdList();        
        volAss.saveasmpObj();
        volAss.cancelSave();
        volAss.saveClose();
        // Finish testing
    }
 }