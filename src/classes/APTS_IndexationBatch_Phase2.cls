/**
 * @description       : APTS_IndexationBatch_Phase2
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 31-03-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   02-02-2021   Karan Khatri   Initial Version
**/
global class APTS_IndexationBatch_Phase2 implements Database.Batchable<sObject>{

    String query;
    Boolean isStandardIndexation;
    private static String BATCHNAME = 'APTS_StandardIndexBatch_Phase2';
    private static String STREAM = 'CLM';
    private static String TYPE = 'Batch';
    private static final String HYPHEN = '-';
    Set<ID> AgreementIDSet = new Set<ID>();
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
    
    Map<String, String> agmtIdToIndexNumberMap = new Map<String, String>();

    global APTS_IndexationBatch_Phase2(Set<ID> AgreementIDSet,Map<String, String> agmtIdToIndexNumberMap, Boolean isStdIndex){
                
        if(!AgreementIDSet.isEmpty()){
            this.AgreementIDSet = AgreementIDSet;
        }
         if(!agmtIdToIndexNumberMap.isEmpty()){
            this.agmtIdToIndexNumberMap = agmtIdToIndexNumberMap;
        }
        this.isStandardIndexation = isStdIndex;
        System.debug('*******AgreementIDSet========>'+AgreementIDSet);
        
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
       //Set<String> optionGroupCheckSet = new Set<String>{TECHSERVICE,RESPONSETIME,SERVICEWINDOW,VALUEADDEDSERVICE,PREVENTIVEMAINTENANCE,CONNECTEDCOFFEEMACHINE,MACHINECARE,VALUEADDEDMACHINECARE};
       //List<String> optionGroupCheckSet = System.label.APTS_OptionGroupTextIndexation.split(',');
       /*List<String> optionGroupCheckSet = new List<String>();
       optionGroupCheckSet.addAll(System.label.APTS_TSOptionGroupIndexation.split(','));
       optionGroupCheckSet.addAll(System.label.APTS_MCSOptionGroupIndexation.split(','));*/
       List<String> indexSupportedChargeTypes = new List<String>();
       indexSupportedChargeTypes.addAll(System.label.APTS_TechnicalServiceChargetypeIndexation.split(','));
       //indexSupportedChargeTypes.addAll(System.label.APTS_MachineCareChargetypeIndexation.split(',')); 
       System.debug('***indexSupportedChargeTypes====>'+indexSupportedChargeTypes);
       System.debug('agreementIdSet=============>'+agreementIdSet);
        try{
            for(APTS_Batch_Queries__mdt batchQuery : [SELECT Id,
                                                          APTS_Query_String__c
                                                          FROM APTS_Batch_Queries__mdt
                                                          WHERE APTS_Batch_Name__c =: BATCHNAME]){
                query = batchQuery.APTS_Query_String__c;
            }
            System.debug('QUERY=================>'+query);
            return Database.getQueryLocator(query);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), TYPE, String.valueOf(ex) ,BATCHNAME, null, STREAM, false, false, null, true); return null;}
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<String, Set<ID>> agrAcnt = new Map<String, Set<ID>>();
        Integer assetCount = Integer.valueOf(Label.APTS_Admin_Order_Asset_Count);
        Set<Id> assetLIIdSet = new Set<Id>();
        List<Apttus_Config2_AssetAdjustItem__c> astAdjLineList = new List<Apttus_Config2_AssetAdjustItem__c>();
        Map<Integer, String> integerToALIMap = new Map<Integer, String>();
        Set<ID> AssetIDset = new Set<ID>();
        Map<Id,APTS_Index_Transaction__c> indTransMap = new Map<Id,APTS_Index_Transaction__c>();
        Map<Id, Apttus_Config2__AssetLineItem__c> assetMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
        Map<Id,Id> assetBundleIdERAMap = new Map<Id,Id>();
        Set<Id> bundleAssetIdSet = new Set<Id>();
        Map<Id,Boolean> inProgressDeInstallBundleMap = new Map<Id,Boolean>();
        Integer icount = 1;
        if(!isStandardIndexation) { icount = 11;}
        System.debug('*******agmtIdToIndexNumberMap========>'+agmtIdToIndexNumberMap.size());
        System.debug('*******scope========>'+scope.size());
        if(!agmtIdToIndexNumberMap.isEmpty()){
            for(Apttus_Config2__AssetLineItem__c astLine : (List<Apttus_Config2__AssetLineItem__c>) scope){
                //assetMap.put(astLine.Id, astLine);
                if(String.IsNotBlank(astLine.Apttus_Config2__BundleAssetId__c)){
                    assetBundleIdERAMap.put(astLine.Apttus_Config2__BundleAssetId__c,astLine.APTS_relatedlist_agreement__c);
                }
                bundleAssetIdSet.add(astLine.Apttus_Config2__BundleAssetId__c);
            }
            inProgressDeInstallBundleMap = APTS_ValidationCallBack.validateIfDeinstallationOrder(bundleAssetIdSet);
            if(!assetBundleIdERAMap.isEmpty()){
                For(ID bundleId : assetBundleIdERAMap.keySet()){       
                    APTS_Index_Transaction__c indTrans = new APTS_Index_Transaction__c();
                    indTrans.APTS_Asset_Line_Item__c=bundleId;
                    indTrans.APTS_Is_Processed__c='Unprocessed';
                    indTrans.APTS_Processing_Status__c=null;
                    indTrans.APTS_Indexed_order__c=null;
                    indTrans.APTS_Machine_care_Index__c=null;
                    indTrans.APTS_Technical_services_Index__c=null;
                    indTrans.Thread__c=null;
                    if(!inProgressDeInstallBundleMap.isEmpty() && inProgressDeInstallBundleMap.KeySet().contains(bundleId)){
                        indTrans.APTS_Is_Processed__c = 'Ignored';
                        indTrans.APTS_Processing_Status__c='Open de-installation against the order thus no indexation can be done';
                    }
                    indTrans.APTS_is_Standard_indexation__c=isStandardIndexation;
                    if(assetBundleIdERAMap.get(bundleId)!=null && agmtIdToIndexNumberMap.get(assetBundleIdERAMap.get(bundleId)+ HYPHEN +MACHINECARESERVICE)!=null){
                        indTrans.APTS_Machine_care_Index__c =  Decimal.valueOf(agmtIdToIndexNumberMap.get(assetBundleIdERAMap.get(bundleId)+ HYPHEN +MACHINECARESERVICE));
                    }
                    if(assetBundleIdERAMap.get(bundleId)!=null && agmtIdToIndexNumberMap.get(assetBundleIdERAMap.get(bundleId)+ HYPHEN +TECHSERVICES)!=null){
                        indTrans.APTS_Technical_services_Index__c = Decimal.valueOf(agmtIdToIndexNumberMap.get(assetBundleIdERAMap.get(bundleId)+ HYPHEN +TECHSERVICES));
                    }
                    indTrans.Thread__c = String.valueOf(icount);
                    if(indTransMap.get(bundleId)==null){
                        indTransMap.put(bundleId,indTrans);
                    }
                    indTrans.APTS_Index_transaction_Ext_ID__c = bundleId + String.valueOf(Date.Today().month()) + String.valueOf(Date.Today().year());
                    if(isStandardIndexation) {
                        if(icount == Integer.valueOf(System.Label.APTS_IndexationBatchThreadSize)) { 
                            icount = 1; 
                        }else{ 
                            icount++; 
                        }
                    } 
                }
            }
        }
        System.debug('assetMap.size()=============>'+assetMap.size());
        System.debug('astAdjLineList.size()=============>'+astAdjLineList.size());
        System.debug('indTransMap===SIZE==========>'+indTransMap.size());

        if(!indTransMap.isEmpty()){
            Database.upsert(indTransMap.values(),APTS_Index_Transaction__c.fields.APTS_Index_transaction_Ext_ID__c,false);
            //Database.insert(indTransMap.values(),false);
        }
    }

    global void finish(Database.BatchableContext BC) {
        Integer batchsize = 3;  
         if(isStandardIndexation) {
              //Id batchInstanceId = Database.executeBatch(new APTS_IndexationBatch_Phase3('1'),1);
              //Id batchInstanceId2 = Database.executeBatch(new APTS_IndexationBatch_Phase3('2'),1);
              Integer indexationBatchThreadSize = Integer.valueOf(System.Label.APTS_IndexationBatchThreadSize);
              //Not greater than 3 threads are allowed | Risk on ORG BATCH DEADLOCK
              if(indexationBatchThreadSize<=3){
                    /*For(Integer i=1;i<=indexationBatchThreadSize;i++){
                        //Database.executeBatch(new APTS_AssetRenewalBatch_Phase2(String.valueOf(i)),1);
                        Database.executeBatch(new APTS_IndexationBatch_Phase3(String.valueOf(i)),1);
                    }*/
                    if(indexationBatchThreadSize==3){
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('1'),1);
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('2'),1);
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('3'),1);
                    }
                    if(indexationBatchThreadSize==2){
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('1'),1);
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('2'),1);
                    }
                    if(indexationBatchThreadSize==1){
                        Database.executeBatch(new APTS_IndexationBatch_Phase3('1'),1);
                    }
              }
              //Id batchInstanceId3 = Database.executeBatch(new APTS_IndexationBatch_Phase3('3'),1);
          }
          else { //Non-Standard batches
              Id batchInstanceId4 = Database.executeBatch(new APTS_IndexationBatch_Phase3('11'),1);
          }
    }
}