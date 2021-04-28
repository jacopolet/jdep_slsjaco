/**********************************************************************************
 * @Author: Lavanya Ravindran
 * @Company: Accenture
 * @Description: Test class For APTS_AgreementLineItemBizIsland 
 * @Created Date: Oct 4, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Lavanya              10.10.2018       Created
 **********************************************************************************/

@isTest
private class APTS_AgreementLineItemBizIslandTest {
    
   
   
   
   
   @testSetup
 static void testData()
   {
        String indirecttaxamt;
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
        Database.insert(prod1);
        
        Apttus_Config2__PriceList__c  PriceList = APTS_TestDataFactory.createPriceList('testpricelist');
        PriceList.APTS_Region__c='SAP_0975';
        PriceList.APTS_PriceList_Type__c= 'CSP';
        Database.insert(priceList);
        
        APTS_Sales_Org_Data__c sales = new APTS_Sales_Org_Data__c();
        sales.APTS_Distribution_channel__c='SAP_10';
        insert sales;

        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        priceListItem.Apttus_Config2__PriceUom__c=' SAP_PCE';
        priceListItem.APTS_TAX_DK_specific_UOM__c=10;
        priceListItem.APTS_Related_sales_org_data__c=sales.id;
        Database.insert(priceListItem);
        
                Apttus__APTS_Agreement__c agree=APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
        agree.APTS_Region__c='SAP_0975';
        agree.Apttus__Status_Category__c='In Effect';
        agree.Apttus__Status__c='Activated';
        agree.APTS_Distribution_Channel__c = 'National (SAP_10)';
        agree.Apttus__Contract_End_Date__c= Date.Today() ;
        Database.insert(agree); 
        
        List <Apttus__AgreementLineItem__c> agreementLineList = new List <Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c agreementLine = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        agreementLine.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine.Apttus_CMConfig__LineType__c ='Option'; 
        agreementLine.Apttus__Quantity__c=5;
        //agreementLine.Apttus_CMConfig__HasOptions__c =false;
        agreementLine.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine.Apttus__AgreementId__c= agree.id;
        agreementLine.Apttus__NetPrice__c=1500;
        agreementLine.Apttus__ExtendedPrice__c=1500;
        agreementLine.Apttus_CMConfig__SellingUom__c='SAP_BX';
        agreementLineList.add(agreementLine);

        Apttus__AgreementLineItem__c agreementLine1 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        agreementLine1.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine1.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine1.Apttus_CMConfig__HasOptions__c =false;
        agreementLine1.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine1.Apttus__NetPrice__c=1500;
        agreementLine1.Apttus__ExtendedPrice__c=1500;
        agreementLine1.Apttus_CMConfig__SellingUom__c='SAP_BX';
        agreementLine1.CreatedDate = Date.Today()-1;
        agreementLine1.LastModifiedDate = Date.Today();
        agreementLine1.Apttus__AgreementId__c= agree.id;
        
      
        agreementLineList.add(agreementLine1);
        Database.insert(agreementLineList);
        
        Apttus_Config2__FrequencyConversionRate__c freq=new Apttus_Config2__FrequencyConversionRate__c();
        freq.Apttus_Config2__ProductId__c=prod1.id;
        freq.Apttus_Config2__FromFrequency__c='Hourly';
        freq.Apttus_Config2__FromUom__c='SAP_PCE';
        freq.Apttus_Config2__ToUom__c='SAP_BX';
        freq.Apttus_Config2__ConversionFactor__c=25;
        insert freq;
        
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
       APTS_AgreementLineItemBizIsland instBatch = new APTS_AgreementLineItemBizIsland();
       Database.executeBatch(instBatch, 200);
        Test.stopTest();
       }
        
       @isTest
        static void testBatch(){
            Test.startTest();
           APTS_AgreementLineItemBizIsland instBatch = new APTS_AgreementLineItemBizIsland();
           Database.executeBatch(instBatch, 200);
            Test.stopTest();
       }
    }