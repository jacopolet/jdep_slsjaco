@isTest
public class APTS_GenerateBillingSchedulesHelperTest  {

    public static Account grandParent = new Account();
    public static Account parentAccount= new Account();
    public static Account childAccount= new Account();
    public static List<Account> accounts = new List<Account>();
    @testSetup
    private static void testDataSetup() {

         //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

        Apttus_Billing__BillingSystemProperties__c syspropty = new Apttus_Billing__BillingSystemProperties__c();
        syspropty.Name = 'System Properties';
        syspropty.Apttus_Billing__CreateRedundantBillingSchedules__c = true;
        syspropty.Apttus_Billing__AllowBillingPreferenceOverride__c = true;
        insert syspropty;
        
        Product2 product =APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');
        insert product;

        
        Apttus_Config2__BillingPreference__c billingPreference = new Apttus_Config2__BillingPreference__c();
                billingPreference.Name = 'BillingPreference';
                billingPreference.Apttus_Config2__Active__c = True;
                billingPreference.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
                billingPreference.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
                billingPreference.Apttus_Config2__BillingInterval__c = 'Anytime ';
                billingPreference.Apttus_Config2__CalendarCycleStart__c = ' Account Calendar Cycle Start'; 
        insert billingPreference;
        
               
        Apttus_Config2__PriceList__c priceList = new  Apttus_Config2__PriceList__c();
                priceList.Name =  'Belgium General Pricelist - EUR';
                priceList.Apttus_Config2__Active__c = true;
                priceList.APTS_SalesOrg__c = 'SalesOrg';
              
        insert priceList;
         Apttus_Config2__PriceList__c priceList1 = new  Apttus_Config2__PriceList__c();
                priceList1.Name =  'Belgium General Pricelist - EUR';
                priceList1.Apttus_Config2__Active__c = true;
                priceList1.APTS_SalesOrg__c = 'SalesOrg'; 
        insert priceList1;  
        
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.id,product.id);
        insert priceListItem; 
                grandParent.Name = 'Grand Parent Account';
                grandParent.Phone = '+2222222222';
                grandParent.Main_Street_Only__c = 'Test Street';
                grandParent.Main_House_Number__c = 'Test no.';
                grandParent.billingcountry = 'Netherlands';
         insert grandParent;
        
        
        
                parentAccount.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
                parentAccount.Name = 'Parent Account';
                parentAccount.Phone = '+919898468401';
                parentAccount.Main_Street_Only__c = 'Test Street';
                parentAccount.Main_House_Number__c = 'Test no.';
                parentAccount.Parent = grandParent;
                parentAccount.ParentId = grandParent.Id;
        insert  parentAccount;   
        
         
                 childAccount.Name = 'Child Account';
                 childAccount.Phone = '+919898468401';
                 childAccount.Main_Street_Only__c = 'Test Street';
                 childAccount.Main_House_Number__c = 'Test no.';
                 childAccount.Parent = parentAccount;
                 childAccount.ParentId = parentAccount.Id;
               
        insert childAccount;
        
        
       accounts.add(grandParent);
       accounts.add(parentAccount);
       accounts.add(childAccount);
      
       Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Test Agreement',
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceList.Id,
                Apttus__Account__c = parentAccount.Id);
      insert agreementRec;
        
        PhysicalAsset__c physicalAsset =  new   PhysicalAsset__c(recordtypeid = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
               Name = 'Physical Asset',
               Product__c=product.Id,
               AssetStatus__c = 'Activated',
               SerialNumber__c = 'ABCTest');
        insert physicalAsset; 
        
         Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c( 
         APTS_Order_Type__c = 'Admin Order',
                            APTS_Order_Sub_Type__c = 'Billing Schedule',
                            Apttus_Config2__PriceListId__c = priceList.Id,
                            Apttus_Config2__BillingPreferenceId__c = parentAccount.Apttus_Config2__BillingPreferenceId__c,
                            Apttus_Config2__BillToAccountId__c = parentAccount.Id,
                            Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
                            Apttus_Config2__SoldToAccountId__c = parentAccount.Id,
                            Apttus_Config2__Source__c = 'Account',
                            Apttus_Config2__OrderStartDate__c = Date.today(),
                            Apttus_Config2__OrderEndDate__c = Date.today().addDays(30),
                            Apttus_Config2__OrderDate__c = Date.today(),
                            Apttus_Config2__Status__c = 'Draft');
        insert orderobj;
    
        Apttus_Config2__AssetLineItem__c parentAssetLineItem1 = new Apttus_Config2__AssetLineItem__c(Name = 'Parent Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'New',
               Apttus_Config2__LineNumber__c = 1,
               APTS_Physical_Asset__c = physicalAsset.Id,
               Apttus_Config2__ProductId__c = product.Id,
               Apttus_Config2__PriceListId__c = priceList.Id,
               Apttus_Config2__PriceListItemId__c = priceListItem.Id,
               Apttus_Config2__BillToAccountId__c = parentAccount.Id,
               Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
               Apttus_Config2__PriceMethod__c = 'Per Unit',
               Apttus_Config2__PriceType__c = 'One Time',
               Apttus_Config2__PriceUom__c = 'Each', 
               Apttus_Config2__Quantity__c = 1,
               Apttus_Config2__SellingFrequency__c = 'Hourly', 
               Apttus_Config2__SellingTerm__c = 5, 
               Apttus_Config2__StartDate__c = system.today(), 
              // Apttus_Config2__SellingUom__c = 'Box',
               Apttus_Config2__BillingFrequency__c = 'Hourly',
               Apttus_Config2__BillingRule__c = ' Bill In Advance',
               Apttus_Config2__EndDate__c  = system.today().adddays(10),
               Apttus_Config2__AccountId__c = parentAccount.Id,
               Apttus_Config2__InitialActivationDate__c = system.today(),
               Apttus_Config2__Comments__c = 'this is a test comment',
               Apttus_Config2__BillThroughDate__c  = system.today(),
               APTS_Batch_Billing_Schedules__c = False,
               //RM 19-12-2018. Include 3 fields. Defect #22992
               APTS_Cumulative_Call_Out_Coverage__c = 11,
               APTS_Cumulative_Labour_coverage__c = 12,
               APTS_Cumulative_Spare_Parts_Coverage__c = 13,
               //RM 08-01-2019. Include Base Price Override field. Defect #23455
               APTS_BasePriceOverride__c = 14,
               APTS_ZX10__c = 100,
               APTS_Calculated_Base_Extended_Price__c = 1,
               APTS_SourceSystem__c = 'BEC');
         insert parentAssetLineItem1; 
      
          Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id; 
        orderltobj.Apttus_Config2__Status__c = 'Draft'; 
        orderltobj.APTS_Migrated_Asset_Line_Item__c = parentAssetLineItem1.id; 
        orderltobj.Apttus_Config2__AssetLineItemId__c = parentAssetLineItem1.id;  
        insert orderltobj; 
        Apttus_Config2__AssetLineItem__c parentAssetLineItem = new Apttus_Config2__AssetLineItem__c(Name = 'Parent Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'New',
               Apttus_Config2__LineNumber__c = 1,
               APTS_Physical_Asset__c = physicalAsset.Id,
               Apttus_Config2__ProductId__c = product.Id,
               Apttus_Config2__PriceListId__c = priceList.Id,
               Apttus_Config2__PriceListItemId__c = priceListItem.Id,
               Apttus_Config2__BillToAccountId__c = parentAccount.Id,
               Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
               Apttus_Config2__PriceMethod__c = 'Per Unit',
               Apttus_Config2__PriceType__c = 'One Time',
               Apttus_Config2__PriceUom__c = 'Each', 
               Apttus_Config2__Quantity__c = 1,
               Apttus_Config2__SellingFrequency__c = 'Hourly', 
               Apttus_Config2__SellingTerm__c = 5, 
               Apttus_Config2__StartDate__c = system.today(), 
              // Apttus_Config2__SellingUom__c = 'Box',
               Apttus_Config2__BillingFrequency__c = 'Hourly',
               Apttus_Config2__BillingRule__c = ' Bill In Advance',
               Apttus_Config2__EndDate__c  = system.today().adddays(10),
               Apttus_Config2__AccountId__c = parentAccount.Id,
               Apttus_Config2__InitialActivationDate__c = system.today(),
               Apttus_Config2__Comments__c = 'this is a test comment',
               Apttus_Config2__BillThroughDate__c  = system.today(),
               APTS_Batch_Billing_Schedules__c = False, 
               Apttus_Config2__BusinessLineItemId__c = orderltobj.id,
               Apttus_Config2__BusinessObjectId__c = orderobj.id,
               Apttus_Config2__BusinessObjectType__c = 'Apttus_Config2__Order__c',
               //RM 19-12-2018. Include 3 fields. Defect #22992
               APTS_Cumulative_Call_Out_Coverage__c = 11,
               APTS_Cumulative_Labour_coverage__c = 12,
               APTS_Cumulative_Spare_Parts_Coverage__c = 13,
               //RM 08-01-2019. Include Base Price Override field. Defect #23455
               APTS_BasePriceOverride__c = 14,APTS_Option_Group_Text__c = 'OP',
               APTS_SourceSystem__c = 'BEC');
         insert parentAssetLineItem; 
         
          Apttus_Config2__AssetUsagePriceTier__c aptsPriceTier = new Apttus_Config2__AssetUsagePriceTier__c(Apttus_Config2__AssetLineItemId__c = parentAssetLineItem.Id,Apttus_Config2__Sequence__c = 1); 
          insert aptsPriceTier;
          
           Apttus_Config2__OrderSystemProperties__c orderSystemProperties = new Apttus_Config2__OrderSystemProperties__c();
           orderSystemProperties.Name = 'System Properties';
           orderSystemProperties.Apttus_Config2__CreateAssetOnOrderActivation__c = true;
           orderSystemProperties.Apttus_Config2__EnableInflightChangesAndCancellation__c = true;
           orderSystemProperties.Apttus_Config2__InitiateBillingOnOrderActivation__c = true;
           orderSystemProperties.APTS_Orders_to_display__c = 5;
           insert orderSystemProperties;
    }

   

    private static testMethod void test1() { 
       //RM 19-12-2018. Include 3 fields. Defect #22992
       //RM 08-01-2019. Include Base Price Override field. Defect #23455
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_GenerateBillingScheiduleBatchHelper", "APTS_Batch_Size__c": 100, "APTS_Control__c": false, "APTS_Is_Active__c": true, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id from Account","Second_Query__c":"SELECT Id, Name,CurrencyIsoCode, Apttus_Config2__AccountId__c, APTS_MigrationDate__c, Apttus_CMConfig__AgreementId__c, APTS_AssetLineItemExtId__c, APTS_ConversionId__c, APTS_SourceSystem__c, Apttus_Config2__BillingDayOfMonth__c, Apttus_Config2__PurchaseDate__c, Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListItemId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__PriceMethod__c, Apttus_Config2__PriceType__c, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__Quantity__c, Apttus_Config2__SellingFrequency__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__StartDate__c, Apttus_Config2__SellingUom__c, Apttus_Config2__BillingFrequency__c, Apttus_Config2__BillingRule__c, Apttus_Config2__EndDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__Frequency__c, APTS_Physical_Asset__c, APTS_Bill_to_Party_Ingredients_and_Payer__c, APTS_Bill_to_Party_Machines_Services__c, APTS_Order_LSP_Detail__c, APTS_PayerIngredients__c, APTS_PayerMachinesServices__c, APTS_Payment_Method__c, APTS_RefurbishedMachine__c, APTS_Type_of_Contract__c, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__LocationId__c, Apttus_Config2__LineType__c, Apttus_Config2__OptionId__c, Apttus_Config2__AdjustedPrice__c, Apttus_Config2__AttributeValueId__c, Apttus_Config2__AutoRenew__c, Apttus_Config2__AutoRenewalType__c, Apttus_Config2__BaseCost__c, Apttus_Config2__BaseExtendedCost__c, Apttus_Config2__BaseExtendedPrice__c, Apttus_Config2__BasePrice__c, Apttus_Config2__BasePriceMethod__c, Apttus_Config2__BillingPlanId__c, Apttus_Config2__CancelledDate__c, Apttus_Config2__ChargeGroupId__c, Apttus_Config2__ChargeType__c, Apttus_Config2__Comments__c, Apttus_Config2__Description__c, Apttus_Config2__ExtendedCost__c, Apttus_Config2__ExtendedDescription__c, Apttus_Config2__ExtendedPrice__c, Apttus_Config2__HasAttributes__c, Apttus_Config2__HasOptions__c, Apttus_Config2__HideInvoiceDisplay__c, Apttus_Config2__IsOptionRollupLine__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__IsPrimaryRampLine__c, Apttus_Config2__IsUsageTierModifiable__c, Apttus_Config2__ItemSequence__c, Apttus_Config2__LineNumber__c, Apttus_Config2__ListPrice__c, Apttus_Config2__MaxUsageQuantity__c, Apttus_Config2__MinUsageQuantity__c, Apttus_Config2__NetUnitPrice__c, Apttus_Config2__OptionCost__c, Apttus_Config2__OptionPrice__c, Apttus_Config2__ParentBundleNumber__c, Apttus_Config2__PaymentTermId__c, Apttus_Config2__PriceGroup__c, Apttus_Config2__PriceIncludedInBundle__c, Apttus_Config2__PricingDate__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__RenewalAdjustmentAmount__c, Apttus_Config2__RenewalAdjustmentType__c, Apttus_Config2__ShipToAccountId__c, Apttus_Config2__Taxable__c, Apttus_Config2__TaxCodeId__c, Apttus_Config2__TaxInclusive__c, Apttus_Config2__Term__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__BundleAssetId__c, Apttus_Config2__InitialActivationDate__c, Apttus_Config2__RenewalDate__c, Apttus_Config2__RenewalFrequency__c, Apttus_Config2__RenewalTerm__c, Apttus_Config2__LastRenewEndDate__c, Apttus_Config2__NextRenewEndDate__c, Apttus_Config2__BillThroughDate__c, APTS_Installation_Sales_Order_Item__c, APTS_Installation_Sales_Order_Id__c, Apttus_Config2__BillingStartDate__c, Apttus_Config2__BillingEndDate__c, Apttus_Config2__DeltaPrice__c, Apttus_Config2__DeltaQuantity__c, APTS_AgreementExtId__c, APTS_ProductExtId__c, APTS_PhysicalAssetExtId__c, APTS_Reason_code__c, APTS_Consumer_Price__c, APTS_Category_Level__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c, APTS_Cumulative_Call_Out_Coverage__c, APTS_Cumulative_Labour_coverage__c, APTS_Cumulative_Spare_Parts_Coverage__c, APTS_BasePriceOverride__c,APTS_ZX10__c,APTS_Option_Group_Text__c,APTS_Calculated_Base_Extended_Price__c  FROM Apttus_Config2__AssetLineItem__c where Apttus_Config2__AccountId__c IN : scopeList", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));                
    } 

    private static testMethod void ExceptionCase() { 
        //RM 19-12-2018. Include 3 fields. Defect #22992
        //RM 08-01-2019. Include Base Price Override field. Defect #23455
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_GenerateBillingScheiduleBatchHelper", "APTS_Batch_Size__c": 100, "APTS_Control__c": false, "APTS_Is_Active__c": true, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id from Account","Second_Query__c":"SELECT Id, Name,CurrencyIsoCode, APTS_MigrationDate__c, Apttus_CMConfig__AgreementId__c, APTS_AssetLineItemExtId__c, APTS_ConversionId__c, APTS_SourceSystem__c, Apttus_Config2__BillingDayOfMonth__c, Apttus_Config2__PurchaseDate__c, Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListItemId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__PriceMethod__c, Apttus_Config2__PriceType__c, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__Quantity__c, Apttus_Config2__SellingFrequency__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__StartDate__c, Apttus_Config2__SellingUom__c, Apttus_Config2__BillingFrequency__c, Apttus_Config2__BillingRule__c, Apttus_Config2__EndDate__c, Apttus_Config2__NetPrice__c, Apttus_Config2__Frequency__c, APTS_Physical_Asset__c, APTS_Bill_to_Party_Ingredients_and_Payer__c, APTS_Bill_to_Party_Machines_Services__c, APTS_Order_LSP_Detail__c, APTS_PayerIngredients__c, APTS_PayerMachinesServices__c, APTS_Payment_Method__c, APTS_RefurbishedMachine__c, APTS_Type_of_Contract__c, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__LocationId__c, Apttus_Config2__LineType__c, Apttus_Config2__OptionId__c, Apttus_Config2__AdjustedPrice__c, Apttus_Config2__AttributeValueId__c, Apttus_Config2__AutoRenew__c, Apttus_Config2__AutoRenewalType__c, Apttus_Config2__BaseCost__c, Apttus_Config2__BaseExtendedCost__c, Apttus_Config2__BaseExtendedPrice__c, Apttus_Config2__BasePrice__c, Apttus_Config2__BasePriceMethod__c, Apttus_Config2__BillingPlanId__c, Apttus_Config2__CancelledDate__c, Apttus_Config2__ChargeGroupId__c, Apttus_Config2__ChargeType__c, Apttus_Config2__Comments__c, Apttus_Config2__Description__c, Apttus_Config2__ExtendedCost__c, Apttus_Config2__ExtendedDescription__c, Apttus_Config2__ExtendedPrice__c, Apttus_Config2__HasAttributes__c, Apttus_Config2__HasOptions__c, Apttus_Config2__HideInvoiceDisplay__c, Apttus_Config2__IsOptionRollupLine__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__IsPrimaryRampLine__c, Apttus_Config2__IsUsageTierModifiable__c, Apttus_Config2__ItemSequence__c, Apttus_Config2__LineNumber__c, Apttus_Config2__ListPrice__c, Apttus_Config2__MaxUsageQuantity__c, Apttus_Config2__MinUsageQuantity__c, Apttus_Config2__NetUnitPrice__c, Apttus_Config2__OptionCost__c, Apttus_Config2__OptionPrice__c, Apttus_Config2__ParentBundleNumber__c, Apttus_Config2__PaymentTermId__c, Apttus_Config2__PriceGroup__c, Apttus_Config2__PriceIncludedInBundle__c, Apttus_Config2__PricingDate__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__RenewalAdjustmentAmount__c, Apttus_Config2__RenewalAdjustmentType__c, Apttus_Config2__ShipToAccountId__c, Apttus_Config2__Taxable__c, Apttus_Config2__TaxCodeId__c, Apttus_Config2__TaxInclusive__c, Apttus_Config2__Term__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__BundleAssetId__c, Apttus_Config2__InitialActivationDate__c, Apttus_Config2__RenewalDate__c, Apttus_Config2__RenewalFrequency__c, Apttus_Config2__RenewalTerm__c, Apttus_Config2__LastRenewEndDate__c, Apttus_Config2__NextRenewEndDate__c, Apttus_Config2__BillThroughDate__c, APTS_Installation_Sales_Order_Item__c, APTS_Installation_Sales_Order_Id__c, Apttus_Config2__BillingStartDate__c, Apttus_Config2__BillingEndDate__c, Apttus_Config2__DeltaPrice__c, Apttus_Config2__DeltaQuantity__c, APTS_AgreementExtId__c, APTS_ProductExtId__c, APTS_PhysicalAssetExtId__c, APTS_Reason_code__c, APTS_Consumer_Price__c, APTS_Category_Level__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c, APTS_Cumulative_Call_Out_Coverage__c, APTS_Cumulative_Labour_coverage__c, APTS_Cumulative_Spare_Parts_Coverage__c, APTS_BasePriceOverride__c,APTS_BasePriceOverride__c,APTS_ZX10__c,APTS_Option_Group_Text__c,APTS_Calculated_Base_Extended_Price__c  FROM Apttus_Config2__AssetLineItem__c where Apttus_Config2__AccountId__c IN : scopeList", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));                
    } 

}