//-------------------------------------------------------------------------------------------//
// Author       :   Abram Vixen Reyes
// Created Date :   March 18, 2020
// Usage        :   Base class with all logic that can be called asynchronously
//-------------------------------------------------------------------------------------------//
public without sharing class TS_QueueableProcesses implements Queueable, Database.AllowsCallouts{
    
    public static Boolean hasException = false;

    //VARIABLE FOR CANCEL CASE, WORKORDER, WOLI
    public Boolean METHOD_CANCELOPENWFTASKS = false;          
    public Boolean METHOD_CANCELOPENCASE_S41 =  false;    
    public Boolean METHOD_CANCELOPENWO_S41 =  false;          
    public Boolean METHOD_CANCELOPENTASK_S41 =  false;      
    public Boolean METHOD_CANCELCONTRACTORDER_S41 =  false;
    public Map<String, String> woliReferenceMap = new Map<String, String>();
    public List<String> assetIds = new List<String>();
    public Set<String> caseWoli = new Set<String>();
                  
    //VARIABLE FOR COMPLETED WITH SAP05
    public Boolean METHOD_EVALUATE_COMPLETED_SAP05 = false;
    public Set<String> paSet  = new Set<String>();
    public List<String> woliList = new List<String>();
    public Map<Id, WorkOrderLineItem> extWoliNewMap = new Map<Id, WorkOrderLineItem>();
    
    //VARIABLE FOR UPDATESEQUENCE_ACTUALDURATION
    public Boolean METHOD_UPDATESEQUENCE_ACTUALDURATION = false;
    public Set<String> comboSet = new Set<String>();
    public Map<WorkOrder, List<WorkOrderLineItem>> map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>();
    public List<WorkOrderLineItem> finalWolitoInsertList = new List<WorkOrderLineItem>();
    public List<WorkOrder> wotoInsertList = new List<WorkOrder>();
    public Date runDate;
    public Date taskDate;
    
    //VARIABLE FOR INSERT_DELETE_PERMSET
    public Boolean METHOD_3PO_PERMISSIONSET =  false; //DOO-5217 Karen Hung to insert or delete permission set assignment
    public List<String> forSchedPerm = new List<String>();
    public List<String> forPermRemoval = new List<String>();
    
    //VARIABLE FOR MISSINGPARTS_SALESORDER
    public Boolean METHOD_MISSINGPARTS_SALESORDER = false;
    public Set<String> woliSet_missingParts  = new Set<String>();
    
    //VARIABLE FOR AUTHORIZED FIELDS UPDATE
    public Boolean METHOD_UPDATE_ORDERLINEITEM_AUTHORIZED = false;
    public List<Apttus_Config2__OrderLineItem__c> orderLineList = new List<Apttus_Config2__OrderLineItem__c>();

    public class TS_QueueableProcessesException extends Exception {}

    public void execute(QueueableContext context) {
        
        CustomLogging.push('execute', 'TS_QueueableProcesses');

        try {
            
            //CALL ALL METHODS HERE WITH IF CONDITION AS SWITCH
            if(METHOD_CANCELOPENWFTASKS) CANCELOPENCASE(assetIds, caseWoli);
            if(METHOD_CANCELCONTRACTORDER_S41) CANCELOPENCASE(assetIds, caseWoli);
            if(METHOD_CANCELOPENTASK_S41) CANCELOPENWOLI();                     
            if(METHOD_EVALUATE_COMPLETED_SAP05) EVALUATE_COMPLETED_SAP05(paSet, woliList, extWoliNewMap);            
            if(METHOD_UPDATESEQUENCE_ACTUALDURATION) UPDATESEQUENCE_ACTUALDURATION();
            if(METHOD_MISSINGPARTS_SALESORDER) MISSINGPARTS_SALESORDER();
            if(METHOD_UPDATE_ORDERLINEITEM_AUTHORIZED) UPDATE_ORDERLINEITEM_AUTHORIZED();
            if(METHOD_3PO_PERMISSIONSET)INSERT_DELETE_PERMSET(forSchedPerm,forPermRemoval);
            

        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
        }

        CustomLogging.pop();
    }
    
    public void CANCELOPENCASE(List<String> assetIds, Set<String> caseWoli){
        CustomLogging.push('CANCELOPENCASE', 'TS_QueueableProcesses');
        try{             
            List<Case> casetoUpdate = new List<Case>();
            Set<String> excludedStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};  
            Set<String> excludedWOType = new Set<String>{TS_Constants.WO_TYPE_S21_COUNTERREADING, TS_Constants.TYPE_S25_ROUTESALES, TS_Constants.ORDER_INSTYPE_MOVEMENT};   

            //Karen Hung DOO-3886 Feb 20,2020 to exclude case of the woli in cancelation
            if(METHOD_CANCELOPENWFTASKS == true){     
                if(!assetIds.isEmpty() && !caseWoli.isEmpty()){          
                    for(Case c :[SELECT Id FROM Case WHERE SubType__c = :TS_Constants.TYPE_S32_WATERFILTER AND PhysicalAsset__c IN :assetIds AND Id NOT IN :caseWoli AND Status NOT IN (:TS_Constants.STATUS_CLOSED,:TS_Constants.STATUS_CANCELED)]){
                        c.Status = TS_Constants.STATUS_CANCELED;
                        c.CaseSubStatus__c = TS_Constants.STATUS_CANCELED;
                        c.CancelationReason__c = TS_Constants.WTS_PERFORMED; //WTS already performed.
                        casetoUpdate.add(c);        
                    }
                }
            }

            //Francis Allen Alindogan DOO-4800 09/24/2020            
            else if(METHOD_CANCELCONTRACTORDER_S41 == true){   
                if(!assetIds.isEmpty()){  
                    //GROUPED SINCE WE NEED TO GET THE ORIGINAL PHYSICAL ASSET FROM WOLI LEVEL, SINCE NOT ALL CASES HAVE PHYSICAL ASSET 
                    for(AggregateResult agr : [SELECT Case__r.Id caseId, PhysicalAsset__c paId
                                            FROM WorkOrderLineItem
                                            WHERE (Case__r.SubType__c =: TS_Constants.TYPE_S30_PREVMAINTENANCE OR Case__r.SubType__c =: TS_Constants.TYPE_S32_WATERFILTER)                                 
                                            AND Case__r.Status NOT IN (:TS_Constants.STATUS_CLOSED,:TS_Constants.STATUS_CANCELED)
                                            AND Case__r.SubType__c NOT IN:excludedWOType //EXCLUDE MOVEMENT
                                            AND PhysicalAsset__c IN: assetIds                                            
                                            GROUP BY Case__r.Id, PhysicalAsset__c
                                            ]){

                        String caseId = agr.get('caseId') != null ? (String) agr.get('caseId') : null;
                        String paId = agr.get('paId') != null ? (String) agr.get('paId') : null;
                        String cancelReason;
                                                
                        //GET THE JDELINEITEMNUMBER REFERENCE
                        if(paId != null && !woliReferenceMap.isEmpty() && woliReferenceMap.get(paId) != null){
                            cancelReason = TS_Constants.MACHINE_TO_BE_DEINSTALLED + ' (from '+ woliReferenceMap.get(paId) +').'; //Machine de-installed from jdelineitemnumber
                        }
                        else {
                            cancelReason = TS_Constants.MACHINE_TO_BE_DEINSTALLED ;
                        }
                        Case newCase = new Case(Id = caseId, Status = TS_Constants.STATUS_CANCELED, CaseSubStatus__c = TS_Constants.STATUS_CANCELED,CancelationReason__c = cancelReason);
                        casetoUpdate.add(newCase);                         
                                                
                    }
                }                   
            }
            
            //Francis Allen Alindogan DOO-4801 09/24/2020                        
            else if(METHOD_CANCELOPENCASE_S41 == true){
                Set<String> excludeCase = new Set<String>();
                Set<String> allCase = new Set<String>();
                Map<String, String> cancelReasonMap = new Map<String,String>();
                
                if(!caseWoli.isEmpty() && !assetIds.isEmpty()){                                                   
                    for(AggregateResult agr :[  SELECT COUNT(Id) counter, WorkOrderType__c woType, PhysicalAsset__c paId, Case__c cseId
                                                FROM WorkOrderLineItem
                                                WHERE Status NOT IN: excludedStatus                                                  
                                                AND WorkOrderType__c NOT IN: excludedWOType
                                                AND WorkOrderType__c != null
                                                AND Case__c IN: caseWoli               
                                                AND Case__r.Status NOT IN(:TS_Constants.STATUS_CLOSED,:TS_Constants.STATUS_CANCELED) 
                                                AND Case__r.SubType__c NOT IN:excludedWOType //EXCLUDE MOVEMENT
                                                AND Case__r.Type =: TS_Constants.CASE_TYPE_FIELDSERVICE
                                                GROUP BY WorkOrderType__c, Case__c, PhysicalAsset__c]){

                        Integer woliCount = agr.get('counter') != null ? (Integer)  agr.get('counter') : null;                            
                        String paId = agr.get('paId') != null ? (String) agr.get('paId') : null;
                        String woType = agr.get('woType') != null ? (String) agr.get('woType') : null;
                        String cseId = agr.get('cseId') != null ? (String) agr.get('cseId') : null;                                
                        
                        if(WoliCount != null && woType != null & cseId != null){                    
                            //EXCLUDE CASES THAT HAVE WOLI FROM OTHER PA, OR CASES THAT HAVE WOLI WITH NULL PA
                            if(!assetIds.contains(paId) || paId == null){
                                excludeCase.add(cseId);
                            }
                            allCase.add(cseId);
                                                                          
                            //GET THE JDELINEITEMNUMBER REFERENCE
                            if(paId != null && !woliReferenceMap.isEmpty() && woliReferenceMap.get(paId) != null){                        
                                String cancelReason;         
                                cancelReason = TS_Constants.MACHINE_DEINSTALLED + ' (from '+ woliReferenceMap.get(paId) +').'; //Machine de-installed from jdelineitemnumber
                                cancelReasonMap.put(cseId, cancelReason);
                            }                                                        
                        }                               
                    }
                    
                    //LOOP CASES                
                    for(Id cse : allCase){
                        //CHECK IF THERE ARE NO EXCLUDED CASE OR CASE IS NOT EXCLUDED
                        if(excludeCase.isEmpty() || !excludeCase.contains(cse)){
                            String cancelReason; 
                            if(!cancelReasonMap.isEmpty() && cancelReasonMap.get(cse) != null){
                                cancelReason = cancelReasonMap.get(cse);
                            }
                            else {
                                cancelReason = TS_Constants.MACHINE_DEINSTALLED;
                            }

                            Case newCase = new Case(Id = cse, Status = TS_Constants.STATUS_CANCELED, CaseSubStatus__c = TS_Constants.STATUS_CANCELED, CancelationReason__c = cancelReason);      
                            casetoUpdate.add(newCase);                          
                        }
                    }
                }       
            }
            
            if(!casetoUpdate.isEmpty()){
                update casetoUpdate;
            }
        
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_QueueableProcessesException('Force to throw an exception');
            }
            
        } catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());   
        }        
        CustomLogging.pop();
    }

    public void UPDATESEQUENCE_ACTUALDURATION(){
        CustomLogging.push('UPDATESEQUENCE_ACTUALDURATION', 'TS_QueueableProcesses');

        WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;
        WorkOrderLineItemTriggerHandler.isRouteOperating = true;

        try{
            
            /********************************************************************* */
            //PERFORM SEQUENCING
            /********************************************************************* */
            Map<String, List<DateTime>> completed2WeeksAgo = checkTwoWeeksAgo(comboSet);
            Map<String, List<DateTime>> completed4WeeksAgo = checkFourWeeksAgo(comboSet);   

            Map<String, List<String>> woComboListMap = new Map<String, List<String>>(); // WorkOrderId => List of assetId+type combo strings with history
            Map<String, String> dateComboComboMap = new Map<String,String>(); // StartDate + combo string => combo string
            Map<String, String> comboWoMap = new Map<String, String>(); //combo string => WorkOrderId to insert
            Map<String, List<WorkOrderLineItem>> comboWOLIMap = new Map<String, List<WorkOrderLineItem>>(); //combo string => list of WOLI to insert

            //Get historical woli data with the same asset and type from 2 weeks ago or 4 weeks ago for sequence reference
            for(String combo : comboSet ){
                if(completed2WeeksAgo.containsKey(combo)){
                    for(Integer i=0; i < completed2WeeksAgo.get(combo).size(); i++){
                        dateComboComboMap.put(String.valueOf(completed2WeeksAgo.get(combo)[i]) + combo, combo);    
                    }
                }else if(completed4WeeksAgo.containsKey(combo)){
                    for(Integer i=0; i < completed4WeeksAgo.get(combo).size(); i++){
                        dateComboComboMap.put(String.valueOf(completed4WeeksAgo.get(combo)[i]) + combo, combo);    
                    }
                }
            }

            for(WorkOrderLineItem finalWoli : finalWolitoInsertList){   
                
                String combo = finalWoli.PhysicalAsset__c + finalWoli.WorkOrderLineItemType__c;                           
                if(finalWoli.SLADate__c.date() == taskdate){
                    comboWoMap.put(combo, finalWoli.WorkOrderId);

                    if(comboWOLIMap.containsKey(combo)){
                        comboWOLIMap.get(combo).add(finalWoli);
                    }else{
                        comboWOLIMap.put(combo, new List<WorkOrderLineItem>{finalWoli});
                    }

                }
                
            }

            if(!dateComboComboMap.isEmpty()){
                
                //sort dateCombo from the Map
                List<String> dateComboString = new List<String>();
                dateComboString.addAll(dateComboComboMap.keySet());
                dateComboString.sort(); 
                
                for(String dateCombo : dateComboString){
                    
                    String combo = dateComboComboMap.get(dateCombo);

                    if(woComboListMap.containsKey(comboWoMap.get(combo))){
                        woComboListMap.get(comboWoMap.get(combo)).add(combo);
                    }else{
                        woComboListMap.put(comboWoMap.get(combo), new List<String>{combo});
                    }                                   
                } 

                //put mapping on asset+activitytype combo and sequence based on date
                Map<String, List<Integer>> comboSequenceMap = new Map<String, List<Integer>>();

                for(String workOrder : woComboListMap.keySet()){
                    Integer sequenceNumber = 1;
                    for(String comboString : woComboListMap.get(workOrder)){
                        if(comboWOLIMap.containsKey(comboString)){
                            Integer i = 0;
                            while(comboWOLIMap.get(comboString).size() > i && comboWOLIMap.get(comboString)[i].Sequence_Number__c != null){
                                i++;
                            }

                            if(comboWOLIMap.get(comboString).size() > i){
                                WorkOrderLineItem woli = comboWOLIMap.get(comboString)[i];
                                woli.Sequence_Number__c = sequenceNumber;
                                sequenceNumber++;
                            }                                        
                        }
                    }
                }
            }

            Database.SaveResult[] saveResults = Database.update(finalWolitoInsertList, false);
            INSERT_LOGGING(saveResults, 'WorkOrderLineItem Update');

            /********************************************************************* */
            //PERFORM ACTUAL DURATION CALCULATION HERE
            /********************************************************************* */
            //LIST OF WO-WOLI PAIRING
            Map<Id, List<WorkOrderLineItem>> map_wo_woli = new Map<Id, List<WorkOrderLineItem>>();
            for(WorkOrderLineItem wo_var : finalWolitoInsertList){
                if(map_wo_woli.containsKey(wo_var.WorkOrderId)){
                    map_wo_woli.get(wo_var.WorkOrderId).add(wo_var);
                } else {
                    map_wo_woli.put(wo_var.WorkOrderId, new List<WorkOrderLineItem>{wo_var});
                }
            }

            //GET ALL EXISTING WORKORDERLINEITEMS AND MERGE
            List<WorkOrder> list_postponedWO = new List<WorkOrder>();
            if(!map_wo_woliList.isEmpty()){
                for(WorkOrder wo_var : map_wo_woliList.keySet()){
                    if(map_wo_woli.containsKey(wo_var.Id)){
                        map_wo_woli.get(wo_var.Id).addAll(map_wo_woliList.get(wo_var));
                    }
                    list_postponedWO.add(wo_var);
                }
            }

            //GET ALL WORK ORDER RECORDS
            List<WorkOrder> list_final_wo = new List<WorkOrder>();
            list_final_wo.addAll(wotoInsertList);
            list_final_wo.addAll(list_postponedWO);
            Map<Id, WorkOrder> map_wo_final = new Map<Id, WorkOrder>(list_final_wo);

            //GET ALL SALES ORGANIZATION
            Set<String> salesOrg_set = new Set<String>();
            for(WorkOrder wo_var : list_final_wo){
                salesOrg_set.add(wo_var.SalesOrganization__c);
            }

            //GET ALL PRICEBOOKENTRY DETAILS
            Set<Id> pbEntry_set = new Set<Id>();
            Map<Id, PricebookEntry> map_id_pbEntry = new Map<Id, PricebookEntry>();
            Map<Id, Integer> map_countTasks = new Map<Id, Integer>();
            for(Id str : map_wo_woli.keySet()){
                for(WorkOrderLineItem woli_var : map_wo_woli.get(str)){
                    pbEntry_set.add(woli_var.PricebookEntryId);
                }
                
                map_countTasks.put(str, map_wo_woli.get(str).size());
            }

            if(!pbEntry_set.isEmpty()){
                map_id_pbEntry = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c, MeanTimeToOperateC__c, MeanTimeToOperateLM__c, MeanTimeToOperateSM__c
                                                                FROM PricebookEntry
                                                                WHERE Id IN: pbEntry_set AND Sales_Organization__c IN: salesOrg_set]);
            }

            //GET ALL CALL TYPE PER COUNTRY SETTING
            Map<String, Map<String, Decimal>> map_woType_country_mttoCallType = new Map<String, Map<String, Decimal>>();
            for(CountrySetting__c cs_var : [SELECT Id, WorkOrderType__c, Country__c, Mean_Time_To_Operate__c FROM CountrySetting__c WHERE RecordType.Name = 'Mean Time To Operate per Call Type' AND Active__c = true]){
                if(map_woType_country_mttoCallType.containsKey(cs_var.WorkOrderType__c)){
                    if(!map_woType_country_mttoCallType.get(cs_var.WorkOrderType__c).containsKey(cs_var.Country__c)){
                        map_woType_country_mttoCallType.get(cs_var.WorkOrderType__c).put(cs_var.Country__c, cs_var.Mean_Time_To_Operate__c);
                    }
                } else {
                    map_woType_country_mttoCallType.put(cs_var.WorkOrderType__c, new Map<String, Decimal>{cs_var.Country__c => cs_var.Mean_Time_To_Operate__c});
                }
            }

            //GET ROUTE AND ACCOUNT LOCATION DETAILS
            Map<Id, Route__c> map_routeMap = new Map<Id, Route__c>();
            if(!list_final_wo.isEmpty()){

                //GET ALL ROUTE IDS
                Set<Id> set_routeId = new Set<Id>();
                for(WorkOrder wo_var : list_final_wo){
                    set_routeId.add(wo_var.Route_Id__c);
                }

                //QUERY ACCOUNT LOCATION INFORMATION PER ROUTE
                if(!set_routeId.isEmpty()){
                    map_routeMap = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Account_Location__c, Account_Location__r.Apttus_Config2__AccountId__c, Account_Location__r.Mini_Sales_Organization__c, Account_Location__r.AverageRoutePrep__c, Account_Location__r.MTTTWithinSite__c, Account_Location__r.MTTOLocationSpecific__c FROM Route__c WHERE Id IN :set_routeId]);
                }
            }

            //CALCULATE PER ROUTE AND PUT IN WORKORDER
            List<WorkOrder> list_wo_update = new List<WorkOrder>();
            Map<String, String> set_task_types_map = new Map<String, String>{'Large' => 'LM', 'Small' => 'SM', 'Cups' => 'C'};
            for(Id wo_var : map_wo_woli.keySet()){
                
                WorkOrder wo_update = new WorkOrder();
                wo_update.Id = wo_var;

                Decimal totalMTTO = 0;
                Integer num_task = map_countTasks.get(wo_var);
                String routeId = map_wo_final.containsKey(wo_var) ? map_wo_final.get(wo_var).Route_Id__c : null;
                String salesOrg = map_wo_final.containsKey(wo_var) ? map_wo_final.get(wo_var).SalesOrganization__c : null;
                
                Decimal aveRoutePrep = 0;
                if(map_routeMap.containsKey(routeId)){
                    if(map_routeMap.get(routeId).Account_Location__r.AverageRoutePrep__c != null){
                        aveRoutePrep = map_routeMap.get(routeId).Account_Location__r.AverageRoutePrep__c;
                    }
                }

                Decimal mtttWithinSite = 0;
                if(map_routeMap.containsKey(routeId)){
                    if(map_routeMap.get(routeId).Account_Location__r.MTTTWithinSite__c != null){
                        mtttWithinSite = map_routeMap.get(routeId).Account_Location__r.MTTTWithinSite__c;
                    }
                }

                Decimal mtttoLocationSpecific = 0;
                if(map_routeMap.containsKey(routeId)){
                    if(map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c != null){
                        mtttoLocationSpecific = map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c != null ? map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c : 0;
                    }
                }
                
                Decimal calc_perTask = 0;

                for(WorkOrderLineItem woli_var :  map_wo_woli.get(wo_var)){
                    
                    Decimal perCallType = map_woType_country_mttoCallType.get('S20').get(salesOrg) != null ? map_woType_country_mttoCallType.get('S20').get(salesOrg) : 0 ;

                    //GET VALUE DEPENDS ON THE ACTIVITY TYPE
                    String api_var = 'MeanTimeToOperate' + set_task_types_map.get(woli_var.WorkOrderLineItemType__c) + '__c';

                    Decimal perPriceBook = 0;
                    if(set_task_types_map.get(woli_var.WorkOrderLineItemType__c) !=null && map_id_pbEntry.get(woli_var.PricebookEntryId).get(api_var) != null){
                        PricebookEntry pbe = map_id_pbEntry.get(woli_var.PricebookEntryId);
                        perPriceBook = Decimal.valueOf(String.valueOf(pbe.get(api_var))) != null ? Decimal.valueOf(String.valueOf(pbe.get(api_var))) : 0;
                    }

                    calc_perTask = calc_perTask + (perCallType + perPriceBook + mtttoLocationSpecific);

                }

                totalMTTO = calc_perTask + aveRoutePrep + ((num_task - 1) * mtttWithinSite);
                // wo_update.Actual_Duration__c = totalMTTO / 60; Karen Hung DOO-4886 Changed actual duration field to planned duration
                wo_update.Planned_Duration__c = totalMTTO / 60;
                list_wo_update.add(wo_update);
            }

            //UPDATE WORKORDER
            if(!list_wo_update.isEmpty()){
                Database.SaveResult[] saveResults_MTTO = Database.update(list_wo_update, false);
                INSERT_LOGGING(saveResults_MTTO, 'WorkOrder Update');
            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_QueueableProcessesException('Force to throw an exception');
            }
            
        } catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());   
        }
        
        CustomLogging.pop();
    }

    Map<String, List<DateTime>> checkTwoWeeksAgo (Set<String> comboSet){
        Map<String, List<DateTime>> tasksMap = new Map<String, List<DateTime>>();
        Date twoweeksAgo = runDate.addDays(-14);
        DateTime twoweeksAgoDT = DateTime.newInstance(twoweeksAgo.year(), twoweeksAgo.month(), twoweeksAgo.day(), 0, 0, 0);
        DateTime twoweeksAgoEndDT = DateTime.newInstance(twoweeksAgo.year(), twoweeksAgo.month(), twoweeksAgo.day(), 23, 59, 59);
        for(WorkOrderLineItem woli : [SELECT Id,PhysicalAsset__c,StartDate__c, EndDate__c, WorkOrderLineItemType__c FROM WorkOrderLineItem WHERE Status = 'Completed' AND EndDate__c >= :twoweeksAgoDT AND EndDate__c <= :twoweeksAgoEndDT AND WorkOrderType__c = 'S20' ORDER BY StartDate__c]){
            if(tasksMap.containsKey(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c) && comboSet.contains(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c)){
                tasksMap.get(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c).add(woli.StartDate__c);
            }else if(comboSet.contains(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c)){
                tasksMap.put(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c, new List<DateTime>{woli.StartDate__c});
            }
        }
        return tasksMap;
    }

    Map<String, List<DateTime>> checkFourWeeksAgo (Set<String> comboSet){
        Map<String, List<Datetime>> tasksMap = new Map<String, List<Datetime>>();
        Date fourweeksAgo = runDate.addDays(-28);
        DateTime fourweeksAgoDT = DateTime.newInstance(fourweeksAgo.year(), fourweeksAgo.month(), fourweeksAgo.day(), 0, 0, 0);
        DateTime fourweeksAgoEndDT = DateTime.newInstance(fourweeksAgo.year(), fourweeksAgo.month(), fourweeksAgo.day(), 23, 59, 59);
        for(WorkOrderLineItem woli : [SELECT Id,PhysicalAsset__c, StartDate__c,Status, EndDate__c, WorkOrderLineItemType__c FROM WorkOrderLineItem WHERE Status = 'Completed' AND EndDate__c >= :fourweeksAgoDT AND EndDate__c <= :fourweeksAgoEndDT AND WorkOrderType__c = 'S20' ORDER BY StartDate__c]){
            if(tasksMap.containsKey(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c) && comboSet.contains(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c)){
                tasksMap.get(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c).add(woli.StartDate__c);
            }else if(comboSet.contains(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c)){
                tasksMap.put(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c, new List<DateTime>{woli.StartDate__c});
            }
        }
        return tasksMap;
    }

    public void INSERT_LOGGING (List<Database.SaveResult> saveResultList, String description) {

        //Custom Logging for Database.Error
        Set<String> exception_List_batch = new Set<String>();

        /* Create error message to each Database.Error. */
        for (Database.SaveResult sr: saveResultList) {
            if (!sr.isSuccess()) {
                //Operation failed. Get error details               
                for(Database.Error err : sr.getErrors()) {
                    String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                    exception_List_batch.add(msg);
                }
            }
        }

        //Create custom log record per batch if there is an error.
        if(!exception_List_batch.isEmpty()){
            String mainMessage = '';

            for(String err : exception_List_batch){
                mainMessage = err + '\n';
            }

            //CREATE CUSTOM LOG
            Custom_Log__c log = new Custom_Log__c(
                StackTrace__c = 'Route Task Batch: ' + description,
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);    
            insert log;
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          August 04, 2020
    * @description   DOO-4650 Method to remove Waterfilter Suggestion
    * @revision(s)   
                    08/28/2020 Francis Allen Alindogan
                    Merged the previous logic for DOO-4650 with DOO-4675 and DOO-4676
                    DOO-4675 added functionality to remove Waterfilter Task from MCO
                    DOO-4676 added functionality to create Opportunity/Case                                        
    */
    public void EVALUATE_COMPLETED_SAP05(Set<String> paSet, List<String> woliList, Map<Id, WorkOrderLineItem> extWoliNewMap){
        CustomLogging.push('EVALUATE_COMPLETED_SAP05', 'TS_QueueableProcesses');        
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();   
        Map<Id,WorkOrderLineItem> woliMap = new Map<Id,WorkOrderLineItem>();        
        List<Case> caseToInsert = new List<Case>();
        Set<String> woliWithDeletion = new Set<String>();
        Set<String> excludedStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};                
        
        try{            
            if(!paSet.isEmpty() && !woliList.isEmpty()){
                for(WorkOrderLineItem woli :[SELECT Id,Replace_WTS__c,RetriggerClick__c,Waterfilter_Suggestion__c,Status,WorkOrderLineItemType__c,PhysicalAsset__c,PhysicalAsset__r.SalesOrganization__c,Case__r.ContactId,ParentworkOrderLineItemId,JDELineItemNumber__c
                                            FROM WorkOrderLineItem 
                                            WHERE
                                                (Replace_WTS__c = true                                      
                                            OR                                        
                                                (WorkOrderType__c =: TS_Constants.WO_TYPE_S20_MACHINECARE AND (WorkOrderLineItemType__c =: TS_Constants.ACTIVITY_WATERFILTER OR WorkOrderLineItemType__c like: '%W%')))             
                                            //GENERAL CRITERIA                  
                                            AND Status NOT IN: excludedStatus    
                                            AND PhysicalAsset__c IN :paSet 
                                            AND Id NOT IN :woliList]){
                                                woliMap.put(woli.Id, woli);
                                            }
            }       
                                                            
            if(!woliMap.isEmpty()){                           
                for(Id key : woliMap.keySet()){                    
                    WorkOrderLineItem woli = woliMap.get(key);
                    Boolean forUpdate = false;                                                                                                             
                    //MCO WATERFILTER CANCEL             
                    if(woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_WATERFILTER){                            
                        woli.Status = TS_Constants.STATUS_CANCELED;                                
                        forUpdate = true;
                        if(!woliWithDeletion.contains(woli.PhysicalAsset__c)) {
                            woliWithDeletion.add(woli.PhysicalAsset__c);                          
                        }  
                    }                        
                    //MCO WATERFILTER REMOVAL                    
                    else if(woli.WorkOrderLineItemType__c != TS_Constants.ACTIVITY_WATERFILTER && woli.WorkOrderLineItemType__c.contains('W')){                            
                        woli.WorkOrderLineItemType__c = woli.WorkOrderLineItemType__c.replace('W','');
                        forUpdate = true;
                        if(!woliWithDeletion.contains(woli.PhysicalAsset__c)) {
                            woliWithDeletion.add(woli.PhysicalAsset__c);                          
                        }
                    }                            
                    //FOR WF SUGGESTION REMOVAL
                    if(woli.Replace_WTS__c == true){                        
                        woli.Replace_WTS__c = false;
                        woli.Waterfilter_Suggestion__c = null;
                        forUpdate = true;
                    }                                    
                    //GENERAL ACTION FOR WOLI
                    if(forUpdate == true){                        
                        woli.RetriggerClick__c = woli.RetriggerClick__c + 1;
                        woliToUpdate.add(woli);                
                    }      
                                        
                }                          
            }            
            
            for(String w : woliList){
                if(!extWoliNewMap.isEmpty() && extWoliNewMap.containsKey(w)){
                    WorkOrderLineItem extWOLI = extWoliNewMap.get(w);                                                            
                    if( extWOLI.PhysicalAsset__r.Machine_Care__c == TS_Constants.MACHINE_CLEAN_OPERATING && //DOO-4950 Francis Allen Alindogan
                        ( ( !woliWithDeletion.isEmpty() && !woliWithDeletion.contains(extWOLI.PhysicalAsset__c) ) || woliWithDeletion.isEmpty() )
                      ){                                                                                        
                            Case cse = new Case();                            
                            cse.Subject = Label.TS_CaseVerifyWFSubject;                            
                                                                                       
                            cse.Type = TS_Constants.CASE_TYPE_CUSTOMERCARE;
                            cse.SubType__c = TS_Constants.CASE_SUBTYPE_GENERICQUESTION;                         
                            cse.PhysicalAsset__c = extWOLI.PhysicalAsset__c;
                            cse.SalesOrganization__c = extWOLI.PhysicalAsset__r.SalesOrganization__c;
                            cse.ContactId = extWOLI.Case__r.ContactId;
                            cse.Default_Owner_by_Country_Setting__c = 'Queue';
                            cse.CaseQualificationDate__c = DateTime.now();                        
                            
                            if(!woliReferenceMap.isEmpty() && woliReferenceMap.get(extWOLI.PhysicalAsset__c) != null){
                                cse.Description = Label.TS_CaseVerifyWFDescription + ' (from '+ woliReferenceMap.get(extWOLI.PhysicalAsset__c) +').';    
                            }
                            else {
                                cse.Description = Label.TS_CaseVerifyWFDescription;    
                            }
                            caseToInsert.add(cse);                                   
                    }      
                }
            }
            if(!woliToUpdate.isEmpty()){
                update woliToUpdate;
            }

            if(!caseToInsert.isEmpty()){
                CaseTriggerHandler.IGNORE_CASEOWNER_CSETTING = true;
                insert caseToInsert;                
            }                                
            if (Test.isRunningTest() && hasException) {
                throw new TS_QueueableProcessesException('Force to throw an exception');
            }        
        } 
        catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
        }

        CustomLogging.pop();
    }

    //XEN REYES DOO-4721 August 3, 2020
    public void MISSINGPARTS_SALESORDER(){
        CustomLogging.push('MISSINGPARTS_SALESORDER', 'TS_QueueableProcesses');        
        
        try{
            
            List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();
            for(String varStr : woliSet_missingParts){
                integLogsList.add(new Integration_Log__c(Object_Id__c = varStr,
                                                  Object__c = INT_Constants.WOLI_MISSINGPARTS,
                                                  Integration_Status__c = INT_Constants.INITIAL,
                                                  Work_Order_Line_Item__c = varStr));
            }
            
            if(!integLogsList.isEmpty()){
                insert integLogsList;
            }
                    
            if (Test.isRunningTest() && hasException) {
                throw new TS_QueueableProcessesException('Force to throw an exception');
            }
        
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
        }

        CustomLogging.pop();
    }
    
    public void UPDATE_ORDERLINEITEM_AUTHORIZED(){
        CustomLogging.push('UPDATE_ORDERLINEITEM_AUTHORIZED', 'TS_QueueableProcesses');        
        
        try{
            
            if(!orderLineList.isEmpty()){
                update orderLineList;
            }
                    
            if (Test.isRunningTest() && hasException) {
                throw new TS_QueueableProcessesException('Force to throw an exception');
            }
        
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
        }

        CustomLogging.pop();
    }   

    /*
    * @author        Francis Allen Alindogan
    * @date          September 23, 2020
    * @description   Generic method to cancel WOLI
    * @revision(s)   
    */
    
    public void CANCELOPENWOLI(){
        CustomLogging.push('CANCELOPENWOLI', 'TS_QueueableProcesses');  
        List<WorkOrderLineItem> woliToCancelList = new List<WorkOrderLineItem>();   
        Map<String, Integer> workOrderWoliCntMap = new Map<String, Integer>();     
        Set<String> excludedStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};        
        Set<String> excludedWOType = new Set<String>{TS_Constants.WO_TYPE_S21_COUNTERREADING, TS_Constants.TYPE_S25_ROUTESALES, TS_Constants.ORDER_INSTYPE_MOVEMENT};
        Set<String> woliWOSet = new Set<String>();
        Set<String> woliCaseSet = new Set<String>();
        List<String> woliPAList = new List<String>();             
                              
        //Francis Allen Alindogan DOO-4801 09/24/2020                  
        if(METHOD_CANCELOPENTASK_S41 == true){            
            if(!caseWoli.isEmpty()){                
                //GET ALL PA FROM COMPLETED S41 WOLI SINCE NOT ALL CASE OR WO HAVE PA
                for(WorkOrderLineItem w :[  SELECT Id, PhysicalAsset__c
                                            FROM WorkOrderLineItem 
                                            WHERE Status =: TS_Constants.STATUS_COMPLETED
                                            AND WorkOrderType__c =: TS_Constants.ORDER_S41                                                                                                                                
                                            AND Case__c IN: caseWoli]){         
                    if(w.PhysicalAsset__c != null){
                        woliPAList.add(w.PhysicalAsset__c);                               
                    }                                                                      
                }                  
                //GET ALL RELATED WOLI
                for(WorkOrderLineItem w :[SELECT Id, Status, CancelationReason__c, WorkOrderId, Case__c, PhysicalAsset__c                            
                                            FROM WorkOrderLineItem 
                                            WHERE Status NOT IN: excludedStatus    
                                            AND WorkOrderType__c NOT IN:excludedWOType
                                            AND WorkOrderType__c != null
                                            AND PhysicalAsset__c IN :woliPAList 
                                            AND Case__r.SubType__c NOT IN:excludedWOType //EXCLUDE MOVEMENT
                                            AND Case__c NOT IN: caseWoli]){//EXCLUDE ORIGIN CASE

                    String cancelReason;
                    w.Status = TS_Constants.STATUS_CANCELED;        
                    
                    //GET THE JDELINEITEMNUMBER REFERENCE
                    if(w.PhysicalAsset__c != null && !woliReferenceMap.isEmpty() && woliReferenceMap.get(w.PhysicalAsset__c) != null){                        
                        cancelReason = TS_Constants.MACHINE_DEINSTALLED + ' (from '+ woliReferenceMap.get(w.PhysicalAsset__c) +').'; //Machine de-installed from jdelineitemnumber
                    }
                    else {
                        cancelReason = TS_Constants.MACHINE_DEINSTALLED;
                    }
                    w.CancelationReason__c = cancelReason;
                    woliToCancelList.add(w);  
                                           
                    if(w.WorkOrderId != null){
                        woliWOSet.add(w.WorkOrderId); //WORKORDER FOR CANCELLATION 
                    }

                    if(w.Case__c != null){
                        woliCaseSet.add(w.Case__c); //CASE FOR CANCELLATION       
                    }     
                }                
            }            
            if(!woliWOSet.isEmpty()){                
                METHOD_CANCELOPENWO_S41 = true;
                CANCELOPENWO(null, woliWOSet);
            }   

            if(!woliCaseSet.isEmpty()){                                           
                METHOD_CANCELOPENCASE_S41 = true;
                CANCELOPENCASE(woliPAList, woliCaseSet);  
            }   
        }

        if(!woliToCancelList.isEmpty() && woliToCancelList.size() > 0){
            try {
                update woliToCancelList;
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_QueueableProcessesException('Force to throw an exception');
                }
            }
            catch (Exception e){
                CustomLogging.debugException(e);
                CustomLogging.pop();
                System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
            }        
            CustomLogging.pop();                        
        }
    }
    

    /*
    * @author        Francis Allen Alindogan
    * @date          October 2, 2020
    * @description   Generic method to cancel WO
    * @revision(s)   
    */
    
    public void CANCELOPENWO(List<String> assetIds, Set<String> woIds){
        CustomLogging.push('CANCELOPENWO', 'TS_QueueableProcesses');  
        List<WorkOrder> woToCancelList = new List<WorkOrder>();   
        Set<String> excludedWoliStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};                           
       
        //Francis Allen Alindogan DOO-4801 10/02/2020                  
        if(METHOD_CANCELOPENWO_S41 == true){
            if(!woIds.isEmpty()){                                   
                //ITERATE WORKORDER BASED ON PA FROM WOLI AND EXCLUDE ORIGNAL CASE, WOLI WAS USED SINCE WE NEED TO COUNT ALL CHILD WOLI IDS                
                for(AggregateResult agr :[SELECT COUNT(Id) counter, WorkOrder.Id woId
                                    FROM WorkOrderLineItem
                                    WHERE WorkOrder.Status NOT IN: excludedWoliStatus                                                 
                                    AND WorkOrder.Id IN: woIds
                                    AND WorkOrderType__c =: TS_Constants.WO_TYPE_S20_MACHINECARE
                                    GROUP BY WorkOrder.Id, WorkOrder.Status
                                    ]){
                    
                    String woId = agr.get('woId') != null ? (String) agr.get('woId') : null;
                    Integer woliCount = agr.get('counter') != null ? (Integer)  agr.get('counter') : null;

                    if(woId != null && woliCount != null){                                                                                
                        //IF S20 WO HAS MORE THAN 1 WOLI, DONT CANCEL
                        if(woliCount > 1){
                            continue;
                        }                            
                        else{
                            WorkOrder tempWO = new WorkOrder(Id = woId, Status = TS_Constants.STATUS_CANCELED);                               
                            woToCancelList.add(tempWO);        
                        }      
                    }                                                             
                }                                
            }
        }

        if(!woToCancelList.isEmpty() && woToCancelList.size() > 0){
            try {
                update woToCancelList;
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_QueueableProcessesException('Force to throw an exception');
                }
            }
            catch (Exception e){
                CustomLogging.debugException(e);
                CustomLogging.pop();
                System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
            }        
            CustomLogging.pop();                        
        }
    }
    
     /*
    * @author        Karen Hung
    * @date          April 8, 2021
    * @description   DOO-5217  method to insert or delete permission set
    * @revision(s)   
    */    
    public void INSERT_DELETE_PERMSET(List<String> forSchedPerm,List<String> forPermRemoval){
        CustomLogging.push('INSERT_DELETE_PERMSET', 'TS_QueueableProcesses'); 
        if(!forSchedPerm.isEmpty() || !forPermRemoval.isEmpty()){
            try {
                
                String permissionSetId = '';
                
                for(PermissionSet pSet : [SELECT Id, Label, Name FROM PermissionSet WHERE Name ='JDE_3rd_Party_Enable_Operating_Schedule']){
                    permissionSetId = pSet.Id;    
                }
                
                system.debug(permissionSetId + 'permSet');
                //insert permission set assignment if applicable
                if(!forSchedPerm.isEmpty()){
                    List<PermissionSetAssignment> permtoInsert = new List<PermissionSetAssignment>();
                    
                    for(String str : forSchedPerm){
                        PermissionSetAssignment psa = new PermissionSetAssignment();
                        psa.PermissionSetId = permissionSetId;
                        psa.AssigneeId = str;
                        permtoInsert.add(psa);
                    }
                    
                    if(!permtoInsert.isEmpty()){
                        insert(permtoInsert);    
                    }
                    
                }
                
                //delete permission set assignment if applicable
                if(!forPermRemoval.isEmpty()){
                    List<PermissionSetAssignment> permtoDelete = new List<PermissionSetAssignment>(); 
                    permtoDelete = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :forPermRemoval AND PermissionSetId =:permissionSetId];
                    if(!permtoDelete.isEmpty()){
                        delete(permtoDelete);
                    }
                }
                
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_QueueableProcessesException('Force to throw an exception');
                }
                
            } catch (Exception e){
                //CustomLogging.debugException(e);
                //CustomLogging.pop();
                System.debug(e.getMessage() + '\n' + e.getStackTraceString()); 
            }             
        }
    	//CustomLogging.pop(); 
    }
    
}