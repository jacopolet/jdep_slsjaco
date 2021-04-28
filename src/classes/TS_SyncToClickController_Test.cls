/*
    * @author       Karen Hung
    * @date         2 October 2019         
    * @description   Test class for TS_SyncToClickController
    * @revision(s)
    */
@isTest
private class TS_SyncToClickController_Test {
    
    public static Product2 prod;
    
    @TestSetup
    static void setupTestData() {
        prod = TS_TestDataFactory.createProductTest('My Product', 'Material Type');
        prod.APTS_Material_Type__c = 'ZSER';
        insert prod;    
    }
    
    static testMethod void updateProductTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
        	setupTestData();
            TS_SyncToClickController.updateProduct(prod.Id);
            
        }
        system.assert(prod !=null);
    }
    
    static testMethod void updateProductAdminTest(){
        User u = TS_TestDataFactory.createUser('System Administrator');
        System.runAs(u) { 
            setupTestData();
            prod.APTS_Material_Type__c = 'ZCMA';
            update prod;
            TS_SyncToClickController.updateProduct(prod.Id);           
        }
        system.assert(prod !=null);
    }
    
    static testMethod void updateProductAdminExceptionTest(){
        User u = TS_TestDataFactory.createUser('System Administrator');
        System.runAs(u) { 
            setupTestData();
            TS_SyncToClickController.hasException = true;
            TS_SyncToClickController.updateProduct(prod.Id);           
        }
        system.assert(prod !=null);
    }

}