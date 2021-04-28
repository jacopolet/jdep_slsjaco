@isTest
private class APTS_ProdClassificationTriggerTest {
    @testSetup
    static void testSetup(){
    
		User testUser = APTS_TestDataFactory.createUser();
        System.runAs(testUser) {
            //insert custom settings
            insert new TriggerSettings__c(ProdClassificationTrigger__c = true);
            insert new APTS_Webshop_Enabled__c(Webshops_to_Be_Enabled__c='NL');
        }
    }
    
    private static testMethod void testProdInsertUpdate() {
		User usr= [SELECT Id FROM User WHERE UserName = 'testuser123@jdecoffee.com' LIMIT 1];
        System.runAs(usr) {
       
            List<Product2> productList=new List<Product2>();
            productList=TestDataFactory.createProduct(50);
            insert productList;
            
            List<Apttus_Config2__ClassificationName__c> category=new List<Apttus_Config2__ClassificationName__c>();
            category=TestDataFactory.createCategory(2);
            insert category;
              Test.startTest();
            List<Apttus_Config2__ClassificationHierarchy__c> cateList=new List<Apttus_Config2__ClassificationHierarchy__c>();
            cateList=TestDataFactory.createHierarchy(2,category);
            insert cateList;
            
            
            List<Apttus_Config2__ProductClassification__c> cateItemList=new List<Apttus_Config2__ProductClassification__c>();
            cateItemList=TestDataFactory.createClassification(50,productList,category,cateList);
            insert cateItemList;
            
            /*cateItemList[0].Apttus_Config2__ClassificationId__c=cateList[1].Id;
            update cateItemList[0];
           
            cateItemList[0].Apttus_Config2__MaxQuantity__c=12223.123;       
            
            update cateItemList;*/
             
          
             update cateItemList;
             delete cateItemList;
             undelete cateItemList;
            Test.stopTest();
         }
         List<Integration_Log__c> intLogCheck = [SELECT ID FROM Integration_Log__c];
         system.assert(intLogCheck.size()>0);
    }
}