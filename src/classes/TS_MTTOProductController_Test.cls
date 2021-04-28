/**
* @author        Francis Alindogan
* @date          01.31.2020
* @description   Test class for TS_MTTOProductController
* @revision(s)   
*/
@isTest
public class TS_MTTOProductController_Test {
    
    static void setupTestData() {
        	//Create product
            product2 prod = new product2();
            prod.Name = 'Operating Sched Product Test';
            prod.APTS_Material_Type__c = 'ZSPR';
        	prod.ProductCode = '0111';
            insert prod;
        
          	//Create Standard Pricebook
            //Create sales org pricebook
            pricebook2 orgPB = new pricebook2();
            orgPB.name = 'NL Price Book';
            orgPB.IsActive = true;
            orgPB.Sales_Organization__c = 'SAP_0111';
        	orgPB.Country_ISO__c = 'SAP_0111';
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
    
     static testmethod void testGetPriceBook() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
            setupTestData();
        	Test.startTest();
                    PriceBookEntry pb = [SELECT Id, ProductCode, Country_ISO__c
                             //MeanTimeToOperateC__c
                             //MeanTimeToOperateLM__c,
                             //MeanTimeToOperateSM__c,
                             //MTTO_MCO_Bottles__c,
                             //MTTO_MCO_Descaling__c,
                             //MTTO_MCO_Large__c,
                             //MTTO_MCO_PM__c,
                             //MTTO_MCO_Waterfilter__c 
                             FROM PriceBookEntry LIMIT 1];
			TS_MTTOProductController.processBucketUpdate([SELECT Id FROM PricebookEntry][0].Id);
        	System.assert(TS_MTTOProductController.getPriceBook('SAP_0111', '0111') != null);
        	Test.stopTest();
        }
    }
    
    static testmethod void testCustomPermission() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	Test.startTest();
        	System.assert(TS_MTTOProductController.hasCustomPermission('test-class') == false);
        	Test.stopTest();    
        }
    }
}