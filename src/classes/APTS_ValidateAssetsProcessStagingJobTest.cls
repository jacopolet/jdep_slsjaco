/*************************************************************
@Name: APTS_ValidateAssetsProcessStagingJobTest
@Author: Mahesh Chilaka
@CreateDate: 25-08-2020
@Description: This batch apex will validate the Assets Data including DeInstallation and Original Start Date.
@UsedBy: 
******************************************************************/
@isTest
private class APTS_ValidateAssetsProcessStagingJobTest {

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
        }
         
         
         insert bs;
         insert lstALIHis;
         update listAssetLineItem;
         insert lstTransData;

        //Create new Asset for validateDeinstallation_OriginalStartDate.
        List < Apttus_Config2__AssetLineItem__c > listCreateAssetLineItem = new List < Apttus_Config2__AssetLineItem__c > ();
        // List <Apttus_Billing__BillingSchedule__c> bs_003 = new List<Apttus_Billing__BillingSchedule__c>();
        // List<Apttus_Config2__AssetTransactionHistory__c> lstALIHis_003 = new List<Apttus_Config2__AssetTransactionHistory__c>();
        for (integer i = 0; i < 10; i++) {
            Apttus_Config2__AssetLineItem__c tstAssetPosO = new Apttus_Config2__AssetLineItem__c();
            tstAssetPosO.Apttus_Config2__StartDate__c = Date.today().addDays(-1);
            tstAssetPosO.Apttus_Config2__EndDate__c = Date.today().addDays(-2);
            tstAssetPosO.APTS_Amendment_Effective_Date__c = Date.today().addDays(-1);
            tstAssetPosO.Apttus_Config2__OriginalStartDate__c = Date.today();

            tstAssetPosO.Apttus_Config2__ChargeType__c = 'Service Fee';

            tstAssetPosO.Apttus_CMConfig__AgreementId__c = agreement.id;
            tstAssetPosO.APTS_Physical_Asset__c = testPhysicalAsset.id;
            tstAssetPosO.Apttus_Config2__LineType__c = 'Product/Service';
            tstAssetPosO.APTS_Type_Of_Contract__c = 'Rent';
            tstAssetPosO.APTS_Asset_Validaton_Error__c = false;
            tstAssetPosO.APTS_Is_Primary_L1_Line__c = true;
            tstAssetPosO.Apttus_Config2__IsPrimaryLine__c = true;
            tstAssetPosO.Apttus_Config2__BasePrice__c = 10.00;
            tstAssetPosO.Apttus_Config2__Quantity__c = 10;
            tstAssetPosO.Apttus_Config2__SellingTerm__c = 1;
            tstAssetPosO.Apttus_Config2__ListPrice__c = 10.00;
            tstAssetPosO.APTS_MigrationDate__c = Date.today().addDays(-1);
            tstAssetPosO.APTS_Is_Primary_L1_Asset__c = listAssetLineItem_PriL1[i].Id;
            tstAssetPosO.Apttus_Config2__AccountId__c = account.Id;
            tstAssetPosO.Apttus_Config2__ProductId__c = prod.Id;
            tstAssetPosO.Apttus_Config2__BillingStartDate__c = Date.today();
            tstAssetPosO.Apttus_Config2__PriceListId__c = prcLst.Id;
            tstAssetPosO.Apttus_Config2__AssetStatus__c = 'Activated';

            listCreateAssetLineItem.add(tstAssetPosO);
        }

        insert listCreateAssetLineItem;
        
        
          /**************************************************************
          Condition 1 , 
          Type of contact != sales
          CED != Asset EndDate
          BTT = 0002
    
     **************************************************************/

    List < RTR_LAE_Transaction_Data__c > listTransData = new List < RTR_LAE_Transaction_Data__c > ();
    Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
    List < Apttus_Config2__AssetLineItem__c > listALI = [SELECT Id, Apttus_Config2__EndDate__c FROM Apttus_Config2__AssetLineItem__c WHERE APTS_Type_Of_Contract__c != 'Sales'
        AND Apttus_Config2__ChargeType__c IN: setChargeType
        AND Apttus_Config2__LineType__c = 'Product/Service'
        AND Apttus_Config2__AssetStatus__c = 'Activated'
        limit 200
    ];

    for (Apttus_Config2__AssetLineItem__c ali : listALI) {

        RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
        transData.APTS_Asset_Line_Item__c = ali.Id;
        transData.APTS_Contract_Effective_Date__c = System.Today();
        transData.APTS_Business_Transaction_Type__c = '0002';

        listTransData.add(transData);
    }

    insert listTransData;

    /*************************************************************
       Condition 2 , 
      Type of contact != sales
      CED != Asset EndDate
      BTT = 0002
              Created 0003's later
    /**************************************************************/

    List < RTR_LAE_Transaction_Data__c > listTransData2 = new List < RTR_LAE_Transaction_Data__c > ();
    

    
    List < Apttus_Config2__AssetLineItem__c > listALI2 = [SELECT Id, Apttus_Config2__EndDate__c FROM Apttus_Config2__AssetLineItem__c WHERE APTS_Type_Of_Contract__c != 'Sales'
        AND Apttus_Config2__ChargeType__c IN: setChargeType
        AND Apttus_Config2__LineType__c = 'Product/Service'
        AND Apttus_Config2__AssetStatus__c = 'Activated'
        limit 200
    ];

    for (Apttus_Config2__AssetLineItem__c ali : listALI2) {

        RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
        transData.APTS_Asset_Line_Item__c = ali.Id;
        transData.APTS_Contract_Effective_Date__c = System.Today();
        transData.APTS_Business_Transaction_Type__c = '0002';
        
        listTransData2.add(transData);

    }

    insert listTransData2;
    }

    static testMethod void validateDeInstallation_OriginalStartDate() {

  
    Set < Id > setAssetId = new Set < Id > ();
    List < RTR_LAE_Transaction_Data__c > listTransData3 = new List < RTR_LAE_Transaction_Data__c > ();
    
    for (RTR_LAE_Transaction_Data__c transDataRec: [SELECT Id, APTS_Asset_Line_Item__c FROM RTR_LAE_Transaction_Data__c  Order By CreatedDate Desc LIMIT 200]) {

        RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
        transData.APTS_Asset_Line_Item__c = transDataRec.APTS_Asset_Line_Item__c;
        transData.APTS_Contract_Effective_Date__c = Date.today();
        transData.APTS_Business_Transaction_Type__c = '0003';
        setAssetId.add(transData.APTS_Asset_Line_Item__c);
        listTransData3.add(transData);

    }

    insert listTransData3;

    /**************************************************************
              Condition 3 , 
              Asset EndDate <= Asset Original Start Date
        
            /**************************************************************/

    List < RTR_LAE_Transaction_Data__c > listTransData4 = new List < RTR_LAE_Transaction_Data__c > ();
    Set<String> setChargeType = new Set<String>{'Service Fee', 'Rental Fee', 'Sales Price'};
    Integer iCount = 0;

    for (Apttus_Config2__AssetLineItem__c asset: [SELECT Id, Apttus_Config2__EndDate__c,
        Apttus_Config2__OriginalStartDate__c
        FROM Apttus_Config2__AssetLineItem__c WHERE  Apttus_Config2__ChargeType__c IN: setChargeType
        AND Apttus_Config2__LineType__c = 'Product/Service'
        AND Apttus_Config2__AssetStatus__c = 'Activated'
        limit 200
        ]) {
        if (asset.Apttus_Config2__EndDate__c <= asset.Apttus_Config2__OriginalStartDate__c) {
        RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
        transData.APTS_Asset_Line_Item__c = asset.Id;
        transData.APTS_Contract_Effective_Date__c = Date.today().addDays(1);
        transData.APTS_Business_Transaction_Type__c = '0002';

        listTransData4.add(transData);
            iCount++;
        }

    }

    If(!listTransData4.isEmpty()) {
        insert listTransData4;
    }

        APTS_RTR_Scheduler_Query__c schQuery = new APTS_RTR_Scheduler_Query__c();
        schQuery.APTS_Contract_Effective_Start_Date__c = System.Today();
        schQuery.APTS_Contract_Effective_End_Date__c = Date.today().addDays(5);
        schQuery.isBatchableRequest__c = true;
        insert schQuery;
        APTS_RTR_Scheduler_Query__c schQuerySec = new APTS_RTR_Scheduler_Query__c();
        schQuerySec.APTS_Contract_Effective_Start_Date__c = System.Today();
        schQuerySec.APTS_Contract_Effective_End_Date__c = Date.today().addDays(5);
        //schQuerySec.APTS_Agreement_Number__c = 'SAP_0079';
        //schQuerySec.Asset_Line_Item_Number__c = setAssetId.toString();
        //schQuerySec.APTS_Business_Transaction_Type__c = '0002';
       // schQuerySec.APTS_Company_Code__c = '1124';
        //schQuerySec.APTS_Controlled_Interface_Flag__c = true;
        //schQuerySec.APTS_Finance_ID__c = '12312';
        //schQuerySec.APTS_LAE_RAR_Transaction_ID__c = '1212';
        //schQuerySec.APTS_Type_of_Contract__c = 'Sales';
        schQuerySec.isDataValidated__c=FALSE;
        schQuerySec.isBatchableRequest__c = true;
        schQuerySec.isProcessed__c = false;
        //schQuerySec.APTS_Current_Job_Work_In_Progress__c ='Process Staging';
        insert schQuerySec;

        Test.startTest();
        APTS_ValidateAssetsBfrProcessStagingJob validateJob = new APTS_ValidateAssetsBfrProcessStagingJob();
        Database.executeBatch(validateJob);
        Test.stopTest();

    }

    static testmethod void validateDeInstallation_Negitive(){
    
    list<RTR_LAE_Transaction_Data__c> listTransData2 = new List<RTR_LAE_Transaction_Data__c>();
     Set < Id > setAssetId = new Set < Id > ();
     List < Apttus_Config2__AssetLineItem__c > listALI2 = [SELECT Id, Apttus_Config2__EndDate__c FROM Apttus_Config2__AssetLineItem__c WHERE APTS_Type_Of_Contract__c != 'Sales'
        AND Apttus_Config2__ChargeType__c = 'Service Fee'
        AND Apttus_Config2__LineType__c = 'Product/Service'
        AND Apttus_Config2__AssetStatus__c = 'Activated'
         limit 200
     ];

    for (Apttus_Config2__AssetLineItem__c ali : listALI2) {

        RTR_LAE_Transaction_Data__c transData = new RTR_LAE_Transaction_Data__c();
        transData.APTS_Asset_Line_Item__c = ali.Id;
        transData.APTS_Contract_Effective_Date__c = System.Today();
        transData.APTS_Business_Transaction_Type__c = '0002';
        setAssetId.add(transData.APTS_Asset_Line_Item__c);
        listTransData2.add(transData);

    }

    insert listTransData2;
        Map<Id, RTR_LAE_Transaction_Data__c> mapTrandIds = new Map<Id, RTR_LAE_Transaction_Data__c>([Select Id From RTR_LAE_Transaction_Data__c Where Id IN: listTransData2]);
        APTS_RTR_Scheduler_Query__c schQuerySec = new APTS_RTR_Scheduler_Query__c();
        schQuerySec.APTS_Contract_Effective_Start_Date__c = System.Today();
        schQuerySec.APTS_Contract_Effective_End_Date__c = Date.today().addDays(1);
        schQuerySec.APTS_Agreement_Number__c = 'SAP_0079';
        schQuerySec.Asset_Line_Item_Number__c = setAssetId.toString();
        schQuerySec.APTS_Business_Transaction_Type__c = '0002';
        schQuerySec.APTS_Company_Code__c = '1124';
        schQuerySec.APTS_Controlled_Interface_Flag__c = true;
        schQuerySec.APTS_Finance_ID__c = '12312';
        schQuerySec.APTS_LAE_RAR_Transaction_ID__c = mapTrandIds.keyset().toString();
        schQuerySec.APTS_Type_of_Contract__c = 'Sales';
        schQuerySec.isDataValidated__c=FALSE;
        schQuerySec.isBatchableRequest__c = true;
        schQuerySec.APTS_Current_Job_Work_In_Progress__c ='Process Staging';
        schQuerySec.isProcessed__c = false;
        insert schQuerySec;

        //Test.startTest();
        APTS_ValidateAssetsBfrProcessStagingJob validateJob = new APTS_ValidateAssetsBfrProcessStagingJob();
        //validateJob.execute(BC,listTransData2);
        Database.executeBatch(validateJob);
        //Test.stopTest();

    
    }
}