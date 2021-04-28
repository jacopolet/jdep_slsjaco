/*******************
Purpose: 
Revision History:
#No     Name        Date        Purpose
1.0     Nagavi      16/01/2017  Created the class for the Product trigger Handler
************************/
@isTest
private class APTS_ProductTriggerHandlerTest {

    @testSetup
    static void testSetup() {

        Profile p = [SELECT Id FROM Profile WHERE Name =: 'System Administrator'];
        User u = APTS_TestDataFactory.createUser();
        insert u;

        System.runAs(u) {

            insert new APTS_Webshop_Enabled__c(Webshops_to_Be_Enabled__c = 'NL');
            insert new APTS_ProductPricingBatchSettings__c(APTS_AllowedPlantStatusDuringUpdate__c = 'PR',
                APTS_AllowedPlantStatusDuringInitialLoad__c = 'PR,OB,BP,NC,BL',
                APTS_BlockedPlantStatusDuringUpdate__c = 'DV,RP,RL');

            TriggerSettings__c settings = new TriggerSettings__c();
            settings.SalesOrgDataTrigger__c = true;
            settings.ProductTrigger__c = true;
            Database.insert(settings, true);

            List < Product2 > productList = new List < Product2 > ();
            productList = TestDataFactory.createProduct(7);
            productList[3].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[3].APTS_Material_Type__c = 'ZCMA';
            productList[1].Apttus_Config2__ConfigurationType__c = 'Standalone';
            productList[1].APTS_Material_Type__c = 'ZCBB';
            productList[1].Name = 'FIXED TERM - INGREDIENTS VAT LOW';
            productList[1].ProductCode = '81172493';
            productList[2].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[2].APTS_Material_Type__c = 'ZCMA';
            productList[2].APTS_Option_Group_Indicator__c = System.label.APTS_04_Value;
            productList[4].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[4].APTS_Material_Type__c = 'ZCMA';
            productList[4].APTS_Sales_Catalog__c = '0702';
            productList[5].APTS_Sales_Catalog__c = '0701';
            productList[5].Name = 'Coffee Kitchen';
            productList[5].APTS_Material_Type__c = 'ZCMA';
            productList[6].APTS_Option_Group_Indicator__c = '0102';
            productList[6].Name = 'Brita Water';
            productList[7].APTS_Sales_Catalog__c = '010104';
            productList[7].Name = 'Tea Standalone';

            List < Apttus_Config2__PriceList__c > priceList = TestDataFactory.createPriceList(1);
            for (integer index = 0; index < priceList.size(); index++) {
                priceList[index].APTS_SalesOrg__c = '0333';
            }
            Database.insert(priceList);

            List < APTS_Sales_Org_Data__c > salesOrgList = new List < APTS_Sales_Org_Data__c > ();
            for (integer index = 0; index < productList.size(); index++) {
                APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c(
                    APTS_Sales_Org_Data_Ext_ID__c = productList[index].ProductCode + '|' + '0333',
                    APTS_Sales_Org_Data_Name__c = '0333',
                    APTS_Distribution_chain_specific_materia__c = 'SAP_01',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Cost_Price__c = '1786',
                    APTS_Price_List__c = priceList[0].Id
                );
                salesOrgList.add(salesOrg);
            }

            Database.insert(salesOrgList);

            try {
                System.debug('before l');
                insert productList;

                APTS_ProductTriggerHandler.processProductsInsertBasedOnMARA(productList);
                APTS_ProductTriggerHandler.onAfterInsertProduct2(productList);
                System.debug('After l' + productList.size());
            } catch (Exception e) {
                //  Boolean expectedExceptionThrownInsert =  e.getMessage().contains('Script-thrown exception') ? true : false;
                System.debug('Exception Occured' + e.getMessage());
            }


            Test.startTest();
            productList[0].IsActive = false;
            productList[1].ProductCode = 'ASC';
            productList[1].ExternalId = '12345';
            productList[1].APTS_Cross_plant_material_status__c = 'RP';
            try {
                update productList;
            } catch (Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains('Script-thrown exception') ? true : false;
                System.assertEquals(expectedExceptionThrown, false);
            }
            delete productList;
            undelete productList;
            Test.stopTest();


        }
    }


    private static testMethod void testProdInsertUpdate() {
        User usr = [Select Id from User where UserName = 'testuser123@jdecoffee.com'];
        System.runAs(usr) {

            List < Product2 > productList = new List < Product2 > ();
            productList = TestDataFactory.createProduct(7);
            productList[3].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[3].APTS_Material_Type__c = 'ZCMA';
            productList[1].Apttus_Config2__ConfigurationType__c = 'Standalone';
            productList[1].APTS_Material_Type__c = 'ZCBB';
            productList[1].Name = 'FIXED TERM - INGREDIENTS VAT LOW';
            productList[1].ProductCode = '81172493';
            productList[2].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[2].APTS_Material_Type__c = 'ZCMA';
            productList[2].APTS_Option_Group_Indicator__c = System.label.APTS_04_Value;
            productList[4].Apttus_Config2__ConfigurationType__c = 'Bundle';
            productList[4].APTS_Material_Type__c = 'ZCMA';
            productList[4].APTS_Sales_Catalog__c = '0702';
            productList[5].APTS_Sales_Catalog__c = '0701';
            productList[5].Name = 'Coffee Kitchen';
            productList[5].APTS_Material_Type__c = 'ZCMA';
            productList[6].APTS_Option_Group_Indicator__c = '0102';
            productList[6].Name = 'Brita Water';
            productList[7].APTS_Sales_Catalog__c = '010104';
            productList[7].Name = 'Tea Standalone';

            try {
                System.debug('before l');
                insert productList;
                System.debug('After l' + productList.size());
            } catch (Exception e) {
                //  Boolean expectedExceptionThrownInsert =  e.getMessage().contains('Script-thrown exception') ? true : false;
                System.debug('Exception Occured' + e.getMessage());
            }


            List < Apttus_Config2__PriceList__c > priceList = TestDataFactory.createPriceList(1);
            for (integer index = 0; index < priceList.size(); index++) {
                priceList[index].APTS_SalesOrg__c = '0333';
            }
            Database.insert(priceList);

            List < APTS_Sales_Org_Data__c > salesOrgList = new List < APTS_Sales_Org_Data__c > ();
            for (integer index = 0; index < productList.size(); index++) {
                APTS_Sales_Org_Data__c salesOrg = new APTS_Sales_Org_Data__c(
                    APTS_Sales_Org_Data_Ext_ID__c = productList[index].ProductCode + '|' + '0333',
                    APTS_Sales_Org_Data_Name__c = '0333',
                    APTS_Distribution_chain_specific_materia__c = 'SAP_01',
                    APTS_Product_Code__c = productList[index].ProductCode,
                    APTS_Cost_Price__c = '1786',
                    APTS_Price_List__c = priceList[0].Id
                );
                salesOrgList.add(salesOrg);
            }

            Database.insert(salesOrgList);






            Test.startTest();
            productList[0].IsActive = false;
            //update productList[0];

            productList[1].ProductCode = 'ASC';
            productList[1].ExternalId = '12345';
            productList[1].APTS_Cross_plant_material_status__c = 'RP';
            try {
                update productList;
            } catch (Exception ex) {
                Boolean expectedExceptionThrown = ex.getMessage().contains('Script-thrown exception') ? true : false;
                System.assertEquals(expectedExceptionThrown, false);
            }
            delete productList;
            undelete productList;
            Test.stopTest();
        }
    }

    public static TestMethod void integrationLogHandlerUtilityTests() {

        APTS_IntegrationLogHandlerUtility.getProdWebshops('shop1;shop2');
        APTS_IntegrationLogHandlerUtility.getWebShopString(new Set < String > {
            'shop1',
            'shop2'
        });

    }

    /*
     * @author        Abram Vixen Reyes
     * @date          September 25, 2019
     * @description   Test Method to sync the pricebookentry to Click
     * @revision(s)
     */

    private static testMethod void test_SYNC_TO_CLICK() {

        User usr = [Select Id from User where UserName = 'testuser123@jdecoffee.com'];

        System.runAs(usr) {

            //CREATE PRODUCT
            Product2 p = new Product2();
            p.Name = 'KTS-1028';
            p.APTS_Material_Type__c = 'ZSPR';
            p.APTS_Cross_plant_material_status__c = 'PR';
            insert p;

            //CREATE SALES ORGANIZATION PRICEBOOK
            Pricebook2 orgPB = new Pricebook2();
            orgPB.Name = 'BE Price Book';
            orgPB.IsActive = true;
            orgPB.Sales_Organization__c = 'SAP_0333';
            insert orgPB;

            //CREATE PBENTRY WITH STANDARD AND SALES ORG PRICEBOOK
            PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = p.id;
            pbe.Pricebook2Id = Test.getStandardPricebookId();
            pbe.UnitPrice = 1;
            pbe.IsActive = true;
            pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
            insert pbe;

            pbe = new PricebookEntry();
            pbe.Product2Id = p.id;
            pbe.Pricebook2Id = orgPB.id;
            pbe.UnitPrice = 11;
            pbe.IsActive = true;
            pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(orgPB.id);
            insert pbe;

            Test.startTest();
            p.TS_SyncToClick__c = 2;
            update p;
            Test.stopTest();
        }
    }
}