/*******************************************************************************************
Name            : APTS_RelatedAgreementQueueable
Created By      : Mahesh Chilaka
Created Date    : 05-07-2019
Description     : This class having custom logic to Amend/Renew Agreement. 
Version history : 1.0
*********************************************************************************************/
public class APTS_RelatedAgreementQueueable implements Queueable {

    private static String OBJECT_NAME = 'Related Agreement';
    private static String STREAM = 'CLM';
    private static String CODE_TYPE = 'Apex';
    private static String IS_RENEWED_BY = 'Is Renewed By';
    private static String IS_RENEWAL_FOR = 'Is Renewal For';
    private static String IS_AMENDED_BY = 'Is Amended By';
    private static String IS_AMENDED_FOR = 'Is Amendment For';
    private static String LABEL_MONTHLY = 'Monthly';
    public static Map<Id,Id> oldAgrToNewMap = new Map<Id,Id>();
    public set<Id> agreementFromSet = new set<Id>();
    //DFT2C-1249 | Reference : REF01 | Below constructor helps to run only for specific agreement 
    public APTS_RelatedAgreementQueueable(set<Id> fromAgrrSet){
        agreementFromSet=fromAgrrSet;
    }
    public void execute(QueueableContext context) {
        //Do some action here
        APTS_AgreementLineItemTriggerHandler.isBatchExecuting=true;
        List<Apttus__APTS_Related_Agreement__c> relAgreeList = new List<Apttus__APTS_Related_Agreement__c>();        
        Set<Id> relAgreeSet = new Set<Id>();
        Set<Id> toAgreementSet = new Set<Id>();
        Map<Id, APTS_Related_Agreement_Transaction__c> relAgreeTransMap = new Map<Id, APTS_Related_Agreement_Transaction__c>();
        Boolean hasProdConfig = false;
        System.debug('agreementFromSet=======>'+agreementFromSet);
        //DFT2C-1249 | Reference : REF01 | Below line helps to run only for specific agreement i.e. helping redued one queueable on the refrenced point.
        for(APTS_Related_Agreement_Transaction__c relAgreeTran : [SELECT Id, Related_Agreement__c, Related_Agreement__r.Apttus__APTS_Contract_From__c, Related_Agreement__r.Apttus__APTS_Contract_To__c,
                                                                                IsAgreeFinalizeCartExecuted__c, IsAgreeProductConfigExecuted__c 
                                                                    FROM APTS_Related_Agreement_Transaction__c
                                                                    WHERE Status__c = 'TBProcessed' and IsExecuted__c = false and Related_Agreement__r.Apttus__APTS_Contract_From__c IN : agreementFromSet]){
            toAgreementSet.add(relAgreeTran.Related_Agreement__r.Apttus__APTS_Contract_To__c);
            relAgreeSet.add(relAgreeTran.Related_Agreement__c);
            relAgreeTransMap.put(relAgreeTran.Related_Agreement__r.Apttus__APTS_Contract_From__c, relAgreeTran);
       } 
       System.debug('relAgreeSet=======>'+relAgreeSet);  

         if(!relAgreeSet.isEmpty()) {

            relAgreeList = [Select Id,  Apttus__APTS_Contract_From__c, Apttus__Relationship_From_Type__c,
                                        Apttus__APTS_Contract_To__c, Apttus__Relationship_To_Type__c
                            FROM Apttus__APTS_Related_Agreement__c WHERE Id IN: relAgreeSet LIMIT 1];

            for(Apttus_Config2__ProductConfiguration__c prodConfig : [SELECT id, Apttus_Config2__NumberOfItems__c, Apttus_CMConfig__AgreementId__c 
                                                                      FROM Apttus_Config2__ProductConfiguration__c 
                                                                      WHERE Apttus_CMConfig__AgreementId__c =: relAgreeList[0].Apttus__APTS_Contract_From__c AND
                                                                            Apttus_Config2__Status__c = 'Finalized' 
                                                                            ORDER BY Createddate DESC LIMIT 1]){
                    hasProdConfig = true;
                    
                    if(prodConfig.Apttus_Config2__NumberOfItems__c < = 100 && 
                        !relAgreeTransMap.get(prodConfig.Apttus_CMConfig__AgreementId__c).IsAgreeProductConfigExecuted__c && 
                        !relAgreeTransMap.get(prodConfig.Apttus_CMConfig__AgreementId__c).IsAgreeFinalizeCartExecuted__c) {
                        initialCall(relAgreeList, true, false, true);
                    }
                    else if(relAgreeTransMap.get(prodConfig.Apttus_CMConfig__AgreementId__c).IsAgreeProductConfigExecuted__c && 
                            !relAgreeTransMap.get(prodConfig.Apttus_CMConfig__AgreementId__c).IsAgreeFinalizeCartExecuted__c){
                         initialCall(relAgreeList, false, true, false);
                    }
                    else { 
                         initialCall(relAgreeList, true, false, false);
                     }
                               
            }
            //DFT2C-1249 | Commented below code as its no longer needed added justification @ reference : REF01(search comments).
            /*if(hasQueueableJobRunning() && relAgreeSet.size() >= 1) {
                if(!Test.isRunningTest()) { 
                    System.debug('************************Inside related queable 2 time********************************');
                    System.enqueuejob( new APTS_RelatedAgreementQueueable()); }
            }*/
            //DFT2C-1249 | Once agreement line items are created - fire counter reading Queue. 
            if(!toAgreementSet.isEmpty() && !Test.isRunningTest()){
                enqueueCounterReadingQueue(toAgreementSet);
            }

        if(!hasProdConfig) {  updateRelatedAgreeTransaction(relAgreeSet, false, false, true); }
        }


    }
    
    /* This method will be initialCall for amend/renew agreement */
    public static void initialCall(List<SObject> newList, Boolean executeProductConfig, Boolean executeFinalCart, Boolean directCall){

        Set<Id> amendSetId = new Set<Id>();
        Set<Id> renewedAgreeSetId = new Set<Id>();
        List<Apttus_Config2__ProductConfiguration__c> prodConList = new List<Apttus_Config2__ProductConfiguration__c>();        
        Map<Id,Id> agreementMap = new Map<Id,Id>(); 
        
        set<Id> fromAgreementSet = new set<Id>();
        Boolean isSuccess = false;
        set<Id> amendSet = new set<Id>();
        set<Id> renewSet = new set<Id>();
        Set<Decimal> rmvLines = new Set<Decimal>();
        Set<ID> productCartID = new Set<ID>();
        Set<ID> relAgreeId = new Set<ID>();
        List<Apttus_Config2__LineItem__c> liSOList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        
        try {
            APTS_ConfigurationTriggerHandler.isTriggerDisabled = true;
            //Logic for Deep cloning and Finalizing the Product Configuration from Parent to Child Agreement
            for(Apttus__APTS_Related_Agreement__c relAggr : (List<Apttus__APTS_Related_Agreement__c>)newList){
                amendSetId.add(relAggr.Apttus__APTS_Contract_To__c);
                relAgreeId.add(relAggr.Id);

                if(relAggr.Apttus__APTS_Contract_To__c != null && relAggr.Apttus__APTS_Contract_From__c != null){
                    agreementMap.put(relAggr.Apttus__APTS_Contract_To__c, relAggr.Apttus__APTS_Contract_From__c);
                    fromAgreementSet.add(relAggr.Apttus__APTS_Contract_From__c);
                    
                    if(IS_RENEWED_BY.equalsIgnoreCase(relAggr.Apttus__Relationship_From_Type__c) && IS_RENEWAL_FOR.equalsIgnoreCase(relAggr.Apttus__Relationship_To_Type__c)){
                        renewSet.add(relAggr.Apttus__APTS_Contract_To__c);
                    }
                    
                    if(IS_AMENDED_BY.equalsIgnoreCase(relAggr.Apttus__Relationship_From_Type__c) && IS_AMENDED_FOR.equalsIgnoreCase(relAggr.Apttus__Relationship_To_Type__c)){
                        amendSet.add(relAggr.Apttus__APTS_Contract_To__c);
                    }
                }
            }

            if(executeProductConfig){
                 relatedAgreementFinalizeCart(newList, amendSetId, relAgreeId, agreementMap, fromAgreementSet, renewSet, amendSet);
                 //relatedAgreementProductConfig(newList, directCall, amendSetId, relAgreeId, agreementMap, fromAgreementSet, renewSet, amendSet);
            }
            else if (executeFinalCart){
                relatedAgreementFinalizeCart(newList, amendSetId, relAgreeId, agreementMap, fromAgreementSet, renewSet, amendSet);
            }

       }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), CODE_TYPE,ex.getMessage() + '\n\n' + ex.getStackTraceString(), OBJECT_NAME, null, STREAM, false, false, null, true);
             updateRelatedAgreeTransaction(relAgreeId, false, false, true);
        } 
         
    }

    /* Copy agreement product configuration. */
    /*public static void relatedAgreementProductConfig(List<SObject> newList, Boolean directCall, Set<Id> amendSetId, Set<Id> relAgreeId, Map<Id, Id> agreementMap, Set<Id> fromAgreementSet, Set<Id> renewSet, Set<Id> amendSet){
    
       
        Boolean isSuccess = false;
        Set<Decimal> rmvLines = new Set<Decimal>();
        Set<ID> productCartID = new Set<ID>();
        List<Apttus_Config2__LineItem__c> liSOList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        
        try {
            APTS_ConfigurationTriggerHandler.isTriggerDisabled = true;
            //Logic for Deep cloning and Finalizing the Product Configuration from Parent to Child Agreement
            for(Apttus__APTS_Related_Agreement__c relAggr : (List<Apttus__APTS_Related_Agreement__c>)newList){
                isSuccess = Apttus_CMConfig.CMConfigWebService.copyProductConfiguration(relAggr.Apttus__APTS_Contract_From__c,relAggr.Apttus__APTS_Contract_To__c);
                relAgreeId.add(relAggr.Id);
             }
            
            if(isSuccess){
                for(Apttus_Config2__ProductConfiguration__c prodConList1 : [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__Status__c 
                                                                             FROM Apttus_Config2__ProductConfiguration__c
                                                                            WHERE Apttus_CMConfig__AgreementId__c IN: amendSetId]){
                    
                    
                    prodConList1.APTS_Amendment_CER_Creation__c = false;
                    prodConfigList.add(prodConList1);
                    productCartID.add(prodConList1.ID);
                }
                
                for(Apttus_Config2__LineItem__c removelineitem : [SELECT ID,
                                                                    APTS_is_Tax_and_VAT_calculated__c, 
                                                                    APTS_Asset_Change_type__c,
                                                                    Apttus_Config2__IsPrimaryLine__c,
                                                                    Apttus_Config2__AssetLineItemId__c,
                                                                    Apttus_Config2__LineNumber__c 
                                                                    FROM Apttus_Config2__LineItem__c 
                                                                    WHERE Apttus_Config2__ConfigurationId__c IN: productCartID]){
                    if(removelineitem.Apttus_Config2__IsPrimaryLine__c == true && removelineitem.Apttus_Config2__AssetLineItemId__c != null){
                        rmvLines.add(removelineitem.Apttus_Config2__LineNumber__c);
                    }else if(!removelineitem.APTS_is_Tax_and_VAT_calculated__c){
                        removelineitem.APTS_is_Tax_and_VAT_calculated__c = true;
                        liSOList.add(removelineitem);
                    }
                }
                
                if(liSOList.size()>0){
                    update liSOList;
                }
                
                if(prodConfigList.size()>0){
                    update prodConfigList;
                }
                
                Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO request = new Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO();                
                for(ID cartId : productCartID){
                    if(!rmvLines.isEmpty()){
                        for(Decimal i : rmvLines){
                            request.LineNumbers.add(i);
                            request.CartId = cartId;
                        }
                    }
                }
                Apttus_CPQApi.CPQWebService.removeMultiBundles(request);
                
                if(directCall) {
                    relatedAgreementFinalizeCart(newList, amendSetId, relAgreeId, agreementMap, fromAgreementSet, renewSet, amendSet);
                }
                else {
                       updateRelatedAgreeTransaction(relAgreeId, true, false, false);
                }
            }  

            
                

        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), CODE_TYPE, ex.getMessage() + '\n\n' + ex.getStackTraceString(), OBJECT_NAME, null, STREAM, false, false, null, true);
            updateRelatedAgreeTransaction(relAgreeId, false, false, true);
        } 
            
    }*/
    
    /* Finalize agreement product cart */
    public static void relatedAgreementFinalizeCart(List<SObject> newList, Set<Id> amendSetId, Set<Id> relAgreeId, Map<Id, Id> agreementMap, Set<Id> fromAgreementSet, Set<Id> renewSet, Set<Id> amendSet){
        
        
        Set<ID> productCartID = new Set<ID>();
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> fromAgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigListnew = new List<Apttus_Config2__ProductConfiguration__c>();
        
     try{
            APTS_ConfigurationTriggerHandler.isTriggerDisabled = true;           

            /*for(Apttus_Config2__ProductConfiguration__c prodConList1 : [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__Status__c 
                                                                             FROM Apttus_Config2__ProductConfiguration__c
                                                                            WHERE Apttus_CMConfig__AgreementId__c IN: amendSetId]){
                      productCartID.add(prodConList1.ID);
                }

                for( ID cartId : productCartID){
                    Apttus_CpqApi.CPQ.FinalizeCartRequestDO finalizeRequest = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
                    finalizeRequest.CartId = CartId;
                    if(!Test.isRunningTest()) { Apttus_CpqApi.CPQ.FinalizeCartResponseDO finalizeResponse = Apttus_CpqApi.CPQWebService.finalizeCart(finalizeRequest); }
                }
            */
         
            for(Apttus__APTS_Agreement__c agree : [SELECT Id, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, APTS_Agreement_Duration_Months__c,
                                                           Apttus__Subtype__c, APTS_Agreement_Request__c  
                                                   FROM Apttus__APTS_Agreement__c
                                                   WHERE Id IN: fromAgreementSet ]){
                fromAgreementMap.put(agree.Id, agree);
            }
            
            for(Id updatedAgreementId : agreementMap.Keyset()){
                if(agreementMap.get(updatedAgreementId) != null && fromAgreementMap.containsKey(agreementMap.get(updatedAgreementId)) && fromAgreementMap.get(agreementMap.get(updatedAgreementId)) != null){
                    Apttus__APTS_Agreement__c updatedAgreement = new Apttus__APTS_Agreement__c();
                    updatedAgreement.Id = updatedAgreementId;
                    if(renewSet.contains(updatedAgreementId) && fromAgreementMap.get(agreementMap.get(updatedAgreementId)).Apttus__Contract_End_Date__c != null){
                        Date renewAgreeStartDate = fromAgreementMap.get(agreementMap.get(updatedAgreementId)).Apttus__Contract_End_Date__c.adddays(1);
                        updatedAgreement.Apttus__Contract_Start_Date__c = renewAgreeStartDate;
                        //DFT2C-796 changes | Agreement renewal should be -1 day in general
                        updatedAgreement.Apttus__Contract_End_Date__c = renewAgreeStartDate.addMonths(12).addDays(-1);
                        updatedAgreement.APTS_Agreement_Duration_Months__c = 12;
                        updatedAgreement.APTS_Agreement_Request__c = 'Renewal';
                        agreementList.add(updatedAgreement);
                        
                    }
                    if(amendSet.contains(updatedAgreementId)){
                        updatedAgreement.Apttus__Contract_Start_Date__c = fromAgreementMap.get(agreementMap.get(updatedAgreementId)).Apttus__Contract_Start_Date__c;
                        updatedAgreement.Apttus__Contract_End_Date__c = fromAgreementMap.get(agreementMap.get(updatedAgreementId)).Apttus__Contract_End_Date__c;
                        updatedAgreement.Apttus__Subtype__c = fromAgreementMap.get(agreementMap.get(updatedAgreementId)).Apttus__Subtype__c;
                        updatedAgreement.APTS_Agreement_Request__c = 'Amendment';
                        if(updatedAgreement.Apttus__Contract_Start_Date__c != null && updatedAgreement.Apttus__Contract_End_Date__c != null){
                           updatedAgreement.APTS_Agreement_Duration_Months__c = Apttus_Config2.CPQWebService.computeTerm(updatedAgreement.Apttus__Contract_Start_Date__c,updatedAgreement.Apttus__Contract_End_Date__c,LABEL_MONTHLY);                                                     
                        }
                        agreementList.add(updatedAgreement);
                    }
                }
            }
            
            //update agreementList;
            Database.update(agreementList , false);
            for(Apttus_Config2__ProductConfiguration__c prodConList1 : [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__Status__c 
                                                                             FROM Apttus_Config2__ProductConfiguration__c
                                                                            WHERE Apttus_CMConfig__AgreementId__c IN: amendSetId]){
                      productCartID.add(prodConList1.ID);
                }
                list<Apttus_Config2__LineItem__c> finallineupdate=new list<Apttus_Config2__LineItem__c>();
                Map<id,Apttus_Config2__LineItem__c>finalmap=new Map<Id,Apttus_Config2__LineItem__c>();
                APTS_IndexedRepriceCtrl irc=new APTS_IndexedRepriceCtrl();
                system.debug('++Shahul++productCartID+++'+productCartID);
                finallineupdate=irc.IndexedRepriceapi(productCartID);
                for(Apttus_Config2__LineItem__c linemap:finallineupdate){
                finalmap.put(linemap.Id,linemap);
                
                }
                system.debug('++Shahul++finallineupdate+++'+finallineupdate);
            for(Apttus_Config2__LineItem__c lineitemUpdate:[select id,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:productCartID]){
                    if(lineitemUpdate.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c=='Renewal'){
                    Date renewAgreeStartDate = fromAgreementMap.get(agreementMap.get(lineitemUpdate.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c)).Apttus__Contract_End_Date__c.adddays(1);
                    lineitemUpdate.Apttus_Config2__StartDate__c=renewAgreeStartDate;
                    lineitemUpdate.Apttus_Config2__EndDate__c=renewAgreeStartDate.addMonths(12).addDays(-1); 
                    //finallineupdate.add(lineitemUpdate);  
                    finalmap.put(lineitemUpdate.Id,lineitemUpdate);                 
                }
                }
                if(finalmap.size()>0){
                Database.update(finalmap.values(),false);}
                system.debug('+++AnalysisStarted+++');
                for( ID cartId : productCartID){
                    Apttus_CpqApi.CPQ.FinalizeCartRequestDO finalizeRequest = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
                    finalizeRequest.CartId = CartId;
                    if(!Test.isRunningTest()) { Apttus_CpqApi.CPQ.FinalizeCartResponseDO finalizeResponse = Apttus_CpqApi.CPQWebService.finalizeCart(finalizeRequest); }
                }
                for(Apttus_Config2__ProductConfiguration__c prodConList2 : [SELECT Id, Apttus_CMConfig__AgreementId__c, Apttus_Config2__Status__c,APTS_Amendment_CER_Creation__c 
                                                                             FROM Apttus_Config2__ProductConfiguration__c
                                                                            WHERE ID IN:productCartID]){
                      if(prodConList2.APTS_Amendment_CER_Creation__c==true){prodConList2.APTS_Amendment_CER_Creation__c=false;
                      }
                      prodConfigListnew.add(prodConList2);
                }
                if(prodConfigListnew.size()>0){
                    update prodConfigListnew;
                }
            updateRelatedAgreeTransaction(relAgreeId, false, true, false);

            //System.enqueueJob(new APTS_AgreementLIOnCounterReading(newItems));

        }catch(Exception ex){
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), CODE_TYPE,ex.getMessage() + '\n\n' + ex.getStackTraceString(), OBJECT_NAME, null, STREAM, false, false, null, true);
            updateRelatedAgreeTransaction(relAgreeId, false, false, true);
        } 
    }

     /* This method will return true if there no jobs running */
    public static boolean hasQueueableJobRunning(){

           Set<String> status = new Set<String>();
            status.add('Completed');
            status.add('Failed');
            status.add('Aborted');
            
            
            Set<String> classNames = new Set<String>();
            status.add('APTS_RelatedAgreementQueueable');

            List<AsyncApexJob> hasJobs = [Select id, apexclass.name, JobType, Status from AsyncApexJob where apexclass.name IN: classNames and Status Not IN: status];
             
            if(hasJobs.isEmpty()){ 
                return true;
            }

            return false;
    }

    /* This method will update related agreement transaction */
    public static void updateRelatedAgreeTransaction(Set<Id> relAgreeId, boolean productConfig, boolean finaCart, boolean failed) {

        List<APTS_Related_Agreement_Transaction__c> relAgreeTranList = new List<APTS_Related_Agreement_Transaction__c>();
                    
        for( APTS_Related_Agreement_Transaction__c relAgreeTran :[SELECT Id, IsAgreeProductConfigExecuted__c, IsAgreeFinalizeCartExecuted__c, IsExecuted__c, Status__c FROM APTS_Related_Agreement_Transaction__c WHERE Related_Agreement__c IN: relAgreeId]) {
            if(productConfig){
                relAgreeTran.IsAgreeProductConfigExecuted__c = true;
            }
            else if(finaCart){
                relAgreeTran.IsAgreeFinalizeCartExecuted__c = true;
                relAgreeTran.IsExecuted__c = true;
                relAgreeTran.Status__c = 'Completed';
            }
            else if(failed){
                relAgreeTran.IsExecuted__c = true;
                relAgreeTran.Status__c = 'Failed';
            }

            relAgreeTranList.add(relAgreeTran);
        }

        if(!relAgreeTranList.isEmpty()){
            update relAgreeTranList;
        }
    }
    //DFT2C-1249 | Update counter reading once all agreement line items are created. 
    public static void enqueueCounterReadingQueue(Set<ID> agreementIdList){
        String EMPTY_STRING = ' ';
        System.debug('agreementIdList============>'+agreementIdList);
        Map<Id,Apttus__AgreementLineItem__c> agreementLineItemMap = new Map<Id,Apttus__AgreementLineItem__c>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Apttus__AgreementLineItem__c').getDescribe().fields.getMap();
        String thisQuery = Label.APTS_SelectLabel + EMPTY_STRING;
        for(Schema.SObjectField field : fieldMap.values()){
            thisQuery += field.getDescribe().getName() + Label.APTS_CommaSeparator;
        }
        thisQuery = thisQuery.subString(0, thisQuery.length()-1);
        thisQuery += EMPTY_STRING + Label.APTS_FromLabel + EMPTY_STRING + 'Apttus__AgreementLineItem__c' + EMPTY_STRING + 'Where Apttus__AgreementId__c IN: agreementIdList';
        System.debug('thisQuery============>'+thisQuery);


        For(Apttus__AgreementLineItem__c sobj : Database.query(thisQuery)){
            agreementLineItemMap.put(sobj.id,sobj);
        }
        System.debug('agreementLineItemMap============>'+agreementLineItemMap);
        System.debug('========================Inside counter reading queable========================');
        APTS_AgreementLIOnCounterReading astCntReading =  new APTS_AgreementLIOnCounterReading(agreementLineItemMap);
        System.enqueueJob(astCntReading);
    }
}