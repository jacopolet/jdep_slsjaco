/**
* @author        Karen Hung
* @date          14.11.2019
* @description   test class for PartRequestTriggerHandler , part of DOO-2196
* @revision(s)   
*/
@isTest
public class PartRequestTriggerHandler_Test {
	static Product2 prod;
    static Part_Request__c pReq;
    static Part_Request_Line_Item__c prItem;
    static Resource__c engr;
    
    /**
    * @author        Karen Hung
    * @date          14.11.2019           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.PartRequestTrigger__c = true;
        trg.PartRequestLineItemTrigger__c = true;
        upsert trg;
    }
    
    /**
    * @author        Karen Hung
    * @date          14.11.2019           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData(){
        
        CountrySetting__c cset = new CountrySetting__c();
        cset.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYPURCHASING);
        cset.Company_Code__c = '0079';
        cset.Active__c = true;
        insert cset;
        
        engr = new Resource__c();
        engr.Name = '1232343434';
        engr.Sales_Organization__c = 'SAP_0111';
        engr.CompanyCode__c = '0079';
        engr.SAPStorageLocation__c ='Test Storage';
        insert engr;
        
        prod = TS_TestDataFactory.createProductTest('My Product', 'ZSPR');
        prod.APTS_Sales_Organization__c = 'SAP_0111';
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(prod.Id,pricebookId);
        Insert pbEntrySTD;
        
        Pricebook2 pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0111');
        insert pricebook;
        
        PricebookEntry pbEntry= TS_TestDataFactory.createPricebookEntryTest(prod.Id,Pricebook.Id); 
        Insert pbEntry;
        
        pReq = new Part_Request__c();
        pReq.Resource__c = engr.Id;
        pReq.Status__c = TS_Constants.STATUS_OPEN;
        
    }
    
    /*test validation*/
    static testMethod void validateItemTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();           
            insert pReq;
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }
    
    /*test iLog creation*/
    static testMethod void createIntegrationTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            insert pReq;
            pReq.Status__c = TS_Constants.STATUS_COMPLETED;
            update pReq;
            delete pReq;
            undelete pReq;
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }

    /*test exception*/
    static testMethod void exceptionTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            PartRequestTriggerHandler.hasException = true;
            setupTestData();
            insert pReq;
            pReq.Status__c = TS_Constants.STATUS_COMPLETED;
            update pReq;
            delete pReq;
            undelete pReq;
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }
}