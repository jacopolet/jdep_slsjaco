/**************************************************************
* @Author: saranya.a.rajagopal
* @Company: Accenture
* @Description: Test class for APTS_ProductBizIsland
* @Created Date: OCT 10, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      saranya.a.rajagopal      Oct 10, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_ProductBizIslandTest {
@testSetup
     static void testData(){
     
            Account acc = APTS_TestDataFactory.createAccount('testAccount');
            acc.APTS_BizIsland_Bonsai_Account__c=true;
            Database.insert(acc);
            
             Contact con=APTS_TestDataFactory.createContact(acc,'1234556');
             Database.insert(con);
        
            /*Product2 prod1 = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
            prod1.APTS_Associated_Sales_Org__c= 'SAP_0975';
            prod1.APTS_Cross_plant_material_status__c= 'PR';
            prod1.APTS_Sales_Catalog__c = '1234';
            prod1.Apttus_Config2__Uom__c = 'SAP_EA';
            prod1.Apttus_Config2__ConfigurationType__c='Option';
            Database.insert(prod1);*/

            Product2 prod = APTS_TestDataFactory.createProduct('TestProduct','test1000','Coffee', 'Option', FALSE, TRUE);
            prod.APTS_Associated_Sales_Org__c= 'SAP_0975';
            prod.APTS_Cross_plant_material_status__c= 'PR';
            prod.APTS_Sales_Catalog__c = '1234';
            prod.Apttus_Config2__Uom__c = 'SAP_EA';
            prod.Apttus_Config2__ConfigurationType__c='Option';
            prod.Family='SAP_01';
            Database.insert(prod);
             
            Bonsai__c customSetting = new Bonsai__c();
            customSetting.Name = 'test';
            customSetting.Delta_Load__c = true;
            customSetting.Full_Load__c = true;
            insert customSetting;
            
            Apttus_Config2__FrequencyConversionRate__c freqConv = new Apttus_Config2__FrequencyConversionRate__c();
            //freqConv.APTS_Denominator__c= 0234;
            freqConv.Apttus_Config2__FromUom__c='SAP_PCE';
            //freqConv.APTS_Numerator__c= 234;
            freqConv.Apttus_Config2__ToUom__c= 'SAP_KGM';
            freqConv.Apttus_Config2__ProductId__c=prod.id;
            freqConv.APTS_Denominator__c = 1.20;
            freqConv.APTS_Numerator__c  = 2.20;
            Database.insert(freqConv);
            
            
            Apttus_Config2__FrequencyConversionRate__c freqConv1 = new Apttus_Config2__FrequencyConversionRate__c();
            //freqConv.APTS_Denominator__c= 0234;
            freqConv1.Apttus_Config2__FromUom__c='SAP_PCE';
            //freqConv.APTS_Numerator__c= 234;
            freqConv1.Apttus_Config2__ToUom__c= 'SAP_LTR';
            freqConv1.Apttus_Config2__ProductId__c=prod.id;
            freqConv1.APTS_Denominator__c = 1.00;
            freqConv1.APTS_Numerator__c  = 2.00;
            Database.insert(freqConv1);
        
            BizIsland_Request__c bizland = new BizIsland_Request__c();
            bizland.name = 'Bonsai Request '+Date.Today();
            Database.insert(bizland);
            
            APTS_Sales_Org_Data__c salesorg = new APTS_Sales_Org_Data__c();
            salesorg.APTS_Selling_Unit__c ='SAP_EA';
            salesorg.APTS_Distribution_channel__c = 'SAP_10';
            salesorg.APTS_Sales_Org_Data_Ext_ID__c = '0975';
            salesorg.APTS_Product__c = prod.id;
            Database.insert(salesorg);
            
            
            
            
        }
        @isTest
        static void testElseBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = true;
        update customSetting;
       
        Test.startTest();
        APTS_ProductBizIsland   ProductBizbatch = new  APTS_ProductBizIsland ();
        Database.executeBatch(ProductBizbatch, 200);
        Test.stopTest();
      }
        
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_ProductBizIsland   productBizbatch = new  APTS_ProductBizIsland ();
            Database.executeBatch(productBizbatch, 200);
            Test.stopTest();
       }

    }