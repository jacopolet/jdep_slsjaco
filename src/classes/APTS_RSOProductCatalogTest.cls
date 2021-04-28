@isTest
private class APTS_RSOProductCatalogTest
{
	@testSetup
    static void testSetup(){
        //Get settings for batch
        APTS_RSO_batch_settings__c obj = new APTS_RSO_batch_settings__c(
                Name = 'General',
                APTS_Initial_Load__c = true,
            	APTS_RSO_Routesales_Batch__c = true
                );

        insert obj;
        //Create Product
        Product2 product = new Product2();
        product.Name = 'test Product';
        product.ProductCode = '0100';
        product.Family = 'Coffee';
        product.APTS_Product_Family2__c = 'Coffee|Beans';
        product.APTS_Product_Family3__c = 'Coffee|Beans |Nordic Roast';
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';
        product.APTS_Sales_Catalog__c = '0100';
        insert product;

        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List R';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_PriceList_Type__c = 'Routesales';
        priceList.APTS_Region__c = 'SAP_0111';
        priceList.APTS_SalesOrg__c = 'Netherlands';
        insert priceList;

        Apttus_Config2__PriceList__c priceListD = new Apttus_Config2__PriceList__c();
        priceListD.Name = 'JDE Price List D';
        priceListD.Apttus_Config2__Active__c = true;
        priceListD.APTS_PriceList_Type__c = 'Direct';
        priceListD.APTS_Region__c = 'SAP_0333';
        priceListD.APTS_SalesOrg__c = 'Belgium';
        insert priceListD;
        
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceList.Id;
        pli.Apttus_Config2__ProductId__c = product.Id;
        pli.Apttus_Config2__ListPrice__c = 0;
        pli.Apttus_Config2__ChargeType__c = 'Sales Price';
        pli.Apttus_Config2__PriceType__c = 'One Time';
        pli.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pli.Apttus_Config2__Active__c = true;
        pli.Apttus_Config2__BillingFrequency__c = 'One Time';
        pli.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        insert pli;

        Apttus_Config2__PriceListItem__c pliD = new Apttus_Config2__PriceListItem__c();
        pliD.Apttus_Config2__PriceListId__c = priceListD.Id;
        pliD.Apttus_Config2__ProductId__c = product.Id;
        pliD.Apttus_Config2__ListPrice__c = 0;
        pliD.Apttus_Config2__ChargeType__c = 'Sales Price';
        pliD.Apttus_Config2__PriceType__c = 'One Time';
        pliD.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pliD.Apttus_Config2__Active__c = true;
        pliD.Apttus_Config2__BillingFrequency__c = 'One Time';
        pliD.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        insert pliD;

        List<APTS_Sales_Org_Data__c> lstSalesOrgData = new List<APTS_Sales_Org_Data__c>();

        lstSalesOrgData.add(new APTS_Sales_Org_Data__c(
            APTS_Product__c = product.Id,
            APTS_Selling_Unit__c = 'SAP_EA',
            APTS_Upsert_Routesales_Product_Catalog__c = true,
            APTS_Sales_Org_Data_Name__c = '0111'));

        lstSalesOrgData.add(new APTS_Sales_Org_Data__c(
            APTS_Product__c = product.Id,
            APTS_Selling_Unit__c = 'SAP_BX',
            APTS_Upsert_Operating_Product_Catalog__c = true,
            APTS_Sales_Org_Data_Name__c = '0333'));
        
        insert lstSalesOrgData;       
    }

	private static testMethod void testScenario1()
	{
		test.startTest();
            APTS_RSOProductCatalogSch scheduler = new APTS_RSOProductCatalogSch();      
			String sch = '0  00 1 3 * ?';
			system.schedule('Test APTS_RSOProductCatalogBatch', sch, scheduler);
        test.stopTest();
	}
}