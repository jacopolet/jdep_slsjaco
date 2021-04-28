@isTest
private class APTS_AssetMovementTxCEDUpdQueueableTest {
    
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
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
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
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
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
      //testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      //testDataB.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataB);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_005;
    insert bs_005;
    update listUpdateAssetLineItem_0005;  
  
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
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
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
      //testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      //testDataB.APTS_Contract_Effective_Date__c = Date.today();
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
      tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
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
      //testDataA.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataA);
      
      RTR_LAE_Transaction_Data__c testDataB = new RTR_LAE_Transaction_Data__c();
      testDataB.APTS_Asset_Line_Item__c = tstAssetPos.Id;
      testDataB.APTS_Business_Transaction_Type__c = 'B005';
      //testDataB.APTS_Contract_Effective_Date__c = Date.today();
      lstTransData.add(testDataB);
            mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
    }
    
    insert lstALIHis_Neg2_005;
    insert bs_Neg2_005;
    update listUpdateAssetLineItem_Neg2_0005;  

    
    Insert lstTransData;

    }

   static testMethod void testQueueable(){
    
       Test.startTest();
       System.enqueueJob(new APTS_AssetMovementTxCEDUpdateQueueable());
       Test.stopTest();
  }

   static testMethod void testSchedulable(){
      APTS_AssetMovementTxCEDSchedulable schClass = new APTS_AssetMovementTxCEDSchedulable();
      string sch = '0 0 23 * * ?';
      Test.startTest();
      string jobId = System.schedule('Transaction Update', sch, schClass);
      Test.stopTest();
   }
}