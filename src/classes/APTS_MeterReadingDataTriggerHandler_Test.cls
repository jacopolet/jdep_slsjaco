/**
* @author        Abram Vixen Reyes
* @date          28.9.2018
* @description   Test class for APTS_MeterReadingDataTriggerHandler
* @revision(s)   
*/

@isTest
public class APTS_MeterReadingDataTriggerHandler_Test {
    
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

    /* Method to test counter reading*/
    static testmethod void test_counterReadingTask() {

    	setupTestData();

	    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
	    meter.APTS_Reason_code_SFDC__c = 'Work Order Created';

	    System.runAs(u) {
	    	Test.startTest();
	    		update meter;
	    	Test.stopTest();
	    }

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
    
    /* new Method to test counter reading for those with FUP WO*/
    static testmethod void test_counterReadingTaskFUP() {
        
        setupTestData();
	    User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
	    meter.APTS_Reason_code_SFDC__c = 'Work Order Created';
        meter.APTS_Corrective_Action__c = TS_Constants.METERREADING_WORKORDERCREATED;
        meter.APTS_Status__c = TS_Constants.STATUS_INPROGRESS;
        meter.PhysicalAsset__c = pa.Id;
        
        Id counterReadingFUP = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_COUNTERREADING).getRecordTypeId();
        WorkOrder wo = TS_TestDataFactory.createWorkOrder();
        wo.RecordtypeId = counterReadingFUP;
        wo.OP_Physical_Asset__c = pa.Id;
        wo.WorkOrderType__c = TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP;
        wo.Status = TS_Constants.WO_STATUS_SENTPLANNING;
                
        System.runAs(u) {
            Test.startTest();
            insert wo;
            update meter;
            System.assertNotEquals(null,meter);
            Test.stopTest();
        }
        
    }
}