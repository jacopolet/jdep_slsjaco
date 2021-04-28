/*
* @author        Francis Allen Alindogan
* @date          05.12.2020
* @description   Test class for TS_CreateOperatingTaskController.
* @revision(s)
*/
@isTest
private class TS_CreateOperatingTaskControllerTest {

 
    static Apttus_Config2__AccountLocation__c newAccLoc;
    static PhysicalAsset__c newPa;


    @testSetup
    static void dataSetup() {

        product2 prod = new product2();
        prod.Name = 'Operating Sched Product Test';
        prod.APTS_Material_Type__c = 'ZSPR';
        insert prod;

        Account acc = new Account(Name='Sample Account', Phone='+31302979111');
        insert acc;
		
        Resource__c res = TS_TestDataFactory.createResourceTest('0002331323');
        insert res;
        
        Apttus_Config2__AccountLocation__c accLoc = TS_TestDataFactory.createAccountLocation(acc.Id);
        accLoc.Third_Party_Resource__c = res.Id;
        insert accLoc;

        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.AccountLocation__c = accLoc.Id;
        pa.SalesOrganization__c = 'SAP_0111';
        pa.Product__c = prod.Id;
        insert pa;         
        
    }

     //Load all records
     static void dataLoad(){
        newPa = [SELECT Id FROM PhysicalAsset__c LIMIT 1];
        newAccLoc = [SELECT Id FROM Apttus_Config2__AccountLocation__c LIMIT 1];
    }

    /**
    * @author        Francis Allen Alindogan
    * @date          05.12.2020           
    * @description   Test method for createOperatingTask() in TS_CreateOperatingTaskController
    * @revision(s)
    */  
    private static testMethod void testCreateOperatingTask(){    
        Test.startTest();
            dataSetup();
            dataLoad();
            TS_CreateOperatingTaskController.thirdPartyS20Enabled = true;
            Boolean enabledFlag = TS_CreateOperatingTaskController.checkFeatureFlag();
            String ret = TS_CreateOperatingTaskController.createOperatingTask(newPa.Id, 'SAP_0111', newAccLoc.Id, Label.TS_Activity_Type_S20, 'Small', date.valueof('2020-01-01'), date.valueof('2020-01-01'),'TestDesc' );
            System.assertNotEquals(ret, 'ERROR');
        Test.stopTest();

    }
    
    /**
    * @author        Karen Hung
    * @date          18.08.2020           
    * @description   Test method for noRoute() in TS_CreateOperatingTaskController
    * @revision(s)
    */  
    private static testMethod void testnoRoute(){    
        Test.startTest();
            dataSetup();
            dataLoad();
            Boolean noRoute = TS_CreateOperatingTaskController.noRoute(newPa.Id);
            System.assertEquals(noRoute, true);
        Test.stopTest();
    }

}