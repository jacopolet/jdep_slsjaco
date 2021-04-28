@isTest 
private class APTS_CreateAssetRollupBatchHelperTests {

    @testSetup
    private static void testDataSetup() {

        //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

         Apttus_Config2__BillingPreference__c oBillingPref = new Apttus_Config2__BillingPreference__c();
        oBillingPref.Name = 'Pending';
        oBillingPref.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        oBillingPref.Apttus_Config2__Active__c = true;
        oBillingPref.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        oBillingPref.Apttus_Config2__BillingInterval__c = 'Anytime';
        oBillingPref.Apttus_Config2__CalendarCycleStart__c = 'January';
        oBillingPref.Apttus_Config2__TaxLevel__c = 'Product';
        oBillingPref.Apttus_Config2__InvoiceDeliveryMethod__c = 'Email';
        oBillingPref.Apttus_Config2__InvoiceOutputFormat__c = 'PDF';
        insert oBillingPref;
        
        Apttus_Config2__BillingPreference__c oBillingPref1 = new Apttus_Config2__BillingPreference__c();
        oBillingPref1.Name = 'Pending';
        oBillingPref1.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        oBillingPref1.Apttus_Config2__Active__c = true;
        oBillingPref1.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        oBillingPref1.Apttus_Config2__BillingInterval__c = 'Anytime';
        oBillingPref1.Apttus_Config2__CalendarCycleStart__c = 'January';
        oBillingPref1.Apttus_Config2__TaxLevel__c = 'Product';
        oBillingPref1.Apttus_Config2__InvoiceDeliveryMethod__c = 'Email';
        oBillingPref1.Apttus_Config2__InvoiceOutputFormat__c = 'PDF';
        insert oBillingPref1;
        
        Account acc = new Account();
        acc.Name = 'accNameDM';
        acc.Phone = '+31302979111';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppNameDM';
        opp.Amount = 1000;
        opp.StageName = 'Proposal/Price Quote';
        opp.CloseDate = system.today() + 20;
        opp.AccountId = acc.id;
        insert opp;

        Product2 prod = new Product2();
        prod.Name = 'Test ';
        prod.APTS_Material_Type__c = 'ZCBB';
        prod.APTS_Option_Group_Indicator__c = '06'; 
        Insert prod;
                
        Product2 prod1 = new Product2();
        prod1.Name = 'Test ';
        prod1.APTS_Material_Type__c = 'ZCBB';
        prod1.APTS_Option_Group_Indicator__c = '06';
        prod1.Apttus_Config2__ConfigurationType__c = 'Standalone';
        Insert prod1;
        
        Contact contact = new Contact();
        contact.AccountId = acc.id;
        contact.MobilePhone = '+31302979111';
        contact.LastName = acc.Name;
        contact.Email = 'DataMigContact@qp1.org';
        insert contact;
        
        Apttus_Config2__PriceList__c price = new Apttus_Config2__PriceList__c();
        price.Apttus_Config2__Active__c = true;
        price.Name = 'DMPriceList';
        price.Apttus_Config2__EffectiveDate__c = System.today().addYears(-1);
        price.Apttus_Config2__ExpirationDate__c = System.today().addYears(2);
        price.APTS_SalesOrg__c = 'Netherlands';
        insert price;
        
        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c();
        oAgreement.Name = 'Agreement';
        oAgreement.Apttus__Primary_Contact__c = contact.id;
        oAgreement.Apttus__Agreement_Category__c = 'Standard';
        oAgreement.Apttus_CMConfig__PriceListId__c = price.id;
        oAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        oAgreement.Apttus__Account__c = acc.id;
        oAgreement.APTS_SourceSystem__c = 'NL';
        insert oAgreement;
        
        Apttus__APTS_Agreement__c oAgreement1 = new Apttus__APTS_Agreement__c();
        oAgreement1.Name = 'Agreement';
        oAgreement1.Apttus__Primary_Contact__c = contact.id;
        oAgreement1.Apttus__Agreement_Category__c = 'Standard';
        oAgreement1.Apttus_CMConfig__PriceListId__c = price.id;
        oAgreement1.Apttus_CMConfig__PricingDate__c = System.Today();
        oAgreement1.Apttus__Account__c = acc.id;
        oAgreement1.APTS_SourceSystem__c = 'NL';
        insert oAgreement1;

        List<Apttus_Config2__AssetLineItem__c> assetLineItems = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c assetLineItemL1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItemL1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItemL1.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItemL1.APTS_Type_Of_Contract__c = 'Sales';
        assetLineItemL1.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItemL1.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItemL1.Apttus_Config2__ItemSequence__c = 1;
        assetLineItemL1.Apttus_Config2__Quantity__c = 1;
        assetLineItemL1.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItemL1.Apttus_Config2__SellingTerm__c =1;
        assetLineItemL1.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItemL1.Apttus_Config2__ProductId__c = prod1.id;
        assetLineItemL1.Apttus_Config2__PrimaryLineNumber__c = 1;
        assetLineItemL1.Apttus_Config2__LineNumber__c = 1;
        assetLineItemL1.APTS_MigrationDate__c = System.Today();
        insert assetLineItemL1; 

        Apttus_Config2__AssetLineItem__c assetLineItemL1a = new Apttus_Config2__AssetLineItem__c();
        assetLineItemL1a.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItemL1a.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItemL1a.APTS_Type_Of_Contract__c = 'Sales';
        assetLineItemL1a.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItemL1a.Apttus_CMConfig__AgreementId__c = oAgreement1.id; 
        assetLineItemL1a.Apttus_Config2__ItemSequence__c = 1;
        assetLineItemL1a.Apttus_Config2__Quantity__c = 1;
        assetLineItemL1a.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItemL1a.Apttus_Config2__SellingTerm__c =1;
        assetLineItemL1a.Apttus_Config2__BillingPreferenceId__c = oBillingPref1.id;
        assetLineItemL1a.Apttus_Config2__PrimaryLineNumber__c = 1;
        assetLineItemL1a.Apttus_Config2__LineNumber__c = 1;
        assetLineItemL1a.APTS_MigrationDate__c = System.Today();
        insert assetLineItemL1a; 

        Apttus_Config2__AssetLineItem__c assetLineItemL2 = new Apttus_Config2__AssetLineItem__c();
        assetLineItemL2.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItemL2.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItemL2.APTS_Type_Of_Contract__c = 'Consumption';
        assetLineItemL2.Apttus_Config2__ChargeType__c = 'Rental Fee';
        assetLineItemL2.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItemL2.Apttus_Config2__ItemSequence__c = 1;
        assetLineItemL2.Apttus_Config2__Quantity__c = 1;
        assetLineItemL2.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItemL2.Apttus_Config2__SellingTerm__c =1;
        assetLineItemL2.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItemL2.APTS_MigrationDate__c = System.Today();
        assetLineItemL2.Apttus_Config2__PrimaryLineNumber__c = 1;
        assetLineItemL2.Apttus_Config2__LineNumber__c = 1;
        insert assetLineItemL2; 

        Apttus_Config2__AssetLineItem__c assetLineItemL3 = new Apttus_Config2__AssetLineItem__c();
        assetLineItemL3.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItemL3.Apttus_Config2__LineType__c = 'Option';
        assetLineItemL3.APTS_Type_Of_Contract__c = 'Consumption';
        assetLineItemL3.Apttus_Config2__ChargeType__c = 'Rental Fee';
        assetLineItemL3.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItemL3.Apttus_Config2__ItemSequence__c = 1;
        assetLineItemL3.Apttus_Config2__Quantity__c = 1;
        assetLineItemL3.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItemL3.Apttus_Config2__SellingTerm__c =1;
        assetLineItemL3.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItemL3.APTS_MigrationDate__c = System.Today();
        assetLineItemL3.Apttus_Config2__PrimaryLineNumber__c = 1;
        assetLineItemL3.Apttus_Config2__LineNumber__c = 1;
        assetLineItemL3.Apttus_Config2__OptionId__c = prod.id;
        assetLineItemL3.Apttus_Config2__ParentBundleNumber__c = 1;
        insert assetLineItemL3;

        Apttus_Config2__AssetLineItem__c assetLineItemL3s = new Apttus_Config2__AssetLineItem__c();
        assetLineItemL3s.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItemL3s.Apttus_Config2__LineType__c = 'Option';
        assetLineItemL3s.APTS_Type_Of_Contract__c = 'Consumption';
        assetLineItemL3s.Apttus_Config2__ChargeType__c = 'Rental Fee';
        assetLineItemL3s.Apttus_CMConfig__AgreementId__c = oAgreement1.id; 
        assetLineItemL3s.Apttus_Config2__ItemSequence__c = 1;
        assetLineItemL3s.Apttus_Config2__Quantity__c = 1;
        assetLineItemL3s.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItemL3s.Apttus_Config2__SellingTerm__c =1;
        assetLineItemL3s.Apttus_Config2__BillingPreferenceId__c = oBillingPref1.id;
        assetLineItemL3s.APTS_MigrationDate__c = System.Today();
        assetLineItemL3s.Apttus_Config2__PrimaryLineNumber__c = 1;
        assetLineItemL3s.Apttus_Config2__LineNumber__c = 1;
        assetLineItemL3s.Apttus_Config2__OptionId__c = prod1.id;
        assetLineItemL3s.Apttus_Config2__ProductId__c = prod1.id;
        assetLineItemL3s.Apttus_Config2__ParentBundleNumber__c = 1;
        insert assetLineItemL3s; 

        Apttus_Config2__AssetLineItem__c assetLineItem = new Apttus_Config2__AssetLineItem__c();
        assetLineItem.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem.Apttus_Config2__LineType__c = 'Option';
        assetLineItem.Apttus_Config2__ChargeType__c = 'Service Fee';
        assetLineItem.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem.Apttus_Config2__ItemSequence__c = 1;
        assetLineItem.Apttus_Config2__Quantity__c = 1;
        assetLineItem.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItem.Apttus_Config2__SellingTerm__c =1;
        assetLineItem.Apttus_Config2__OptionId__c = prod.id;
        assetLineItem.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem.APTS_MigrationDate__c = System.Today();
        insert assetLineItem; 
                
        Apttus_Config2__AssetLineItem__c assetLineItems1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItems1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItems1.Apttus_Config2__LineType__c = 'Option';
        assetLineItems1.Apttus_Config2__ChargeType__c = 'Service Fee';
        assetLineItems1.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItems1.Apttus_Config2__ItemSequence__c = 1;
        assetLineItems1.Apttus_Config2__Quantity__c = 1;
        assetLineItems1.Apttus_Config2__BaseExtendedPrice__c = 100;
        assetLineItems1.Apttus_Config2__SellingTerm__c =1;
        assetLineItems1.Apttus_Config2__OptionId__c = prod1.id;
        assetLineItems1.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItems1.APTS_MigrationDate__c = System.Today();
        insert assetLineItems1; 
        
        Apttus_Config2__AssetLineItem__c assetLineItem1 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem1.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem1.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem1.Apttus_Config2__IsOptionRollupLine__c = True;
        assetLineItem1.Apttus_Config2__ChargeType__c = 'Sales Price';
        assetLineItem1.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem1.Apttus_Config2__ItemSequence__c = 2;
        assetLineItem1.Apttus_Config2__Quantity__c = 2;
        assetLineItem1.Apttus_Config2__BaseExtendedPrice__c = 200;
        assetLineItem1.Apttus_Config2__SellingTerm__c =1;
        assetLineItem1.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem1.APTS_MigrationDate__c = System.Today();
        insert assetLineItem1; 
        
        Apttus_Config2__AssetLineItem__c assetLineItem2 = new Apttus_Config2__AssetLineItem__c();
        assetLineItem2.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem2.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem2.Apttus_CMConfig__AgreementId__c = oAgreement.id; 
        assetLineItem2.Apttus_Config2__ItemSequence__c = 3;
        assetLineItem2.Apttus_Config2__Quantity__c = 3;
        assetLineItem2.Apttus_Config2__BaseExtendedPrice__c = 300;
        assetLineItem2.Apttus_Config2__SellingTerm__c =1;
        assetLineItem2.APTS_Is_Primary_L1_Line__c =true;        
        assetLineItem2.Apttus_Config2__BillingPreferenceId__c = oBillingPref.id;
        assetLineItem2.APTS_MigrationDate__c = System.Today();
        assetLineItem2.Apttus_Config2__AdjustedPrice__c = 1;
        assetLineItem2.Apttus_Config2__AdjustedPrice__c = 1;
        assetLineItem2.Apttus_Config2__AdjustedPrice__c = 1;
        insert assetLineItem2;  
        
        Apttus_Config2__AssetLineItem__c assetLineItem2s = new Apttus_Config2__AssetLineItem__c();
        assetLineItem2s.Apttus_Config2__PriceType__c = 'Recurring';
        assetLineItem2s.Apttus_Config2__LineType__c = 'Product/Service';
        assetLineItem2s.Apttus_CMConfig__AgreementId__c = oAgreement1.id; 
        assetLineItem2s.Apttus_Config2__ItemSequence__c = 3;
        assetLineItem2s.Apttus_Config2__Quantity__c = 3;
        assetLineItem2s.Apttus_Config2__BaseExtendedPrice__c = 300;
        assetLineItem2s.Apttus_Config2__SellingTerm__c =1;
        assetLineItem2s.APTS_Is_Primary_L1_Line__c =true;       
        assetLineItem2s.Apttus_Config2__BillingPreferenceId__c = oBillingPref1.id;
        assetLineItem2s.APTS_MigrationDate__c = System.Today();
        assetLineItem2s.Apttus_Config2__AdjustedPrice__c = 1;
        assetLineItem2s.Apttus_Config2__AdjustedPrice__c = 1;
        assetLineItem2s.Apttus_Config2__AdjustedPrice__c = 1;
        insert assetLineItem2s; 
    }


    @isTest
    private static void testCreateRollupBatch() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_CreateAssetRollupLineBatchHelper", "APTS_Batch_Size__c": 2, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id,Apttus__Account__c FROM Apttus__APTS_Agreement__c","Second_Query__c": "Select id,CurrencyIsoCode,APTS_AgreementExtId__c , Apttus_Config2__BundleAssetId__r.Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__OptionId__r.APTS_Material_Type__c, Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__SellingTerm__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__StartDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__ItemSequence__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceType__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceMethod__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__BasePriceMethod__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__DeltaQuantity__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__OriginalStartDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceListId__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__PriceUom__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__ShipToAccountId__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__EndDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__Quantity__c,Apttus_Config2__BundleAssetId__r.APTS_Type_Of_Contract__c,Apttus_Config2__BundleAssetId__r.APTS_Is_Primary_L1_Line__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__BundleAssetId__r.APTS_MigrationDate__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__IsInactive__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__AttributeValueId__c,Apttus_Config2__BundleAssetId__r.Apttus_Config2__BillingFrequency__c,Apttus_Config2__ParentAssetId__r.Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__BillingStartDate__c, Apttus_Config2__BillingRule__c, Apttus_Config2__BillingEndDate__c, Apttus_Config2__BasePrice__c,APTS_BasePriceOverride__c,Apttus_Config2__ParentBundleNumber__c, Apttus_Config2__PrimaryLineNumber__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__LineNumber__c, Apttus_Config2__ExtendedPrice__c, APTS_SourceSystem__c, Apttus_Config2__NetPrice__c, Apttus_Config2__OptionPrice__c,Apttus_Config2__NetUnitPrice__c, Apttus_Config2__AdjustedPrice__c, Apttus_Config2__BaseExtendedPrice__c,Apttus_Config2__ProductId__r.Name,APTS_Physical_Asset__c,Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,Apttus_Config2__BusinessObjectId__c, Apttus_Config2__BusinessObjectType__c, Apttus_Config2__LineType__c,Apttus_Config2__AssetStatus__c, Apttus_Config2__Description__c, Apttus_Config2__ProductId__c, Apttus_Config2__ChargeType__c, Apttus_Config2__BundleAssetId__c, Apttus_Config2__AccountId__c,Apttus_CMConfig__AgreementId__c,Apttus_Config2__IsInactive__c,APTS_Type_Of_Contract__c,APTS_Is_Primary_L1_Line__c,Apttus_Config2__OptionId__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__Quantity__c,Apttus_Config2__IsOptionRollupLine__c, Apttus_Config2__HasOptions__c, Apttus_Config2__BillToAccountId__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__ChargeType__c, Apttus_Config2__BundleAssetId__r.Apttus_Config2__LineNumber__c From Apttus_Config2__AssetLineItem__c where Apttus_CMConfig__AgreementId__c IN : agreementList and Apttus_Config2__IsInactive__c = false", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));

    }
}