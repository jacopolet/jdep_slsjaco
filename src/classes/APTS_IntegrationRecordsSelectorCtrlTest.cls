@isTest
private class APTS_IntegrationRecordsSelectorCtrlTest {
    
    @testSetup
    private static void testDataSetup() {

        Account acc = APTS_TestUtils.createaccount();
        acc.Sales_Organization__c = 'SAP_0333';
        Database.insert(acc,false);
        //System.assertNotEquals(acc,null);
        
        Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
        Database.insert(prd,false);
        //System.assertNotEquals(prd,null);
        
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        //System.assertNotEquals(plist,null);
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);
        //System.assertNotEquals(pli,null);
        
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
        //System.assertNotEquals(billpre,null);
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc.Id,plist.Id,billpre.Id);
        Database.insert(order,false);
        //System.assertNotEquals(order,null);

        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        //System.assertNotEquals(con,null);
        
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        aggr.Name = 'Test Agreement';
        aggr.Apttus__Primary_Contact__c = con.Id;
        aggr.Apttus__Agreement_Category__c = 'Standard';
        aggr.Apttus_CMConfig__PriceListId__c = plist.Id;
        aggr.Apttus_CMConfig__PricingDate__c = System.Today();
        aggr.Apttus__Status__c = 'Activated';
        aggr.Apttus__Status_Category__c = 'In Effect';
        aggr.Apttus__Account__c = acc.Id;
        aggr.Apttus__Perpetual__c = true;
        insert aggr;
        //System.assertNotEquals(aggr,null);*/
        
        List<Apttus_Config2__AssetLineItem__c> aliInsertList = new List<Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        aliInsertList.add(ali);
        
        Database.insert(aliInsertList,False);
        //System.assertNotEquals(aliInsertList,null);

        /*RTR_LAE_Staging_Data__c objStaging = new RTR_LAE_Staging_Data__c(
                        APTS_Asset_Line_Item__c = aliInsertList[0].Id,
                        APTS_Billing_Condition1__c = 'GROSS',
                        APTS_Billing_Condition2__c = 'NET',
                        APTS_Business_Transaction_Type__c = '0001',
                        //APTS_Contract_Description__c = aliInsertList[0].Apttus_CMConfig__AgreementId__r.Apttus__Description__c,
                        APTS_Currency_Code__c = aliInsertList[0].Apttus_CMConfig__AgreementId__r.CurrencyIsoCode,
                        APTS_End_Date__c = aliInsertList[0].Apttus_Config2__BillingPlanId__r.Apttus_Config2__BillingEndDate__c,
                        APTS_Migration_Date__c = aliInsertList[0].Apttus_CMConfig__AgreementId__r.APTS_Migration_Date__c,
                        APTS_Product__c = aliInsertList[0].APTS_Physical_Asset_Id__r.ProductCode__c,
                        APTS_Product_Family__c = aliInsertList[0].Apttus_Config2__ProductId__r.Family,
                        APTS_Sales_Order_Item__c = aliInsertList[0].APTS_Installation_Sales_Order_Item__c,
                        APTS_Sales_Order_Number__c = aliInsertList[0].APTS_Installation_Sales_Order_Id__c,
                        APTS_Serial_Number__c = aliInsertList[0].APTS_Physical_Asset_Id__r.SerialNumber__c,
                        APTS_Start_Date__c = aliInsertList[0].Apttus_Config2__BillingPlanId__r.Apttus_Config2__BillingStartDate__c
                    );*/
        RTR_LAE_Staging_Data__c objStaging = new RTR_LAE_Staging_Data__c(
                        APTS_Asset_Line_Item__c = aliInsertList[0].Id,
                        APTS_Business_Transaction_Type__c = '0001'
                    );       
        insert objStaging;
    }

    private static testMethod void test1() {

        test.startTest();
            PageReference pageRef = Page.APTS_IntegrationRecordsSelector;
            Test.setCurrentPage(pageRef);

            APTS_IntegrationRecordsSelectorCtrl objCtrl = new APTS_IntegrationRecordsSelectorCtrl();
            List<selectOption> lstOption0 = objCtrl.recordsXPage;
            List<selectOption> lstOption1 = objCtrl.level1Items;
            objCtrl.selectedLevel1.add(lstOption1[0].getValue());
            objCtrl.searchRecords();
            List<selectOption> lstOption2 = objCtrl.level2Items;
            objCtrl.selectedLevel2.add(lstOption2[0].getValue());
            objCtrl.searchRecords();
            List<selectOption> lstOption3 = objCtrl.level3Items;
            objCtrl.selectedLevel3.add(lstOption3[0].getValue());
            objCtrl.searchRecords();
            objCtrl.lstWrapperStagingData[0].checked = true;
            Boolean hasNext = objCtrl.hasNext;
            Boolean hasPrevious = objCtrl.hasPrevious;
            Integer pageNumber = objCtrl.pageNumber;  
            Integer totalPages = objCtrl.totalPages;
            objCtrl.first();
            objCtrl.last();
            objCtrl.next();
            objCtrl.createRecords();
            objCtrl.clearFilters();

        test.stopTest();
   
    }
    
}