/*******************************************************************************************
Name            : APTS_AgreementTriggerHandler
Created By      : Beulah Ann Thomas
Created Date    : 01/24/2018
Description     : Handler class of Agreement trigger 'APTS_AgreementTrigger'.
Version history : v1.0 - Created - Checks whether an Agreement is fixed term.

If a fixed term agreement is activated, then order,
                  order line item and asset line item has to be created with dummy
                  products through APTS_FixedTermAgreement class.
Test Class      : APTS_AgreementTriggerHandlerTest (80% code coverage)
*********************************************************************************************/
//v101 08-03-2018 Galin Georgiev - move check for trigger settings in trigger
/*********************************************************************************************
* Version History   : V102 
* Modified By       : Balashanthi A
* Modified Date     : 16-03-2018
* Change Description: For FD# 2801 FD_T_pOTC_030_Apttus Billing Management - Foundation
*                     added createBillingSetting(agreementList) in AfterUpdate Method.
*                     This method will create Billing Setting Record based on Bill To selection @ agreement header
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V103 
* Modified By       : Balashanthi A
* Modified Date     : 27-03-2018
* Change Description: For FD# 2801 FD_T_pOTC_030_Apttus Billing Management - Foundation
*                     invoked APTS_BIRUtils.createBillingSetting((Map<Id, Apttus__APTS_Agreement__c>) mapAgreements,
                                                                    (Map<Id, Apttus__APTS_Agreement__c>) mapOldAgreements) from AfterInsert Method.
*                     This Invokation will handle the creation of  Billing Setting Record for hierarchy account
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V104 
* Modified By       : Balashanthi A
* Modified Date     : 04-05-2018
* Change Description: For FD# 2801 FD_T_pOTC_030_Apttus Billing Management - Foundation
*                     Added one parameter for APTS_BIRUtils.createBillingSetting((Map<Id, Apttus__APTS_Agreement__c>) mapAgreements,
                                                                    (Map<Id, Apttus__APTS_Agreement__c>) mapOldAgreements) in AfterInsert & AfterUpdate
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V105
* Modified By       : Amit Singh
* Modified Date     : 25-05-2018
* Change Description: For FD# 3333 FD_T_pQTC_070_Apttus Rebate Management - Foundation
*                     Added one parameter for createAgmtVolumeObligation Method;
                      in AfterInsert & AfterUpdate
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V106
* Modified By       : Raul Orozco
* Modified Date     : 05-07-2018
* Change Description: Defect #16416
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V107
* Modified By       : Aftab Mohammed
* Modified Date     : 05-07-2018
* Change Description: Bulkification
***********************************************************************************************/
/*********************************************************************************************
* Version History  : V108
* Modified By       : jason.e.mactal
* Modified Date     : 09-26-2018
* Change Description: ALM: 19648 added updateVolumeAssumptionRecords() method
************************************************************************************************/
/*********************************************************************************************
* Version History  : V109
* Modified By       : Venky Muppalaneni
* Modified Date     : 05-13-2019
* Change Description: DOK31-154 Decomissioning Asset Amendments in the Agreement(Admin Order)
************************************************************************************************/
/*********************************************************************************************
* Version History  : V110
* Modified By       : Jagan Venkesan
* Modified Date     : 05-27-2019
* Change Description: DOK31-154 Creation of admin order for Register Machine
************************************************************************************************/
//V111 09-02-2019 :: Aarthi Pitchai - QTCFLEX1-911 Prevent creation of Non standard Indexation task for Amended Agreement
//V112 09-11-2019 :: Nikita Ermonskiy - QTCFLEX1-1228 Upon creation of agreement, set start date of agreement to today
//V113 20-04-2020:: Shahul- Added Custom label to Process Asset Count to Update assets(updateAssetsOnAgreementActivation) through batch if it exceeded limit

public without sharing class APTS_AgreementTriggerHandler implements ITriggerHandler
{

    public static boolean triggerDisabled = false;
    public static final String STANDARD = 'Standard Deal';
    public static final String CONSUMPTION = 'Consumption Model';
    public static final String YEARLY = 'Yearly';
    public static final String HALFYEARLY = 'Half-Yearly';
    public static final String FULLY_SIGNED = 'Fully Signed';
    public static final String ACTIVATED = 'Activated';
    private static String AGREEMENT = 'Apttus__APTS_Agreement__c';
    public static final String REGISTRATION_FORM = 'Registration Form';
    public static boolean isRenewalBatchExecuting = false;
    
    public static Set<String> setrecurs = new Set<String>();

    public Boolean isDisabled() {

        return triggerDisabled;
    }   
    //v101++>>

    /* After agreement is updated. */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> mapAgreements,
                            List<SObject> oldList, Map<Id, SObject> mapOldAgreements)
    {

        try
        {
            Map<Id, Apttus__APTS_Agreement__c> oldRecMap = (Map<Id, Apttus__APTS_Agreement__c>) mapOldAgreements;
            Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
            Map<Id,Id> agreementToAccountMap = new Map<Id,Id>();
            String registrationformID = Schema.getGlobalDescribe().get(AGREEMENT).getDescribe().getRecordTypeInfosByName().get('Registration Form').getRecordTypeId();
            
            List<Apttus__APTS_Agreement__c> activatedAgreementList = new List<Apttus__APTS_Agreement__c>();

            for(Apttus__APTS_Agreement__c newagr : (List<Apttus__APTS_Agreement__c>)newList){
                            
                if(newagr.Apttus__Status__c != oldRecMap.get(newagr.Id).Apttus__Status__c || newagr.Apttus__Status_Category__c != oldRecMap.get(newagr.Id).Apttus__Status_Category__c){
                    if(APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerAfterUpdate')){
                        APTS_CheckRecursive.processedSet.remove('APTS_AgreementTriggerHandlerAfterUpdate');
                    }
                }
            }
            
            //Recursive check
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerAfterUpdateVA')){
                Set <Id> aggWithUpdatedPricingDate = new Set<Id> ();
                for(Apttus__APTS_Agreement__c newAgg: (List<Apttus__APTS_Agreement__c>)mapAgreements.values()){
                    if(newAgg.APTS_PricingDate__c != oldRecMap.get(newAgg.Id).APTS_PricingDate__c){ //check if pricing date is changed
                        aggWithUpdatedPricingDate.add(newAgg.id);
                    }
                }
                updateVolumeAssumptionRecords(aggWithUpdatedPricingDate);//added by: jason.e.mactal 9/26/2018 V108
            }
            
            //Recursive check
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerAfterUpdate')){
                APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterUpdate');
                Set<Id> accountId = new Set<Id>();
                /* Added by Wendy Kelley - 14/2/2018 - Start */
                /* Activate agreeement when Status is changed to 'Fully Signed' */
                
                List <Apttus__APTS_Agreement__c> newstatuslist = new List <Apttus__APTS_Agreement__c> ();
                Map<Id, Apttus__APTS_Agreement__c> activatedAgreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
                Map<String, Id> agreementNoToIdMap = new Map<String, Id>();
                Set <Id> aggrId = new Set <Id>();
                Set<Id> agreementSet = new Set<Id>();
                for(Apttus__APTS_Agreement__c oAgg : (List<Apttus__APTS_Agreement__c>)newList) {                    
                    
                    /************ CHANGES FOR CER STARTS **************/

                    if(oldRecMap.get(oAgg.Id).Apttus__Status__c != ACTIVATED && oAgg.Apttus__Status__c == ACTIVATED)
                    {
                        if(!Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(oAgg.recordTypeId).getDeveloperName().equalsIgnoreCase('Registration_Form'))
                          newstatuslist.add(oAgg);

                        aggrId.add(oAgg.Id);
                        
                        //Enable Invoice Payment
                        agreementToAccountMap.put(oAgg.Id, oAgg.Apttus__Account__c);

                        //Contracted Products Only
                        Account oAccount = new Account(Id=oAgg.Apttus__Account__c);
                        oAccount.Contracted_Products_Only__c = !(oAgg.APTS_Order_Non_Contracted_Products__c);
                        accountUpdateMap.put(oAccount.Id, oAccount);

                        //ALI Agreement Field population
                        activatedAgreementList.add(oAgg);
                        activatedAgreementMap.put(oAgg.Id, oAgg);
                        agreementNoToIdMap.put(oAgg.Apttus__Agreement_Number__c, oAgg.Id);
                    }
                    
                }
                
                //Recursive check
                if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerAfterUpdateBS')){
                    for(APTS_Billing_Settings__c billingSetting : [SELECT APTS_Agreement_ID__c,
                                                                            APTS_Agreement_ID__r.Apttus__Account__c,
                                                                            APTS_Agreement_ID__r.Apttus__Account__r.Enable_Invoice_Payment_Flag__c,
                                                                            APTS_Payment_Term_Setting__c,
                                                                            APTS_Agreement_Billing_Type__c 
                                                                            FROM APTS_Billing_Settings__c
                                                                            WHERE APTS_Agreement_ID__c IN: agreementToAccountMap.keyset()
                                                                            AND APTS_Agreement_Billing_Type__c = 'Ingredients'
                                                                            ]){
                        Account oAccount;
                        if(accountUpdateMap.containsKey(billingSetting.APTS_Agreement_ID__r.Apttus__Account__c)){
                            oAccount = accountUpdateMap.get(billingSetting.APTS_Agreement_ID__r.Apttus__Account__c);
                        }else{
                            oAccount = new Account();
                        }
                        oAccount.Id = billingSetting.APTS_Agreement_ID__r.Apttus__Account__c;
                        if(!billingSetting.APTS_Agreement_ID__r.Apttus__Account__r.Enable_Invoice_Payment_Flag__c && billingSetting.APTS_Payment_Term_Setting__c != null){
                            oAccount.Enable_Invoice_Payment_Flag__c = true;
                            accountUpdateMap.put(oAccount.Id, oAccount);
                        }else if(billingSetting.APTS_Agreement_ID__r.Apttus__Account__r.Enable_Invoice_Payment_Flag__c && billingSetting.APTS_Payment_Term_Setting__c == null){
                            oAccount.Enable_Invoice_Payment_Flag__c = false;
                            accountUpdateMap.put(oAccount.Id, oAccount);
                        }
                    }
                    

                    if(accountUpdateMap != null && !accountUpdateMap.IsEmpty()){
                        Database.update(accountUpdateMap.values(),false);
                    }
                    APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterUpdateBS');
                }
               
                
                //Populate 'Last related Agreement' field of ALI on Agreement Activation
                
                Map<String, APTS_Agreement_PO_Details__c> agreementPODetailsMap = new Map<String, APTS_Agreement_PO_Details__c>();
                for(APTS_Agreement_PO_Details__c agreementPODetailsSO : [SELECT Id,
                                                                APTS_Agreement__c,
                                                                APTS_Agreement__r.Apttus__Agreement_Number__c,
                                                                APTS_PO_Number__c,
                                                                APTS_PO_Number_Required__c,
                                                                APTS_PO_Category__c,
                                                                APTS_PO_Number_Type__c
                                                                FROM APTS_Agreement_PO_Details__c
                                                                WHERE APTS_Agreement__c IN :activatedAgreementMap.keySet() and APTS_Agreement__r.APTS_PO_Details_Changed__c = true])
                {
                    agreementPODetailsMap.put(agreementPODetailsSO.APTS_PO_Category__c, agreementPODetailsSO);
                }
                
                for(Apttus__APTS_Agreement__c oAgreement : [Select Id from Apttus__APTS_Agreement__c where Apttus__Agreement_Number__c IN: agreementNoToIdMap.keySet() LIMIT 50000]){
                agreementSet.add(oAgreement.Id);
                }
                
                List<Apttus_Config2__AssetLineItem__c> assetLineItemList = [SELECT Id, APTS_relatedlist_agreement__c, Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c, 
                                                  APTS_Physical_Asset__r.PONumberMachines__c, APTS_Physical_Asset__r.PONumberRequiredMachines__c, 
                                                  APTS_Physical_Asset__r.PONumberTypeMachines__c, APTS_Physical_Asset__r.PONumberServices__c, 
                                                  APTS_Physical_Asset__r.PONumberRequiredServices__c, APTS_Physical_Asset__r.PONumberTypeServices__c, 
                                                  Apttus_CMConfig__AgreementId__c, APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c 
                                                  WHERE Apttus_CMConfig__AgreementId__c IN: agreementSet];
                if(assetLineItemList.size() > integer.Valueof(LABEL.APTS_Process_Asset_Count))
                {
                    APTS_ProcessAssetsBatch processAssetBatchSO = new APTS_ProcessAssetsBatch(agreementSet, agreementNoToIdMap, agreementPODetailsMap);
                    Database.executeBatch(processAssetBatchSO);
                }
                else
                {
                    /*if(!activatedAgreementList.isEmpty()){
                    APTS_CLMUtil.populateAgreementInALI(activatedAgreementList);
                }
                if(!activatedAgreementMap.isEmpty()){
                    APTS_CLMUtil.amendPhysicalAssetUpdate(activatedAgreementMap);
                    }*/
                    APTS_CLMUtil.updateAssetsOnAgreementActivation(assetLineItemList, activatedAgreementMap.keySet(), agreementNoToIdMap, agreementPODetailsMap);
                }
                
                
                
               if(!aggrId.isEmpty()){
                  
                //Logic Added to create the Compliance task for the One-time bonus
                 List<task> taskList = new List<task>();
                 String description;
                 Set<String> countrySet = new Set<String>();
                 for(Apttus__APTS_Agreement__c agr : (List<Apttus__APTS_Agreement__c>)newList){
                       accountId.add(agr.Apttus__Account__c);
                       countrySet.add((String)agr.APTS_Country__c);
                 } 
                 Map<String,Internal_contract_compliance__c> intConComMap = new Map<String,Internal_contract_compliance__c>();
                 for(Internal_contract_compliance__c intCom: [Select Id, Name, budget_internal_freq__c, Budget_internal_task_User__c, Contracted_Indexation_task_User__c, Country__c, fixed_terms_internal_freq__c, Fixed_Terms_internal_task_user__c, Fixed_Terms_Settlement_task_User__c, 
                                                              kpi_internal_freq__c, KPI_SLA_internal_task_User__c, KPI_SLA_Settlement_task_User__c,
                                                              volume_obligation_internal_freq__c, Volume_Obligation_internal_task_User__c, volume_obligation_internal_triggerpoint__c, Volume_Obligation_Settlement_task_User__c, One_time_Bonus_internal_task_User__c, OwnerId, 
                                                              PO_Number_internal_task_User__c, Standard_Indexation_queue_user__c, APTS_Queue_Task__c FROM Internal_contract_compliance__c 
                                                              where Country__c IN :countrySet])
                                                              {intConComMap.put(intCom.Country__c,intCom);
                                                              }
                                                              
                 Map<Id,Contact> contactMap = new Map<Id,Contact>();
                 
                 for(Contact accountContact: [SELECT Id, Name, Account.Name, AccountId, Main_Commercial_Person__c 
                                         FROM Contact 
                                         WHERE Main_Commercial_Person__c = true and Account_ID__c IN :accountId])
                 {
                 contactMap.put(accountContact.AccountId, accountContact);
                 }
                if(newstatuslist.size() > 0 && !isRenewalBatchExecuting)
                {
                  APTS_ManageCER.manageCERRecords(newstatuslist,'Agreement','Update'); 
                }
                
                for(Apttus__APTS_Agreement__c agg: [SELECT Id, Name, APTS_Country__c, Apttus__FF_Agreement_Number__c, Apttus__Account__c, Apttus__Activated_Date__c, APTS_One_Time_Bonus__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c, Apttus__Version_Number__c, OwnerId FROM Apttus__APTS_Agreement__c WHERE Id IN: aggrId])
                { 
                  description = 'Contract '+ agg.Apttus__FF_Agreement_Number__c + 'has been activated, one-time bonus can be payed out'+'\n' +'- Create CMR for ' +agg.Apttus__Account__c+'\n' +'- One-Time bonus amount: ' + agg.APTS_One_Time_Bonus__c;
                  
                    if(agg.APTS_One_Time_Bonus__c != null && agg.Apttus__Version_Number__c == 0)                    
                        taskList = APTS_ComplianceTaskUtils.createComplianceTaskForOneTime(agg, 'ONE-TIME BONUS', Label.APTS_High, 80,agg.Apttus__Activated_Date__c, Label.APTS_Open, description, intConComMap.get(agg.APTS_Country__c), contactMap.get(agg.Apttus__Account__c));                       
                    
                    
                }
                List<Database.SaveResult> srList = Database.insert(taskList,false);
                for (Database.SaveResult sr : srList) {
                System.debug('Error Log'+sr.getErrors());}
                System.debug('newstatuslist=====>'+newstatuslist);
                if(!newstatuslist.isEmpty() && !isRenewalBatchExecuting){
                   //Added to invoke the S&M team Class   
                   SM_AgreementToAccount smAgreeAcc = new SM_AgreementToAccount(); 
                   try{
                     smAgreeAcc.AgreementToAccountMethods(newstatuslist);
                   }
                   catch(Exception ex){
                       if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Please fill Commercial Registration Number: ') || ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Account record type is Customer, Customer Validation, or Promotion Requested then VAT Registration Number ')){
                         newList[0].addError('One of the related Accounts does not have a Commercial Registration Number and/or VAT Registration Number');  
                       }
                       else{
                         newList[0].addError(ex.getMessage());
                       }
                   }
                }   
               }
               
                /************ CHANGES FOR CER ENDS**************/
                
                /* Added by Wendy Kelley - 14/2/2018 - End */
                /*Added by Santosh - 15/2/2018 
                  Create tasks when Agreement is Activated  */
                Set<Id> aggidfortask = new Set<Id>();
                 //V111 ++ <<
                Map<string, Apttus__APTS_Agreement__c> agreementforTaskMap = new Map<string, Apttus__APTS_Agreement__c>();
                 //V111 ++ >>
                for(Apttus__APTS_Agreement__c oAgg : (List<Apttus__APTS_Agreement__c>)newList) {
                 /*** PI fix # 111931 **** removed the commented lines ***/
                    if(ACTIVATED.equalsIgnoreCase(oAgg.Apttus__Status__c) && (oldRecMap.get(oAgg.Id).Apttus__Status_Category__c == 'In Signatures' || oldRecMap.get(oAgg.Id).Apttus__Status_Category__c == 'Add email from customer')) {
                        aggidfortask.add(oAgg.Id);
                         //V111 ++ <<
                        agreementforTaskMap.put(oAgg.Apttus__Agreement_Number__c, oAgg);
                         //V111 ++ >>
                        /*V109 Start*/
                        /*V110 Start*/
                        system.debug('@@Recordtype' +oAgg.RecordTypeId);
                        system.debug('@@RegisterformID' +registrationformID);
                        system.debug('@@agreementstatus' +oAgg.Apttus__Status__c);
                        if(!oAgg.APTS_Created_From_Batch__c && oAgg.RecordTypeId == registrationformID){
                            System.enqueueJob(new APTS_CreateAdminOrderQueue(oAgg));
                        }
                        /*110 End*/
                        /*V109 End*/
                    }
                }
                 //V111 ++ <<
                //createtask(aggidfortask);
                if(!agreementforTaskMap.isEmpty())
                {
                     createtask(agreementforTaskMap);
                }
                  //V111 ++ >>              
                /************ CHANGES BY BALASHANTHI STARTS**************/
                // Changes added for For FD# 2801 FD_T_pOTC_030_Apttus Billing Management - Foundation
                // This method will create Billing Setting Record based on Bill To selection @ agreement header
                
                if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerBillingSetting')){
                    APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerBillingSetting');
                    APTS_BIRUtils.createBillingSetting((Map<Id, Apttus__APTS_Agreement__c>) mapAgreements, (Map<Id, Apttus__APTS_Agreement__c>) mapOldAgreements,true);
                }
                /************ CHANGES BY BALASHANTHI ENDS**************/
                
                /************ CHANGES BY Amit Begins **************/
                //Class to create volume assumption & obligation schedule records
                
                APTS_AgmtVolumeObligationsCreation agmtVlmOblg = new APTS_AgmtVolumeObligationsCreation();
                agmtVlmOblg.createAgmtVolumeObligation(mapAgreements, mapOldAgreements);
                /************ CHANGES BY Amit Begins **************/
                
                /**********PRANJAL: CHANGES FOR 2890: START***********/
                APTS_CLMUtil.populateURL((List<Apttus__APTS_Agreement__c>) newList, (Map<Id, Apttus__APTS_Agreement__c>) mapAgreements,
                            (List<Apttus__APTS_Agreement__c>) oldList, (Map<Id, Apttus__APTS_Agreement__c>) mapOldAgreements);
                /**********PRANJAL: CHANGES FOR 2890: END***********/
                
                 /* If a fixed term agreement is activated, then order, order line item and asset line item
                needs to be created and activated. Pass the old and new map to the batch class
                to check for fixed term agreement record and order creation through API. */
                if(!mapAgreements.values().isempty()){
                List<Apttus__APTS_Agreement__c> agrmnt= mapAgreements.values();
                if(agrmnt[0].APTS_Fixed_Term_Type__c !=null){
                    APTS_FixedTermAgreement.fixedTermAgreementActivation(mapAgreements, mapOldAgreements);
                }
                }
            }
        }

        catch(exception ex){
        APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);}

    }

    /* Before inserting agreement. */
    //Added by Shahul_CPQ_Under Testing
    //rQTC-Contract basics-006
    public void beforeInsert(List<SObject> newItems){
    try
    {    
    //Recursive check
        if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerBeforeInsert')){
                APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerBeforeInsert');
        
        /**Added to default the Internal frequency for the Compliance task**/
        
        Set<String> countryId = new Set<String>();
        Set<Id> accountId = new Set<Id>();
        Set<String> accounthierId = new Set<String>();
        Map<Id,Contact> contactmap = new Map<Id,Contact>();
        Map<Id,Account> accountmap = new Map<Id,Account>();
        List<String> lstLang = new List<String>();
        List<Apttus__APTS_Agreement__c> initialAgglist = new List<Apttus__APTS_Agreement__c>();
        Set<ID> accountLocationSet = new Set<ID>();
        Map<ID,Schema.RecordTypeInfo> RecMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
        Map<String, Internal_contract_compliance__c> countryMap = new Map<String, Internal_contract_compliance__c>();
            for(Apttus__APTS_Agreement__c oAgg : (List<Apttus__APTS_Agreement__c>)newItems) {
                //update Bonsai Agreement from Bonsai Account 
                if(oAgg.APTS_Migration_Date__c == null){
                    oAgg.Apttus_Approval__Approval_Status__c = 'Not Submitted';
                }

                //Defaulting 'JDE Signatory' field with Agreement Owner
                oAgg.APTS_JDE_Signatory__c = oAgg.OwnerId;
                
                if(oAgg.APTS_Country__c != null) {
                    countryId.add(oAgg.APTS_Country__c);
                    oAgg.APTS_IndexationRelatedListDetails__c = 'StandardIndexation|';
                }
                accountId.add(oAgg.Apttus__Account__c);
            }

            for(Contact con : [select Id,name,AccountId from Contact where AccountId IN: accountId and Authorized_Signer__c = true]) {
                contactmap.put(con.AccountId, con);
            }

            for(Account acc : [select id, name, ParentId, Parent.ParentId, APTS_Payment_Method__c, (select id,Apttus__FF_Agreement_Number__c from R00N50000001Xl0UEAS__r where Apttus__Status_Category__c = 'In Effect' AND Apttus__Status__c = 'Activated') from Account where Id IN: accountId]) {
                accountmap.put(acc.Id, acc);
                if(acc.ParentId != null) {
                    accounthierId.add(acc.ParentId);
                }
                if(acc.Parent.ParentId != null) {
                    accounthierId.add(acc.Parent.ParentId);
                }
            }

            for(Account acc : [select id,name,ParentId,Parent.ParentId,(select id,Apttus__FF_Agreement_Number__c from R00N50000001Xl0UEAS__r where Apttus__Status_Category__c = 'In Effect' AND Apttus__Status__c = 'Activated') from Account where Id IN: accounthierId]) {
                accountmap.put(acc.Id, acc);
            }

            if(countryId.size()>0){
                for(Internal_contract_compliance__c intConCom : [SELECT 
                                                                Id, 
                                                                budget_internal_freq__c, 
                                                                Country__c, 
                                                                fixed_terms_internal_freq__c, 
                                                                kpi_internal_freq__c, 
                                                                volume_obligation_internal_freq__c,
                                                                volume_obligation_internal_triggerpoint__c 
                                                            FROM Internal_contract_compliance__c 
                                                            WHERE Country__c IN :countryId]){

                    countryMap.put(intConCom.Country__c,intConCom);
                }

            }
            
            for(Apttus__APTS_Agreement__c oAgg : (List<Apttus__APTS_Agreement__c>)newItems) {
            
                if(contactmap.containskey(oAgg.Apttus__Account__c)) {
                    oAgg.APTS_Autorized_Signature_Customer__c = contactmap.get(oAgg.Apttus__Account__c).Id;
                }
                if(oAgg.Apttus__Account__c!=null){
                if(accountmap.get(oAgg.Apttus__Account__c).Parent.ParentId!=null) {
                    if(!accountmap.get(accountmap.get(oAgg.Apttus__Account__c).Parent.ParentId).R00N50000001Xl0UEAS__r.isEmpty()) {
                        oAgg.APTS_Grand_Parent_Contract__c = accountmap.get(accountmap.get(oAgg.Apttus__Account__c).Parent.ParentId).R00N50000001Xl0UEAS__r[0].Apttus__FF_Agreement_Number__c;
                    }
                }else if(accountmap.get(oAgg.Apttus__Account__c).ParentId!=null) {
                    if(!accountmap.get(accountmap.get(oAgg.Apttus__Account__c).ParentId).R00N50000001Xl0UEAS__r.isEmpty()) {
                        oAgg.APTS_Grand_Parent_Contract__c = accountmap.get(accountmap.get(oAgg.Apttus__Account__c).ParentId).R00N50000001Xl0UEAS__r[0].Apttus__FF_Agreement_Number__c;
                        }
                }else if(accountmap.get(oAgg.Apttus__Account__c)!=null){
                    if(!accountmap.get(oAgg.Apttus__Account__c).R00N50000001Xl0UEAS__r.isEmpty()) {
                        oAgg.APTS_Grand_Parent_Contract__c = accountmap.get(oAgg.Apttus__Account__c).R00N50000001Xl0UEAS__r[0].Apttus__FF_Agreement_Number__c;    
                    }
                }
                }
                if(countryMap.containsKey(oAgg.APTS_Country__c) && countryMap.get(oAgg.APTS_Country__c) != null){
                    Internal_contract_compliance__c intConCom = countryMap.get(oAgg.APTS_Country__c);
                    if(intConCom.budget_internal_freq__c != null){
                        oAgg.budget_internal_freq__c = intConCom.budget_internal_freq__c;
                   }
                   if(intConCom.fixed_terms_internal_freq__c != null){
                        oAgg.Fixed_Terms_Internal_Freq__c = intConCom.fixed_terms_internal_freq__c;
                   }
                   if(intConCom.kpi_internal_freq__c != null){
                        oAgg.kpi_internal_freq__c = intConCom.kpi_internal_freq__c;
                   }
                   if(intConCom.volume_obligation_internal_freq__c != null){
                        oAgg.volume_obligation_internal_freq__c = intConCom.volume_obligation_internal_freq__c;
                   }
                   if(intConCom.volume_obligation_internal_triggerpoint__c != null){
                        oAgg.volume_obligation_internal_triggerpoint__c = intConCom.volume_obligation_internal_triggerpoint__c;
                   }
                } 
                if(oAgg.APTS_Migration_Date__c == null && oAgg.Apttus__Version_Number__c == 0){
                    //V112 ++ <<
                oAgg.Apttus__Contract_Start_Date__c =system.today();
                    //V1112++ >>
            }
            
                if(oAgg.Apttus__Version_Number__c == 0){
                        initialAgglist.add(oAgg);
                    }

            if(RecMap.get(oAgg.recordTypeID).getName().containsIgnoreCase(Consumption)){
                oAgg.APTS_Unlimited_Machine_Ordering__c=true;
            }
            //Added by Karan START
            accountLocationSet.add(oAgg.APTS_Location__c);

             if(oAgg.APTS_Language__c != NULL){
            lstLang.add(oAgg.APTS_Language__c);
          }
            }
            
            if(lstLang.size() > 0){
          APTS_LanguageTranslator.translateLanguage(newItems, 'Apttus__APTS_Agreement__c', lstLang);
        }
        
        
         //Added by Karan START
        
        Map<ID,ID> accountLocationAccountMap = new Map<ID,ID>();
        //Added by Karan END
        
        //START Deal Management - Added by jason.e.mactal
        APTS_WarehousingCost oWHCost = new APTS_WarehousingCost();
        oWHCost.getWarehousingCost((List<Apttus__APTS_Agreement__c>)newItems);
        //End Deal Management
        
        //START rQTC-Pricing-029 - Added by jason.e.mactal
            if(initialAgglist!=null){
        APTS_DefaultPriceList  defaultPriceList = new APTS_DefaultPriceList ();
        defaultPriceList.setDefaultPriceList(initialAgglist, accountId);
                }
        //END rQTC-Pricing-029
        
        
        
        //Added by Karan START
        for(Apttus_Config2__AccountLocation__c accLocation : [select id,Apttus_Config2__AccountId__c from Apttus_Config2__AccountLocation__c where id IN: accountLocationSet]){
            if(accountLocationAccountMap.get(accLocation.id)==null){
                accountLocationAccountMap.put(accLocation.id,accLocation.Apttus_Config2__AccountId__c);
            }
        }
        if(!accountLocationAccountMap.isEmpty()){
            for(Apttus__APTS_Agreement__c agr : (List<Apttus__APTS_Agreement__c>)newItems){
                if(accountLocationAccountMap.get(agr.APTS_Location__c)!=null && agr.APTS_Migration_Date__c == null){
                    agr.Apttus__Account__c =accountLocationAccountMap.get(agr.APTS_Location__c);
                }
            }
        }

            }
        
          }
          catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);}   
    }

    /* Before record updation. */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,
    List<SObject> oldList, Map<Id, SObject> oldItems){
    Set<Id> accountIds = new Set<Id>();
    Set<String> agreementnumberlist= new Set<String>();
    List<Apttus__APTS_Agreement__c> agreementstoupdate = new List<Apttus__APTS_Agreement__c>();
    Boolean terminationcheck=false;
    /**Logic added for restricting the termination of an Agreement 
    without termination of all the Asset line items for 'Fixed End Date' Subtype**/
        try{
            
            Map<Id, Apttus__APTS_Agreement__c> oldItemsMap = (Map<Id,Apttus__APTS_Agreement__c>) oldItems;
            
            /*for(Apttus__APTS_Agreement__c newagr : (List<Apttus__APTS_Agreement__c>)newList){
                if(newagr.Apttus__Status__c != oldItemsMap.get(newagr.Id).Apttus__Status__c || newagr.Apttus__Status_Category__c != oldItemsMap.get(newagr.Id).Apttus__Status_Category__c){
                    if(APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerBeforeUpdate')){
                        APTS_CheckRecursive.processedSet.remove('APTS_AgreementTriggerHandlerBeforeUpdate');
                    }
                }
            }*/
            
            //Recursive check
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerBeforeUpdate')){
                APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerBeforeUpdate');
                List <Apttus__APTS_Agreement__c> newterlist = new List <Apttus__APTS_Agreement__c> ();
                //Opp get
                Set<Id> SetOpportunity = new Set<Id>();
                //START Deal Management - Added by jason.e.mactal
                APTS_WarehousingCost oWHCost = new APTS_WarehousingCost();
                oWHCost.getWarehousingCost((List<Apttus__APTS_Agreement__c>)newList);
                //End Deal Management
                Map<Id, Apttus__APTS_Agreement__c> aggrMap = new Map<Id, Apttus__APTS_Agreement__c>();
                    for(Apttus__APTS_Agreement__c aggr : (List<Apttus__APTS_Agreement__c>)newList){
                        
                        Apttus__APTS_Agreement__c oldAggrValueterminate = (Apttus__APTS_Agreement__c)oldItems.get(aggr.Id);
                        
                        if(aggr.Apttus_Approval__Approval_Status__c == 'Cancelled'){
                            aggr.APTS_Lock_Agreement__c = false;
                        }
                        
                        if(aggr.APTS_Lock_Agreement__c && oldAggrValueterminate.APTS_Lock_Agreement__c){
                            aggr.addError('This Agreement record is locked.');
                        }
                        
                         if(aggr.Apttus__Status__c=='Activated' && aggr.Apttus__Status_Category__c=='In Effect' )
                        SetOpportunity.add(aggr.Apttus__Related_Opportunity__c);
                    
                        if(aggr.Apttus__Status__c != null && FULLY_SIGNED.equalsIgnoreCase(aggr.Apttus__Status__c) && !FULLY_SIGNED.equalsIgnoreCase(oldItemsMap.get(aggr.Id).Apttus__Status__c)){
                            aggr.APTS_Agreement_Signature_Date__c = System.Today();
                        }
                        
                        //Termination Date population
                        if(!Label.APTS_Terminated.equalsIgnoreCase(oldAggrValueterminate.Apttus__Status__c) && Label.APTS_Terminated.equalsIgnoreCase(aggr.Apttus__Status__c)) {
                            System.debug('came inside termination check');
                            aggr.Apttus__Termination_Date__c = System.Today();
                            agreementnumberlist.add(aggr.Apttus__FF_Agreement_Number__c);
                            terminationcheck=true;

                        }
                        
                        if(!String.IsEmpty(aggr.Apttus__Status__c) && aggr.Apttus__Status__c.equals(Label.APTS_Terminated) 
                            && !String.IsEmpty(aggr.Apttus__Status_Category__c) && aggr.Apttus__Status_Category__c.equals(Label.APTS_Terminated)
                            && !String.IsEmpty(aggr.Apttus__Subtype__c) && aggr.Apttus__Subtype__c.equals(Label.APTS_Fixed_End_Date)){
                            aggrMap.put(aggr.Id, aggr);
                        }
                        accountIds.add(aggr.Apttus__Account__c);
                       
                       if((!Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(aggr.recordTypeId).getDeveloperName().equalsIgnoreCase('Registration_Form')) && ((oldAggrValueterminate.Apttus__Status__c!= 'Terminated' && aggr.Apttus__Status__c=='Terminated') 
                           || (oldAggrValueterminate.Apttus__Status__c!= 'Expired' && aggr.Apttus__Status__c=='Expired')
                           || (oldAggrValueterminate.Apttus__Status__c!= 'Superseded' && aggr.Apttus__Status__c=='Superseded')
                           || (oldAggrValueterminate.Apttus__Status__c!= 'Cancelled' && aggr.Apttus__Status__c=='Cancelled')
                           || (oldAggrValueterminate.Apttus__Status__c!= 'Cancelled Request' && aggr.Apttus__Status__c=='Cancelled Request')))
                        { 
                         newterlist.add(oldAggrValueterminate);
                        } 
            if(Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(aggr.recordTypeId).getDeveloperName().equalsIgnoreCase('Registration_Form') && 
                          aggr.Apttus_CMConfig__ConfigurationFinalizedDate__c != ((Apttus__APTS_Agreement__c) oldItems.get(aggr.Id)).Apttus_CMConfig__ConfigurationFinalizedDate__c
                          && aggr.Apttus__Status__c != 'Added')
                        {
                          aggr.Apttus__Status__c = 'Not added';
                          aggr.Apttus__Status_Category__c = 'Add email from customer';
                        }
                    }
                    setrecurs.add('beforeUpdateProcessed');
                      if(SetOpportunity != null && SetOpportunity.size()>0)
                    syncAgreementWithOpp(SetOpportunity);          
                    
                    //seting termination date to related agreeemnt no.
                    if(terminationcheck) 
                    {   
                        System.debug('came inside my termination logic');   
                    System.debug('agreementnumberlist---->'+agreementnumberlist);                 
                        for(Apttus__APTS_Agreement__c agreementobj : [select Id,Apttus__Agreement_Number__c,Apttus__Termination_Date__c  from Apttus__APTS_Agreement__c  where  Apttus__Agreement_Number__c In : agreementnumberlist and Apttus__Termination_Date__c = null])
                        {
                        agreementobj.Apttus__Termination_Date__c=System.Today();
                        agreementstoupdate.add(agreementobj);
                        }
                    }
                    System.debug('agreementstoupdate----->'+agreementstoupdate);
                //update agreemnets with termination date.
                if(agreementstoupdate.size()>0)
                {
                    update agreementstoupdate;
                }
                //CER Record Deletion Start
                if(newterlist.size()>0){
                APTS_ManageCER.manageCERRecords(newterlist ,'Agreement','Delete');
                }
                //CER Record Deletion End
            
                /*v107 - This is added to bulkify*/
                Id sd_rtId = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
                Id cm_rtId = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
                List<Apttus__APTS_Agreement__c> relatedAgg = new List<Apttus__APTS_Agreement__c>([Select Id,Apttus__Account__c,Apttus__Status__c,Apttus__Status_Category__c,
                  RecordTypeId, Apttus__Agreement_Number__c, RecordType.DeveloperName from Apttus__APTS_Agreement__c WHERE Apttus__Status_Category__c = 'In Effect'
                  AND Apttus__Account__c IN :accountIds]);
                    
                 for(Apttus__APTS_Agreement__c agrmt : (List<Apttus__APTS_Agreement__c>)newList){
                     for(Apttus__APTS_Agreement__c relAg : relatedAgg){
                         if(agrmt.Apttus__Status__c == 'Activated' && agrmt.Apttus__Status_Category__c == 'In Effect'
                          && relAg.Apttus__Status_Category__c == agrmt.Apttus__Status_Category__c
                          && relAg.Apttus__Agreement_Number__c != agrmt.Apttus__Agreement_Number__c){
                             
                             if(relAg.RecordTypeId == sd_rtId && agrmt.RecordTypeId == sd_rtId && agrmt.Apttus__Account__c == relAg.Apttus__Account__c ){ //== relAg.Apttus__Account__c
                               agrmt.addError('Activated Standard Deal Agreement already exists for this account ');
                             } else if((relAg.RecordTypeId).equals(cm_rtId) && (agrmt.RecordTypeId).equals(cm_rtId) && agrmt.Apttus__Account__c == relAg.Apttus__Account__c){
                               agrmt.addError('Activated Consumption Model Agreement already exists for this account ');
                             }
                         }
                     }
                 }
                
                //START Get RouteSales PriceList - jason 10.26.2018 ALM: 20722
                Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Sales_Organization__c FROM Account WHERE Id IN: accountIds]);
                /*** PI fix # 111931 **** removed unused variables "prodConfigList" and "aggConfigMap" ***/
                
                APTS_DefaultPriceList defaultPriceList = new APTS_DefaultPriceList();
                Map<String, map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap = defaultPriceList.getPriceLists();
                //END Get RouteSales PriceList - jason 10.26.2018 ALM: 20722
                Map<String, APTS_SalesOrg_Settings__mdt> getSalesOrgSettings = defaultPriceList.getSalesOrgSettings();
                //Added for Language Translation in templates - Pranjal
                List<String> lstLang = new List<String>();
                for(Apttus__APTS_Agreement__c tmp : (List<Apttus__APTS_Agreement__c>) newList){
                    if(oldItemsMap.get(tmp.id).APTS_Routesales__c != tmp.APTS_Routesales__c){
                        if(getSalesOrgSettings.get(accountMap.get(tmp.Apttus__Account__c).Sales_Organization__c).APTS_Allow_Routesales__c){
                            //START Get RouteSales PriceList - jason 10.26.2018 ALM: 20722
                            if(tmp.Apttus__Status_Category__c == 'Request'){ 
                                if(tmp.APTS_Migration_Date__c == null && tmp.APTS_Routesales__c && !oldItemsMap.get(tmp.id).APTS_Routesales__c){
                                    tmp.Apttus_CMConfig__PriceListId__c = defaultPriceList.getRoutesalesPriceList(accountMap.get(tmp.Apttus__Account__c), priceListByCountryMap);
                                }
                                
                                //END Get RouteSales PriceList - jason 10.26.2018 ALM: 20722
                                // Reassign pricelist back to original when routesales is unchecked
                                if(!tmp.APTS_Routesales__c){
                                    defaultPriceList.setDefaultPriceList((List<Apttus__APTS_Agreement__c>) newList, accountIds);
                                } 
                                /*** PI fix # 111931 **** removed the commented lines ***/
                            }else{
                                tmp.addError('You can only update the pricelist on an agreement when Status Category = Request.');
                            }
                        }else{
                           // tmp.addError('Routesales PriceList not available in your country.');
                            /*if(!tmp.APTS_Routesales__c)
                            defaultPriceList.setDefaultPriceList((List<Apttus__APTS_Agreement__c>) newList, accountIds);
                            if(tmp.APTS_Routesales__c)
                            tmp.addError('Routesales PriceList not available in your country.');*/
                        } 
                    }
                    
                    if(tmp.APTS_Language__c != NULL){
                        lstLang.add(tmp.APTS_Language__c);
                    }
                }

                for(Apttus__APTS_Agreement__c oAggmnt : (List<Apttus__APTS_Agreement__c>) newList){
                  if((oAggmnt.Apttus__Auto_Renewal__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).Apttus__Auto_Renewal__c || 
                     oAggmnt.APTS_Bill_to_Party_Ingredients__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).APTS_Bill_to_Party_Ingredients__c || 
                     oAggmnt.APTS_Bill_to_Party_MachServ__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).APTS_Bill_to_Party_MachServ__c || 
                     oAggmnt.APTS_Payer_Ingredients__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).APTS_Payer_Ingredients__c || 
                     oAggmnt.APTS_Payer_Machines_Services__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).APTS_Payer_Machines_Services__c || 
                     oAggmnt.APTS_Is_Billing_Setting_Change__c != ((Apttus__APTS_Agreement__c) oldItems.get(oAggmnt.Id)).APTS_Is_Billing_Setting_Change__c)
                     && oAggmnt.Apttus__Version_Number__c > 0) {

                        oAggmnt.APTS_Is_Admin_Order_Needed__c = true;
                  }
                }
            }
        }
       catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true); } 
    }

    /* Before deleting agreement records. */
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    /* After inserting agreement records. */
    /* Logic Added by Santosh to create Index Contract Records after insertion of Agreement record*/
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems){

        try{
            //Recursive check
            if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementTriggerHandlerAfterInsert')){
                APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterInsert');
            /************ CHANGES FOR CER STARTS **************/
            //v106++<<
            //CER method only should be executed if no more active agreements exists for the Account
            Set<Id> setAccoundIds = new Set<Id>();
            
            Set<String> setAccoundWithActivatedAgreements = new Set<String>();
            List<Apttus__APTS_Agreement__c> lstAgreementForCER = new List<Apttus__APTS_Agreement__c>();
            
            //Get list of accounts
            for(Apttus__APTS_Agreement__c currentAgreement : (List<Apttus__APTS_Agreement__c>)newList) {
                setAccoundIds.add(currentAgreement.Apttus__Account__c);

            }
            
            for(AggregateResult currentAR : [ SELECT Apttus__Account__c
                                              FROM Apttus__APTS_Agreement__c
                                              WHERE Apttus__Account__c IN :setAccoundIds 
                                              AND Apttus__Status_Category__c = 'In Effect'
                                              AND Apttus__Status__c = 'Activated'
                                              GROUP BY Apttus__Account__c
                                            ]){
              setAccoundWithActivatedAgreements.add((String)currentAR.get('Apttus__Account__c'));
            }

            //If the account related with the agreement doesn't have any activated agreements, add the 
            //current agreement to list for CER record creation
            List<APTS_Index_Contract__c> indexcontractlist = new List<APTS_Index_Contract__c>();
            Set<string> countryset = new Set<string>();
            Map<String,String> RegionMap = new  Map<String,String>();
            for( Schema.PicklistEntry v : Account.Sales_Organization__c.getDescribe().getPicklistValues()) {
                  RegionMap.put(v.getValue(),v.getLabel());
            }
            system.debug('UOMMap===>'+RegionMap);
            for(Apttus__APTS_Agreement__c currentAgreement : (List<Apttus__APTS_Agreement__c>)newList) {
                if(!setAccoundWithActivatedAgreements.contains(currentAgreement.Apttus__Account__c) && currentAgreement.APTS_Migration_Date__c == NULL && !Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosById().get(currentAgreement.recordTypeId).getDeveloperName().equalsIgnoreCase('Registration_Form')){
                  lstAgreementForCER.add(currentAgreement);
                }
                if(currentAgreement.APTS_Region__c != null && RegionMap.get(currentAgreement.APTS_Region__c)!=null) {
                    countryset.add(RegionMap.get(currentAgreement.APTS_Region__c));
                    system.debug('UOMMappp===>'+RegionMap.get(currentAgreement.APTS_Region__c));
                }
                /*if(currentAgreement.APTS_Country__c != null) {
                    countryset.add(currentAgreement.APTS_Country__c);
                }*/
                if(currentAgreement.Apttus__Version_Number__c > 0){
                    APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterUpdate');
                     APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerBeforeUpdate');
                }
            }
            if(!countryset.isEmpty()) {
                   indexcontractlist = processAggrecords(newList, countryset);
               
            }

            if(!indexcontractlist.isEmpty()) {
                insert indexcontractlist;
            }
            //If agreements found invoke CER method
            if(lstAgreementForCER.size() > 0){
              APTS_ManageCER.manageCERRecords(lstAgreementForCER,'Agreement','Insert');
            }
            //v106++>> 
            /************ CHANGES FOR CER ENDS**************/
              

             /************ CHANGES BY BALASHANTHI STARTS**************/
            // Changes added for For FD# 2801 FD_T_pOTC_030_Apttus Billing Management - Foundation
            // This method will create Billing Setting Record based on Bill To selection @ agreement header
                Map<Id, Apttus__APTS_Agreement__c> oldMap = new Map<Id, Apttus__APTS_Agreement__c>();
                APTS_BIRUtils.createBillingSetting((Map<Id, Apttus__APTS_Agreement__c>) newItems,oldMap,false);
            /************ CHANGES BY BALASHANTHI ENDS**************/   
             
            }            
            
        }catch(Exception ex){newList[0].addError(ex.getmessage());APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);}
    }

    /* After deleting agreement records. */
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

     /* After undeleting agreement records. */
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    @future     
    public static void syncAgreementWithOpp(Set<Id> SetOpportunity) 
    {   
        List<Opportunity> lstOpportunity = new List<Opportunity>();    
        if(SetOpportunity != null && SetOpportunity.size()>0)  
        {   
        for(Opportunity opp : [select StageName from Opportunity where Id IN :SetOpportunity])  
        {   
        opp.StageName= 'Closed Won';                        
        lstOpportunity.add(opp);    
        }   
        if(lstOpportunity.size()>0) 
        update lstOpportunity;  
        }   
                    
    }

    /*To Process Agreement Records and return Index Contract records */
    public List<APTS_Index_Contract__c> processAggrecords(List<Apttus__APTS_Agreement__c> oAggmtList, Set<string> countryset) {
        try
        {
        Map<String, Map<String,APTS_Index_Country_Defaulted_Values__c>> indexctrydefMap = new Map<String, Map<String,APTS_Index_Country_Defaulted_Values__c>>();
        List<APTS_Index_Contract__c> finalindexcontractlst = new List<APTS_Index_Contract__c>();

        for(APTS_Index_Country_Defaulted_Values__c oIndexcountrydef : [select id,name,APTS_Additional_Conditions__c,APTS_Communication_Deadline__c,
                                                  APTS_Communication_Needed__c,APTS_Country__c,APTS_Customer_Approval_Required__c,APTS_Default_Category__c,
                                                  APTS_Frequency__c,APTS_Indexation_Number__c,APTS_Maximum_Bandwidth__c,APTS_Default_Indexation_Type__c,
                                                  APTS_Start_Date__c from APTS_Index_Country_Defaulted_Values__c
                                                  where APTS_Country__c IN: countryset]) {
                                                      
                                                      
                                                      
                                                      if(indexctrydefMap.containsKey(oIndexcountrydef.APTS_Country__c.toLowerCase())) {
                                                            Map<String,APTS_Index_Country_Defaulted_Values__c> tempMap = indexctrydefMap.get(oIndexcountrydef.APTS_Country__c.toLowerCase());
                                                            tempMap.put(oIndexcountrydef.APTS_Default_Category__c,oIndexcountrydef);
                                                            indexctrydefMap.put(oIndexcountrydef.APTS_Country__c.toLowerCase(), tempMap);
                                                           
                                                      }
                                                      else{

                                                        indexctrydefMap.put(oIndexcountrydef.APTS_Country__c.toLowerCase(), new Map<String,APTS_Index_Country_Defaulted_Values__c>{oIndexcountrydef.APTS_Default_Category__c => oIndexcountrydef});
                                                      }     
                                                  }
        
        if(!indexctrydefMap.isEmpty()) {
        Map<String,String> RegionMap = new  Map<String,String>();
            for( Schema.PicklistEntry v : Account.Sales_Organization__c.getDescribe().getPicklistValues()) {
                  RegionMap.put(v.getValue(),v.getLabel());
            }
        
        for(Apttus__APTS_Agreement__c oAggmnt : oAggmtList) {
                if(RegionMap.get(oAggmnt.APTS_Region__c).toLowerCase()!=null && indexctrydefMap.containskey(RegionMap.get(oAggmnt.APTS_Region__c).toLowerCase()) && oAggmnt.Apttus__Version_Number__c!=null && oAggmnt.Apttus__Version_Number__c== 0 ) {
                    List<APTS_Index_Contract__c> indexcontractlst = createindexdata(oAggmnt, indexctrydefMap.get(RegionMap.get(oAggmnt.APTS_Region__c).toLowerCase()));
                    finalindexcontractlst.addAll(indexcontractlst);
                    
                    
                }
            }
        }
        return finalindexcontractlst;
        
        }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true); return null;}
    }

    /* To prepare Index contract records for different Categories */
    public List<APTS_Index_Contract__c> createindexdata(Apttus__APTS_Agreement__c oAgreement, Map<String,APTS_Index_Country_Defaulted_Values__c> oIndexCntrydef) {
        try
        {
        Map<ID,Schema.RecordTypeInfo> rtMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
        List<APTS_Index_Contract__c> indexlist = new List<APTS_Index_Contract__c>();
        if(rtMap.get(oAgreement.recordTypeID).getName().containsIgnoreCase(STANDARD) || rtMap.get(oAgreement.recordTypeID).getName().containsIgnoreCase(CONSUMPTION)) {
            if(oIndexCntrydef.containsKey('Products (Ingredients and &More)')){
                indexlist.add(getindexdata(oAgreement, oIndexCntrydef.get('Products (Ingredients and &More)'), 'Products (Ingredients and &More)'));
            }else{
                indexlist.add(getindexdata(oAgreement, null, 'Products (Ingredients and &More)'));    
            }
            if(oIndexCntrydef.containsKey('Technical Services')) {
                indexlist.add(getindexdata(oAgreement, oIndexCntrydef.get('Technical Services'), 'Technical Services'));
            }else{
                indexlist.add(getindexdata(oAgreement, null, 'Technical Services')); 
            }
            /*if(oIndexCntrydef.containsKey('Machine Care Service')){
                indexlist.add(getindexdata(oAgreement, oIndexCntrydef.get('Machine Care Service'), 'Machine Care Service'));
            }else{
                indexlist.add(getindexdata(oAgreement, null, 'Machine Care Service'));
            }*/
        }
        if(rtMap.get(oAgreement.recordTypeID).getName().containsIgnoreCase(CONSUMPTION)) {
            if(oIndexCntrydef.containsKey('Consumption Pricing')){
                indexlist.add(getindexdata(oAgreement, oIndexCntrydef.get('Consumption Pricing'), 'Consumption Pricing'));
            }else {
            indexlist.add(getindexdata(oAgreement, null, 'Consumption Pricing'));
            }
        }
        return indexlist;
     }
     catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true); return null;} 
    }

    /* To create Index contract records */
    public APTS_Index_Contract__c getindexdata(Apttus__APTS_Agreement__c oAgreement, APTS_Index_Country_Defaulted_Values__c oIndexCntrydef, String Category) {
        try
        {
        APTS_Index_Contract__c oIndexctrct = new APTS_Index_Contract__c();
        oIndexctrct.APTS_Contract__c = oAgreement.Id;
        oIndexctrct.APTS_Indexation_Category__c = Category;
        if(oIndexCntrydef != null) {
            oIndexctrct.APTS_Index_Type__c = oIndexCntrydef.APTS_Default_Indexation_Type__c;
            oIndexctrct.APTS_Indexation_Number__c = oIndexCntrydef.APTS_Indexation_Number__c;
            oIndexctrct.APTS_Frequency__c = oIndexCntrydef.APTS_Frequency__c;
            if(oIndexCntrydef.APTS_Frequency__c == YEARLY) {
                oIndexctrct.APTS_Start_Date__c = system.today().addMonths(12);
            }else if(oIndexCntrydef.APTS_Frequency__c == HALFYEARLY) {
                oIndexctrct.APTS_Start_Date__c = system.today().addMonths(6);
            }
            oIndexctrct.APTS_Communication_Needed__c = oIndexCntrydef.APTS_Communication_Needed__c;
            oIndexctrct.APTS_Communication_Deadline__c = oIndexCntrydef.APTS_Communication_Deadline__c;
            oIndexctrct.APTS_Customer_Approval_Required__c = oIndexCntrydef.APTS_Customer_Approval_Required__c;
            oIndexctrct.APTS_Maximum_Bandwidth__c = oIndexCntrydef.APTS_Maximum_Bandwidth__c;
            oIndexctrct.APTS_Additional_Conditions__c = oIndexCntrydef.APTS_Additional_Conditions__c;
        }else{
            oIndexctrct.APTS_Index_Type__c = 'Standard Indexation';
            oIndexctrct.APTS_Indexation_Number__c = '';
            oIndexctrct.APTS_Maximum_Bandwidth__c = 0;
            oIndexctrct.APTS_Additional_Conditions__c = '';

        }

        return oIndexctrct;
    }
    catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true); return null;} 
    }

    /*Added by Santosh to create Admin Order for Automation Admin Order CR - 28/8/2018 - End */
    
    /*@methodName - updateVolumeAssumptionRecords
    * @description - updates all Volume Assumption Records for the specified Agreements
    * @author - jason.e.mactal
    * @param - Set<Id>
    * @return -
    */
    public void updateVolumeAssumptionRecords(Set<Id> agreementIdSet){
        List<APTS_AgreementTotalVolumeObligation__c> oVAOtoUpdateList = new List<APTS_AgreementTotalVolumeObligation__c>();
        for(APTS_AgreementTotalVolumeObligation__c oVAO: [SELECT Id, APTS_Agreement__r.APTS_PricingDate__c FROM APTS_AgreementTotalVolumeObligation__c WHERE APTS_Agreement__c IN: agreementIdSet]){
            if(!APTS_CheckRecursive.processedSet.contains(string.valueOf(oVAO.id)) && oVAO.APTS_Agreement__r.APTS_PricingDate__c != null){
                oVAOtoUpdateList.add(oVAO);
                APTS_CheckRecursive.processedSet.add(string.valueOf(oVAO.id));
            }
        }
        if(!oVAOtoUpdateList.isEmpty()){
            
            database.update(oVAOtoUpdateList);
        }
        APTS_CheckRecursive.processedSet.add('APTS_AgreementTriggerHandlerAfterUpdateVA');
    }
    /*Added by Santosh - 15/2/2018 */
    //V111 ++ <<
    public void createtask(Map<string, Apttus__APTS_Agreement__c> agreementforTaskMap) 
    {
        try
        {
        Set<id> setAgreementForTaskCreation = new Set<Id>();
        Map<string, Apttus__APTS_Agreement__c> mapAmendedAgreements = new Map<string, Apttus__APTS_Agreement__c>();
        set<string> setAmendedAgreementNumbers = new set<String>();
        //Split the amended agreements
        for(Apttus__APTS_Agreement__c oAgr: agreementforTaskMap.values())
        {
            if(oAgr.Apttus__Version_Number__c > 0)
            {
                //Amended Agreement
                string agrFFNumber = oAgr.Apttus__Agreement_Number__c+ '_' + oAgr.Apttus__Version_Number__c;
                mapAmendedAgreements.put(agrFFNumber, oAgr);   
                setAmendedAgreementNumbers.add(oAgr.Apttus__Agreement_Number__c);             
            }
            else
                setAgreementForTaskCreation.add(oAgr.id);
        }
        List<Task> taskListToUpdate = new List<Task>();
        Map<string, task> mapAgreementToTask = new Map<string, task>();
        //Map<id, Decimal> mapAgreementVersion = new Map<id, Decimal>();
        //Id latestVersion = null;        
        if(!setAmendedAgreementNumbers.isEmpty())
        {
            Id currentAgrID = null;
            Map<id, Apttus__APTS_Agreement__c> mapAmendedAgrAllversions = new Map<id, Apttus__APTS_Agreement__c>([Select id, Apttus__Agreement_Number__c, Apttus__Version_Number__c from Apttus__APTS_Agreement__c where Apttus__Agreement_Number__c in: setAmendedAgreementNumbers and Apttus__Status_Category__c!= 'Cancelled' order By CreatedDate desc]);
            Set<id> previousVersions = new Set<id>();
            for(Apttus__APTS_Agreement__c agr : mapAmendedAgrAllversions.Values())
            {
                Decimal currentAgrVersion = agreementforTaskMap.get(agr.Apttus__Agreement_Number__c).Apttus__Version_Number__c;
                currentAgrId = agreementforTaskMap.get(agr.Apttus__Agreement_Number__c).Id;
                
                if(agr.Apttus__Version_Number__c >= 0 && agreementforTaskMap.Keyset().contains(agr.Apttus__Agreement_Number__c) && (agr.Apttus__Version_Number__c < currentAgrVersion))
                {                    
                    previousVersions.add(agr.id);
                    //if(agr.Apttus__Version_Number__c < currentAgrVersion)
                    //{
                        // mapAgreementVersion.add(agr.id, agr.Apttus__Version_Number__c);
                    
                    break;
                }
            }
            //check if Non standard Indexation task exists for previousVersionAgr
            string strguidance = 'Execute Non-Standard Indexation for ';
            List<Task> lstTask = [Select id,whatid, ActivityDate,Guidance__c from Task where whatid in: previousVersions and Guidance__c != null order By createdDate desc];
            if(setAgreementForTaskCreation.isEmpty() && lstTask.isEmpty())
            {
                setAgreementForTaskCreation.add(currentAgrId);
            }
            for(Task tk : lstTask)
            {
            if( tk.Guidance__c.startswith(strguidance) ){
                Apttus__APTS_Agreement__c agr = mapAmendedAgrAllversions.get(tk.whatid);
                Id currentAgreementId = agreementforTaskMap.get(agr.Apttus__Agreement_Number__c).id;
                if(mapAgreementToTask.isempty() || !mapAgreementToTask.keyset().contains(agr.Apttus__Agreement_Number__c )){
                mapAgreementToTask.put(agr.Apttus__Agreement_Number__c ,tk); 
                }               
                if(!setAgreementForTaskCreation.contains(currentAgreementId)){
                   setAgreementForTaskCreation.add(currentAgreementId);
                }
               } 
                              
            }
        }
        
        List<task> tasklist = new List<task>(); 
        String touchpoint = 'INDEXATION NON STD';
        // Nonstandardindexationtaskuser is the user assigning for non standard indexation task, if any changes requested by queuegatekeeper change the custom label
        String assignid = system.Label.APTS_Nonstandardindexationtaskuser;
        //String queuegatekeeperid = [Select User_Keeper__c from QueueGateKeepers__c where  Queue_Name__c = 'NL - Rebates/Indexation/Invoicing Queue'].User_Keeper__c;
        Integer freqvalue;
        for(APTS_Index_Contract__c oIndexcon : [select id,name,APTS_Index_Type__c,APTS_Indexation_Category__c,APTS_Contract__c,APTS_Index_Contract__c.APTS_Contract__r.Apttus__Account__c,APTS_Contract__r.Apttus__Account__r.Name,
                                                APTS_Communication_Needed__c,APTS_Communication_Deadline__c,APTS_Start_Date__c,APTS_Frequency__c ,APTS_Contract__r.Apttus__Agreement_Number__c  
                                                from APTS_Index_Contract__c where APTS_Contract__c IN: setAgreementForTaskCreation and 
                                                APTS_Index_Type__c = 'Non-Standard Indexation']) {
                                                   
            if(oIndexcon.APTS_Communication_Needed__c == true) {
                If(oIndexcon.APTS_Frequency__c == YEARLY){
                      freqvalue = 12;  
                }else{
                    freqvalue = 6;  
                }
                task existingtask = mapAgreementToTask.get(oIndexcon.APTS_Contract__r.Apttus__Agreement_Number__c); 
                string guidance = 'Execute '+oIndexcon.APTS_Index_Type__c+ ' for '+oIndexcon.APTS_Indexation_Category__c ;
                Date activitydate = oIndexcon.APTS_Start_Date__c.addMonths(freqvalue-Integer.valueof(oIndexcon.APTS_Communication_Deadline__c)).adddays(-7);
                if(existingtask!=null &&  guidance == existingtask.Guidance__c && activityDate == existingtask.ActivityDate ) {
                    Task tkToUpdate = new Task();
                    tkToUpdate.id = existingtask.id;
                    tkToUpdate.whatid = agreementforTaskMap.get(oIndexcon.APTS_Contract__r.Apttus__Agreement_Number__c).id;
                    tkToUpdate.OwnerId = assignid;
                    taskListToUpdate.add(tkToUpdate);                   
                    
                 }else{
                task newtask=new task(
                        whatid=oIndexcon.APTS_Contract__c, 
                        Status = 'Open',
                        OwnerId = assignid,
                        Subject = 'Other',
                        Touchpoint_Type__c = touchpoint,
                        Account__c = oIndexcon.APTS_Contract__r.Apttus__Account__c,
                        Account_Name__c = oIndexcon.APTS_Contract__r.Apttus__Account__r.Name,
                        ActivityDate = oIndexcon.APTS_Start_Date__c.addMonths(freqvalue-Integer.valueof(oIndexcon.APTS_Communication_Deadline__c)).adddays(-7),
                        Guidance__c = 'Execute '+oIndexcon.APTS_Index_Type__c+ ' for '+oIndexcon.APTS_Indexation_Category__c);
                    
                tasklist.add(newtask);
               }
            }
           
        }
        if(!tasklist.isempty())
        {
            Database.insert(tasklist);  
            for(Task tk : tasklist)
            {
                Task tkToUpdate = new Task();
                tkToUpdate.id = tk.id;
                tkToUpdate.OwnerId = assignid;
                taskListToUpdate.add(tkToUpdate);
            }          
        }
        if(!taskListToUpdate.isempty())
        {        
            Database.update(taskListToUpdate);
        }        
        
      }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);} 
    
    }
    //V111 ++ >>
}