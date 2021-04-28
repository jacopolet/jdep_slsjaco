/*************************************************************
@Name: APTS_UpdateFinancialStartDateQueueable
@Author: Mahesh Chilaka
@CreateDate: 09-09-2020
@Description: DQ-369 - This queueable job is used to updated the FinancialStartDate on Assets when an Asset Movement successfully moved to RAR/LAE (SAP).
@UsedBy: 
******************************************************************/
@isTest
private  class APTS_UpdateFinancialStartDateQueueTest {
    
    @testSetup
    static void testSetup(){
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
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId(),
            Name = 'Agreement',
            Apttus__Agreement_Category__c = 'Sales',
            Apttus_CMConfig__PriceListId__c = prcLst.Id,
            APTS_Fixed_Term_Type__c = 'Fixed Cost', Apttus__Agreement_Number__c = '1124');
        
            insert agreement;
        
        Apttus__APTS_Agreement__c agreement2 = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId(),
            Name = 'Agreement',
            Apttus__Agreement_Category__c = 'Sales',
            Apttus_CMConfig__PriceListId__c = prcLst.Id,
            APTS_Fixed_Term_Type__c = 'Fixed Cost');
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
          tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(-2);
          tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
          tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today();
          if(math.mod(i, 2) == 0) {
          tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
          }else {
          tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
          }
          tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
          tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
          tstAssetPos.Apttus_Config2__LineType__c = 'Product/Service';
          tstAssetPos.APTS_Type_Of_Contract__c = 'Rent';
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
          tstAssetPos.Apttus_Config2__AssetStatus__c = 'Pending Activation';   
          
          listAssetLineItem_PriL1.add(tstAssetPos);
                
        }
    
            insert listAssetLineItem_PriL1;
    
        
        // New Asset creation for Sales/Rent
        List<Apttus_Config2__AssetLineItem__c> listAssetLineItem = new List <Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Billing__BillingSchedule__c> bs = new List<Apttus_Billing__BillingSchedule__c>();
        List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis = new List<Apttus_Config2__AssetTransactionHistory__c>();
        List<RTR_LAE_Transaction_Data__c> lstTransData = new List<RTR_LAE_Transaction_Data__c>();
        List<RTR_LAE_Staging_Data__c> lstStagingData = new List<RTR_LAE_Staging_Data__c>();
        for(integer i=0; i<10; i++){
          Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
          tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
          tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(-2);
          tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
          tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today();
          if(math.mod(i, 2) == 0) {
          tstAssetPos.Apttus_Config2__ChargeType__c = 'Sales Price';
          }else {
          tstAssetPos.Apttus_Config2__ChargeType__c = 'Service Fee';
          }
          tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
          tstAssetPos.APTS_Physical_Asset__c = testPhysicalAsset.id;
          tstAssetPos.Apttus_Config2__LineType__c = 'Option';
          tstAssetPos.APTS_Type_Of_Contract__c = 'Rent';
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
          tstAssetPos.Apttus_Config2__AssetStatus__c = 'Pending Activation';   
          
          listAssetLineItem.add(tstAssetPos);
        }
        
        for(integer i=0; i<10; i++){
          Apttus_Config2__AssetLineItem__c tstAssetPos = new Apttus_Config2__AssetLineItem__c();
          tstAssetPos.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
          tstAssetPos.Apttus_Config2__EndDate__c = Date.today().addDays(-2);
          tstAssetPos.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
          tstAssetPos.Apttus_Config2__OriginalStartDate__c = Date.today();
          tstAssetPos.Apttus_Config2__ChargeType__c = 'Rental Fee';
          tstAssetPos.Apttus_CMConfig__AgreementId__c = agreement.id;
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
          //tstAssetPos.APTS_MigrationDate__c = Date.today().addDays(-1);
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
                testData.APTS_Controlled_Interface_Flag__c = false;
          lstTransData.add(testData);
                mapAssetLineItem.put(tstAssetPos.Id, tstAssetPos);
                
            RTR_LAE_Staging_Data__c sd = new RTR_LAE_Staging_Data__c();
            sd.APTS_Start_Date__c = System.Today();
            sd.APTS_Asset_Line_Item__c = tstAssetPos.Id;
            sd.APTS_Business_Transaction_Type__c = 'B005';
            sd.APTS_Integration_Log_Id__c = '123456789';
            lstStagingData.add(sd);
        }
         
         
         insert bs;
         insert lstALIHis;
         update listAssetLineItem;
         insert lstTransData;
         insert lstStagingData;

        
    }

    static testMethod void updateFinancialStartDate() {
        Test.startTest();
        Date todayDate = System.Today();

        List<RTR_LAE_Staging_Data__c> listStagingData = [SELECT Id FROM RTR_LAE_Staging_Data__c 
                                                         WHERE APTS_Integration_Log_Id__c != null 
                                                        AND APTS_Asset_Line_Item__c != null
                                                        AND APTS_Business_Transaction_Type__c = 'B005'
                                                        AND APTS_isFinancialStartDateUpdated__c = false
                                                        AND CreatedDate >=: todayDate];
        
        System.AssertEquals( 20, listStagingData.size()) ;
        System.enqueueJob(new APTS_UpdateFinancialStartDateQueueable());
        Test.stopTest();
    }

}