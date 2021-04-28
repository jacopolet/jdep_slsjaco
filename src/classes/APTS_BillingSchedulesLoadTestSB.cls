@isTest
public with sharing class APTS_BillingSchedulesLoadTestSB {

    public static Account grandParent = new Account();
    public static Account parentAccount= new Account();
    public static Account childAccount= new Account();
    public static List<Account> accounts = new List<Account>();
    @testSetup
    private static void testDataSetup() {

        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.APTS_Order_Trigger__c = false;
        objTriggerSettings.APTS_OrderLineItemTrigger__c = false;
        insert objTriggerSettings;
        
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
        
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.id,product.id);
        insert priceListItem;
        
       
                grandParent.Name = 'Grand Parent Account';
                grandParent.Phone = '+919898468401';
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
        
        Apttus_Config2__AssetLineItem__c parentAssetLineItem = new Apttus_Config2__AssetLineItem__c(Name = 'Parent Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'Activated',
               Apttus_Config2__LineNumber__c = 1,
               //APTS_Physical_Asset_Id__c = physicalAsset.Id,
               APTS_Physical_Asset__c= physicalAsset.Id,//Added by Abhishek K to Change Field
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
               APTS_Batch_Billing_Schedules__c = False);
         insert parentAssetLineItem; 
         
        Apttus_Config2__AssetLineItem__c assetLineItem = new Apttus_Config2__AssetLineItem__c(Name = 'Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'Activated',
               Apttus_Config2__LineNumber__c = 1,
               //APTS_Physical_Asset_Id__c = physicalAsset.Id,
               APTS_Physical_Asset__c = physicalAsset.Id,//Added by Abhishek to change Field
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
               Apttus_Config2__ParentAssetId__c = parentAssetLineItem.id,
               Apttus_Config2__BundleAssetId__c = parentAssetLineItem.id,
               Apttus_Config2__RenewalDate__c  = system.today().adddays(5),
               Apttus_Config2__RenewalTerm__c = 5,
               Apttus_Config2__RenewalFrequency__c  = 'Hourly',
               APTS_Batch_Billing_Schedules__c = False);
         insert assetLineItem;       

    }

    private static testMethod void test1() {

        //Set metadata
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Billing_Schedules\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"Select Id, Apttus_Config2__BillingPreferenceId__c,'+ 
'(SELECT Id,Apttus_CMConfig__AgreementId__c,'+ 
'Apttus_Config2__BillToAccountId__c,'+ 
'Apttus_Config2__PriceListItemId__c,'+ 
'Apttus_Config2__PriceListId__c,'+ 
'Apttus_Config2__PriceMethod__c,'+ 
'Apttus_Config2__PriceType__c,'+ 
'Apttus_Config2__PriceUom__c,'+ 
'Apttus_Config2__ProductId__c,'+ 
'Apttus_Config2__Quantity__c,'+ 
'Apttus_Config2__SellingFrequency__c,'+ 
'Apttus_Config2__SellingTerm__c,'+ 
'Apttus_Config2__StartDate__c,'+ 
'Apttus_Config2__SellingUom__c,'+ 
'Apttus_Config2__BillingFrequency__c,'+ 
'Apttus_Config2__BillingRule__c,'+ 
'Apttus_Config2__EndDate__c,'+ 
'Apttus_Config2__NetPrice__c,'+ 
'Apttus_Config2__Frequency__c,'+ 
'APTS_Physical_Asset__c,'+ 
'APTS_Bill_to_Party_Ingredients_and_Payer__c,'+ 
'APTS_Bill_to_Party_Machines_Services__c,'+ 
'APTS_Order_LSP_Detail__c,'+ 
'APTS_PayerIngredients__c,'+ 
'APTS_PayerMachinesServices__c,'+ 
'APTS_Payment_Method__c,'+ 
'APTS_RefurbishedMachine__c,'+ 
'APTS_Type_of_Contract__c,'+ 
'Apttus_Config2__BillingPreferenceId__c,'+ 
'Apttus_Config2__LocationId__c,'+ 
'Apttus_Config2__LineType__c,'+ 
'Apttus_Config2__OptionId__c,'+ 
'Apttus_Config2__AdjustedPrice__c,'+ 
'Apttus_Config2__AttributeValueId__c,'+ 
'Apttus_Config2__AutoRenew__c,'+ 
'Apttus_Config2__AutoRenewalType__c,'+ 
'Apttus_Config2__BaseCost__c,'+ 
'Apttus_Config2__BaseExtendedCost__c,'+ 
'Apttus_Config2__BaseExtendedPrice__c,'+ 
'Apttus_Config2__BasePrice__c,'+ 
'Apttus_Config2__BasePriceMethod__c,'+ 
'Apttus_Config2__BillingPlanId__c,'+ 
'Apttus_Config2__CancelledDate__c,'+ 
'Apttus_Config2__ChargeGroupId__c,'+ 
'Apttus_Config2__ChargeType__c,'+ 
'Apttus_Config2__Comments__c,'+ 
'Apttus_Config2__Description__c,'+ 
'Apttus_Config2__ExtendedCost__c,'+ 
'Apttus_Config2__ExtendedDescription__c,'+ 
'Apttus_Config2__ExtendedPrice__c,'+ 
'Apttus_Config2__HasAttributes__c,'+ 
'Apttus_Config2__HasOptions__c,'+ 
'Apttus_Config2__HideInvoiceDisplay__c,'+ 
'Apttus_Config2__IsOptionRollupLine__c,'+ 
'Apttus_Config2__IsPrimaryLine__c,'+ 
'Apttus_Config2__IsPrimaryRampLine__c,'+ 
'Apttus_Config2__IsUsageTierModifiable__c,'+ 
'Apttus_Config2__ItemSequence__c,'+ 
'Apttus_Config2__LineNumber__c,'+ 
'Apttus_Config2__ListPrice__c,'+ 
'Apttus_Config2__MaxUsageQuantity__c,'+ 
'Apttus_Config2__MinUsageQuantity__c,'+ 
'Apttus_Config2__NetUnitPrice__c,'+ 
'Apttus_Config2__OptionCost__c,'+ 
'Apttus_Config2__OptionPrice__c,'+ 
'Apttus_Config2__ParentBundleNumber__c,'+ 
'Apttus_Config2__PaymentTermId__c,'+ 
'Apttus_Config2__PriceGroup__c,'+ 
'Apttus_Config2__PriceIncludedInBundle__c,'+ 
'Apttus_Config2__PricingDate__c,'+ 
'Apttus_Config2__PrimaryLineNumber__c,'+ 
'Apttus_Config2__RenewalAdjustmentAmount__c,'+ 
'Apttus_Config2__RenewalAdjustmentType__c,'+ 
'Apttus_Config2__ShipToAccountId__c,'+ 
'Apttus_Config2__Taxable__c,'+ 
'Apttus_Config2__TaxCodeId__c,'+ 
'Apttus_Config2__TaxInclusive__c,'+ 
'Apttus_Config2__Term__c,'+ 
'Apttus_Config2__ParentAssetId__c,'+ 
'Apttus_Config2__BundleAssetId__c,'+ 
'Apttus_Config2__InitialActivationDate__c,'+ 
'Apttus_Config2__RenewalDate__c,'+ 
'Apttus_Config2__RenewalFrequency__c,'+ 
'Apttus_Config2__RenewalTerm__c,'+ 
'Apttus_Config2__LastRenewEndDate__c,'+ 
'Apttus_Config2__NextRenewEndDate__c,'+ 
'Apttus_Config2__BillThroughDate__c '+ 
'FROM Apttus_Config2__AssetLineItems__r '+ 
'Where APTS_Batch_Billing_Schedules__c = False)'+ 
'FROM Account",'+
                '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c",'+
                '"APTS_Control__c":"true"}]', 
                List<APTS_Batch_Queries__mdt>.class
                )
            );

        test.startTest();
            APTS_BillingSchedulesLoadSch scheduler = new APTS_BillingSchedulesLoadSch();      
            String sch = '0 28 * * * ?';
            system.schedule('Test APTS_BillingSchedulesLoadSch', sch, scheduler);
           
        test.stopTest();
   
    }
}