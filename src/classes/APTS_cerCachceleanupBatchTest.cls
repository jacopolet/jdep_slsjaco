@isTest
private class APTS_cerCachceleanupBatchTest {

    private static testMethod void testpositivecerCachceleanupBatch(){
            String standardDeal = 'Standard Deal';
        String billingPrefrence = 'JDETestPrefrence';
        String accountName = 'JDETestAccount';
        String contactNumber = '1010101011';
        String opportunityName = 'JDETestOpportunity';
        String priceListName = 'JDETest Price List';
        String prodFamilyName = 'MA';
        String prodConfigBundle = 'Bundle';
        String prodConfigOption = 'Option';
        String productService = 'PRODUCT/SERVICE';
        String billingFreqMonthly = 'Monthly';
        String billingTypeAdvanced = 'Bill In Advance';
        String priceTypeOnetime = 'One Time';
        String priceUnitPer = 'Per Unit';
        String priceUnitEach = 'Each';
        String orderTypeMachineOrder = 'Machine Order';
        String orderSubtypeTechnicalSwap = 'Technical Swap';
        String commercialSwap = 'Commercial Swap';
        String pageParamId = 'id';
        String pageParamFirstParam = 'firstParam';
        String agreementActivated = 'Activated';
        String agrrementInEffect = 'In Effect';


             Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(billingPrefrence);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigOption, FALSE, TRUE);
        Database.insert(prod1);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        pli1.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        oAgreement.Apttus__Status__c='Cancelled Request';
        oAgreement.Apttus__Status_Category__c='Cancelled';
        Database.insert(oAgreement);
        
        Apttus__APTS_Agreement__c oAgreement1 = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        oAgreement1.Apttus__Status__c='Terminated';
        oAgreement1.Apttus__Status_Category__c='Terminated';
        Database.insert(oAgreement1);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        oProductConfiguration.Apttus_Config2__Status__c = 'Superseded';
        Database.insert(oProductConfiguration);
        
        Apttus_Config2__ProductConfiguration__c oProductConfiguration1 = APTS_TestDataFactory.createProductConfig(oAgreement1);
        oProductConfiguration1.Apttus_Config2__Status__c = 'finalized';
        Database.insert(oProductConfiguration1);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, prodConfigOption, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        lineItem.Apttus_Config2__LineType__c = 'option';
        Database.insert(lineItem);
        
        Apttus_Config2__AdjustmentLineItem__c adjdel = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
        Apttus_Config2__LineItemId__c = lineItem.id,
        Apttus_Config2__SubType__c = 'ZP03',
        APTS_Adjustment_Source__c='child');
        Database.insert(adjdel);
        
        CERDiscountCache__c recCER = new CERDiscountCache__c(Name=adjdel.Apttus_Config2__LineItemId__c+adjdel.Apttus_Config2__SubType__c+adjdel.APTS_Adjustment_Source__c, Sub_Type__c = adjdel.Apttus_Config2__SubType__c, 
        Name__c = adjdel.Apttus_Config2__LineItemId__c,
         Configuration__c = oProductConfiguration.id, 
         Source__c = adjdel.APTS_Adjustment_Source__c);
         Database.insert(recCER );
         
         APTS_cerCachceleanupBatch cc=new APTS_cerCachceleanupBatch();
         database.executebatch(cc,22);
    
    
}

}