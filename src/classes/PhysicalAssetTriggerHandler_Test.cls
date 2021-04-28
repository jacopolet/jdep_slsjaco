/**
* @author        Abram Vixen Reyes
* @date          2.06.2018
* @description   Test class for PhysicalAssetTriggerHandler
* @revision(s)   2.21.2018 Paul Aguiling: KTS-1095 Added resetPhysicalAssetManualIndicatorPrevMain 
*                                         and resetPhysicalAssetManualIndicatorWTS test methods
*/
@isTest
public class PhysicalAssetTriggerHandler_Test {
	
    static PhysicalAsset__c pa;
    static PhysicalAsset__c pa2;
	static PhysicalAsset__c pa3;
    static Product2 prod;
	static Product2 optionProd;
    
    /**
    * @author        Abram Vixen Reyes
    * @date          2.06.2018           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
	*/
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.PhysicalAssetTrigger__c = true;
        upsert trg;
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          2.06.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
	*/
    static void setupTestData() {
        prod = TS_TestDataFactory.createProduct('Test','Coffee');
		prod.Description = 'Desc';
        prod.APTS_Vendor_Code__c = 'CMS';
		insert prod;
       	
        optionProd = TS_TestDataFactory.createProduct('OptionTest','Coffee');
        optionProd.Description = 'Desc Option';
        optionProd.APTS_Vendor_Code__c = 'WIT';
		insert optionProd;
        
        pa = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
								  Product__c = prod.Id,
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        
        pa2 = new PhysicalAsset__c(Name='Test2', 
                                   UniqueNumber__c='1234567-TestMachine2', 
                                   RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        insert pa2;
    }
        
     /**
    * @author        Abram Vixen Reyes
    * @date          2.06.2018           
    * @description   Test method to cover createHistoryRecord - update
    * @revision(s)
	*/
    static testMethod void createHistoryRecord() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            PhysicalAssetTriggerHandler.done = false;
            pa2.AssetStatus__c = 'Activated';
            pa2.UniqueNumber__c = 'Test Machine 123';
            update pa2;
            Test.stopTest();
        }
    }
    
     /**
    * @author        Abram Vixen Reyes
    * @date          2.06.2018           
    * @description   Test method to cover createHistoryRecord
    * @revision(s)
	*/
    static testMethod void validateIfHasChange() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            insert pa;
            
            PhysicalAsset__c newPA = pa.clone(true,true,false,false);
            pa.AssetStatus__c = 'Activated';
            
            Test.startTest();
            PhysicalAssetTriggerHandler path = new PhysicalAssetTriggerHandler();
            Boolean hasChanges = path.validateIfHasChange(newPA,pa);
            Test.stopTest();
            
            //Verify Results
            System.assert(hasChanges);
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          2.21.2018           
    * @description   Test method for resetPhysicalAssetManualIndicator Preventive Maintenance
    * @revision(s)
    */
    static testMethod void resetPhysicalAssetManualIndicatorPrevMain() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            pa.NextPreventiveMaintenanceDate__c = Date.today();
            insert pa;

            pa.LastPreventiveMaintenanceDate__c = Date.today();
            update pa;

            Test.startTest();
                System.assert(pa2.NextPreventiveMaintenanceDate__c == null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          2.21.2018           
    * @description   Test method for resetPhysicalAssetManualIndicator Water Filter Change
    * @revision(s)
    */
    static testMethod void resetPhysicalAssetManualIndicatorWTS() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            pa.NextWTSDate__c = Date.today();
            insert pa;

            pa.LastWTSDate__c = Date.today();
            update pa;

            Test.startTest();
                System.assert(pa2.NextWTSDate__c == null);
            Test.stopTest();
        }
    }
    
    /*with exception test*/
    static testMethod void testEx(){
        
        Test.startTest();
            PhysicalAssetTriggerHandler.hasException = true;
            setupTestData();
			pa.SerialNumber__c = '555';
            pa.NextWTSDate__c = Date.today();
            insert pa;

			pa3 = TS_TestDataFactory.createPhysicalAsset();
			pa3.ParentPhysicalAsset__c = pa.Id;
			pa3.Product__c = optionProd.Id;
			pa3.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get(TS_Constants.PA_RECTYPE_OPTION).getRecordTypeId();
			insert pa3;
            
            pa.LastWTSDate__c = Date.today();
			pa.SerialNumber__c = '1234';
            update pa;
            
            delete pa;
            undelete pa;
            System.assert(pa2.NextWTSDate__c == null);       
        Test.stopTest();
    }
}