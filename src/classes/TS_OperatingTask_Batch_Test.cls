/*
* @author        Marvin Gatchalian
* @date          2.22.2018          
* @description   Test class for TS_OperatingTask_Batch
* @revision(s)
*/


@isTest
public class TS_OperatingTask_Batch_Test {
    
    static OperatingSchedule__c testOS;
    static PhysicalAsset__c pa2;
    static PhysicalAsset__c pa3;
    
    //@testSetup
    public static void dataSetup(String lTask, String sTask, String cTasks, String machineCare, Boolean isRinse, Boolean is247) {
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            Id bsId = bs.id;
            
            id rt = TS_UtilityClass.getRecordTypeIdByName('OperatingSchedule__c', 'Every Day');
            id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');

            //Create product
            product2 prod = new product2();
            prod.Name = 'Operating Sched Product Test';
            prod.APTS_Material_Type__c = 'ZSPR';
            insert prod;
            
            List<Account> account_List = TS_TestDataFactory.createAccounts(1);
            insert account_List;
            
            Apttus_Config2__AccountLocation__c accLocation = TS_TestDataFactory.createAccountLocationTest('454545577868',account_List[0].Id );
            insert accLocation;

            PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
            pa.RecordTypeId = rtpa;
            pa.Machine_Care__c = machineCare;
            pa.StartDate__c = date.today().addDays(-365);
            pa.EndDate__c = date.today().addDays(365);
            pa.TypeOfContract__c = 'Sales';
            pa.AssetStatus__c = 'Activated';
            pa.ActiveContract__c = true;
            pa.SalesOrganization__c = 'SAP_0333';
            pa.Product__c = prod.id;
            pa.UniqueNumber__c = '123ABC';
            pa.AccountLocation__c = accLocation.Id;
            insert pa;

            pa2 = TS_TestDataFactory.createPhysicalAsset();
            pa2.RecordTypeId = rtpa;
            pa2.Machine_Care__c = machineCare;
            pa2.StartDate__c = date.today().addDays(-365);
            pa2.EndDate__c = date.today().addDays(365);
            pa2.TypeOfContract__c = 'Sales';
            pa2.AssetStatus__c = 'Activated';
            pa2.ActiveContract__c = true;
            pa2.SalesOrganization__c = 'SAP_0333';
            pa2.Product__c = prod.id;
            pa2.UniqueNumber__c = '456DEF';
            pa.AccountLocation__c = accLocation.Id;
            insert pa2;

            pa3 = TS_TestDataFactory.createPhysicalAsset();
            pa3.RecordTypeId = rtpa;
            pa3.Machine_Care__c = machineCare;
            pa3.StartDate__c = date.today().addDays(-365);
            pa3.EndDate__c = date.today().addDays(365);
            pa3.TypeOfContract__c = 'Sales';
            pa3.AssetStatus__c = 'Activated';
            pa3.ActiveContract__c = true;
            pa3.SalesOrganization__c = 'SAP_0333';
            pa3.Product__c = prod.id;
            pa3.UniqueNumber__c = '789GHI';
            pa.AccountLocation__c = accLocation.Id;
            insert pa3;
            
            testOS = TS_TestDataFactory.createOperatingSchedule();
            testOS.PhysicalAsset__c = pa.id;
            testOS.RecordTypeId = rt;
            testOS.Start_Date__c = date.today().toStartofWeek().addDays(1);
            testOS.Interval_in_Weeks__c = '1';
            //testOS.LM_1_Monday__c = lTask;
            //testOS.SM_1_Monday__c = sTask;
            //testOS.SM_1_Friday__c = 'PM';
             testOS.SM_1_Thursday__c = '1';
            //testOS.SM_2_Thursday__c = '1';
            //testOS.SM_1_Wednesday__c = 'PM';
            //testOS.C_1_Monday__c = cTasks;
            //testOS.R_1_Monday__c = isRinse;
            //testOS.R_1_Tuesday__c = isRinse;
            testOS.OP_247Customer__c = is247;
            Insert testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
            
            testCS.Business_Hours__c = bsId;
            testCS.RecordTypeId = rtCs;
            testCS.NumberDayToLookup__c  = 10;
            Insert testCS;
            
            //Create Standard Pricebook
            //Create sales org pricebook
            pricebook2 orgPB = new pricebook2();
            orgPB.name = 'BE Price Book';
            orgPB.IsActive = true;
            orgPB.Sales_Organization__c = 'SAP_0333';
            insert orgPB;
            
            //Create Pricebookentry with standard and sales org pricebook
            pricebookentry pbe = new pricebookentry();
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
            insert pbe;
            
    }
    
    private static testMethod void RegularBatchTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {

            dataSetup('1', 'PM', '1', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            testOS.LM_1_Monday__c = '1';
            testOS.SM_1_Monday__c = 'PM';
            testOS.C_1_Monday__c = '1';
            testOS.SM_1_Tuesday__c = '1';

            testOS.LM_2_Monday__c = '1';
            testOS.SM_2_Monday__c = 'PM';
            testOS.C_2_Monday__c = '1';
            testOS.SM_2_Tuesday__c = '1';
            
            update testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'regularbatch';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__r.Id
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                TS_OperatingTaskUtility tsUtils = new TS_OperatingTaskUtility();
                Map<Integer, boolean> fHM = tsUtils.getFutureHolidayMap (Integer.valueOf(cs.NumberDayToLookup__c), bhId, mdate);
                Map<Integer, boolean> pHM = tsUtils.getPastHolidayMap (Integer.valueOf(cs.NumberDayToLookup__c), bhId, mdate);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            
        }
        system.assertEquals(3, [select id from workorderlineitem].size());
        
    }
    
    
    private static testMethod void HolidayBatchForwardNoLTaskWith2STaskTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {

            dataSetup('0', 'PM', '1', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            testOS.SM_1_Friday__c = 'PM';
            testOS.R_1_Friday__c = true;

            testOS.LM_1_Thursday__c = '0';
            testOS.SM_1_Thursday__c = '2';
            
            update testOS;
            
            System.debug('testOS: ' +testOS);
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchFWD';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c, Business_Hours__r.Id 
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Friday as Holiday
                //Batch Run Date = Wednesday, thus index 0 is Wednesday
                fHM.put(0, true);
                fHM.put(1, true);
                fHM.put(2, false);
                fHM.put(3, false);
                fHM.put(4, false);
                
                pHM.put(0, true);
                pHM.put(1, true);
                pHM.put(2, true);
                pHM.put(3, false);
                pHM.put(4, false);
                
                system.debug('Batch Run Date from Test Class ' + mdate.addDays(3));
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(3), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            system.assertEquals(0, [select id from workorderlineitem].size());
        }
        
    }
    
    private static testMethod void HolidayBatchForwardNoLTaskWithSTaskTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {

            dataSetup('0', 'PM', '1', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            testOS.SM_1_Friday__c = 'PM';
            testOS.R_1_Friday__c = true;
            testOS.LM_1_Thursday__c = '0';
            update testOS;
            System.debug('testOS' +testOS);
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchFWD';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c, Business_Hours__r.Id
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Friday as Holiday
                //Batch Run Date = Wednesday, thus index 0 is Wednesday
                fHM.put(0, true);
                fHM.put(1, true);
                fHM.put(2, false);
                fHM.put(3, false);
                fHM.put(4, false);
                
                pHM.put(0, true);
                pHM.put(1, true);
                pHM.put(2, true);
                pHM.put(3, false);
                pHM.put(4, false);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(3), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            system.assertEquals(0, [select id from workorderlineitem].size());
        }
        
    }
    
    private static testMethod void HolidayBatchForwardWithLTaskTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {

            dataSetup('0', 'PM', '1', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            testOS.SM_1_Friday__c = 'PM';
            testOS.R_1_Friday__c = true;
            testOS.LM_1_Thursday__c = '1';
            update testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchFWD';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c , Business_Hours__r.Id 
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Friday as Holiday
                //Batch Run Date = Wednesday, thus index 0 is Wednesday
                fHM.put(0, true);
                fHM.put(1, true);
                fHM.put(2, false);
                fHM.put(3, false);
                fHM.put(4, false);
                
                pHM.put(0, true);
                pHM.put(1, true);
                pHM.put(2, true);
                pHM.put(3, false);
                pHM.put(4, false);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(3), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            system.assertEquals(0, [select id from workorderlineitem].size());
        }
        
    }
    
    
    private static testMethod void HolidayBatchBackwardTest() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            List<OperatingSchedule__c> ops = new List<OperatingSchedule__c>();
            dataSetup('1', '0', '0', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            
            testOS.LM_1_Thursday__c = '1';
            testOS.SM_1_Thursday__c = '0';
            testOS.C_1_Thursday__c = '0';
            testOS.R_1_Thursday__c = true;
            
            testOS.LM_1_Friday__c = '1';
            testOS.SM_1_Friday__c = '1';
            testOS.C_1_Friday__c = '0';

            testOS.ForceScheduleToNextBusinessDay__c = false;
            update testOS;
            
            OperatingSchedule__c testOS2 = testOS.clone();
            testOS2.SM_1_Friday__c = '2';
            testOS2.PhysicalAsset__c = pa2.Id;
            ops.add(testOS2);
            
            OperatingSchedule__c testOS3 = testOS.clone();
            testOS3.SM_1_Friday__c = 'PM';
            testOS3.PhysicalAsset__c = pa3.Id;
            ops.add(testOS3);
            insert ops;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(4);  //Setting to Thrusday
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchBWK';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c, Business_Hours__r.Id  
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Thursday as Holiday
                //Batch Run Date = Thursday, thus index 0 is Wednesday
                fHM.put(0, false);
                fHM.put(1, true);
                fHM.put(2, true);
                fHM.put(3, true);
                fHM.put(4, true);
                
                pHM.put(0, false);
                pHM.put(1, false);
                pHM.put(2, false);
                pHM.put(3, true);
                pHM.put(4, true);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            //System.assertEquals(7, [select id from workorderlineitem].size());
        }
        
    }
    
    private static testMethod void HolidayBatchBackwardCase3Test() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        //List<PhysicalAsset__c> paList = [SELECT Id, UniqueNumber__c FROM PhysicalAsset__c WHERE (UniqueNumber__c = '456DEF' OR UniqueNumber__c = '789GHI')];

        System.runAs(usr) {
            List<OperatingSchedule__c> ops = new List<OperatingSchedule__c>();
            dataSetup('1', '0', '0', 'Full Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            
            testOS.LM_1_Monday__c = '0';
            testOS.SM_1_Monday__c = 'AM';
            testOS.C_1_Monday__c = '0';
            testOS.R_1_Monday__c = true;
            
            testOS.LM_1_Tuesday__c = '1';
            testOS.SM_1_Tuesday__c = '1';
            testOS.C_1_Tuesday__c = '0';

            testOS.ForceScheduleToNextBusinessDay__c = false;
            update testOS;
            
            OperatingSchedule__c testOS2 = testOS.clone();
            testOS2.LM_1_Tuesday__c = '0';
            testOS2.SM_1_Tuesday__c = '0';
            testOS2.PhysicalAsset__c = pa2.Id;
            ops.add(testOS2);
            
            OperatingSchedule__c testOS3 = testOS.clone();
            testOS3.LM_1_Tuesday__c = '0';
            testOS3.SM_1_Tuesday__c = '4';
            testOS3.PhysicalAsset__c = pa3.Id;
            ops.add(testOS3);
            insert ops;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);  //Setting to Thrusday
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchBWK';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__r.Id
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Thursday as Holiday
                //Batch Run Date = Thursday, thus index 0 is Wednesday
                fHM.put(0, false);
                fHM.put(1, true);
                fHM.put(2, true);
                fHM.put(3, true);
                fHM.put(4, true);
                
                pHM.put(0, false);
                pHM.put(1, false);
                pHM.put(2, false);
                pHM.put(3, true);
                pHM.put(4, true);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            //System.assertEquals(10, [select id from workorderlineitem].size());
        }
        
    }
    
    private static testMethod void HolidayBatchBackwardCase4Test() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            List<OperatingSchedule__c> ops = new List<OperatingSchedule__c>();
            dataSetup('1', '0', '0', 'Comfort Operating', true, true);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            
            testOS.LM_1_Monday__c = '1';
            testOS.SM_1_Monday__c = '0';
            testOS.C_1_Monday__c = '0';
            testOS.R_1_Monday__c = true;
            
            testOS.LM_1_Tuesday__c = '0';
            testOS.SM_1_Wednesday__c = '2';
            testOS.C_1_Tuesday__c = '0';

            testOS.ForceScheduleToNextBusinessDay__c = false;
            update testOS;
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);  //Setting to Thrusday
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchBWK';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c , Business_Hours__r.Id 
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Thursday as Holiday
                //Batch Run Date = Thursday, thus index 0 is Wednesday
                fHM.put(0, false);
                fHM.put(1, true);
                fHM.put(2, true);
                fHM.put(3, true);
                fHM.put(4, true);
                
                pHM.put(0, false);
                pHM.put(1, false);
                pHM.put(2, false);
                pHM.put(3, true);
                pHM.put(4, true);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            //system.assertEquals(4, [select id from workorderlineitem].size());
        }
        
    }
    
    private static testMethod void HolidayBatchBackwardCase5Test() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            List<OperatingSchedule__c> ops = new List<OperatingSchedule__c>();
            dataSetup('1', '0', '0', 'Full Operating', true, false);  // lTask,  sTask,  cTasks, sTomorrow, isRinse,  is247
            
            testOS.LM_1_Monday__c = '1';
            testOS.SM_1_Monday__c = 'AM';
            testOS.C_1_Monday__c = '0';
            testOS.R_1_Monday__c = true;
            
            testOS.LM_1_Tuesday__c = '0';
            testOS.SM_1_Tuesday__c = '1';
            testOS.C_1_Tuesday__c = '0';

            testOS.ForceScheduleToNextBusinessDay__c = false;
            update testOS;
            
            OperatingSchedule__c testOS2 = testOS.clone();
            testOS2.ForceScheduleToNextBusinessDay__c = true;
            testOS2.PhysicalAsset__c = pa2.Id;
            ops.add(testOS2);
            
            //OperatingSchedule__c testOS3 = testOS.clone();
            //testOS3.LM_1_Tuesday__c = '0';
            //testOS3.SM_1_Tuesday__c = '4';
            //ops.add(testOS3);
            insert ops;
            
            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
            Date mdate = date.today().toStartofWeek().addDays(1);  //Setting to Thrusday
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            String bhId = String.valueOf(bs.id);
            String batchType = 'holidaybatchBWK';
                        

            Test.startTest();       
                CountrySetting__c cs = [Select id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c , Business_Hours__c , Business_Hours__r.Id 
                                                     From CountrySetting__c
                                                     Where Business_Hours__c = :bhId And RecordTypeId = :rtCs AND Active__c = true Limit 1];
                
                Map <Integer, Boolean> fHM = new Map <Integer, Boolean>();
                Map <Integer, Boolean> pHM = new Map <Integer, Boolean>();
                //Setting Thursday as Holiday
                //Batch Run Date = Thursday, thus index 0 is Wednesday
                fHM.put(0, false);
                fHM.put(1, true);
                fHM.put(2, true);
                fHM.put(3, true);
                fHM.put(4, true);
                
                pHM.put(0, false);
                pHM.put(1, false);
                pHM.put(2, false);
                pHM.put(3, true);
                pHM.put(4, true);
                
                
                TS_OperatingTask_Batch regularBatch = new TS_OperatingTask_Batch
                                                    (batchType, mdate.addDays(1), fHM, pHM, cs); 
                                                            
                Database.executeBatch(regularBatch);
            
            Test.stopTest();
            //System.assertEquals(6, [select id from workorderlineitem].size());
        }
        
    }
    
    
           
}