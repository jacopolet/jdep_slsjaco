/**************************************************************
* @Author: saranya.a.rajagopal
* @Company: Accenture
* @Description: Test class for  APTS_ProductBizIslandlevel
* @Created Date: OCT 10, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      saranya.a.rajagopal      Oct 10, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_ProductBizIslandlevelTest {

     @testSetup
     static void testData(){
     
            Account acc = APTS_TestDataFactory.createAccount('testAccount');
            acc.APTS_BizIsland_Bonsai_Account__c=true;
            Database.insert(acc);
            
            Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
            prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
            prod1.APTS_Cross_plant_material_status__c= 'PR';
            prod1.APTS_Sales_Catalog__c = '1234';
            prod1.Apttus_Config2__Uom__c = 'SAP_EA';
            prod1.Apttus_Config2__ConfigurationType__c='Option';
            prod1.Family='SAP_01';
            Database.insert(prod1);
            
            Apttus_Config2__ClassificationName__c catego = APTS_TestDataFactory.createCategory();
            Database.insert(catego);
            
            Apttus_Config2__ClassificationHierarchy__c catehi = APTS_TestDataFactory.createCategoryHierarchy(catego.id, 'test');
            Database.insert(catehi);
            
            Apttus_Config2__ClassificationHierarchy__c catSub = APTS_TestDataFactory.createSubCategory(catego.id,catehi.id);
            Database.insert(catSub); 
              
            Apttus_Config2__ProductOptionGroup__c optionGr = APTS_TestDataFactory.createProductOptionGroup(catehi.id,catSub.id);
            optionGr.Apttus_Config2__ParentOptionGroupId__c =catehi.id;
            Database.insert(optionGr);
            
            Apttus_Config2__ProductOptionComponent__c produOp = APTS_TestDataFactory.createProductOptionComponent(optionGr.id);
            produOp.Apttus_Config2__ParentProductId__c= prod1.id;
            Database.insert (produOp);
            
            Apttus_Config2__ProductClassification__c classpr = APTS_TestDataFactory.createProductClassification(catsub.id,prod1.id);
            Database.insert(classpr);
            
            Bonsai__c customSetting = new Bonsai__c();
            customSetting.Name = 'test';
            customSetting.Delta_Load__c = true;
            customSetting.Full_Load__c = true;
            insert customSetting;
        
            BizIsland_Request__c bizland = new BizIsland_Request__c();
            bizland.name = 'Bonsai Request '+Date.Today();
            Database.insert(bizland);
            
        }
          @isTest
        static void testElseBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = true;
        update customSetting;
       
        Test.startTest();
        APTS_AccountBizIsland accountBizbatch = new APTS_AccountBizIsland();
        Database.executeBatch(accountBizbatch,200);
        Test.stopTest();
    }
        
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_ProductBizIslandlevel  productBizbatchlevel = new APTS_ProductBizIslandlevel ();
            Database.executeBatch(productBizbatchlevel, 200);
            Test.stopTest();
       }
}