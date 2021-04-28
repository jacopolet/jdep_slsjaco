/*******************************************************************************************
Name            : APTS_VolumeObligationLineItemsTest
Created By      : Beulah Ann Thomas
Created Date    : 05/26/2018
Description     : Test class written for 'createVolumeObligationLineItems' method in
                  APTS_BIRUtils.
Version history : v1.0 - Created - 
Classes Covered : APTS_BIRUtils(91% code coverage)
*********************************************************************************************/

@isTest
public with sharing class APTS_VolumeObligationLineItemsTest
{
    @TestSetup
    private static void createTestData()
    {
        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
            
            /*Create Account*/
            Account gpAccount = APTS_TestUtils.createGrandParentAccount();
            gpAccount.Purchase_Organization__c = True;
            Database.Insert(gpAccount);
            
            Account parentAccount = APTS_TestUtils.createParentAccount(gpAccount);
            parentAccount.Purchasing_Organization__c = gpAccount.Id;
            INSERT parentAccount;
            
            Account childAccount = APTS_TestUtils.createChildAccount(parentAccount);
            childAccount.Purchasing_Organization__c = gpAccount.Id;
            INSERT childAccount;
            
             Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
            Database.Insert(priceList);
            
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
            
             /*create subsub-category*/
            Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createCategoryHierarchy(category.Id); 
            subSubCategoryHierarchy.Name = 'Machines';
            subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';
            subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
            subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;           
            subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Machines';
            subSubCategoryHierarchy.Apttus_Config2__Left__c = 2;
            subSubCategoryHierarchy.Apttus_Config2__Level__c = 2;
            subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
            subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
            Database.insert(subSubCategoryHierarchy);
            
            
            Product2 testP1 =  APTS_TestDataFactory.createProduct('Coffee', '104', 'MA', 'Standalone', FALSE, FALSE);
            Database.Insert(testP1);
            Product2 testP2 =  APTS_TestDataFactory.createProduct('Coffee1', '104', 'MA', 'Standalone', FALSE, FALSE);
            INSERT(testP2);
            Product2 testP3 =  APTS_TestDataFactory.createProduct('Coffee2', '104', 'MA', 'Standalone', FALSE, FALSE);
            INSERT(testP3);
            Apttus_Config2__ClassificationName__c categoryIngredients = APTS_TestDataFactory.createCategory();
            Database.insert(categoryIngredients);
            
            Apttus_Config2__ClassificationHierarchy__c categoryHierarchyIngre = APTS_TestDataFactory.createCategoryHierarchy(categoryIngredients.Id, 'Coffee');
            Database.Insert(categoryHierarchyIngre);
            
             Apttus_Config2__ProductClassification__c productClassification = 
                 APTS_TestDataFactory.createProductClassification(categoryHierarchy.Id, testP1.Id); 
             INSERT productClassification;
             
             
             Apttus_Config2__ProductClassification__c productSubClassification = 
                 APTS_TestDataFactory.createProductClassification(subCategoryHierarchy.Id, testP2.Id); 
             INSERT productSubClassification;
             
             Apttus_Config2__ProductClassification__c productSubSubClassification = 
                 APTS_TestDataFactory.createProductClassification(subSubCategoryHierarchy.Id, testP3.Id); 
             INSERT productSubSubClassification;
                      
            //Create Price List Items
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(priceList.Id, testP1.Id);
            priceListItemList.add(oPriceListItemStandalone);
            
            INSERT priceListItemList;
            
            
            /*create Agreement*/               
            Apttus__APTS_Agreement__c testAgreement=  new Apttus__APTS_Agreement__c(
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = gpAccount.Id,
                                                                                    APTS_Bill_to_Party_MachServ__c = gpAccount.Id, 
                                                                                    APTS_Sold_To__c = gpAccount.Id,
                                                                                    Name='Agreement1',
                                                                                    Apttus__Status__c='Activated',
                                                                                    Apttus__Status_Category__c='In Effect' 
                                                                                    );
           
            Database.insert(testAgreement);
            
            Apttus__APTS_Agreement__c testParentAgreement=  new Apttus__APTS_Agreement__c(
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = parentAccount.Id,
                                                                                    APTS_Bill_to_Party_MachServ__c = parentAccount.Id, 
                                                                                    APTS_Sold_To__c = parentAccount.Id,
                                                                                    Name='ParentAgreement1',
                                                                                    Apttus__Status__c='Activated',
                                                                                    Apttus__Status_Category__c='In Effect'
                                                                                    );
           
            Database.insert(testParentAgreement);
            
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation1 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testAgreement.Id,
                                                                                    APTS_CategoryName__c = 'categoryHierarchy',
                                                                                    APTS_Categoryvalue__c = categoryHierarchy.Id  ,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'v1' ,
                                                                                    APTS_Product_Name__c = 'test',
                                                                                    APTS_SubCategoryName__c = 'subCategoryHierarchy',
                                                                                    APTS_SubCategoryValue__c = subCategoryHierarchy.Id,
                                                                                    APTS_Type__c = 'SubCategory' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = subCategoryHierarchy.Id,
                                                                                    APTS_Value_Name__c = 'subCategoryHierarchy'
                                                                                    );
                                                                          
            INSERT totalVolumeObligation1;
                                                                                            
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation2 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testAgreement.Id,
                                                                                    APTS_CategoryName__c = 'categoryHierarchy',
                                                                                    APTS_Categoryvalue__c = categoryHierarchy.Id  ,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'v1' ,
                                                                                    APTS_Product_Name__c = 'test',
                                                                                    APTS_SubCategoryName__c = 'subCategoryHierarchy',
                                                                                    APTS_SubCategoryValue__c = subCategoryHierarchy.Id,
                                                                                    APTS_Type__c = 'SubCategory' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = subCategoryHierarchy.Id,
                                                                                    APTS_Value_Name__c = 'subCategoryHierarchy'
                                                                                    );  
                                                                                                                                                                      
            INSERT totalVolumeObligation2;
            
            
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation3 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testParentAgreement.Id,
                                                                                    APTS_CategoryName__c = 'categoryHierarchy',
                                                                                    APTS_Categoryvalue__c = categoryHierarchy.Id  ,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'v3' ,
                                                                                    APTS_Product_Name__c = 'testP3',
                                                                                    APTS_SubCategoryName__c = 'subCategoryHierarchy',
                                                                                    APTS_SubCategoryValue__c = subCategoryHierarchy.Id,
                                                                                    APTS_Type__c = 'SubSubCategory' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = subSubCategoryHierarchy.Id,
                                                                                    APTS_Value_Name__c = 'subSubCategoryHierarchy'
                                                                                    );  
                                                                                                                                                                      
            INSERT totalVolumeObligation3;
            
            
            
             APTS_AgreementTotalVolumeObligation__c totalVolumeObligation4 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testAgreement.Id,
                                                                                    APTS_CategoryName__c = 'categoryHierarchy',
                                                                                    APTS_Categoryvalue__c = categoryHierarchy.Id  ,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'v4' ,
                                                                                    APTS_Product_Name__c = 'testP3',
                                                                                    APTS_SubCategoryName__c = 'subCategoryHierarchy',
                                                                                    APTS_SubCategoryValue__c = subCategoryHierarchy.Id,
                                                                                    APTS_Type__c = 'SubSubCategory' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = subSubCategoryHierarchy.Id,
                                                                                    APTS_Value_Name__c = 'subSubCategoryHierarchy'
                                                                                    );  
                                                                                                                                                                      
            INSERT totalVolumeObligation4;
            
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation5 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testParentAgreement.Id,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'Product' ,
                                                                                    APTS_Product_Name__c = 'testP2',
                                                                                    APTS_Type__c = 'Product' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = testP2.Id,
                                                                                    APTS_Value_Name__c = 'Product'
                                                                                    );  
                                                                                                                                                                      
            INSERT totalVolumeObligation5;
            
            APTS_AgreementTotalVolumeObligation__c totalVolumeObligation6 = new APTS_AgreementTotalVolumeObligation__c (
                                                                                    APTS_Agreement__c = testAgreement.Id,
                                                                                    APTS_Malus_per_Unit__c = 10,
                                                                                    APTS_Name__c = 'Product' ,
                                                                                    APTS_Product_Name__c = 'testP3',
                                                                                    APTS_Type__c = 'Product' ,
                                                                                    APTS_Unit_of_Measure__c = 'SAP_KGM',
                                                                                    APTS_Value__c = testP3.Id,
                                                                                    APTS_Value_Name__c = 'Product'
                                                                                    );  
                                                                                                                                                                      
            INSERT totalVolumeObligation6;
            
            APTS_AgreementVolumeObligation__c volumeObligation1 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation1.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                    APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation1;   
            
            APTS_AgreementVolumeObligation__c volumeObligation2 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation2.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation2;                
            
            APTS_AgreementVolumeObligation__c volumeObligation3 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testParentAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation3.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation3;  
            
            APTS_AgreementVolumeObligation__c volumeObligation4 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation4.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation4;                
            
            APTS_AgreementVolumeObligation__c volumeObligation5 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testParentAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation5.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation5; 
            
            APTS_AgreementVolumeObligation__c volumeObligation6 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation6.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation6;  

            APTS_AgreementVolumeObligation__c volumeObligation7 = new APTS_AgreementVolumeObligation__c(
                                                                   APTS_Agreement__c = testAgreement.Id, 
                                                                   APTS_Agreement_Total_Volume_Obligation__c = totalVolumeObligation1.Id,
                                                                   APTS_Start_Date__c = System.Today(), 
                                                                   APTS_End_Date__c = System.Today()+ 365,
                                                                                   APTS_Status__c = 'Open'
                                                                                    );  
            INSERT volumeObligation7; 
            
            
                                    
            Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(gpAccount.Id,priceList.id, NULL);
            order.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
            order.Apttus_Config2__SoldToAccountId__c = gpAccount.Id;
            order.APTS_Name__c = 'TestOrder';
            Database.Insert(order);
            
            Apttus_Config2__BillingPreference__c testBillingPrefrence = APTS_TestUtils.createBillingPrefrence('January');
            Insert testBillingPrefrence;
            
            Apttus_Config2__OrderLineItem__c oli1 = APTS_TestUtils.createOrderLineItem(
            testP1.Id, order.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            oli1.Apttus_Config2__FulfilledQuantity__c = 1;
            oli1.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
            oli1.Apttus_Config2__BillToAccountId__c = gpAccount.Id;
            oli1.APTS_Bill_to_Party_Ingredients_and_Payer__c = gpAccount.Id;
            oli1.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
            oli1.Apttus_Config2__ProductId__c = testP1.Id;
            INSERT oli1;
            
            Apttus_Config2__OrderLineItem__c oli2 = APTS_TestUtils.createOrderLineItem(
            testP2.Id, order.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            oli2.Apttus_Config2__FulfilledQuantity__c = 1;
            oli2.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
            oli2.Apttus_Config2__BillToAccountId__c = gpAccount.Id;
            oli2.APTS_Bill_to_Party_Ingredients_and_Payer__c = gpAccount.Id;
            oli2.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
            oli2.Apttus_Config2__ProductId__c = testP2.Id;
            INSERT oli2;

            Apttus_Config2__OrderLineItem__c oli3 = APTS_TestUtils.createOrderLineItem(
            testP2.Id, order.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            oli3.Apttus_Config2__FulfilledQuantity__c = 1;
            oli3.Apttus_CMConfig__AgreementId__c = testAgreement.Id;
            oli3.Apttus_Config2__BillToAccountId__c = gpAccount.Id;
            oli3.APTS_Bill_to_Party_Ingredients_and_Payer__c = gpAccount.Id;
            oli3.Apttus_Config2__ClassificationId__c = subCategoryHierarchy.Id;
            oli3.Apttus_Config2__ProductId__c = testP2.Id;
            oli3.APTS_Returned_Quantity__c = 1;
            INSERT oli3;
            
            APTS_Agreement_Volume_Obligation_Line__c volumeObligationLine = new APTS_Agreement_Volume_Obligation_Line__c(
                                    APTS_Order_Line_Item__c = oli2.Id,
                                    APTS_Inactive__c = False,
                                    APTS_Agreement_Volume_Obligation__c = volumeObligation2.Id,
                                    APTS_Fulfillment_Date__c = System.Today(),
                                    APTS_Ordered_Quantity__c = 1,
                                    APTS_Order_In_Progress_Quantity__c = 1
                                    );
            INSERT volumeObligationLine;

            APTS_Agreement_Volume_Obligation_Line__c volumeObligationLine1 = new APTS_Agreement_Volume_Obligation_Line__c(
                                    APTS_Order_Line_Item__c = oli3.Id,
                                    APTS_Inactive__c = False,
                                    APTS_Agreement_Volume_Obligation__c = volumeObligation2.Id,
                                    APTS_Fulfillment_Date__c = System.Today(),
                                    APTS_Ordered_Quantity__c = 1,
                                    APTS_Order_In_Progress_Quantity__c = 1
                                    );
            INSERT volumeObligationLine1;

            
            Apttus__APTS_Agreement__c testChildAgreement=  new Apttus__APTS_Agreement__c(
                                                                                    Apttus__Contract_Start_Date__c = Date.today(),
                                                                                    Apttus__Contract_End_Date__c = Date.today()+365, 
                                                                                    Apttus_CMConfig__PriceListId__c = priceList.id,
                                                                                    Apttus__Subtype__c ='Default',
                                                                                    APTS_Bill_to_Party_Ingredients__c = childAccount.Id,
                                                                                    APTS_Bill_to_Party_MachServ__c = childAccount.Id, 
                                                                                    APTS_Sold_To__c = childAccount.Id,
                                                                                    Name='AgreementChild'
                                                                                    );
           
            Database.insert(testChildAgreement);
            
            Apttus_Config2__Order__c childOrder = APTS_TestDataFactory.createOrder(childAccount.Id,priceList.id, NULL);
            childOrder.Apttus_CMConfig__AgreementId__c = testChildAgreement.Id;
            childOrder.Apttus_Config2__SoldToAccountId__c = childAccount.Id;
            childOrder.APTS_Name__c = 'TestChildOrder';
            Database.Insert(childOrder);
            
            
            Apttus_Config2__OrderLineItem__c childOLI1 = APTS_TestUtils.createOrderLineItem(
                                                        testP1.Id, childOrder.Id, null,  testBillingPrefrence.Id , 
                                                        priceList.Id, priceListItemList[0].Id); 
            
            childOLI1.Apttus_CMConfig__AgreementId__c = testChildAgreement.Id;
            childOLI1.Apttus_Config2__BillToAccountId__c = childAccount.Id;
            childOLI1.APTS_Bill_to_Party_Ingredients_and_Payer__c = childAccount.Id;
            childOLI1.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
            childOLI1.Apttus_Config2__ProductId__c = testP1.Id;
            INSERT childOLI1;
            
            Apttus_Config2__OrderLineItem__c childOLI2 = APTS_TestUtils.createOrderLineItem(
                                                        testP3.Id, childOrder.Id, null,  testBillingPrefrence.Id , 
                                                        priceList.Id, priceListItemList[0].Id); 
            
            childOLI2.Apttus_CMConfig__AgreementId__c = testChildAgreement.Id;
            childOLI2.Apttus_Config2__BillToAccountId__c = childAccount.Id;
            childOLI2.APTS_Bill_to_Party_Ingredients_and_Payer__c = childAccount.Id;
            //childOLI1.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
            childOLI2.Apttus_Config2__ProductId__c = testP3.Id;
            INSERT childOLI2;
    
            
            Apttus_Config2__OrderLineItem__c childOLI3 = APTS_TestUtils.createOrderLineItem(
                                                        testP3.Id, childOrder.Id, null,  testBillingPrefrence.Id , 
                                                        priceList.Id, priceListItemList[0].Id); 
            
            childOLI2.Apttus_CMConfig__AgreementId__c = testChildAgreement.Id;
            childOLI2.Apttus_Config2__BillToAccountId__c = childAccount.Id;
            childOLI2.APTS_Bill_to_Party_Ingredients_and_Payer__c = childAccount.Id;
            childOLI1.Apttus_Config2__ClassificationId__c = subSubCategoryHierarchy.Id;
            childOLI2.Apttus_Config2__ProductId__c = testP3.Id;
            INSERT childOLI3;
                                                                                   
                    
            Apttus_Config2__Order__c parentOrder = APTS_TestDataFactory.createOrder(parentAccount.Id,priceList.id, NULL);
            parentOrder.Apttus_CMConfig__AgreementId__c = testParentAgreement.Id;
            parentOrder.Apttus_Config2__SoldToAccountId__c = parentAccount.Id;
            order.APTS_Name__c = 'TestOrder';
            Database.Insert(parentOrder);
            
            Apttus_Config2__OrderLineItem__c oliParent = APTS_TestUtils.createOrderLineItem(
            testP3.Id, parentOrder.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            oliParent.Apttus_Config2__FulfilledQuantity__c = 1;
            oliParent.Apttus_CMConfig__AgreementId__c = testParentAgreement.Id;
            oliParent.Apttus_Config2__BillToAccountId__c = parentAccount.Id;
            oliParent.APTS_Bill_to_Party_Ingredients_and_Payer__c = parentAccount.Id;
            //oliParent.Apttus_Config2__ClassificationId__c = subSubCategoryHierarchy.Id;
            oliParent.Apttus_Config2__ProductId__c = testP3.Id;
            INSERT oliParent;
            
            Apttus_Config2__OrderLineItem__c oliParent2 = APTS_TestUtils.createOrderLineItem(
            testP2.Id, parentOrder.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            oliParent.Apttus_Config2__FulfilledQuantity__c = 1;
            oliParent.Apttus_CMConfig__AgreementId__c = testParentAgreement.Id;
            oliParent.Apttus_Config2__BillToAccountId__c = parentAccount.Id;
            oliParent.APTS_Bill_to_Party_Ingredients_and_Payer__c = parentAccount.Id;
            //oliParent.Apttus_Config2__ClassificationId__c = subSubCategoryHierarchy.Id;
            oliParent.Apttus_Config2__ProductId__c = testP2.Id;
            INSERT oliParent2;
            
            //Create return order
            Apttus_Config2__Order__c returnOrder = APTS_TestDataFactory.createOrder(parentAccount.Id,priceList.id, NULL);
            returnOrder.Apttus_CMConfig__AgreementId__c = testParentAgreement.Id;
            returnOrder.Apttus_Config2__SoldToAccountId__c = parentAccount.Id;
            returnOrder.APTS_Order_Type__c = 'Standard Order';
            returnOrder.APTS_Order_Sub_Type__c = 'Standard Return';
            returnOrder.APTS_SAP_OrderType__c='XB01';
            returnOrder.APTS_Name__c = 'ReturnOrder';
            returnOrder.APTS_Order_Reason__c='Z99';
            Database.Insert(returnOrder);
            
            Apttus_Config2__OrderLineItem__c returnOLI = APTS_TestUtils.createOrderLineItem(
            testP3.Id, returnOrder.Id,null,  testBillingPrefrence.Id , priceList.Id, priceListItemList[0].Id);
            returnOLI.Apttus_CMConfig__AgreementId__c = testParentAgreement.Id;
            returnOLI.Apttus_Config2__BillToAccountId__c = parentAccount.Id;
            returnOLI.APTS_Bill_to_Party_Ingredients_and_Payer__c = parentAccount.Id;
            //returnOLI.Apttus_Config2__ClassificationId__c = subSubCategoryHierarchy.Id;
            returnOLI.Apttus_Config2__ProductId__c = testP3.Id;
            INSERT returnOLI;
            
            Apttus_Config2__ExternalOrderSummary__c externalOrder = new Apttus_Config2__ExternalOrderSummary__c();
            externalOrder.Apttus_Config2__AccountId__c = childAccount.Id;
            externalOrder.Apttus_CMConfig__AgreementId__c = testChildAgreement.Id;
            externalOrder.Apttus_Config2__BillToAccountId__c = childAccount.Id;
            externalOrder.Apttus_Config2__Description__c = 'Test';
            externalOrder.APTS_ExternalId__c = 'AbcTest123';
           // externalOrder.Apttus_Config2__ForecastData__c = System.Today()+90;
           // externalOrder.Apttus_Config2__LocationId__c = ;
            externalOrder.Apttus_Config2__PeriodEndDate__c =  System.Today();
            externalOrder.Apttus_Config2__PeriodStartDate2__c = System.Today() + 38;
            externalOrder.Apttus_Config2__Status__c = 'In Review';
            externalOrder.Apttus_Config2__Type__c = 'Sales Data';
            INSERT externalOrder;
            
            
            TriggerSettings__c testSetting = new TriggerSettings__c();
            testSetting.APTS_OrderLineItemTrigger__c = True;
            testSetting.APTS_ExternalOrderSummaryItem__c = True;
            INSERT testSetting;
        }
    }
    
    static testMethod void createVolumeObligationLineItemsTest()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];

     /*   Apttus_Config2__OrderSystemProperties__c orderSystemProperties = new Apttus_Config2__OrderSystemProperties__c();
       orderSystemProperties.Name = 'System Properties';
       orderSystemProperties.APTS_User_Id_With_Debug_Log__c = testUser.Id;
       insert orderSystemProperties;*/
       set<Id> orderIds = new set<Id>();
       Apttus_Config2__OrderLineItem__c oldOLI = [SELECT Id,Name FROM Apttus_Config2__OrderLineItem__c LIMIT 1];
        
        Map<Id, Apttus_Config2__OrderLineItem__c> mapoldOLI = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        mapoldOLI.put(oldOLI.Id, oldOLI);
        
        List<Apttus_Config2__OrderLineItem__c> oOLI = [SELECT Id,Name FROM Apttus_Config2__OrderLineItem__c LIMIT 15];
        
        for(Apttus_Config2__OrderLineItem__c oli : oOLI)
        {
            orderIds.add(oli.Id);
            oli.Apttus_Config2__StartDate__c = system.Today();
            oli.Apttus_Config2__EndDate__c = system.Today() + 200;
            oli.Apttus_Config2__FulfilledQuantity__c =2;
            oli.Apttus_Config2__Status__c = 'Pending';
        }
        
        test.startTest();
        System.runAs(testUser) 
        {
            UPDATE oOLI;
            Map<Id, Apttus_Config2__OrderLineItem__c> mapNewOLI = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            //mapNewOLI.put(oOLI.Id, oOLI);
            //createVolumeObligationLineItems(List<SObject> newList, Map<Id, SObject> mapOrderLineItems, 
              //                                  List<SObject> oldList, Map<Id, SObject> mapOldOrderLineItems)
        }
        List<APTS_Agreement_Volume_Obligation_Line__c> volObligationLineList = [Select Id
                                                                        FROM APTS_Agreement_Volume_Obligation_Line__c 
                                                                        WHERE APTS_Order_Line_Item__c IN :orderIds
                                                                        LIMIT 50000];
        system.debug('==> Vol Obligation List Size()==>'+volObligationLineList);                                                                        
        system.assert(volObligationLineList.size() > 0);
        test.stopTest();
        
       
    }
    
    static testMethod void createParentVolumeLineItem()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];

     /*   Apttus_Config2__OrderSystemProperties__c orderSystemProperties = new Apttus_Config2__OrderSystemProperties__c();
       orderSystemProperties.Name = 'System Properties';
       orderSystemProperties.APTS_User_Id_With_Debug_Log__c = testUser.Id;
       insert orderSystemProperties;*/
         
       Apttus_Config2__OrderLineItem__c oli = [SELECT Id,Name FROM Apttus_Config2__OrderLineItem__c WHERE 
                                                   Apttus_Config2__ProductId__r.Name = 'Coffee2'
                                                   LIMIT 1];
                
        oli.Apttus_Config2__StartDate__c = system.Today();
        oli.Apttus_Config2__EndDate__c = system.Today() + 200;
        oli.Apttus_Config2__FulfilledQuantity__c =2;
        oli.Apttus_Config2__Status__c = 'Activated';
        
        
        test.startTest();
        System.runAs(testUser) 
        {
            UPDATE oli;
            Map<Id, Apttus_Config2__OrderLineItem__c> mapNewOLI = new Map<Id, Apttus_Config2__OrderLineItem__c>();
            
        }
        test.stopTest();
    }
    
    static testMethod void createReturnOLIs()
    {
        User testUser = [SELECT Id FROM User LIMIT 1];

    /*    Apttus_Config2__OrderSystemProperties__c orderSystemProperties = new Apttus_Config2__OrderSystemProperties__c();
       orderSystemProperties.Name = 'System Properties';
       orderSystemProperties.APTS_User_Id_With_Debug_Log__c = testUser.Id;
       insert orderSystemProperties;*/
         
       Apttus_Config2__OrderLineItem__c oli = [SELECT Id,Name 
                                               FROM Apttus_Config2__OrderLineItem__c 
                                               WHERE Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c = 
                                               'Standard Return' 
                                               LIMIT 1];  
                                               
        oli.Apttus_Config2__StartDate__c = system.Today();
        oli.Apttus_Config2__EndDate__c = system.Today() + 200;
        oli.APTS_Returned_Quantity__c  = 2;
        oli.Apttus_Config2__Status__c = 'Activated';
               
        test.startTest();
        System.runAs(testUser) 
        {
            UPDATE oli;
            
        }
        test.stopTest();
    }
    
    static testMethod void createExternalOrderLineItem()
    {
        Map<Id, Apttus_Config2__ExternalOrderSummaryItem__c> mapExternalOLI =
        new Map<Id, Apttus_Config2__ExternalOrderSummaryItem__c>();
        Apttus_Config2__ExternalOrderSummary__c externalOrder = [SELECT Id, Apttus_Config2__AccountId__c, 
                                                                Apttus_CMConfig__AgreementId__c 
                                                                FROM Apttus_Config2__ExternalOrderSummary__c 
                                                                LIMIT 1];

        Product2 testP3 =  [SELECT Id, Name From Product2 WHERE Name='Coffee2' LIMIT 1];
      
        Apttus_Config2__ExternalOrderSummaryItem__c externalOLI = new Apttus_Config2__ExternalOrderSummaryItem__c();
        externalOLI.Apttus_Config2__BillToAccountId__c = externalOrder.Apttus_Config2__AccountId__c ;
        externalOLI.Apttus_Config2__ShipToAccountId__c = externalOrder.Apttus_Config2__AccountId__c ;
        externalOLI.Apttus_Config2__SoldToAccountId__c= externalOrder.Apttus_Config2__AccountId__c ;
        
        externalOLI.Apttus_Config2__Quantity__c = 2;
        //externalOLI.Apttus_CMConfig__AgreementId__c = externalOrder.Apttus_CMConfig__AgreementId__c;
        externalOLI.Apttus_Config2__OrderSummaryId__c = externalOrder.Id;
        externalOLI.Apttus_Config2__ProductId__c = testP3.Id;
        externalOLI.Apttus_Config2__PeriodStartDate__c = System.Today();
        externalOLI.Apttus_Config2__PeriodEndDate__c  = System.Today() + 34;
        
        test.startTest();
        INSERT externalOLI;
        
        mapExternalOLI.put(externalOLI.Id, externalOLI);
        
        APTS_ExternalOrderSummaryItemHandler externalOLIHandler = new APTS_ExternalOrderSummaryItemHandler();
        externalOLIHandler.afterUpdate(mapExternalOLI.values(), mapExternalOLI, 
        mapExternalOLI.values(), mapExternalOLI);
        externalOLIHandler.beforeUpdate(mapExternalOLI.values(), mapExternalOLI, 
        mapExternalOLI.values(), mapExternalOLI);
        externalOLIHandler.beforeDelete(mapExternalOLI.values(), mapExternalOLI); 
        externalOLIHandler.afterDelete(mapExternalOLI.values(), mapExternalOLI);
        externalOLIHandler.afterUndelete(mapExternalOLI.values(), mapExternalOLI);
        APTS_BIRUtils.createVolumeOLIForExternalOLI(mapExternalOLI.values(),mapExternalOLI);
        test.stopTest();
        
    }  
}