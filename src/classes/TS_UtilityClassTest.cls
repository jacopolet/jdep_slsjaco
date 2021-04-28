/**
* @author        Adrian Reyes
* @date          01.11.2018
* @description   Test class for TS_UtilityClass
* @revision(s)
*/

@isTest
public class TS_UtilityClassTest {
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover populateIntLogValues
    * @revision(s)
	*/
    static testMethod void testPopulateIntLogValues() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            Integration_Log__c integrationLog = TS_UtilityClass.populateIntLogValues(INT_Constants.CLICK_GETAVAILABLESLOTS_PERFORMANCE, null, null, null);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(INT_Constants.PAUSED, integrationLog.Integration_Status__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover getRecordTypeIdByName
    * @revision(s)
	*/
    static testMethod void testGetRecordTypeIdByName() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            Id regtaskRecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_REGTASK);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, regtaskRecordTypeId);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover getRecordTypeNameById
    * @revision(s)
	*/
    static testMethod void testGetRecordTypeNameById() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            Id customerCareRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType =: Label.TS_Obj_API_Name_Case AND DeveloperName = 'CustomerCare' LIMIT 1].Id;
            String customerCareRecordTypeName = TS_UtilityClass.getRecordTypeNameById(Label.TS_Obj_API_Name_Case, customerCareRecordTypeId);
            Test.stopTest();
            
            //Verify Results
            System.assertEquals('Customer Care', customerCareRecordTypeName);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover getWorkingDate
    * @revision(s)
	*/
    static testMethod void testGetWorkingDate() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            //Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name = 'BE - Service Standard' LIMIT 1].Id;
            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name = 'BE - Default' LIMIT 1].Id;
            Date oldDate1 = Date.newInstance(2018, 1, 6);
            Date newDate1 = TS_UtilityClass.getWorkingDate(businessHoursId, oldDate1);
            Date oldDate2 = Date.newInstance(2018, 1, 7);
            Date newDate2 = TS_UtilityClass.getWorkingDate(businessHoursId, oldDate2);
            Test.stopTest();
            
            //Verify Results
            System.assertNotEquals(null, newDate1.format());
            System.assertNotEquals(null, newDate2.format());
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover getBusinessHours
    * @revision(s)
	*/
    static testMethod void testGetBusinessHours() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            //Map<String,Id> businessHoursMap = TS_UtilityClass.getBusinessHours(new List<String>{'BE - Service Standard'});
            Map<String,Id> businessHoursMap = TS_UtilityClass.getBusinessHours(new List<String>{'BE - Default'});
            Test.stopTest();
            
            //Verify Results
            //System.assertNotEquals(null, businessHoursMap.get('BE - Service Standard'));
            System.assertNotEquals(null, businessHoursMap.get('BE - Default'));
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover getReadableDay
    * @revision(s)
	*/
    static testMethod void testGetReadableDay() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            String readableDay = TS_UtilityClass.getReadableDay(Date.newInstance(2018, 1, 11));
            Test.stopTest();
            
            //Verify Results
            System.assertEquals('Thursday', readableDay);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          01.11.2018           
    * @description   Test method to cover convertToFile
    * @revision(s)
	*/
    static testMethod void testConvertToFile() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            ContentVersion contentVersion = TS_UtilityClass.convertToFile(Blob.valueOf('test'), 'test', 'test');
            Test.stopTest();
            
            //Verify Results
            System.assertEquals('S', contentVersion.ContentLocation);
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.07.2018           
    * @description   Test method to cover getBusinessHoursLatestTime
    * @revision(s)
    */
    static testMethod void testGetBusinessHoursLatestTime() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

            CountrySetting__c countrySetting = new CountrySetting__c(Name = 'Test BHRs', 
                RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Default Business Hours'),
                Country__c = 'SAP_0333', Business_Hours__c = bh.Id, Active__c = true);
            insert countrySetting; 

            CountrySetting__c countrySet = [SELECT Business_Hours__r.MondayEndTime,
                                                   Business_Hours__r.TuesdayEndTime,
                                                   Business_Hours__r.WednesdayEndTime,
                                                   Business_Hours__r.ThursdayEndTime,
                                                   Business_Hours__r.FridayEndTime,
                                                   Business_Hours__r.SaturdayEndTime,
                                                   Business_Hours__r.SundayEndTime
                                            FROM  CountrySetting__c
                                            WHERE Id = :countrySetting.Id
                                            AND Active__c = true
                                            LIMIT 1];            

            Test.startTest();
                Date mondDate = date.parse('3/5/2018');

                Time newTime = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, mondDate);
                System.assert(newTime != null);

                Date tueDate = date.parse('3/6/2018');

                Time newTime2 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, tueDate);
                System.assert(newTime2 != null);

                Date wedDate = date.parse('3/7/2018');

                Time newTime3 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, wedDate);
                System.assert(newTime3 != null);

                Date thursDate = date.parse('3/8/2018');

                Time newTime4 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, thursDate);
                System.assert(newTime4 != null);

                Date friDate = date.parse('3/9/2018');

                Time newTime5 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, friDate);
                System.assert(newTime5 != null);

                Date satDate = date.parse('3/10/2018');

                Time newTime6 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, satDate);
                System.assert(newTime6 != null);

                Date sunDate = date.parse('3/11/2018');

                Time newTime7 = TS_UtilityClass.getBusinessHoursLatestTime(countrySet, sunDate);
                System.assert(newTime7 != null);
            Test.stopTest();
        }
    }

     /**
    * @author        Archi Delphinanto
    * @date          2 May 2018           
    * @description   Test method for isSObjectAccessible, isSObjectQueryable,isSObjectCreateable
    * @revision(s)
    */
    static testMethod void testObjectCRUD() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {

             Test.startTest();
             Boolean isTestOK = TS_UtilityClass.isSObjectAccessible(new String[] {'Case'}) ;
             System.assertEquals(isTestOK, True);
             isTestOK = TS_UtilityClass.isSObjectAccessible(new String[] {'CaseXXXX'}) ;
             System.assertEquals(isTestOK, False);
             isTestOK = TS_UtilityClass.isSObjectQueryable(new String[] {'Case'}) ;
             System.assertEquals(isTestOK, True);
             isTestOK = TS_UtilityClass.isSObjectQueryable(new String[] {'CaseXXXX'}) ;
             System.assertEquals(isTestOK, False);
             isTestOK = TS_UtilityClass.isSObjectCreateable(new String[] {'Case'}) ;
             System.assertEquals(isTestOK, True);
             isTestOK = TS_UtilityClass.isSObjectCreateable(new String[] {'CaseXXXX'}) ;
             System.assertEquals(isTestOK, False);
             isTestOK = TS_UtilityClass.isSObjectUpdateable(new String[] {'Case'}) ;
             System.assertEquals(isTestOK, True);
             isTestOK = TS_UtilityClass.isSObjectUpdateable(new String[] {'CaseXXXX'}) ;
             System.assertEquals(isTestOK, False);
             isTestOK = TS_UtilityClass.isSObjectDeletable(new String[] {'Case'}) ;
             System.assertEquals(isTestOK, True);
             isTestOK = TS_UtilityClass.isSObjectDeletable(new String[] {'CaseXXXX'}) ;
             System.assertEquals(isTestOK, False);
             Test.stopTest();

        }

     }

    /**
    * @author        Paul Aguiling
    * @date          7.02.2018
    * @description   Test method for resendTaskIntegLog
    * @revision(s)
    */
    static testMethod void testResendTaskIntegLog() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {

            Account acc = new Account(Name='Account', Phone='+31302979111');
            insert acc;

            Contact con = TS_TestDataFactory.createContact();  
            con.Preferred_Language__c = 'SAP_EN';
            insert con;

            Apttus_Config2__AccountLocation__c al = TS_TestDataFactory.createAccountLocation(acc.Id);     
            al.ApprovalPreventiveMaintenanceWTS__c = true;
            al.Account_Location_Status__c = 'ACTIVE';
            al.Apttus_Config2__IsDefault__c = true;
            al.Mini_Sales_Organization__c = 'SAP_0111';
            insert al;

            Case c = TS_TestDataFactory.createFieldServiceCase();
            c.ContactId = con.Id;
            c.Status = Label.TS_Status_InProgress;
            insert c;
            
            WorkOrder wo = TS_TestDataFactory.createWorkOrder();
            wo.CaseId = c.Id;
            wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
            wo.ContactId = con.Id;
            insert wo;

            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);   
            woli.WorkOrderType__c = 'S10';      
            woli.Case__c = c.Id;
            woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
            woli.StartDate__c = Datetime.now().addhours(-1);
            woli.EndDate__c = DateTime.now();
            woli.IsFirstTask__c = true;
            woli.CoffeeRunsUponArrival__c = true;
            woli.Status = Label.TS_Status_InProgress;
            woli.AccountLocation__c = al.Id;
            insert woli;

            List<SObject> newAccountList = new List<SObject>();
            newAccountList.add(al);

            al.ApprovalPreventiveMaintenanceWTS__c = false;
            al.Apttus_Config2__PostalCode__c = '1003';
            update al;

            Map<Id, SObject> oldAccountMap = new Map<Id, SObject>();
            oldAccountMap.put(al.Id, al);

            Test.startTest();
                TS_UtilityClass.resendTaskIntegLog('Apttus_Config2__AccountLocation__c', 'AccountLocation__c', newAccountList, oldAccountMap);
                System.assert([SELECT Id FROM WorkOrderLineItem WHERE AccountLocation__c = :al.Id].Id != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Abram Reyes
    * @date          1.10.2018           
    * @description   Test method to cover countrySAPCodeUtility and queueNameIdMapUtility
    * @revision(s)
    */
    static testMethod void test_SAPCodeQueue() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            Test.startTest();
            Map<String, String> countrySAP = TS_UtilityClass.countrySAPCodeUtility();
            Map<String, String> queueNameId = TS_UtilityClass.queueNameIdMapUtility();
            system.assert(countrySAP != null);
            Test.stopTest();
        }
    }
    
     /**
    * @author        Karen Hung
    * @date          10.03.2021           
    * @description   Test method to cover createPriceBookEntryMap
    * @revision(s)
    */
    static testMethod void test_createPriceBookEntryMap() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            //Create product
            Product2 prod = new Product2();
            prod.Name = 'Operating Sched Product Test';
            prod.APTS_Material_Type__c = 'ZSPR';
            insert prod;
            
            List<Account> account_List = TS_TestDataFactory.createAccounts(1);
            insert account_List;

            Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
        	accLocation.AverageRoutePrep__c = 1;
        	accLocation.MTTTWithinSite__c = 2;
            accLocation.MTTOLocationSpecific__c = 1;
            accLocation.Mini_Sales_Organization__c = 'SAP_0111';
            insert accLocation;
            
            id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');

            PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
            pa.RecordTypeId = rtpa;
            pa.Machine_Care__c = 'Full Operating';
            pa.StartDate__c = date.today().addDays(-365);
            pa.EndDate__c = date.today().addDays(365);
            pa.TypeOfContract__c = 'Sales';
            pa.AssetStatus__c = 'Activated';
            pa.ActiveContract__c = true;
            pa.SalesOrganization__c = 'SAP_0111';
            pa.Product__c = prod.id;
            pa.UniqueNumber__c = '123ABC';
            pa.AccountLocation__c = accLocation.Id;
            insert pa;
            
            //Create sales org pricebook
            Pricebook2 orgPB = new Pricebook2();
            orgPB.name = 'NL Price Book';
            orgPB.IsActive = true;
            orgPB.Sales_Organization__c = 'SAP_0111';
            insert orgPB;
            
            //Create Pricebookentry with standard and sales org pricebook
            PricebookEntry pbe = new PricebookEntry();
            pbe.product2id = prod.id;
            pbe.pricebook2id = Test.getStandardPricebookId();
            pbe.UnitPrice = 1;
            pbe.IsActive = true;
            pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(Test.getStandardPricebookId());
            insert pbe;
            
            pbe = new pricebookentry();
            pbe.product2id = prod.id;
            pbe.pricebook2id = orgPB.id;
            pbe.UnitPrice = 11;
            pbe.IsActive = true;
            pbe.TS_Load_Id__c = String.valueOf(prod.id) + String.valueOf(orgPB.id);
        	pbe.MeanTimeToOperateC__c = 1;
            pbe.MeanTimeToOperateLM__c = 1;
        	pbe.MeanTimeToOperateSM__c = 1;
            pbe.MTTO_MCO_PM__c = 1;
            pbe.MTTO_MCO_PM_Bucket__c = 'A';
            pbe.MTTO_MCO_Waterfilter__c = 2;
            insert pbe;
            
            OperatingSchedule__c testOS = TS_TestDataFactory.createOperatingSchedule();
            testOS.PhysicalAsset__c = pa.id;
            testOS.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
            testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
            testOS.Interval_in_Weeks__c = '1';
            testOS.LM_1_Monday__c = '1';
            testOS.SM_1_Monday__c = '1';
            testOS.SM_1_Friday__c = 'PM';
            testOS.SM_1_Thursday__c = '1';
            testOS.SM_2_Thursday__c = '1';
            testOS.SM_1_Wednesday__c = 'PM';
            Insert testOS;
            
            Test.startTest();
            List<OperatingSchedule__c> schedList = new List<OperatingSchedule__c>();
            OperatingSchedule__c sched = [SELECT ID, PhysicalAsset__r.Product__c,PhysicalAsset__c,PhysicalAsset__r.SalesOrganization__c FROM OperatingSchedule__c][0];
            schedList.add(sched);
            Map<String, PricebookEntry> pbeMap = TS_UtilityClass.createPriceBookEntryMap(schedList);
            String operatingBucket = TS_UtilityClass.operatingBucket('PW', pbe);
            TS_UtilityClass.recalculatePBEBuckets();
            system.debug(testOs.PhysicalAsset__r.Product__c + testOs.PhysicalAsset__r.SalesOrganization__c);
            system.assert(pbeMap.size() == 1);
            Test.stopTest();
        }
    }
}