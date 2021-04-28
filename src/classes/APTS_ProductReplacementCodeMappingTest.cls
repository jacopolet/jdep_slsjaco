/**
* Class Name : APTS_ProductReplacementCodeMappingTest
* Description :  Apex Class to test APTS_ProductReplacementCodeMapping Class
* Author : Shahul(shahul.nizam.moideen@accenture.com)
* Date Created : 16/04/2018
**/
@isTest 
private with sharing class APTS_ProductReplacementCodeMappingTest
{
    
    @testSetup static void setupTestData(){

        User oTestUser = APTS_TestFacade.createTestUser();

        Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
        prod1.APTS_Associated_Sales_Org__c= 'SAP_0333';
        prod1.APTS_Cross_plant_material_status__c= 'PR';
        prod1.ProductCode = '111456';
        prod1.APTS_Replaced_by__c='111456';
        prod1.APTS_Sales_Catalog__c = '1234';
        prod1.Apttus_Config2__Uom__c = 'SAP_EA';
        prod1.Apttus_Config2__ConfigurationType__c='Option';
        prod1.IsActive=true;
        insert(prod1);

        Product2 prod2 = APTS_TestDataFactory.createProduct('TestProduct2','test1000','Coffee', 'Option', FALSE, TRUE);
        prod2.APTS_Associated_Sales_Org__c= 'SAP_0333';
        prod2.APTS_Cross_plant_material_status__c= 'PR';
        prod2.ProductCode = '12345';
        prod2.APTS_Replaced_by__c='12345';
        prod2.APTS_Sales_Catalog__c = '1234';
        prod2.Apttus_Config2__Uom__c = 'SAP_EA';
        prod2.Apttus_Config2__ConfigurationType__c='Option';
        prod2.IsActive=true;        
        insert(prod2);

        APTS_Product_Replacement_Codes__c prc0=new APTS_Product_Replacement_Codes__c();
        prc0.APTS_Product_Code__c='12345';
        prc0.APTS_Sales_Org__c='0333';
        prc0.Name='JDEReplacement1';
        prc0.APTS_Product__c=prod2.id;
        prc0.APTS_Valid_From__c=System.today();
        prc0.APTS_Replacement_Product_Code__c='123456';
        prc0.Plant_status__c = 'SAP_01'; 
        insert(prc0);

        APTS_Product_Replacement_Codes__c prc=new APTS_Product_Replacement_Codes__c();
        prc.APTS_Product_Code__c='111456';
        prc.APTS_Sales_Org__c='0333';
        prc.APTS_Valid_From__c=System.today();
        prc.Name='JDEReplacement1';
        prc.APTS_Replacement_Product_Code__c='11145677';
        prc.Plant_status__c = 'SAP_01'; 
        insert(prc);

        APTS_Sales_Org_Data__c instSalesOrg = new APTS_Sales_Org_Data__c();
        instSalesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        instSalesOrg.APTS_Product_Code__c = '111456';
        instSalesOrg.APTS_Sales_Org_Data_Ext_ID__c= '111456|0333';
        instSalesOrg.APTS_Product__c = prod1.id;
        instSalesOrg.APTS_Distribution_chain_specific_materia__c = 'SAP_01'; 
        insert instSalesOrg;
         
        APTS_Sales_Org_Data__c instSalesOrg1 = new APTS_Sales_Org_Data__c();
        instSalesOrg1.APTS_Sales_Org_Data_Name__c = '0333';
        instSalesOrg1.APTS_Product_Code__c = '12345';
        instSalesOrg1.APTS_Sales_Org_Data_Ext_ID__c= '11145677|0333';
        instSalesOrg1.APTS_Product__c = prod2.id;
        instSalesOrg1.APTS_Distribution_chain_specific_materia__c = 'SAP_01';  
        insert instSalesOrg1; 
        
        APTS_Sales_Org_Data__c instSalesOrg2 = new APTS_Sales_Org_Data__c();
        instSalesOrg2.APTS_Sales_Org_Data_Name__c = '0333';
        instSalesOrg2.APTS_Product_Code__c = '12345678';
        instSalesOrg2.APTS_Sales_Org_Data_Ext_ID__c= '111456778899|0333';
        instSalesOrg2.APTS_Product__c = prod2.id;
        instSalesOrg2.APTS_Distribution_chain_specific_materia__c = 'SAP_01';  
        insert instSalesOrg2; 

        APTS_Product_Replacement_Codes__c prc1=new APTS_Product_Replacement_Codes__c();
        prc1.CurrencyIsoCode = null;
        //prc1.CreatedDate= System.today();
        prc1.CreatedById=null;
        //prc1.LastModifiedDate=System.today();
        prc1.APTS_Valid_From__c=System.today();
        prc1.APTS_Valid_To__c = System.today().addDays(100);
        prc1.APTS_Replacement_External_ID__c=null;
        prc1.APTS_Cross_plant_material_status__c=null;
        prc1.Plant_status__c=null;
        prc1.APTS_Product_Code__c='11145677';
        prc1.APTS_Sales_Org__c='0333';
        prc1.Name='JDEReplacement2';
        prc1.APTS_Replacement_Product_Code__c='1114567788';
        insert(prc1);
       
        APTS_Product_Replacement_Codes__c prc2=new  APTS_Product_Replacement_Codes__c();
        prc2.APTS_Product_Code__c='1114567788';
        prc2.APTS_Sales_Org__c='0333';
        prc2.Name='JDEReplacement2';
        prc2.APTS_Replacement_Product_Code__c='111456778899';
        insert(prc2);
        System.assertNotEquals('0332',prc2.APTS_Sales_Org__c);
        
        APTS_Product_Replacement_Codes__c prc3=new  APTS_Product_Replacement_Codes__c();
        prc3.APTS_Product_Code__c='1114567781';
        prc3.APTS_Sales_Org__c='0333';
        prc3.Name='JDEReplacement2';
        prc3.APTS_Replacement_Product_Code__c='11145009900';
        insert(prc3);
        System.assertNotEquals('0332',prc3.APTS_Sales_Org__c);
        
        //insert new TriggerSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), SalesOrgDataTrigger__c = true);
        APTS_ProductReplacementCodeMapping oPRCM = new APTS_ProductReplacementCodeMapping();
        oPRCM.disableSalesOrgDataTrigger(true);
        oPRCM.disableSalesOrgDataTrigger(false);
        
    }
     @isTest
        static void testElseBatch(){      

        Test.StartTest();
        APTS_ProductReplacementCodeMapping prodDstBtch2 = new APTS_ProductReplacementCodeMapping();
        DataBase.executeBatch(prodDstBtch2,200);
        //APTS_ProductReplacementCodeMapping_Clone prodDstBtch3 = new APTS_ProductReplacementCodeMapping_Clone();
        //DataBase.executeBatch(prodDstBtch3,200);
        insert new TriggerSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), SalesOrgDataTrigger__c = true);
        prodDstBtch2.disableSalesOrgDataTrigger(true);
        prodDstBtch2.disableSalesOrgDataTrigger(false);
        Test.StopTest();
    }
}