/**
* Class Name : APTS_ExecuteBillingScheduleBatch
* Description : Admin Order Creation for Recurring Billing Schedules on click of button from Order detail page                   
* Author : Amit // This class will not be moved to Production this is only for testing purpose
* Date Created : 12/05/2018
* Revision V101 : Balashanthi A - 21/04/2019 Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
**/
global class APTS_ExecuteBillingScheduleBatch implements Database.Batchable<sObject>{
    
    public Id recordId;
    public Map<String, Id> adminOrderCreatedInEachChunk = new Map<String,Id>();
    private static final String FIXEDTERMFLAG = 'Z';
    private static final String FIXEDTERMSAPTYPE = 'XD01';
    private static final String FIXEDTERMNAME = 'Fixed Term dummy';
    
    //<<++ Revision V102 : Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
    //public Map<Id,Apttus_Billing__BillingSchedule__c> p1LineBSStartDateMap = new Map<Id,Apttus_Billing__BillingSchedule__c>();
    //public Map<Id,Apttus_Billing__BillingSchedule__c> p1LineBSEndDateMap = new Map<Id,Apttus_Billing__BillingSchedule__c>();
    public Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate = new Map<Id,Apttus_Config2__OrderLineItem__c>();
    //<<++ Revision V101 : Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
    public Map<String,Date> primaryL1DateMap = new Map<String,Date>();
    Map<String,String> invoiceMap = APTS_BIRUtils.getInvoiceDeliveryPreferenceMapping(); 
    
    global APTS_ExecuteBillingScheduleBatch(Id orderId){
        recordId = orderId;
    
    }

    /** Method Name : start
    * Description : start method of Batch class
    **/

    /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        Date currentDate = Date.today();
        String query = 'SELECT Id,'+
        'Apttus_Billing__AgreementLineItemId__c,'+
        'Apttus_Billing__AssetLineItemId__c,'+ 
        'Apttus_Billing__BillToAccountId__c,'+ 
        'Apttus_Billing__BillingRule__c,'+ 
        'Apttus_Billing__FeeAmount__c,'+ 
        'Apttus_Billing__IsSuperseded__c,'+ 
        'Apttus_Billing__OrderLineItemId__c,'+ 
        'Apttus_Billing__PeriodEndDate__c,'+ 
        'Apttus_Billing__PeriodStartDate__c,'+ 
        'Apttus_Billing__Quantity__c,'+ 
        'Apttus_Billing__ReadyForInvoiceDate__c,'+ 
        'Apttus_Billing__Status__c,'+ 
        'Apttus_Billing__SupersededScheduleId__c,'+ 
        'Apttus_Billing__Type__c,'+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c,'+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,'+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,'+
        'Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Name__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__r.CurrencyIsoCode,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Fixed_Term_Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.Apttus__Primary_Contact__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_BasePriceOverride__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ItemSequence__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingRule__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Line__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementLineItemId__r.Apttus_CMConfig__BasePriceOverride__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Item_Category__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Asset_Line_Item_Number__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Payment_Method__r.APTS_Payment_Method_Code__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PaymentTermId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Billing_Rule_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Type__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Ingredients_and_Payer__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Bill_to_Party_Machines_Services__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ExtendedPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BaseExtendedPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BasePrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BusinessObjectId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ListPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__NetUnitPrice__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ParentAssetId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ParentBundleNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Physical_Asset__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PhysicalAssetExtId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PricingDate__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Option_Group_Text__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Call_Out_Coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Labour_coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Cumulative_Spare_Parts_Coverage__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__IsPrimaryLine__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__HasOptions__c,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ChargeType__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Type_of_Contract__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceListItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__OptionId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceUom__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PrimaryLineNumber__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Quantity__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Reason_code__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_RefurbishedMachine__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingFrequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingTerm__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__SellingUom__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ShipToAccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Ship_to_Party__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__AccountId__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerIngredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_PayerMachinesServices__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LocationId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__EndDate__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_Config2__Frequency__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_ZX10__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Item_Category_Adjustment__c,'+
        'Apttus_Billing__AssetLineItemId__r.APTS_Is_Primary_L1_Asset__r.Apttus_Config2__BusinessLineItemId__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Name,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.RecordTypeId,'+ 
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Payer_Machines_Services__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Payer_Ingredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_Ingredients__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Bill_to_Party_MachServ__c,'+  
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.Apttus__Primary_Contact__c, '+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Check_on_Account_Machines__c,'+
        'Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c \n'+
        ' FROM '+APTS_BIRUtils.EMPTY_STRING+'Apttus_Billing__BillingSchedule__c';
    query += ' WHERE Apttus_Billing__Status__c = \'Pending Billing\' AND Apttus_Billing__Type__c = \'Contracted\'  AND Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c  != \'Trial\'';
    query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__IsSuperseded__c = false AND Apttus_Billing__ReadyForInvoiceDate__c <=:currentDate AND Apttus_Billing__AssetLineItemId__c != NULL';
    query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillToAccountId__c != NULL AND Apttus_Billing__AssetLineItemId__r.Apttus_CMConfig__AgreementId__c != NULL';
    query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__PriceType__c != \'One Time\'';
    query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c != \'One Time\'';
    query += APTS_BIRUtils.EMPTY_STRING+' AND Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.Id =:recordId';
    //system.debug('query==>'+query);
        return Database.getQueryLocator(query);
    }

    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext, List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords) {
        List<Apttus_Billing__BillingSchedule__c> bsToBeProcessed = new List<Apttus_Billing__BillingSchedule__c>();
        List<Apttus_Billing__BillingSchedule__c> toBeProcessedFixedTermList = new List<Apttus_Billing__BillingSchedule__c>();
        Set<Id> orderIdSet = new Set<Id>();  
        Boolean muteSAPCall  = false;
        Map<String, APTS_MuteSAPSubmission__c> customSettingMap = APTS_MuteSAPSubmission__c.getAll();
        if(customSettingMap.containsKey('Mute SAP Call') 
            && customSettingMap.get('Mute SAP Call') != null){
            muteSAPCall = customSettingMap.get('Mute SAP Call').APTS_ISSAPCallDisabled__c;
        }
        //system.debug('billingScheduleRecords==>'+billingScheduleRecords);
        try{
            if(!billingScheduleRecords.isEmpty()){
                //system.debug('billingScheduleRecords 1==>');
                for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                    if(billingScheduleList.Apttus_Billing__OrderLineItemId__c != null){
                        if(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c != null){
                            if(FIXEDTERMFLAG.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c)){
                                // Allow XD01 SAP order Type Orders with Z indicator
                                if(FIXEDTERMSAPTYPE.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                    bsToBeProcessed.add(billingScheduleList);
                                }
                                // Allow Consumption Type of Contract with Z indicator
                                else if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){
                                    bsToBeProcessed.add(billingScheduleList);
                                }
                            }else{
                                //system.debug('billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Name__c==>'+billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Name__c);
                                if(FIXEDTERMNAME.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Name__c) ){
                                    toBeProcessedFixedTermList.add(billingScheduleList);
                                }
                                else{
                                    // Non "Z" indicator at Orders need to be processed
                                    bsToBeProcessed.add(billingScheduleList);
                                }
                            }
                            
                            
                        }
                    }else{
                        // Will run for Data Migration records - As migrated Records won't have Order Line item @ billing schedules
                        bsToBeProcessed.add(billingScheduleList);
                    }
                }
                //system.debug('########toBeProcessedFixedTermList######==>'+toBeProcessedFixedTermList);
                if(!toBeProcessedFixedTermList.IsEmpty()){
                    Map<String, Id> tempMap = APTS_RecurringBillingScheduleBatchHelper.createAdminOrderForFixedTerm(toBeProcessedFixedTermList,adminOrderCreatedInEachChunk,invoiceMap); 
                    //system.debug('########tempMap ######==>'+tempMap);
                    if(!tempMap.isEmpty()){
                        adminOrderCreatedInEachChunk.putAll(tempMap);
                    }
                }
                //system.debug('########bsToBeProcessed######==>'+bsToBeProcessed);
                if(!bsToBeProcessed.isEmpty()){
                    //Map<String, Id> tempMap = APTS_RecurringBillingScheduleBatchHelper.createAdminOrder(bsToBeProcessed,adminOrderCreatedInEachChunk); 
                    Map<String, Id> tempMap = APTS_RecurringBillingScheduleBatchHelper.createAdminOrder(bsToBeProcessed,adminOrderCreatedInEachChunk,primaryOrderLineToUpdate,invoiceMap,primaryL1DateMap);
                    if(!tempMap.isEmpty()){
                        adminOrderCreatedInEachChunk.putAll(tempMap);
                    }
                }
                    //system.debug('########adminOrderCreatedInEachChunk######==>'+adminOrderCreatedInEachChunk);
                    if(!adminOrderCreatedInEachChunk.isEmpty()){
                        orderIdSet.addAll(adminOrderCreatedInEachChunk.values());
                        if(!orderIdSet.isEmpty()
                            && !muteSAPCall){
                            APTS_RecurringBillingScheduleBatchHelper.submitOrdersToSAP(orderIdSet);
                        }
                    }
                
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDEREXECUTE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }
    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext) {}
    
}