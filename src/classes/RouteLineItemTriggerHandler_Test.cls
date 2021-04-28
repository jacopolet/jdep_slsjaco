/**
* @author        Karen Hung
* @date          10.12.2020
* @description   Test class for RouteLineItemTriggerHandler
* @revision(s)   
*/
@isTest
private class RouteLineItemTriggerHandler_Test {
   
    static Account acct;
    static PhysicalAsset__c asset;
    static Route__c route;
    static Route_Line_Item__c rli;
    
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.RouteLineItemTrigger__c = true;
        upsert trg;
    }
    
    static void setupTestData(){
        
        //Create product
        Product2 prod = TS_TestDataFactory.createProductTest('Operating Sched Product Test', 'ZSPR');
        insert prod;
        
        acct = APTS_TestUtils.createaccount();
        insert acct;
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868', acct.Id );
        accLocation.AverageRoutePrep__c = 1;
        accLocation.MTTTWithinSite__c = 2;
        accLocation.MTTOLocationSpecific__c = 1;
        accLocation.Mini_Sales_Organization__c = 'SAP_0975';
        insert accLocation;
        
        id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        asset = TS_TestDataFactory.createPhysicalAsset();
        asset.RecordTypeId = rtpa;
        asset.Machine_Care__c = 'Comfort Operating';
        asset.StartDate__c = date.today().addDays(-365);
        asset.EndDate__c = date.today().addDays(365);
        asset.TypeOfContract__c = 'Sales';
        asset.AssetStatus__c = 'Activated';
        asset.ActiveContract__c = true;
        asset.SalesOrganization__c = 'SAP_0333';
        asset.Product__c = prod.id;
        asset.UniqueNumber__c = '123ABC';
        asset.AccountLocation__c = accLocation.Id;
        asset.MothballAssetIndicator__c = false;
        insert asset;
        
        route = TS_TestDataFactory.createRoute('TEST R', accLocation.Id);
        insert route;
        
        rli = TS_TestDataFactory.createRouteLine('TEST RLI', route.Id);
        rli.PhysicalAssetId__c = asset.Id;
        insert rli;
        
    }
    
     @isTest static void checkRouteLineItemsTest(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {        	
            
            test.startTest();
            
            setupTestData();
            
            Route_Line_Item__c rli = new Route_Line_Item__c();
            rli.PhysicalAssetId__c = asset.Id;
            rli.RouteId__c = route.Id;
            insert rli;
            
            rli.Name = 'Test1';
            update rli;
            
            delete rli;
            undelete rli;
      
            test.stopTest();
            List<Route_Line_Item__c> rliList = [SELECT Id FROM Route_Line_Item__c];
            //verify if there's 2 route line item            
            system.assertEquals(2, rliList.size());
        }
    }
    
     @isTest static void checkRouteLineItemsTestEx(){
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {        	
            
            test.startTest();
            setupTestData();
            RouteLineItemTriggerHandler.hasException = true;
            
            Route_Line_Item__c rli = new Route_Line_Item__c();
            rli.PhysicalAssetId__c = asset.Id;
            rli.RouteId__c = route.Id;
            insert rli;
          
            test.stopTest();
            List<Route_Line_Item__c> rliList = [SELECT Id FROM Route_Line_Item__c];
            //verify if there's 2 route line item            
            system.assertEquals(2, rliList.size());
        }
    }

}