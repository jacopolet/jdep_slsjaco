/*************************************************************
@Name: APTS_AssetMovementTest
@Author: Pranjal Mittal
@CreateDate: 23-05-2018
@Description: Test class for APTS_AssetMovement class
@UsedBy: APTS_AssetMovement
**************************************************************/
@isTest
private class APTS_AssetMovementTest {
    public static Apttus_Config2__ProductConfiguration__c oCart;
    public static Apttus_Config2__TempObject__c oTemp;
    public static Apttus__APTS_Agreement__c oAggr;

    @isTest
    static void testFetch(){
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;

        Apttus_Config2__AssetLineItem__c oALI = new Apttus_Config2__AssetLineItem__c();
        oALI.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI.Apttus_Config2__LineType__c = 'Product/Service';   
        oALI.Apttus_Config2__IsPrimaryLine__c = true;
        insert oALI;

        oAggr = new Apttus__APTS_Agreement__c();
        oAggr.Apttus__Contract_Start_Date__c = System.today();
        oAggr.Apttus__Contract_End_Date__c = System.today() + 5;
        insert oAggr;

        oCart = new Apttus_Config2__ProductConfiguration__c();
        oCart.Apttus_Config2__BusinessObjectRefId__c = oAggr.Id;
        insert oCart;

        oTemp = new Apttus_Config2__TempObject__c();
        oTemp.Apttus_Config2__ConfigurationId__c = oCart.Id;
        insert oTemp;

        Apttus_Config2__LineItem__c oLI = new Apttus_Config2__LineItem__c();
        oLI.Apttus_Config2__ConfigurationId__c = oCart.Id;
        oLI.Apttus_Config2__ItemSequence__c = 1;
        oLI.Apttus_Config2__LineNumber__c = 1;
        oLI.Apttus_Config2__LineStatus__c = 'Existing';
        oLI.Apttus_Config2__PricingStatus__c  = 'Completed';
        insert oLI;
        
        ApexPages.currentPage().getParameters().put('id', oCart.Id);
        ApexPages.currentPage().getParameters().put('flow', 'NGDefault');
        ApexPages.currentPage().getParameters().put('businessObjectId', oAggr.Id);
        ApexPages.currentPage().getParameters().put('configRequestId', oTemp.Id);
        
        Test.startTest();
        APTS_AssetMovement oController = new APTS_AssetMovement();
        oController.serialNumber = 'Test123';
        oController.fetchAsset();
        oController.createLineItem();
        PageReference pageRef = oController.goBack();
        Test.stopTest();
        /* ---------- Start of PI fix # 718080----------------------- */
        List<Apttus_Config2__LineItem__c> lstline = [Select Id,Apttus_Config2__LineStatus__c from Apttus_Config2__LineItem__c];
        system.assertEquals('New',lstline[0].Apttus_Config2__LineStatus__c);
        /* ---------- End of PI fix # 718080 ----------------------- */
    }

    @isTest
    static void testFetch1(){
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;

        Apttus_Config2__PriceList__c pricelist1 = APTS_TestDataFactory.createPriceList('JDETest Price List1');
        Database.insert(pricelist1);

        Apttus_Config2__PriceList__c pricelist2 = APTS_TestDataFactory.createPriceList('JDETest Price List2');
        Database.insert(pricelist2);

        Apttus_Config2__AssetLineItem__c oALI1 = new Apttus_Config2__AssetLineItem__c();
        oALI1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI1.Apttus_Config2__LineType__c = 'Product/Service';  
        oALI1.Apttus_Config2__IsPrimaryLine__c = true;
        oALI1.Apttus_Config2__PriceListId__c = pricelist1.Id;
        insert oALI1;

        Apttus_Config2__AssetLineItem__c oALI2 = new Apttus_Config2__AssetLineItem__c();
        //oALI2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI2.Apttus_Config2__LineType__c = 'Product/Service';  
        oALI2.Apttus_Config2__IsPrimaryLine__c = true;
        oALI2.Apttus_Config2__PriceListId__c = pricelist1.Id;
        insert oALI2;

        oAggr = new Apttus__APTS_Agreement__c();
        oAggr.Apttus_CMConfig__PriceListId__c = pricelist2.Id;
        oAggr.Apttus__Contract_Start_Date__c = System.today();
        oAggr.Apttus__Contract_End_Date__c = System.today() + 7;
        insert oAggr;

        oCart = new Apttus_Config2__ProductConfiguration__c();
        oCart.Apttus_Config2__BusinessObjectRefId__c = oAggr.Id;
        insert oCart;

        oTemp = new Apttus_Config2__TempObject__c();
        oTemp.Apttus_Config2__ConfigurationId__c = oCart.Id;
        insert oTemp;

        Apttus_Config2__LineItem__c oLI = new Apttus_Config2__LineItem__c();
        oLI.Apttus_Config2__ConfigurationId__c = oCart.Id;
        oLI.Apttus_Config2__ItemSequence__c = 1;
        oLI.Apttus_Config2__LineNumber__c = 1;
        oLI.Apttus_Config2__LineStatus__c = 'Existing';
        oLI.Apttus_Config2__PricingStatus__c  = 'Completed';
        insert oLI;
        
        ApexPages.currentPage().getParameters().put('id', oCart.Id);
        ApexPages.currentPage().getParameters().put('flow', 'NGDefault');
        ApexPages.currentPage().getParameters().put('businessObjectId', oAggr.Id);
        ApexPages.currentPage().getParameters().put('configRequestId', oTemp.Id);
        
        Test.startTest();
        APTS_AssetMovement oController = new APTS_AssetMovement();
        oController.serialNumber = 'Test123';
        oController.fetchAsset();
        oController.createLineItem();
        PageReference pageRef = oController.goBack();
        Test.stopTest();
        /* ---------- Start of PI fix # 718080----------------------- */
        List<Apttus_Config2__LineItem__c> lstline = [Select Id,Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c from Apttus_Config2__LineItem__c];
        system.assertEquals(system.today()+7,lstline[0].Apttus_Config2__EndDate__c);
        /* ---------- End of PI fix # 718080 ----------------------- */
    }

    @isTest
    static void testFetch2(){
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;

        Apttus_Config2__PriceList__c pricelist1 = APTS_TestDataFactory.createPriceList('JDETest Price List1');
        Database.insert(pricelist1);

        Apttus_Config2__PriceList__c pricelist2 = APTS_TestDataFactory.createPriceList('JDETest Price List2');
        Database.insert(pricelist2);

        Apttus_Config2__AssetLineItem__c oALI1 = new Apttus_Config2__AssetLineItem__c();
        oALI1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI1.Apttus_Config2__LineType__c = 'Product/Service';  
        oALI1.Apttus_Config2__IsPrimaryLine__c = true;
        oALI1.Apttus_Config2__PriceListId__c = pricelist1.Id;
        insert oALI1;

        Apttus_Config2__AssetLineItem__c oALI2 = new Apttus_Config2__AssetLineItem__c();
        oALI2.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI2.Apttus_Config2__LineType__c = 'Product/Service';  
        oALI2.Apttus_Config2__IsPrimaryLine__c = true;
        oALI2.Apttus_Config2__PriceListId__c = pricelist1.Id;
        insert oALI2;

        oAggr = new Apttus__APTS_Agreement__c();
        oAggr.Apttus_CMConfig__PriceListId__c = pricelist2.Id;
        oAggr.Apttus__Contract_Start_Date__c = System.today();
        oAggr.Apttus__Contract_End_Date__c = System.today() + 9;
        insert oAggr;

        oCart = new Apttus_Config2__ProductConfiguration__c();
        oCart.Apttus_Config2__BusinessObjectRefId__c = oAggr.Id;
        insert oCart;

        oTemp = new Apttus_Config2__TempObject__c();
        oTemp.Apttus_Config2__ConfigurationId__c = oCart.Id;
        insert oTemp;

        Apttus_Config2__LineItem__c oLI = new Apttus_Config2__LineItem__c();
        oLI.Apttus_Config2__ConfigurationId__c = oCart.Id;
        oLI.Apttus_Config2__ItemSequence__c = 1;
        oLI.Apttus_Config2__LineNumber__c = 1;
        oLI.Apttus_Config2__LineStatus__c = 'Existing';
        oLI.Apttus_Config2__PricingStatus__c  = 'Completed';
        insert oLI;
        
        ApexPages.currentPage().getParameters().put('id', oCart.Id);
        ApexPages.currentPage().getParameters().put('flow', 'NGDefault');
        ApexPages.currentPage().getParameters().put('businessObjectId', oAggr.Id);
        ApexPages.currentPage().getParameters().put('configRequestId', oTemp.Id);
        
        Test.startTest();
        APTS_AssetMovement oController = new APTS_AssetMovement();
        oController.serialNumber = 'Test123';
        oController.fetchAsset();
        oController.createLineItem();
        PageReference pageRef = oController.goBack();
        Test.stopTest();
        /* ---------- Start of PI fix # 718080----------------------- */
        List<Apttus_Config2__LineItem__c> lstline = [Select Id,Apttus_Config2__StartDate__c from Apttus_Config2__LineItem__c];
        system.assertEquals(system.today(),lstline[0].Apttus_Config2__StartDate__c);
        /* ---------- End of PI fix # 718080 ----------------------- */
    }
}