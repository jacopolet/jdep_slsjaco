@isTest
private class APTS_ProductTranslationTriggerTest {
    @testSetup
    static void testSetup(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='ample@testUser.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',  
                          LocaleSidKey='en_US', ProfileId = p.Id, Elevated_Access_Reason__c = 'Authorization Issue',Elevated_Access_Reference__c = 'Authorization Issue',
                          TimeZoneSidKey='America/Los_Angeles', UserName='sampleone@testUser.com', Sales_Organization__c = 'SAP_0333');
        //insert new TriggerSettings__c(SetupOwnerId=UserInfo.getOrganizationId(), ProductTranslationTrigger__c=true);
        
        System.runAs(u) {
            //insert custom settings
            insert new TriggerSettings__c(ProductTranslationTrigger__c = true);
            insert new APTS_Webshop_Enabled__c(Webshops_to_Be_Enabled__c='NL');
        }
    }
    
    private static testMethod void testProductTranslationTrigger() {
        
        User usr=[Select Id from User where UserName='sampleone@testUser.com']; 
        System.runAs(usr) {
            List<Product2> productList=TestDataFactory.createProduct(50);
            insert productList;
            
            List<Apttus_Config2__ProductTranslation__c> productTransList= new List<Apttus_Config2__ProductTranslation__c>();
            for(Product2 prod: productlist){
                Apttus_Config2__ProductTranslation__c prodTrans = new Apttus_Config2__ProductTranslation__c();
                prodTrans.Apttus_Config2__ProductId__c = prod.id;
                prodTrans.Apttus_Config2__ProductCode__c= prod.ProductCode;
                prodTrans.Apttus_Config2__Name__c = 'Test'+prod.Name;
                prodTrans.Apttus_Config2__Description__c ='Test';
                // prodTrans.APTS_Product_active__c = false;
                
                productTransList.add(prodTrans);
            }
            Test.startTest();
            APTS_ProductTranslationTriggerHandler.getProducts(new Set<string>{'TEST'});
            insert productTransList;
            productTransList[0].Apttus_Config2__Description__c='Updated Description';
            update productTransList;
            delete productTransList;
            undelete productTransList;
            Test.stopTest();
        }
        List<Integration_Log__c> intLogCheck = [SELECT ID FROM Integration_Log__c];
        system.assert(intLogCheck.size()>0);
    }
}