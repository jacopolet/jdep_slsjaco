/*
* @author        Marvin Gatchalian
* @date          2.19.2018          
* @description   Test class for TS_HolidayWrapper
* @revision(s)	 4.26.2018 Paul Aguiling - Updated test method on Start_Date__c = Date.newinstance(2018, 4, 23);
*/
@isTest
public with sharing class TS_HolidayWrapper_Test {
	
    private static testMethod void OperatingScheduleWrap_Test() {
    	User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
		System.runAs(u) {
			Test.startTest();
				
				BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
				
				Date mdate = date.today();
				String bhId = String.valueOf(bs.id);
				//id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'High Vol. 1 a Day');
				id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
				
				PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
				pa.RecordTypeId = rtpa;
				insert pa;
				
				OperatingSchedule__c testOS = TS_TestDataFactory.createOperatingSchedule ();
				testOS.PhysicalAsset__c = pa.id;
				testOS.RecordTypeId = Schema.SObjectType.OperatingSchedule__c.getRecordTypeInfosByName().get('Daily').getRecordTypeId();
				testOS.Start_Date__c = Date.newinstance(2018, 4, 23);
				insert testOS;
				
				
				OperatingSchedule__c os = [SELECT Id, Start_Date__c, TypeofContract__c, OP_247Customer__c, 
											C_2_Wednesday__c, SM_2_Wednesday__c, LM_2_Wednesday__c, 
											R_2_Wednesday__c, C_2_Thursday__c, SM_2_Thursday__c, 
											LM_2_Thursday__c, R_2_Thursday__c, C_2_Friday__c, LM_2_Tuesday__c,
											SM_2_Friday__c, LM_2_Friday__c, R_2_Friday__c, C_2_Saturday__c, 
											SM_2_Saturday__c, LM_2_Saturday__c, R_2_Saturday__c, C_2_Sunday__c, 
											SM_2_Sunday__c, LM_2_Sunday__c, R_2_Sunday__c, C_1_Sunday__c, 
											SM_1_Sunday__c, LM_1_Sunday__c, R_1_Sunday__c, C_1_Monday__c, 
											SM_1_Monday__c, LM_1_Monday__c, R_1_Monday__c, C_1_Tuesday__c, 
											SM_1_Tuesday__c, LM_1_Tuesday__c, R_1_Tuesday__c, C_1_Wednesday__c, 
											SM_1_Wednesday__c, LM_1_Wednesday__c, R_1_Wednesday__c, C_1_Thursday__c, 
											SM_1_Thursday__c, LM_1_Thursday__c, R_1_Thursday__c, C_1_Friday__c, 
											LM_1_Friday__c, SM_1_Friday__c, R_1_Friday__c, C_1_Saturday__c,
											LM_1_Saturday__c, SM_1_Saturday__c, R_1_Saturday__c, C_2_Tuesday__c, 
											SM_2_Tuesday__c, R_2_Tuesday__c, C_2_Monday__c, LM_2_Monday__c,
											SM_2_Monday__c, R_2_Monday__c, ForceScheduleToNextBusinessDay__c
											FROM OperatingSchedule__c
											WHERE Active__c = true];
				
				TS_OperatingTaskUtility tsUtils = new TS_OperatingTaskUtility();
				
				Map<Integer, boolean> fHM = tsUtils.getFutureHolidayMap (10, bhId, mdate);
				Map<Integer, boolean> pHM = tsUtils.getPastHolidayMap (10, bhId, mdate);
				
				TS_HolidayWrapper ts = new TS_HolidayWrapper();
				
				Map<Integer, TS_HolidayWrapper.OpSched> tsMapF = ts.getFwdHolidayMap (mdate, os, fHM);
				Map<Integer, TS_HolidayWrapper.OpSched> tsMapP = ts.getBwkHolidayMap (mdate, os, pHM);
				
				//Verify if index 1 is tomorrow
				system.assertequals(tsMapF.get(1).actualDate, mdate.addDays(1));
				//Verify if index 1 is yesterday
				system.assertequals(tsMapP.get(1).actualDate, mdate.addDays(-1));
				
			Test.stopTest();
		}
    }
}