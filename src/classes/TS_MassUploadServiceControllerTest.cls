/**
* @author        Abram Vixen Reyes
* @date          Feb. 16, 2021 
* @description   TS_MassUploadServiceController
* @revision(s)
*/
@isTest
public class TS_MassUploadServiceControllerTest {
   
    static CountrySetting__c csMassUploadServ = new CountrySetting__c();
    static WorkOrder wo = new WorkOrder();
    static WorkOrderLineItem woli = new WorkOrderLineItem();
    
    public static void dataSetup() {

        //CREATE COUNTRY SETTING
        csMassUploadServ = TS_TestDataFactory.createCountrySettings();
        csMassUploadServ.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c','Mass Upload Service Settings');
        csMassUploadServ.Active__c = true;
        csMassUploadServ.Name='Mass Update Jobs 3PO';
        csMassUploadServ.Object__c = 'WorkOrderLineItem';
        csMassUploadServ.Event__c = 'Update';
        csMassUploadServ.Required_Fields__c = 'Id,Status';
        csMassUploadServ.Optional_Fields__c = 'OP_CancelationReasonMachine__c';
        insert csMassUploadServ;
        
        //CREATE SAMPLE S20
        Date mdate = date.today().toStartofWeek().addDays(2);
        mdate = mdate.addDays(1);
        mdate = mdate.addDays(-14);

        wo = TS_TestDataFactory.createWorkOrder();
        wo.Route_Number__c = '1';
        wo.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
        wo.WorkOrderType__c = Label.TS_Activity_Type_S20;    
        wo.SalesOrganization__c = 'SAP_0111';
        //wo.Route_Id__c = r.Id;
        wo.Early_Start_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        wo.SLA_Date__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        wo.OwnerId = UserInfo.getUserId();
        //wo.Pricebook2Id = orgPB.Id;
        insert wo;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        //woli.PhysicalAsset__c = pa.Id;
        woli.EarlyStart__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli.SLADate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 16, 0, 0);
        woli.StartDate__c =  DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 8, 0, 0);
        woli.EndDate__c = DateTime.newInstance(mdate.year(), mdate.month(), mdate.day(), 11, 0, 0);
        woli.WorkOrderType__c = Label.TS_Activity_Type_S20; 
        woli.WorkOrderLineItemType__c = 'Small';
        woli.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
        woli.Status = 'Open';
        //woli.PricebookEntryId = pbe.Id;
        insert woli;          
    }

    static testMethod void test_uploadFile() {
        
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            dataSetup();
            TS_MassUploadServiceController.checkAccess();

            //CREATE CSV TO BASE64

            //SCENARIO 1: Incorrect PL value to throw exception in Batch
            String csvMock = 'Id,WorkOrderType__c,Status,OP_CancelationReasonMachine__c' 
                                + '\n' + String.valueOf(woli.Id) + ',S20,Completed,"sample cancelation, 123 cancel"';
            
            //SCENARIO 2: Mismatch sObjectType of Id and countrySettings - Batch error
            String csvMock2 = 'Id,WorkOrderType__c,Status,OP_CancelationReasonMachine__c' 
                                + '\n' + String.valueOf(wo.Id) + ',S20,Completed,"sample cancelation, 123 cancel"';
            
            //SCENARIO 3: Mismatch sObjectType of Id and countrySettings && Id not valid (exception) - Batch error 
            String csvMock3 = 'Id,WorkOrderType__c,Status,OP_CancelationReasonMachine__c' 
                                + '\n' + 'DummyIdForError' + ',S20,Completed,"sample cancelation, 123 cancel"';
            
            //SCENARIO 4: Correct file and successful update
            String csvMock4 = 'Id,WorkOrderType__c,Status,OP_CancelationReasonMachine__c' 
                                + '\n' + String.valueOf(woli.Id) + ',S20,Completed,';
            
            //SCENARIO 5: Missing required field
            String csvMock5 = 'Id,WorkOrderType__c,OP_CancelationReasonMachine__c' 
                                + '\n' + String.valueOf(woli.Id) + ',S20,';
            
            //SCENARIO 6:
            String csvMock6 = 'Id,WorkOrderType__c,OP_CancelationReasonMachine__c,Status' 
                                + '\n' + String.valueOf(woli.Id) + ',S20,,Start Work';

			//SCENARIO 7:
			String csvMock7 = 'Id,WorkOrderType__c,OP_CancelationReasonMachine__c,Status,Description' 
                                + '\n' + String.valueOf(woli.Id) + ',S20,,Completed,';

            String result = EncodingUtil.Base64Encode(Blob.valueOf(csvMock));
            String result2 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock2));
            String result3 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock3));
            String result4 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock4));
            String result5 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock5));
            String result6 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock6));
            String result7 = EncodingUtil.Base64Encode(Blob.valueOf(csvMock7));
            
            Test.startTest();
                TS_MassUploadServiceController.getProcessCountrySettings();
                TS_MassUploadServiceController.uploadFile('Test.csv', result, csMassUploadServ.Name, true, ',');
                TS_MassUploadServiceController.uploadFile('Test.csv', result2, csMassUploadServ.Name, true, ',');
                TS_MassUploadServiceController.uploadFile('Test.csv', result3, csMassUploadServ.Name, true, ',');
                TS_MassUploadServiceController.uploadFile('Test.csv', result4, csMassUploadServ.Name, true, ',');
                TS_MassUploadServiceController.uploadFile('Test.csv', result5, csMassUploadServ.Name, true, ',');
            
            	csMassUploadServ.Acceptable_Values__c = 'Status:Completed,Canceled;OP_CancelationReasonMachine__c:Mothball Not Needed,Machine issue,Customer issue,Not reachable';
            	update csMassUploadServ;
            	TS_MassUploadServiceController.uploadFile('Test.csv', result6, csMassUploadServ.Name, true, ',');  
            
            	csMassUploadServ.Conditional_Fields_Values__c = 'Status[Completed]:Description';
            	update csMassUploadServ;                
            	TS_MassUploadServiceController.uploadFile('Test.csv', result7, csMassUploadServ.Name, true, ',');
            	system.assert([SELECT Id FROM MassUploadServiceRecords__c  LIMIT 1] != null);
            Test.stopTest();
        }
    }
}