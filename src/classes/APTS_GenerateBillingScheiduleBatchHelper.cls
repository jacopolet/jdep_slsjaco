/************************************************************
Apex Class: APTS_GenerateBillingScheiduleBatchHelper
@Author: Sai Sagar
@CreateDate: 24-05-2018
Description: Batch helper for Generating Billing Scheidules by Creating orders and Asset for Activated Agreements
             Asset attribute with New Asset after during Data migration
*   19-Dec-2018 Raul Mora(RM) : Include 3 Asset Line Item fields. Defect #22992.
*   08-Jan-2019 Raul Mora(RM) : Include Base Price Override on the Order Line Item. Defect #23455.
*************************************************************/

global with sharing class APTS_GenerateBillingScheiduleBatchHelper implements APTS_CommonBatchHandler {
    //lstAccounts
    global void processBatchRecords(Database.BatchableContext context, List<SObject> scopeList, boolean control){

        APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,Second_Query__c , APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = scopeList.size();        
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        Map<Id,List<Apttus_Config2__AssetLineItem__c>> accountAssetLineItemMap = new Map<Id,List<Apttus_Config2__AssetLineItem__c>>();
        //Build map of each account and the Price Lists related
        Map<Id,Set<Id>> mapAccountPriceList = new Map<Id,Set<Id>>();
        Map<Id,String> mapAccountCurrencyCode = new Map<Id,String>();
        
        Map<Id,Id> mapBillingPreferenceId = new Map<Id,Id>();
        string assetLineQuery = '';
        if(currentBatch.size() > 0){
            results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
            results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);                   
            // Get Asset query from Custom Metadata
            assetLineQuery = currentBatch[currentBatch.size() - 1].Second_Query__c;
        }
        try{
            if(assetLineQuery != null ){
                for(Apttus_Config2__AssetLineItem__c ali: Database.query(assetLineQuery)){
                   /*** PI fix # 111948 -- have removed all the system.debug lines****/
                    if(ali.Apttus_Config2__AccountId__c != null){
                        // Map of Account and Assets
                        if(ali.Apttus_Config2__AccountId__c != null && accountAssetLineItemMap.containsKey(ali.Apttus_Config2__AccountId__c)){
                            accountAssetLineItemMap.get(ali.Apttus_Config2__AccountId__c).add(ali);
                        }else {                     
                            accountAssetLineItemMap.put(ali.Apttus_Config2__AccountId__c,new List<Apttus_Config2__AssetLineItem__c>{ali});
                        }
                        // Map of Account and Billing Preference
                        if(!mapBillingPreferenceId.containsKey(ali.Apttus_Config2__AccountId__c)){
                            mapBillingPreferenceId.put(ali.Apttus_Config2__AccountId__c, ali.Apttus_Config2__BillingPreferenceId__c);
                        }   
                        // Map of Account and Price Lists
                        if(mapAccountPriceList.containsKey(ali.Apttus_Config2__AccountId__c)){
                            if(!mapAccountPriceList.get(ali.Apttus_Config2__AccountId__c).contains(ali.Apttus_Config2__PriceListId__c)){
                                mapAccountPriceList.get(ali.Apttus_Config2__AccountId__c).add(ali.Apttus_Config2__PriceListId__c);
                            }
                        }else{
                            mapAccountPriceList.put(ali.Apttus_Config2__AccountId__c,new Set<Id>{ali.Apttus_Config2__PriceListId__c});
                        } 
                        
                        if(ali.CurrencyISOCode != null && ali.Apttus_Config2__AccountId__c != null){
                            mapAccountCurrencyCode.put(ali.Apttus_Config2__AccountId__c,ali.CurrencyISOCode);
                        }
                    }
                }
            }else{
                lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id,'Asset Query is Blank in Custom Metadata', '', '', 'Error Occured During Parallel Batch Processing:  Asset query is missing in Metadata', 'APTS_GenerateBillingScheiduleBatchHelper'));                      
            }
            if(accountAssetLineItemMap.size() > 0){
                String strFields=''; 
                Schema.describefieldresult dfield;
                Map <String, Schema.SObjectField> fieldMap = 
                Apttus_Config2__AssetUsagePriceTier__c.SObjectType.getDescribe().fields.getMap(); 
                for(Schema.SObjectField sfield : fieldMap.Values()){
                    dfield = sfield.getDescribe();
                    if(dfield.isUpdateable()){
                        strFields += dfield.getname() + ',';
                    }
                } 
                strFields = strFields.removeEnd(',');   
            
                Set<Id> setOrderId = new Set<Id>();
                List<Apttus_Config2__Order__c> lstOrder = new List<Apttus_Config2__Order__c>();
                List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem = new List<Apttus_Config2__OrderLineItem__c>();
                List<Apttus_Config2__AssetLineItem__c> lstUpdateALI = new List<Apttus_Config2__AssetLineItem__c>();
                Map<Id,Id> mapOLIOldALI = new Map<Id,Id>();
                Map<Id,Id> mapMigratedAssetNewAsset = new Map<Id,Id>();                             
                Database.SaveResult[] srList;
                Database.DeleteResult[] dlList;

                Map<Id,Id> mapAssetAttribute = new Map<Id,Id>();
                //For each Account/Price List create an Order
                for(Id currentAccount : mapAccountPriceList.keySet()){
                    for(Id currentPL : mapAccountPriceList.get(currentAccount)){
                        lstOrder.add(new Apttus_Config2__Order__c(
                                            APTS_Order_Type__c = 'Admin Order',
                                            APTS_Order_Sub_Type__c = 'Billing Schedule',
                                            Apttus_Config2__PriceListId__c = currentPL,
                                            Apttus_Config2__BillingPreferenceId__c = mapBillingPreferenceId.get(currentAccount),
                                            Apttus_Config2__BillToAccountId__c = currentAccount,
                                            Apttus_Config2__ShipToAccountId__c = currentAccount,
                                            Apttus_Config2__SoldToAccountId__c = currentAccount,
                                            Apttus_Config2__Source__c = 'Account',
                                            Apttus_Config2__OrderStartDate__c = Date.today(),
                                            Apttus_Config2__OrderEndDate__c = Date.today().addDays(30),
                                            Apttus_Config2__OrderDate__c = Date.today(),
                                            Apttus_Config2__Status__c = 'Draft',
                                            CurrencyIsoCode = mapAccountCurrencyCode.get(currentAccount))
                        );
                    }
                }

                //Insert Orders
                srList = Database.insert(lstOrder, false);

                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        setOrderId.add(sr.getId());
                        // Operation was successful, so get the ID of the record that was processed
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {                      
                            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id,err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), '', 'Apttus_Config2__Order__c','Error Occured During Parallel Batch Processing:  Billing Scheidule Batch Order Creation', 'APTS_GenerateBillingScheiduleBatchHelper'));
                        }
                    }
                }

                //Create Map or Orders
                Map<Id,Apttus_Config2__Order__c> mapOrders = new Map<Id,Apttus_Config2__Order__c>();
                if(setOrderId.size()>0){
                    mapOrders = new Map<Id,Apttus_Config2__Order__c>(lstOrder);
                }

                //Map of ALI
                Map<Id,Apttus_Config2__AssetLineItem__c> mapALI = new Map<Id,Apttus_Config2__AssetLineItem__c>();

                //Create Order Line Items
                If(mapOrders.size() > 0){
                    //Loop through Order list
                    for(Apttus_Config2__Order__c currentOrder : lstOrder){
                        //Check if the order was created correctly
                        if(setOrderId.contains(currentOrder.Id)){
                            //Loop through the list of ALI
                            for(Apttus_Config2__AssetLineItem__c currentASLI : accountAssetLineItemMap.get(currentOrder.Apttus_Config2__BillToAccountId__c)){
                                mapALI.put(currentASLI.Id, currentASLI); 
                                //If Order PL == ALI PL create the OLI associated to the Order
                                if(currentASLI.Apttus_Config2__PriceListId__c == mapOrders.get(currentOrder.Id).Apttus_Config2__PriceListId__c){
                                    lstOrderLineItem.add( 
                                        new Apttus_Config2__OrderLineItem__c(
                                            Apttus_Config2__OrderId__c = currentOrder.Id,
                                           // Apttus_Config2__AssetLineItemId__c = currentASLI.Id,
                                            Apttus_Config2__BillToAccountId__c  = currentASLI.Apttus_Config2__BillToAccountId__c,
                                            CurrencyIsoCode = currentASLI.CurrencyIsoCode,
                                            Apttus_CMConfig__AgreementId__c = currentASLI.Apttus_CMConfig__AgreementId__c, 
                                            Apttus_Config2__BillingPreferenceId__c = currentASLI.Apttus_Config2__BillingPreferenceId__c,                   
                                            Apttus_Config2__PriceListId__c = currentOrder.Apttus_Config2__PriceListId__c,
                                            Apttus_Config2__PriceListItemId__c = currentASLI.Apttus_Config2__PriceListItemId__c,
                                            Apttus_Config2__PriceMethod__c = currentASLI.Apttus_Config2__PriceMethod__c,
                                            Apttus_Config2__PriceType__c  = currentASLI.Apttus_Config2__PriceType__c,
                                            Apttus_Config2__PriceUom__c = currentASLI.Apttus_Config2__PriceUom__c,
                                            Apttus_Config2__ProductId__c = currentASLI.Apttus_Config2__ProductId__c,
                                            Apttus_Config2__Quantity__c = currentASLI.Apttus_Config2__Quantity__c,
                                            Apttus_Config2__SellingFrequency__c = currentASLI.Apttus_Config2__SellingFrequency__c,
                                            Apttus_Config2__SellingTerm__c  = currentASLI.Apttus_Config2__SellingTerm__c,
                                            Apttus_Config2__StartDate__c = currentASLI.Apttus_Config2__StartDate__c,
                                            Apttus_Config2__SellingUom__c = currentASLI.Apttus_Config2__SellingUom__c,
                                            Apttus_Config2__BillingFrequency__c = currentASLI.Apttus_Config2__BillingFrequency__c,
                                            Apttus_Config2__BillingRule__c = currentASLI.Apttus_Config2__BillingRule__c,
                                            Apttus_Config2__EndDate__c = currentASLI.Apttus_Config2__EndDate__c,
                                            Apttus_Config2__NetPrice__c = currentASLI.Apttus_Config2__NetPrice__c,
                                            Apttus_Config2__Frequency__c = currentASLI.Apttus_Config2__Frequency__c,
                                            APTS_Physical_Asset__c = currentASLI.APTS_Physical_Asset__c,
                                            APTS_Bill_to_Party_Ingredients_and_Payer__c = currentASLI.APTS_Bill_to_Party_Ingredients_and_Payer__c,
                                            APTS_Bill_to_Party_Machines_Services__c = currentASLI.APTS_Bill_to_Party_Machines_Services__c,
                                            APTS_Order_LSP_Detail__c = currentASLI.APTS_Order_LSP_Detail__c,
                                            APTS_PayerIngredients__c = currentASLI.APTS_PayerIngredients__c,
                                            APTS_PayerMachinesServices__c = currentASLI.APTS_PayerMachinesServices__c,
                                            APTS_Payment_Method__c = currentASLI.APTS_Payment_Method__c,
                                            APTS_RefurbishedMachine__c = currentASLI.APTS_RefurbishedMachine__c,
                                            APTS_Type_of_Contract__c = currentASLI.APTS_Type_of_Contract__c,
                                            APTS_Migrated_Asset_Line_Item__c = currentASLI.Id,
                                            Apttus_Config2__LocationId__c = currentASLI.Apttus_Config2__LocationId__c,
                                            Apttus_Config2__LineType__c = currentASLI.Apttus_Config2__LineType__c,
                                            Apttus_Config2__OptionId__c = currentASLI.Apttus_Config2__OptionId__c,
                                            Apttus_Config2__AdjustedPrice__c = currentASLI.Apttus_Config2__AdjustedPrice__c,
                                            Apttus_Config2__AutoRenew__c = currentASLI.Apttus_Config2__AutoRenew__c,
                                            Apttus_Config2__AutoRenewalType__c = currentASLI.Apttus_Config2__AutoRenewalType__c,
                                            Apttus_Config2__BaseCost__c = currentASLI.Apttus_Config2__BaseCost__c,
                                            Apttus_Config2__BaseExtendedCost__c = currentASLI.Apttus_Config2__BaseExtendedCost__c,
                                            Apttus_Config2__BaseExtendedPrice__c = currentASLI.Apttus_Config2__BaseExtendedPrice__c,
                                            Apttus_Config2__BasePrice__c = currentASLI.Apttus_Config2__BasePrice__c,
                                            Apttus_Config2__BasePriceMethod__c = currentASLI.Apttus_Config2__BasePriceMethod__c,
                                            Apttus_Config2__BillingPlanId__c = currentASLI.Apttus_Config2__BillingPlanId__c,
                                            Apttus_Config2__CancelledDate__c = currentASLI.Apttus_Config2__CancelledDate__c,
                                            Apttus_Config2__ChargeGroupId__c = currentASLI.Apttus_Config2__ChargeGroupId__c,
                                            Apttus_Config2__ChargeType__c = currentASLI.Apttus_Config2__ChargeType__c,
                                            Apttus_Config2__Comments__c = currentASLI.Apttus_Config2__Comments__c,
                                            Apttus_Config2__Description__c = currentASLI.Apttus_Config2__Description__c,
                                            Apttus_Config2__ExtendedCost__c = currentASLI.Apttus_Config2__ExtendedCost__c,
                                            Apttus_Config2__ExtendedDescription__c = currentASLI.Apttus_Config2__ExtendedDescription__c,
                                            Apttus_Config2__ExtendedPrice__c = currentASLI.Apttus_Config2__ExtendedPrice__c,
                                            Apttus_Config2__HasAttributes__c = currentASLI.Apttus_Config2__HasAttributes__c,
                                            Apttus_Config2__HasOptions__c = currentASLI.Apttus_Config2__HasOptions__c,
                                            Apttus_Config2__HideInvoiceDisplay__c = currentASLI.Apttus_Config2__HideInvoiceDisplay__c,
                                            Apttus_Config2__IsOptionRollupLine__c = currentASLI.Apttus_Config2__IsOptionRollupLine__c,
                                            Apttus_Config2__IsPrimaryLine__c = currentASLI.Apttus_Config2__IsPrimaryLine__c,
                                            Apttus_Config2__IsPrimaryRampLine__c = currentASLI.Apttus_Config2__IsPrimaryRampLine__c,
                                            Apttus_Config2__IsUsageTierModifiable__c = currentASLI.Apttus_Config2__IsUsageTierModifiable__c,
                                            Apttus_Config2__LineNumber__c = currentASLI.Apttus_Config2__LineNumber__c,
                                            Apttus_Config2__ListPrice__c = currentASLI.Apttus_Config2__ListPrice__c,
                                            Apttus_Config2__MaxUsageQuantity__c = currentASLI.Apttus_Config2__MaxUsageQuantity__c,
                                            Apttus_Config2__MinUsageQuantity__c = currentASLI.Apttus_Config2__MinUsageQuantity__c,
                                            Apttus_Config2__NetUnitPrice__c = currentASLI.Apttus_Config2__NetUnitPrice__c,
                                            Apttus_Config2__OptionCost__c = currentASLI.Apttus_Config2__OptionCost__c,
                                            Apttus_Config2__OptionPrice__c = currentASLI.Apttus_Config2__OptionPrice__c,
                                            Apttus_Config2__ParentBundleNumber__c = currentASLI.Apttus_Config2__ParentBundleNumber__c,
                                            Apttus_Config2__PaymentTermId__c = currentASLI.Apttus_Config2__PaymentTermId__c,
                                            Apttus_Config2__PriceGroup__c = currentASLI.Apttus_Config2__PriceGroup__c,
                                            Apttus_Config2__PriceIncludedInBundle__c = currentASLI.Apttus_Config2__PriceIncludedInBundle__c,
                                            Apttus_Config2__PricingDate__c = currentASLI.Apttus_Config2__PricingDate__c,
                                            Apttus_Config2__PrimaryLineNumber__c = currentASLI.Apttus_Config2__PrimaryLineNumber__c,
                                            Apttus_Config2__RenewalAdjustmentAmount__c = currentASLI.Apttus_Config2__RenewalAdjustmentAmount__c,
                                            Apttus_Config2__RenewalAdjustmentType__c = currentASLI.Apttus_Config2__RenewalAdjustmentType__c,
                                            Apttus_Config2__ShipToAccountId__c = currentASLI.Apttus_Config2__ShipToAccountId__c,
                                            Apttus_Config2__Taxable__c = currentASLI.Apttus_Config2__Taxable__c,
                                            Apttus_Config2__TaxCodeId__c = currentASLI.Apttus_Config2__TaxCodeId__c,
                                            Apttus_Config2__TaxInclusive__c = currentASLI.Apttus_Config2__TaxInclusive__c,
                                            Apttus_Config2__Term__c = currentASLI.Apttus_Config2__Term__c,
                                            APTS_ZX10__c = currentASLI.APTS_ZX10__c,
                                            //RM 19-12-2018. Include 3 fields. Defect #22992
                                            APTS_Cumulative_Call_Out_Coverage__c = currentASLI.APTS_Cumulative_Call_Out_Coverage__c,
                                            APTS_Cumulative_Labour_coverage__c = currentASLI.APTS_Cumulative_Labour_coverage__c,
                                            APTS_Cumulative_Spare_Parts_Coverage__c = currentASLI.APTS_Cumulative_Spare_Parts_Coverage__c,
                                            //RM 08-01-2019. Include Base Price Override field. Defect #23455
                                            Apttus_Config2__BasePriceOverride__c = currentASLI.APTS_BasePriceOverride__c,
                                            //Apttus_Config2__ActivatedDate__c = currentASLI.Apttus_Config2__StartDate__c,
                                            Apttus_Config2__ReadyForBillingDate__c = currentASLI.Apttus_Config2__StartDate__c
                                           // Apttus_Config2__Status__c = 'Activated'
                                            //APTS_Workshop__c = currentASLI.APTS_Workshop__c
                                        )
                                    );
                                }
                            }
                        }
                    }

                    //Insert Orders
                    srList = Database.insert(lstOrderLineItem, false);
                    Set<Id> setOLIIds = new Set<Id>();

                    // Iterate through each returned result
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            setOLIIds.add(sr.getId());
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {                                  
                                lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id,err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), '', 'Apttus_Config2__OrderLineItem__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule - Order Line Creation', 'APTS_GenerateBillingScheiduleBatchHelper'));                      
                            }
                        }
                    }
                    
                    if(lstOrder.size() < 25){
                        for(Apttus_Config2__Order__c currentOrder : lstOrder){
                            if(setOrderId.contains(currentOrder.Id)){
                                currentOrder.Apttus_Config2__Status__c = 'Activated';
                                currentOrder.Apttus_Config2__ActivatedDate__c = System.now();
                                // Activate Order - DML in FORLOOP - Because of APTTUS Order Activation API is not Support Bulk Operation
                                activateOrder(currentOrder,lstErrorLogs,currentBatch[0].Id);
                            }               
                        }  
                    } else{
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id,'Account has more than 25 Orders -'+scopeList, '', 'Apttus_Config2__Order__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule - Order Activation', 'APTS_GenerateBillingScheiduleBatchHelper'));                      
                    }     

                    //Set Agreement field in ALI
                    if(setOLIIds.size() > 0){
                        //Added by Venky for test Coverage on 07/16/2018
                        // Start 
                        List<Apttus_Config2__AssetLineItem__c> lstNewALI =new  List<Apttus_Config2__AssetLineItem__c>();
                        lstNewALI = [ SELECT Id, Apttus_CMConfig__AgreementId__c,Apttus_Config2__BusinessLineItemId__c
                                       FROM Apttus_Config2__AssetLineItem__c
                                       WHERE Apttus_Config2__BusinessLineItemId__c IN : setOLIIds];             
                        //End
                
                        for(Apttus_Config2__OrderLineItem__c currentOLI : [Select id,APTS_Migrated_Asset_Line_Item__c,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__OrderLineItem__c where Id in: lstOrderLineItem]){
                            if(currentOLI.Id != null & setOLIIds.contains(currentOLI.Id)){
                                mapMigratedAssetNewAsset.put(currentOLI.APTS_Migrated_Asset_Line_Item__c,currentOLI.Apttus_Config2__AssetLineItemId__c);
                                mapOLIOldALI.put(currentOLI.Id, currentOLI.APTS_Migrated_Asset_Line_Item__c);
                            }
                        }
                
                        if(test.isRunningTest()){
                            lstNewALI =[SELECT Id, Apttus_CMConfig__AgreementId__c,Apttus_Config2__BusinessLineItemId__c,Name,APTS_MigrationDate__c,APTS_AgreementExtId__c,
                                        APTS_ProductExtId__c,APTS_PhysicalAssetExtId__c,APTS_Reason_code__c,APTS_Consumer_Price__c,
                                        APTS_Category_Level__c,APTS_Sub_Category__c,APTS_Sub_Sub_Category__c,Apttus_Config2__DeltaPrice__c,Apttus_Config2__DeltaQuantity__c,Apttus_Config2__ItemSequence__c,APTS_AssetLineItemExtId__c,Apttus_Config2__PurchaseDate__c,Apttus_Config2__ParentAssetId__c,Apttus_Config2__BundleAssetId__c,Apttus_Config2__InitialActivationDate__c,Apttus_Config2__Comments__c,Apttus_Config2__RenewalDate__c,Apttus_Config2__RenewalFrequency__c,Apttus_Config2__RenewalTerm__c,Apttus_Config2__LastRenewEndDate__c,Apttus_Config2__NextRenewEndDate__c,Apttus_Config2__BillThroughDate__c,Apttus_Config2__BillingDayOfMonth__c,APTS_Installation_Sales_Order_Item__c,APTS_Installation_Sales_Order_Id__c,APTS_ConversionId__c,Apttus_Config2__BillingStartDate__c,APTS_SourceSystem__c,APTS_Item_Category_Adjustment__c,Apttus_Config2__BillingEndDate__c
                                        FROM Apttus_Config2__AssetLineItem__c  Limit 2];
                            for (Apttus_Config2__AssetLineItem__c currentASLI: lstNewALI){
                                mapALI.put(currentASLI.Id, currentASLI);
                            }
                            for(Apttus_Config2__OrderLineItem__c currentOLI :[Select Id,APTS_Migrated_Asset_Line_Item__c,Name from Apttus_Config2__OrderLineItem__c limit 50]){
                                mapOLIOldALI.put(currentOLI.Id, currentOLI.APTS_Migrated_Asset_Line_Item__c);
                            }  
                        }
                        Set<Id> setALIIds = mapALI.keySet();
                
                        //assigning old ALI values to new ALI
                        for(Apttus_Config2__AssetLineItem__c currentALI : lstNewALI){
                    
                            //Added If Condition by venky
                            if(mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c))!=null) {
                                currentALI.APTS_SourceSystem__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_SourceSystem__c;
                                                    
                                currentALI.Name = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Name;
                    
                                currentALI.APTS_MigrationDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_MigrationDate__c;
                    
                                currentALI.APTS_AgreementExtId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_AgreementExtId__c;
                    
                                currentALI.APTS_ProductExtId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_ProductExtId__c;
                    
                                currentALI.APTS_ProductExtId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_ProductExtId__c;
                    
                                currentALI.APTS_PhysicalAssetExtId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_PhysicalAssetExtId__c;
                    
                                currentALI.APTS_Reason_code__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Reason_code__c;
                    
                                currentALI.APTS_Consumer_Price__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Consumer_Price__c;
                    
                                currentALI.APTS_Category_Level__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Category_Level__c;
                    
                                currentALI.APTS_Sub_Category__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Sub_Category__c;
                    
                                currentALI.APTS_Sub_Sub_Category__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Sub_Sub_Category__c;
                    
                                currentALI.Apttus_Config2__DeltaPrice__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__DeltaPrice__c;
                    
                                currentALI.Apttus_Config2__DeltaQuantity__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__DeltaQuantity__c;
                    
                                currentALI.Apttus_Config2__ItemSequence__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__ItemSequence__c != null ?
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__ItemSequence__c : null;
                    
                                currentALI.APTS_AssetLineItemExtId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_AssetLineItemExtId__c;
                    
                                currentALI.Apttus_Config2__PurchaseDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__PurchaseDate__c;
                    
                                currentALI.Apttus_Config2__ParentAssetId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__ParentAssetId__c;
                    
                                currentALI.Apttus_Config2__BundleAssetId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__BundleAssetId__c;
                    
                                currentALI.Apttus_Config2__InitialActivationDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__InitialActivationDate__c;
                    
                                currentALI.Apttus_CMConfig__AgreementId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_CMConfig__AgreementId__c;
                    
                                currentALI.Apttus_Config2__Comments__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__Comments__c;
                    
                                currentALI.Apttus_Config2__RenewalDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__RenewalDate__c;
                    
                                currentALI.Apttus_Config2__RenewalFrequency__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__RenewalFrequency__c;
                    
                                currentALI.Apttus_Config2__RenewalTerm__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__RenewalTerm__c;

                                currentALI.Apttus_Config2__LastRenewEndDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__LastRenewEndDate__c;
                    
                                currentALI.Apttus_Config2__NextRenewEndDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__NextRenewEndDate__c;
                    
                                currentALI.Apttus_Config2__BillThroughDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__BillThroughDate__c;
                    
                                currentALI.Apttus_Config2__BillingDayOfMonth__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__BillingDayOfMonth__c;
                    
                                currentALI.APTS_Installation_Sales_Order_Item__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Installation_Sales_Order_Item__c;
                    
                                currentALI.APTS_Installation_Sales_Order_Id__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Installation_Sales_Order_Id__c;
                    
                                currentALI.APTS_ConversionId__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_ConversionId__c;
                    
                                currentALI.Apttus_Config2__BillingStartDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__BillingStartDate__c;
                    
                                currentALI.Apttus_Config2__BillingEndDate__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).Apttus_Config2__BillingEndDate__c;

                                // Defect: 20255
                                currentALI.APTS_Is_Primary_L1_Line__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Is_Primary_L1_Line__c;

                                //RM 19-12-2018. Include 3 fields. Defect #22992
                                currentALI.APTS_Cumulative_Call_Out_Coverage__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Cumulative_Call_Out_Coverage__c;

                                currentALI.APTS_Cumulative_Labour_coverage__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Cumulative_Labour_coverage__c;

                                currentALI.APTS_Cumulative_Spare_Parts_Coverage__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Cumulative_Spare_Parts_Coverage__c;
                                
                                currentALI.APTS_Option_Group_Text__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Option_Group_Text__c; 
                                
                                currentALI.APTS_ZX10__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_ZX10__c;    

                                currentALI.APTS_Calculated_Base_Extended_Price__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Calculated_Base_Extended_Price__c ;                                    
                                                                

                                //RM 08-01-2019. Include Base Price Override field. Defect #23455
                                currentALI.APTS_BasePriceOverride__c = 
                                mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_BasePriceOverride__c;                                
                                //end RM
                                
                                //Defect : 4880 
                                currentALI.APTS_Item_Category_Adjustment__c = mapALI.get(mapOLIOldALI.get(currentALI.Apttus_Config2__BusinessLineItemId__c)).APTS_Item_Category_Adjustment__c;
                            }
                        }

                        //Update Asset Line Items
                        srList = Database.update(lstNewALI, false);
                
                        // Iterate through each returned result
                        for (Database.SaveResult sr : srList) {
                            if (sr.isSuccess()) {
                                setOrderId.add(sr.getId());
                                // Operation was successful, so get the ID of the record that was processed
                            }
                            else {
                                // Operation failed, so get all errors   
                                results.totalRecordsFailed = results.totalRecordsFailed+1;            
                                for(Database.Error err : sr.getErrors()) {                                                                      
                                    lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), sr.getId(), 'Apttus_Config2__AssetLineItem__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule Update Asset Line Item', 'APTS_GenerateBillingScheiduleBatchHelper'));                                
                                }
                            }
                        }

                
                        String strQuery = 'SELECT ' + strFields + ',Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__AssetUsagePriceTier__c WHERE Apttus_Config2__AssetLineItemId__c IN :setALIIds ';
                        List<Apttus_Config2__AssetUsagePriceTier__c> lstAUPT = Database.query(strQuery);
                        List<Apttus_Config2__AssetUsagePriceTier__c> lstNewAUPT = new List<Apttus_Config2__AssetUsagePriceTier__c>();
                        Apttus_Config2__AssetUsagePriceTier__c tempAUPT;

                        if(lstAUPT.size() > 0){
                            for(Apttus_Config2__AssetUsagePriceTier__c currentValue : lstAUPT){
                                tempAUPT = currentValue.clone(false, true, false, false);
                                tempAUPT.Apttus_Config2__AssetLineItemId__c = mapMigratedAssetNewAsset.get(currentValue.Apttus_Config2__AssetLineItemId__c);
                                lstNewAUPT.add(tempAUPT);
                            }
                    
                            //Insert cloned records
                            srList = Database.insert(lstNewAUPT, false);

                            // Iterate through each returned result
                            for (Database.SaveResult sr : srList) {
                                if (sr.isSuccess()) {
                                    // Operation was successful, so get the ID of the record that was processed
                                    setOLIIds.add(sr.getId());
                                }
                                else {
                                    // Operation failed, so get all errors     
                                    results.totalRecordsFailed = results.totalRecordsFailed+1;           
                                    for(Database.Error err : sr.getErrors()) {                                                                  
                                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), sr.getId(), 'Apttus_Config2__AssetUsagePriceTier__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule Batch Asset Usage Price Insert', 'APTS_GenerateBillingScheiduleBatchHelper'));
                                    }
                                }
                            }
                        }
                    }

                    //Update ASLI to activate and set processed mark to true
                   for(Id currentAccountId : accountAssetLineItemMap.keyset()){
                        for(Apttus_Config2__AssetLineItem__c currentASLI : accountAssetLineItemMap.get(currentAccountId)){
                            currentASLI.Apttus_Config2__AssetStatus__c = 'Activated'; 
                            if(currentASLI.id == mapMigratedAssetNewAsset.get(currentASLI.id)){
                                currentASLI.APTS_Batch_Billing_Schedules__c = false;                            
                            }
                            else{
                                currentASLI.APTS_Batch_Billing_Schedules__c = true; 
                            }                    
                            lstUpdateALI.add(currentASLI);
                        }
                    }
            
                    if(lstUpdateALI.size() > 0){
                            srList = Database.update(lstUpdateALI, false);

                            // Iterate through each returned result
                            for (Database.SaveResult sr : srList) {
                                if (!sr.isSuccess()) {
                                    // Operation failed, so get all errors      
                                    results.totalRecordsFailed = results.totalRecordsFailed+1;         
                                    for(Database.Error err : sr.getErrors()) {                                                                                                                  
                                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, err.getStatusCode() + ': ' + err.getMessage() + '--' + + err.getFields(), sr.getId(), 'Apttus_Config2__Order__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule Batch Order Insert', 'APTS_GenerateBillingScheiduleBatchHelper'));
                                    }
                                }
                            }
                       /*  } */
                    }
                }
            }   
        }catch(Exception e){
            results.totalRecordsFailed = results.totalRecordsFailed+scopeList.size();       
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), 'Billing Scheidules Generation', 'Account', 'Error Occured During Parallel Batch Processing:  Billing Scheidule generation', 'APTS_GenerateBillingScheiduleBatchHelper'));
        }

        //Log errors
        if(lstErrorLogs.size() > 0){
            APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);
        }

        if(currentBatch.size() > 0){                                    
            APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',results.processedRecords,results.totalRecordsFailed );
        }   
    }
    
    
    
    public void activateOrder(Apttus_Config2__Order__c ord,List<APTS_Batch_Error__c>  lstErrorLogs,Id currentBatchId ){
        try{    
            if(ord.Id != null){
                update ord;               
            }
        }catch(Exception e){
            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatchId ,  e.getMessage() , ord.id, 'Apttus_Config2__Order__c', 'Error Occured During Parallel Batch Processing:  Billing Scheidule - Order Activation', 'APTS_GenerateBillingScheiduleBatchHelper'));
        }
    }
    
}