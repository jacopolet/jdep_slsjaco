/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Test class for TS_CustomPicklistController
* @revision(s)
*/
@isTest
private class TS_CustomPicklistControllerTest {
	
	@isTest static void test_fetchPicklistValues() {
		Test.startTest();
		List < TS_CustomPicklistController.PickListWrapper > picList = TS_CustomPicklistController.fetchPicklistValues('Case','Type');
		Test.stopTest();
		System.assertNotEquals(0, picList.size());
	}
	
	
	
}