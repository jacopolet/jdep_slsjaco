/**
* @author        Karen Hung
* @date          11.1.2018
* @description   test class for TS_PhysicalAssetUpdate_Batch
* @revision(s)
*/
@isTest
private with sharing class TS_PhysicalAssetUpdate_Batch_Test {

	static Date dateRun;
	static PhysicalAsset__c pa;

	/*setup data*/
	@testSetup
	static void dataSetup(){

		//Machine recordtype
		String machineId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(TS_Constants.PA_RECTYPE_MACHINE).getRecordTypeId();
		pa = TS_TestDataFactory.createPhysicalAsset();
		pa.EndDate__c = Date.Today().addDays(-1);
		pa.RecordTypeId = machineId;
		dateRun = Date.today();
	}

	/*test batch*/
	@isTest
	static void test_TS_PhysicalAssetUpdate_Batch(){
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	dataSetup();
        	
        	List<PhysicalAsset__c> paList = new List<PhysicalAsset__c>{ pa };
        	database.insert(paList);

        	Test.startTest();
	        
	        TS_PhysicalAssetUpdate_Batch paUpdate = new TS_PhysicalAssetUpdate_Batch(dateRun);
	        Database.executeBatch(paUpdate,50);
        	
        	Test.stopTest();

        	System.assertEquals(1,paList.size());

        }
	}
	/*test exception*/
	static testMethod void test_TS_PhysicalAssetUpdate_Exception(){
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	dataSetup();
        	
        	List<PhysicalAsset__c> paList = new List<PhysicalAsset__c>{ pa };
        	database.insert(paList);

        	Test.startTest();
        	TS_PhysicalAssetUpdate_Batch paUpdate = new TS_PhysicalAssetUpdate_Batch(dateRun);
        	TS_PhysicalAssetUpdate_Batch.hasException = true;	

        	Database.executeBatch(paUpdate,50);
        	
        	Test.stopTest();
        }

        System.assert(TS_PhysicalAssetUpdate_Batch.hasException);		
	}
}