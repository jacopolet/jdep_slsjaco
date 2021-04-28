/**************************************************************
* @Author: saranya.a.rajagopal
* @Company: Accenture
* @Description: Test class for APTS_PriceListitemBizIsland
* @Created Date: OCT 11, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      saranya.a.rajagopal      Oct 11, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_PriceListitemBizIslandTest {
@testSetup
 static void testData()
   {

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        acc.APTS_BizIsland_Bonsai_Account__c=true;
        Database.insert(acc);
        
        Contact con=APTS_TestDataFactory.createContact(acc,'1234556');
        Database.insert(con);
        
        Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
        prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
        prod1.APTS_Cross_plant_material_status__c= 'PR';
        prod1.APTS_Sales_Catalog__c = '1234';
        prod1.Apttus_Config2__ConfigurationType__c='Option';
        prod1.Family='SAP_02';
        Database.insert(prod1);

        Apttus_Config2__PriceList__c  PriceList = APTS_TestDataFactory.createPriceList('testpricelist');
        PriceList.APTS_Region__c = 'SAP_0975';
        PriceList.APTS_PriceList_Type__c='Direct';
        Database.insert(priceList);

        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        
        Database.insert(priceListItem);

       
        Apttus_Config2__PriceListItem__c priceListItem1 = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        priceListItem1.CreatedDate = Date.Today()-1;
        priceListItem1.LastModifiedDate = Date.Today();
        Database.insert(priceListItem1);
        

        Bonsai__c customSetting = new Bonsai__c();
        customSetting.Name = 'test';
        customSetting.Delta_Load__c = true;
        customSetting.Full_Load__c = true;
        insert customSetting;
            
        BizIsland_Request__c bizland = new BizIsland_Request__c();
        bizland.name = 'Bonsai Request '+Date.Today();
        Database.insert(bizland);
        
         }
        @isTest
        static void testElseBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = false;
        update customSetting;
       
        Test.startTest();
      APTS_PriceListitemBizIsland   Pricezbatch = new APTS_PriceListitemBizIsland ();
      Database.executeBatch( Pricezbatch,200);
        Test.stopTest();
       }
        
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_PriceListitemBizIsland   Pricezbatch = new APTS_PriceListitemBizIsland ();
            Database.executeBatch( Pricezbatch,200);
            Test.stopTest();
       }
    }