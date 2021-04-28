/**
* @author        Rey Austral
* @date          10.2.2017           
* @description   Test Class for TS_PicklistFieldHelper and TS_BitSet
* @revision(s)
*/
@isTest
private class TS_PicklistFieldHelperTest {
	
	@isTest static void test_getDependentOptionsImpl() {
		Test.startTest();
		Map<String,TS_PicklistEntryWrapper> pickMap = TS_PicklistFieldHelper.getDependentOptionsImpl('Case','Type','SubType__c');
		Test.stopTest();
		System.assertNotEquals(0, pickMap.size());
	}
	
	@isTest static void test_NoObjectFound() {
		Test.startTest();
		Map<String,TS_PicklistEntryWrapper> pickMap = TS_PicklistFieldHelper.getDependentOptionsImpl('Case__c','Type','SubType__c');
		Test.stopTest();
		System.assertEquals(null, pickMap);
	}

	@isTest static void test_NoFieldFound() {
		Test.startTest();
		Map<String,TS_PicklistEntryWrapper> pickMap = TS_PicklistFieldHelper.getDependentOptionsImpl('Case','Type','SubType1__c');
		Test.stopTest();
		System.assertEquals(0, pickMap.size());
	}
	
}