/**************************************************************
* @Author: saranya.a.rajagopal
* @Company: Accenture
* @Description: Test class for APTS_AgreementBizIsland
* @Created Date: OCT 11, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      saranya.a.rajagopal      Oct 11, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_AgreementBizIslandTest {
@testSetup
 static void testData()
   {

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        acc.APTS_BizIsland_Bonsai_Account__c=true;
        acc.Distribution_Channel__c='SAP_10';
        Database.insert(acc);
        
        Contact con=APTS_TestDataFactory.createContact(acc,'1234556');
        Database.insert(con);
        
        Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
        prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
        prod1.APTS_Cross_plant_material_status__c= 'PR';
        prod1.APTS_Sales_Catalog__c = '1234';
        prod1.Apttus_Config2__ConfigurationType__c='Option';
        Database.insert(prod1);
        
        Apttus_Config2__PriceList__c  PriceList = APTS_TestDataFactory.createPriceList('testpricelist');
        Database.insert(priceList);

        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        Database.insert(priceListItem);

        Apttus__APTS_Agreement__c agree=APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
        agree.APTS_Region__c='SAP_0975';
        agree.APTS_Distribution_Channel__c = 'National (SAP_10)';
        Database.insert(agree); 

        Apttus__APTS_Agreement__c agree1 = APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
        agree1.APTS_Region__c='SAP_0975';
        agree1.name='Test,Agreement';
        agree1.APTS_Distribution_Channel__c = 'National (SAP_10)';
        agree1.CreatedDate = Date.Today()-1;
        agree1.LastModifiedDate = Date.Today();
        agree1.APTS_Sold_To__c=acc.id;
        Database.insert(agree1); 

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
        customSetting.Full_Load__c = true;
        update customSetting;
       
        Test.startTest();
        APTS_AgreementBizIsland agreementbatch = new APTS_AgreementBizIsland ();
        Database.executeBatch( agreementbatch, 200);
        Test.stopTest();
       }
        
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_AgreementBizIsland agreementbatch = new APTS_AgreementBizIsland ();
            Database.executeBatch( agreementbatch, 200);
            Test.stopTest();
       }
    }