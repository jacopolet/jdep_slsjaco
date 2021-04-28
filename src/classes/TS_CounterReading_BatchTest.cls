/*
* @author        Archi Delphinanto
* @date          14 March 2018          
* @description   Test class for TS_CounterReading_Batch
* @revision(s)
*/
@isTest
public class TS_CounterReading_BatchTest {



 public static void dataSetup(){
            BusinessHours  bs = [select id from BusinessHours where Name = 'Default'];
            Id bsId = bs.id;
        
            //Create product
            product2 prod = new product2();
            prod.Name = 'Counter Reading Product Test';
            //prod.APTS_Material_Type__c = 'ZSPR';
            insert prod;

            //create physical asset
            id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
            PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();            
            pa.RecordTypeId = rtpa;
           // pa.SoldTo__c = accounttest.Id;
            //pa.Machine_Care__c = 'Full Operating';
            pa.StartDate__c = date.today().addDays(-365);
            pa.EndDate__c = date.today().addDays(365);
            pa.TypeOfContract__c = 'Sales';
            pa.AssetStatus__c = 'Activated';
            pa.ActiveContract__c = true;
            pa.SalesOrganization__c = 'SAP_0333';
            pa.Product__c = prod.id;
            pa.CounterReading__c = 'Yes';
            pa.connected__c = 'No';
            insert pa;
            
            //create counter reading
            APTS_CounterReadingData__c cr = new APTS_CounterReadingData__c();
            cr.TS_Physical_Asset__c = pa.Id;
           // cr.Name = 'Counter Reading Test';
            //cr.APTS_CounterID__c = '123' ;
            cr.APTS_CounterSequence__c = 1;
            insert cr;
            
            //create country setting            
            Id rtCs = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Counter Reading Scheduler');
            CountrySetting__c testCS = TS_TestDataFactory.createCountrySettings ();
            testCS.RecordTypeId = rtCs;
            testCS.Country__c = 'SAP_0333';
            testCS.DefaultStartTime__c = 6;
            testCS.DefaultEndTime__c =  18;
            testCS.Number_SLA_day__c  = 11;
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


    private static testMethod void testrunCounterReadingbatch() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            dataSetup();                         
     
            Operating_Task__c op = new Operating_Task__c();
            op.Send_Email_Upon_Batch_Completion__c = true;
            op.Batch_Email__c = 'test@email.com';
            insert op;

            Test.startTest();
                TS_CounterReading_Batch crBatch = new TS_CounterReading_Batch(null);                                      
                ID batchprocessid = Database.executeBatch(crBatch);
                AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                                    FROM AsyncApexJob 
                                    WHERE ID =: batchprocessid ];
                System.assertNotEquals('0' , aaj.Id);
            Test.stopTest();   
        }   
    }
    
}