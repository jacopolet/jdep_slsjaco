/**
* @author        Karen Hung
* @date          11.1.2018
* @description   Class for TS_PhysicalAssetDataRemover
* @revision(s)
*/
@isTest
private with sharing class TS_PhysicalAssetDataRemover_Test {

	static PhysicalAsset__c pAsset;

	/*setup data*/
	@testSetup
	static void dataSetup(){
		pAsset = TS_TestDataFactory.createPhysicalAsset();
		//pAsset.Status = 'Activated';
	}

	/*test scenario 1 & 2*/
	@isTest
	static void test_removeFieldValuesNotInvocable(){
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
			dataSetup();
			List<PhysicalAsset__c> assetList = new List<PhysicalAsset__c>{ pAsset };
			database.insert(assetList);

			Test.startTest();
				TS_PhysicalAssetDataRemover.removeServicesFieldValues(assetList);
				TS_PhysicalAssetDataRemover.removeOperationalDataFieldValues(assetList);
			Test.stopTest();

			System.assertEquals(1,assetList.size());
		}
	}

	/*test scenario 3/ invocable*/
	static testMethod void test_removeFieldValuesInvocableEx(){
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
			dataSetup();
			List<PhysicalAsset__c> assetList = new List<PhysicalAsset__c>{ pAsset };
			database.insert(assetList);	

			Test.startTest();
				TS_PhysicalAssetDataRemover.removeOperationalDataFieldValuesInvocable(assetList);
				TS_PhysicalAssetDataRemover.hasException = true;
			Test.stopTest();
			System.assertEquals(1,assetList.size());
		}
	}

	/*test scenario 3/ invocable*/
	@isTest
	static void test_removeFieldValuesInvocable(){
		User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
			dataSetup();
			List<PhysicalAsset__c> assetList = new List<PhysicalAsset__c>{ pAsset };
			database.insert(assetList);	

			Test.startTest();
				TS_PhysicalAssetDataRemover.removeOperationalDataFieldValuesInvocable(assetList);
				TS_PhysicalAssetDataRemover.hasException = false;
			Test.stopTest();
			System.assertEquals(1,assetList.size());
		}
	}
}