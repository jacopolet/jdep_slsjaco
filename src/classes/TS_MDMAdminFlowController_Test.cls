/*
* @author       Karen Hung
* @date         2 October 2019         
* @description   Test class for TS_MDMAdminFlowController
* @revision(s)
*/
@isTest
private class TS_MDMAdminFlowController_Test {
    
    private static List<Account>  accList;
    private static List<Customer_Holiday__c> chList;
    private static List<Apttus_Config2__AccountLocation__c> alList;
    private static List<Route_Line_Item__c>  rliList;
    private static List<Route__c> rList;
    private static List<PhysicalAsset__c> paList;
    private static List<Resource__c> resList;
    
    @TestSetup
    static void setupTestData() {     
        List<Account> acc = TS_TestDataFactory.createAccounts(1);
        insert acc;
        Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc[0].Id);
        insert al;
        Customer_Holiday__c ch = TS_TestDataFactory.createHoliday('My Holiday', al.Id);
        insert ch;
        Route__c r = TS_TestDataFactory.createRoute('My Route', al.Id);
        insert r;
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.AccountLocation__c = al.Id;
        pa.MothballAssetIndicator__c = false;
        pa.AssetStatus__c = 'Activated';
        pa.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pa.Machine_Care__c = 'Full Operating';
        insert pa;
        Route_Line_Item__c rli = TS_TestDataFactory.createRouteLine('My RouteLine', r.Id);
        rli.PhysicalAssetId__c = pa.Id;
        insert rli;
        Resource__c res = TS_TestDataFactory.createResourceSingle('My resource');
        insert res;     
        
    }
    
    //method to get all records
    static void getAllRecords(){
        accList = [SELECT Id FROM Account];
        alList = [SELECT Id FROM Apttus_Config2__AccountLocation__c];
        chList = [SELECT Id FROM Customer_Holiday__c];
        rList = [SELECT Id FROM Route__c];
        rliList = [SELECT Id FROM Route_Line_Item__c];
        paList = [SELECT Id FROM PhysicalAsset__c];
        resList = [SELECT Id FROM Resource__c];
    }
    
    @isTest
    private static void testGetRoutes(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) { 
            setupTestData();
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getRoutes(alList[0].Id,0);
            Test.stopTest();
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Route__c WHERE Account_Location__c =: alList[0].Id]);
        }
    }
    
    @isTest
    private static void testGetRouteItems(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getRouteItems(alList[0].Id,0,rList[0].Id);
            Test.stopTest();
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__c =: alList[0].Id]);
        }
    }
    
    @isTest
    private static void testGetHolidays(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getHolidays(alList[0].Id,0);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Customer_Holiday__c WHERE Account_Location__c =: alList[0].Id]);
        }
    }
    
    @isTest
    private static void testDeleteRecord(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.deleteRecord(rList[0].Id,'Route__c');
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(0,[SELECT COUNT() FROM Route__c WHERE Id =: rList[0].Id]);
        }
    }
    
    @isTest
    private static void testUpdateRouteItemRecord(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> recordIds = new List<String>();
            recordIds.add(rliList[0].Id);
            TS_MDMAdminFlowController.updateRouteItemRecord(recordIds,rList[0].Id);
            
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Route_Line_Item__c WHERE RouteId__c =: rList[0].Id]);
        }
    }
    
    @isTest
    private static void testUpdateRoutes(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<Route__c> routes = new List<Route__c>();
            routes.add(rList[0]);
            TS_MDMAdminFlowController.updateRoutes(routes);
            
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Route__c WHERE Id IN : routes]);
        }
    }
    
    @isTest
    private static void testUpdateRouteLines(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<Route_Line_Item__c> rlis = new List<Route_Line_Item__c>();
            rlis.add(rliList[0]);
            TS_MDMAdminFlowController.updateRouteLines(rlis);
            
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Route_Line_Item__c WHERE Id IN : rlis]);
        }
    }
    
    @isTest
    private static void testUpdateHolidays(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();  
            Test.startTest();
            List<Customer_Holiday__c> chs = new List<Customer_Holiday__c>();
            chs.add(chList[0]);
            TS_MDMAdminFlowController.updateHolidays(chs);
            
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM Customer_Holiday__c WHERE Id IN : chs]);
        }
    }
    
    @isTest
    private static void testGetRoutePicklist(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getRoutePicklist(alList[0].Id);
            
            Test.stopTest();
            
            //Verify Results
            Set<Id> routeIds = new Set<Id>();
            for(Route_Line_Item__c routeItem : [SELECT Id, RouteId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__c = :alList[0].Id]){
                routeIds.add(routeItem.RouteId__c);	    
            }
            System.assertEquals(1,[SELECT COUNT() FROM Route__c WHERE Id IN :routeIds]);
        }    
    }
    
    @isTest
    private static void testGetDetails(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            getAllRecords();
            Test.startTest();
            rList[0].Account_Location__c = alList[0].Id;
            update rList;
            TS_MDMAdminFlowController.AccountLocationWrapper.getDetails(alList[0].Id);
            Test.stopTest();
            //Verify Results
            Set<Id> routeIds = new Set<Id>();
            for(Route_Line_Item__c routeItem : [SELECT Id, RouteId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__c = :alList[0].Id]){
                routeIds.add(routeItem.RouteId__c);	    
            }
            System.assertEquals(1,[SELECT COUNT() FROM Route__c WHERE Id IN :routeIds]);
        }
    }
    
    @isTest
    private static void testAccountLocationWrapper(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.AccountLocationWrapper wrapper = new TS_MDMAdminFlowController.AccountLocationWrapper();
            wrapper.machineCount = 1;
            wrapper.routeCount = 1;
            wrapper.machineWORouteCount = 1;
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,wrapper.routeCount);
        }            
    }
    
    @isTest
    private static void testGetUnassignedMachines(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getUnassignedMachines(alList[0].Id,0);          
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    @isTest
    private static void testGetNoOpSched(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.getNoOpSched(alList[0].Id,0);
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    @isTest
    private static void testAssignMachines(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
            TS_MDMAdminFlowController.assignMachines(sList,rList[0].Id);
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    @isTest
    private static void testUpdateMachines(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
            TS_MDMAdminFlowController.updateMachines(sList, 'building', true, 'floor', 
                                                     '1234567890', 'area', true,Date.today(), 'Yes',
                                                     true, 'Yes', resList[0].Id, resList[0].Id, '10');
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    @isTest
    private static void testUpdateMachinesInline(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.updateMachinesInline(paList);
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    @isTest
    private static void testException(){
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile); 
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.hasException = true;
            TS_MDMAdminFlowController.getRoutes(alList[0].Id,0);
            TS_MDMAdminFlowController.getRouteItems(alList[0].Id,0,rList[0].Id);
            TS_MDMAdminFlowController.getHolidays(alList[0].Id,0);
            List<String> recordIds = new List<String>();
            recordIds.add(rliList[0].Id);
            TS_MDMAdminFlowController.updateRouteItemRecord(recordIds,rList[0].Id);
            List<Route__c> routes = new List<Route__c>();
            routes.add(rList[0]);
            TS_MDMAdminFlowController.updateRoutes(routes);
            List<Route_Line_Item__c> rlis = new List<Route_Line_Item__c>();
            rlis.add(rliList[0]);
            TS_MDMAdminFlowController.updateRouteLines(rlis);
            List<Customer_Holiday__c> chs = new List<Customer_Holiday__c>();
            chs.add(chList[0]);
            TS_MDMAdminFlowController.updateHolidays(chs);
            TS_MDMAdminFlowController.deleteRecord(rList[0].Id,'Route__c');
            TS_MDMAdminFlowController.getRoutePicklist(alList[0].Id);
            
            TS_MDMAdminFlowController.getUnassignedMachines(recordIds[0],0);
            TS_MDMAdminFlowController.getNoOpSched(recordIds[0],0);
            TS_MDMAdminFlowController.assignMachines(recordIds,routes[0].Id);
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
            TS_MDMAdminFlowController.updateMachines(sList, 'building', true, 'floor', 
                                                     '1234567890', 'area', true, Date.today(), 'Yes',
                                                     true, 'Yes', resList[0].Id, resList[0].Id, '10');
            TS_MDMAdminFlowController.updateMachinesInline(paList);
            
            
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(0,[SELECT count() from Route__c]);
        }   
    }
    
    @isTest
    private static void runBatch(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            TS_MDMAdminFlowController.executeRecalculationBatch('0001', 'NL', '1', 'all');
            Test.stopTest();
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }

    @isTest
    private static void testcheckThirdParty(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
			TS_MDMAdminFlowController.hasException = true;
            TS_MDMAdminFlowController.checkThirdParty();
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }

    @isTest
    private static void testrecordTypes(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
            TS_MDMAdminFlowController.recordTypes('WorkOrder');
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    @isTest
    private static void testCheckFlag(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            getAllRecords();
            Test.startTest();
            List<String> sList = new List<String>();
            sList.add(paList[0].Id);
            TS_MDMAdminFlowController.hasException = true;
            TS_MDMAdminFlowController.checkFlag('WorkOrder');
            TS_MDMAdminFlowController.getWithOpSched(alList[0].Id);
            TS_MDMAdminFlowController.evaluateAssignments(alList[0].Id, 'RouteItem');
            TS_MDMAdminFlowController.evaluateAssignments(alList[0].Id, 'Machine');
            TS_MDMAdminFlowController.checkCreateEditPermission();
            Test.stopTest();  
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM PhysicalAsset__c WHERE Id IN :paList]);
        }    
    }
    
    
}