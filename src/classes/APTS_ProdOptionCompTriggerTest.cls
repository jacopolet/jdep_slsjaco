@isTest
private class APTS_ProdOptionCompTriggerTest {
    @testSetup
    static void testSetup(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = APTS_TestDataFactory.createUser();
        insert u;
        
        System.runAs(u) {
            //insert custom settings
            insert new TriggerSettings__c(ProdOptionCompTrigger__c = true);
            insert new APTS_Webshop_Enabled__c(Webshops_to_Be_Enabled__c='NL');
        }
    }
    
    private static testMethod void testProdInsertUpdate() {
        User usr=[Select Id from User where UserName='testuser123@jdecoffee.com']; 
         System.runAs(usr) {
            List<Product2> productList=new List<Product2>();
            productList=TestDataFactory.createProduct(50);
            insert productList;
            System.assert(productList != Null);
            
            
           /* List<Apttus_Config2__PriceList__c> priceList=new List<Apttus_Config2__PriceList__c>();
            priceList=TestDataFactory.createPriceList(1);
            insert priceList;*/
            
            Test.startTest();
            List<Apttus_Config2__ProductOptionComponent__c> plItemList=new List<Apttus_Config2__ProductOptionComponent__c>();
            plItemList=TestDataFactory.createProdOptionComp(50,productList);
            insert plItemList;
            
            plItemList[0].Apttus_Config2__DefaultQuantity__c=66;       
            
            update plItemList;
            System.assertEquals(plItemList[0].Apttus_Config2__DefaultQuantity__c,66);
             
            /*plItemList[0].Apttus_Config2__Modifiable__c=false;       
            plItemList[1].Apttus_Config2__Sequence__c=8.009;
            
            update plItemList;
             
            plItemList[0].Apttus_Config2__Modifiable__c=true;       
           
            update plItemList;*/
            
             delete plItemList;
             undelete plItemList;
            Test.stopTest();
         }
    }
    
    public static testmethod void testMyUpdate_Error()
    {
    Product2 record = new Product2(); // cannot update this record
    record.Name='Test';
    insert record;
    
    }
    
     public static testmethod void testIntegrationUtility()
    {
        Set<Id> poset = new Set<Id>();
        for(Apttus_Config2__ProductOptionComponent__c po : [Select id from Apttus_Config2__ProductOptionComponent__c])
        {
            poset.add(po.id);
        }
        APTS_IntegrationLogHandlerUtility.createIntegrationLogs(poset);
        APTS_IntegrationLogHandlerUtility.getWebShopString(new Set<String>{'abhi','shek'});
        
        
    }
        
        
}