/**
* @author        Karen Hung
* @date          11.9.2018
* @description   Test Class for OperatingScheduleTriggerHandler
* @revision(s)   
*/
@isTest
private class OperatingScheduleTriggerHandler_Test {
    static OperatingSchedule__c opSched;
    static PhysicalAsset__c pAsset;
    static Id opsRecordType;
    static Id opsRecordType_daily;
    
    /*data prep*/
    @testSetup
    static void dataPrep(){
        opsRecordType = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c',Label.APTS_Weekly);
        opsRecordType_daily = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', TS_Constants.FREQUENCY_DAILY);

        List<Account> account_List = TS_TestDataFactory.createAccounts(1);
        database.insert(account_List);
        
        product2 pd = TS_TestDataFactory.createProductTest('ProductTest','ZSPR');
        database.insert(pd);
        
        Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('3471974109874',account_List[0].Id );
        
        Resource__c resource_obj = TS_TestDataFactory.createResourceTest('ResourceTest');
        Insert resource_obj;	
        
        Id recordType =  TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
        pAsset = TS_TestDataFactory.createPhysicalAssetTest(recordType, pd.Id,'SAP_0111', account_List[0].Id, accLocation.Id, 'building', 'floor', resource_obj.Id, 'Full Operating');
        database.insert(pAsset);
       
       
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(pd.Id,pricebookId);
        database.insert(pbEntrySTD);
        
        Pricebook2 Pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0111');
        database.insert(Pricebook);
        
        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(pd.Id,Pricebook.Id);
        database.insert(pbEntry);
        
        List <BusinessHours> businessList = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT);
        CountrySetting__c cs = new CountrySetting__c();
        cs.country__c = 'SAP_0111';   
        cs.Business_Hours__c = businessList[0].id;
        cs.RecordTypeId = rtCs;
        cs.Active__c = true;
        database.insert(cs);
        
    }
    
    /*test the trigger*/
    static testMethod void opSchedTriggerTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
                
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.OperatingScheduleTrigger__c = true;
        upsert trg; 
        
        System.runAs(u) {
            
            test.startTest();
           
            dataPrep();  
            List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
            List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
            opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
            opSched.Start_Date__c = TS_Constants.SYSTEM_START_DATE;
            opSched.OP_Business_Hours__c = businessHours_List[0].id;
            opSched.PhysicalAsset__c= pAsset.Id;
            opSched.recordTypeId = opsRecordType;
            
            operatingScheduleList.add(opSched);
            database.Insert(operatingScheduleList);            
            opSched.SM_1_Monday__c = '1';
            
            database.update(operatingScheduleList);
            
            database.delete(operatingScheduleList);
            
            database.undelete(operatingScheduleList);
            test.stopTest();
            system.assertEquals(1,operatingScheduleList.size());
        }
        
    }
    
    /*false trigger setting*/                 
    static testMethod void opSchedTriggerTest1(){
        User u1 = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        TriggerSettings__c trg1 = TriggerSettings__c.getOrgDefaults();
        trg1.OperatingScheduleTrigger__c = false;
        upsert trg1; 
        System.runAs(u1) {
            test.startTest();          
                dataPrep();  
                List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
                List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
                opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
                opSched.Start_Date__c = TS_Constants.SYSTEM_START_DATE;
                opSched.OP_Business_Hours__c = businessHours_List[0].id;
                opSched.PhysicalAsset__c= pAsset.Id;
                opSched.recordTypeId = opsRecordType;
                
                operatingScheduleList.add(opSched);
                database.Insert(operatingScheduleList);   
                /*for exception*/
                OperatingScheduleTriggerHandler handler = new OperatingScheduleTriggerHandler();
                handler.BeforeInsert(null);
                handler.BeforeUpdate(null, null, null, null);
            test.stopTest();
            system.assertEquals(1, operatingScheduleList.size());
        }
        
    }

    /*false trigger setting*/                 
    static testMethod void opSchedTriggerTest_validation(){
        User u1 = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        TriggerSettings__c trg1 = TriggerSettings__c.getOrgDefaults();
        trg1.OperatingScheduleTrigger__c = false;
        upsert trg1; 
        System.runAs(u1) {
            test.startTest();          
                dataPrep();  
                List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
                List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
                opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
                opSched.Start_Date__c = TS_Constants.SYSTEM_START_DATE.addDays(7);
                opSched.OP_Business_Hours__c = businessHours_List[0].id;
                opSched.PhysicalAsset__c= pAsset.Id;
                opSched.recordTypeId = opsRecordType_daily;
                
                operatingScheduleList.add(opSched);
                database.insert(operatingScheduleList);   
            test.stopTest();
            system.assertEquals(1, operatingScheduleList.size());
        }
        
    }
    
    /*test the trigger*/
    static testMethod void validateScheduleTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
                
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.OperatingScheduleTrigger__c = true;
        upsert trg; 
        
        System.runAs(u) {
            
            test.startTest();
           
            dataPrep();  
            List<OperatingSchedule__c> operatingScheduleList = new List<OperatingSchedule__c>();  
            List <BusinessHours> businessHours_List = [SELECT Id, Name FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
            opSched = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
            opSched.Start_Date__c = TS_Constants.SYSTEM_START_DATE;
            opSched.OP_Business_Hours__c = businessHours_List[0].id;
            opSched.PhysicalAsset__c= pAsset.Id;
            opSched.recordTypeId = opsRecordType;
            
            operatingScheduleList.add(opSched);
           
            database.Insert(operatingScheduleList);
            
            String opsRecordType_regular = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
            OperatingSchedule__c ops2 = TS_TestDataFactory.createOperatingScheduleTest(false, false, 'AM', '0', '0', '0', 'PM', '0', '0');
            ops2.Start_Date__c = TS_Constants.SYSTEM_START_DATE;
            ops2.OP_Business_Hours__c = businessHours_List[0].id;
            ops2.PhysicalAsset__c= pAsset.Id;
            ops2.recordTypeId = opsRecordType_regular;
            ops2.Active__c = false;
            ops2.Schedule_Type__c = TS_Constants.REGULAR;
            insert ops2;
            
            database.delete(operatingScheduleList);
            
            database.undelete(operatingScheduleList);
            test.stopTest();
            system.assertEquals(1,operatingScheduleList.size());
        }
        
    }
}