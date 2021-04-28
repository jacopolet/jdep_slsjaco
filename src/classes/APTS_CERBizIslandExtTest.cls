/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Test class For APTS_CERBizIsland 
 * @Created Date: Jan 09, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana              25.03.2019      Created
 **********************************************************************************/

@isTest
private class APTS_CERBizIslandExtTest {
    @testSetup
 static void testData()
   {
   
        CER_Bizisland__c cerBiz= new CER_Bizisland__c();
        cerBiz.Sales_Organization__c= 'SAP_0975';
        cerBiz.Distribution_Channel__c= 'National (SAP_10)';
        cerBiz.ID_Level__c= 'ÁGR';
        cerBiz.Agreement_number__c = '23456';
        cerBiz.Customer_Number__c = '56789';
        cerBiz.Product_number__c = '12345';
        cerBiz.List_Price__c = '12';
        cerBiz.Net_Price_Incl_Indirect_Tax__c = '15';
        cerBiz.Customer_Currency__c = 'DKK';
        cerBiz.Base_unit_of_measure__c = 'SAP_BX';
        cerBiz.Discount_in_customer_currency__c = '20';
        cerBiz.Indirect_tax_amount_in_customer_currency__c = '10';
        cerBiz.Status__c = 'New';
        cerBiz.isExecuted__c = false;
        insert cerBiz;
        cerBiz.Status__c = 'Modified';
        update cerBiz;
        
        
        Bonsai__c customSetting = new Bonsai__c();
        customSetting.Name = 'test';
        customSetting.Full_Load__c = true;
        insert customSetting;
            
        BizIsland_Request__c bizland = new BizIsland_Request__c();
        bizland.name = 'Bonsai Request '+Date.Today();
        Database.insert(bizland);
   
   }
   
   @isTest
        static void testElseBatch(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Full_Load__c = true;
        update customSetting;
       
        Test.startTest();
        APTS_CERBizIslandExt instBatch  = new APTS_CERBizIslandExt ();
        Database.executeBatch(instBatch, 200);
        Test.stopTest();
       }
       
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_CERBizIslandExt instBatch = new APTS_CERBizIslandExt();
            Database.executeBatch(instBatch, 200);
            Test.stopTest();
       }

        @isTest
        static void testPurgeBatch(){
            Test.startTest();   

            CER_Bizisland__c cerBiz= new CER_Bizisland__c();
            cerBiz.Sales_Organization__c= 'SAP_0975';
            cerBiz.Distribution_Channel__c= 'National (SAP_10)';
            cerBiz.ID_Level__c= 'ÁGR';
            cerBiz.Agreement_number__c = '23456';
            cerBiz.Customer_Number__c = '56789';
            cerBiz.Product_number__c = '12345';
            cerBiz.List_Price__c = '12';
            cerBiz.Net_Price_Incl_Indirect_Tax__c = '15';
            cerBiz.Customer_Currency__c = 'DKK';
            cerBiz.Base_unit_of_measure__c = 'SAP_BX';
            cerBiz.Discount_in_customer_currency__c = '20';
            cerBiz.Indirect_tax_amount_in_customer_currency__c = '10';
            cerBiz.Status__c = 'New';
            cerBiz.isExecuted__c = true;
            insert cerBiz;            

            APTS_PurgeCERBizIslandBufferData deleteCERBiz = new APTS_PurgeCERBizIslandBufferData();
            Database.executeBatch(deleteCERBiz, 200);
            Test.stopTest();
       }
    }