/**
* Class Name : APTS_ProductRedistributionBatch_Test
* Description :  Apex Class to test APTS_ProductRedistributionBatch Class
* Author : V. Shankaranarayanan
* Date Created : 03/02/2018
**/
@isTest
private with sharing class APTS_ProductRedistributionBatch_Test{
    
    private static Map<Id,List<APTS_Batch_Error__c>> batchErrorsMap=new Map<Id,List<APTS_Batch_Error__c>>();
    private static Set<String> offeringCodesSet = new set<String>();
    private static Set<String> tempOptSet=new Set<String>();
    private static Set<String> optionCodesSet = new set<String>();
    private static Map<String, Product2> activeProductMapNew = new Map<String, Product2>();
    private static Apttus_Config2__ProductGroup__c prodGrp = new Apttus_Config2__ProductGroup__c ();
    @testSetup
    //Test Data Setup Method to create all test Data to test "APTS_ProductRedistributionBatch" Class
    static void setupTestData(){ 
        List<Product2> prodInsertList = new List<Product2>();
        
        prodInsertList = TestDataFactory.createProduct(4);
        //APTS_CPQConstants.PRD_TYPE
        prodInsertList[0].Name = APTS_CPQConstants.PRD_NAME;
        prodInsertList[0].ProductCode = APTS_CPQConstants.PRD_CODE; 
        prodInsertList[0].APTS_Sales_Catalog__c = APTS_CPQConstants.PRD_SALE_CAT;
        prodInsertList[0].APTS_Conversion_Option_Indicator__c = APTS_CPQConstants.PRD_OPTION_INDICATOR;
        //Commented by Hari for fixing the defect 16724 releted to deleting redundant fields
        //prodInsertList[0].APTS_To_Be_Processed_From_SAP__c = true;
        prodInsertList[0].Apttus_Config2__ConfigurationType__c = APTS_CPQConstants.PRD_TYPE;
        prodInsertList[0].APTS_Material_Type__c = APTS_CPQConstants.PRD_MATERIAL_TYPE;
        prodInsertList[0].APTS_Cross_plant_material_status__c = APTS_CPQConstants.PRD_BL;
        //Commented by Hari for deleting the unwanted fields in Product2 object which is part of defect 16724
        //prodInsertList[0].APTS_Associated_Sales_Organization__c= '0111;6712';
        prodInsertList[0].APTS_Associated_Sales_Org__c = APTS_CPQConstants.PRD_SALS_ORG;
        prodInsertList[0].APTS_Upserted_from_SAP__c=TRUE;
        prodInsertList[0].APTS_Sales_Catalog__c= APTS_CPQConstants.PRD_SALES_CAT;
        prodInsertList[0].APTS_Option_Group_Indicator__c = APTS_CPQConstants.PRD_OPTION_INDI;
        
        
        prodInsertList[1].Name = APTS_CPQConstants.PRD_NME;
        prodInsertList[1].APTS_Option_Group_Indicator__c = APTS_CPQConstants.PRD_GRP_INDI;
        //Commented by Hari for fixing the defect 16724 releted to deleting redundant fields
        //prodInsertList[1].APTS_To_Be_Processed_From_SAP__c = true;
        prodInsertList[1].Apttus_Config2__ConfigurationType__c = APTS_CPQConstants.PRD_TYPE;
        prodInsertList[1].APTS_Material_Type__c = APTS_CPQConstants.PRD_MATERIAL_TYPE1;
        prodInsertList[1].APTS_Cross_plant_material_status__c = APTS_CPQConstants.PRD_BL;
        prodInsertList[1].APTS_Conversion_Option_Indicator__c = APTS_CPQConstants.PRD_OPTION_INDICATOR;
        //Commented by Hari for deleting the unwanted fields in Product2 object which is part of defect 16724
        //prodInsertList[1].APTS_Associated_Sales_Organization__c= '0111';
        prodInsertList[1].APTS_Upserted_from_SAP__c=TRUE;
        prodInsertList[0].APTS_Sales_Catalog__c= APTS_CPQConstants.PRD_OPTION_INDI;
        prodInsertList[0].APTS_Option_Group_Indicator__c = APTS_CPQConstants.PRD_SALES_CAT;
        
        prodInsertList[2].Name = APTS_CPQConstants.PRD_NAME1;
        prodInsertList[2].IsActive = false;
        prodInsertList[2].APTS_Sales_Catalog__c = APTS_CPQConstants.PRD_OPTION_INDI;
        //Commented by Hari for fixing the defect 16724 releted to deleting redundant fields
        //prodInsertList[2].APTS_To_Be_Processed_From_SAP__c = true;
        prodInsertList[2].Apttus_Config2__ConfigurationType__c = APTS_CPQConstants.PRD_TYPE;
        prodInsertList[2].APTS_Material_Type__c = APTS_CPQConstants.PRD_MATERIAL_TYPE1;
        prodInsertList[2].APTS_Cross_plant_material_status__c = APTS_CPQConstants.PRD_BL;
        prodInsertList[2].APTS_Conversion_Option_Indicator__c = APTS_CPQConstants.PRD_OPTION_INDICATOR;
        //Commented by Hari for deleting the unwanted fields in Product2 object which is part of defect 16724
        //prodInsertList[2].APTS_Associated_Sales_Organization__c= '0111';
        prodInsertList[0].APTS_Associated_Sales_Org__c = APTS_CPQConstants.PRD_SALS_ORG;
        prodInsertList[2].APTS_Upserted_from_SAP__c=TRUE;
        
        prodInsertList[3].Name = APTS_CPQConstants.PRD_NAME2;
        prodInsertList[3].IsActive = false;
        prodInsertList[3].APTS_Sales_Catalog__c = APTS_CPQConstants.PRD_OPTION_INDI;
        //Commented by Hari for fixing the defect 16724 releted to deleting redundant fields
        //prodInsertList[3].APTS_To_Be_Processed_From_SAP__c = true;
        prodInsertList[3].Apttus_Config2__ConfigurationType__c = APTS_CPQConstants.PRD_TYPE;
        prodInsertList[3].APTS_Material_Type__c = APTS_CPQConstants.PRD_MATERIAL_TYPE1;
        prodInsertList[3].APTS_Cross_plant_material_status__c = APTS_CPQConstants.PRD_HI;
        //Commented by Hari for deleting the unwanted fields in Product2 object which is part of defect 16724
        //prodInsertList[3].APTS_Associated_Sales_Organization__c= '0111';
        prodInsertList[0].APTS_Associated_Sales_Org__c = APTS_CPQConstants.PRD_SALS_ORG;
        prodInsertList[3].APTS_Upserted_from_SAP__c=TRUE;
        prodInsertList[3].APTS_Conversion_Option_Indicator__c = APTS_CPQConstants.PRD_OPTION_INDICATOR;
        
        Database.insert(prodInsertList);
        
        List<Apttus_Config2__ClassificationName__c> categoryList = TestDataFactory.createCategory(2);
        Database.insert(categoryList);
        
        List<Apttus_Config2__ClassificationHierarchy__c> hierarchyList = TestDataFactory.createHierarchy(2, categoryList);
        Database.insert(hierarchyList);
        
        Apttus_Config2__ProductClassification__c prodClassification = new Apttus_Config2__ProductClassification__c();
        prodClassification.Apttus_Config2__ProductId__c = prodInsertList[0].Id;
        prodClassification.Apttus_Config2__ClassificationId__c = hierarchyList[0].Id;
        Database.insert(prodClassification);
          
        hierarchyList[0].APTS_CategoryHierarchyOfferingExtId__c = APTS_CPQConstants.CAT_HYR; 
        hierarchyList[0].APTS_CategoryHierarchyOptionExtId__c = APTS_CPQConstants.PRD_GRP_INDI;
        hierarchyList[1].APTS_CategoryHierarchyOptionExtId__c = APTS_CPQConstants.CAT_HYR_OPTION1;
        System.assertNotEquals('040193',hierarchyList[0].APTS_CategoryHierarchyOfferingExtId__c);   // Added by Rajesh Patel
        System.assertEquals(APTS_CPQConstants.CAT_HYR_OPTION1 ,hierarchyList[1].APTS_CategoryHierarchyOptionExtId__c); // Added by Rajesh Patel
        Database.update(hierarchyList);
                      
                
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.PG_OFFERING, APTS_CPQConstants.PG_COFFEE);
        Database.insert(pDstGrpStgs);
        
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs0 = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.PG_OFFER_O4, APTS_CPQConstants.PG_MACH);
        Database.insert(pDstGrpStgs0);
        
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs1 = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.AG_OFFERING, APTS_CPQConstants.AG_MATCH);
        Database.insert(pDstGrpStgs1);
        
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs2 = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.PG_NAME_TIME, APTS_CPQConstants.PG_RES);
        Database.insert(pDstGrpStgs2);
        
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs3 = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.AG_OPTION, APTS_CPQConstants.AG_ONETIME);
        Database.insert(pDstGrpStgs3);
        
        APTS_ProdDistributionGroupSettings__c pDstGrpStgs4 = TestDataFactory.createProdDistbGrpStgs(APTS_CPQConstants.AG_NAME, APTS_CPQConstants.AG_ALLINCOVERAGE);
        Database.insert(pDstGrpStgs4);
        
        Apttus_Config2__FieldExpression__c fe = new Apttus_Config2__FieldExpression__c();
        fe.Name = APTS_CPQConstants.EXPRES_TEST;
        Database.insert(fe);
        
        Apttus_Config2__FrequencyConversionRate__c fCR = new Apttus_Config2__FrequencyConversionRate__c();
        fCR.Apttus_Config2__ProductId__c= prodInsertList[0].Id; 
        fCR.APTS_ProductCode__c = prodInsertList[0].ProductCode;
        fCR.Apttus_Config2__FromFrequency__c= APTS_CPQConstants.LABEL_MONTHLY;
        fCR.Apttus_Config2__ToFrequency__c= APTS_CPQConstants.LABEL_MONTHLY;
        insert fCR;
        
        Apttus_Config2__ProductTranslation__c prodTrans=new Apttus_Config2__ProductTranslation__c();
        prodTrans.Name= APTS_CPQConstants.TEST_TRANS;
        prodTrans.Apttus_Config2__ProductCode__c=prodInsertList[0].ProductCode;
        insert prodTrans;
        
        APTS_Sales_Org_Data__c sOD = TestDataFactory.createSlsOrgData(APTS_CPQConstants.TEST_SALES_ORG, APTS_CPQConstants.CODE_0333, prodInsertList[0].Id, APTS_CPQConstants.SAP_01);
        Database.insert(sOD);
        
        APTS_Sales_Org_Data__c sOD1 = TestDataFactory.createSlsOrgData(APTS_CPQConstants.TEST_SALES_ORG,APTS_CPQConstants.USR_SALES_ORG, prodInsertList[1].Id, APTS_CPQConstants.SAP_01);
        Database.insert(sOD1);
        
        APTS_MARA_MVKE_Status_Mapping__c mMSM = new APTS_MARA_MVKE_Status_Mapping__c();
        mMSM.Name = APTS_CPQConstants.BL_SAP_01;
        mMSM.APTS_MARA_MVKE_Field_Combination__c = APTS_CPQConstants.BL_SAP_01;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_Has_PLI_active_PLI__c = true;
        mMSM.APTS_Visible_in_Catalogue__c = false;
        Database.insert(mMSM); 
        
        Apttus_Config2__ProductAttributeGroup__c attributeGroup = new Apttus_Config2__ProductAttributeGroup__c();
        attributeGroup.Name = APTS_CPQConstants.TEST_ATT_GRP;
        attributeGroup.Apttus_Config2__BusinessObject__c = APTS_CPQConstants.APTS_PAV;
        attributeGroup.APTS_AttributeGroupExtId__c = APTS_CPQConstants.AG_MACH;
        Database.insert(attributeGroup); 
        
        Apttus_Config2__ProductAttribute__c prodAttr = new Apttus_Config2__ProductAttribute__c();
        prodAttr.Apttus_Config2__AttributeGroupId__c = attributeGroup.Id;
        prodAttr.Apttus_Config2__Field__c = APTS_CPQConstants.TEST_NM;
        prodAttr.Apttus_Config2__Sequence__c = 0;
        Database.insert(prodAttr); 
        
        Apttus_Config2__ProductAttributeGroupMember__c prodGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c ();
         prodGroupMem.Apttus_Config2__AttributeGroupId__c= attributeGroup.Id;
         prodGroupMem.Name=attributeGroup.Name;
         prodGroupMem.Apttus_Config2__ProductId__c=prodInsertList[2].Id;
         prodGroupMem.Apttus_Config2__Sequence__c=0;
         Database.insert(prodGroupMem); 
        
        prodGrp = TestDataFactory.createprodGrp(APTS_CPQConstants.TEST_PRD_GRP, APTS_CPQConstants.PG_RES);
        Database.insert(prodGrp);
        
        Apttus_Config2__ProductGroup__c prodGrp0 = TestDataFactory.createprodGrp(APTS_CPQConstants.TEST_PRD_GRP, APTS_CPQConstants.AG_MACH);
        Database.insert(prodGrp0);
        
        Apttus_Config2__ProductGroup__c prodGrp1 = TestDataFactory.createprodGrp(APTS_CPQConstants.TEST_PRD_GRP, APTS_CPQConstants.AG_ONETIME);
        Database.insert(prodGrp1);
      
        Apttus_Config2__ProductGroupMember__c prodGrpMbr = new Apttus_Config2__ProductGroupMember__c();
        prodGrpMbr.Apttus_Config2__ProductId__c = prodInsertList[2].Id; 
        prodGrpMbr.Apttus_Config2__ProductGroupId__c = prodGrp.Id; 
        prodGrpMbr.Apttus_Config2__Sequence__c = 0;
        Database.insert(prodGrpMbr);
        
        //Database.UpsertResult[] srList = Database.upsert(hierarchyList,false);
        //APTS_ProductRedistributionBatchHandler.getUpsertErrorDetails(srList,batchErrorsMap,'Error');
        
    }
    //Test Method to test the "APTS_ProductRedistributionBatch" Class
    @isTest
    static void testProdClassDelink(){
        Test.startTest();
        APTS_ProductRedistributionBatch prodDstBtch = new APTS_ProductRedistributionBatch();
        prodDstBtch.query = APTS_ProductRedistributionBatchHandler.getObjectQuery('Product2')+' WHERE APTS_Upserted_from_SAP__c=TRUE';
        DataBase.executeBatch(prodDstBtch); 
        
        Set<string> statusList=new Set<String>();
        statusList.add('Completed');
        statusList.add('Aborted');
        System.assert(statusList != null); // Added by Rajesh Patel
        AsyncApexJob job=[Select Id,JobType,ApexClassId, ApexClass.Name, Status,JobItemsProcessed,TotalJobItems,
        NumberOfErrors,CompletedDate,MethodName,ExtendedStatus,ParentJobId,LastProcessed,LastProcessedOffset 
        from AsyncApexJob where Status not in : statusList];
        APTS_ProductRedistributionBatchHandler.sendEmail(job);
        List<id> prodids = new List<id>();
        for(Product2 p : [Select id from Product2])
        {
        prodids.add(p.id);
        }
        //APTS_ProductRedistributionBatchHandler.runMaintenanceBatches(prodids);
        APTS_ProductRedistributionBatchHandler.getCodesSet('testset');
        APTS_ProductRedistributionBatchHandler.createMemberRecord(prodGrp.id,prodids[0]);
        APTS_ProductRedistributionBatchHandler.changeStringToListValue('part1,part2');
        //prodDstBtch.execute(,);
        Test.stopTest();       
    }

}