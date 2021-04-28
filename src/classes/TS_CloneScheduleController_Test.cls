/*Created by: Karen Hung 11/22/2018
 * test class for TS_CloneScheduleController
 */
 @isTest
public class TS_CloneScheduleController_Test {
	static OperatingSchedule__c opSched;
    static PhysicalAsset__c pAsset;
    static PhysicalAsset__C pAsset2;
    static Id opsRecordType;
    static Apttus_Config2__AccountLocation__c accLocation;
    
    /*data prep*/
    @testSetup
    static void dataPrep(){
        opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c',Label.APTS_Weekly);

        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        database.insert(account_List);
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        database.insert(pd);
        
        accLocation = new Apttus_Config2__AccountLocation__c();
        accLocation.Apttus_Config2__AccountId__c = account_List[0].id;
        insert accLocation;
        
        Resource__c resource_obj = TS_TestDataFactory.createResourceTest('ResourceTest');
        Insert resource_obj;	
        
        String recordType = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(TS_Constants.PA_RECTYPE_MACHINE).getRecordTypeId(); 
        pAsset = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        database.insert(pAsset);
        
        pAsset2 = new PhysicalAsset__c();
        pAsset2.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(TS_Constants.PA_RECTYPE_MACHINE).getRecordTypeId();
        pAsset2.Product__c = pd.Id;
        pAsset2.AccountLocation__c = accLocation.id;
        pAsset2.SalesOrganization__c = 'SAP_0333';
        pAsset2.SoldTo__c = account_List[0].Id;
        pAsset2.Machine_Care__c = 'Full Operating';
        pAsset2.AssetStatus__c = 'Activated';
        //TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0333', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        database.insert(pAsset2);
       
       
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        database.insert(pbEntrySTD);
        
        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0333');
        database.insert(Pricebook);
        
        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        database.insert(pbEntry);

        
    }
    
    /*test the trigger*/
    static testMethod void opSchedTriggerTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            
            test.startTest();
           
            dataPrep();
            List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
            List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
            opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
            opSched.Start_Date__c = Date.newInstance(2018,09,07);//Date.newInstance(2018,08,06);
            opSched.PhysicalAsset__c= pAsset.Id;
            opSched.recordTypeId = opsRecordType;
            opSched.Account_Location__c = accLocation.Id;
            opSched.Interval_in_Weeks__c = '1';
            operatingScheduleList.add(opSched);
            database.Insert(operatingScheduleList);   

            OperatingSchedule__c opSched2 =  new OperatingSchedule__c();
            opSched2.Start_Date__c = Date.newInstance(2018,09,07);
            opSched2.Active__c=true;
            opSched2.Interval_in_Weeks__c = '1';
            opSched2.PhysicalAsset__c = pAsset2.id;
            insert opSched2;

            TS_CloneScheduleController.getPAs(operatingScheduleList[0].id); 
            List<Object> obList = TS_CloneScheduleController.getPAs(operatingScheduleList[0].id);
            String str = JSON.serialize(obList);
			TS_CloneScheduleController.createOpSched(str, operatingScheduleList[0].id);
            
            test.stopTest();
            system.assertEquals(1,operatingScheduleList.size());
        }
        
    }

}