/*
* @author        Marvin Gatchalian
* @date          2.19.2018          
* @description   Test class for TS_OperatingTaskUtility
* @revision(s)
*/


@isTest
public with sharing class TS_OperatingTaskUtility_Test {
	private static testMethod void HolidayMap_Test() {
		Test.startTest();
			
			BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
			
			Date mdate = date.today();
			String bhId = String.valueOf(bs.id);
			
			TS_OperatingTaskUtility tsUtils = new TS_OperatingTaskUtility();
			
			Map<Integer, boolean> fHM = tsUtils.getFutureHolidayMap (10, bhId, mdate);
			Map<Integer, boolean> pHM = tsUtils.getPastHolidayMap (10, bhId, mdate);
			
			//Verify the size of map including 0
			system.assertequals(fHM.size(), 11);

		Test.stopTest();
    }
}