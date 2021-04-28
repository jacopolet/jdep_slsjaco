/*************************************************************
@Name: APTS_ProcessStagingTest
@Author: Mahesh Chilaka
@CreateDate: 30-08-2019
@Description: 
@UsedBy: 
******************************************************************/

@isTest
private class APTS_ProcessStagingTest {
    

  @testSetup
    static void testSetup(){

    TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;        
        insert objTriggerSettings; 

      Account account = APTS_TestUtils.createaccount();
        account.Duplicate_Reason__c = 'Office building';
        account.Mini_Company_Code__c = 'SAP_0079';    
        Database.insert(account);

        account.SAP_Customer_ID__c = '2423';
        account.Distribution_Channel__c = 'SAP_10';
        account.Sales_Organization__c = 'SAP_0111';
        Database.update(account);
    
      Product2 prod = APTS_TestUtils.createProduct('Test Product', 'P-0001', 'SAP_01');
          Database.insert(prod);
      prod.APTS_Option_Group_Indicator__c = '0102';
      update prod;
    
      Apttus_Config2__PriceList__c prcLst = APTS_TestUtils.createPriceList(); 
        Database.insert(prcLst);
        
        system.assert(prcLst.Id != null);
        
        Id consumRecType = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        system.assert(consumRecType  != null);
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.recordtypeid = consumRecType ;
        agreement.Name = 'Agreement';
        agreement.Apttus__Agreement_Category__c = 'Sales';
        agreement.Apttus_CMConfig__PriceListId__c = prcLst.Id;
        agreement.APTS_Fixed_Term_Type__c = 'Fixed Cost'; 
        agreement.Apttus__Agreement_Number__c = '1124';
        
        insert agreement;
    
      Apttus__APTS_Agreement__c agreement2 = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId(),
        Name = 'Agreement',
        Apttus__Agreement_Category__c = 'Sales',
        Apttus_CMConfig__PriceListId__c = prcLst.Id,
        APTS_Fixed_Term_Type__c = 'Fixed Cost', Apttus__Agreement_Number__c = '1134');
        insert agreement2;
    
      PhysicalAsset__c testPhysicalAsset = APTS_TestUtils.createPhysicalAsset();
        testPhysicalAsset.InitialActivationDate__c = Date.today().addDays(-30);    
        Database.insert(testPhysicalAsset, false);



        // Assert APTS_Is_Primary_L1_Asset__c       
      Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>();  
      List<Apttus_Config2__AssetLineItem__c> listAssetLineItem_PriL1 = new List <Apttus_Config2__AssetLineItem__c>();    
      for(integer i=0; i<10; i++){
        Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
        tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
        tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
        tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
        tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
        if(math.mod(i, 2) == 0) {
        tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
        }else {
        tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
        }
        tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
        tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
        tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
        tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
        tstAssetPos.APTS_Asset_Validaton_Error__c = false;
        tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
        tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
        tstAssetPos.Apttus_Config2__Quantity__c = 10;
        tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
        tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;      
        tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
        tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
        tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
        tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
        tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';   
        
        listAssetLineItem_PriL1.add(tstAssetPos);
              
      }

        insert listAssetLineItem_PriL1;

    
    // New Asset creation for Sales/Rent
    List<Apttus_Config2__AssetLineItem__c> listAssetLineItem = new List <Apttus_Config2__AssetLineItem__c>();
    List<Apttus_Billing__BillingSchedule__c> bs = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Billing__BillingSchedule__c> bs_2 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Billing__BillingSchedule__c> bs_3 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis = new List<Apttus_Config2__AssetTransactionHistory__c>();
    List<RTR_LAE_Transaction_Data__c> lstTransData = new List<RTR_LAE_Transaction_Data__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
     // tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
   if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
    }else {
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement2.id;
    }
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Option';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
      tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Pending Activation';   
      
      listAssetLineItem.add(tstAssetPos);
    }
    
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Rental Fee';
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Rent';
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
      tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Pending Activation';  
      
      listAssetLineItem.add(tstAssetPos);
    }
    
    insert listAssetLineItem;
    
    for(Apttus_config2__AssetLineItem__c tstAssetPos : listAssetLineItem){
      
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'New';
      lstALIHis.add(newH);
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testData.APTS_Business_Transaction_Type__c = '0001';
      testData.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testData);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
     
     
     insert bs;
     insert lstALIHis;
     update listAssetLineItem;
     
    integer icount = 1;
    for(Apttus_config2__AssetLineItem__c tstAssetPos : listAssetLineItem){
    
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + icount++;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_2.add(bilScdl);

    }
    insert bs_2;
    

    for(Apttus_config2__AssetLineItem__c tstAssetPos : listAssetLineItem){
    
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + icount++;
      bilScdl.APTS_Agreement__c = agreement2.id;
      //insert bilScdl;
      bs_3.add(bilScdl);

    }
    insert bs_3;

    //Create new Asset and update of Sales/Rent... 0003
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_0003 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_003 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_003 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
      tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Pending Activation';   
      
      listUpdateAssetLineItem_0003.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_0003;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_0003){      
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(465);  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_003.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_003.add(newH);
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testData.APTS_Business_Transaction_Type__c = '0003';
      testData.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testData);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_003;
    insert bs_003;
    update listUpdateAssetLineItem_0003;
    
    
    
    //Create new Asset and update of Sales/Rent... 0002
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_0002 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_002 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_002 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
            tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      
      listUpdateAssetLineItem_0002.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_0002;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_0002){      
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(265);  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_002.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_002.add(newH);
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testData.APTS_Business_Transaction_Type__c = '0002';
      testData.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testData);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_002;
    insert bs_002;
    update listUpdateAssetLineItem_0002;
    

    //Create new Option Asset and Update of Sales/Rent ....0003  
    // Assert APTS_Is_Primary_L1_Asset__c       
        //Map<Id, Apttus_Config2__AssetLineItem__c> mapAssetLineItem = new Map<Id, Apttus_Config2__AssetLineItem__c>();  
        List<Apttus_Config2__AssetLineItem__c> listAssetLineItem_PriLOption1 = new List <Apttus_Config2__AssetLineItem__c>();    
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;      
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';   
      
      listAssetLineItem_PriLOption1.add(tstAssetPos);
            
    }

        insert listAssetLineItem_PriLOption1;


    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItemOption_0003 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bsOption_003 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHisOption_003 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Rental Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Option';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      //tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
            tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriLOption1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__OptionId__c = prod.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';   
      
      listUpdateAssetLineItemOption_0003.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItemOption_0003;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItemOption_0003){      
      //tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(465);  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bsOption_003.add(bilScdl);
      /*
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_003.add(newH);
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testData.APTS_Business_Transaction_Type__c = '0003';
      testData.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testData);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
      */
    }
    
    //insert lstALIHisOption_003;
    insert bsOption_003;
    //update listUpdateAssetLineItemOption_0003;
    
    
    
    
    
    //Create new Asset and update of Sales/Rent... 0004
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_0004 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_004 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_004 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Rental Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      //tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
            tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__NetPrice__c = 1200;  
      
      listUpdateAssetLineItem_0004.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_0004;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_0004){      
      tstAssetPos.Apttus_Config2__NetPrice__c = 1211;  
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_004.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Amend';
      lstALIHis_004.add(newH);
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testData.APTS_Business_Transaction_Type__c = '0004';
      testData.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testData);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_004;
    insert bs_004;
    update listUpdateAssetLineItem_0004;
    
    
    
    
    //Create new Asset and update of Sales/Rent... A005 and B005
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_0005 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_005 = new List<Apttus_Billing__BillingSchedule__c>();
    List <Apttus_Billing__BillingSchedule__c> contractChangebs_005 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_005 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';      
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      //tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
            tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__NetPrice__c = 1200;  
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';
      
      listUpdateAssetLineItem_0005.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_0005;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_0005){      
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement2.id;
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement2.id;
      //insert bilScdl;
      bs_005.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_005.add(newH);
      
      RTR_LAE_Transaction_Data__c testDataA = new RTR_LAE_Transaction_Data__c();
      testDataA.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataA.APTS_Business_Transaction_Type__c = 'A005';
      testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      testDataB.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataB);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_005;
    insert bs_005;
    update listUpdateAssetLineItem_0005;  
    
    // Contract change on Asset Line Item.
  /*  integer countI = 0;
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listAssetLineItem_PriL1){      
      
      
      if(countI <= 5){
        tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement2.id;
        
        Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
        //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
        //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
        bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
        bilScdl.APTS_AddToExternalOrderlineItem__c = false;
        bilScdl.Apttus_Billing__FeeAmount__c = 250;
        //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
        bilScdl.Apttus_Billing__Type__c = 'Contracted';
        bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
        bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
        bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
        bilScdl.APTS_Agreement__c = agreement2.id;
        //insert bilScdl;
        contractChangebs_005.add(bilScdl);
        }
      countI++;
      
    }

    insert contractChangebs_005;
    update listAssetLineItem_PriL1;
    */

        /******* Negative Scenario  ***/

        //Create new Asset and update of Sales/Rent... A005 and B005
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_Neg_0005 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_Neg_005 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_Neg_005 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';
            
      listUpdateAssetLineItem_Neg_0005.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_Neg_0005;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_Neg_0005){      
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement2.id;
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_Neg_005.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      //newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_005.add(newH);
      
      RTR_LAE_Transaction_Data__c testDataA = new RTR_LAE_Transaction_Data__c();
      testDataA.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataA.APTS_Business_Transaction_Type__c = 'A005';
      testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      testDataB.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataB);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_Neg_005;
    insert bs_Neg_005;
    update listUpdateAssetLineItem_Neg_0005;  


         //Create new Asset and update of Sales/Rent... A005 and B005
    List<Apttus_Config2__AssetLineItem__c> listUpdateAssetLineItem_Neg2_0005 = new List <Apttus_Config2__AssetLineItem__c>();
    List <Apttus_Billing__BillingSchedule__c> bs_Neg2_005 = new List<Apttus_Billing__BillingSchedule__c>();
    List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_Neg2_005 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      
      if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
      }
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
            
      listUpdateAssetLineItem_Neg2_0005.add(tstAssetPos);
    }
    
    insert listUpdateAssetLineItem_Neg2_0005;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_Neg2_0005){      
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement2.id;
      
      Apttus_Billing__BillingSchedule__c bilScdl = new Apttus_Billing__BillingSchedule__c ();
      //bilScdl.Apttus_Billing__BillToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.APTS_Is_Primary_L1_Asset__c;
            //bilScdl.Apttus_Billing__AssetLineItemId__c = tstAssetPos.Id;
      bilScdl.APTS_AddToExternalOrderlineItem__c = false;
      bilScdl.Apttus_Billing__FeeAmount__c = 250;
      //bilScdl.Apttus_Billing__ShipToAccountId__c = account0.Id;
      bilScdl.Apttus_Billing__Type__c = 'Contracted';
      bilScdl.Apttus_Billing__Status__c = 'Pending Invoiced';
      bilScdl.Apttus_Billing__PeriodStartDate__c = System.today();
      bilScdl.Apttus_Billing__PeriodEndDate__c = System.today() + 15;
      bilScdl.APTS_Agreement__c = agreement.id;
      //insert bilScdl;
      bs_Neg_005.add(bilScdl);
      
      Apttus_Config2__AssetTransactionHistory__c newH = new Apttus_Config2__AssetTransactionHistory__c();
      //newH.Apttus_Config2__AssetLineItemId__c = tstAssetPos.Id;
      newH.Apttus_Config2__Action__c = 'Renew';
      lstALIHis_005.add(newH);
      
      RTR_LAE_Transaction_Data__c testDataA = new RTR_LAE_Transaction_Data__c();
      testDataA.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataA.APTS_Business_Transaction_Type__c = 'A005';
      testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      testDataB.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataB);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_Neg2_005;
    insert bs_Neg2_005;
    update listUpdateAssetLineItem_Neg2_0005;  

    
    Insert lstTransData;

    // Create Staging Data records
    List<RTR_LAE_Staging_Data__c> lstStageData = new List<RTR_LAE_Staging_Data__c>();
    for(RTR_LAE_Transaction_Data__c transData : lstTransData) {

        Apttus_Config2__AssetLineItem__c assetLI = mapAssetLineItem.get(transData.APTS_Asset_Line_Item__c);

        RTR_LAE_Staging_Data__c newStageData = new RTR_LAE_Staging_Data__c();
        newStageData.APTS_Asset_Line_Item__c = transData.APTS_Asset_Line_Item__c;
        newStageData.APTS_Business_Transaction_Type__c = transData.APTS_Business_Transaction_Type__c;
        newStageData.APTS_Contractual_Purchase__c = transData.APTS_Contractual_Purchase__c;
        newStageData.APTS_Contract_End_Date__c = assetLI.Apttus_Config2__EndDate__c;
        newStageData.APTS_Contract_Effective_Date__c = transData.APTS_Contract_Effective_Date__c;

        if(mapAssetLineItem.get(assetLI.Id).APTS_MigrationDate__c != null){
            newStageData.APTS_Contract_Start_Date__c = assetLI.Apttus_Config2__EndDate__c;
            newStageData.APTS_Due_Date__c = assetLI.Apttus_Config2__EndDate__c;
        }
        else {
            newStageData.APTS_Contract_Start_Date__c = assetLI.Apttus_Config2__BillingStartDate__c;
            newStageData.APTS_Due_Date__c = assetLI.Apttus_Config2__BillingStartDate__c;
        }

        
            newStageData.APTS_Contract_End_Date__c = assetLI.Apttus_Config2__EndDate__c;
        
        
        newStageData.APTS_Start_Date__c = assetLI.Apttus_Config2__OriginalStartDate__c;
        newStageData.APTS_NetPrice_Amount__c = 100;
        newStageData.APTS_Gross_Amount__c =  200;
        newStageData.APTS_Contract_Number__c = assetLI.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c;
        newStageData.APTS_Customer__c = assetLI.Apttus_Config2__AccountId__r.SAP_Customer_ID__c;
        newStageData.APTS_Company_Code__c = assetLI.Apttus_Config2__AccountId__r.Mini_Company_Code__c;
        newStageData.APTS_Physical_Asset__c = assetLI.APTS_Physical_Asset__c;
    
        lstStageData.add(newStageData);
      }

    insert lstStageData;


    // Create Staging Data records for APTS_TransStageDataUpdateJob
        List<RTR_LAE_Staging_Data__c> lstStageDataUpdate = new List<RTR_LAE_Staging_Data__c>();
    List<RTR_LAE_Transaction_Data__c> lstTransDataUpdate = new List<RTR_LAE_Transaction_Data__c>();

        for(RTR_LAE_Transaction_Data__c transData : lstTransData) {
           
      RTR_LAE_Transaction_Data__c transDataUpdate = new RTR_LAE_Transaction_Data__c();
            RTR_LAE_Staging_Data__c newStageDataUpdate = new RTR_LAE_Staging_Data__c();

            newStageDataUpdate.APTS_Asset_Line_Item__c = transData.APTS_Asset_Line_Item__c;
      newStageDataUpdate.APTS_Business_Transaction_Type__c = '0001';
            transDataUpdate.APTS_Asset_Line_Item__c = transData.APTS_Asset_Line_Item__c;
        
            lstStageDataUpdate.add(newStageDataUpdate);
      lstTransDataUpdate.add(transDataUpdate);
        }

    insert lstTransDataUpdate;
    insert lstStageDataUpdate;
    
    List<RTR_LAE_Transaction_Data__c> lstTransDataRec = [SELECT Id,APTS_Contract_Effective_Date__c FROM RTR_LAE_Transaction_Data__c];
    for(RTR_LAE_Transaction_Data__c transDataRec : lstTransDataRec){
      transDataRec.APTS_Contract_Effective_Date__c = Date.today();
    }
    
    update lstTransDataRec;


  APTS_RTR_Scheduler_Query__c schQuery = new APTS_RTR_Scheduler_Query__c(); 
  schQuery.APTS_Contract_Effective_Start_Date__c = Date.today();
  schQuery.APTS_Contract_Effective_End_Date__c = Date.today();             
  schQuery.APTS_Company_Code__c = 'SAP_0079';
  schQuery.APTS_Business_Transaction_Type__c = 'A005,B005,0004';
  schQuery.APTS_Type_of_Contract__c = 'typeofContract';
  schQuery.APTS_Agreement_Number__c = '0005016125';
  schQuery.APTS_Finance_ID__c = '0001024791';
  schQuery.Asset_Line_Item_Number__c = String.valueOf(listUpdateAssetLineItem_Neg2_0005[0].Id);
  schQuery.APTS_LAE_RAR_Transaction_ID__c = 'a9p1x0000004Jt6AAE';
  schQuery.APTS_Controlled_Interface_Flag__c = true;
  schQuery.isDataValidated__c = true;
  schQuery.isBatchableRequest__c = true;

  insert schQuery;


   //  Asset Data validation.

    //Create new Asset and update of Sales/Rent... 0004
    List<Apttus_Config2__AssetLineItem__c> validateAsset_0004 = new List <Apttus_Config2__AssetLineItem__c>();
    List<RTR_LAE_Transaction_Data__c> lstALIHisVA_004 = new List<RTR_LAE_Transaction_Data__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      //tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
     /* if(math.mod(i, 2) == 0) {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
      }else {
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Rental Fee';
      }*/
      //tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      //tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Sales';
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      //tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
      tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      //tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      //tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      //tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__NetPrice__c = 1200;  
      
      validateAsset_0004.add(tstAssetPos);
    }

    insert validateAsset_0004;
    
    for(Apttus_Config2__AssetLineItem__c tstAssetPos : listUpdateAssetLineItem_0004){      
      tstAssetPos.Apttus_Config2__NetPrice__c = 1211;  
      
      
      
      RTR_LAE_Transaction_Data__c testData = new RTR_LAE_Transaction_Data__c();
      testData.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      //testData.APTS_Business_Transaction_Type__c = '0004';
      //testData.APTS_Contract_Effective_Date__c = Date.today();
      lstALIHisVA_004.add(testData);      
    }
    
    insert lstALIHisVA_004;
   // APTS_ProcessStaging oBatch = new APTS_ProcessStaging();
   // Database.executebatch(oBatch);


    //Create new Asset for validateDeinstallation_OriginalStartDate.
    List<Apttus_Config2__AssetLineItem__c> listCreateAssetLineItems = new List <Apttus_Config2__AssetLineItem__c>();
   // List <Apttus_Billing__BillingSchedule__c> bs_003 = new List<Apttus_Billing__BillingSchedule__c>();
   // List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_003 = new List<Apttus_Config2__AssetTransactionHistory__c>();
    for(integer i=0; i<10; i++){
      Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
      tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(365);
      tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
      tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today().addDays(-1);
      
      tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
     
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;tstAssetPos.APTS_Financial_Agreement__c = agreement.id;
      tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
      tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
      tstAssetPos.APTS_Type_Of_Contract__c = 'Rent';
      tstAssetPos.APTS_Asset_Validaton_Error__c = false;
      tstAssetPos.APTS_Is_Primary_L1_Line__c = true;
      tstAssetPos.Apttus_Config2__IsPrimaryLine__c  = true;
      tstAssetPos.Apttus_Config2__BasePrice__c = 10.00;
      tstAssetPos.Apttus_Config2__Quantity__c = 10;
      tstAssetPos.Apttus_Config2__SellingTerm__c = 1;
      tstAssetPos.Apttus_Config2__ListPrice__c = 10.00;
      tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
      tstAssetPos.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
      tstAssetPos.Apttus_Config2__AccountId__c = account.Id;
      tstAssetPos.Apttus_Config2__ProductId__c = prod.Id;
      tstAssetPos.Apttus_Config2__BillingStartDate__c = Date.today();
      tstAssetPos.Apttus_Config2__PriceListId__c = prcLst.Id;
      tstAssetPos.Apttus_Config2__AssetStatus__c = 'Activated';   
      
      listCreateAssetLineItems.add(tstAssetPos);
    }
    
    insert listCreateAssetLineItems;

  }
  
  static testMethod void testBatch(){
    
    Test.startTest();
    RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
    APTS_ProcessStaging oBatchDate = new APTS_ProcessStaging(Date.Today().addDays(-1));
    oBatchDate.createStagingRecord(transData);
    //APTS_ProcessStaging oBatch = new APTS_ProcessStaging();
    //Database.executebatch(oBatch);

    Map<Id, RTR_LAE_Staging_Data__c> mapStageData = new Map<Id, RTR_LAE_Staging_Data__c>([SELECT Id FROM RTR_LAE_Staging_Data__c]);
    System.assert(mapStageData.size() > 0);
    APTS_IntegationLogJob integrJob = new APTS_IntegationLogJob(mapStageData, Date.Today());     

    /*APTS_TransStagingDataUpdateJob transStageBatchInit = new APTS_TransStagingDataUpdateJob('SELECT Id FROM RTR_LAE_Staging_Data__c'); 
    APTS_TransStagingDataUpdateJob transStageBatch = new APTS_TransStagingDataUpdateJob();   
        Database.executeBatch(transStageBatch); */

    Test.stopTest();
  }

  static testMethod void testBatchNegitive(){
    
    Test.startTest();  
     Set<Id> setAssetId = new Set<Id>();
    Map<Id, Decimal> mapGross = new Map<Id, Decimal>();
    Map<Id, Decimal> mapNet = new Map<Id, Decimal>();
    Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
        Set<String> setSchBusinesstype = new Set<String>{'0001','0002','0003','0004','A005','B005'};

    String lineType = 'Product/Service';
    List<RTR_LAE_Transaction_Data__c> lstTransDataRec = [SELECT Id,APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.Name,APTS_Contract_Effective_Date__c,APTS_Contractual_Purchase__c,APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c,APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_MigrationDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__BillingStartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__StartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Distribution_Channel__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.ProductCode,APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c,APTS_Asset_Line_Item__r.APTS_Installation_Sales_Order_Item__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Sales_Organization__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__c,APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c, APTS_Asset_Line_Item__r.APTS_RAR_LAE_OriginalStartDate__c, APTS_Asset_Line_Item__r.APTS_Financial_Start_Date__c,Service_Installation_Override__c,Error_Description__c,APTS_Asset_Line_Item__r.APTS_Contract_Change__c,APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Processed__c,APTS_Business_Transaction_Type__c,APTS_Asset_Line_Item__c, Error_in_Processing__c  from  RTR_LAE_Transaction_Data__c ];  
     for(RTR_LAE_Transaction_Data__c trnD : lstTransDataRec ){
          setAssetId.add(trnD.APTS_Asset_Line_Item__c);
        }
    RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
    APTS_ProcessStaging oBatchDate = new APTS_ProcessStaging(Date.Today().addDays(-1));
    oBatchDate.createStagingRecord(transData);
    oBatchDate.getAllTransactionData(setAssetId,setSchBusinesstype);
    APTS_ProcessStaging oBatch = new APTS_ProcessStaging();
    oBatch.remainingUsefulLife(lstTransDataRec);
        
        
   List<RTR_LAE_Transaction_Data__c> newlistlae=new List<RTR_LAE_Transaction_Data__c>();
   newlistlae=[SELECT Id, APTS_Asset_Line_Item__r.APTS_Asset_Line_Item_Number__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Mini_Company_Code__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.Name,APTS_Contract_Effective_Date__c,APTS_Contractual_Purchase__c,APTS_Asset_Line_Item__r.Apttus_Config2__EndDate__c,APTS_Asset_Line_Item__r.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,APTS_Asset_Line_Item__r.APTS_Financial_Agreement__r.Apttus__Agreement_Number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.InitialActivationDate__c,APTS_Asset_Line_Item__r.APTS_MigrationDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__BillingStartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__StartDate__c,APTS_Asset_Line_Item__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Distribution_Channel__c,APTS_Asset_Line_Item__r.Apttus_Config2__ProductId__r.ProductCode,APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c,APTS_Asset_Line_Item__r.APTS_Type_Of_Contract__c,APTS_Asset_Line_Item__r.APTS_Installation_Sales_Order_Item__c,APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r.Sales_Organization__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.APTS_FinanceId__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.ActiveWarranty__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.WarrantyStartDate__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__r.Warranty__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c,APTS_Asset_Line_Item__r.APTS_Physical_Asset__c,APTS_Asset_Line_Item__r.Apttus_Config2__OriginalStartDate__c,Service_Installation_Override__c,Error_Description__c,APTS_Asset_Line_Item__r.APTS_Contract_Change__c,APTS_Asset_Line_Item__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_PHA_serial_number__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Terminated_Physical_Asset__c,APTS_Asset_Line_Item__r.APTS_RAR_LAE_OriginalStartDate__c, APTS_Asset_Line_Item__r.APTS_Financial_Start_Date__c,APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__r.APTS_Term_PHA_Initial_Activation_Date__c,APTS_Asset_Line_Item__c,APTS_Business_Transaction_Type__c FROM RTR_LAE_Transaction_Data__c WHERE APTS_Asset_Processed__c = false AND isDeleted = false AND Error_in_Processing__c = false AND APTS_Asset_Line_Item__c != null AND APTS_Asset_Line_Item__r.Apttus_Config2__ChargeType__c IN : setChargeType AND APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c =: lineType LIMIT 40000];
   APTS_ProcessStaging oBatch1 = new APTS_ProcessStaging();
   oBatch1.validateTransData(newlistlae, mapGross, mapNet);
   oBatch1.executeExt(newlistlae,true);
    Database.executeBatch(oBatch1);

   Map<Id, RTR_LAE_Staging_Data__c> mapStageData = new Map<Id, RTR_LAE_Staging_Data__c>([SELECT Id FROM RTR_LAE_Staging_Data__c]);
   System.assert(mapStageData.size() > 0);
   List<Apttus_Config2__AssetLineItem__c> assetLineItemWithStaging = [SELECT ID, (SELECT Id, APTS_Asset_Line_Item__c,  APTS_Serial_Number__c, APTS_Contract_Number__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, 
                                                                                  APTS_Business_Transaction_Type__c FROM Apttus_Integration_Logs__r                                                                                          
                                                                                        ORDER BY CreatedDate DESC LIMIT 1 ) 
                                                                      FROM Apttus_Config2__AssetLineItem__c ];
                                                                      
   APTS_IntegationLogJob integrJob = new APTS_IntegationLogJob();  
   //integrJob.executeExt(assetLineItemWithStaging, true);
  
   List<Apttus_Config2__AssetLineItem__c> assetLineItemWithStaging005 = [SELECT ID, (SELECT Id, APTS_Asset_Line_Item__c,  APTS_Serial_Number__c, APTS_Contract_Number__c, APTS_Asset_Line_Item__r.APTS_Is_Primary_L1_Asset__c, 
                                                                                  APTS_Business_Transaction_Type__c FROM Apttus_Integration_Logs__r  WHERE APTS_Business_Transaction_Type__c = 'B005'                                                                                        
                                                                                        ORDER BY CreatedDate DESC LIMIT 1 ) 
                                                                      FROM Apttus_Config2__AssetLineItem__c ];
  
   //integrJob.executeExt(assetLineItemWithStaging005, true);

    APTS_IntegationLogJob integrJobext = new APTS_IntegationLogJob(mapStageData, Date.today());
    Database.executeBatch(integrJobext);
       
            

    Test.stopTest();
  }

  

  static testMethod void reinterfaceTest(){

    PageReference  pref = Page.APTS_LAE_RAR_Reinterface;
    List<RTR_LAE_Transaction_Data__c> transDataRec = [Select Id from RTR_LAE_Transaction_Data__c Limit 1];
    System.assert(transDataRec.size() > 0);
    pref.getParameters().put('Id',transDataRec[0].Id);
    Test.setCurrentPage(pref);
    APTS_LAE_RAR_Reinterface reinter = new APTS_LAE_RAR_Reinterface();

    Test.startTest();    
    reinter.reInterface();
    Test.stopTest();
  }
  
  static testMethod void stopinterfaceTest(){

    PageReference  pref = Page.APTS_StopLaeInterface;
    List<RTR_LAE_Transaction_Data__c> transDataRec = [Select Id from RTR_LAE_Transaction_Data__c Limit 1];
    System.assert(transDataRec.size() > 0);
    pref.getParameters().put('Id',transDataRec[0].Id);
    Test.setCurrentPage(pref);
    APTS_StopLaeInterface stopinter = new APTS_StopLaeInterface();
    Test.startTest();    
    stopinter.StopLaeInterface();
    Test.stopTest();
  }

  
}