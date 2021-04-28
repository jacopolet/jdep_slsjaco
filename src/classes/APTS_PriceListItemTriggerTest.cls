/*******************
Purpose: 
Revision History:
#No     Name        Date        Purpose
1.0     Nagavi      16/01/2017  Created the class for the Price List Item trigger Handler
************************/
@isTest
private with sharing class APTS_PriceListItemTriggerTest {
    @testSetup
    static void testSetup(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        // Modified by Rajesh Patel
        User u = new User(Alias = APTS_CPQConstants.ALISE, Email= APTS_CPQConstants.USR_EMAIL, 
        EmailEncodingKey= APTS_CPQConstants.USR_ENCODING_KEY, LastName= APTS_CPQConstants.USR_LNAME, LanguageLocaleKey = APTS_CPQConstants.USR_LNG_KEY,  
        LocaleSidKey= APTS_CPQConstants.USR_LNG_KEY, ProfileId = p.Id, Elevated_Access_Reason__c = 'Authorization Issue',Elevated_Access_Reference__c = 'Authorization Issue',
        TimeZoneSidKey= APTS_CPQConstants.USR_TIMEZONE, UserName= APTS_CPQConstants.USR_NAME, Sales_Organization__c = APTS_CPQConstants.USR_SALES_ORG);        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'JDE_CPQ_Admin'];

        System.runAs(u) {
            //insert custom settings
            insert new TriggerSettings__c(PriceLineItemTrigger__c = true);
            insert new APTS_Webshop_Enabled__c(Webshops_to_Be_Enabled__c= APTS_CPQConstants.NL);  // Modified by Rajesh Patel
        }
    }
    
    private static testMethod void testProdInsertUpdate() {
        User usr=[Select Id from User where UserName='sample@testUserjde.com']; 
         System.runAs(usr) {
            List<Product2> productList=new List<Product2>();
            productList=TestDataFactory.createProduct(50);
            insert productList;
            
            List<Apttus_Config2__PriceList__c> priceList=new List<Apttus_Config2__PriceList__c>();
            priceList=TestDataFactory.createPriceList(1);
            insert priceList;
            
            Test.startTest(); 
            List<Apttus_Config2__PriceListItem__c> plItemList=new List<Apttus_Config2__PriceListItem__c>();
            plItemList=TestDataFactory.createPriceListItem(50,productList,priceList);
            insert plItemList;

             APTS_PriceListItemTriggerHandler.onAfterInsertPLItems(plItemList);
           
            
            plItemList[0].Apttus_Config2__EffectiveDate__c=system.Now();       
            plItemList[1].Apttus_Config2__ExpirationDate__c=system.Now();
            plItemList[2].APTS_Default_Selling_Uom__c='Test';
            plItemList[3].Apttus_Config2__PriceUom__c='Hour';
            plItemList[4].APTS_ListPriceUnit__c='Test';
            update plItemList;
             
            plItemList[0].Apttus_Config2__Active__c=false;       
            plItemList[1].APTS_TaxDigitalTeaCoffeeAmount__c=8.009;
            plItemList[2].APTS_TaxDigitalHighLowIndicator__c='Test';
            plItemList[3].APTS_ListPriceDigitalExclAllTaxes__c=5.89;
            plItemList[4].APTS_TaxDigitalRecyclingPackagingAmount__c=8.890;
            update plItemList;
            APTS_PriceListItemTriggerHandler.updateMasterListPriceforCSP(plItemList);
            // Modified by Rajesh Patel
            System.assert(plItemList != Null);
            System.assertEquals(plItemList[3].APTS_ListPriceDigitalExclAllTaxes__c,5.89);
            
             
            plItemList[0].Apttus_Config2__Active__c=true;       

            update plItemList;
            //CheckDeletion(plItemList);
             //delete plItemList;
             //undelete plItemList;
            Test.stopTest();
         }
    }
    private static testMethod void testCSP() {
        User usr=[Select Id from User where UserName='sample@testUserjde.com']; 
         System.runAs(usr) {
            List<Product2> productList=new List<Product2>();
            productList=TestDataFactory.createProduct(50);
            insert productList;
            
            List<Apttus_Config2__PriceList__c> priceList=new List<Apttus_Config2__PriceList__c>();
            priceList=TestDataFactory.createPriceList(1);
            insert priceList;
            
            Test.startTest(); 
            List<Apttus_Config2__PriceListItem__c> plItemList=new List<Apttus_Config2__PriceListItem__c>();
            plItemList=TestDataFactory.createPriceListItem(50,productList,priceList);
            insert plItemList;
            
            plItemList[0].Apttus_Config2__EffectiveDate__c=system.Now();       
            plItemList[1].Apttus_Config2__ExpirationDate__c=system.Now();
            plItemList[2].APTS_Default_Selling_Uom__c='Test';
            plItemList[3].Apttus_Config2__PriceUom__c='Hour';
            plItemList[4].APTS_ListPriceUnit__c='Test';
            update plItemList;
             
            plItemList[0].Apttus_Config2__Active__c=false;       
            plItemList[1].APTS_TaxDigitalTeaCoffeeAmount__c=8.009;
            plItemList[2].APTS_TaxDigitalHighLowIndicator__c='Test';
            plItemList[3].APTS_ListPriceDigitalExclAllTaxes__c=5.89;
            plItemList[4].APTS_TaxDigitalRecyclingPackagingAmount__c=8.890;
            update plItemList;

            List<Apttus_Config2__PriceList__c> priceListCSP=new List<Apttus_Config2__PriceList__c>();
            priceListCSP=TestDataFactory.createPriceList(1);
            priceListCSP[0].APTS_PriceList_Type__c='CSP';
            priceListCSP[0].Apttus_Config2__BasedOnPriceListId__c =priceList[0].id;
            insert priceListCSP;
            
            List<Apttus_Config2__PriceListItem__c> plICSPtemList=new List<Apttus_Config2__PriceListItem__c>();
            plICSPtemList=TestDataFactory.createPriceListItem(50,productList,priceListCSP);
            insert plICSPtemList;

            //DOQCP-178
            
            
            Apttus_Config2__PriceList__c pl= new Apttus_Config2__PriceList__c();
            pl.Name= 'Denmark general PriceList';
            Pl.APTS_PriceList_Type__c='Direct';
            pl.Apttus_Config2__Active__c=true;
            pl.CurrencyIsoCode='EUR';
            pl.APTS_Region__c='SAP_0975';
            pl.APTS_SalesOrg__c = 'Denmark';
            insert pl;
            
            Apttus_Config2__PriceList__c CSPPL= new Apttus_Config2__PriceList__c();
            CSPPL.Name= 'Denmark CSP PriceList';
            CSPPL.APTS_PriceList_Type__c='CSP';
            CSPPL.Apttus_Config2__Active__c=true;
            CSPPL.CurrencyIsoCode='EUR';
            CSPPL.APTS_Region__c='SAP_0975';
            CSPPL.APTS_SalesOrg__c = 'Denmark';
            insert CSPPL;

            Apttus_Config2__PriceListItem__c pli= new Apttus_Config2__PriceListItem__c();
            pli.Apttus_Config2__PriceListId__c=pl.Id;
            pli.Apttus_Config2__Active__c=true;
            pli.Apttus_Config2__ProductId__c=productList[0].Id;
            pli.APTS_Product_Code__c = productList[0].ProductCode;
            pli.APTS_Sales_Organization__c = '0975';
            pli.Apttus_Config2__ChargeType__c='sales Price';
            pli.APTS_TXP_Coffee_Tax__c=10;
            pli.APTS_TXP_Instant_Coffee_Tax__c=11;
            pli.APTS_TXP_Liquid_Coffee_Tax__c=12;
            pli.APTS_TXP_Tea_Tax__c=13;
            pli.APTS_TXP_Chocolate_Tax__c=14;
            pli.APTS_TXP_Disposable_Tableware__c=15;
            pli.APTS_TXP_Cappuccino_Tax_Mixed__c=16;
            pli.APTS_TXP_Recycle_Con_Pack_Tax__c=17;
            pli.APTS_TXP_Belgian_GSV__c=18;
            pli.APTS_Recycling_Fee__c=19;
            pli.APTS_TAX_DK_specific_UOM__c=20;
            pli.APTS_TAX_all_countries_UOM__c=21;
            pli.APTS_Tax_per_UOM__c=22;
            pli.APTS_VAT_indicator__c=23;
            pli.APTS_VAT_percentage__c=24;
            insert pli;
            
            Apttus_Config2__PriceListItem__c csppli= new Apttus_Config2__PriceListItem__c();
            csppli.Apttus_Config2__PriceListId__c= CSPPL.Id;
            csppli.Apttus_Config2__Active__c=true;
            csppli.Apttus_Config2__ProductId__c=productList[0].Id;
            csppli.APTS_Product_Code__c = productList[0].ProductCode;
            csppli.APTS_Sales_Organization__c = '0975';
            csppli.Apttus_Config2__ChargeType__c='sales Price';
            insert csppli;
            // Modified by Rajesh Patel
            APTS_PriceListItemTriggerHandler.onAfterInsertPLItems(plItemList);
            APTS_PriceListItemTriggerHandler.onAfterInsertPLItems(plICSPtemList);
            System.assert(plItemList != Null);
            System.assertEquals(plItemList[3].APTS_ListPriceDigitalExclAllTaxes__c,5.89);
            
             
            plItemList[0].Apttus_Config2__Active__c=true;       
            APTS_PriceListItemTriggerHandler.updateMasterListPriceforCSP(plItemList);
            update plItemList;
            
             //APTS_PriceListItemTriggerHandler.CheckDeletion(plICSPtemList);
             //delete plICSPtemList;
             //undelete plICSPtemList;
            Test.stopTest();
         }
    }
}