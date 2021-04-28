@isTest
private class APTS_ProductRepalcementTHandlerTest
{
    private static testMethod void testReplacementProduct()
     {
     Apttus_Config2__PriceList__c priceList = APTS_TestDataFactory.createPriceList('EUR Price list');
            priceList.APTS_PriceList_Type__c='Direct';
            priceList.APTS_SalesOrg__c='0333';
            Database.Insert(priceList, false);
            
            //insert product
            Product2 prod = APTS_TestDataFactory.createProduct('TestCoffee', '111456', 'Coffee', 'Standalone', true, false);
            Database.Insert(prod, false);
            
            //Insert price list item
            Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(priceList.id,prod.id);
            pricelistItem.APTS_ConditionType__c='YRF0';
            pricelistItem.Apttus_Config2__ProductId__c=prod.id;
            pricelistItem.Apttus_Config2__PriceListId__c=priceList.id;
            pricelistItem.Apttus_Config2__ChargeType__c=Label.APTS_Rental_Price;
            pricelistItem.APTS_Sales_Organization__c='0333';
            pricelistItem.Apttus_Config2__Description__c='Karan tax test';
            pricelistItem.APTS_Product_Code__c='111456';
            Database.upsert(pricelistItem, false);
            
            Test.startTest();
            APTS_Product_Replacement_Codes__c prc1=new APTS_Product_Replacement_Codes__c();
            prc1.APTS_Product_Code__c='111456';
            prc1.APTS_Sales_Org__c='0333';
            prc1.Name='JDEReplacement2';
            prc1.APTS_Valid_From__c = System.today();
            prc1.APTS_Replacement_Product_Code__c='11145688';
            Database.insert(prc1);
         
            prc1.APTS_Product__c=prod.id;
            database.update(prc1);
            Test.stopTest();
            List<Apttus_Config2__PriceListItem__c> PLI = [Select Id,APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c =: prod.Id];
            system.assert(PLI[0].APTS_Product_Code__c != NULL);
    }
}