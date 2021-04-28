/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Handler class for APTS_AgreementLineItemTrigger
 * @Created Date: May 3, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      May 3, 2018     Initial Version
        Lavanya .R         May 22, 2018     AgreementIncludes? Updation - FD#50
        Ankit Joshi         Jan 25, 2109    Schedule Counter Reading class only for Consumption Record Type
 * 
 *************************************************************/
 //V101 16-Sep-2019 Aarthi : QTCFLEX1-1282 - Allow counter reading creation for standard deal contracts as well.
 
public without sharing class APTS_AgreementLineItemTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = true;
    public static boolean isBatchExecuting = false; 
    
    public void BeforeInsert(List<SObject> newItems){
        getServiceCostPrices(newItems);  
        String AgreementIncludeTemp = '';
        String AgreementIncludesDbFinal = '';
        String AgreementIncludeToInsert='';
        Set<String> MultiSelectValueSet = new Set<String>();
        String strtemp='';
        Map<ID, Set<String>> AgreementIncludesFinalMap = new Map<ID, Set<String>>();
        Set<Apttus__APTS_Agreement__c> instAgreementSet = new Set<Apttus__APTS_Agreement__c>();
        Set<String> offeringlocal = new Set<String>();      
        //Populate AgreementIncludes field in Agreement, based on the Agreement Lineitems' Option group on each finalise
        //Added by Hari to fix Defect No:16880
        Set<Id> agrids = new Set<Id>();
        Map<String,Decimal> bundleIdRollupOneTimeMap = new Map<String,Decimal>();
        Map<String,Decimal> bundleIdRollupRecurringMap = new Map<String,Decimal>();
        for(Apttus__AgreementLineItem__c instagreementLI : (List<Apttus__AgreementLineItem__c>)newItems)
        {
            if(instagreementLI.Apttus__AgreementId__c != null){
               agrids.add(instagreementLI.Apttus__AgreementId__c);
            }
            if(instagreementLI.Apttus_CMConfig__LineType__c.equalsIgnoreCase('Option') && instagreementLI.Apttus_CMConfig__NetUnitPrice__c!=null && instagreementLI.Apttus__Quantity__c!=null && instagreementLI.Apttus_CMConfig__PriceType__c!=null){
               if(instagreementLI.Apttus_CMConfig__PriceType__c.equalsIgnoreCase('Recurring')){
                    if(bundleIdRollupRecurringMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c))==null){
                        bundleIdRollupRecurringMap.put(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c),instagreementLI.Apttus_CMConfig__NetUnitPrice__c * instagreementLI.Apttus__Quantity__c);
                    }else{
                        Decimal TotalRecurringLines = 0;
                        TotalRecurringLines = bundleIdRollupRecurringMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c));
                        bundleIdRollupRecurringMap.remove(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c));
                        bundleIdRollupRecurringMap.put(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c),TotalRecurringLines + (instagreementLI.Apttus_CMConfig__NetUnitPrice__c * instagreementLI.Apttus__Quantity__c));
                    }
                }
                if(instagreementLI.Apttus_CMConfig__PriceType__c.equalsIgnoreCase('One Time')){
                    if(bundleIdRollupOneTimeMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c))==null){
                        bundleIdRollupOneTimeMap.put(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c),instagreementLI.Apttus_CMConfig__NetUnitPrice__c * instagreementLI.Apttus__Quantity__c);
                    }else{
                        Decimal TotalRecurringLines = 0;
                        TotalRecurringLines = bundleIdRollupOneTimeMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c));
                        bundleIdRollupOneTimeMap.remove(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c));
                        bundleIdRollupOneTimeMap.put(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__ParentBundleNumber__c),TotalRecurringLines + (instagreementLI.Apttus_CMConfig__NetUnitPrice__c * instagreementLI.Apttus__Quantity__c));
                    }
                }
                if(instagreementLI.Apttus_CMConfig__NetUnitPrice__c!=null && instagreementLI.Apttus__Quantity__c!=null){
                    instagreementLI.APTS_Total_price_per_month__c = instagreementLI.Apttus_CMConfig__NetUnitPrice__c * instagreementLI.Apttus__Quantity__c;
                }
            }
        }
        System.debug ('bundleIdRollupRecurringMap====END==FINAL==>'+bundleIdRollupRecurringMap);         
        List<Apttus__APTS_Agreement__c> lstAgreement = new List<Apttus__APTS_Agreement__c>([Select id,APTS_Agreement_Includes__c, APTS_Language__c from Apttus__APTS_Agreement__c where ID IN: agrids]);
        Map<Id,Apttus__APTS_Agreement__c> AgreementMap = new Map<Id,Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c instAg : lstAgreement)
        {
            AgreementMap.put(instAg.id,instAg);  
        }
        for(Apttus__AgreementLineItem__c instagreementLI : (List<Apttus__AgreementLineItem__c>)newItems)
        {         
        //get parent OG and offering in the Set<String>
            
            if(instagreementLI.Offering__c!= NULL)
            {
                offeringlocal.add(instagreementLI.Offering__c) ;
            }
            if(instagreementLI.APTS_Parent_Option_Group__c!=NULL)
            {
                offeringlocal.add(instagreementLI.APTS_Parent_Option_Group__c);
            }
            if(offeringlocal != NULL && Offeringlocal.size()>0)
            { 
               
               for(String p : offeringlocal)
                {
                    if(p.equals(APTS_CPQConstants.LABEL_CONVERSIONMACHINES))
                        {strtemp=APTS_CPQConstants.LABEL_OPERATINGSERVICE; }
                    else if(p.equals(APTS_CPQConstants.LABEL_SERVICE))
                        {strtemp=APTS_CPQConstants.LABEL_SERVICES ;}
                    else if(p.equals(APTS_CPQConstants.LABEL_MACHINE))
                        {strtemp=APTS_CPQConstants.LABEL_MACHINES;}
                    else if(p.equals(APTS_CPQConstants.LABEL_COFFEE) || p.equals(APTS_CPQConstants.LABEL_TEA))
                        {strtemp=APTS_CPQConstants.LABEL_INGREDIENTS;}
                    else {strtemp = p;}
            
                    if(AgreementIncludesFinalMap.containsKey(instagreementLI.Apttus__AgreementId__c)){
                        AgreementIncludesFinalMap.get(instagreementLI.Apttus__AgreementId__c).add(strtemp);
                    }
                    else{
                        AgreementIncludesFinalMap.put(instagreementLI.Apttus__AgreementId__c, new Set<String>{strtemp});
                    }
                     //this set<String> has updated picklist values needed for AgreementInclude? Multiselect picklist   
                }
            }
                    instAgreementSet.add(AgreementMap.get(instagreementLI.Apttus__AgreementId__c));
                 //Calculating total monthly fee and total one time fee per bundle context for output templates
                 if(instagreementLI.Apttus_CMConfig__LineType__c.equalsIgnoreCase('Product/Service') 
                     && !instagreementLI.Apttus_CMConfig__IsOptionRollupLine__c 
                     && instagreementLI.Apttus_CMConfig__HasOptions__c
                     && instagreementLI.Apttus__Quantity__c!=null
                     && instagreementLI.Apttus__Quantity__c!=0){
                     if(!bundleIdRollupRecurringMap.isEmpty() && bundleIdRollupRecurringMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__PrimaryLineNumber__c))!=null){
                         instagreementLI.APTS_Total_Monthly_fee__c = instagreementLI.Apttus__Quantity__c * bundleIdRollupRecurringMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__PrimaryLineNumber__c));
                     }
                     if(!bundleIdRollupOneTimeMap.isEmpty() && bundleIdRollupOneTimeMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__PrimaryLineNumber__c))!=null){
                         instagreementLI.APTS_Total_one_time_fee__c = instagreementLI.Apttus__Quantity__c * bundleIdRollupOneTimeMap.get(instagreementLI.Apttus__ProductId__c+String.valueOf(instagreementLI.Apttus_CMConfig__PrimaryLineNumber__c));
                     }
                 }
                 System.debug ('instagreementLI.APTS_Total_Monthly_fee__c==>'+instagreementLI.APTS_Total_Monthly_fee__c);         
                 System.debug ('instagreementLI.APTS_Total_one_time_fee__c==>'+instagreementLI.APTS_Total_one_time_fee__c);         
        
            }
            for(Apttus__APTS_Agreement__c instAgreement : instAgreementSet)
            {
            /*** PI fix # 190437 ****/
             if(AgreementIncludesFinalMap != null && AgreementIncludesFinalMap.containsKey(instAgreement.ID)){
                for(String t:AgreementIncludesFinalMap.get(instAgreement.ID)) 
                {
                    //only if these updated values then insert intp multiselect picklist
                    AgreementIncludeTemp += (AgreementIncludeTemp==''?'':';')+t;     
                    AgreementIncludeToInsert = AgreementIncludeTemp+';'+instAgreement.APTS_Agreement_Includes__c;                 
                    List<String> MultiSelectValueList = AgreementIncludeToInsert.split(';') ;     
                    MultiSelectValueSet.addAll(MultiSelectValueList);
                } 
                }
                
                for(String t: MultiSelectValueSet)
                {
                    if(t.equals(APTS_CPQConstants.LABEL_MACHINES) || t.equals(APTS_CPQConstants.LABEL_CONCEPTS) || t.equals(APTS_CPQConstants.LABEL_INGREDIENTS) || t.equals(APTS_CPQConstants.LABEL_OPERATINGSERVICE) || t.equals(APTS_CPQConstants.LABEL_SERVICES))
                    {
                    AgreementIncludesDbFinal += (AgreementIncludesDbFinal==''?'':';')+t;
                    instAgreement.APTS_Agreement_Includes__c = AgreementIncludesDbFinal; 
                        
                    } 
                }
            }
            //Added by Pranjal for Language Translation Changes :: START
            List<String> lstLang = new List<String>();

            //This SOQL will be merged with SOQL on line 38 when filter will be applied by CPQ team on it.
            //for(Apttus__APTS_Agreement__c tmpAggr : [SELECT Id, APTS_Language1__c FROM Apttus__APTS_Agreement__c WHERE Id IN: agrids]){
            for(Apttus__APTS_Agreement__c tmpAggr : lstAgreement){
                if(tmpAggr.APTS_Language__c != NULL){
                    lstLang.add(tmpAggr.APTS_Language__c);
                }
            }

            if(lstLang.size() > 0){
                APTS_LanguageTranslator.translateLanguage(newItems, 'Apttus__AgreementLineItem__c', lstLang);
            }
            //Changes for Language Translation :: END
            
            try{
            /*** PI fix # 111922 **** removed isupdateable()***/
                List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
                agreementsToUpdate.addAll(instAgreementSet);
                update agreementsToUpdate;           
            } catch(Exception e){
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', String.valueOf(e) ,'AgreementLineItem', null ,'CPQ',false,false,'cpqerror@accenture.com',true);
            }
    }
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementLineItemTriggerHandlerBeforeUpdate')){
            APTS_CheckRecursive.processedSet.add('APTS_AgreementLineItemTriggerHandlerBeforeUpdate');

            getServiceCostPrices(newList); 
            
            Map<Id, Apttus__AgreementLineItem__c> oldMap = (Map<Id, Apttus__AgreementLineItem__c>) oldItems;
            Map<Id, String> oLIMap = new Map<Id, String>();  
            //Added for Contracted Products change
            for(Apttus__AgreementLineItem__c oALI : [SELECT Id, Apttus__AgreementId__r.Apttus__Contract_Number__c, Apttus_CMConfig__DerivedFromId__r.Name FROM Apttus__AgreementLineItem__c WHERE ID IN: newItems.keySet()]){
                if(String.IsNotBlank(oALI.Apttus__AgreementId__c) && String.IsNotBlank(oALI.Apttus_CMConfig__DerivedFromId__c)){
                    oLIMap.put(oALI.Id, oALI.Apttus__AgreementId__r.Apttus__Contract_Number__c +' - '+ oALI.Apttus_CMConfig__DerivedFromId__r.Name);
                }
            }
            
            //Added by Pranjal for Language Translation Changes :: START
            List<String> lstLang = new List<String>();
            Set<Id> setAgreementIds = new Set<Id>();
            
            for(Apttus__AgreementLineItem__c tmp : (List<Apttus__AgreementLineItem__c>) newList){
                //Added for Contracted Products change
                if(oLIMap.containsKey(tmp.Id) && tmp.Apttus_CMConfig__LineStatus__c == 'New' && String.IsBlank(tmp.APTS_Global_linkage_ID__c)){
                    tmp.APTS_Global_linkage_ID__c = oLIMap.get(tmp.Id);
                    if(tmp.Apttus_CMConfig__IsPrimaryLine__c && String.IsNotBlank(tmp.APTS_Type_of_Contract__c) && tmp.APTS_Type_of_Contract__c != oldMap.get(tmp.Id).APTS_Type_of_Contract__c){
                    tmp.Apttus__Description__c = tmp.Apttus__Description__c+' - '+tmp.APTS_Type_of_Contract__c;
                    }
                }
                setAgreementIds.add(tmp.Apttus__AgreementId__c);
            }

            //This SOQL will be merged with SOQL on line 38 when filter will be applied by CPQ team on it.
            /**The below code is for templates and will be done after 3.1
            for(Apttus__APTS_Agreement__c tmpAggr : [SELECT Id, APTS_Language__c FROM Apttus__APTS_Agreement__c WHERE Id IN: setAgreementIds]){
                if(tmpAggr.APTS_Language__c != NULL){
                    lstLang.add(tmpAggr.APTS_Language__c);
                }
            }

            if(lstLang.size() > 0){
                APTS_LanguageTranslator.translateLanguage(newList, 'Apttus__AgreementLineItem__c', lstLang);
            }**/
            //Changes for Language Translation :: END
        }
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    //Added by Santosh to populate Category hierarchy data on Agreement Header 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        Set<Id> aggIdset = new Set<Id>();
        Set<Id> catgryIdset = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus_Config2__ClassificationHierarchy__c> catghierarchymap = new Map<Id, Apttus_Config2__ClassificationHierarchy__c>();
        Map<Id, String> agglivscatnamemap = new Map<Id, String>();
        Boolean isConsumptionAgeement = false;
        Boolean isBatchContext = false;
        Boolean planogramExists = false;
        string MENU = 'Menu';
        
        for(Apttus__AgreementLineItem__c oALI : (List<Apttus__AgreementLineItem__c>)newList) {            
            aggIdset.add(oALI.Apttus__AgreementId__c);
            if(oALI.Apttus_CMConfig__ClassificationId__c != null) {
                catgryIdset.add(oALI.Apttus_CMConfig__ClassificationId__c);
            }
            //check if Planogram exist
            if(MENU.equalsIgnoreCase(oALI.APTS_Option_Group_Text__c)){
                planogramExists = true;
            }
           
        }
        
        if(!aggIdset.isEmpty()) {
            Id consumptionRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
            for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_AgreementLIRelatedListDetails__c,APTS_Is_Amended_for_Indexation__c,APTS_Created_From_Batch__c, RecordType.Id,Apttus__Status_Category__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                if(!APTS_CheckRecursive.processedSet.contains(string.valueOf(oAgg.id))){//Added by jason.e.mactal | 9.26.2018
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                    APTS_CheckRecursive.processedSet.add(string.valueOf(oAgg.id));
                }
                // v3 Start
                //Check if Consumption Model Agreement is present
                if(oAgg.RecordType.Id == consumptionRecordTypeId){
                    isConsumptionAgeement = true;
                }

                //Check if the context is from Batch
                if(oAgg.APTS_Created_From_Batch__c){
                    isBatchContext = true;
                }
            }
        }

        if(!catgryIdset.isEmpty()) {
            for(Apttus_Config2__ClassificationHierarchy__c ocathier : [select id,name,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where id in: catgryIdset]) {
                catghierarchymap.put(ocathier.Id,ocathier);
            }
        }

        for(Apttus__AgreementLineItem__c oALI : (List<Apttus__AgreementLineItem__c>)newList) {
            if(catghierarchymap.containsKey(oALI.Apttus_CMConfig__ClassificationId__c)) {
                agglivscatnamemap.put(oALI.Id, catghierarchymap.get(oALI.Apttus_CMConfig__ClassificationId__c).Name);
            }
        }

        /**aggMaptUpdate = prepareAggMap(newList, aggMaptUpdate, agglivscatnamemap); 
        
        if(!aggMaptUpdate.isEmpty()) {
            try{
                update aggMaptUpdate.values();      
            } catch(Exception e){
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'AgreementLineItem', null ,'CPQ',false,false,'cpqerror@accenture.com',false);
            }
           
        }**/
        
        //v3 start
        // Enque APTS_AgreementLIOnCounterReading class only for Consumption Model and if Planogram Exist
        System.debug('*****isConsumptionAgeement===========>'+isConsumptionAgeement);
        System.debug('*****planogramExists===========>'+planogramExists);
        System.debug('*****isBatchExecuting===========>'+isBatchExecuting);
        //DFT2C-1249 | Added isBatchExecuting check to skip logic for Agreement ammendment trigger | Alternative code can be found in APTS_RelatedAgreementQueueable(method : enqueueCounterReadingQueue)
       //V101 ++ <<>> - Removed consumption model agreement check -isConsumptionAgeement &&
        if(planogramExists && !isBatchExecuting){
            //Check if context is normal, enqueue batch, else run in synchronous mode
            if(!isBatchContext){
                If(Limits.getQueueableJobs() == 0 ){
                    System.debug('*****APTS_AgreementLIOnCounterReading INVOKED********');
                    APTS_AgreementLIOnCounterReading astCntReading =  new APTS_AgreementLIOnCounterReading(newItems);
                    System.enqueueJob(astCntReading); 
                }
                else{
                    //create entry in the log table
                    APTS_CustomLogging.createErrorLog(null, 'Apex', 'queueable job already running' ,'AgreementLineItem', null ,'CPQ',false,false,'cpqerror@accenture.com',false);
                }
            }
            else{
                APTS_AgreementLIOnCounterReading.createCounterReadings((Map<Id, Apttus__AgreementLineItem__c>) newItems);
            }
        }
        //v3 End
        //Code added by Ankit Joshi to update Agreement Line Item on Counter Reading Data Object
            
           
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        /**The below code is for templates and will be done after 3.1
        if(!APTS_CheckRecursive.processedSet.contains('APTS_AgreementLineItemTriggerHandlerAfterUpdate')){
            APTS_CheckRecursive.processedSet.add('APTS_AgreementLineItemTriggerHandlerAfterUpdate');
            updateaggfield(newList);
        }**/
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        //The below code is for templates and will be done after 3.1
        //updateaggfield(oldList);    
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
 
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().APTS_AgreementLineItemTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /*@methodName - getServiceCostPrices
    * @description - method used to fetch service cost prices
    * @author - jason.e.mactal
    * @param - List<SObject>
    * @return -
    */
    public void getServiceCostPrices(List<SObject> agreementLIList){
        
        try{
            Set<Id> bundleProductsIdSet = new Set<Id>();
            Set<string> salesOrgSet = new Set<string>();
            Set<Id> agreementLIIdSet = new Set<Id>();
            Map<Id,List<APTS_AverageServiceCostPrice__c>> avgServiceCostPriceMap= new Map<Id,List<APTS_AverageServiceCostPrice__c>>();
            
            for(Apttus__AgreementLineItem__c aggLI: (List<Apttus__AgreementLineItem__c>)agreementLIList){
                if(aggLI.Apttus__ProductId__c != NULL)
                bundleProductsIdSet.add(aggLI.Apttus__ProductId__c);
                salesOrgSet.add(aggLI.APTS_Sales_Org__c);
                agreementLIIdSet.add(aggLI.Id);
            }
            
            Map<Id,Apttus__AgreementLineItem__c> newAggLIMap = new Map<Id,Apttus__AgreementLineItem__c>([SELECT Id, Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_hours_per_month__c, Apttus_CMConfig__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Name, Apttus__AgreementId__r.APTS_PricingDate__c FROM Apttus__AgreementLineItem__c WHERE Id IN: agreementLIIdSet]);
           
            //Get All Average Service Cost Price Record for the Bundles && Sales Org in ALI
            for(APTS_AverageServiceCostPrice__c avgSCP: [SELECT Id, APTS_ASCP_BundleProduct__c, APTS_End_Date__c, APTS_Start_Date__c, APTS_ASCP_AllServCP__c, APTS_ASCP_BasServCP__c, APTS_ASCP_COCP__c, APTS_ASCP_FOCP__c, APTS_ASCP_Depreciation_Cost__c
                                                         FROM APTS_AverageServiceCostPrice__c
                                                         WHERE APTS_ASCP_BundleProduct__c IN: bundleProductsIdSet AND APTS_ASCP_SalesOrg__c IN: salesOrgSet]){
                if(avgServiceCostPriceMap.containsKey(avgSCP.APTS_ASCP_BundleProduct__c)) {
                    avgServiceCostPriceMap.get(avgSCP.APTS_ASCP_BundleProduct__c).add(avgSCP);
                }else {
                    avgServiceCostPriceMap.put(avgSCP.APTS_ASCP_BundleProduct__c, new List<APTS_AverageServiceCostPrice__c> {avgSCP});
                }
            }
            
                                                     
            for(Apttus__AgreementLineItem__c aggLI: (List<Apttus__AgreementLineItem__c>)agreementLIList){
                //Populate ALI Pricing Date
                if(newAggLIMap.containsKey(aggLI.id) && newAggLIMap.get(aggLI.id).Apttus__AgreementId__c != null)
                    aggLI.APTS_PricingDate__c = newAggLIMap.get(aggLI.id).Apttus__AgreementId__r.APTS_PricingDate__c;
                if(aggLI.APTS_ParentBundle__c != NULL && aggLI.Apttus__Description__c != NULL && aggLI.APTS_PricingDate__c != NULL && avgServiceCostPriceMap.containsKey(aggLI.Apttus__ProductId__c)){
                    for(APTS_AverageServiceCostPrice__c avgSCP: avgServiceCostPriceMap.get(aggLI.Apttus__ProductId__c)){
                        if(aggLI.APTS_PricingDate__c >= avgSCP.APTS_Start_Date__c && aggLI.APTS_PricingDate__c <= avgSCP.APTS_End_Date__c){
                            
                            if(aggLI.Apttus_CMConfig__LineType__c == 'Option' && newAggLIMap.containsKey(aggLI.Id)){
                                
                                //Check if Product Name CONTAINS "All" AND ("Coverage" OR "Service")
                                if('Technical Service'.equalsIgnoreCase(aggLI.APTS_Option_Group_Text__c) && aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_All_Value) && (aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Coverage_Value) || aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Service))){
                                    aggLI.APTS_Average_Service_Cost_Price__c = avgSCP.Id;
                                    aggLI.APTS_All_in_Service_Cost_Price__c = avgSCP.APTS_ASCP_AllServCP__c;
                                }
                                //Check if Product Name CONTAINS "Basic" AND ("Coverage" OR "Service")
                                if('Technical Service'.equalsIgnoreCase(aggLI.APTS_Option_Group_Text__c) && aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Basic_Value) && (aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Coverage_Value) || aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Service))){
                                    aggLI.APTS_Average_Service_Cost_Price__c = avgSCP.Id;
                                    aggLI.APTS_Basic_Service_Cost_Price__c = avgSCP.APTS_ASCP_BasServCP__c;
                                }
                                //Check if Product Name CONTAINS "Full" AND "Co" AND "Operating"
                                if('Machine Care'.equalsIgnoreCase(aggLI.APTS_Option_Group_Text__c) && newAggLIMap.get(aggLI.Id).Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_hours_per_month__c != null && 
                                    aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Full) && aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Operating) && aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Co)){
                                    aggLI.APTS_Average_Service_Cost_Price__c = avgSCP.Id;
                                    aggLI.APTS_Comfort_Operating_Cost_Price__c = avgSCP.APTS_ASCP_COCP__c * newAggLIMap.get(aggLI.Id).Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_hours_per_month__c;
                                }
                                //Check if Product Name CONTAINS "Full" AND "Operating" AND !CONTAIN "Co"
                                if('Machine Care'.equalsIgnoreCase(aggLI.APTS_Option_Group_Text__c) && newAggLIMap.get(aggLI.Id).Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_hours_per_month__c != null && 
                                    aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Full) && aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Operating) && !aggLI.Apttus__Description__c.containsIgnoreCase(Label.APTS_Co)){
                                    aggLI.APTS_Average_Service_Cost_Price__c = avgSCP.Id;
                                    aggLI.APTS_Full_Operating_Cost_Price__c = avgSCP.APTS_ASCP_FOCP__c * newAggLIMap.get(aggLI.Id).Apttus_CMConfig__AttributeValueId__r.APTS_Number_of_hours_per_month__c;
                                }
                            }
                            //Check if Bundle Primary Line
                            else if(aggLI.Apttus_CMConfig__LineType__c == 'Product/Service' && aggLI.Apttus_CMConfig__HasOptions__c == TRUE && aggLI.Apttus_CMConfig__IsPrimaryLine__c == TRUE){
                                aggLI.APTS_Depreciation_Cost__c = avgSCP.APTS_ASCP_Depreciation_Cost__c;
                                aggLI.APTS_Average_Service_Cost_Price__c = avgSCP.Id;
                            }
                            else{
                                aggLI.APTS_Average_Service_Cost_Price__c = null;
                                aggLI.APTS_All_in_Service_Cost_Price__c = null;
                                aggLI.APTS_Basic_Service_Cost_Price__c = null;
                                aggLI.APTS_Comfort_Operating_Cost_Price__c = null;
                                aggLI.APTS_Full_Operating_Cost_Price__c = null;
                                aggLI.APTS_Depreciation_Cost__c = null;
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', String.valueOf(e) ,'AgreementLineItem', null ,'CPQ',false,false,'cpqerror@accenture.com',false);
        }
        
    }

    //Added by Santosh
    /**The below code is for templates and will be done after 3.1
    public void updateaggfield(List<SObject> objList) {

        Set<Id> aggIdset = new Set<Id>();
        Set<Id> catgryIdset = new Set<Id>();
        List<Apttus__AgreementLineItem__c> newAggLIlist = new List<Apttus__AgreementLineItem__c>();
        Map<Id, Apttus__APTS_Agreement__c> aggMaptUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<Id, Apttus_Config2__ClassificationHierarchy__c> catghierarchymap = new Map<Id, Apttus_Config2__ClassificationHierarchy__c>();
        Map<Id, String> agglivscatnamemap = new Map<Id, String>();
        
        for(Apttus__AgreementLineItem__c oALI : (List<Apttus__AgreementLineItem__c>)objList) {
            aggIdset.add(oALI.Apttus__AgreementId__c);
            if(oALI.Apttus_CMConfig__ClassificationId__c != null) {
                catgryIdset.add(oALI.Apttus_CMConfig__ClassificationId__c);
            }
        }

        if(!aggIdset.isEmpty()) {
            for(Apttus__APTS_Agreement__c oAgg : [select id,APTS_AgreementLIRelatedListDetails__c from Apttus__APTS_Agreement__c where id IN: aggIdset]) {
                if(!APTS_CheckRecursive.processedSet.contains(string.valueOf(oAgg.id))){//Added by jason.e.mactal | 9.26.2018
                    oAgg.APTS_AgreementLIRelatedListDetails__c = '';
                    aggMaptUpdate.put(oAgg.Id, oAgg);
                    APTS_CheckRecursive.processedSet.add(string.valueOf(oAgg.id));
                }
            }
        }
       
        if(!catgryIdset.isEmpty()) {
            for(Apttus_Config2__ClassificationHierarchy__c ocathier : [select id,name,Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c where id in: catgryIdset]) {
                catghierarchymap.put(ocathier.Id,ocathier);
            }
        }
        
        for(Apttus__AgreementLineItem__c oALI : (List<Apttus__AgreementLineItem__c>)newAggLIlist) {
            if(catghierarchymap.containsKey(oALI.Apttus_CMConfig__ClassificationId__c)) {
                agglivscatnamemap.put(oALI.Id, catghierarchymap.get(oALI.Apttus_CMConfig__ClassificationId__c).Name);
            }
        }
       

        aggMaptUpdate = prepareAggMap(newAggLIlist, aggMaptUpdate, agglivscatnamemap); 

        
        if(!aggMaptUpdate.isEmpty()) {
            try{
                update aggMaptUpdate.values();  
            } catch(Exception e){
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', String.valueOf(e) ,'AgreementLineItem', null ,'CPQ',false,false,'cpqerror@accenture.com',false);
            }
           
        }
    } **/

    //Added by Santosh
    /**The below code is for templates and will be done after 3.1
    public static Map<Id, Apttus__APTS_Agreement__c> prepareAggMap(List<SObject> newList, Map<Id, Apttus__APTS_Agreement__c> aggMap, Map<Id, String> agglicatnamemap) {

        for(Apttus__AgreementLineItem__c oALI : (List<Apttus__AgreementLineItem__c>)newList) {
            List<String> catgrylist = new List<String>();
            if(oALI.Apttus_CMConfig__ClassificationHierarchy__c!=null && oALI.Apttus_CMConfig__ClassificationHierarchy__c.contains('|')) catgrylist = oALI.Apttus_CMConfig__ClassificationHierarchy__c.split('\\|');
           
            
            if(agglicatnamemap.containsKey(oALI.Id)) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, agglicatnamemap.get(oALI.Id)+'||');

            if((agglicatnamemap.containsKey(oALI.Id) && (agglicatnamemap.get(oALI.Id) == 'Machine') || (agglicatnamemap.get(oALI.Id) == 'Service')||(agglicatnamemap.get(oALI.Id) == 'Spare Parts')||(agglicatnamemap.get(oALI.Id) == 'Coffee Kitchen')||(oALI.Offering__c == 'Machines')||(oALI.Apttus_CMConfig__LineType__c.containsIgnoreCase('Service')))&&oALI.APTS_Type_of_Contract__c == 'Rent') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'MacSerSpareCoffKitchen||');
            
            if(agglicatnamemap.containsKey(oALI.Id)) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Product||');
            
            if(oALI.Apttus_CMConfig__ClassificationHierarchy__c == 'Concepts | Coffee Kitchen') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Concepts | Coffee Kitchen||');
            
            if(oALI.APTS_Type_of_Contract__c != null && oALI.APTS_Type_of_Contract__c != '') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, oALI.APTS_Type_of_Contract__c+'||');

            if(oALI.APTS_Seasonal_Contract__c == 'yes') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'SeasonalContract||');
            
            if((oALI.Apttus__Description__c!=null && oALI.Apttus__Description__c.containsIgnoreCase('Training')) || (oALI.Apttus_CMConfig__ClassificationHierarchy__c!=null && oALI.Apttus_CMConfig__ClassificationHierarchy__c.containsIgnoreCase('Training'))) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Training||');
            
            if(oALI.Apttus__Description__c!=null) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, oALI.Apttus__Description__c+'||');           
            
            if(oALI.Apttus__Description__c!=null && oALI.Apttus__Description__c.containsIgnoreCase('Full Operating')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Full Operating||');
            
            if(oALI.Apttus__Description__c!=null && oALI.Apttus__Description__c.containsIgnoreCase('Full Operating') && agglicatnamemap.containsKey(oALI.Id) && agglicatnamemap.get(oALI.Id) == 'Connectivity System') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'FullOperatingConnectsystem||');
            
            if(oALI.Apttus__Description__c!=null && (oALI.Apttus__Description__c.containsIgnoreCase('Full Operating')||oALI.Apttus__Description__c.containsIgnoreCase('Connectivity'))) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'FullOperatingConnectsystem||');
            
            if(oALI.Apttus__Description__c!=null && oALI.Apttus__Description__c.containsIgnoreCase('cafitesse') && !catgrylist.isEmpty() && catgrylist.size()>=2 && catgrylist[0].trim() == 'coffee' && catgrylist[1].trim() == 'liquid') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'CoffeeliquidCafitesse||');

            if(!catgrylist.isEmpty() && catgrylist.size()>1) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, catgrylist[0].trim()+'||');    

            if(!catgrylist.isEmpty() && catgrylist.size()>1) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'SubCategory:'+catgrylist[1].trim()+'||');

            if(!catgrylist.isEmpty() && catgrylist[0].containsIgnoreCase('Machines') ) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Machines||');
            
            if(!catgrylist.isEmpty() && catgrylist.size()>1 && catgrylist[0].trim() == 'Machines') aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Machine:'+catgrylist[1].trim()+'||');    
            
            if(!catgrylist.isEmpty() && catgrylist.size()>1 && (catgrylist[1].containsIgnoreCase('Yearly value added service') || catgrylist[1].containsIgnoreCase('value added services'))) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'YearlyVAS||');    
            
            if(!catgrylist.isEmpty() && catgrylist.size()>1 && catgrylist[1].containsIgnoreCase('value added services')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'VAS||');    
            
            if(!catgrylist.isEmpty() && catgrylist.size()>1 && catgrylist[1].containsIgnoreCase('Additional services')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'AddService||');    
            
            if(!catgrylist.isEmpty() && catgrylist[0].containsIgnoreCase('Machines') && catgrylist[1].containsIgnoreCase('Liquid')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'MachineLiquid||');    
            
            if(!catgrylist.isEmpty() && !(catgrylist[0].containsIgnoreCase('Machines') || catgrylist[0].containsIgnoreCase('Concepts')) && !(catgrylist[1].containsIgnoreCase('Liquid') || catgrylist[1].containsIgnoreCase('Coffee Kitchen'))) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'NotMachLiqconkitchen||');    
            
            if((oALI.APTS_Type_of_Payment_System__c != '' || oALI.APTS_Type_of_Payment_System__c != null) && (oALI.APTS_Merchant__c == 'JDE & Customer') || (oALI.APTS_Merchant__c == 'JDE')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'PMJDEnJDECustomer||');
            
            if((oALI.APTS_Type_of_Payment_System__c != '' || oALI.APTS_Type_of_Payment_System__c != null) && (oALI.APTS_Merchant__c == 'JDE & Customer') || (oALI.APTS_Merchant__c == 'Customer')) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'PMCustomernJDECustomer||');
            
            if(oALI.APTS_Option_Group_Text__c !='' || oALI.APTS_Option_Group_Text__c !=null) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'OptionGroup:'+oALI.APTS_Option_Group_Text__c+'||');
            
            if(oALI.Apttus_CMConfig__AdjustmentType__c != null) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, oALI.Apttus_CMConfig__AdjustmentType__c+'||');
            
            if(oALI.APTS_Consumer_Price__c != null) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'ConsumerPrice||');

            if(oALI.Apttus_CMConfig__NetAdjustmentPercent__c != 0 && (oALI.APTS_Bundle_Option__c || oALI.APTS_Ingredient_Standalone__c || oALI.APTS_More_Standalone__c)) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, '% Ingredient Discount||');

            if(oALI.Apttus_CMConfig__NetAdjustmentPercent__c != 0 && oALI.APTS_Machine_Bundle__c) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, '% Machine Discount||');

            if(oALI.APTS_Net_Adjustment_Amount_2_decimals__c != 0 && (oALI.APTS_Bundle_Option__c || oALI.APTS_Ingredient_Standalone__c || oALI.APTS_More_Standalone__c)) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Ingredient Discount||');

            if(oALI.APTS_Net_Adjustment_Amount_2_decimals__c != 0 && oALI.APTS_Machine_Bundle__c) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Machine Discounts||');

            if(oALI.APTS_Bundle_Option__c || oALI.APTS_Ingredient_Standalone__c || oALI.APTS_More_Standalone__c) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Ingredient Present||');

            if(oALI.APTS_Machine_Bundle__c) aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'Machine Present||');
            
            if(String.IsNotBlank(oALI.Apttus__Description__c)
                && ((String.IsNotBlank(oALI.APTS_Option_Group_Text__c) 
                && oALI.APTS_Option_Group_Text__c.containsIgnoreCase('Connectivity System') 
                && oALI.Apttus__Description__c.containsIgnoreCase('Full Co Operating'))
                || oALI.Apttus__Description__c.containsIgnoreCase('Full Operating') 
                || oALI.Apttus__Description__c.containsIgnoreCase('Semi Operating') 
                || oALI.Apttus__Description__c.containsIgnoreCase('Reporting Service'))) {
                aggMap = getAggMap(aggMap, oALI.Apttus__AgreementId__c, 'ReportingRequired');
            }

        }
        return aggMap;
    }**/
    
    //Added by Santosh
    /**The below code is for templates and will be done after 3.1
    public static Map<Id, Apttus__APTS_Agreement__c> getAggMap(Map<Id, Apttus__APTS_Agreement__c> newAggMap, Id aggid, String rellistdata) {
        if(newAggMap.containsKey(aggId) && newAggMap.get(aggId) != null){
            Apttus__APTS_Agreement__c aggmt = newAggMap.get(aggid);
            if(rellistdata == 'ReportingRequired'){
                aggmt.APTS_reporting_required__c = true;
            }
            if(rellistdata != 'ReportingRequired'){
                if(aggmt.APTS_AgreementLIRelatedListDetails__c == null || aggmt.APTS_AgreementLIRelatedListDetails__c == '') {
                    aggmt.APTS_AgreementLIRelatedListDetails__c = rellistdata;
                }else if(!aggmt.APTS_AgreementLIRelatedListDetails__c.containsIgnoreCase(rellistdata)) {
                    aggmt.APTS_AgreementLIRelatedListDetails__c += rellistdata;
                }
            }
            newAggMap.put(aggmt.Id, aggmt);
        }
        return newAggMap;
    }**/
}