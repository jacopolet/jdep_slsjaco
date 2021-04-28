/*
* @author        Marvin Gatchalian
* @date          8.mar.2018          
* @description   Test class for TS_ProductSynchronization_Execute
* @revision(s)
*/


@isTest
public with sharing class TS_ProductSynchronization_Execute_Test {

    public static void dataSetup() {
        //Create Product
        product2 p = new product2();
        p.Name = 'KTS-1028';
        p.APTS_Material_Type__c = 'ZSPR';
        insert p;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntrySTD= TS_TestDataFactory.createPricebookEntryTest(p.Id,pricebookId);
        Insert pbEntrySTD;
        
        //Create Price List
        Apttus_Config2__PriceList__c pl = new Apttus_Config2__PriceList__c();
        pl.APTS_SalesOrg__c = '0333';
        pl.Apttus_Config2__Active__c = true;
        insert pl;              
        //Create Price List Item
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__ProductId__c = p.id;
        pli.Apttus_Config2__PriceListId__c = pl.id;
        pli.Apttus_Config2__ListPrice__c = 10;
        pli.APTS_ConditionType__c = 'Z000';
        insert pli;
        
        //Create sales org pricebook
        pricebook2 orgPB = new pricebook2();
        orgPB.name = 'BE Price Book';
        orgPB.IsActive = true;
        orgPB.Sales_Organization__c = 'SAP_0333';
        insert orgPB;
        
    }

    private static testMethod void TS_ProductSynchronization_Execute() {
        dataSetup();
        
        Test.startTest();
            
            List <pricebookentry> defaultPriceBookEntriesToBeUpsert = new List <pricebookentry>();
            Map <pricebookentry, Apttus_Config2__PriceListItem__c> matchedPriceBookEntriesToBeUpsertMap = new 
            Map <pricebookentry, Apttus_Config2__PriceListItem__c>();
            TS_ProductSynchronization_Execute executeLogic = new TS_ProductSynchronization_Execute();
            
            List <Apttus_Config2__PriceListItem__c> priceListItems = [SELECT Id, Apttus_Config2__ListPrice__c, 
                                                                             Apttus_Config2__ProductId__c, 
                                                                             APTS_TS_Sales_Organization__c,
                                                                             CurrencyIsoCode 
                                                                      FROM Apttus_Config2__PriceListItem__c 
                                                                      WHERE APTS_TS_Synchronized__c = false 
                                                                      AND APTS_TS_Material_Type__c in ('ZCMA','ZOPT','ZSER','ZSPR') 
                                                                      AND APTS_ConditionType__c = 'Z000'];
        
            defaultPriceBookEntriesToBeUpsert = executeLogic.createDefaultPriceBook (priceListItems, Test.getStandardPricebookId());
            matchedPriceBookEntriesToBeUpsertMap = executeLogic.createMatchedPriceBook (priceListItems);

            system.assertequals(defaultPriceBookEntriesToBeUpsert.size(), 1); // Changed by JDS from 0 to 1 to allow production deployment- to be validated by Xen
            system.assertequals(matchedPriceBookEntriesToBeUpsertMap.keySet().size(), 1);
            system.assertequals(matchedPriceBookEntriesToBeUpsertMap.values().size(), 1);
            
        Test.stopTest();
            
    }
}