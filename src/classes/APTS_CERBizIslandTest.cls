/**********************************************************************************
 * @Author: Saranya Rajagopal
 * @Company: Accenture
 * @Description: Test class For APTS_CERBizIsland 
 * @Created Date: Jan 09, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Saranya              09.01.2019      Created
 **********************************************************************************/

@isTest
private class APTS_CERBizIslandTest {
    
   
   
   
   
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
        prod1.Family = 'SAP_01';
        Database.insert(prod1);
        
        Apttus_Config2__PriceList__c  PriceList = APTS_TestDataFactory.createPriceList('testpricelist');
        PriceList.APTS_Region__c='SAP_0975';
        PriceList.APTS_PriceList_Type__c= 'Direct';
        PriceList.Apttus_Config2__Active__c = true;
        Database.insert(priceList);
        
        APTS_Sales_Org_Data__c sales = new APTS_Sales_Org_Data__c();
        sales.APTS_Distribution_channel__c='SAP_10';
        insert sales;

        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        priceListItem.Apttus_Config2__PriceUom__c=' SAP_PCE';
        priceListItem.APTS_TAX_DK_specific_UOM__c=10;
        priceListItem.APTS_Related_sales_org_data__c=sales.id;
        priceListItem.Apttus_Config2__ListPrice__c = 12;
        //priceListItem.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        //priceListItem.APTS_Sales_Org__c = 'SAP_0975';

        Apttus_Config2__PriceListItem__c priceListItem2 = APTS_TestDataFactory.createPriceListItem(PriceList.id,prod1.id);
        priceListItem2.Apttus_Config2__PriceUom__c=' SAP_BX';
        priceListItem2.APTS_TAX_DK_specific_UOM__c=10;
        priceListItem2.APTS_Related_sales_org_data__c=sales.id;
        priceListItem2.Apttus_Config2__ListPrice__c = 12;
        //priceListItem.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        //priceListItem.APTS_Sales_Org__c = 'SAP_0975';

        Database.insert(priceListItem);
        Id RecId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        Apttus__APTS_Agreement__c agree=APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
        agree.APTS_Region__c='SAP_0975';
        agree.RecordTypeId = RecId;
        agree.Apttus__Status_Category__c='In Effect';
        agree.Apttus__Status__c='Activated';
        agree.APTS_Distribution_Channel__c = 'National (SAP_10)';
        agree.Apttus__Contract_End_Date__c= Date.Today() ;        
        Database.insert(agree); 
        
        Apttus__APTS_Agreement__c agree2 =APTS_TestDataFactory.createAgreement(con.id,priceList.id,acc.id,'Standard Deal');
        agree2.APTS_Region__c='SAP_0975';
        agree2.RecordTypeId = RecId;
        agree2.Apttus__Status_Category__c='In Effect';
        agree2.Apttus__Status__c='Activated';
        agree2.APTS_Distribution_Channel__c = 'National (SAP_10)';
        agree2.Apttus__Contract_End_Date__c= Date.Today() ;        
        Database.insert(agree2); 
        
        List <Apttus__AgreementLineItem__c> agreementLineList = new List <Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c agreementLine = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        agreementLine.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine.Apttus_CMConfig__LineType__c ='Option'; 
        agreementLine.Apttus__Quantity__c=5;
        agreementLine.Apttus_CMConfig__HasOptions__c =false;
        agreementLine.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine.Apttus__AgreementId__c= agree.id;
        agreementLine.Apttus__NetPrice__c=1500;
        agreementLine.Apttus__ExtendedPrice__c=1500;
        agreementLine.Apttus_CMConfig__SellingUom__c='SAP_PCE';
        agreementLine.Apttus_CMConfig__PriceUom__c = 'SAP_PCE';
 
        agreementLineList.add(agreementLine);

        Apttus__AgreementLineItem__c agreementLine1 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        agreementLine1.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine1.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine1.Apttus_CMConfig__HasOptions__c =false;
        agreementLine1.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine1.Apttus__NetPrice__c=1500;
        agreementLine1.Apttus__ExtendedPrice__c=1500;
        agreementLine1.CreatedDate = Date.Today()-1;
        agreementLine1.LastModifiedDate = Date.Today();
        agreementLine1.Apttus__AgreementId__c= agree.id;
        agreementLine1.Apttus_CMConfig__SellingUom__c='SAP_PCE';
        agreementLine1.Apttus_CMConfig__HasOptions__c =false;
      
        agreementLineList.add(agreementLine1);

         Apttus__AgreementLineItem__c agreementLine12 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        //agreementLine12.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine12.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine12.Apttus_CMConfig__HasOptions__c =false;
        agreementLine12.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine12.Apttus__NetPrice__c=1500;
        agreementLine12.Apttus__ExtendedPrice__c=1500;
        agreementLine12.CreatedDate = Date.Today()-1;
        agreementLine12.LastModifiedDate = Date.Today();
        agreementLine12.Apttus__AgreementId__c= agree.id;
        agreementLine12.Apttus_CMConfig__SellingUom__c='SAP_BX';
        agreementLine12.Apttus_CMConfig__HasOptions__c =false;
        agreementLine12.Apttus_CMConfig__BasePriceOverride__c = 0;
        agreementLine12.Apttus_CMConfig__PriceUom__c = 'SAP_BX';
      
        agreementLineList.add(agreementLine12);
         Apttus__AgreementLineItem__c agreementLine13 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem.id);
        //agreementLine1.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine13.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine13.Apttus_CMConfig__HasOptions__c =false;
        agreementLine13.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine13.Apttus__NetPrice__c=1500;
        agreementLine13.Apttus__ExtendedPrice__c=1500;
        agreementLine13.CreatedDate = Date.Today()-1;
        agreementLine13.LastModifiedDate = Date.Today();
        agreementLine13.Apttus__AgreementId__c= agree.id;
        agreementLine13.Apttus_CMConfig__SellingUom__c='SAP_PCE';
        agreementLine13.Apttus_CMConfig__HasOptions__c =false;
        agreementLine13.Apttus_CMConfig__PriceUom__c = 'SAP_PCE';

        agreementLineList.add(agreementLine13);

        Apttus__AgreementLineItem__c agreementLine14 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree.id,acc.id,priceListItem2.id);
        agreementLine14.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine14.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine14.Apttus_CMConfig__HasOptions__c =false;
        agreementLine14.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine14.Apttus__NetPrice__c=1500;
        agreementLine14.Apttus__ExtendedPrice__c=1500;
        agreementLine14.CreatedDate = Date.Today()-1;
        agreementLine14.LastModifiedDate = Date.Today();
        agreementLine14.Apttus__AgreementId__c= agree.id;
        agreementLine14.Apttus_CMConfig__SellingUom__c='SAP_PCE';
        agreementLine14.Apttus_CMConfig__HasOptions__c =false;
        agreementLine14.Apttus_CMConfig__PriceListItemId__c = priceListItem2.id;
      
        agreementLineList.add(agreementLine14);

        Apttus__AgreementLineItem__c agreementLine15 = APTS_TestDataFactory.createAgreementLineItem(prod1.id,agree2.id,acc.id,priceListItem2.id);
        agreementLine15.Apttus_CMConfig__OptionId__c = prod1.id;
        agreementLine15.Apttus_CMConfig__LineType__c ='Product/Service'; 
        agreementLine15.Apttus_CMConfig__HasOptions__c =false;
        agreementLine15.Apttus_CMConfig__PriceListId__c = PriceList.id;
        agreementLine15.Apttus__NetPrice__c=1500;
        agreementLine15.Apttus__ExtendedPrice__c=1500;
        agreementLine15.CreatedDate = Date.Today()-1;
        agreementLine15.LastModifiedDate = Date.Today();
        agreementLine15.Apttus__AgreementId__c= agree2.id;
        agreementLine15.Apttus_CMConfig__SellingUom__c='SAP_PCE';
        agreementLine15.Apttus_CMConfig__HasOptions__c =false;
        agreementLine15.Apttus_CMConfig__PriceListItemId__c = priceListItem2.id;
      
        agreementLineList.add(agreementLine15);
        

        Database.insert(agreementLineList);
        
        Apttus_Config2__FrequencyConversionRate__c freq=new Apttus_Config2__FrequencyConversionRate__c();
        freq.Apttus_Config2__ProductId__c=prod1.id;
        freq.Apttus_Config2__FromFrequency__c='Hourly';
        freq.Apttus_Config2__FromUom__c='SAP_PCE';
        freq.Apttus_Config2__ToUom__c='SAP_BX';
        freq.Apttus_Config2__ConversionFactor__c=25;
        insert freq;

        Apttus_Config2__FrequencyConversionRate__c freq2=new Apttus_Config2__FrequencyConversionRate__c();
        freq2.Apttus_Config2__ProductId__c=prod1.id;
        freq2.Apttus_Config2__FromFrequency__c='Hourly';
        freq2.Apttus_Config2__FromUom__c='SAP_PCE';
        freq2.Apttus_Config2__ToUom__c='SAP_PCE';
        freq2.Apttus_Config2__ConversionFactor__c=25;
        insert freq2;

        Apttus_Config2__FrequencyConversionRate__c freq3=new Apttus_Config2__FrequencyConversionRate__c();
        freq3.Apttus_Config2__ProductId__c=prod1.id;
        freq3.Apttus_Config2__FromFrequency__c='Hourly';
        freq3.Apttus_Config2__FromUom__c='SAP_BX';
        freq3.Apttus_Config2__ToUom__c='SAP_PF';
        freq3.Apttus_Config2__ConversionFactor__c=25;
        insert freq3;

        
        APTS_Contract_Entitlement_Repository__c cer= new APTS_Contract_Entitlement_Repository__c();
        cer.APTS_Product__c=prod1.id;
        cer.APTS_Agreement_Type__c='Standard Deal';
        cer.APTS_Agreement_Line_Item__c=agreementLineList[1].id;
        cer.CreatedDate = Date.Today()-1;
        cer.LastModifiedDate = Date.Today();
        cer.APTS_Sold_to_Party__c = acc.id;
        
        insert cer;
        
        APTS_Contract_Entitlement_Repository__c cer3= new APTS_Contract_Entitlement_Repository__c();
        cer3.APTS_Product__c=prod1.id;
        cer3.APTS_Agreement_Type__c='Standard Deal';
        cer3.APTS_Agreement_Line_Item__c=agreementLine14.id;
        cer3.CreatedDate = Date.Today()-1;
        cer3.LastModifiedDate = Date.Today();
        cer3.APTS_Sold_to_Party__c = acc.id;
        cer3.APTS_Contributing_Agreement_Level__c = 'Child';
        insert cer3;

        APTS_Contract_Entitlement_Repository__c cer4= new APTS_Contract_Entitlement_Repository__c();
        cer4.APTS_Product__c=prod1.id;
        cer4.APTS_Agreement_Type__c='Standard Deal';
        cer4.APTS_Agreement_Line_Item__c=agreementLine14.id;
        cer4.CreatedDate = Date.Today()-1;
        cer4.LastModifiedDate = Date.Today();
        cer4.APTS_Sold_to_Party__c = acc.id;
        cer4.APTS_Contributing_Agreement_Level__c = 'Child';
        insert cer4;

        APTS_Contract_Entitlement_Repository__c cer5= new APTS_Contract_Entitlement_Repository__c();
        cer5.APTS_Product__c=prod1.id;
        cer5.APTS_Agreement_Type__c='Standard Deal';
        cer5.APTS_Agreement_Line_Item__c=agreementLine14.id;
        cer5.CreatedDate = Date.Today()-1;
        cer5.LastModifiedDate = Date.Today();
        cer5.APTS_Sold_to_Party__c = acc.id;
        cer5.APTS_Contributing_Agreement_Level__c = 'Parent';
        insert cer5;

        APTS_Contract_Entitlement_Repository__c cer2= new APTS_Contract_Entitlement_Repository__c();
        cer2.APTS_Product__c=prod1.id;
        cer2.APTS_Agreement_Type__c='Standard Deal';
        cer2.APTS_Agreement_Line_Item__c=agreementLine14.id;
        cer2.CreatedDate = Date.Today()-1;
        cer2.LastModifiedDate = Date.Today();
        cer2.APTS_Sold_to_Party__c = acc.id;
        
        insert cer2;

        APTS_Contract_Entitlement_Repository__c cer6= new APTS_Contract_Entitlement_Repository__c();
        cer6.APTS_Product__c=prod1.id;
        cer6.APTS_Agreement_Type__c='Standard Deal';
        cer6.APTS_Agreement_Line_Item__c=agreementLine13.id;
        cer6.CreatedDate = Date.Today()-1;
        cer6.LastModifiedDate = Date.Today();
        cer6.APTS_Sold_to_Party__c = acc.id;
        
        insert cer6;

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
        APTS_CERBizIsland instBatch  = new APTS_CERBizIsland();
        Database.executeBatch(instBatch, 200);
        Test.stopTest();
       }
       
       @isTest
        static void testElseBatchtrue(){
        Bonsai__c customSetting = Bonsai__c.getAll().values();
        customSetting.Delta_Load__c = false;
        customSetting.Full_Load__c = true;
        update customSetting;
       
        Test.startTest();
        APTS_CERBizIsland instBatch  = new APTS_CERBizIsland();
        Database.executeBatch(instBatch, 200);
        Test.stopTest();
       }
        
       @isTest
        static void testBatch(){
            Test.startTest();
            APTS_CERBizIsland instBatch = new APTS_CERBizIsland(); 
            Database.executeBatch(instBatch, 200);
            Test.stopTest();
       }
    }