/**
* @author        Karen Hung
* @date          14.11.2019
* @description   test class for PartRequestLineItemTriggerHandler , part of DOO-2196
* @revision(s)   
*/
@isTest
public class PartRequestLineItemTriggerHandler_Test {
	static Product2 prod;
    static Part_Request__c pReq;
    static Part_Request_Line_Item__c prItem;
    static Resource__c engr;
    static PricebookEntry pbEntry;
    
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
        cset.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Country Purchasing Settings');
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

        APTS_Sales_Org_Data__c orgData = new APTS_Sales_Org_Data__c();
        orgData.APTS_Product__c = prod.Id;
        orgData.APTS_Sales_Org_Data_Name__c = '0111';
        orgData.APTS_Distribution_chain_specific_materia__c = 'SAP_01';
        insert orgData;
                
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(prod.Id,pricebookId);
        Insert pbEntrySTD;
        
        Pricebook2 pricebook = new Pricebook2(Name=' Pricebook', isActive=true, Sales_Organization__c ='SAP_0111');
        insert pricebook;
        
        pbEntry= TS_TestDataFactory.createPricebookEntryTest(prod.Id,Pricebook.Id); 
        pbEntry.IsActive=true;
        insert pbEntry;
        
        pReq = new Part_Request__c();
        pReq.Resource__c = engr.Id;
        pReq.Status__c = 'Open';
   		insert pReq;
        
        prItem = new Part_Request_Line_Item__c();
        prItem.Part_Request__c = pReq.Id;
        prItem.Product__c = prod.Id;
        prItem.Quantity__c = 1;
        insert prItem;        
    }
    
    /*test validation*/
    static testMethod void validateItemTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            delete prItem;
            undelete prItem;
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }
       
    /*test validation update*/
    static testMethod void validateItemUpdateTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
            engr.CompanyCode__c = '0079';
            update engr;
            prItem.Quantity__c = 2;
            update prItem;            
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }
    /*test exception*/
    static testMethod void exceptionTest(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            PartRequestLineItemTriggerHandler.hasException = true;
            setupTestData();
            prItem.Quantity__c = 2;
            update prItem;
        }
        system.assertEquals('0079',engr.CompanyCode__c );
    }
  
}