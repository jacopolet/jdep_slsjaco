/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Test class for APTS_WarehousingCost
 * @Created Date: May 7, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      May 7, 2018     Initial Version
 * 
 *************************************************************/
@isTest
public class APTS_WarehousingCostTest {

    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        
        
        insert new TriggerSettings__c(Agreement__c = true);
        
        Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
        insert oAcc;
        
        List<APTS_Warehousing_Cost__c> whCostList = new List<APTS_Warehousing_Cost__c>();
        APTS_Warehousing_Cost__c oWHCost = new APTS_Warehousing_Cost__c();
        oWHCost.APTS_Start_Date__c = date.today().addDays(-2);
        oWHCost.APTS_End_Date__c = date.today().addMOnths(2);
        oWHCost.APTS_WC_PrefDelivery__c = 'Routesales';
        oWHCost.APTS_WC_SalesOrg__c = 'SAP_0111';
        oWHCost.APTS_WC_WarehouseCost__c = 100;
        whCostList.add(oWHCost);
        
        APTS_Warehousing_Cost__c oWHCost2 = new APTS_Warehousing_Cost__c();
        oWHCost2.APTS_Start_Date__c = date.today().addMonths(2).addDays(1);
        oWHCost2.APTS_End_Date__c = date.today().addMOnths(4);
        oWHCost2.APTS_WC_PrefDelivery__c = 'Routesales';
        oWHCost2.APTS_WC_SalesOrg__c = 'SAP_0111';
        oWHCost2.APTS_WC_WarehouseCost__c = 110;
        whCostList.add(oWHCost2);
        
        insert whCostList;
        
        
    }
    
     private static testMethod void netherlandsAggTest() {
        List<Apttus__APTS_Agreement__c> agrList = new List<Apttus__APTS_Agreement__c>();
        Account oAcc = [SELECT Id FROM Account LIMIT 1];
        Apttus__APTS_Agreement__c oAgg1 = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg1.APTS_PricingDate__c = date.today().addDays(1);
        oAgg1.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        agrList.add(oAgg1);
		
		Apttus__APTS_Agreement__c oAgg2 = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg2.APTS_PricingDate__c = date.today().addDays(1);
        oAgg2.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        oAgg2.APTS_Region__c = 'SAP_0333';
		agrList.add(oAgg2);
		
		Apttus__APTS_Agreement__c oAgg3 = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
		oAgg3.APTS_PricingDate__c = date.today().addDays(1);
        oAgg3.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        oAgg3.APTS_Region__c = 'SAP_0111';
		agrList.add(oAgg3);
		
         APTS_WarehousingCost wc = new APTS_WarehousingCost();
		wc.getWarehousingCost(agrList);
			}
    
/*
    private static testMethod void netherlandsAggTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
         Account testAccount = APTS_TestUtils.createGrandParentAccount();
        testAccount.Name = 'Test Account';
        Database.Insert(testAccount);
        
        Account oAcc = [SELECT Id FROM Account LIMIT 1];
              Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        Database.Insert(priceList);
        Opportunity testOppty = APTS_TestUtils.createOpportunity(testAccount.id);
        insert testOppty;
        Id recordtype = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Deal).getRecordTypeId();
        Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
      oAgg.Apttus__Related_Opportunity__c = testOppty.id;
        Apttus__APTS_Agreement__c optionTestAgreement = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Activated',Apttus__Related_Opportunity__c = testOppty.id);
        //agreementList.add(optionTestAgreement);
        Database.Insert(optionTestAgreement);
        Apttus__APTS_Agreement__c oAgg = new Apttus__APTS_Agreement__c(Apttus__Account__c = testAccount.Id, 
                        Name = 'New Agreement',RecordTypeId = recordtype,
                        Apttus__Contract_Start_Date__c = Date.today(), Apttus__Contract_End_Date__c = Date.today()+365, 
                        Apttus_CMConfig__PriceListId__c = priceList.id,Apttus__Subtype__c ='Fixed-Term-Fixed Costs',
                        Apttus__Status_Category__c = 'Request', Apttus__Status__c = 'Activated');
        //oAgg.APTS_PricingDate__c = date.today().addDays(1);
        //oAgg.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
       // oAgg.APTS_Region__c = 'SAP_0111';
        System.debug('**Abhishek'+oAgg);
        insert oAgg;
        system.runAs(testUser) {
         //   test.startTest();
            //insert oAgg;
            update oAgg;
           // test.stopTest();
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_Warehousing_Cost__c FROM Apttus__APTS_Agreement__c oAgg LIMIT 1];
        system.assertEquals(100,oAggCheck.APTS_Warehousing_Cost__c);
    }
    
    private static testMethod void routesalesNoRegionTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        Account oAcc = [SELECT Id FROM Account LIMIT 1];
        
        Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg.APTS_PricingDate__c = date.today().addDays(1);
        oAgg.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        system.runAs(testUser) {
            test.startTest();
            insert oAgg;
            update oAgg;
            test.stopTest();
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_WarehousingCost__c FROM Apttus__APTS_Agreement__c oAgg LIMIT 1];
        system.assertEquals(null,oAggCheck.APTS_WarehousingCost__c);
    }
    
    private static testMethod void belgiumNoWarehousingCostRecTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        Account oAcc = [SELECT Id FROM Account LIMIT 1];
        
        Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg.APTS_PricingDate__c = date.today().addDays(1);
        oAgg.APTS_Preferred_way_of_ingredient_deliver__c = 'Routesales';
        oAgg.APTS_Region__c = 'SAP_0333';
        system.runAs(testUser) {
            test.startTest();
            insert oAgg;
            update oAgg;
            test.stopTest();
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_WarehousingCost__c FROM Apttus__APTS_Agreement__c oAgg LIMIT 1];
        system.assertEquals(null,oAggCheck.APTS_WarehousingCost__c);
    }
*/
}