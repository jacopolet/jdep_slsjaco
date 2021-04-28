/**
* Class Name : APTS_SalesOrgDataTriggerHandler_Test
* Description :  Apex Class to test APTS_SalesOrgDataTriggerHandler class
* Author : V. Shankaranarayanan
* Date Created : 15-03-2018
**/
@isTest
private class APTS_SalesOrgDataTriggerHandler_Test{


    static testMethod void testSalesOrgTrigger(){
        test.starttest();
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.SalesOrgDataTrigger__c = true;
        Database.insert(settings, false);
        APTS_Transactional_UOM__c tom = new APTS_Transactional_UOM__c(name='SAP_BX');
        insert tom;
        Product2 testProduct = TestDataFactory.createProduct(1)[0];
        testProduct.ProductCode = '12345678';
        //testProduct.APTS_Material_Type__c = Label.APTS_ZCMA;
        //testProduct.APTS_Option_Group_Indicator__c='04';
        //testProduct.APTS_Sales_Catalog__c='0702';
        Database.insert(testProduct, false);

        Apttus_Config2__PriceList__c testPriceList = TestDataFactory.createPriceList(1)[0];
        testPriceList.APTS_SalesOrg__c = 'TESTORG';
        testPriceList.APTS_PriceList_Type__c='Direct';
        Database.insert(testPriceList, false);
        
        APTS_Sales_Org_Data__c testSalesOrgData = TestDataFactory.createSalesOrgData(testProduct.Id);
        testSalesOrgData.APTS_Sales_Org_Data_Ext_ID__c = '12345678|TESTORG';
        testSalesOrgData.APTS_Sales_Org_Data_Name__c = 'TESTORG';
        testSalesOrgData.APTS_Product_Code__c=testProduct.ProductCode;
        Database.insert(testSalesOrgData, false);
        //insert testSalesOrgData;
        System.debug('testSalesOrgData=====>'+testSalesOrgData); 
        APTS_Sales_Org_Data__c updatedSalesOrgData = [SELECT Id, APTS_Product__c, APTS_Price_List__c FROM APTS_Sales_Org_Data__c where id=: testSalesOrgData.id];
        System.debug('updatedSalesOrgData=====>'+updatedSalesOrgData);
        System.AssertEquals(updatedSalesOrgData.APTS_Product__c, testProduct.Id);
        System.AssertEquals(updatedSalesOrgData.APTS_Price_List__c, testPriceList.Id);
        testSalesOrgData.APTS_Selling_Unit__c = 'SAP_BX';
        Database.update(testSalesOrgData, false);
        Database.delete(testSalesOrgData, false);
        Database.undelete(testSalesOrgData, false);

        test.stoptest();
    }

    static testMethod void testSalesOrgTrigger_AssocSalesOrgCase1(){

        test.startTest();

        TriggerSettings__c settings = new TriggerSettings__c();
        settings.SalesOrgDataTrigger__c = true;
        Database.insert(settings, false);

        APTS_MARA_MVKE_Status_Mapping__c mMSM = new APTS_MARA_MVKE_Status_Mapping__c();
        mMSM.Name = 'PR|SAP_01';
        mMSM.APTS_MARA_MVKE_Field_Combination__c = 'PR|SAP_01';
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_Has_PLI_active_PLI__c = true;
        mMSM.APTS_Visible_in_Catalogue__c = true;
        Database.insert(mMSM);

        Product2 assocSalesProduct = APTS_TestDataFactory.createProduct('TestCoffee', '123', 'Coffee', 'Standalone', true, false);
        assocSalesProduct.APTS_Cross_plant_material_status__c = 'PR';
        Database.insert(assocSalesProduct, false);

        APTS_Sales_Org_Data__c assocSalesOrg = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        assocSalesOrg.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_02';
        Database.insert(assocSalesOrg, false);

        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_01';
        Database.update(assocSalesOrg, false);
        test.stopTest();
    }

    static testMethod void testSalesOrgTrigger_AssocSalesOrgCase2(){
        test.startTest();

        TriggerSettings__c settings = new TriggerSettings__c();
        settings.SalesOrgDataTrigger__c = true;
        Database.insert(settings, false);

        APTS_MARA_MVKE_Status_Mapping__c mMSM = new APTS_MARA_MVKE_Status_Mapping__c();
        mMSM.Name = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Field_Combination__c = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_Has_PLI_active_PLI__c = true;
        mMSM.APTS_Visible_in_Catalogue__c = false;
        insert mMSM;

        Product2 assocSalesProduct = APTS_TestDataFactory.createProduct('TestCoffee', '123', 'Coffee', 'Standalone', true, false);
        assocSalesProduct.APTS_Cross_plant_material_status__c = 'PR';
        insert assocSalesProduct;

        APTS_Sales_Org_Data__c assocSalesOrg = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        assocSalesOrg.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_01';
        insert assocSalesOrg;

        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_02';
        update assocSalesOrg;
        test.stopTest();
    }

    static testMethod void testSalesOrgTrigger_AssocSalesOrgCase3(){
        test.startTest();
        List<APTS_Sales_Org_Data__c> salesOrgList = new  List<APTS_Sales_Org_Data__c>();

        TriggerSettings__c settings = new TriggerSettings__c();
        settings.SalesOrgDataTrigger__c = true;
        Database.insert(settings, false);
        
        APTS_MARA_MVKE_Status_Mapping__c mMSM = new APTS_MARA_MVKE_Status_Mapping__c();
        mMSM.Name = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Field_Combination__c = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_Has_PLI_active_PLI__c = true;
        mMSM.APTS_Visible_in_Catalogue__c = false;
        insert mMSM;

        Product2 assocSalesProduct = APTS_TestDataFactory.createProduct('TestCoffee', '123', 'Coffee', 'Standalone', true, false);
        assocSalesProduct.APTS_Cross_plant_material_status__c = 'PR';
        insert assocSalesProduct;

        APTS_Sales_Org_Data__c assocSalesOrg = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        assocSalesOrg.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_01';
        insert assocSalesOrg;

        APTS_Sales_Org_Data__c assocSalesOrg1 = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg1.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg1.APTS_Sales_Org_Data_Name__c = '0111';
        assocSalesOrg1.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg1.APTS_Distribution_chain_specific_materia__c='SAP_01';
        insert assocSalesOrg1;

        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_02';

        assocSalesOrg1.APTS_Distribution_chain_specific_materia__c='SAP_02';

        salesOrgList.add(assocSalesOrg1);
        salesOrgList.add(assocSalesOrg);

        update salesOrgList;
    }

    static testMethod void testSalesOrgTrigger_AssocSalesOrgCase4(){
        test.startTest();
        List<APTS_Sales_Org_Data__c> salesOrgList = new  List<APTS_Sales_Org_Data__c>();

        TriggerSettings__c settings = new TriggerSettings__c();
        settings.SalesOrgDataTrigger__c = true;
        Database.insert(settings, false);
        
        APTS_MARA_MVKE_Status_Mapping__c mMSM = new APTS_MARA_MVKE_Status_Mapping__c();
        mMSM.Name = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Field_Combination__c = 'PR|SAP_02';
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_MARA_MVKE_Addition_Removal__c = true;
        mMSM.APTS_Has_PLI_active_PLI__c = true;
        mMSM.APTS_Visible_in_Catalogue__c = false;
        insert mMSM;

        Product2 assocSalesProduct = APTS_TestDataFactory.createProduct('TestCoffee', '123', 'Coffee', 'Standalone', true, false);
        assocSalesProduct.APTS_Cross_plant_material_status__c = 'PR';
        assocSalesProduct.APTS_Associated_Sales_Org__c='SAP_0975;';
        insert assocSalesProduct;

        APTS_Sales_Org_Data__c assocSalesOrg = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg.APTS_Sales_Org_Data_Name__c = '0333';
        assocSalesOrg.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg.APTS_Product__c = assocSalesProduct.id;
        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_01';
        insert assocSalesOrg;

        APTS_Sales_Org_Data__c assocSalesOrg1 = TestDataFactory.createSalesOrgData(assocSalesProduct.Id);
        assocSalesOrg1.APTS_Sales_Org_Data_Ext_ID__c = '12345678|0333';
        assocSalesOrg1.APTS_Sales_Org_Data_Name__c = '0111';
        assocSalesOrg1.APTS_Product_Code__c=assocSalesProduct.ProductCode;
        assocSalesOrg1.APTS_Product__c = assocSalesProduct.id;
        assocSalesOrg1.APTS_Distribution_chain_specific_materia__c='SAP_01';
        insert assocSalesOrg1;

        assocSalesOrg.APTS_Distribution_chain_specific_materia__c='SAP_02';

        assocSalesOrg1.APTS_Distribution_chain_specific_materia__c='SAP_02';

        salesOrgList.add(assocSalesOrg1);
        salesOrgList.add(assocSalesOrg);

        update salesOrgList;

        test.stopTest();
    }
}