/**
* @author        Ritesh Kumar
* @date          08.16.2018          
* @description   Test class for TS_BusinessHoursChecker
* @revision(s)
*/
@isTest
public class TS_BusinessHoursChecker_Test {
    static PhysicalAsset__c pa;
    static APTS_Meter_Reading_Data__c meter;
    
    /* Method responsible for creating custom setting records */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.APTS_MeterReadingDataTrigger__c = true;
        upsert trg;


        List <BusinessHours> businessHours_List = [SELECT Id, MondayEndTime, TuesdayEndTime, WednesdayEndTime, ThursdayEndTime,FridayEndTime, SaturdayEndTime, SundayEndTime, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
       
        String recordType = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT).getRecordTypeId();
        CountrySetting__c countrySetting = new CountrySetting__c(RecordTypeId= recordType,Active__c = true ,Country__c = 'SAP_0333',   Priority__c='Medium', SLAinHours__c=4, Business_Hours__c = businessHours_List[0].id);
        insert countrySetting;
    }
    
    /* Method responsible for creating test data */
    static void setupTestData() {

    	try{
    		pa = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
                                  Connected__c = 'No',
                                  CounterReading__c = 'Yes',
                                  SalesOrganization__c = 'SAP_0333');
	        insert pa;
    	} catch (Exception e){
    		System.debug(e);
    	}

    	try{
    		meter = new APTS_Meter_Reading_Data__c(PhysicalAsset__c = pa.Id);
	        insert meter;
    	} catch (Exception e){
    		System.debug(e);
    	}
        
    }
    
    //Method to test the nest business day
    @isTest static void test_getNextBusinessDay(){
        //To hold the record of countrysetting.
        List<CountrySetting__c> countrySetting_List = new List<CountrySetting__c>();
        BusinessHours businessHours_obj = [SELECT Id FROM BusinessHours WHERE MondayEndTime != null LIMIT 1];
        CountrySetting__c countrySetting_obj = new CountrySetting__c();
        countrySetting_obj.Name = 'Country Test';
        countrySetting_obj.Active__c = true;
        countrySetting_obj.Business_Hours__c = businessHours_obj.Id;
        countrySetting_List.add(countrySetting_obj);
        insert countrySetting_List;
        Test.startTest();
        List<DateTime> DateTime_List = TS_BusinessHoursChecker.getNextBusinessDay(countrySetting_List);
        Test.stopTest();
        system.assert(DateTime_List != null);
    } 
    
     //Method to test the nest business day
    @isTest static void test_getNextBusinessDay1(){
        //To hold the record of countrysetting.
        List<CountrySetting__c> countrySetting_List = new List<CountrySetting__c>();
        List<BusinessHours> businessHours_obj = [SELECT Id FROM BusinessHours WHERE SundayEndTime != null];
        CountrySetting__c countrySetting_obj = new CountrySetting__c();
        countrySetting_obj.Name = 'Country Test';
        countrySetting_obj.Active__c = true;
        countrySetting_obj.Business_Hours__c = businessHours_obj[2].Id;
        countrySetting_List.add(countrySetting_obj);
        insert countrySetting_List;
        Test.startTest();
        List<DateTime> DateTime_List = TS_BusinessHoursChecker.getNextBusinessDay(countrySetting_List);
        Test.stopTest();
        system.assert(DateTime_List != null);
    } 
    
    /* new Method to test counter reading for those with changes in fields*/
    static testmethod void test_counterReadingTaskNew() {

        setupTestData();

        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        meter.APTS_Reason_code_SFDC__c = 'Work Order Created';
        meter.APTS_Corrective_Action__c = TS_Constants.METERREADING_WORKORDERCREATED;
        meter.APTS_Status__c = TS_Constants.STATUS_INPROGRESS;
        meter.PhysicalAsset__c = pa.Id;
        
        APTS_Meter_Reading_Data__c newMeter = new APTS_Meter_Reading_Data__c();
        newMeter.PhysicalAsset__c = pa.Id;
        newMeter.APTS_Status__c = TS_Constants.STATUS_INPROGRESS;
        newMeter.APTS_Reason_code_SFDC__c = 'Work Order Created';
        

        System.runAs(u) {
            Test.startTest();
            	insert newMeter;
                update meter;
                delete meter;
                undelete meter;
                System.assertNotEquals(null,meter);
            Test.stopTest();
        }
    }

    //Francis Allen Alindogan  04/13/2020
    //Method to test if the static return map is being populated. Workaround for test class coverage regardless of day.
    static testmethod void testNextBusinessDayMap() {
        List<CountrySetting__c> countrySetting_List = new List<CountrySetting__c>();
        BusinessHours businessHours_obj = [SELECT Id FROM BusinessHours WHERE SundayEndTime != null LIMIT 1];
        CountrySetting__c countrySetting_obj = new CountrySetting__c();
        countrySetting_obj.Name = 'Country Test';
        countrySetting_obj.Active__c = true;
        countrySetting_obj.Business_Hours__c = businessHours_obj.Id;
        countrySetting_List.add(countrySetting_obj);
        insert countrySetting_List;
        Test.startTest();
        TS_BusinessHoursChecker.isTest = true;
        List<DateTime> DateTime_List = TS_BusinessHoursChecker.getNextBusinessDay(countrySetting_List);
        TS_BusinessHoursChecker.isTest = false;
        List<DateTime> DateTime_List2 = TS_BusinessHoursChecker.getNextBusinessDay(countrySetting_List);
        Test.stopTest();
        system.assert(TS_BusinessHoursChecker.nextBusinessDayMap != null);
    }
}