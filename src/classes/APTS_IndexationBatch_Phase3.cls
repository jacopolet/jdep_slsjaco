/**
 * @description       : APTS_IndexationBatch_Phase3
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 30-03-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-01-2021   Karan Khatri   Initial Version
**/
global class APTS_IndexationBatch_Phase3 implements Database.Batchable<sObject>{
    String query, thread;
    private static String BATCHNAME = 'APTS_StandardIndexBatch_Phase3';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    private static final String TECHSERVICE = 'Technical Service';
    private static final String RESPONSETIME = 'Response Time';
    private static final String SERVICEWINDOW = 'Service Window';
    private static final String VALUEADDEDSERVICE = 'Value Added Service';
    private static final String PREVENTIVEMAINTENANCE = 'Preventive Maintenance';
    private static final String CONNECTEDCOFFEEMACHINE = 'Connected Coffee Machine';
    private static final String MACHINECARE = 'Machine Care';
    private static final String MACHINECARESERVICE = 'Machine Care Service';
    private static final String VALUEADDEDMACHINECARE = 'Value Added Machine Care';
    private static final String TECHSERVICES = 'Technical Services';
    private static final String SERVICEFEE = 'Service Fee';
    private static final String SUCCESS = 'Success';
    global APTS_IndexationBatch_Phase3(String thread){
       this.thread = thread;
    }
    

   global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: BATCHNAME]){
               
                  query = batchQuery.APTS_Query_String__c ;           
                  
                system.debug('query ++++ '  + query);
            }
            
            if(String.isNotBlank(thread) && thread != '0'){
                  query = query  + ' And thread__c = \''+thread+'\'';
               }
            
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> indTransList) {
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        Map<Id, List<Id>> assetIdMap = new Map<Id, List<Id>>();
        Map<Id, Id> cartidOrderIdMap = new Map<Id,Id>();
        Set<Id> assetIdSet = new Set<Id>();
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__Order__c oOrder;
        Map<String,Date> minAssetPendingBillingDateMap = new Map<String,Date>();
        Map<String,Decimal> indexBundlePercentageMap = new Map<String,Decimal>();
        Map<Id,String> bundleIdAdditionalInfoMap = new  Map<Id,String>();
        //List<String> optionGroupTextList = System.label.APTS_OptionGroupTextIndexation.split(',');
        List<String> indexSupportedChargeTypes = new List<String>();
        indexSupportedChargeTypes.addAll(System.label.APTS_TechnicalServiceChargetypeIndexation.split(','));
        //indexSupportedChargeTypes.addAll(System.label.APTS_MachineCareChargetypeIndexation.split(',')); 

        List<APTS_Index_Transaction__c> transUpdateList = new List<APTS_Index_Transaction__c>();
        try{   
        
         System.debug('******indTransList=====>'+indTransList);
          
            System.debug('******assetIdMap=====>'+assetIdMap);
            System.debug('******agreementMap=====>'+agreementMap);
            System.debug('******accountMap=====>'+accountMap);
           
            for(APTS_Index_Transaction__c indTrans : (List<APTS_Index_Transaction__c>) indTransList){
                System.debug('indTrans=====>'+indTrans);
                System.debug('indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__r===>'+indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__r);
                System.debug('indTrans.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r===>'+indTrans.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r);
                if(indTrans.APTS_Asset_Line_Item__c!=null){
                    assetIdSet.add(indTrans.APTS_Asset_Line_Item__c);
                }
                oOrder = APTS_CLMUtil.createAdminOrder(indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__r,indTrans.APTS_Asset_Line_Item__r.Apttus_Config2__AccountId__r, 'Admin Order');
                oOrder.APTS_Order_Sub_Type__c = 'Indexation';
                oOrder.APTS_Indexation_source_id__c =indTrans.id;
                oOrder.CurrencyIsoCode=indTrans.APTS_Asset_Line_Item__r.CurrencyIsoCode;
                orderList.add(oOrder);
                if(assetIdMap.get(indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__c)==null){
                   assetIdMap.put(indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__c, new List<Id>{indTrans.APTS_Asset_Line_Item__c});
                }else{
                    assetIdMap.get(indTrans.APTS_Asset_Line_Item__r.APTS_relatedlist_agreement__c).add(indTrans.APTS_Asset_Line_Item__c);
                }
                if(indexBundlePercentageMap.get(indTrans.APTS_Asset_Line_Item__c+TECHSERVICES)==null && indTrans.APTS_Technical_services_Index__c!=null){
                    indexBundlePercentageMap.put(indTrans.APTS_Asset_Line_Item__c+TECHSERVICES,indTrans.APTS_Technical_services_Index__c);
                }
                if(indexBundlePercentageMap.get(indTrans.APTS_Asset_Line_Item__c+MACHINECARESERVICE)==null && indTrans.APTS_Machine_care_Index__c!=null){
                    indexBundlePercentageMap.put(indTrans.APTS_Asset_Line_Item__c+MACHINECARESERVICE,indTrans.APTS_Machine_care_Index__c);
                }
            }
            System.debug('****assetIdMap=====>'+assetIdMap);
            if(orderList.size() > 0){
                Database.insert(orderList, false);
            }
            System.debug('Bundle asset ## Billing check=====>'+assetIdSet);
            For(Apttus_Config2__AssetLineItem__c optionAsset : [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__BundleAssetId__c IN: assetIdSet]){
                assetIdSet.add(optionAsset.id);
            }
            System.debug('Bundle + Option asset ## Billing check=====>'+assetIdSet);
            System.debug('orderList=====>'+orderList);    
            if(!assetIdSet.isEmpty()){
                minAssetPendingBillingDateMap = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetIdSet);
            }
            System.debug('minAssetPendingBillingDateMap ## Billing check=====>'+minAssetPendingBillingDateMap);
            for(Apttus_Config2__Order__c oOrder1 : orderList){
                if(oOrder1 != null && oOrder1.Id != null){
                    Id cartId = APTS_OrderUtils.createCart(oOrder1.Id);
                    if(assetIdMap.containsKey(oOrder1.Apttus_CMConfig__AgreementId__c) && assetIdMap.get(oOrder1.Apttus_CMConfig__AgreementId__c) != null){
                        Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
                        System.debug('****assetIdMap.get(oOrder.Apttus_CMConfig__AgreementId__c)====>'+assetIdMap.get(oOrder.Apttus_CMConfig__AgreementId__c));
                        request.AssetIds = assetIdMap.get(oOrder.Apttus_CMConfig__AgreementId__c);
                        request.CartId = cartId;
                        Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
                        System.debug('#### response====>'+response);
                        if(cartidOrderIdMap.get(cartid)==null){
                            cartidOrderIdMap.put(cartid,oOrder1.id);
                        }
                    }
                }
            }
            System.debug('#### cartidOrderIdMap====>'+cartidOrderIdMap);
            System.debug('#### indexBundlePercentageMap====>'+indexBundlePercentageMap);
            if(!cartidOrderIdMap.isEmpty() && !indexBundlePercentageMap.isEmpty()){
                for(Apttus_Config2__LineItem__c oLineItem : [SELECT Id,
                                                                    APTS_Type_of_Contract__c,
                                                                    Apttus_Config2__ChargeType__c,
                                                                    Apttus_Config2__AssetLineItemId__c,APTS_Option_Group_Text__c,
                                                                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c,
                                                                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                                                                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,
                                                                    Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c,
                                                                    Apttus_Config2__OptionId__r.name,
                                                                    Apttus_Config2__StartDate__c,
                                                                    APTS_is_Indexation_skip__c,
                                                                    Apttus_Config2__Description__c,
                                                                    Apttus_Config2__LineType__c,
                                                                    Apttus_Config2__BasePriceOverride__c,
                                                                    Apttus_Config2__BasePrice__c
                                                                FROM Apttus_Config2__LineItem__c
                                                                WHERE Apttus_Config2__ConfigurationId__c IN: cartidOrderIdMap.keySet() 
                                                                and Apttus_Config2__LineType__c='Option'
                                                                and Apttus_Config2__PriceType__c IN ('Recurring')
                                                                and Apttus_Config2__ChargeType__c IN: indexSupportedChargeTypes]){
                    manageIndexedOptionLineItems(oLineItem,indexBundlePercentageMap,minAssetPendingBillingDateMap,lineitemList);
                    bundleIdAdditionalInfoMap = addAdditionalInfoOnProcessedItems(oLineItem,minAssetPendingBillingDateMap,bundleIdAdditionalInfoMap);
                }
                System.debug('lineItemList===OUT======>'+lineItemList);
                if(!lineItemList.isEmpty()){
                    System.debug('lineItemList=========>'+lineItemList);
                    update lineItemList;
                }
                
                For(ID cartid : cartidOrderIdMap.keySet()){
                    activateOrder(cartid,cartidOrderIdMap);
                }
            }
            System.debug('bundleIdAdditionalInfoMap=========>'+bundleIdAdditionalInfoMap);
            for(APTS_Index_Transaction__c indTrans : (List<APTS_Index_Transaction__c>) indTransList){
                    indTrans.APTS_Is_Processed__c = 'Processed';
                    
                    if(!bundleIdAdditionalInfoMap.isEmpty() && bundleIdAdditionalInfoMap.get(indTrans.APTS_Asset_Line_Item__c)!=null){
                        indTrans.APTS_Processing_Status__c = bundleIdAdditionalInfoMap.get(indTrans.APTS_Asset_Line_Item__c);
                    }else{
                        indTrans.APTS_Processing_Status__c = 'Processed with no errors';
                    }
                    indTrans.APTS_Indexed_order__c = oOrder.id;
                    transUpdateList.add(indTrans);
            }
            System.debug('******transUpdateList=====>'+transUpdateList);
            if(transUpdateList.size() > 0){
                Database.update(transUpdateList, false);
            }
            
        }catch(Exception ex){
            System.debug('******failure=====>'+ex.getMessage() + ex.getLineNumber());
            List<APTS_Index_Transaction__c> tranList = new List<APTS_Index_Transaction__c>();
            for(APTS_Index_Transaction__c indTrans : (List<APTS_Index_Transaction__c>) indTransList){
                    indTrans.APTS_Processing_Status__c = String.valueOf(ex) + '\n\n' + ex.getStackTraceString();
                    indTrans.APTS_Is_Processed__c = 'Processed with errors'; 
                    indTrans.APTS_Indexed_order__c = oOrder.id;
                    tranList.add(indTrans);
            }
            if(tranList.Size()>0){
                update tranList;
            }
            System.debug('******tranList- failure=====>'+tranList);
        }
    }
    public static void activateOrder(Id cartId,Map<Id, Id> cartidOrderIdMap ) {
        Id orderId = cartidOrderIdMap.get(cartId);
        //Stamp next Billing Date on line items
        if(!Test.isRunningTest()){
            if(cartId != null && orderId != null) {
                APTS_OrderUtils.repriceCart(cartId);
                APTS_OrderUtils.repriceCart(cartId);
                APTS_OrderUtils.repriceCart(cartId);
                APTS_OrderUtils.finalizeCart(cartId);
                APTS_OrderUtils.syncCart(cartId);
                APTS_OrderUtils.acceptOrder(orderId);
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        Set<String> pendingJobStatus = new Set<String>{'Preparing','Processing','Queued','Holding'};
        List<AsyncApexJob> pendingJobs = [select Status from AsyncApexJob where ApexClass.name like '%IndexationBatch%' and Status IN : pendingJobStatus and ParentJobId =null];
        System.debug('*****pendingJobs=====>'+pendingJobs);
        if(pendingJobs.isEmpty()){
            if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
                TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());
                Database.delete(triggerSettings,false);
            }
            if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null){            
                ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
                Database.delete(PBSettings,false);
            }
        }
    }
    
    public static void manageIndexedOptionLineItems(Apttus_Config2__LineItem__c oLineItem, Map<String,Decimal> indexBundlePercentageMap,Map<String,Date> minAssetPendingBillingDateMap,List<Apttus_Config2__LineItem__c> lineitemList){
         System.debug('minAssetPendingBillingDateMap GET ## Billing check=====>'+minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c));
         System.debug('BP=====>'+oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c);
         System.debug('BPO=====>'+oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c);
         System.debug('ALI=====>'+oLineItem.Apttus_Config2__AssetLineItemId__c);
         /*List<String> optionGroupTSTextList = System.label.APTS_TSOptionGroupIndexation.split(',');
         List<String> optionGroupMCSTextList = System.label.APTS_MCSOptionGroupIndexation.split(',');*/
         List<String> technicalServiceChargeTypes = System.label.APTS_TechnicalServiceChargetypeIndexation.split(',');
        // List<String> machineCareChargeTypes = System.label.APTS_MachineCareChargetypeIndexation.split(',');
         if(!minAssetPendingBillingDateMap.isEmpty() && 
         minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c)!=null &&
         ((oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c==0 && oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c!=null && oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c>0) ||
         (oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c>0 && oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c!=0))){
            oLineItem.Apttus_Config2__StartDate__c = minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c);
            oLineItem.Apttus_Config2__SellingTerm__c=null;
            System.debug('Asset BP======>'+oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c);
            if(oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c==null){
                oLineItem.Apttus_Config2__BasePriceOverride__c=oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c;
            }
            if(oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c!=null){
                oLineItem.Apttus_Config2__BasePriceOverride__c=oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c;
            }
            System.debug('old BPO======>'+oLineItem.Apttus_Config2__BasePriceOverride__c);
            if(oLineItem.Apttus_Config2__BasePriceOverride__c!=null && oLineItem.Apttus_Config2__BasePriceOverride__c!=0){
                /*if(machineCareChargeTypes.contains(oLineItem.Apttus_Config2__ChargeType__c) &&
                    indexBundlePercentageMap.get(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c+MACHINECARESERVICE)!=null){
                    oLineItem.Apttus_Config2__BasePriceOverride__c += (oLineItem.Apttus_Config2__BasePriceOverride__c * (indexBundlePercentageMap.get(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c+MACHINECARESERVICE)/100));
                }*/
                System.debug('new BPO==MCS====>'+oLineItem.Apttus_Config2__BasePriceOverride__c);
                if(technicalServiceChargeTypes.contains(oLineItem.Apttus_Config2__ChargeType__c) && 
                    indexBundlePercentageMap.get(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c+TECHSERVICES)!=null){
                    oLineItem.Apttus_Config2__BasePriceOverride__c += (oLineItem.Apttus_Config2__BasePriceOverride__c * (indexBundlePercentageMap.get(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c+TECHSERVICES)/100));
                }  
            }
            oLineItem.APTS_is_Indexation_skip__c=true;
            System.debug('new BPO==TS====>'+oLineItem.Apttus_Config2__BasePriceOverride__c); 
            lineitemList.add(oLineItem);
        }
    }
    public static Map<id,String> addAdditionalInfoOnProcessedItems(Apttus_Config2__LineItem__c oLineItem,Map<String,Date> minAssetPendingBillingDateMap,Map<Id,String> bundleIdAdditionalInfoMap){
        String additionalMessage = bundleIdAdditionalInfoMap.get(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c);
        if(additionalMessage==null){additionalMessage='';}
        if(minAssetPendingBillingDateMap.isEmpty() || (!minAssetPendingBillingDateMap.isEmpty() && minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c)==null)){
            additionalMessage+= oLineItem.Apttus_Config2__OptionId__r.name + ' => ' + 'No pending billing schedule found anymore, manual renewal & indexation needed. ' + '\n';
        }
        if(oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BasePrice__c==0 && oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c==null){
            additionalMessage+= oLineItem.Apttus_Config2__OptionId__r.name + ' => ' + 'Base Price 0 found no indexation done. ' + '\n';
        }
        if(oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__AssetLineItemId__r.APTS_BasePriceOverride__c==0){
            additionalMessage+= oLineItem.Apttus_Config2__OptionId__r.name + ' => ' + 'Base Price Override 0 found no indexation done. ' + '\n';
        }
        /*if(oLineItem.Apttus_Config2__AssetLineItemId__c!=null && oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c <= System.TODAY()){
            additionalMessage+= oLineItem.Apttus_Config2__OptionId__r.name + ' => ' + 'End date of the option before indexation date, manual renewal & indexation needed. ' + '\n';
        }*/
        bundleIdAdditionalInfoMap.put(oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BundleAssetId__c,additionalMessage);
        System.debug('bundleIdAdditionalInfoMap=========>'+bundleIdAdditionalInfoMap);
        return bundleIdAdditionalInfoMap;
    }
}