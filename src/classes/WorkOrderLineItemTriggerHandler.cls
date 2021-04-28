/**
* @author        Paul Jarred Aguiling
* @date          3.17.2017           
* @description   Class responsible for the trigger business logic of Work Order Line Item object
* @revision(s)
* 4.4.2017    Kimiko Roberto: added createIntegrationLogs method and validateWorkOrderLineItem method to AfterInsert and AfterUpdate calls
* 4.7.2017    Rey Austral: added cloning of record in the after update calls
* 4.10.2017   Rey Austral: added new criteria for inserting integration log
* 4.10.2017   Kimiko Roberto: modified updateWorkOrderStatus method to fit new Status Flow criterias
* 5.05.2017   Rey Austral: add method that will convert base64 to attachments
* 5.16.2017   Rey Austral: Add createion of integration log in the after insert
* 5.17.2017   Rey Austral: Update the criteria that will trigger the interface
* 5.24.2017   Paul Aguiling: Update in updateWorkOrderStatus()
* 8.15.2017   Bas Hoeberigs: update I/o, CATS and Goodsmovement updates for inserts and update call.  
* 8.23.2017   Paul Aguiling: TSWS-279 Added caseClosure and getExtWoliMap methods
* 1.9.2017    Paul Aguiling: KTS-365 Added updateFirstRespCaseMilestones and indicateFirstTaskWOLI methods
* 2.27.2018   Paul Aguiling: KTS-1500 Added caseCancellation method
* 3.23.2018   Marvin Gatchalian: Enhancement: Moved TS_OpenAndCompletedWOLIonCase FLOW functionality in After Insert/Update/Delete
* 4.26.2018   Archi Delphinanto: Update the method validateWorkOrderLineItem for good movement as it is no generated (KTS-1704).
* 4.27.2018   Marvin Gatchalian: Added logic in validateWorkOrderLineItem for Disaster Recovery internal order intergration log creation.
* 6.1.2018    Paul Aguiling: KTS-1715 Added integration logic for service materials and required parts
* 6.25.2018   Paul Aguiling: KTS-1867 Updated integration logic by adding grouping indicator for potential roundtrip
* 8.3.2018    Paul Aguiling: KTS 1980 Added validateExecutingEngr()
* 9.11.2018   Karen Hung: KTS 2141 added filter in if condition
* 9.17.2018   Karen Hung:  commented out the createSignatureAttachments and generateWOsummary under after insert
* 4.29.2019   Ata: Changes to populate De-installation Authorization and Installation Authorization Dates on OrderLineitem
*/
public without sharing class WorkOrderLineItemTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = true;
    private static Map<Id, Group> QUEUES = null;
    public static Id tsWOLIRecordType = null;
    private static Boolean createIntegrationLogOnce = true;
    public static Boolean afterUpdateRunOnce = true;
    public static Boolean beforeUpdateRunOnce = true;
    private static Map<Id, WorkOrderLineItem> extWoliNewMap = null;
    private static Map<Id,List<WorkOrderLineItem>> childWoliNewMap = null;
    private static Boolean notifyServiceMaterial = false;
    private static Boolean notifyUsedParts = false;
    public static Boolean hasException = false;
    public static Boolean isDebugOk = false;
    private String CONST_WOLITASK_FIELDSET = TS_Constants.CONST_WOLITASK_FIELDSET;
    private String CONST_WOLI_OP_TASK_FIELDSET = TS_Constants.CONST_WOLI_OP_TASK_FIELDSET;
    private String CONST_WOLI_ROUTESALES_FIELDSET = TS_Constants.CONST_WOLI_ROUTESALES_FIELDSET;
    private static Integer beforeInsertTriggerTransactionSequence = 1;
    private static Integer afterInsertTriggerTransactionSequence = 1;
    private static Integer beforeUpdateTriggerTransactionSequence = 1;
    private static Integer afterUpdateTriggerTransactionSequence = 1;
    private static Integer genericTriggerTransactionSequence = 1;

    //XEN REYES 9.4.2018 KTS-2140
    public static Boolean integBillingTriggered = false;
    public static Boolean integCATSTriggered = false;
    public static Boolean integIOTriggered = false;
    public static Boolean integMissingPartTriggered = false; //Karen Hung DOO-4861

    public static Boolean counterReadingTriggered = false; //XEN REYES Oct.3.018 KTS-2232
    public static Boolean isNotBatchExecution = true; //XEN REYES Nov. 13, 2018 - Method muting static variable for batches (Waterfilter, Prev. Maintenance)
    public static Boolean isAttachPDFBatch = false; //XEN REYES Jan. 9, 2019 - To isolate ATTACH PDF Batch

    //ALM 6243 XEN REYES March 26, 2019
    public static List<WorkOrderLineItem> TO_REPARENT_COUNTERREADINGS_LIST = new List<WorkOrderLineItem>();
    public static Map<Id, List<WorkOrderLineItem>> WORKORDER_COUNTEREADING_MAP = new Map<Id, List<WorkOrderLineItem>>();
    public static Boolean COUNTERREADING_RUNONCE = false;

    public static Boolean LARGE_INSERT_MUTE = false; //ALM 6909 Xen Reyes April 24, 2019
    public static Boolean IS_OPERATING_TASK = false; //DOO - Xen Reyes May 8, 2019
    public static Boolean INTEGRATION_MUTE = false; //Xen Reyes May 8, 2019
    public static Map<Id, Boolean> HAS_CHANGES_MAP = new  Map<Id, Boolean>(); //Xen Reyes May 13, 2019
    public static Boolean IS_RETURN_NEEDED = false; //Xen Reyes June 26, 2019
        
    //XEN REYES August 21, 2019
    private static Boolean COMPLETED_THIRDPARTY = false;
    public static Map<String, CountrySetting__c> COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP = new Map<String, CountrySetting__c>();

    //XEN REYES January 30, 2020
    public static Boolean isRouteOperating = false;

    //Francis Allen Alindogan DOO-4256 03/17/2020
    public static Boolean isRSTaskFlushReady = false;

    //DOO-4743 XEN REYES
    public static Boolean FIXED_COST_DONE = false;
    
    //DOO-5035/DOO-4629 Karen Hung Nov 23, 2020
    public static Boolean serviceNotifProcessed = false;
    
    //Francis Allen Alindogan DOO-5315 02/24/2021
    public static Map<Id, String> THIRDPARTY_RESOURCE_MAP = new Map<Id, String>();

    //DOO-5307 Karen Hung 22/2/2021
    public static Boolean engineerAccessProcessed = false;
    public static Boolean reinitiateAccessEnabled = false;

    //Francis Allen Alindogan DOO-4795 09/09/2020
    public static Map<String, CountrySetting__c> COUNTRYSETTING_INTERNALORDERSAP_MAP = new Map<String, CountrySetting__c>();    
    
    //Francis Allen Alindogan DOO-4800 09/24/2020
    public static Map<String, CountrySetting__c> COUNTRYSETTING_CONTRACTTRIGGER_MAP = new Map<String, CountrySetting__c>();

    //Francis Allen Alindogan DOO-4921 10/01/2020
    public static Map<Id, Case> extCSEMap = new Map<Id, Case>();
    public static Map<Id,String> woliResponseMap = new Map<Id, String>();
    
    //Karen Hung 25/11/2020 DOO-5035
    public static String clickName = IntegrationUserAndProfile__c.getInstance().Click_Integration_Name__c;
    public static String clickUserId = IntegrationUserAndProfile__c.getInstance().ClickUserId__c; //DOO-5129 Karen Hung 5/12/2020
    public static List<Contact> dummyContacts = [SELECT Id FROM Contact WHERE Name = 'Dummy Contact ( DO NOT DELETE )' AND Recordtype.Name = :TS_Constants.TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT];
    public static Contact contactRec = dummyContacts.isEmpty() ? null : dummyContacts[0];
    
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Map<String, Boolean> enabledFeatureMap = new Map<String, Boolean>();

    /**
    * @author         Paul Jarred Aguiling
    * @date           12.01.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */
    public class TS_WoliTriggerHandlerException extends Exception {}

    public void BeforeInsert(List<SObject> newItems) {
        CustomLogging.push('BeforeInsert', 'WorkOrderLineItemTriggerHandler');
        //System.debug('WOLI Trigger Transaction Sequence, BeforeInsert: '+ beforeInsertTriggerTransactionSequence + ', Generic sequence: '+ genericTriggerTransactionSequence++);
        try {

            //May 15, 2019 XEN REYES
            POPULATE_ACCOUNTLOCATIONID(newItems, null);

            if(!LARGE_INSERT_MUTE && !IS_OPERATING_TASK){
                insertCaseOnChildWoli(newItems); //Chi (updated): some potential overlaping with operating task and counter reading 
                indicateFirstTaskWOLI(newItems);//Chi: no potential overlaping with operating task and counter reading --> filtered only for S10
                checkifScheduleManually(newItems);//Chi: no potential overlaping with operating task and counter reading --> filtered only for recordtypes of Register Task and add service job
                populateRecordtypeId(newItems); //Karen Hung 5.8.2020 DOO-4631

                if(isNotBatchExecution){
                    checkActiveWOLI(newItems); //XR KTS-1978 6.08.2018
                    populateProduct(newItems); //Francis Allen Alindogan DOO-4623 06.30.2020
                } 
            
                POPULATE_PREFERREDOPERATOR(newItems); //Karen Hung DOO-4273 16.03.2020
                setClickPriority(newItems);//Francis Allen Alindogan DOO-3907 03.05.2020                
            }

            if(!LARGE_INSERT_MUTE) flagWFSuggestion(newItems); //Karen Hung DOO-4529 21.07.2020

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        beforeInsertTriggerTransactionSequence++;
        genericTriggerTransactionSequence++;
        CustomLogging.pop();
    }

    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('BeforeUpdate', 'WorkOrderLineItemTriggerHandler');
        //System.debug('WOLI Trigger Transaction Sequence, BeforeUpdate: '+ beforeUpdateTriggerTransactionSequence + ', Generic sequence: '+ genericTriggerTransactionSequence++);

        try {
            
			if(!featureFlags.isEmpty() && enabledFeatureMap.isEmpty()){
            	for(TS_Feature_Flag__mdt flag : featureFlags.values()){
            	    enabledFeatureMap.put(flag.QualifiedApiName, flag.Enable__c);    
            	}
        	}

            if ((extWoliNewMap == null && newMapItems != null) || !extWoliNewMap.keySet().containsAll(newMapItems.keySet())) {
                extWoliNewMap = getExtWoliMap(newMapItems.keySet());
            }

            POPULATE_ACCOUNTLOCATIONID(newList, oldMapItems); //May 15, 2019 XEN REYES
            RETURN_NEEDED_MUTING(newList, oldMapItems); //June 24, 2019 XEN REYES
            //ADJUSTTIME_ROUTEOPERATING(newList, oldMapItems); //March 6, 2020 XEN REYES DOO-3894
            
            if(!LARGE_INSERT_MUTE){

                //To avoid recursion due to update being done by create integration log method
                if (beforeUpdateRunOnce) {
                    beforeUpdateRunOnce = false;
                }

                if(isNotBatchExecution && !IS_OPERATING_TASK){
                    SET_FIXED_COST_MATERIALS(newList, newMapItems, oldMapItems); //DOO-4743 XEN REYES
                    if(!FIXED_COST_DONE) EVALUATE_PARTS_WARRANTY(newList, oldMapItems); //DOO-4743 XEN REYES
                    rescheduleWorkOrderLineItems(newList, oldMapItems);///Chi: no potential overlaping with operating task and counter reading --> filtered by Reschedule__c
                    checkForReviewNeededCriteria(newList, oldMapItems); //XR 04.7.2018
                    rescheduleEngineerTaskUpdates(newList, oldMapItems); //XEN REYES 22.9.2018 KTS-2081
                    validateIfReviewNeededBefore(newList, oldMapItems); //XEN REYES Oct.8, 2018 Review Needed to Before Trigger Event
                    checkWTSPerformed(newList,oldMapItems,newMapItems);//Karen Hung DOO-2685 21.11.2019
                    calculateActualDuration(newList); //XEN REYES Oct. 11, 2018 KTS-2263
                    checkifScheduleManually(newList); //Added XEN REYES Feb 19, 2019 KTS-2627 KTS-2627
                    isThirdPartyCheck(newList);// Added by Ata for ThirdParty check                                 
                    setWorkTimeStamps(newList, oldMapItems); //Francis Allen Alindogan DOO-4621 07.01.2020       
                    checkIfThirdPartyResource(newList, null, oldMapItems);//DOO-5150 Francis Allen Alindogan 01/04/2020     
                }   

                //July 3, 2019 Xen Reyes DOO-596
                if(IS_RETURN_NEEDED){
                    calculateActualDuration(newList);
                    checkForReviewNeededCriteria(newList, oldMapItems);
                    validateIfReviewNeededBefore(newList, oldMapItems);
                    checkWTSPerformed(newList,oldMapItems,newMapItems);//Karen Hung DOO-2685 21.11.2019
                    //setClickPriority(newList);//Francis Allen Alindogan DOO-3907 03.05.2020         
                    checkIfThirdPartyResource(newList, null, oldMapItems);//DOO-5150 Francis Allen Alindogan 01/04/2020                        
                    //DOO-5116 Xen Reyes 4/1/2021
                    EVALUATE_PARTS_WARRANTY(newList, oldMapItems);                                      
                }
            }

            //ALM 6243 XEN REYES March 26, 2019
            if(!COUNTERREADING_RUNONCE && !IS_OPERATING_TASK) GET_LARGE_WITH_COUNTERREADING(newList, newMapItems);

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        beforeUpdateTriggerTransactionSequence++;
        genericTriggerTransactionSequence++;
        CustomLogging.pop();
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){

    }

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        CustomLogging.push('AfterInsert', 'WorkOrderLineItemTriggerHandler');
        //System.debug('WOLI Trigger Transaction Sequence, AfterInsert: '+ afterInsertTriggerTransactionSequence + ', Generic sequence: '+ genericTriggerTransactionSequence++);        

        if(!featureFlags.isEmpty() && enabledFeatureMap.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                enabledFeatureMap.put(flag.QualifiedApiName, flag.Enable__c);    
            }
        }

        // Can be reused to consolidate all case records to be updated coming from differecnt logic.
        List<Case> allRelatedCaseToBeUpdated = new List<Case>();

        //Please use the class below for any update related to Case and return the list of case to be Updated.
        TS_UpdateRelatedCase relatedCase = new TS_UpdateRelatedCase();
		Map<Id, String> INTERNALORDERSAP_MAP = new Map<Id, String>(); //Francis Allen Alindogan DOO-4795 09/09/2020
        Map<Id, String> JDELINEITEMNUMBER_MAP = POPULATE_JDELINEITEMNUMBER(newList); //May 13, 2019 - JDELineItemNumber__c
        GENERATE_WO_BILLING(newList); //XEN REYES 9.26.2018 //May 13, 2019 - Moved from try catch
        
        try {

            if(!LARGE_INSERT_MUTE){

                if ((extWoliNewMap == null && newMapItems != null) || !extWoliNewMap.keySet().containsAll(newMapItems.keySet())) {
                    extWoliNewMap = getExtWoliMap(newMapItems.keySet());
                }

                if(TS_UtilityClass.isSObjectAccessible(new String[]{'Case'}) || TS_UtilityClass.isSObjectAccessible(new String[]{'PhysicalAsset__c'})){
                    createIntegrationLogs(newList, null, newMapItems); // Chi: some  potential overlaping with operating task and counter reading
                }

                if(isNotBatchExecution && !IS_OPERATING_TASK){
                    WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
                    cc.caseCloseMethod(newList, null);//Chi: no potential overlaping with operating task and counter reading -->filtered by case not empty
                }
                
                //This class/function is the replacement for TS_OpenAndCompletedWOLIonCase FLOW
                if(!IS_OPERATING_TASK){
                    List<Case> caseToUpdate = relatedCase.actionsForInsertedWoli (newList, newMapItems); //Chi: no potential overlaping with operating task and counter reading --> filtered by recordtype register task
                    if (!caseToUpdate.isEmpty() && Schema.sObjectType.Case.isUpdateable()){
                        allRelatedCaseToBeUpdated.addAll(caseToUpdate);
                        update caseToUpdate;
                    }
                    INTERNALORDERSAP_MAP = POPULATE_INTERNALORDERSAP(newList); //Francis Allen Alindogan DOO-4795 09/09/2020
                    cancelS41Related(newList, null, JDELINEITEMNUMBER_MAP); //Francis Allen Alindogan DOO-4800 09/22/2020
                    checkIfThirdPartyResource(newList, newMapItems, null);//DOO-5150 Francis Allen Alindogan 01/04/2020        
                }
                
                if(enabledFeatureMap.containsKey('DOO_5307_Reinitiate_engineer_access') && enabledFeatureMap.get('DOO_5307_Reinitiate_engineer_access') && !engineerAccessProcessed){
                    reinitiateAccessEnabled = true;
                	//reinitiateEngineerAccess(newList);
                    WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
                    cc.provideEngineerAccessWithoutSharing(newList, null);
                } 
            }
    
            //UPDATE ANY FIELD ON THE CURRENT WOLI //Francis Allen Alindogan DOO-4795 09/10/2020
            AFTERINSERT_WOLI_UPDATE(newList, JDELINEITEMNUMBER_MAP, INTERNALORDERSAP_MAP, THIRDPARTY_RESOURCE_MAP);

            //ALM 6243 XEN REYES March 26, 2019
            if(!IS_OPERATING_TASK) REPARENT_COUNTERREADING(newList);

            //SET PCB ON ASSET TO FALSE Francis Allen Alindogan DOO-4624 10/30/2020
            OPCOUpdate(newList);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        afterInsertTriggerTransactionSequence++;
        genericTriggerTransactionSequence++;
        CustomLogging.pop();
    }

    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'WorkOrderLineItemTriggerHandler');
        
        //Please use the class below for any update related to Case and return the list of case to be Updated.
        TS_UpdateRelatedCase relatedCase = new TS_UpdateRelatedCase();
        
        try {     
                            
            //Should still be evaluated even if LARGE_INSERT_MUTE = true;
            if(isNotBatchExecution && !IS_OPERATING_TASK) updateOpCounterReadingWorkOrderStatus(newList, oldMapItems); //Karen Hung 10.11.2018
            
            if(!featureFlags.isEmpty() && enabledFeatureMap.isEmpty()){
                for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                	enabledFeatureMap.put(flag.QualifiedApiName, flag.Enable__c);    
                }
            }
            
            if(!LARGE_INSERT_MUTE){

                if (tsWOLIRecordType == null) {
                    tsWOLIRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_REGTASK);
                }

                //Insert method incvocation inside to avoid recursion
                if (afterUpdateRunOnce) {
                    afterUpdateRunOnce = false;
                    UPDATE_CLICKREADY(newList, oldMapItems); //May 13, 2019 - Update Click Ready
                }

                if(!IS_OPERATING_TASK){
                    if(TS_UtilityClass.isSObjectAccessible(new String[]{'Case'})){
                        updateCaseSLAs(newList, oldMapItems);
                    }
                }
                
                //DOO-5137 Dec 8,2020 Karen Hung DOO-5035 Karen Hung 23.11.2020
                if((enabledFeatureMap.containsKey('DOO_5035_TS_ServiceNotification') && enabledFeatureMap.get('DOO_5035_TS_ServiceNotification') && !serviceNotifProcessed) || Test.isRunningTest()){
                    serviceNotification(newList, newMapItems, oldMapItems);
                }
                
                if(isNotBatchExecution && !IS_OPERATING_TASK){
                    
                    createSignatureAttachments(newList, oldMapItems);///Chi: no potential overlaping with operating task and counter reading --> filtered by Signature__c and QuotingSignature__c
                    if(TS_UtilityClass.isSObjectAccessible(new String[]{'Case'})){
                        updateFirstRespCaseMilestones(newList, oldMapItems);///Chi: no potential overlaping with operating task and counter reading --> filtered byWorkOrderType__c
                        updateWorkOrderStatus(newList, oldMapItems);//Chi: no potential overlaping with operating task and counter reading --> filtered by record type register task
                    }
                    
                    //DOO-803 Karen Hung transferred from before update
                    WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
                    cc.caseCloseMethod(newList, oldMapItems);
                    cc.provideEngineerAccessWithoutSharing(newList, oldMapItems);

                    //caseCancellation(newList, oldMapItems);
                    updateLastRouteSalesDateAccountLocation(newList, oldMapItems); //XEN REYES KTS-2002
                    cancelOpenWFTasks(newList, oldMapItems); //Karen Hung 21.11.2019 DOO-2686
                    updatePAifMCOComplete(newList, oldMapItems, newMapItems); //Francis Allen Alindogan 04/14/2020 DOO-3910
                    createFollowUpActions(newList, oldMapItems); //Karen Hung 8.6.2020 DOO-4619
                    stampWTSParts(newList, oldMapItems, newMapItems); //Karen Hung 17/7/2020 DOO-4533
                    if(!integMissingPartTriggered) GENERATE_MISSINGPARTS_SALESORDER(oldMapItems, newList); //Karen Hung 1/9/2020 DOO-4861    
                    cancelS41Related(newList, oldMapItems, null); //Francis Allen Alindogan DOO-4800 09/22/2020                          

                    //This Class/function is the replacement for TS_OpenAndCompletedWOLIonCase FLOW
                    List<Case> caseToUpdate = relatedCase.actionsForUpdatedWoli(newList, oldMapItems);
                    if (!caseToUpdate.isEmpty() && Schema.sObjectType.Case.isUpdateable()) {
                        update caseToUpdate;
                    }
                    
                    //XEN REYES October 21, 2020 DOO - 4972
                    if((enabledFeatureMap.containsKey('DOO_4972_Enable_WOLI_Send_Email') && enabledFeatureMap.get('DOO_4972_Enable_WOLI_Send_Email')) || Test.isRunningTest()){
                    	SEND_EMAIL(newList, oldMapItems);    
                    }
                    
                }

                //Xen Reyes June 26, 2019
                if(IS_RETURN_NEEDED){
                    updateFirstRespCaseMilestones(newList, oldMapItems);

                    WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
                    cc.caseCloseMethod(newList, oldMapItems);

                    cancelOpenWFTasks(newList, oldMapItems); //Karen Hung 21.11.2019 DOO-2686
                    createFollowUpActions(newList, oldMapItems); //Karen Hung 8.6.2020 DOO-4619                    
                    createReturnTask(newList, oldMapItems); //Francis Allen Alindogan 10.6.2020 DOO-4616
                    stampWTSParts(newList, oldMapItems, newMapItems); //Karen Hung 17/7/2020 DOO-4533
                    if(!integMissingPartTriggered) GENERATE_MISSINGPARTS_SALESORDER(oldMapItems, newList); //Karen Hung 1/9/2020 DOO-4861  
                                           
                    if((enabledFeatureMap.containsKey('DOO_4972_Enable_WOLI_Send_Email') && enabledFeatureMap.get('DOO_4972_Enable_WOLI_Send_Email')) || Test.isRunningTest()){
                    	SEND_EMAIL(newList, oldMapItems);    
                    }
                }

                if(TS_UtilityClass.isSObjectAccessible(new String[]{'Case'}) || TS_UtilityClass.isSObjectAccessible(new String[]{'PhysicalAsset__c'})){
                    createIntegrationLogs(newList, oldMapItems, newMapItems);  //Chi: some potential oalierlaping with operating task and counter reading 
                }

                //DOO - 4743 Process builder to trigger: Fixed Costs and Warranty
                if(FIXED_COST_DONE) {
                    
                    updateWorkOrderStatus(newList, oldMapItems);

                    //DOO-4967 XEN REYES
                    WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing cc = new WorkOrderLineItemTriggerHandler.woliTriggerHandlerClassWithoutSharing();
                    cc.provideEngineerAccessWithoutSharing(newList, oldMapItems);
                    
                    //DOO-5137 Dec 8,2020 Karen Hung DOO-5035 Karen Hung 23.11.2020
                    if((enabledFeatureMap.containsKey('DOO_5035_TS_ServiceNotification') && enabledFeatureMap.get('DOO_5035_TS_ServiceNotification') && !serviceNotifProcessed) || Test.isRunningTest()){
                        serviceNotification(newList, newMapItems, oldMapItems);
                    }
                }

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                }
   
            }

        } catch(Exception ex) {

            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug('WOLI TRIGGER AFTER UPDATE ERRROR'+ ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        afterUpdateTriggerTransactionSequence++;
        genericTriggerTransactionSequence++;
        CustomLogging.pop();
    }

    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterDelete', 'WorkOrderLineItemTriggerHandler');

        //Please use the class below for any update related to Case and return the list of case to be Updated.
        TS_UpdateRelatedCase relatedCase = new TS_UpdateRelatedCase();

        try {

            if(!LARGE_INSERT_MUTE && !IS_OPERATING_TASK){
                //This Class/function is the replacement for TS_OpenAndCompletedWOLIonCase FLOW
                List<Case> caseToUpdate = relatedCase.actionsForDeletedWoli (oldList, oldMapItems);//(updated) chi: potential issue for operating task, counter reading and routesales
                if (!caseToUpdate.isEmpty() && Schema.sObjectType.Case.isUpdateable())
                    update caseToUpdate;

                //updateOpenCompletedWOLIs(oldList);
            }

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }

    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){

    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          5.15.2017           
    * @description   Method responsible in disabling the function of the trigger if user settings is false
    * @revision(s)
    */
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().WorkOrderLineItemTrigger__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /**
    * @author        Ata
    * @date          4.16.2019
    * @description   Method responsible for checking if the Engineer assigned to a WOLI is an active TS_Resource/Third Part Engineer
    * @revision(s)
    */
    public void isThirdPartyCheck(List<WorkOrderLineItem> newList){
        List<Id> engineersList = new List<Id>();
        if(newList != null && newList.size() > 0) {
            for (Workorderlineitem woli : newList) {
                if (woli.ExecutingEngineer__c != null) {
                    engineersList.add(woli.ExecutingEngineer__c);
                }
            }

            String statusCode = TS_Constants.EMPSTAT_3;
            if (engineersList.size() > 0) {
                Map<Id, Resource__c> resourceMap = new Map<Id, Resource__c>([SELECT Id, UserProfile__c,ActiveUser__c,EmployeeStatus__c FROM Resource__c WHERE ID IN: engineersList 
                
                //DOO-4368 Xen Reyes April 28, 2020 - Removed additional criteria
                //AND ActiveUser__c = TRUE AND EmployeeStatus__c = :statusCode
                
                ]);

                if (resourceMap != null && resourceMap.KeySet().size() > 0) {
                    for (Workorderlineitem woli : newList) {
                        if (woli.ExecutingEngineer__c != null && resourceMap.get(woli.ExecutingEngineer__c) != null && (resourceMap.get(woli.ExecutingEngineer__c).UserProfile__c == TS_Constants.RESOURCE_USERPROFILE_THIRDPARTY ||
                                resourceMap.get(woli.ExecutingEngineer__c).UserProfile__c == TS_Constants.RESOURCE_USERPROFILE_TSRESOURCE)) {
                            woli.WorkingOnSFDC__c = true;
                        } else {
                            woli.WorkingOnSFDC__c = false;
                        }
                    }
                }
            }
        }
    }
    
    
    /**
    * @author        Paul Jarred Aguiling
    * @date          8.23.2017
    * @description   Method responsible for getting additional information on each work order line item (as by
    *                default fields on related records are not accessible). Kindly reuse the method when querying
    *                WOLI records for 2nd or 3rd level fields.
    * @revision(s)
    */
    public Map<Id, WorkOrderLineItem> getExtWoliMap(Set<Id> woliIds) {
        CustomLogging.push('getExtWoliMap', 'WorkOrderLineItemTriggerHandler');
        Map<Id, WorkOrderLineItem> extWoliMap = new Map<Id, WorkOrderLineItem>();

        //Only perform the following query if a set of IDs is provided
        if (woliIds != null && !woliIds.isEmpty()) {
            //This query is restrictive enough not to breach the governor limits
            extWoliMap = new Map<Id, WorkOrderLineItem>(
            [SELECT Id, Status,
                    WorkOrderLineItemType__c,
                    OrderLineItem__c,
                    OrderLineItem__r.Apttus_Config2__AssetLineItemId__c,
                    OrderLineItem__r.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__InitialActivationDate__c,
                    WorkOrderType__c,
                    EndDate__c,
                    IsLabour__c,
                    Case__c,                    
                    Case__r.AccountId, //Francis Allen Alindogan 06/21/2019 - DOO-466
                    Case__r.ContactId,
                    Case__r.ResponseProfile__c, //Francis Allen Alindogan 03/06/2020 DOO-3907
                    Case__r.SalesOrganization__c, //Francis Allen Alindogan 03/06/2020 DOO-3907
                    Case__r.SubType__c,
                    Case__r.TS_FirstRepsonseMilestoneautoclosed__c,
                    Case__r.Type,
                    Case__r.Click__c,
                    Case__r.RequiresCostEstimate__c,
                    Case__r.PhysicalAsset__c,
                    Case__r.Origin,
                    Case__r.AddRequiredPartsandMaterials__c,
                    Case__r.Priority,
                    Case__r.BusinessHoursId,
                    Case__r.Entitlement.ActualWorkingHours__c,
                    Case__r.ProductId,
            	    Case__r.Default_From_Address__c, //Karen Hung 23.11.2020 DOO-5035
             		Case__r.SendTo3rdParty__c, //Francis Allen Alindogan 02/27/2021 DOO-5298
                    ParentWorkOrderLineItem.AssetLineItem__c,
                    ParentWorkOrderLineItem.PhysicalAsset__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.SerialNumber__c,
                    ParentWorkOrderLineItem.EndDate__c,
                    ParentWorkOrderLineItem.WorkOrderType__c,
                    ParentWorkOrderLineItem.OrderHeaderSAPId__c, //XEN REYES April 17, 2019 - ALM 6841
                    AccountLocation__c,
                    ParentWorkOrderLineItemId,
                    ParentWorkOrderLineItem.Status,
                    ParentWorkOrderLineItem.InternalOrderSAP__c,
                    ParentWorkOrderLineItem.ExecutingEngineer__c,
                    ParentWorkOrderLineItem.ExecutingEngineer__r.SAPStorageLocation__c,
                    ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c, //XEN REYES August 21, 2019

                    //XEN REYES August 28, 2020
                    ParentWorkOrderLineItem.Case__c,
                    ParentWorkOrderLineItem.Case__r.PhysicalAsset__c,
                    ParentWorkOrderLineItem.Case__r.PhysicalAsset__r.AssetStatus__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.ActiveWarranty__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.CallOutChargeCoverage__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.SparePartCoverage__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.WaterfilterCoverage__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.FullOperatingCoverage__c,
                    ParentWorkOrderLineItem.PhysicalAsset__r.PreventiveMaintenanceCoverage__c,
             		ParentWorkOrderLineItem.PhysicalAsset__r.LabourChargeCoverage__c,
             
             		//DOO-5285 XEN REYES Feb 1, 2021
                    ParentWorkOrderLineItem.PhysicalAsset__r.EndDate__c,
             		ParentWorkOrderLineItem.PhysicalAsset__r.AssetStatus__c,

                    JDELineItemNumber__c,
                    ExecutingEngineer__c,
                    ExecutingEngineer__r.RelatedUser__c, //Francis Allen Alindogan 06/21/2019 - DOO-466
             	    ExecutingEngineer__r.EmailAddress__c, //Karen Hung 23.11.2020 DOO-5035
             	    ExecutingEngineer__r.UserProfile__c, //Karen Hung 23.11.2020 DOO-5035
             	    ExecutingEngineer__r.ActiveUser__c, //Karen Hung 23.11.2020 DOO-5035
                    PricebookEntryId,
                    Description,
                    Quantity,
                    Warranty__c,
                    TotalHours__c,
                    TS_I_O_IntegrationLogcreated__c,
                    TS_CATS_Integrationlog_created__c,
                    InternalOrderSAP__c,
                    ActualTravelTime__c,
                    WorkQuarters__c,
                    ClickReady__c,
                    LastModifiedBy.Name,
                    Signature__c,
                    QuotingSignature__c,
                    Attachment__c,
                    Attachment1__c,
                    Attachment2__c,
                    LineItemNumber,
                    Click_Integration_Status__c,
                    RelateTo__c,
                    RelateTo__r.ReturnNeeded__c,
                    IsReturnNeededTask__c,
                    AssetLineItem__c,
                    CreatedBy.Name,
                    WorkOrder.CaseId,
                    WorkOrder.Case.SalesOrganization__c,
                    WorkOrder.SalesOrganization__c,
                    WorkOrder.Pricebook2Id,
                    WorkOrderId,
                    WorkOrder.Third_Party__c, //Karen Hung 26/2/2021 DOO-5308
                    TSWOBillingIntegrationLogCreated__c,
                    OrderHeaderSAPId__c, //XEN REYES April 17, 2019 - ALM 6841
                    PhysicalAsset__c, //Francis Allen Alindogan 06/21/2019 - DOO-466
                    PhysicalAsset__r.ActiveWarranty__c, 
                    PhysicalAsset__r.AssetStatus__c,                     
                    PhysicalAsset__r.EndDate__c, 
                    PhysicalAsset__r.LabourChargeCoverage__c, 
                    PhysicalAsset__r.SalesOrganization__c,
                    PhysicalAsset__r.SparePartCoverage__c,
                    PhysicalAsset__r.PreventiveMaintenanceCoverage__c,                    
                    PhysicalAsset__r.ResponseTime__c,
                    PhysicalAsset__r.ResponseTimeS15__c,
                    PhysicalAsset__r.WarrantyEndDate__c,
                    PhysicalAsset__r.WaterfilterCoverage__c,
                    PhysicalAsset__r.Product__c,
                    PhysicalAsset__r.Machine_Care__c,

                    /* XEN REYES May 13, 2019 */
                    AccountLocation__r.Apttus_Config2__PostalCode__c,
                    AccountLocation__r.Shipping_Country_ISO__c,
                    AccountLocation__r.Shipping_Street_Only__c,
                    AccountLocation__r.Apttus_Config2__City__c,

                    //DOO-5150 Francis Allen Alindogan 01/04/2020
                    AccountLocation__r.Third_Party_Resource__c,

                    /* XEN REYES March 6, 2020 */
                    WorkOrder.RecordType.Name,
                    IsCoffeeRunning__c,
             		
             		/* XEN REYES October 21, 2020 */
             		Case__r.NoCaseClosureNotification__c           

            FROM WorkOrderLineItem
            WHERE Id IN :woliIds
            ]);
        }

        CustomLogging.pop();
        return extWoliMap;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          11.08.2017
    * @description   KTS 365 - Close First Response for Field Service Cases.
    *                Method responsible in indicating the first task (WOLI = register task record type).
    * @revision(s)
    */
    public void indicateFirstTaskWOLI(List<SObject> newList) {
        CustomLogging.push('indicateFirstTaskWOLI', 'WorkOrderLineItemTriggerHandler');
        List<Id> caseIds = new List<Id>();
        List<WorkOrderLineItem> newWoliList = new List<WorkOrderLineItem>();
        Map<Id, Id> woliCaseIds = new Map<Id, Id>();

        //Get case ids from woli being created (Activity type = task and type = corrective maintenance)
        /* FEB 27, 2019 - Include S15 first task indicator - XEN REYES - KTS-2640 */
        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
            if (woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                    && (woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI ||
                    woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)){
                caseIds.add(woli.Case__c);
                newWoliList.add(woli);
            }
        }

        //Retrieve cases with child wolis
        if (!caseIds.isEmpty()) {
            for (Case cse: [SELECT Id, (SELECT Id FROM WorkOrderLineItems__r
            WHERE WorkOrderLineItemType__c =: TS_Constants.TYPE_TASK
            AND (WorkOrderType__c =: TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI OR WorkOrderType__c =: TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)
            AND IsFirstTask__c = true)
            FROM Case
            WHERE Id IN: caseIds
            AND Type =: TS_Constants.CASE_TYPE_FIELDSERVICE]) { // 10/30/2019 for DOO-2638 - Francis Allen Alindogan
            //AND Type =: TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_DEFAULT]) {
                for (WorkOrderLineItem woli: cse.WorkOrderLineItems__r) {
                    woliCaseIds.put(cse.Id, woli.Id);
                    break;
                }
            }
        }

        //Set IsFirstTask__c field to true when no wolis found under case record
        for (WorkOrderLineItem woli: newWoliList) {
            if (woliCaseIds.get(woli.Case__c) == null) {
                woli.IsFirstTask__c = true;
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          11.08.2017
    * @description   KTS 365 - Close First Response for Field Service Cases.
    *                Method responsible in updating first response case milestones
    *                via completed first task (WOLI = register task record type).
    *
    * @revision(s)
    */
    public void updateFirstRespCaseMilestones(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('updateFirstRespCaseMilestones', 'WorkOrderLineItemTriggerHandler');
        Map<Id, WorkOrderLineItem> oldWoli = (Map<Id, WorkOrderLineItem>) oldMapItems;
        Map<Id, DateTime> caseWoliMap = new Map<Id, DateTime>();
        List<CaseMilestone> cseMilestoneList = new List<CaseMilestone>();
        Set<Id> checkUniqueCase = new Set<Id>();

        List<Case> cseList = new List<Case>();

        //Case__r.TS_FirstRepsonseMilestoneautoclosed__c

        //Add case id of wolis with activity type = task, work order type = corrective maintenance, and status = completed
        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
            if (woli.Status != oldWoli.get(woli.Id).Status
                    && woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                    && woli.Status == TS_Constants.STATUS_COMPLETED
                    && woli.IsFirstTask__c
                    && woli.Created_Manually__c
                    && (woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI
                    || woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI )) {

                if (checkUniqueCase.add(woli.Case__c))
                    caseWoliMap.put(woli.Case__c, woli.StartDate__c);
                Case cse = new Case(Id=woli.Case__c); //added by Bas
                cse.TS_FirstRepsonseMilestoneautoclosed__c = TRUE; //added by Bas
                cseList.add(cse);//added by Bas
            }
        }

        //Collect list of related first response case milestones then update completion date using woli actual start date
        if (!caseWoliMap.isEmpty() && caseWoliMap.keySet() != null) {
            for (CaseMilestone cseMilestone: [SELECT CompletionDate, CaseId FROM CaseMilestone
            WHERE MilestoneType.Name =: TS_Constants.FIRST_RESPONSE
            AND IsCompleted = false
            AND CaseId IN: caseWoliMap.keySet()]) {
                cseMilestone.CompletionDate = caseWoliMap.get(cseMilestone.CaseId);
                cseMilestoneList.add(cseMilestone);
            }
        }

        if (!cseList.isEmpty() && Schema.sObjectType.Case.isUpdateable()) {
            update cseList;
        }
        if (!cseMilestoneList.isEmpty() && Schema.sObjectType.CaseMilestone.isUpdateable()) {
            update cseMilestoneList;
        }


        CustomLogging.pop();
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Sept. 26, 2018
    * @description   Method to execute queuable interface for Work Order Billing
    */
    public void GENERATE_WO_BILLING(List<SObject> newList) {

        //System.debug('GENERATE_WO_BILLING');

        List<WorkOrderLineItem> woList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> parentWOLIListUpdate = new List<WorkOrderLineItem>();
        Set<Id> parentWOLI = new Set<Id>();

        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.IsReadyToSummarize__c &&
                    woli.Status == TS_Constants.STATUS_COMPLETED &&
                    woli.ParentWorkOrderLineItemId != null &&
                    woli.WorkOrderLineItemType__c == TS_Constants.TYPE_SERVICE
                    ){

                woList.add(woli);
                parentWOLI.add(woli.ParentWorkOrderLineItemId);

            }
        }

        if (woList.size() != 0){
            TS_WorkOrderBillingQueuable cse = new TS_WorkOrderBillingQueuable();
            cse.newList = woList;
            cse.parentWOLI = parentWOLI;
            System.enqueueJob(cse);
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          August 3, 2020
    * @description   Method to execute queuable interface for Missing Parts Sales Order
    */
    public void GENERATE_MISSINGPARTS_SALESORDER(Map<Id, SObject> oldMapItems, List<SObject> newList) {

        //System.debug('GENERATE_MISSINGPARTS_SALESORDER');
        
        Set<String> completedParent = new Set<String>();
        Set<String> parentWOLI = new Set<String>();
        Map<Id, WorkOrderLineItem> oldRec = (Map<Id, WorkOrderLineItem>)oldMapItems;

        //Karen Hung DOO-4861 1.9.2020
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.Status == TS_Constants.STATUS_COMPLETED &&
                woli.Status != oldRec.get(woli.Id).Status &&
                woli.ParentWorkOrderLineItemId == null &&
                woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK &&
                woli.MissingPartsSAPSalesOrder__c == null
              ){

                completedParent.add(woli.Id);
            }
        }

        //Karen Hung DOO-4861 1.9.2020
        if(!completedParent.isEmpty()){
            List<WorkOrderLineItem> missingParts = [SELECT Id, ParentWorkOrderLineItemId, DirectToCustomer__c 
                                              FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId IN :completedParent 
                                              AND DirectToCustomer__c = true 
                                              AND WorkOrderLineItemType__c = :TS_Constants.WOLI_STATUS_MISSING];
            if(!missingParts.isEmpty()){
                for(WorkOrderLineItem partWoli : missingParts){
                    parentWOLI.add(partWoli.ParentWorkOrderLineItemId);    
                }
            }

            if(!parentWOLI.isEmpty()){
                TS_QueueableProcesses varProcess = new TS_QueueableProcesses();
                varProcess.METHOD_MISSINGPARTS_SALESORDER = true;
                varProcess.woliSet_missingParts = parentWOLI;
                System.enqueueJob(varProcess);
                integMissingPartTriggered = true;
            }       
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.17.2017
    * @description   Method responsible in status update of Work Order based on WOLI status
    * @revision(s)
    */
    @TestVisible
    private void updateWorkOrderStatus(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('updateWorkOrderStatus', 'WorkOrderLineItemTriggerHandler');
        //Collection variables for filtering duplicate record
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> workOrderIdsFirstStat = new Set<Id>();
        Set<Id> workOrderIdsSecondStat = new Set<Id>();
        Set<Id> workOrderIdsThirdStat = new Set<Id>();
        Set<Id> workOrderIdsFourthStat = new Set<Id>();
        Set<Id> workOrderIdsFifthStat = new Set<Id>();

        //Mapping variables for related Case, Work Order, and WOLI records
        Map<Id, String> woReturnReviewMap = new Map<Id, String>();
        Map<Id, Id> woOwnerMap = new Map<Id, Id>();
        Map<Id, Id> woFirstStatusMap = new Map<Id, Id>();
        Map<Id, Id> woSecondStatusMap = new Map<Id, Id>();
        Map<Id, Id> woThirdStatusMap = new Map<Id, Id>();
        Map<Id, Id> woFourthStatusMap = new Map<Id, Id>();
        Map<Id, Id> woFifthStatusMap = new Map<Id, Id>();
        Map<Id, String> woOwnerStatusMap = new Map<Id, String>();
        Id caseRecTypeFSDefault = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_DEFAULT);
        Id caseRecTypeFSSales = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_SALES);
        Id caseRecTypeFSContract = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_CONTRACT);
        Id caseRecTypeRouteSales = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_ROUTESALES); //Karen Hung 10.10.18 to include routesales
        Id woliRecTypeRouteSalesTask = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECTYPE_ROUTESALES); //Karen Hung 10.11.18 to include routesales task

        Map<Id, WorkOrderLineItem> oldWoli = (Map<Id, WorkOrderLineItem>) oldMapItems;

        //List all Work Order Ids
        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
            String woliRtId = woli.RecordTypeId;
            if ((woliRtId.contains(tsWOLIRecordType) || woliRtId.contains(woliRecTypeRouteSalesTask)) && woli.Status != oldWoli.get(woli.Id).Status) { //Karen Hung 10.11.18 added routesales task
                workOrderIds.add(woli.WorkOrderId);
            }
        }

        //Query Work Order Line Items related to same Work Order record. This is to verify WOLI status.
        if (!workOrderIds.isEmpty()) {
            for (WorkOrder wo :[SELECT Id, Status,
            (SELECT Status, WorkOrderId, WorkOrder.CaseId, ReturnNeeded__c, ReviewNeeded__c, RecordTypeId
            FROM WorkOrderLineItems)
            FROM WorkOrder
            WHERE Id IN :workOrderIds
            AND (Case.RecordTypeId =: caseRecTypeFSDefault
            OR Case.RecordTypeId =: caseRecTypeFSSales
            OR Case.RecordTypeId =: caseRecTypeFSContract
            OR Case.RecordTypeId =: caseRecTypeRouteSales)]) //Karen Hung 10.10.2018 to include routesales
            {
                //Iterate each WOLI per work order record
                for (WorkOrderLineItem woli: wo.WorkOrderLineItems) {
                    //only run process for TS Work Order Line Item record types
                    String woliRtId = woli.RecordTypeId;
                    if (woliRtId.contains(tsWOLIRecordType) || woliRtId.contains(woliRecTypeRouteSalesTask)) {
                        //Check if status are Open, Scheduled, and Dispatched
                        if (woli.Status == TS_Constants.STATUS_OPEN || woli.Status == TS_Constants.WOLI_STATUS_SCHEDULED
                                || woli.Status == TS_Constants.WOLI_STATUS_DISPATCHED)
                        {
                            if (workOrderIdsFirstStat.add(woli.WorkOrderId)) {
                                woFirstStatusMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                            }
                            //Check if status are Received, On Site, Travelling, or Start Work
                        } else if (woli.Status == TS_Constants.WOLI_STATUS_RECEIVED || woli.Status == TS_Constants.WOLI_STATUS_TRAVELLING
                                || woli.Status == TS_Constants.WOLI_STATUS_ONSITE || woli.Status == TS_Constants.WOLI_STATUS_STARTWORK)
                        {
                            if (workOrderIdsSecondStat.add(woli.WorkOrderId)) {
                                woSecondStatusMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                            }
                            //Check if Status is Review Needed
                        } else if (woli.Status == TS_Constants.WOLI_STATUS_REVIEW) {
                            if (workOrderIdsThirdStat.add(woli.WorkOrderId)) {
                                woThirdStatusMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                                //Add the WOLI record for assigning to queue
                                woOwnerMap.put(woli.WorkOrderId, getQueueByName(TS_Constants.WOLI_STATUS_REVIEW));
                            }
                            //Check if Completed
                            //XEN 11/6 for Return Needed - added !woli.ReturnNeeded__c
                        } else if (woli.Status == TS_Constants.STATUS_COMPLETED && !woli.ReviewNeeded__c && !woli.ReturnNeeded__c) {
                            if (workOrderIdsFourthStat.add(woli.WorkOrderId)) {
                                woFourthStatusMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                            }
                            //Check if status if Canceled
                        } else if (woli.Status == TS_Constants.STATUS_CANCELED) {
                            if (workOrderIdsFifthStat.add(woli.WorkOrderId)) {
                                woFifthStatusMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                            }
                        }
                    }
                }
            }

            //####### Update parent Word Order record ############
            List<WorkOrder> workOrderToUpdate = new List<WorkOrder>();
            Map<Id, String> woIdsMap = new Map<Id, String>();
            Map<Id, String> caseStatusMap = new Map<Id, String>();
            String subStatus = null;

            //Determine Work Order status needed to set based on WOLI statuses
            for (ID workOrderID : workOrderIds) {
                /* Removed due to new logic for return needed -------------------------Kimiko Roberto 4.10.2017
                //Scenario 1: Set WO Status to Review and Return Needed
                if (woReturnReviewMap.get(workOrderID) != null) {
                woIdsMap.put(workOrderID, woReturnReviewMap.get(workOrderID));
                ---------------------------------------------------------------------*/
                //Scenario 1: Set WO Status to Canceled
                if (woFirstStatusMap.get(workOrderID) == null
                        && woSecondStatusMap.get(workOrderID) == null
                        && woThirdStatusMap.get(workOrderID) == null
                        && woFourthStatusMap.get(workOrderID) == null
                        && woFifthStatusMap.get(workOrderID) != null)
                {
                    woIdsMap.put(workOrderID, TS_Constants.STATUS_CANCELED);
                    caseStatusMap.put(woFifthStatusMap.get(workOrderID), TS_Constants.STATUS_CANCELED);

                    //Scenario 2: Set WO Status to Complete
                } else if (woFirstStatusMap.get(workOrderID) == null
                        && woSecondStatusMap.get(workOrderID) == null
                        && woThirdStatusMap.get(workOrderID) == null
                        && woFourthStatusMap.get(workOrderID) != null)
                {
                    woIdsMap.put(workOrderID, TS_Constants.STATUS_COMPLETED);

                    // 10.09.2017 TSWS-496
                    //caseStatusMap.put(woFourthStatusMap.get(workOrderID), Label.TS_Status_CompleteD);
                    caseStatusMap.put(woFourthStatusMap.get(workOrderID), TS_Constants.STATUS_CLOSED);

                    //Scenario 3: Set WO Status to Review Needed
                } else if (woFirstStatusMap.get(workOrderID) == null
                        && woSecondStatusMap.get(workOrderID) == null
                        && woThirdStatusMap.get(workOrderID) != null)
                {
                    woIdsMap.put(workOrderID, TS_Constants.WOLI_STATUS_REVIEW);
                    caseStatusMap.put(woThirdStatusMap.get(workOrderID), TS_Constants.WOLI_STATUS_REVIEW);

                    //Scenario 4: Set WO Status to Sent To Field
                } else if (woFirstStatusMap.get(workOrderID) == null
                        && woSecondStatusMap.get(workOrderID) != null)
                {
                    woIdsMap.put(workOrderID, TS_Constants.WO_STATUS_SENTFIELD);
                    caseStatusMap.put(woSecondStatusMap.get(workOrderID), TS_Constants.CASE_SUBSTATUS_SENTFIELD);

                    //Scenario 5: Set WO Status to Sent To Planning
                } else if (woFirstStatusMap.get(workOrderID) != null){
                    woIdsMap.put(workOrderID, TS_Constants.WO_STATUS_SENTPLANNING);
                    caseStatusMap.put(woFirstStatusMap.get(workOrderID), TS_Constants.CASE_SUBSTATUS_SENTPLANNING);
                }
            }

            if (!woIdsMap.isEmpty()) {
                //Assign the values in the Work Order Record
                for (WorkOrder wo: [SELECT Id, OwnerId, Status FROM WorkOrder WHERE Id IN :woIdsMap.keySet()]) {

                    if (woOwnerMap.get(wo.Id) != null) {
                        wo.OwnerId =  woOwnerMap.get(wo.Id);
                    }

                    wo.Status = woIdsMap.get(wo.Id);
                    workOrderToUpdate.add(wo);
                }

                //Update the Work Order Record
                if (!workOrderToUpdate.isEmpty() 
                    //&& Schema.sObjectType.WorkOrder.isUpdateable() //DOO-4464 XEN REYES June 5, 2020
                    ) {
                    try {
                        //Exception for test class purposes
                        if (Test.isRunningTest() && hasException) {
                            throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                        }
                        update workOrderToUpdate;
                    } catch(Exception ex) {
                        CustomLogging.debugException(ex);
                        CustomLogging.pop();
                    }
                }
            }

            //####### Update Case record ############
            if (!caseStatusMap.isEmpty()) {
                List<Case> caseToUpdate = new List<Case>();
                Boolean executeSubstatus = null;

                for (Case cse: [SELECT CaseSubStatus__c, Status, RecordTypeId,
                (SELECT Id, Status FROM WorkOrders)
                FROM Case WHERE Id IN :caseStatusMap.keySet()]) { //Karen Hung 12.10.2018 added recordtypeId in query

                    //Initialize flag every iteration
                    executeSubstatus = true;

                    //Check Work Order status records related to Parent Case
                    for (WorkOrder wo: cse.WorkOrders) {
                        if (wo.Status != TS_Constants.STATUS_COMPLETED && wo.Status != TS_Constants.STATUS_CANCELED) {
                            executeSubstatus = false;
                            break;
                        }
                    }

                    if (executeSubstatus && caseStatusMap.get(cse.Id) == TS_Constants.STATUS_CANCELED) {
                        cse.CaseSubStatus__c = caseStatusMap.get(cse.Id);
                        // 10.09.2017 TSWS-496
                        // } else if (executeSubstatus && Label.TS_Status_CompleteD.equals(caseStatusMap.get(cse.Id))) {
                    } else if (executeSubstatus && caseStatusMap.get(cse.Id) == TS_Constants.STATUS_CLOSED) {
                        cse.CaseSubStatus__c = caseStatusMap.get(cse.Id);
                    } else if (caseStatusMap.get(cse.Id) != TS_Constants.STATUS_CANCELED
                            // 10.09.2017 TSWS-496
                            // && !Label.TS_Status_CompleteD.equals(caseStatusMap.get(cse.Id))) {
                            && caseStatusMap.get(cse.Id) != TS_Constants.STATUS_CLOSED) {
                        cse.CaseSubStatus__c = caseStatusMap.get(cse.Id);
                    }

                    //set status to In Progress or Canceled
                    // 10.09.2017 TSWS-496
                    // if(!Label.TS_Status_CompleteD.equals(cse.CaseSubStatus__c)
                    if (cse.CaseSubStatus__c != TS_Constants.STATUS_CLOSED
                            && cse.CaseSubStatus__c != TS_Constants.STATUS_CANCELED) {
                        cse.Status = TS_Constants.STATUS_INPROGRESS;
                    }

                    // 10.09.2017 TSWS-496
                    /*if (Label.TS_Status_CompleteD.equals(cse.CaseSubStatus__c)) {
                    cse.Status = Label.TS_Status_CompleteD;
                    } */
                    if (cse.CaseSubStatus__c == TS_Constants.STATUS_CLOSED) {
                        cse.Status = TS_Constants.STATUS_CLOSED;
                    }

                    //Karen Hung 12.10.2018 update status to canceled for routesales if task is canceled
                    if (cse.CaseSubStatus__c == TS_Constants.STATUS_CANCELED && cse.RecordTypeId == caseRecTypeRouteSales) {
                        cse.Status = TS_Constants.STATUS_CANCELED;
                    }
                    caseToUpdate.add(cse);
                }

                if (!caseToUpdate.isEmpty() 
                    //&& Schema.sObjectType.Case.isUpdateable() //DOO-4464 XEN REYES June 5, 2020
                    ) {
                    try {
                        //Exception for test class purposes
                        if (Test.isRunningTest() && hasException) {
                            throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                        }

                        update caseToUpdate;

                    } catch(Exception ex) {

                        /* Do not create custom log for case status change VR - Xen Reyes - April 10, 2019 */
                        /* String VR_CASESTATUS = 'Cannot change case status to previous state';
                        if(!ex.getMessage().contains(VR_CASESTATUS)){
                            CustomLogging.debugException(ex);
                        } */

                        CustomLogging.debugException(ex);
                        CustomLogging.pop();
                    }
                }
            }
            //####### Update Case record ############
        }

        CustomLogging.pop();
    }

    /**
    * @author        Karen Hung
    * @date          10.10.2018
    * @description   Method responsible in status update of Work Order based on WOLI status for Operating and Counter Reading Task
    * @revision(s)
    */
    @TestVisible
    private void updateOpCounterReadingWorkOrderStatus(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('updateOpCounterReadingWorkOrderStatus', 'WorkOrderLineItemTriggerHandler');

        Set<Id> workOrderIds = new Set<Id>();

        Id woRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_WO, TS_Constants.TS_WO_RECORDTYPE_COUNTERREADING);
        Id woRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_WO, TS_Constants.TS_WO_RECORDTYPE_OPERATINGWO);
        Id woliRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADINGTASK);
        Id woliRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK);
        Id woliRecTypeReading = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADING);

        Map<Id, WorkOrderLineItem> oldWoli = (Map<Id, WorkOrderLineItem>) oldMapItems;

        List<WorkOrder> workOrderToUpdate = new List<WorkOrder>();

        //List all Work Order Ids
        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
            //if status is changed and woli record type is either operating task or counter reading task
            if ( woli.Status != oldWoli.get(woli.Id).Status && (woli.RecordTypeId == woliRecTypeCReading || woli.RecordTypeId == woliRecTypeOperating)) {
                workOrderIds.add(woli.WorkOrderId);
            }
        }

        if (!workOrderIds.isEmpty()){
            for(WorkOrder wo : [SELECT Id, Status,
            (SELECT Status, WorkOrderId, WorkOrder.CaseId, ReturnNeeded__c, ReviewNeeded__c, RecordTypeId FROM WorkOrderLineItems)
            FROM WorkOrder
            WHERE Id IN :workOrderIds
            AND (RecordTypeId =: woRecTypeCReading OR RecordTypeId =: woRecTypeOperating)]){

                Set<String> woliStatusSet = new Set<String>();
                //Iterate each WOLI per work order record
                for (WorkOrderLineItem woli: wo.WorkOrderLineItems) {
                    if(woli.RecordTypeId != woliRecTypeReading){
                        woliStatusSet.add(woli.status);
                    }
                }

                //If all wolis are complete
                if(woliStatusSet.size() == 1 && woliStatusSet.contains(TS_Constants.STATUS_COMPLETED)){
                    wo.Status = TS_Constants.STATUS_COMPLETED; //Completed
                    workOrderToUpdate.add(wo);
                }

                //If all wolis are canceled
                if(woliStatusSet.size() == 1 && woliStatusSet.contains(TS_Constants.STATUS_CANCELED)){
                    wo.Status = TS_Constants.STATUS_CANCELED; //Canceled
                    workOrderToUpdate.add(wo);
                }

                //If all wolis are scheduled
                if(woliStatusSet.size() == 1 && woliStatusSet.contains(TS_Constants.WOLI_STATUS_SCHEDULED)){
                    wo.Status = TS_Constants.WOLI_STATUS_SCHEDULED; //Scheduled
                    workOrderToUpdate.add(wo);
                }

            }
        }

        if(!workOrderToUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable()){
            try {
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                }

                database.update(workOrderToUpdate);

            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.17.2017
    * @description   This method will return a map of queues keyed by ID
    * @revision(s)
    */
    private Map<Id, Group> getQueues() {
        CustomLogging.push('getQueues', 'WorkOrderLineItem');
        QUEUES = new Map<Id, Group> ([
                SELECT
                        Id,
                        Name,
                        DeveloperName,
                        Type
                FROM
                        Group
                WHERE
                        Type =: TS_Constants.TYPE_QUEUE]);

        CustomLogging.pop();
        return QUEUES;

    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.17.2017
    * @description   This method will return Queue Id by Name
    * @revision(s)
    */
    private Id getQueueByName(String name) {
        CustomLogging.push('getQueueByName', 'WorkOrderLineItem');
        Map<String, Id> queueMap = new Map<String, Id>();
        String result = null;

        if (QUEUES == null) {
            QUEUES = getQueues();
        }

        for (Group grp: QUEUES.values()) {
            queueMap.put(grp.Name, grp.Id);
        }

        CustomLogging.pop();
        return queueMap.get(name);
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Oct. 8, 2018
    * @description   Review Needed in Before Insert
    * @revision(s)
    */
    public void validateIfReviewNeededBefore(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        CustomLogging.push('validateIfReviewNeededBefore', 'WorkOrderLineItemTriggerHandler');

        //List for updating Completed WOLIS where Review Needed = true
        List<WorkOrderLineItem> woliReiewNeededList = new List<WorkOrderLineItem>();

        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList) {
            WorkOrderLineItem oldWOLI = (WorkOrderLineItem) oldRecordMap.get(woli.Id);
            //Check if Review Needed = true and change Status to Review Needed
            if (woli.ReviewNeeded__c && woli.ReviewNeeded__c != oldWOLI.ReviewNeeded__c) {

                woli.Status = TS_Constants.WOLI_STATUS_REVIEW;
            } else if (woli.Status == TS_Constants.STATUS_COMPLETED && woli.ReviewNeeded__c && oldWOLI.ReviewNeeded__c == woli.ReviewNeeded__c){

                woli.Status = TS_Constants.STATUS_COMPLETED;
                woli.ReviewNeeded__c = false;
            }
        }
        CustomLogging.pop();
    }

    /**
    * @author        Kimiko Roberto
    * @date          04.04.2017
    * @description   Method responsible for creating Integration Logs and Attachments
    * @revision(s)   15.08.2017 Bas Hoeberigs : changed the insert and update for the INTERNAL ORDER (I/O), CATS, and Goodsmovement confditions
    */
    public void createIntegrationLogs(List<SObject> newList, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        CustomLogging.push('createIntegrationLogs', 'WorkOrderLineItemTriggerHandler');

        List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
        // List<WorkOrderLineItem> woliToUpdateList = new List<WorkOrderLineItem>();
        Map<Id,WorkOrderLineItem> woliToUpdateMap = new Map<Id,WorkOrderLineItem>(); //Karen Hung 1/31/19

        //START - XEN REYES - Resource/Engineer Checking CATS Profile - JDEP 9.14.2018 KTS-2141
        Map<Id, Resource__c> resourceIdRecMap = new Map<Id, Resource__c>();
        Map<Id, Resource__c> woliidEngineerRecMap = new Map<Id, Resource__c>();
        Set<Id> engineerIdSet = new Set<Id>();

        for(WorkOrderLineItem wo : (List<WorkOrderLineItem>) newList){
            if(wo.ExecutingEngineer__c != NULL){
                engineerIdSet.add(wo.ExecutingEngineer__c);
            }
        }

        if(!engineerIdSet.isEmpty()){
            resourceIdRecMap = new Map<Id, Resource__c>([SELECT Id, CATSProfile4digCode__c FROM Resource__c WHERE Id IN: engineerIdSet]);
            if(!resourceIdRecMap.isEmpty()){
                for(WorkOrderLineItem wo : (List<WorkOrderLineItem>) newList){
                    if(resourceIdRecMap.containsKey(wo.ExecutingEngineer__c)){
                        woliidEngineerRecMap.put(wo.Id, resourceIdRecMap.get(wo.ExecutingEngineer__c));
                    }
                }
            }
        }
        //END - XEN REYES - Resource/Engineer Checking CATS Profile - JDEP 9.14.2018 KTS-2141

        //Transferred to WorkOrderBilling Queueable - DOO-5026 - Xen Reyes - Nov. 25, 2020
        //START - XEN REYES - Country Purchasing Settings Query for Car Stock Replenishment Order for Missing Parts - August 21, 2019
        if(enabledFeatureMap.containsKey('DOO_5026_SF_Change_trigger_Used_Part_G') && enabledFeatureMap.get('DOO_5026_SF_Change_trigger_Used_Part_G') == false){
            if(COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.isEmpty()){    
                List<CountrySetting__c> GET_COUNTRYPURCHASING_LIST = [SELECT Id, Name, Company_Code__c, Active__c FROM CountrySetting__c    
                                                                    WHERE Active__c = true  
                                                                    AND RecordType.Name =: TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYPURCHASING];    
                if(!GET_COUNTRYPURCHASING_LIST.isEmpty()){  
                    for(CountrySetting__c CS_VAR : GET_COUNTRYPURCHASING_LIST){ 
                        COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.put(CS_VAR.Company_Code__c, CS_VAR);  
                    }   
                }   
            }
        }
        //END - XEN REYES - Country Purchasing Settings Query for Car Stock Replenishment Order for Missing Parts - August 21, 2019

        //iterate from list and validate what kind of integration lof will be created through validateWorkOrderLineItem method
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList) {
            //add all records validated
            //integLogsToInsertList.addAll(validateWorkOrderLineItem(woli, oldRecordMap, woliToUpdateList, newRecordMap, woliidEngineerRecMap));    //Karen Hung 1/31/19
            integLogsToInsertList.addAll(validateWorkOrderLineItem(woli, oldRecordMap,woliToUpdateMap, newRecordMap, woliidEngineerRecMap));    //Karen Hung 1/31/19
        }

        //check if integLogsToInsertList is not empty and proceed to insertion
        if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()  && Schema.sObjectType.Integration_Log__c.isCreateable()) {
            try {
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
                }

                //to prevent the multiple creation in after update scenario
                //notifyClick = oldRecordMap == null ? true : false;
                createIntegrationLogOnce= oldRecordMap == null ? true : false;


                insert integLogsToInsertList;
            } catch(Exception ex) {
                //notifyClick = true;
                createIntegrationLogOnce= true;
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }

        //Karen Hung 1/31/19
        if(woliToUpdateMap != null && !woliToUpdateMap.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
            try {
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
                }
                update woliToUpdateMap.values();

                System.debug('DEBUG woliToUpdateMap ' + woliToUpdateMap.values());

            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Kimiko Roberto
    * @date          04.04.2017
    * @description   Method responsible for validating the integration logs that will be created
    * @revision(s)   15.08.2017 Bas Hoeberigs : changed the insert and update for the I/o CATS and Goodsmovement confditions
    *                6.1.2018 Paul Aguiling KTS-1715: Added integration logic for service materials and required parts
    */
    public List<Integration_Log__c> validateWorkOrderLineItem(WorkOrderLineItem woli, Map<Id, SObject> oldRecordMap, Map<Id,WorkOrderLineItem> woliToUpdateMap, Map<Id, SObject> newRecordMap, Map<Id, Resource__c> woliidEngineerRecMap)
    {
        CustomLogging.push('validateWorkOrderLineItem', 'WorkOrderLineItemTriggerHandler');
        WorkOrderLineItem WoliToBeUpdated = new WorkOrderLineItem();
        List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();

        //***********condition for operating task and counter reading ***************//
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADING).getRecordTypeId();
        Boolean isOperatingTask = woli.RecordtypeId.equals(CONST_WOLI_CHILD_CR_RT) || (woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP);
        //*****************************************************//
        //***********condition for RouteSale task**************//
        Boolean isRouteSalesTask = woli.WorkOrderType__c == TS_Constants.TYPE_S25_ROUTESALES;
        //*****************************************************//

        //Variables specific to add service materials and required parts
        Boolean isAddReqPartsAndSvcMtrls = woli.AddPartsandMaterialsIntegration__c; //KTS-1715 6.1.2018 Added by Paul Jarred

        Boolean caseIsAddReqPartsAndSvcMtrls = false;
        Boolean isCaseSalesOrder = false; //KTS-1867 6.25.2018 Added by Paul Jarred
        
        if(extWoliNewMap.containsKey(woli.Id)){
            caseIsAddReqPartsAndSvcMtrls = extWoliNewMap.get(woli.Id).Case__r != null ? extWoliNewMap.get(woli.Id).Case__r.AddRequiredPartsandMaterials__c : false; //KTS-1715 6.1.2018 Added by Paul Jarred

            //KTS-1867: Determine if the parent case is sales order and grouping indicator(value = JDE line item number) is not empty
            if (extWoliNewMap.get(woli.Id).Case__r != null && extWoliNewMap.get(woli.Id).Case__r.Origin == TS_Constants.CASE_ORIGIN_SALESORDER) {
                isCaseSalesOrder = true;
            }
        }
        
        //Boolean caseIsAddReqPartsAndSvcMtrls = extWoliNewMap.get(woli.Id).Case__r != null? extWoliNewMap.get(woli.Id).Case__r.AddRequiredPartsandMaterials__c: false; //KTS-1715 6.1.2018 Added by Paul Jarred

        //*****INSERT CONDITIONS OF WORKORDERLINEITEMS starts here*********
        if (oldRecordMap == null) {
            if(extWoliNewMap.containsKey(woli.Id)){

                
                //==============================================================================================//
                //It is used for sending to Click, after fixed cost loading service materials on Task and send it to click, notifyServiceMaterial is to make sure integration log created once
                //on task closing, dummy service material is also loaded but no need to create integration log, prevented by IsReadyToSummarize__c
                //Chi: no potential  overlaping with operating task /counter reading --> filtered by WorkOrderLineItemType__c that is not used by operating task/counter reading
                if (woli.WorkOrderLineItemType__c == TS_Constants.TYPE_SERVICE
                    && !woli.IsReadyToSummarize__c //to prevent dummy service material (on task closing) entered to this condition
                    //&& extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ServiceMaterialsLoaded__c // cannot be used as the parent is not updated yet to ServiceMaterialsLoaded__c
                    && extWoliNewMap.get(woli.id).Case__r.Click__c // only for Click non
                    && woli.ParentWorkOrderLineItemId != null
                    && !isAddReqPartsAndSvcMtrls) { //KTS-1715 6.1.2018 Added by Paul Jarred
                        
                        WoliToBeUpdated = new WorkOrderLineItem(Id = woli.ParentWorkOrderLineItemId);
                        if(!woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                            woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                        }

                        notifyServiceMaterial = true;
                        if (isDebugOk) {
                            //System.debug('TS Check: Entered create integrationlog on insert for notifyservicematerial, Generic sequence: '+genericTriggerTransactionSequence+ ' , Afterinsert sequence: '+afterInsertTriggerTransactionSequence);
                        }
                }
                
                //Transferred to WorkOrderBilling Queueable - DOO-5026 - Xen Reyes - Nov. 25, 2020
                //===================Good movement===========================================================================//
                // it is used to send to SAP for Good Movement (create one integration log)
                // when a task is completed and a used part is added by Click or SF mobile, the used part should be sent to SAP, for every used part.
                // the used part is the child woli
                if(enabledFeatureMap.containsKey('DOO_5026_SF_Change_trigger_Used_Part_G') && enabledFeatureMap.get('DOO_5026_SF_Change_trigger_Used_Part_G') == false){
                    if (//createIntegrationLogOnce && !(isOperatingTask || isRouteSalesTask) &&
                        woli.Status == TS_Constants.STATUS_COMPLETED &&
                        woli.WorkOrderLineItemType__c == TS_Constants.TYPE_API_USEDPARTS &&
                        woli.Part_used_from_own_storage_location__c == true && //Karen Hung 29.05.2020 DOO-4468 send only if from own car stock

                        //extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.InternalOrderSAP__c != null && XEN REYES Jan. 11, 2019

                        extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.OrderHeaderSAPId__c == null && //XEN REYES April 17, 2019 - ALM 6841
                        extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ExecutingEngineer__c != null &&
                        extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ExecutingEngineer__r.SAPStorageLocation__c != null
                        ){

                        integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                                Object__c = INT_Constants.WOLI_GOODS_MVMT,
                                Integration_Status__c = INT_Constants.INITIAL,
                                Work_Order_Line_Item__c = woli.Id));
                    }
                }
                //==============================================================================================//

                //Transferred to WorkOrderBilling Queueable - DOO-5026 - Xen Reyes - Nov. 25, 2020
                //==================CAR STOCK REPLENISHMENT ORDER FOR MISSING PARTS===========================================================================//
                //XEN REYES August 21, 2019
                if(enabledFeatureMap.containsKey('DOO_5026_SF_Change_trigger_Used_Part_G') && enabledFeatureMap.get('DOO_5026_SF_Change_trigger_Used_Part_G') == false){
                    if (woli.DirectToCustomer__c == false &&
                        woli.WorkOrderLineItemType__c == TS_Constants.WOLI_STATUS_MISSING &&
                        extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ExecutingEngineer__c != null &&
                        extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c != null &&
                        COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.containsKey(extWoliNewMap.get(woli.id).ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c)){
                        
                        //CREATE INTEGRATION LOGS
                        integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                                Object__c = INT_Constants.WOLI_CARSTOCK,
                                Integration_Status__c = INT_Constants.INITIAL,
                                Work_Order_Line_Item__c = woli.Id));
                    }
                }
                //==============================================================================================//

                //**********************************************************************//
                //Scenario: create integration log for disaster recovery internal order.
                //          This only applies after insert of woli
                //Added by Marvin
                if(Trigger.isInsert && Trigger.isAfter &&
                        extWoliNewMap.get(woli.Id).Case__r.Origin == TS_Constants.CASE_ORIGIN_DR &&
                        woli.Status == TS_Constants.WOLI_STATUS_SCHEDULED &&
                        woli.ExecutingEngineer__c != null &&
                        String.isBlank(woli.InternalOrderSAP__c)  &&
                        //woli.TS_I_O_IntegrationLogcreated__c == false &&
                        woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK &&

                        //XEN REYES DOO-4330 April 8, 2020
                        woli.WorkOrderType__c != TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI) {

                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = INT_Constants.WOLI_CREATION_IO,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id));
                    
                }
            }

        }

        //*****UPDATE CONDITIONS OF WORKORDERLINEITEMS starts here*********
        //Check if fired from an update call
        else
        {   //Cast generic sobj map to WorkOrderLineItem and get old value from oldRecordMap
            WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldRecordMap.get(woli.Id);

            //Scneario: Creation I/O integration log once these criterias are met
            //Chi (updated): some potential  overlaping with  counter reading
            //Ritesh kumar (Updated) : Remove "&&" between the status and TS_WOLI_Status_Scheduled.
            //and put the "||". 29-08-2018
            if(//createIntegrationLogOnce &&
                !(isOperatingTask || isRouteSalesTask) &&
                (woli.Status != oldWoli.Status &&
                //(woli.Status == TS_Constants.WOLI_STATUS_SCHEDULED || woli.Status == TS_Constants.WOLI_STATUS_DISPATCHED)) && //Xen Reyes 8.30.2018 & KTS-2136 11.09.2018
                (woli.Status == TS_Constants.WOLI_STATUS_SCHEDULED || woli.Status == TS_Constants.WOLI_STATUS_DISPATCHED || woli.Status == TS_Constants.WOLI_STATUS_TRAVELLING || woli.Status == TS_Constants.WOLI_STATUS_ONSITE || woli.Status == TS_Constants.WOLI_STATUS_STARTWORK)) && //XEN REYES Jan. 14, 2019 KTS-2476
                woli.ExecutingEngineer__c != null &&
                //Francis Allen Alindogan DOO-4795 09/14/2020
                ((woli.TS_I_O_IntegrationLogcreated__c == false && woli.InternalOrderSAP__c != null) || (woli.InternalOrderSAP__c == null)) &&                
                //woli.TS_I_O_IntegrationLogcreated__c == false &&
                woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK &&
                integIOTriggered == false &&

                //XEN REYES DOO-4330 April 8, 2020
                woli.WorkOrderType__c != TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI){

                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = INT_Constants.WOLI_CREATION_IO,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id));            
                
                    //Francis Allen Alindogan DOO-4795 09/14/2020                            
                    WoliToBeUpdated = new WorkOrderLineItem(Id=woli.Id);
                    WoliToBeUpdated.TS_I_O_IntegrationLogcreated__c = TRUE;
                    if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                        woliToUpdateMap.get(WoliToBeUpdated.id).TS_I_O_IntegrationLogcreated__c = TRUE;                                             
                    }else{
                        woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); 
                    }
                                
                    //Static Variable to avoid re trigger - XEN REYES Oct 16 2018
                    integIOTriggered = true;
            }

            //**********************************************************************//
            //Scenario: Creation - CATS-record integration log once these criterias are met
            //Chi (updated): some potential  overlaping with counter reading
            //Ritesh kumar (Updated) : Remove "&&" between the status and TS_WOLI_Status_Scheduled.
            //and put the "||". 29-08-2018
            if(woli.ExecutingEngineer__c != null && woliidEngineerRecMap.containsKey(woli.Id)){
                if(//createIntegrationLogOnce &&x   
                    !(isOperatingTask || isRouteSalesTask) &&
                        (woli.Status != oldWoli.Status && woli.Status == TS_Constants.STATUS_COMPLETED) && //Xen Reyes 8.30.2018
                        woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK &&
                        woliidEngineerRecMap.get(woli.Id).CATSProfile4digCode__c == TS_Constants.CATSCODE_JDEP && //Karen Hung 9.11.18 KTS 2141
                        !(String.isBlank(woli.InternalOrderSAP__c))  &&
                        //woli.TS_CATS_Integrationlog_created__c == false &&
                        woli.TotalHours__c != null && //this is the total of  labour and travel or either one of them.
                        integCATSTriggered == false ) { //Static Variable to avoid re trigger - Xen Reyes 9.4.2018 KTS-2140
                        //repositioned by Bas to avoid looping of  integration log creation. ( move up on top of integrationloglist.add)
                        //endof Bas repositioning
                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = INT_Constants.WOLI_CATS,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id));

                    //Static Variable to avoid re trigger - Xen Reyes 9.4.2018 KTS-2140
                    integCATSTriggered = true;
                }
            }

            //**********************************************************************//
            // Scenario: create Integration log for operating task (machine care) and counter reading task
            //**********************************************************************//
            Boolean HAS_CHANGES_OPERATING = false;
            if(HAS_CHANGES_MAP.containsKey(woli.Id)){
                HAS_CHANGES_OPERATING = HAS_CHANGES_MAP.get(woli.Id);
            }

            if( isOperatingTask
                    && (
                        
                        //SCENARIO 1: if route operating task not created from the batch
                        !isRouteOperating &&
                        
                        //SCENARIO 2: Do not retrigger if Click modified fields //Karen Hung 21/11/2020 DOO-5035 updated criteria to remove custom label usage
                        ((woli.isFromRoute__c && UserInfo.getName() != clickName) || !woli.isFromRoute__c) &&
                        
                        //SCENARIO 3: Do not send to Click if Canceled and Send Counter Operating = false
                        !(woli.isFromRoute__c && woli.Status == 'Canceled' && woli.SendCounterReadingsOperating__c == FALSE) //Karen Hung to prevent ilog on routetaskcancelation without CR DOO-3116
                        
                        )
                    && woli.ClickReady__c
                    && (!woli.TS_I_O_IntegrationLogcreated__c || HAS_CHANGES_OPERATING)
                    && extWoliNewMap.get(woli.Id) != null
                    && extWoliNewMap.get(woli.Id).WorkOrder.Third_Party__c == false //Karen Hung DOO-5308 26/2/2021
                    && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedbyId == clickUserId) //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                    && woli.ParentWorkOrderLineItemId == null //to avoid child woli
                    )
            {
            
                String integLogObjectDesc;

                //XEN REYES 6.9.2018 Send only counter reading task when all CRs are loaded
                Boolean integReady = false;

                //Karen Hung Feb 13, 2020 DOO-3116 flag for cancelation in integration log
                Boolean isRouteCancelation = woli.isFromRoute__c && woli.Status == 'Canceled' ? true : false;

                if (woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE){
                    
                    if(woli.isFromRoute__c){
                        integLogObjectDesc = INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM;
                    } else {
                        integLogObjectDesc = INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK;
                    }

                    integReady = true;
                } else if (woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP){
                    integLogObjectDesc =INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK;

                    if(woli.isCRswoliisloaded__c){
                        integReady = true;
                    }
                }

                if(integReady){
                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = integLogObjectDesc,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id,
                            Triggered_Timestamp__c = Datetime.now(),
                            Cancelation__c = isRouteCancelation)); //Karen Hung Feb 13, 2020 DOO-3116 flag for cancelation
                }

                WoliToBeUpdated=new WorkOrderLineItem(Id=woli.Id);
                WoliToBeUpdated.TS_I_O_IntegrationLogcreated__c = TRUE;
                WoliToBeUpdated.Click_Integration_Status__c  = TS_Constants.STATUS_INPROGRESS;
                WoliToBeUpdated.ClickReady__c = false;

                if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                    woliToUpdateMap.get(WoliToBeUpdated.id).TS_I_O_IntegrationLogcreated__c = TRUE; //Karen Hung 1/31/19
                    woliToUpdateMap.get(WoliToBeUpdated.id).Click_Integration_Status__c  = TS_Constants.STATUS_INPROGRESS; //Karen Hung 1/31/19
                    woliToUpdateMap.get(WoliToBeUpdated.id).ClickReady__c=false; //Karen Hung 1/31/19
                }else{
                    woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                }
            }

            
            //**********************************************************************//
            // Scenario: Create Integration log for RouteSales task reading task
            //**********************************************************************//
            Boolean HAS_CHANGES_ROUTESALES = false;
            if(HAS_CHANGES_MAP.containsKey(woli.Id)){
                HAS_CHANGES_ROUTESALES = HAS_CHANGES_MAP.get(woli.Id);
            }

            if( isRouteSalesTask
                    && woli.ClickReady__c
                    && ( !woli.TS_I_O_IntegrationLogcreated__c || HAS_CHANGES_ROUTESALES)
                    && extWoliNewMap.get(woli.Id) != null
                    && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedbyId == clickUserId) //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                    && woli.ParentWorkOrderLineItemId == null //to avoid child woli
                    )
            {
                String integLogObjectDesc;
                integLogObjectDesc = INT_Constants.WOLI_CREATEUPDATE_ROUTESALES_TASK;

                integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                        Object__c = integLogObjectDesc,
                        Integration_Status__c = INT_Constants.INITIAL,
                        Work_Order_Line_Item__c = woli.Id,
                        Triggered_Timestamp__c = Datetime.now()));

                WoliToBeUpdated = new WorkOrderLineItem(Id = woli.Id);
                WoliToBeUpdated.TS_I_O_IntegrationLogcreated__c = TRUE;
                WoliToBeUpdated.Click_Integration_Status__c  = TS_Constants.STATUS_INPROGRESS;
                WoliToBeUpdated.ClickReady__c=false;

                if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                    woliToUpdateMap.get(WoliToBeUpdated.id).TS_I_O_IntegrationLogcreated__c = TRUE; //Karen Hung 1/31/19
                    woliToUpdateMap.get(WoliToBeUpdated.id).Click_Integration_Status__c  = TS_Constants.STATUS_INPROGRESS;//Karen Hung 1/31/19
                    woliToUpdateMap.get(WoliToBeUpdated.id).ClickReady__c=false; //Karen Hung 1/31/19
                }else{
                    woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                }
            }

            //************************************************************************************//
            // Scenario: //KTS-1715: Integration part for Add Service Materials and Required Parts
            //************************************************************************************//
            if(extWoliNewMap.get(woli.Id) != null &&

                (
                    //CONDITION 1: click ready and updated by non click - FIRST TASK
                    //CONDITION 4: Additional Service Job //DOO-5294 Xen Reyes Feb 4, 2021
                    ( (isAddReqPartsAndSvcMtrls || woli.Is_Additional_Service_Job__c)
                    && woli.ClickReady__c 
                    && woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                    && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId)) || //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129

                    //CONDITION 2: Return needed
                    (caseIsAddReqPartsAndSvcMtrls
                    && extWoliNewMap.get(woli.Id).RelateTo__c != null 
                    && extWoliNewMap.get(woli.Id).Case__r.Click__c
                    && extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c
                    && !woli.IsReturnNeededTask__c) ||

                    //CONDITION 3: Retrigger Return Task
                    (caseIsAddReqPartsAndSvcMtrls
                    && woli.IsReturnNeededTask__c
                    && woli.ClickReady__c 
                    && woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                    && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId)) //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129

                )
                
                ) { 
                
                //Create Integration log for Add Service Materials and Parts
                WorkOrderLineItem newWoli = (WorkOrderLineItem) newRecordMap.get(woli.Id);

                Boolean HAS_CHANGES = false;
                if(HAS_CHANGES_MAP.containsKey(newWoli.Id)){
                    HAS_CHANGES = HAS_CHANGES_MAP.get(newWoli.Id);
                }

                //if(validateIfHasChanges(newWoli, oldWoli, CONST_WOLITASK_FIELDSET)) {
                if(HAS_CHANGES || (extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c && !woli.IsReturnNeededTask__c)) {
                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = INT_Constants.WOLI_CREATEUPDATETASK,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id,
                            Triggered_Timestamp__c = Datetime.now()));

                    //Update the task to set click specific fields
                    WoliToBeUpdated = new WorkOrderLineItem(Id=woli.Id);
                    WoliToBeUpdated.ClickReady__c = false;
                    WoliToBeUpdated.Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;

                    if(extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c  && !woli.IsReturnNeededTask__c){
                        WoliToBeUpdated.IsReturnNeededTask__c = true;  
                    }

                    if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                        woliToUpdateMap.get(WoliToBeUpdated.id).ClickReady__c = false; //Karen Hung 1/31/19
                        woliToUpdateMap.get(WoliToBeUpdated.id).Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;  //Karen Hung 1/31/19
                    }else{
                        woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                    }

                }
            }


            //**********************************************************************//
            // Scenario: Create Integration log for Sales Orders
            //**********************************************************************//
            if(isCaseSalesOrder
                    && extWoliNewMap.get(woli.Id) != null
                    && woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                    && (

                    /* CONDITION 1 */
                    (woli.ClickReady__c && notifyServiceMaterial) ||//XEN REYES Oct 11 2018 KTS-2252 //Karen Hung 02.04.2019 ALM-6288 added click ready

                    /* CONDITION 2 */
                    (woli.ClickReady__c && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId)) || //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                    //Karen Hung 02.04.2019 ALM-6288 added click ready

                    /* CONDITION 3: Return Needed Task*/
                    (extWoliNewMap.get(woli.Id) != null
                    && extWoliNewMap.get(woli.Id).RelateTo__c != null
                    && extWoliNewMap.get(woli.Id).Case__r.Click__c //Karen Hung May 1, 2019  KTS-2689, ALM 6759 checker if click country
                    && extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c && !woli.IsReturnNeededTask__c) ||

                    //CONDITION 4: When Sales Order task is Closed via Saleforce Console by Third Party User
                    (extWoliNewMap.get(woli.Id) != null
                    && UserInfo.getName() != clickName //Karen Hung 21/11/2020 DOO-5035
                    && woli.Status == TS_Constants.STATUS_COMPLETED 
                    && oldWoli.Status != TS_Constants.STATUS_COMPLETED
                    && extWoliNewMap.get(woli.Id).Case__r.Click__c == true
                    && COMPLETED_THIRDPARTY == false) 

            )){

                String lineNumber = TS_Constants.WOLI_LINENUMBER_00000001; //This indicates the woli is the first task created
                WorkOrderLineItem newWoli = (WorkOrderLineItem) newRecordMap.get(woli.Id);
            
                Boolean HAS_CHANGES = false;
                if(HAS_CHANGES_MAP.containsKey(newWoli.Id)){
                    HAS_CHANGES = HAS_CHANGES_MAP.get(newWoli.Id);
                }

                if (

                        /* SUB-CONDITION 1: Create Integration log for the first task on Sales Order Case */
                        (HAS_CHANGES && lineNumber.equals(woli.LineItemNumber)) ||

                        /* SUB-CONDITION 2: Create Integration log for 2nd tasks or next tasks generated */
                        (HAS_CHANGES && woli.GroupingIndicator__c != null && !lineNumber.equals(woli.LineItemNumber)) ||

                        /* SUB-CONDITION 3: KTS-2609 / ALM-4991 XEN REYES Feb. 18, 2019 Create Integration Log for Return Needed Task */
                        (extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c  && !woli.IsReturnNeededTask__c) ||

                        /* SUB-CONDITION 4: NotifyServiceMaterial*/
                        notifyServiceMaterial ||

                        /* SUB-CONDITION 5: if an additional job is created for a sales order case*/ //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                        (HAS_CHANGES && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId) && woli.Is_Additional_Service_Job__c) ||

                        /* SUB-CONDITION 6: Create Integration log for return tasks*/ //Karen Hung 02.04.2019 ALM-6288 for updates on return tasks //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                        (HAS_CHANGES && woli.ReturnTask__c == true && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId)) ||

                        //SUB-CONDITION 7: When Sales Order task is Closed via Saleforce Console by Third Party User //DOO-4368 Xen Reyes April 28, 2020 //Karen Hung 21/11/2020 DOO-5035
                        (woli.Status == TS_Constants.STATUS_COMPLETED && oldWoli.Status != TS_Constants.STATUS_COMPLETED && UserInfo.getName() != clickName)) //Francis Allen Alindogan 05/07/2020 DOO-4457

                {

                    //DOO-4825 Francis Allen Alindogan 09/03/2020

                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                        Object__c = INT_Constants.WOLI_CREATEUPDATETASK,
                        Integration_Status__c = INT_Constants.INITIAL,
                        Work_Order_Line_Item__c = woli.Id,
                        Triggered_Timestamp__c = Datetime.now()));
                            

                    //Update the task to set click specific fields
                    WoliToBeUpdated = new WorkOrderLineItem(Id = woli.Id);
                    WoliToBeUpdated.ClickReady__c = false;
                    WoliToBeUpdated.Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;

                    if(extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c  && !woli.IsReturnNeededTask__c){
                        WoliToBeUpdated.IsReturnNeededTask__c = true;
                    }

                    if(UserInfo.getName() != clickName && woli.Status == TS_Constants.STATUS_COMPLETED && oldWoli.Status != TS_Constants.STATUS_COMPLETED){ //Francis Allen Alindogan 05/07/2020 DOO-4457 //Karen Hung 21/11/2020 DOO-5035
                        COMPLETED_THIRDPARTY = true;
                    }

                    if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                        woliToUpdateMap.get(WoliToBeUpdated.id).ClickReady__c = false; //Karen Hung 1/31/19
                        woliToUpdateMap.get(WoliToBeUpdated.id).Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;  //Karen Hung 1/31/19
                    } else{
                        woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                    }
                }

                notifyServiceMaterial = false;
            }                                
               
            //**********************************************************************//
            // Scenario: Create Integration log for Standard Jobs
            //**********************************************************************//
            if(
                //KTS-1715 isAddReqPartsAndSvcMtrls 6.1.2018 Added by Paul Jarred
                !(isOperatingTask || isRouteSalesTask || caseIsAddReqPartsAndSvcMtrls || isCaseSalesOrder)

                    //Karen Hung 2/27/2019 KTS-2646 Added Click Ready checker
                    //&& woli.ClickReady__c == true

                    && (

                        //CONDITION 1: updated by non click
                        (extWoliNewMap.get(woli.Id) != null
                        && !(extWoliNewMap.get(woli.Id).LastModifiedBy.Name == clickName && woli.LastModifiedById == clickUserId) //Karen Hung 21/11/2020 DOO-5035 5/12/2020 DOO-5129
                        && woli.ClickReady__c == true) ||

                        //CONDITION 2: updated by Click on new woli for return is needed,
                        (extWoliNewMap.get(woli.Id) != null    
                        && extWoliNewMap.get(woli.Id).RelateTo__c != null
                        && extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c && !woli.IsReturnNeededTask__c
                        && extWoliNewMap.get(woli.Id).Case__r.Click__c == true) || // KTS-2646 To check if Click Country before sending return needed

                        //CONDITION 3: when a notifyservicematerial on task  is  true, notifyServiceMaterial is to make sure created onc
                        (woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && notifyServiceMaterial) ||

                        //CONDITION 4: When counterreadings are loaded // CountersS10loaded__c
                        (woli.SendCounterReadings__c != oldWoli.SendCounterReadings__c && woli.SendCounterReadings__c == true && woli.CountersS10loaded__c == false)

                        //CONDITION 5: When TCS task is Closed via Saleforce Console by Third Party User - Xen Reyes August 16, 2019
                        || (extWoliNewMap.get(woli.Id) != null
                        && UserInfo.getName() != clickName //Karen Hung 21/11/2020 DOO-5035
                        && woli.Status == TS_Constants.STATUS_COMPLETED 
                        && oldWoli.Status != TS_Constants.STATUS_COMPLETED
                        && extWoliNewMap.get(woli.Id).Case__r.Click__c == true //XEN REYES Nov 23, 2019 - To check if Click Country
                        && COMPLETED_THIRDPARTY == false) 

                        //CONDITION 6: Cancelation of Water filters 11.21.2019 Karen Hung DOO-2686
                        ||(woli.Status == TS_Constants.STATUS_CANCELED && 
                        oldWoli.Status != TS_Constants.STATUS_CANCELED &&
                        (woli.WorkOrderType__c == TS_Constants.TYPE_S32_WATERFILTER || woli.WTSPerformed__c == true) &&
                        !HAS_CHANGES_MAP.containsKey(woli.Id))

                        //CONDITION 7: Create iLog for WTS completion with open s32 cancelation
                        ||( woli.Status == TS_Constants.STATUS_COMPLETED &&
                        oldWoli.Status != TS_Constants.STATUS_COMPLETED && 
                        woli.WTSPerformed__c == true &&
                        woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK)

                    )
					
                    //ADDITIONAL CONDITION: EXCLUDE THIRD PARTY OPERATOR FROM INTEGRATION LOG CREATION
                    //DOO-5150 Francis Allen Alindogan 01/04/2020
                    &&  (
                            //NOT AN S15 AUTO ASSIGN TO THIRD PARTY OPERATOR AND FEATURE FLAG IS ENABLED, AND CASE.SendTo3rdParty__c IS NOT TRUE
                            (
                             	!(woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && extWoliNewMap.get(woli.Id).AccountLocation__r.Third_Party_Resource__c != null && 
                             	//DOO-5298 Francis Allen Alindogan 02/27/2021
                        		extWoliNewMap.get(woli.Id).Case__r.SendTo3rdParty__c == true) &&                             
                            	enabledFeatureMap.containsKey('DOO_5150_TS_EnableThirdPartyOperator') && enabledFeatureMap.get('DOO_5150_TS_EnableThirdPartyOperator')
                            ) ||                        
                            //FEATURE FLAG IS DISABLED
                            (enabledFeatureMap.containsKey('DOO_5150_TS_EnableThirdPartyOperator') && !enabledFeatureMap.get('DOO_5150_TS_EnableThirdPartyOperator')) ||                        
                            //FEATURE FLAG IS NOT DEFINED
                            !enabledFeatureMap.containsKey('DOO_5150_TS_EnableThirdPartyOperator')                          	                        	
                        )					
            ){
				                                
                WorkOrderLineItem newWoli = (WorkOrderLineItem) newRecordMap.get(woli.Id);

                Boolean HAS_CHANGES = false;
                if(HAS_CHANGES_MAP.containsKey(newWoli.Id)){
                    HAS_CHANGES = HAS_CHANGES_MAP.get(newWoli.Id);
                }

                System.debug('HAS_CHANGES: ' + HAS_CHANGES);
                System.debug('notifyServiceMaterial: ' + notifyServiceMaterial);
                System.debug('woli.ReturnTask__c && woli.Return_Needed_Parts__c:' + (woli.ReturnTask__c == true && woli.Return_Needed_Parts__c == true));
                System.debug('woli.Status:' + woli.Status);
                System.debug('oldWoli.Status:' + oldWoli.Status);

                //XEN REYES August 13, 2019                
                if( HAS_CHANGES 
                    || notifyServiceMaterial 
                    || (woli.ReturnTask__c == true && woli.Return_Needed_Parts__c == true) 
                    || (UserInfo.getName() != clickName && woli.Status == TS_Constants.STATUS_COMPLETED && oldWoli.Status != TS_Constants.STATUS_COMPLETED) //Karen Hung 21/11/2020 DOO-5035
                    || (woli.Status == TS_Constants.STATUS_CANCELED && oldWoli.Status != TS_Constants.STATUS_CANCELED && (woli.WorkOrderType__c == 'S32' || woli.WTSPerformed__c == true)) //Karen Hung DOO-2686
                    ){

                    notifyServiceMaterial = false;

                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                                                            Object__c = INT_Constants.WOLI_CREATEUPDATETASK,
                                                            Integration_Status__c = INT_Constants.INITIAL,
                                                            Work_Order_Line_Item__c = woli.Id,
                                                            Triggered_Timestamp__c = Datetime.now()));

                    WoliToBeUpdated = new WorkOrderLineItem(Id = woli.Id);
                    WoliToBeUpdated.ClickReady__c = false;
                    WoliToBeUpdated.Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;

                    //FIELD TO BE SET TO TRUE WHEN A RETURN NEEDED TASK WAS CREATED
                    if (extWoliNewMap.get(woli.Id) != null && extWoliNewMap.get(woli.Id).RelateTo__r.ReturnNeeded__c && !woli.IsReturnNeededTask__c) {
                        
                        WoliToBeUpdated.IsReturnNeededTask__c = true;

                        if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                            woliToUpdateMap.get(WoliToBeUpdated.id).IsReturnNeededTask__c = true;
                        }
                    }

                    //UPDATE FIELD INDICATOR IN COUNTER READING for NON-COUNTER READING TASK
                    if(woli.SendCounterReadings__c != oldWoli.SendCounterReadings__c && woli.SendCounterReadings__c == true && woli.CountersS10loaded__c == false){
                        WoliToBeUpdated.CountersS10loaded__c = true;
                        
                        if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                            woliToUpdateMap.get(WoliToBeUpdated.id).CountersS10loaded__c = true;
                        }
                    }

                    //XEN REYES August 21, 2019
                    if(UserInfo.getName() != clickName && woli.Status == TS_Constants.STATUS_COMPLETED && oldWoli.Status != TS_Constants.STATUS_COMPLETED){ //Francis Allen Alindogan 05/07/2020 DOO-4457 //Karen Hung 21/11/2020 DOO-5035
                        COMPLETED_THIRDPARTY = true;
                    }

                    if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                        woliToUpdateMap.get(WoliToBeUpdated.id).ClickReady__c = false; //Karen Hung 1/31/19
                        woliToUpdateMap.get(WoliToBeUpdated.id).Click_Integration_Status__c = TS_Constants.STATUS_INPROGRESS;  //Karen Hung 1/31/19

                    } else{
                        woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated); //Karen Hung 1/31/19
                    }

                }
            }


            //***********************************************************************************************//
            //Scenario: create integration log for notifying Click that the record update by Click is success.
            //***********************************************************************************************//
            if( !(isOperatingTask || isRouteSalesTask) &&
                extWoliNewMap.get(woli.Id) != null &&  !woli.IsLabour__c &&
                (UserInfo.getName() == clickName || Test.isRunningTest()) &&  //Karen Hung Apr.18, 2019 current user is click //Karen Hung 21/11/2020 DOO-5035
                
                woli.Status == TS_Constants.STATUS_COMPLETED && //Xen Reyes Nov. 19, 2018 
                woli.ClickNotified__c == false && //Karen Hung Apr.16, 2019 KTS-2681 Added filter
                woli.WorkOrderLineItemType__c ==  TS_Constants.TYPE_TASK && //Karen Hung Apr.18, 2019 KTS-2681
                isAttachPDFBatch == false //Xen Reyes Jan. 9, 2019 - To isolate ATTACH PDF Batch

                ) {
                        
                    //notifyClick
                    integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
                            Object__c = INT_Constants.CLICK_NOTIFICATION,
                            Integration_Status__c = INT_Constants.INITIAL,
                            Work_Order_Line_Item__c = woli.Id,
                            Triggered_Timestamp__c = Datetime.now()));

                    //Karen Hung Apr. 16, 2019 KTS-2681 Set ClickNotified to True in WOLI
                    WoliToBeUpdated = new WorkOrderLineItem(Id=woli.Id);
                    WoliToBeUpdated.ClickNotified__c = true;

                    if(woliToUpdateMap.containsKey(WoliToBeUpdated.Id)){
                        woliToUpdateMap.get(WoliToBeUpdated.id).ClickNotified__c = true;
                    } else{
                        woliToUpdateMap.put(WoliToBeUpdated.id,WoliToBeUpdated);
                    }

            }

            //**********************************************************************//
            //DOO-4825 Francis Allen Alindogan 09/03/2020
            //**********************************************************************//
            if(Label.TS_ClickReadyDefaultToFalse != null && Boolean.valueOf(Label.TS_ClickReadyDefaultToFalse) == true){                
                if(!woliToUpdateMap.containsKey(woli.Id)){
                    if(woli.ClickReady__c == true && isCaseSalesOrder == false && !caseIsAddReqPartsAndSvcMtrls){ //DOO-4942 09/29/2020 Francis Allen Alindogan DOO-5123 Xen Reyes Dec. 2, 2020
                        WoliToBeUpdated = new WorkOrderLineItem(Id = woli.Id);
                        WoliToBeUpdated.ClickReady__c = false;
                        woliToUpdateMap.put(WoliToBeUpdated.Id, WoliToBeUpdated);
                    }
                }   
            }                    
        }

        CustomLogging.pop();
        return integLogsList;
    }

    /**
    * @author        Rey Austral
    * @date          05.05.2017
    * @description   Method responsible for converting Base64 Value to Attachments
    * @revision(s)
    */
    public void createSignatureAttachments(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        CustomLogging.push('createSignatureAttachments', 'WorkOrderLineItemTriggerHandler');
        List<Attachment> attachmentList = new List<Attachment>();
        List<WorkOrderLineItem> woliToUpdateList = new List<WorkOrderLineItem>();

        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList) {
            Boolean hasSignature = false;

            //For update scenario
            if (oldRecordMap != null) {
                WorkOrderLineItem oldWoli = (WorkOrderLineItem)oldRecordMap.get(woli.Id);

                if (!String.isBlank(woli.QuotingSignature__c) && woli.QuotingSignature__c != oldWoli.QuotingSignature__c) {
                    attachmentList.add( generateAttachment(INT_Constants.CLICK_QUOTESIGNATUREFILE, woli, woli.QuotingSignature__c) );
                    hasSignature = true;
                }

                if (!String.isBlank(woli.Signature__c) && woli.Signature__c != oldWoli.Signature__c) {
                    attachmentList.add( generateAttachment(INT_Constants.CLICK_SIGNATUREFILE, woli, woli.Signature__c) );
                    hasSignature = true;
                }

                //For insert scenario
            } else {
                if (!String.isBlank(woli.QuotingSignature__c)) {
                    attachmentList.add( generateAttachment(INT_Constants.CLICK_QUOTESIGNATUREFILE, woli, woli.QuotingSignature__c) );
                    hasSignature = true;
                }
                if (!String.isBlank(woli.Signature__c)) {
                    attachmentList.add( generateAttachment(INT_Constants.CLICK_SIGNATUREFILE, woli, woli.Signature__c) );
                    hasSignature = true;
                }
            }

            if(hasSignature == true) {
                woliToUpdateList.add(new WorkOrderLineItem(Id = woli.Id, HasSignature__c = true));
            }
        }

        if(!attachmentList.isEmpty() && Schema.sObjectType.Attachment.isCreateable()) {
            try {
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                }

                insert attachmentList;
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }

            try {
                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_WoliTriggerHandlerException('Force to throw an exception');
                }

                if(Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
                    update woliToUpdateList;
                }
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Rey Austral
    * @date          05.05.2017
    * @description   Method responsible for converting Base64 Value to Attachments
    * @revision(s)
    */
    public Attachment generateAttachment(String attachmentName, WorkOrderLineItem woli, String blobString) {
        Attachment attachmentImage = new Attachment();
        attachmentImage.parentId = woli.id;
        attachmentImage.name = attachmentName.replace(' ','') + '_'+woli.JDELineItemNumber__c+'.png';
        attachmentImage.description = attachmentName;
        blob fileContent = EncodingUtil.base64Decode(blobString);
        attachmentImage.body = fileContent;

        //System.debug('XEN 11/7 attachmentImage: ' + attachmentImage);
        return attachmentImage;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          5.17.2017
    * @description   Method responsible in updating case 'within sla' field
    * @revision(s)   Archi 29 March 2018 added Boolean isOperatingTask --> no case update needed.
    */
    public void updateCaseSLAs(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        Map<Id, Boolean> caseMap = new Map<Id, Boolean>();
        Map<Id, Id> woliMap = new Map<Id, Id>();
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> checkWorkOrderId = new Set<Id>();
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_COUNTERREADING).getRecordTypeId();

        //Filter
        for (WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList) {
            WorkOrderLineItem oldWOli = (WorkOrderLineItem) oldRecordMap.get(woli.Id);
            Boolean isOperatingTask = woli.RecordtypeId.equals(CONST_WOLI_CHILD_CR_RT) || (woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP );
            if (!isOperatingTask && woli.WithinSLA__c != oldWOli.WithinSLA__c) {
                workOrderIds.add(woli.WorkOrderId);
            }
        }

        //Check if list of work order line item contains changes on WithinSLA__c field
        if (!workOrderIds.isEmpty()) {
            for (WorkOrder wo :[SELECT Id,
            (SELECT Status, WorkOrderId, WorkOrder.CaseId, WithinSLA__c
            FROM WorkOrderLineItems)
            FROM WorkOrder
            WHERE Id IN :workOrderIds]) {

                List<WorkOrderLineItem> woliList = wo.WorkOrderLineItems;
                Integer countWoli = 0;

                for (WorkOrderLineItem woli: woliList) {
                    if (woli.WithinSLA__c) {
                        if (checkWorkOrderId.add(woli.WorkOrderId))
                            woliMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                        countWoli++;
                    } else {
                        if (checkWorkOrderId.add(woli.WorkOrderId))
                            woliMap.put(woli.WorkOrderId, woli.WorkOrder.CaseId);
                        break;
                    }
                }

                if (woliList.size() == countWoli) {
                    caseMap.put(woliMap.get(wo.Id), true);
                } else {
                    caseMap.put(woliMap.get(wo.Id), false);
                }
            }

            List<Case> cases = [SELECT Id, WithinSLA__c FROM Case WHERE Id =: caseMap.keySet()];
            List<Case> caseToUpdate = new List<Case>();

            for (Case cse: cases) {
                cse.WithinSLA__c = caseMap.get(cse.Id);
                caseToUpdate.add(cse);
            }

            if(!caseToUpdate.isEmpty() && Schema.sObjectType.Case.isUpdateable()) {
                update caseToUpdate;
            }
        }
    }

    /**
    * @author        Rey Austral
    * @date          6.29.2017
    * @description   Method responsible for checking if there are change in the fields
    * @revision(s)   3 April 2018 updated by Archi
    */
    @TestVisible
    private Boolean validateIfHasChanges(WorkOrderLineItem currentWoli, WorkOrderLineItem oldWoli,  String woliFieldSet ) {
        Boolean result = false;
        //woliFieldSet='ClickWOLIFieldSet'
        for(Schema.FieldSetMember fields :Schema.SObjectType.WorkOrderLineItem.fieldSets.getMap().get(woliFieldSet).getFields()) {
            //System.debug('### OUTSIDE NEW  ' + fields.getFieldPath() + ':' + currentWoli.get(fields.getFieldPath()));
            //System.debug('### OUTSIDE OLD  ' + fields.getFieldPath() + ':' + oldWoli.get(fields.getFieldPath()));
            if(currentWoli.get(fields.getFieldPath()) != oldWoli.get(fields.getFieldPath())) {
                //System.debug('### NEW fields.getFieldPath() ' + fields.getFieldPath() + ':' + currentWoli.get(fields.getFieldPath()));
                //System.debug('### OLD fields.getFieldPath() ' + fields.getFieldPath() + ':' + oldWoli.get(fields.getFieldPath()));
                result = true;
                break;
            }
        }
        return result;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          8.29.2017
    * @description   Method responsible for populating case child work order line item
    * @revision(s)   Archi 29 March 2018: added Boolean isOperatingTask  to filter out operating task and counter reading--> they need no case
    */
    private void insertCaseOnChildWoli(List<SObject> newList) {
        CustomLogging.push('insertCaseOnWoli', 'WorkOrderLineItemTriggerHandler');
        Map<Id, Id> woliParentMap = new Map<Id, Id>();
        String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADING).getRecordTypeId();
        //Iterate parent work order Ids
        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
            Boolean isOperatingTask = (woli.RecordtypeId.equals(CONST_WOLI_CHILD_CR_RT) || (woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING || woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP));

            Boolean isRouteSales =  woli.WorkOrderType__c == TS_Constants.TYPE_S25_ROUTESALES;

            if (! (isOperatingTask||isRouteSales) && woli.Case__c == null && woli.ParentWorkOrderLineItemId != null) {
                woliParentMap.put(woli.ParentWorkOrderLineItemId, woli.ParentWorkOrderLineItemId);
            }
        }

        //Update child woli's case using parent work order line item
        if (!woliParentMap.isEmpty()) {
            for (WorkOrderLineItem pWoli: [SELECT Id, Case__c FROM WorkOrderLineItem WHERE Id =:woliParentMap.keySet()]) {
                for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList) {
                    if (woli.ParentWorkOrderLineItemId != null
                            && woliParentMap.get(woli.ParentWorkOrderLineItemId) != null) {
                        woli.Case__c = pWoli.Case__c;
                    }
                }
            }
        }

        CustomLogging.pop();
    }


    /**
    * @author        Abram Vixen Reyes
    * @date          19.10.2018
    * @description   Method to check if a WOLI should be scheduled manually using Manual_Account_Location_Indicators__c field in WOLI.
    * @revision(s)   04.06.2018: Marvin Gatchalian - Added else block to set ScheduleManually__c value from TS_Is_Schedule_Manually__c
    */
    public void checkifScheduleManually(List<SObject> newList) {
        CustomLogging.push('checkifScheduleManually', 'WorkOrderLineItemTriggerHandler');
        Id tsWOLIRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_REGTASK);
        Id addService = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_ADDSERVICE);

        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.RecordTypeId == tsWOLIRecordType || woli.RecordTypeId == addService){

                /* XEN REYES Feb. 19, 2019 KTS-2627 */
                if(woli.RemoveScheduleRestrictions__c){
                    woli.ScheduleManually__c = false;
                } else if(woli.Manual_Account_Location_Indicators__c && woli.ScheduleManually__c != true){
                    woli.ScheduleManually__c = true;
                }
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Adrian Reyes
    * @date          23.02.2018
    * @description   Method to reschedule work order line items
    * @revision(s)
    */
    void rescheduleWorkOrderLineItems(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('rescheduleWorkOrderLineItems', 'WorkOrderLineItemTriggerHandler');
        Set<Id> caseIDs = new Set<Id>();
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
        Map<Id, WorkOrder> woToUpdateMap = new Map<Id, WorkOrder>();

        for(WorkOrderLineItem workOrderLineItem: (List<WorkOrderLineItem>) newList){
            WorkOrderLineItem oldWorkOrderLineItem = (WorkOrderLineItem) oldMapItems.get(workOrderLineItem.Id);
            if(workOrderLineItem.Reschedule__c && workOrderLineItem.Reschedule__c != oldWorkOrderLineItem.Reschedule__c){
                caseIDs.add(workOrderLineItem.Case__c);
                workOrderLineItems.add(workOrderLineItem);
            }
        }

        if(!workOrderLineItems.isEmpty()){
            //Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Click__c FROM Case WHERE Id IN: caseIDs]);
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.StartDate__c = null;
                workOrderLineItem.Roundtrip__c = false;
                workOrderLineItem.EndDate__c = null;
                workOrderLineItem.Status = TS_Constants.WOLI_STATUS_OPEN; //XEN REYES 10.31.2018 !caseMap.get(workOrderLineItem.Case__c).Click__c ? TS_Constants.WOLI_STATUS_SCHEDULED : TS_Constants.WOLI_STATUS_OPEN
                workOrderLineItem.ETA__c = null;
                workOrderLineItem.ATA__c = null;
                workOrderLineItem.BookAppointmentStart__c = null;
                workOrderLineItem.BookAppointmentFinish__c = null;
                workOrderLineItem.Installation_Date_S40__c = null;
                workOrderLineItem.DeInstallationDateS41__c = null;
                workOrderLineItem.ConfigurationDateS43__c = null;
                //workOrderLineItem.ScheduleManually__c = true;
                workOrderLineItem.Reschedule__c = false;    //Untick the checkbox
                workOrderLineItem.ExecutingEngineer__c = null; //XEN REYES 10.31.2018

                if(!woToUpdateMap.containsKey(workOrderLineItem.WorkOrderId)){
                    WorkOrder updateWoUnschedule = new WorkOrder(Id = workOrderLineItem.WorkOrderId, ETA_Sent__c = false, ATA_Sent__c = false);
                    woToUpdateMap.put(workOrderLineItem.WorkOrderId, updateWoUnschedule);
                }
            }

            if(!woToUpdateMap.values().isEmpty()){
                try{
                    update woToUpdateMap.values();
                } catch (Exception e) {
                    System.debug(e);
                }
            }
        }

        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          22.9.2018
    * @description   Method to flush rescheduling fields - KTS-2081
    * @revision(s)
    */

    public void rescheduleEngineerTaskUpdates(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('rescheduleEngineerTaskUpdates', 'WorkOrderLineItemTriggerHandler');

        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_REGTASK).getRecordTypeId();
        Map<Id, WorkOrder> woToUpdateMap = new Map<Id, WorkOrder>();

        for(WorkOrderLineItem workOrderLineItem: (List<WorkOrderLineItem>) newList){

            WorkOrderLineItem oldWorkOrderLineItem = (WorkOrderLineItem) oldMapItems.get(workOrderLineItem.Id);
            if(workOrderLineItem.RecordTypeId == taskId && oldWorkOrderLineItem.RecordTypeId == taskId && 
               extWoliNewMap.get(workOrderLineItem.Id).Case__c != null && extWoliNewMap.get(workOrderLineItem.Id).Case__r.Click__c != true){ //DOO-5403 Francis Allen Alindogan 03/03/20201 

                //CHECK IF ACTUAL START DATE IS CHANGED - ONLY DATE
                Date dtStartNew = workOrderLineItem.StartDate__c != null ? workOrderLineItem.StartDate__c.date() : null;
                Date dtStartOld = oldWorkOrderLineItem.StartDate__c != null ? oldWorkOrderLineItem.StartDate__c.date() : null;

                if(dtStartNew != dtStartOld && dtStartNew != null && dtStartOld != null &&
                        (workOrderLineItem.Status != TS_Constants.STATUS_COMPLETED && workOrderLineItem.Status != TS_Constants.STATUS_CANCELED && workOrderLineItem.Status != TS_Constants.WOLI_STATUS_REVIEW)
                        ){
                    workOrderLineItem.ETA__c = null;
                    workOrderLineItem.ATA__c = null;
                    workOrderLineItem.Installation_Date_S40__c = null;
                    workOrderLineItem.DeInstallationDateS41__c = null;
                    workOrderLineItem.ConfigurationDateS43__c = null;

                    WorkOrder updateWo = new WorkOrder(Id = workOrderLineItem.WorkOrderId, ETA_Sent__c = false, ATA_Sent__c = false);
                    woToUpdateMap.put(workOrderLineItem.WorkOrderId, updateWo);
                }

                //IF THE ENGINEER IS CHANGED, THE STATUS SHOULD BE OPEN OR SCHEDULED
                if(workOrderLineItem.ExecutingEngineer__c != oldWorkOrderLineItem.ExecutingEngineer__c && workOrderLineItem.ExecutingEngineer__c != null &&
                        (workOrderLineItem.Status != TS_Constants.WOLI_STATUS_OPEN && workOrderLineItem.Status != TS_Constants.WOLI_STATUS_SCHEDULED)){
                    workOrderLineItem.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                }

            }


        }

        if(!woToUpdateMap.values().isEmpty()){
            try{
                update woToUpdateMap.values();
            } catch (Exception e) {
                System.debug(e);
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author         Abram Vixen Reyes
    * @date           18.02.2018
    * @description    Without Sharing inner class for WorkOrderLineItemTriggerHandler
    * @revision(s)
    */
    public without sharing class woliTriggerHandlerClassWithoutSharing {

        //WITHOUT SHARING CLASS FOR CASE CLOSE METHOD
        public void caseCloseMethod(List<SObject> newList, Map<Id, SObject> oldRecordMap){

            CustomLogging.push('woliTriggerHandlerClassWithoutSharing.caseCloseMethod', 'WorkOrderLineItemTriggerHandler');
            List<Apttus_Config2__OrderLineItem__c> orderLineList = new List<Apttus_Config2__OrderLineItem__c>();

            for (WorkOrderLineItem newWoli: (List<WorkOrderLineItem>) newList) {
                WorkOrderLineItem oldWoli = oldRecordMap != null? (WorkOrderLineItem) oldRecordMap.get(newWoli.Id) : null;

                //Update scenario for 'Task' Work Order Line Item Type
                if (oldWoli != null && newWoli.Status != oldWoli.Status && newWoli.Status == TS_Constants.STATUS_COMPLETED
                        && newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK
                        && newWoli.OrderLineItem__c != null
                        && extWoliNewMap.containsKey(newWoli.Id)
                        && extWoliNewMap.get(newWoli.Id).Case__c != null
                        && extWoliNewMap.get(newWoli.Id).Case__r.Type == TS_Constants.CASE_TYPE_FIELDSERVICE)
                {


                    //Ata: Added conditions for movement scenario
                    //Installation Subtype Label.TS_Order_Instype_Installation
                    if ((extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.ORDER_S40 ||
                            extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.CASE_SUBTYPE_SWAP ||
                            extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.ORDER_INSTYPE_MOVEMENT) && 
                            newWoli.WorkOrderType__c == TS_Constants.ORDER_S40 &&
                            ((newWoli.ReturnNeeded__c == true && newWoli.Return_Needed_S10__c == true) || newWoli.ReturnNeeded__c == false))//Francis Allen Alindogan 11/14/2019 DOO-870 to check if NOT closed as S40 or S41 with return type S10)
                    {

                        Apttus_Config2__OrderLineItem__c orderLine = new Apttus_Config2__OrderLineItem__c();
                        orderLine.Id = newWoli.OrderLineItem__c;
                        //orderLine.APTS_Installation_Date__c = newWoli.EndDate__c; XEN 2/5
                        orderLine.APTS_Installation_Date_Authorized__c = newWoli.EndDate__c;
                        orderLineList.add(orderLine);

                        // Ata: Added conditions for movement scenario
                        //De-Installation Subtype
                    } else if ((extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.ORDER_S41 ||
                            extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.CASE_SUBTYPE_SWAP ||
                            extWoliNewMap.get(newWoli.Id).Case__r.SubType__c == TS_Constants.ORDER_INSTYPE_MOVEMENT) &&
                            newWoli.WorkOrderType__c == TS_Constants.ORDER_S41 &&
                            ((newWoli.ReturnNeeded__c == true && newWoli.Return_Needed_S10__c == true) || newWoli.ReturnNeeded__c == false))//Francis Allen Alindogan 11/14/2019 DOO-870 to check if NOT closed as S40 or S41 with return type S10)
                    {

                        Apttus_Config2__OrderLineItem__c orderLine = new Apttus_Config2__OrderLineItem__c();
                        orderLine.Id = newWoli.OrderLineItem__c;
                        //orderLine.APTS_De_installation_Date__c = Date.valueOf(newWoli.EndDate__c); XEN 2/5
                        orderLine.APTS_De_installation_Date_Authorized__c = Date.valueOf(newWoli.EndDate__c);
                        orderLineList.add(orderLine);
                    } 
                }
            }

            if (!orderLineList.isEmpty()) {
                //update orderLineList;
                
                TS_QueueableProcesses varProcess = new TS_QueueableProcesses();
                varProcess.METHOD_UPDATE_ORDERLINEITEM_AUTHORIZED = true;
                varProcess.orderLineList = orderLineList;
                System.enqueueJob(varProcess);
            }

            CustomLogging.pop();
        }

        //WITHOUT SHARING CLASS FOR PROVIDING ENGINEER ACCESS
        public void provideEngineerAccessWithoutSharing(List<SObject> newList, Map<Id, SObject> oldMapItems){

            CustomLogging.push('woliTriggerHandlerClassWithoutSharing.provideEngineerAccessWithoutSharing', 'WorkOrderLineItemTriggerHandler');

            /* XEN REYES KTS-2595 Feb 14, 2019*/
            /* Boolean isCommunityUser = false;
            if(UserInfo.getUserType() != 'Standard') isCommunityUser = true; */

            Set<Id> woliIds = new Set<Id>();
            List<PhysicalAsset__Share> phyList = new List<PhysicalAsset__Share>();
            List<CaseShare> caseList = new List<CaseShare>();
            List<WorkOrderShare> woList = new List<WorkOrderShare>();
            List<AccountShare> accLocList = new List<AccountShare>();
            List<ContactShare> contactList = new List<ContactShare>(); //Karen Hung 12/7/2018

            //Xen Reyes Oct 22, 2018
            List<Resource__Share> resourceList = new List<Resource__Share>();

            //Collect scheduled tasks using status = 'Scheduled'
            for(WorkOrderLineItem newWoli: (List<WorkOrderLineItem>) newList){
                WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldMapItems?.get(newWoli.Id);


                //Check if status engineer has changed. XEN REYES Oct. 5, 2018 KTS-2183
                if ((newWoli.ExecutingEngineer__c != oldWoli?.ExecutingEngineer__c && newWoli.ExecutingEngineer__c != null) ||
                    //Karen Hung 22/2/2021 DOO-5307
                    (reinitiateAccessEnabled && newWoli.ExecutingEngineer__c !=null && (newWoli.WorkOrderLineItemType__c == TS_Constants.TS_Type_Task || newWoli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE))                    
                    //XEN REYES Nov. 18, 2019 - DOO-2692
                    || (newWoli.PhysicalAsset__c != oldWoli?.PhysicalAsset__c && newWoli.PhysicalAsset__c != null)
                    ){
                    woliIds.add(newWoli.Id);
                }
            }

            //Query scheduled task to get seconde level fields for the engineers related user
            if (!woliIds.isEmpty()) {
                //Updated criteria. XEN REYES Oct. 5, 2018 KTS-2183
                //Karen Hung added fields(case account, case contact and case secondary contact) in query 12/7/2018
                for (WorkOrderLineItem woli: [SELECT Case__c, Case__r.AccountId, Case__r.Contact.AccountId, Case__r.SecondaryContact__r.AccountId,
                        PhysicalAsset__c, WorkOrderId, AccountLocation__c,
                        AccountLocation__r.Apttus_Config2__AccountId__c,
                        ExecutingEngineer__c, ExecutingEngineer__r.RelatedUser__c
                FROM WorkOrderLineItem
                WHERE ExecutingEngineer__r.RelatedUser__c != null
                AND Id IN :woliIds]) {

                    

                    Id userId = woli.ExecutingEngineer__r.RelatedUser__c;
                    Set<String> accountIds = new Set<String>();

                    //Give edit access to related user for physical asset record
                    if (woli.PhysicalAsset__c != null) {
                        PhysicalAsset__Share phyShare = new PhysicalAsset__Share();
                        phyShare.ParentId = woli.PhysicalAsset__c;
                        phyShare.UserOrGroupId = userId;
                        phyShare.AccessLevel = TS_Constants.SHARING_ACCESSLEVEL_EDIT;
                        phyShare.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                        phyList.add(phyShare);
                    }

                    //Give edit access to related user for case record
                    if (woli.Case__c != null) {
                        CaseShare cseShare = new CaseShare();
                        cseShare.CaseId = woli.Case__c;
                        cseShare.UserOrGroupId = userId;
                        cseShare.CaseAccessLevel = TS_Constants.SHARING_ACCESSLEVEL_EDIT;
                        cseShare.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                        caseList.add(cseShare);
                    }

                    //Give edit access to related user for work order record
                    if (woli.WorkOrderId != null) {
                        WorkOrderShare wOrderShare = new WorkOrderShare();
                        wOrderShare.ParentId = woli.WorkOrderId;
                        wOrderShare.UserOrGroupId = userId;
                        wOrderShare.AccessLevel = TS_Constants.SHARING_ACCESSLEVEL_EDIT;
                        wOrderShare.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                        woList.add(wOrderShare);
                    }

                    //Give read access to related user for account location record
                    if (woli.AccountLocation__c != null && woli.AccountLocation__r.Apttus_Config2__AccountId__c != null) {
                        accountIds.add(woli.AccountLocation__r.Apttus_Config2__AccountId__c);
                    }

                    //Karen Hung 12/7/2018
                    //Give read access to related user for case account
                    if(woli.Case__c != null && woli.Case__r.AccountId !=null){
                        accountIds.add( woli.Case__r.AccountId);
                    }

                    //Karen Hung 12/7/2018
                    //Give read access to related user for case contact (through parent account access)
                    if(woli.Case__c != null && woli.Case__r.ContactId !=null && woli.Case__r.Contact.AccountId !=null){
                        accountIds.add(woli.Case__r.Contact.AccountId);
                    }

                    //Karen Hung 12/7/2018
                    //Give read access to related user for case secondary contact(through parent account access)
                    if(woli.Case__c != null && woli.Case__r.SecondaryContact__r != null && woli.Case__r.SecondaryContact__r.AccountId !=null){
                        accountIds.add(woli.Case__r.SecondaryContact__r.AccountId);
                    }

                    List<String> accList = new List<String>();

                    if(!accountIds.isEmpty()){
                        accList.addAll(accountIds);
                        for(Integer i=0; i<accList.size(); i++){
                            AccountShare accAccess = new AccountShare();
                            accAccess.AccountId = accList[i];
                            accAccess.UserOrGroupId = userId;
                            accAccess.AccountAccessLevel = TS_Constants.SHARING_ACCESSLEVEL_READ;
                            accAccess.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                            accAccess.OpportunityAccessLevel = TS_Constants.SHARING_ACCESSLEVEL_NONE;
                            accLocList.add(accAccess);
                        }
                    }

                    //Xen Reyes Oct 22, 2018
                    //Give read access to related user for the resource record
                    if (woli.ExecutingEngineer__c != null) {
                        Resource__Share resourceShare = new Resource__Share();
                        resourceShare.ParentId = woli.ExecutingEngineer__c;
                        resourceShare.UserOrGroupId = userId;
                        resourceShare.AccessLevel = TS_Constants.SHARING_ACCESSLEVEL_READ;
                        resourceShare.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                        resourceList.add(resourceShare);
                    }
                }
            }

            //Update sharing list for Physical Asset
            if (!phyList.isEmpty()) {
                try {
                    insert phyList;
                } catch (Exception e){
                    System.debug('PhysicalAsset__Share');
                    System.debug(e);
                }

            }

            //Update sharing list for Case
            if (!caseList.isEmpty()) {
                try {
                    insert caseList;
                } catch (Exception e){
                    System.debug('CaseShare');
                    System.debug(e);
                }
            }

            //Update sharing list for Work Order
            if (!woList.isEmpty()) {
                try {
                    insert woList;
                } catch (Exception e){
                    System.debug('WorkOrderShare');
                    System.debug(e);
                }

            }

            //Update sharing list for Account
            if (!accLocList.isEmpty()) {
                try {
                    insert accLocList;
                } catch (Exception e){
                    System.debug('AccountShare');
                    System.debug(e);
                }
            }

            //Xen Reyes Oct 22, 2018
            //Update sharing list for Resource
            if (!resourceList.isEmpty()) {
                try {
                    insert resourceList;
                } catch (Exception e){
                    System.debug('Resource__Share');
                    System.debug(e);
                }
            }
            
            engineerAccessProcessed = true;
			
            CustomLogging.pop();
        }

    }

    /**
    * @author        Francis Allen Alindogan
    * @date          07.08.2020
    * @description   
    * @revision(s)   
                v1.0 Method to check internal SAP order. Update TS_CloseTaskWOLI Lightning component if criteria will be adjusted. 04.7.2018 Vixen Reyes
                v2.0 Changed method name from checkInternalOrderSAP to checkForReviewNeededCriteria.
                     Refactored by including checking of Date Intervals for Work and Travel time. Update TS_CloseTaskWOLI and TS_ReviewNeeded Lightning component if criteria will be adjusted. 07.08.2020 Francis Allen Alindogan
    */
    public void checkForReviewNeededCriteria (List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('checkForReviewNeededCriteria', 'WorkOrderLineItemTriggerHandler');        
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        Id CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();

        for(WorkOrderLineItem woli: (List<WorkOrderLineItem>) newList){
            WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldMapItems.get(woli.Id);
            Boolean isSetToReviewNeededInternally = false;
            Boolean isOperatingOrRouteTask = woli.RecordtypeId.equals(CONST_WOLI_CHILD_CR_RT) ||
                    woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE ||
                    woli.WorkOrderType__c == TS_Constants.WO_TYPE_S21_COUNTERREADING ||
                    woli.WorkOrderType__c == TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP ||
                    woli.WorkOrderType__c == TS_Constants.TYPE_S25_ROUTESALES ||

                    //XEN REYES DOO-4330 April 8, 2020
                    woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI;

            //CHECK INTERNAL ORDER SAP
            if(woli.RecordTypeId == taskId && oldWoli.Status != woli.Status && woli.Status == TS_Constants.STATUS_COMPLETED && woli.InternalOrderSAP__c == null && !isOperatingOrRouteTask ){
                isSetToReviewNeededInternally = true;
                woli.Status = TS_Constants.WOLI_STATUS_REVIEW;
                woli.ReviewNeeded__c = true;
                woli.InternalCompletionNote__c = woli.InternalCompletionNote__c == null ? TS_Constants.INTERNALCOMPLETION_INTERNALORDERMISSING : woli.InternalCompletionNote__c + '\n' + TS_Constants.INTERNALCOMPLETION_INTERNALORDERMISSING;
            }

            //CHECK DATE INTERVALS
            if(woli.WorkOrderLineItemType__c == TS_Constants.TS_Type_Task && oldWoli.Status != woli.Status && !isOperatingOrRouteTask && 
                (
                woli.Status == TS_Constants.STATUS_COMPLETED && oldWoli.Status != TS_Constants.WOLI_STATUS_REVIEW || //FOR GENERAL THRESHOLD SCENARIOS
                woli.Status == TS_Constants.WOLI_STATUS_REVIEW && isSetToReviewNeededInternally == false && String.isBlank(OldWoli.InternalCompletionNote__c) ||//FOR EXPLICIT SET REVIEW NEEDED + THRESHOLD SCENARIO
                isSetToReviewNeededInternally == true // FOR INTERNAL ORDER SAP + THRESHOLD SCENARIO
                ) && 
                    (
                        (woli.Travel_Start_Time__c != null 
                         && woli.Travel_Stop_Time__c != null 
                         && (woli.Travel_Stop_Time__c.getTime() - woli.Travel_Start_Time__c.getTime()) > Integer.valueOf(Label.TS_Travel_Duration_Limit)*3600000) || //TRAVEL DATETIME HAS EXCEEDED THRESHOLD
                        
                        (woli.StartDate__c != null
                         && woli.EndDate__c != null 
                         && (woli.EndDate__c.getTime() - woli.StartDate__c.getTime()) > Integer.valueOf(Label.TS_Work_Duration_Limit)*3600000) || //WORK DATETIME HAS EXCEEDED THRESHOLD
                        
                        !(woli.Travel_Start_Time__c.isSameDay(woli.Travel_Stop_Time__c) 
                          && woli.Travel_Stop_Time__c.isSameDay(woli.StartDate__c) 
                          && woli.StartDate__c.isSameDay(woli.EndDate__c)) //THE 4 DATES ARE NOT THE SAME
                    )
            ){
                woli.Status = TS_Constants.WOLI_STATUS_REVIEW;
                woli.ReviewNeeded__c = true;
                woli.InternalCompletionNote__c = woli.InternalCompletionNote__c == null ? TS_Constants.INTERNALCOMPLETION_TIMETHRESHHOLDEXCEED : woli.InternalCompletionNote__c + '\n' + TS_Constants.INTERNALCOMPLETION_TIMETHRESHHOLDEXCEED;                
            }

        }
        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          01.8.2018
    * @description   Method to update the Account Location: Last Routesales Date of a completed WOLI.
    * @revision(s)
    */

    public void updateLastRouteSalesDateAccountLocation(List<SObject> newList, Map<Id, SObject> oldListMap) {

        CustomLogging.push('updateLastRouteSalesDateAccountLocation', 'WorkOrderLineItemTriggerHandler');

        Set<Id> accLocationIdSet = new Set<Id>();
        List<WorkOrderLineItem> completedS25woliList = new List<WorkOrderLineItem>();
        Map<Id, Apttus_Config2__AccountLocation__c> accLocationToUpdateMap = new Map<Id, Apttus_Config2__AccountLocation__c>();

        //GET ALL COMPLETED && ROUTESALES WOLIs
        for(WorkOrderLineItem wo : (List<WorkOrderLineItem>) newList){
            WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldListMap.get(wo.Id);
            if(wo.WorkOrderType__c == TS_Constants.TYPE_S25_ROUTESALES && oldWoli.Status != wo.Status && wo.Status == TS_Constants.STATUS_COMPLETED){
                completedS25woliList.add(wo);
                accLocationIdSet.add(wo.AccountLocation__c);
            }
        }

        if(!accLocationIdSet.isEmpty()){
            //Karen Hung 1.3.19 RouteSales change, added RoutesalesInterval__c
            accLocationToUpdateMap = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, RoutesalesInterval__c, LastRoutesalesDate__c FROM Apttus_Config2__AccountLocation__c WHERE Id IN:accLocationIdSet]);

            if(!accLocationToUpdateMap.isEmpty() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.isUpdateable()){
                for(WorkOrderLineItem wo : completedS25woliList){
                    //Karen Hung  1.3.19 RouteSales change, added RoutesalesInterval Filter
                    if(accLocationToUpdateMap.containsKey(wo.AccountLocation__c) && wo.EndDate__c != null && accLocationToUpdateMap.get(wo.AccountLocation__c).RoutesalesInterval__c != 1){
                        accLocationToUpdateMap.get(wo.AccountLocation__c).LastRoutesalesDate__c = wo.EndDate__c.date();
                        isRSTaskFlushReady = true; //Francis Allen Alindogan DOO-4256 03/17/2020
                    }
                }

                //System.debug('XEN 8/1 accLocationToUpdateMap.values(): ' + accLocationToUpdateMap.values());

                try{
                    update accLocationToUpdateMap.values();
                } catch (Exception e){
                    System.debug(e.getMessage());
                }
            }
        }

        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          06.8.2018
    * @description   Method to check that there should only be one active per type of WOLI under a case.
    * @revision(s)
    */

    public void checkActiveWOLI(List<SObject> newList) {

        CustomLogging.push('checkActiveWOLI', 'WorkOrderLineItemTriggerHandler');

        Set<Id> caseToCheckSet = new Set<Id>();
        List<WorkOrderLineItem> lineItemToCheckList = new List<WorkOrderLineItem>();
        List<String> listofType = new List<String>{TS_Constants.TYPE_TASK, TS_Constants.TS_WOLI_RECORDTYPE_COUNTERREADING};
        List<String> listofwoType = new List<String>{TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI, TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI, TS_Constants.TYPE_S30_PREVMAINTENANCE, TS_Constants.TYPE_S31_PRECHECK, TS_Constants.TYPE_S32_WATERFILTER, TS_Constants.WO_TYPE_S21_COUNTERREADING, TS_Constants.TYPE_S25_ROUTESALES};
        Map<Id, List<WorkOrderLineItem>> caseIdWOLIToCheckMap = new Map<Id, List<WorkOrderLineItem>>();

        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_REGTASK).getRecordTypeId();
        Id addJobId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_ADDSERVICE).getRecordTypeId();

        //GET ALL CASE IDS TO QUERY ITS WOLIS
        for(WorkOrderLineItem wo : (List<WorkOrderLineItem>) newList){
            caseToCheckSet.add(wo.Case__c);
        }

        if(!caseToCheckSet.isEmpty()){

            //QUERY ALL WOLIS ON EACH CASE AND CREATE A MAP OUT OF IT
            //Added RecordTypeId, ParentWorkOrder && Case to exclude parts 11.09.2018 KTS-2110 //Karen Hung 03/08/19 only include NON-ReturnTask__c KTS-2660
            lineItemToCheckList = [SELECT Id, Case__c, WorkOrderType__c, RecordTypeId FROM WorkOrderLineItem WHERE ReturnTask__c = false AND (Case__c IN: caseToCheckSet AND WorkOrderLineItemType__c IN: listofType AND WorkOrderType__c IN: listofwoType AND Status !=: TS_Constants.STATUS_COMPLETED AND Status !=: TS_Constants.STATUS_CANCELED AND RecordTypeId =: taskId AND ParentWorkOrderLineItemId = NULL AND Case__c != NULL)];

            //MAP OF CASES AGAINST ITS LIST OF WOLIS
            if(!lineItemToCheckList.isEmpty()){
                for(WorkOrderLineItem wo : lineItemToCheckList){
                    if(caseIdWOLIToCheckMap.containsKey(wo.Case__c)){
                        caseIdWOLIToCheckMap.get(wo.Case__c).add(wo);
                    } else {
                        caseIdWOLIToCheckMap.put(wo.Case__c, new List<WorkOrderLineItem>{wo});
                    }
                }

                if(!caseIdWOLIToCheckMap.isEmpty()){
                    //ITERATE WOLIS AND CHECK IF THE TYPE OF WOLI TO INSERT IS EXISTING TO THE MAP
                    for(WorkOrderLineItem wo : (List<WorkOrderLineItem>) newList){
                        if( (wo.RecordTypeId == taskId ||  wo.RecordTypeId == addJobId) && wo.ParentWorkOrderLineItemId == NULL && wo.Case__c != NULL){ //Xen Reyes 11.09.2018 KTS-2110, only compare to task not parts
                            for(WorkOrderLineItem woToCheck : caseIdWOLIToCheckMap.get(wo.Case__c)){
                                if(woToCheck.WorkOrderType__c == wo.WorkOrderType__c){
                                    wo.addError(TS_Constants.ERRORMESSAGE_ONLYONEACTIVEJOB);
                                }
                            }
                        }
                    }
                }
            }
        }

        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          Oct. 11, 2018
    * @description   Method to compute for the actual duration and actual travel time
    * @revision(s)   Karen Hung Oct. 18, 2018 KTS-2270
    */

    public void calculateActualDuration(List<SObject> newList) {

        CustomLogging.push('calculateActualDuration', 'WorkOrderLineItemTriggerHandler');

        if(UserInfo.getName() != IntegrationUserAndProfile__c.getInstance().Click_Integration_Name__c){
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
                if((woli.Status == TS_Constants.STATUS_COMPLETED || woli.Status == TS_Constants.WOLI_STATUS_REVIEW) && woli.StartDate__c != null && woli.EndDate__c != null ){
                    //Integer actualhours = Integer.valueOf(woli.EndDate__c.getTime() - woli.StartDate__c.getTime()) * 24;
                    Decimal result = Decimal.valueOf(woli.EndDate__c.getTime() - woli.StartDate__c.getTime()) / (1000 * 60 * 60);
                    Decimal rounded = result.setScale(2, RoundingMode.HALF_UP);
                    woli.ActualDuration__c = rounded;
                }

                //Karen Hung KTS-2270
                if(woli.Status == TS_Constants.STATUS_COMPLETED || woli.Status == TS_Constants.WOLI_STATUS_REVIEW){
                    if(woli.Travel_Stop_Time__c !=null && woli.Travel_Start_Time__c !=null){
                        Decimal resultTravel = Decimal.valueOf(woli.Travel_Stop_Time__c.getTime() - woli.Travel_Start_Time__c.getTime()) / (1000 * 60 * 60);
                        Decimal roundedTravel = resultTravel.setScale(2, RoundingMode.HALF_UP);
                        woli.ActualTravelTime__c = roundedTravel;
                    }
                }
            }
        }

        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          March 26, 2019
    * @description   Method to reparent the counter readings of a Large task.
    * @revision(s)
    */

    public void REPARENT_COUNTERREADING(List<SObject> newList) {

        CustomLogging.push('REPARENT_LARGE', 'WorkOrderLineItemTriggerHandler');

        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
            if(WOLI_VAR.OP_CreateParent__c){
                if(WORKORDER_COUNTEREADING_MAP.containsKey(WOLI_VAR.ParentWorkOrderLineItemId)){
                    WORKORDER_COUNTEREADING_MAP.get(WOLI_VAR.ParentWorkOrderLineItemId).add(WOLI_VAR);
                } else {
                    WORKORDER_COUNTEREADING_MAP.put(WOLI_VAR.ParentWorkOrderLineItemId, new List<WorkOrderLineItem>{WOLI_VAR});
                }
            }
        }

        if(!WORKORDER_COUNTEREADING_MAP.isEmpty()){
            LARGE_INSERT_MUTE = true;
        }

        //System.debug('REPARENT_COUNTERREADING');
        //System.debug('WORKORDER_COUNTEREADING_MAP: ' + WORKORDER_COUNTEREADING_MAP);
        
        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          March 26, 2019
    * @description   Method to get the parent Large operating task with counter reading
    * @revision(s)
    */

    public void GET_LARGE_WITH_COUNTERREADING(List<SObject> newList,  Map<Id, SObject> newMapItems) {

        CustomLogging.push('GET_LARGE_WITH_COUNTERREADING', 'WorkOrderLineItemTriggerHandler');

        List<WorkOrder> CR_WO_LIST = new List<WorkOrder>();
        List<WorkOrderLineItem> CR_WOLI_LIST = new List<WorkOrderLineItem>();
        Map<Id, WorkOrder> LARGE_WORKORDER_MAP = new Map<Id, WorkOrder>();
        Map<String, String> LOADID_WORKORDERID_MAP = new Map<String, String>();
        Set<Id> ID_LARGE_WORKORDER_SET = new Set<Id>();
        String CONST_WOLI_TASK_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
        String CONST_WORKORDER_CR_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
        String CONST_WOLI_CRTASK_TYPE = 'Counter';
        String CONST_WOLI_COMPLETED_STATUS = 'Completed';
        String CONST_WORKORDER_CR_TYPE = 'S21';
        String CONST_WOLI_TYPECR_ORDINARY = 'Ordinary';

        //System.debug('GET_LARGE_WITH_COUNTERREADING');
        //System.debug('WORKORDER_COUNTEREADING_MAP: ' + WORKORDER_COUNTEREADING_MAP);

        //System.debug('LARGE TASKS: ' + newList);

        if(!WORKORDER_COUNTEREADING_MAP.keySet().isEmpty()){

            //GET PARENT WORK ORDERS ID OF LARGE TASK AS BASIS FOR REPLICATION
            for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
                if(WOLI_VAR.WorkOrderType__c == 'S20' && WOLI_VAR.SendCounterReadingsOperating__c && WOLI_VAR.WorkOrderLineItemType__c == 'Large' && WOLI_VAR.Status == 'Completed'){
                    if(WORKORDER_COUNTEREADING_MAP.containsKey(WOLI_VAR.Id)){
                        ID_LARGE_WORKORDER_SET.add(WOLI_VAR.WorkOrderId);
                    }
                }
            }

            //System.debug('ID_LARGE_WORKORDER_SET: ' + ID_LARGE_WORKORDER_SET);

            //QUERY PARENT ORDER
            if(!ID_LARGE_WORKORDER_SET.isEmpty()){
                LARGE_WORKORDER_MAP = new Map<Id, WorkOrder>([SELECT Id, Pricebook2Id, OP_Physical_Asset__c, SalesOrganization__c, AccountId, OwnerId FROM WorkOrder WHERE Id IN: ID_LARGE_WORKORDER_SET]);
            }

            //System.debug('LARGE_WORKORDER_MAP: ' + LARGE_WORKORDER_MAP);

            //CREATE A WORK ORDER FOR S21
            for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
                if(WOLI_VAR.WorkOrderType__c == 'S20' && WOLI_VAR.SendCounterReadingsOperating__c && WOLI_VAR.WorkOrderLineItemType__c == 'Large' && WOLI_VAR.Status == 'Completed'){
                    if(WORKORDER_COUNTEREADING_MAP.containsKey(WOLI_VAR.Id) && LARGE_WORKORDER_MAP.containsKey(WOLI_VAR.WorkOrderId)){

                        //CREATE A WORK ORDER
                        WorkOrder workOrder = new WorkOrder();
                        workOrder.RecordTypeId = CONST_WORKORDER_CR_RT;
                        workOrder.WorkOrderType__c = CONST_WORKORDER_CR_TYPE;
                        workOrder.Status = 'Completed';
                        workOrder.Pricebook2Id = LARGE_WORKORDER_MAP.get(WOLI_VAR.WorkOrderId).Pricebook2Id;
                        workOrder.OP_Physical_Asset__c = LARGE_WORKORDER_MAP.get(WOLI_VAR.WorkOrderId).OP_Physical_Asset__c;
                        workOrder.SalesOrganization__c = LARGE_WORKORDER_MAP.get(WOLI_VAR.WorkOrderId).SalesOrganization__c;
                        workOrder.AccountId = LARGE_WORKORDER_MAP.get(WOLI_VAR.WorkOrderId).AccountId;
                        workOrder.OwnerId = LARGE_WORKORDER_MAP.get(WOLI_VAR.WorkOrderId).OwnerId;
                        workOrder.LoadID__c = WOLI_VAR.Id;
                        CR_WO_LIST.add(WorkOrder);
                    }
                }
            }

            //System.debug('CR_WO_LIST: ' + CR_WO_LIST);

            if(!CR_WO_LIST.isEmpty()){
                try{
                    insert CR_WO_LIST;
                    for(WorkOrder WO_VAR: CR_WO_LIST){
                        LOADID_WORKORDERID_MAP.put(WO_VAR.LoadID__c, WO_VAR.Id);
                    }
                } catch (Exception e){
                    System.debug(e);
                    CustomLogging.debugException(e);
                    CustomLogging.pop();
                }
            }

            //System.debug('LOADID_WORKORDERID_MAP: ' + LOADID_WORKORDERID_MAP);

            //CREATE A WORK ORDER LINE ITEM FOR S21
            for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
                if(WOLI_VAR.WorkOrderType__c == 'S20' && WOLI_VAR.SendCounterReadingsOperating__c && WOLI_VAR.WorkOrderLineItemType__c == 'Large' && WOLI_VAR.Status == 'Completed'){
                    if(WORKORDER_COUNTEREADING_MAP.containsKey(WOLI_VAR.Id) && !CR_WO_LIST.isEmpty() && LOADID_WORKORDERID_MAP.containsKey(WOLI_VAR.Id)){

                        //CREATE AN S21 TASK
                        WorkOrderLineItem woliTask = new WorkOrderLineItem();
                        woliTask.AccountLocation__c = WOLI_VAR.AccountLocation__c;
                        woliTask.WorkOrderLineItemType__c = CONST_WOLI_CRTASK_TYPE;
                        woliTask.SLADate__c = WOLI_VAR.SLADate__c;
                        woliTask.Building__c = WOLI_VAR.Building__c;
                        woliTask.Floor__c = WOLI_VAR.Floor__c;
                        woliTask.PhysicalAsset__c = WOLI_VAR.PhysicalAsset__c;
                        woliTask.RecordTypeId = CONST_WOLI_TASK_CR_RT;
                        woliTask.Status = CONST_WOLI_COMPLETED_STATUS;
                        woliTask.WorkOrderId = LOADID_WORKORDERID_MAP.get(WOLI_VAR.Id);
                        woliTask.MachineCare__c = WOLI_VAR.MachineCare__c;
                        woliTask.WorkOrderType__c = CONST_WORKORDER_CR_TYPE;
                        woliTask.OP_PreferredOperator__c =  WOLI_VAR.OP_PreferredOperator__c;
                        woliTask.PricebookEntryId = WOLI_VAR.PricebookEntryId;
                        woliTask.TypeofCounterReadingTask__c = CONST_WOLI_TYPECR_ORDINARY;
                        woliTask.Re_active__c = true;
                        woliTask.ExecutingEngineer__c = WOLI_VAR.ExecutingEngineer__c;
                        woliTask.OpFilledbyOperator__c = WOLI_VAR.OpFilledbyOperator__c;
                        woliTask.OP_PCBchanged__c = WOLI_VAR.OP_PCBchanged__c;
                        woliTask.Area__c = WOLI_VAR.Area__c;
                        woliTask.PostalCode__c = WOLI_VAR.PostalCode__c;

                        //DOO-488 INC0119063 Xen Reyes June 18, 2019
                        
                        //July 3, 2019 Xen Reyes
                        woliTask.StartDate__c = WOLI_VAR.StartDate__c;

                        //POPULATE RELATED TO FIELD OF COUNTER READING TASK
                        woliTask.RelateTo__c = WOLI_VAR.Id;

                        CR_WOLI_LIST.add(woliTask);
                    }
                }
            }

            //System.debug('CR_WOLI_LIST: ' + CR_WOLI_LIST);

            try{
                if(!CR_WOLI_LIST.isEmpty()){

                    WorkOrderLineItemTriggerHandler.LARGE_INSERT_MUTE = true;
                    insert CR_WOLI_LIST;
                    COUNTERREADING_RUNONCE = true;

                    TS_LargeCounterReadingQueueable LARGE_QUEUEABLE = new TS_LargeCounterReadingQueueable();
                    LARGE_QUEUEABLE.CR_WOLI_LIST = CR_WOLI_LIST;
                    LARGE_QUEUEABLE.WORKORDER_COUNTEREADING_MAP = WORKORDER_COUNTEREADING_MAP;
                    System.enqueueJob(LARGE_QUEUEABLE);

                }

            } catch (Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
        }

        CustomLogging.pop();
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          May 13, 2019
    * @description   Method to populate the JDELineItemNumber__c field using the auto number generated from WorkOrderLineItemNumber__c
    * @revision(s)
    */
    public map<Id, String> POPULATE_JDELINEITEMNUMBER(List<SObject> newList) {

        //System.debug('POPULATE_JDELINEITEMNUMBER');

        Map<Id,String> WOLI_MAP = new Map<Id,String>();
        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
            if(WOLI_VAR.JDELineItemNumber__c == null || (WOLI_VAR.JDELineItemNumber__c != WOLI_VAR.WorkOrderLineItemNumber__c)){
                WOLI_MAP.put(WOLI_VAR.Id, WOLI_VAR.WorkOrderLineItemNumber__c);                
            }

            //May 24, 2019 -  XEN REYES
            //FOR TASKS WITH GROUPING INDICATOR
            if(WOLI_VAR.DependentWOLI__c != null){
                afterUpdateRunOnce = true;
            }
        }

        if(!WOLI_MAP.isEmpty()){
            WorkOrderLineItemTriggerHandler.INTEGRATION_MUTE = true;            
        }

        return WOLI_MAP;
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          May 13, 2019
    * @description   Method to update Click Ready (from Workflow)
    * @revision(s)   
    */

    public void UPDATE_CLICKREADY(List<SObject> newList, Map<Id,SObject> oldMapItems) {

        List<WorkOrderLineItem> WOLI_LIST = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
            if(extWoliNewMap.containsKey(WOLI_VAR.Id)){
                WorkOrderLineItem QUERIED_WOLI = extWoliNewMap.get(WOLI_VAR.Id);
                WorkOrderLineItem OLD_WOLI = (WorkOrderLineItem) (oldMapItems.get(WOLI_VAR.Id));

                /* System.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
                System.debug('System.Label.TS_ClickSoftwareUserId: ' + System.Label.TS_ClickSoftwareUserId);
                System.debug('WOLI_VAR.Click_Integration_Status__c: ' + WOLI_VAR.Click_Integration_Status__c);
                System.debug('OLD_WOLI.Click_Integration_Status__c: ' + OLD_WOLI.Click_Integration_Status__c);
                System.debug('WOLI_VAR.ClickReady__c: ' + WOLI_VAR.ClickReady__c);
                System.debug('OLD_WOLI.ClickReady__c: ' + OLD_WOLI.ClickReady__c);
                System.debug('WOLI_VAR.ReturnTask__c: ' + WOLI_VAR.ReturnTask__c); */

                Boolean GENERAL_CRITERIA = false;
                GENERAL_CRITERIA =  UserInfo.getName() != clickName && //Karen Hung 21/11/2020 DOO-5035
                        (
                                QUERIED_WOLI.Case__r.Click__c ||
                                        WOLI_VAR.WorkOrderType__c == Label.TS_Activity_Type_S20 ||
                                        WOLI_VAR.WorkOrderType__c == Label.TS_Activity_Type_S21 ||
                                        WOLI_VAR.WorkOrderType__c == Label.TS_Activity_Type_S22 ||
                                        WOLI_VAR.WorkOrderType__c == Label.TS_Activity_Type_S25
                        ) &&
                        WOLI_VAR.Click_Integration_Status__c == OLD_WOLI.Click_Integration_Status__c &&
                        WOLI_VAR.JDELineItemNumber__c != null &&
                        WOLI_VAR.WorkOrderType__c != null &&
                        (
                                (WOLI_VAR.EarliestAppointmentTime__c != null && WOLI_VAR.ScheduleManually__c) ||
                                        WOLI_VAR.BookAppointmentStart__c != null ||
                                        WOLI_VAR.SLADate__c != null ||
                                        WOLI_VAR.ReturnTask__c
                        ) &&
                        QUERIED_WOLI.AccountLocation__r.Apttus_Config2__PostalCode__c != null &&
                        QUERIED_WOLI.AccountLocation__r.Shipping_Country_ISO__c != null &&
                        QUERIED_WOLI.AccountLocation__r.Shipping_Street_Only__c != null &&
                        QUERIED_WOLI.AccountLocation__r.Apttus_Config2__City__c != null &&
                        !((WOLI_VAR.ClickReady__c != OLD_WOLI.ClickReady__c) && !WOLI_VAR.ClickReady__c);

                //XEN REYES Nov 23, 2019 - Do not send integration message to Click when task is Review Needed
                if(WOLI_VAR.Status == 'Review Needed' && Label.TS_ReviewNeededClick == 'true'){
                    GENERAL_CRITERIA = false;
                }

                if(isRouteOperating){
                    GENERAL_CRITERIA = false;
                }

                //System.debug('GENERAL_CRITERIA - UPDATE_CLICKREADY: ' + GENERAL_CRITERIA);

                if(GENERAL_CRITERIA){
                    WOLI_LIST.add(new WorkOrderLineItem(Id = WOLI_VAR.Id, 
                                                        ClickReady__c = true));

                    if(validateIfHasChanges(WOLI_VAR, OLD_WOLI, CONST_WOLITASK_FIELDSET)){
                        HAS_CHANGES_MAP.put(WOLI_VAR.Id, true);
                        //System.debug('HAS CHANGES: TRUE');
                    }
                }
            }
        }

        if(!WOLI_LIST.isEmpty()){
            WorkOrderLineItemTriggerHandler.INTEGRATION_MUTE = true;
            update WOLI_LIST;
        }
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          May 15, 2019
    * @description   Method to populate Account Location ID field
    * @revision(s)
    */

    public void POPULATE_ACCOUNTLOCATIONID (List<SObject> newList, Map<Id,SObject> oldMapItems) {

        List<WorkOrderLineItem> WOLI_LIST = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){

            if(oldMapItems == null){
                if(WOLI_VAR.AccountLocation__c != null){
                    WOLI_VAR.AccountLocationID__c = WOLI_VAR.AccountLocation__c;
                }
            } else if(oldMapItems.containsKey(WOLI_VAR.Id)){
                WorkOrderLineItem OLD_WOLI_VAR = (WorkOrderLineItem) (oldMapItems.get(WOLI_VAR.Id));
                if((WOLI_VAR.AccountLocation__c != OLD_WOLI_VAR.AccountLocation__c) && WOLI_VAR.AccountLocation__c != null){
                    WOLI_VAR.AccountLocationID__c = WOLI_VAR.AccountLocation__c;
                }
            }

        }
    } 

    /*
    * @author        Abram Vixen Reyes
    * @date          June 24, 2019
    * @description   Method to mute methods when return needed
    * @revision(s)   
    */
    public void RETURN_NEEDED_MUTING (List<SObject> newList, Map<Id,SObject> oldMapItems) {

        List<WorkOrderLineItem> WOLI_LIST = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
            if(oldMapItems.containsKey(WOLI_VAR.Id)){
                WorkOrderLineItem OLD_WOLI_VAR = (WorkOrderLineItem) (oldMapItems.get(WOLI_VAR.Id));

                //MUTE UPDATES IN CREATE RETURN NEEDED FLOW PROCESS BUILDER
                if((WOLI_VAR.Return_task_processed__c != OLD_WOLI_VAR.Return_task_processed__c) && WOLI_VAR.Return_task_processed__c){
                    WorkOrderLineItemTriggerHandler.LARGE_INSERT_MUTE = true;
                    CaseTriggerHandler.IS_RETURN_NEEDED = TRUE;
                }

                //DOO-3911 Francis Allen Alindogan Feb. 26, 2020
                if(WOLI_VAR.ReturnNeeded__c){
                    WorkOrderLineItemTriggerHandler.isNotBatchExecution = false;
                    WorkOrderLineItemTriggerHandler.IS_RETURN_NEEDED = true;
                }
            }
        }
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          March 6, 2020
    * @description   Method to reduce one (1) hour in time fields when an OPG Route Task is completed
    * @revision(s)   
    */
    /* public void ADJUSTTIME_ROUTEOPERATING (List<SObject> newList, Map<Id,SObject> oldMapItems) {

        List<WorkOrderLineItem> WOLI_LIST = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem WOLI_VAR : (List<WorkOrderLineItem>) newList){
            if(oldMapItems.containsKey(WOLI_VAR.Id)){
                WorkOrderLineItem OLD_WOLI_VAR = (WorkOrderLineItem) (oldMapItems.get(WOLI_VAR.Id));
                
                if( WOLI_VAR.Status == TS_Constants.STATUS_COMPLETED && 
                    OLD_WOLI_VAR.Status != TS_Constants.STATUS_COMPLETED && 
                    WOLI_VAR.RecordTypeId == Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId() &&
                    extWoliNewMap.get(WOLI_VAR.Id).WorkOrder.RecordType.Name == TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO &&
                    UserInfo.getUserId() == System.Label.TS_ClickSoftwareUserId
                    ){

                    List<String> fieldsToReduce = System.Label.TS_FieldsToReduce != null ? System.Label.TS_FieldsToReduce.split(',') : new List<String>{};
                    Integer timeToReduce = (System.Label.TS_TimeToReduce != null && System.Label.TS_TimeToReduce != '0') ? Integer.valueOf(System.Label.TS_TimeToReduce) : 0;
                    
                    if(!fieldsToReduce.isEmpty()){
                        for(String str : fieldsToReduce){
                            if(WOLI_VAR.get(str) != null) WOLI_VAR.put(str, DateTime.valueOf(WOLI_VAR.get(str)).addHours(timeToReduce * -1));
                        }
                    }
                }
            }
        }
    } */

    /*
    * @author        Karen Mae Hung
    * @date          November 20, 2019
    * @description   DOO-2685 Method to check WTS performed in parent woli when there is  used part added that has  material pricing group id of 05
    * @revision(s)   
    */
    public void checkWTSPerformed(List<SObject> newList,Map<Id,SObject> oldMapItems,Map<Id,SObject> newMapItems){
        CustomLogging.push('checkWTSPerformed', 'WorkOrderLineItemTriggerHandler');       
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        Map<Id,WorkOrderLineItem> newWoli = (Map<Id,WorkOrderLineItem>) newMapItems;

        try{
            //get completed WOLI's
            List<String> completedWOLI = new List<String>();
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){

                if(oldWoli.get(woli.Id).Status != newWoli.get(woli.Id).Status && woli.Status == TS_Constants.STATUS_COMPLETED && woli.WTSPerformed__c == false){
                    completedWOLI.add(woli.Id);
                }
            }
            
            if(!completedWOLI.isEmpty()){
                Map<String, List<String>> assetProductsMap = getWFparts(completedWOLI,newWoli);
            }
                        
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());       
        }
        
        CustomLogging.pop();
    }
    
    
    /*
    * @author        Karen Mae Hung
    * @date          November 20, 2019
    * @description   DOO-2686 Method to cancel other open water filter tasks when wts performed is checked upon completion
    * @revision(s)   
    */
    public void cancelOpenWFTasks(List<SObject> newList, Map<Id,SObject> oldMapItems){
        CustomLogging.push('cancelOpenWFTasks', 'WorkOrderLineItemTriggerHandler');
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        List<String> assetIds = new List<String>();

        try{

            
            //DOO-3886 Karen Hung
            Set<String> caseWoli = new Set<String>();
            
            //get completed woli where WTS = TRUE
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
                if(oldWoli.get(woli.Id).Status != woli.Status && woli.Status == TS_Constants.STATUS_COMPLETED && woli.WTSPerformed__c == true){
                    assetIds.add(woli.PhysicalAsset__c);
                    caseWoli.add(woli.Case__c); // Karen Hung DOO-3886 Feb 20,2020  to exclude case of the woli in cancelation 
                }
            }
            
            
            //cancel waterfilter cases
            if(!assetIds.isEmpty()){

                TS_QueueableProcesses cs = new TS_QueueableProcesses();
                cs.METHOD_CANCELOPENWFTASKS = true;
                cs.assetIds = assetIds;
                cs.caseWoli = caseWoli;
                System.enqueueJob(cs);

            }
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }
            
        } catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());   
        }
        
        CustomLogging.pop();    
    } 
    
    /*
    * @author        Francis Allen Alindogan
    * @date          March 5, 2020
    * @description   DOO-3907 Sets the ClickPriority for S10 work order type WOLI
    * @revision(s)   
                     DOO-4271 10.01.2020 Modified to separate concerns for Insert and Update scenarios
                                        Modified to separate concerns for original and return task scenarios
    */
    public void setClickPriority(List<WorkOrderLineItem> newList){
        CustomLogging.push('setClickPriority', 'WorkOrderLineItemTriggerHandler');
        Map<String,String> clickPriorityMap = new Map<String, String>();
        List<WorkOrderLineItem> woliList = new List<Workorderlineitem>();
        
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            woliList.add(woli);
        }

        //GET CLICK PRIORITY MAP<SalesOrg+ResponseProfile, ClickPriority>
        clickPriorityMap = getClickPriority(woliList);                  
        if(!extCSEMap.isEmpty() && !clickPriorityMap.isEmpty()){   
            //ASSIGN TO NEW WOLI     
            for(WorkOrderLineItem woli : woliList){                
                if(clickPriorityMap.get(String.valueOf(extCSEMap.get(woli.Case__c).SalesOrganization__c) + String.valueOf(extCSEMap.get(woli.Case__c).ResponseProfile__c)) != null &&
                   extCSEMap.get(woli.Case__c) != null && 
                   extCSEMap.get(woli.Case__c).SalesOrganization__c != null && 
                   extCSEMap.get(woli.Case__c).ResponseProfile__c != null               
                   ){             
                        String woliKey;                  
                        woliKey = String.valueOf(extCSEMap.get(woli.Case__c).SalesOrganization__c) + String.valueOf(extCSEMap.get(woli.Case__c).ResponseProfile__c);                                                                                                                    
                        woli.Click_Priority__c = String.valueOf(clickPriorityMap.get(woliKey));
                   }                
            }
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          October 1, 2020
    * @description   Helper method to get Click Priority from country setting
    * @revision(s)   
    */
    public Map<String,String> getClickPriority(List<WorkOrderLineItem> woliList){
        CustomLogging.push('getClickPriority', 'WorkOrderLineItemTriggerHandler');
        Map<String, CountrySetting__c> csMap = new Map<String, CountrySetting__c>();
        Map<String, String> returnMap = new Map<String, String>();        
        List<CountrySetting__c> csList = new List<CountrySetting__c>();
        Set<Id> cseSet = new Set<Id>();
        String woliKey;        
        Boolean isMuted = true;

        //ITERATE WOLI
        for(WorkOrderLineItem woli : woliList){            
            //GET CASE IF FROM INSERT, SKIP IF FROM RETURN TASK OR UPDATE
            if(woli.Case__c != null && Trigger.isInsert){
                cseSet.add(woli.Case__c);
            }
            //TOGGLE MUTE TO FALSE IF THERE IS AN S10, OPEN AND CLICK PRIORITY IS NULL
            if(woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI &&
                woli.Click_Priority__c == null &&
                woli.Status == TS_Constants.WOLI_STATUS_OPEN &&
                isMuted == true){
                    isMuted = false;
            }
        }
        
        if(isMuted == false){
            //GET COUNTRY SLA DERIVATION SETTINGS 
            csList = [
                SELECT Country__c, ResponseProfile__c, Priority__c
                FROM CountrySetting__c 
                WHERE Active__c = true 
                AND RecordType.Name =: TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYSLADERIVATION
            ];

            for(CountrySetting__c cs : csList){
                String key = cs.Country__c + cs.ResponseProfile__c;
                csMap.put(key, cs);
            }            
    
            //GET ALL RELATED CASES FOR INSERT, SKIP IF FROM RETURN TASK
            if(extCSEMap.isEmpty() && Trigger.isInsert){
                extCSEMap = getWoliRelatedCaseMap(cseSet);
            }

            //ITERATE AND ASSIGN CLICK PRIORITY TO MAP <SALESORG+RESPONSEPROFILE, CLICKPRIORITY>
            for(WorkOrderLineItem woli : woliList){               
                
                if( woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI &&
                    woli.Click_Priority__c == null &&
                    woli.Status == TS_Constants.WOLI_STATUS_OPEN 
                    ){                    
                    //FOR NON RETURN TASK USE CASE AS RESPONSE PROFILE
                    if( woli.ReturnTask__c == false &&
                        csMap != null && extCSEMap != null &&
                        extCSEMap.get(woli.Case__c).SalesOrganization__c != null && 
                        extCSEMap.get(woli.Case__c).ResponseProfile__c != null 
                        ){                                        
                        woliKey = String.valueOf(extCSEMap.get(woli.Case__c).SalesOrganization__c) + String.valueOf(extCSEMap.get(woli.Case__c).ResponseProfile__c);                                                                                       
                        if(csMap.get(woliKey) != null && csMap.get(woliKey).Priority__c != null){                             
                            returnMap.put(woliKey , String.valueOf(csMap.get(woliKey).Priority__c));
                        }
                    }
                    //DOO-4271 10.01.2020 Francis Allen Alindogan
                    //FOR RETURN TASK USE ORIG WOLI AS RESPONSE PROFILE                             
                    else if( woli.ReturnTask__c == true &&
                             csMap != null && extWoliNewMap != null && woliResponseMap != null && 
                             extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c != null && 
                             woliResponseMap.get(woli.RelateTo__c) != null 
                             ){                                                   
                             woliKey = String.valueOf(extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c) + String.valueOf(woliResponseMap.get(woli.RelateTo__c));                                                                                                                                       
                             if(csMap.get(woliKey) != null && csMap.get(woliKey).Priority__c != null){                             
                                returnMap.put(woliKey , String.valueOf(csMap.get(woliKey).Priority__c));
                             }
                    }
                }
            }
        }
        return returnMap;
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          March 5, 2020
    * @description   Helper method to get related WOLI related Cases
    * @revision(s)   
    */
    public Map<Id, Case> getWoliRelatedCaseMap(Set<Id> caseIds) {
        CustomLogging.push('getRelatedCaseMap', 'WorkOrderLineItemTriggerHandler');
        Map<Id, Case> relatedCaseMap = new Map<Id, Case>();

        if (caseIds != null && !caseIds.isEmpty()) {
            relatedCaseMap = new Map<Id, Case>(
            [SELECT 
                Id, 
                SalesOrganization__c,
                ResponseProfile__c,
                ProductId
            FROM Case
            WHERE Id IN :caseIds
            ]);
        }
        CustomLogging.pop();
        return relatedCaseMap;
    }

    /*
    * @author        Karen Hung
    * @date          March 12, 2020
    * @description   Helper method to populate preferred operator from route DOO-4273
    * @revision(s)   
    */
    public void POPULATE_PREFERREDOPERATOR(List<SObject> newList){
        CustomLogging.push('POPULATE_PREFERREDOPERATOR', 'WorkOrderLineItemTriggerHandler');

        Map<String, Route_Line_Item__c> assetRouteItemMap = new Map<String, Route_Line_Item__c>();

        Set<String> assetIds = new Set<String>();
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.WorkOrderType__c == 'S15' || woli.WorkOrderType__c == 'S22'){
                assetIds.add(woli.PhysicalAsset__c);      
            }      
        }

        if(!assetIds.isEmpty()){
            for(Route_Line_Item__c routeItem : [SELECT Id, PhysicalAssetId__c, RouteId__c, RouteId__r.Name, RouteId__r.Unique_Route_Number__c, RouteId__r.Preferred_Operator__c, RouteId__r.Required_Operator__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :assetIds and RouteId__c != null]){
                assetRouteItemMap.put(routeItem.PhysicalAssetId__c, routeItem);  
            }

            //populate Route_Name__c and Unique_Number__c and RequiredEngineer__c/OP_PreferredOperator__c
            for(WorkOrderLineItem newItems : (List<WorkOrderLineItem>) newList){
                if(assetRouteItemMap.containsKey(newItems.PhysicalAsset__c) && (newItems.WorkOrderType__c == 'S15' || newItems.WorkOrderType__c == 'S22')){ 
                    newItems.Route_Name__c = assetRouteItemMap.get(newItems.PhysicalAsset__c).RouteId__r.Name;
                    newItems.Unique_Number__c = assetRouteItemMap.get(newItems.PhysicalAsset__c).RouteId__r.Unique_Route_Number__c;
                    if(assetRouteItemMap.get(newItems.PhysicalAsset__c).RouteId__r.Required_Operator__c != null){
                        newItems.RequiredEngineer__c = assetRouteItemMap.get(newItems.PhysicalAsset__c).RouteId__r.Required_Operator__c;
                    }else{
                        newItems.OP_PreferredOperator__c = assetRouteItemMap.get(newItems.PhysicalAsset__c).RouteId__r.Preferred_Operator__c;
                    }                                 
                }      
            }
        }
        CustomLogging.pop();  
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          April 14, 2020
    * @description   Method to update Physical Asset's  Last Preventive Maintenance Date, Last WTS Change Date if MCO Task is Completed
    * @revision(s)   
    */
    public void updatePAifMCOComplete(List<WorkOrderLineItem> newList, Map<Id,SObject> oldMapItems, Map<Id,SObject> newMapItems){
        CustomLogging.push('updatePAifMCOComplete', 'WorkOrderLineItemTriggerHandler');
        String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        String CONST_DK_SALESORG = Label.TS_New_Operating_SalesOrg;
        List<String> salesOrgList = CONST_DK_SALESORG.split(',');
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        Map<Id,WorkOrderLineItem> newWoli = (Map<Id,WorkOrderLineItem>) newMapItems;
        Map<Id,PhysicalAsset__c> paMapForUpdate = new Map<Id,PhysicalAsset__c>();
        Set<Id> pmSet = new Set<Id>();
        Set<Id> wfSet = new Set<Id>();
        Set<Id> paSet = new Set<Id>();
        Map<Id,Date> paEndDateMap = new Map<Id,Date>();
        
        for(WorkOrderLineItem woli : newList){
            Boolean isForUpdate = false;

            if( woli.RecordTypeId == CONST_WOLI_OP_RT &&
                woli.isFromRoute__c == true &&
                woli.Status == TS_Constants.STATUS_COMPLETED &&
                woli.Status != oldWoli.get(woli.Id).Status &&
                woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE &&
                woli.EndDate__c != null &&
                woli.WorkOrderLineItemType__c != null
            ){   
                if(woli.WorkOrderLineItemType__c.contains('P')){ 
                    pmSet.add(woli.PhysicalAsset__c);
                } 

                if(woli.WorkOrderLineItemType__c.contains('W')){ 
                    wfSet.add(woli.PhysicalAsset__c);
                }                     
                paEndDateMap.put((Id)woli.PhysicalAsset__c, woli.EndDate__c.date());             
            }
        }

        //UPDATE PHYSICAL ASSET
        if( (pmSet != null && pmSet.size() > 0) ||
            (wfSet != null && wfSet.size() > 0) 
           ){
            paSet.addAll(pmSet);
            paSet.addAll(wfSet);        
            List<PhysicalAsset__c> paQuery = [SELECT Id, LastPreventiveMaintenanceDate__c, LastWTSDate__c FROM PhysicalAsset__c WHERE Id IN: paSet AND SalesOrganization__c IN: salesOrgList];
            for(PhysicalAsset__c pa : paQuery){
                if(pmSet.contains(pa.Id)){
                    pa.LastPreventiveMaintenanceDate__c = paEndDateMap.get(pa.Id);  
                }

                if(wfSet.contains(pa.Id)){
                    pa.LastWTSDate__c = paEndDateMap.get(pa.Id);                     
                }
                paMapForUpdate.put(pa.Id,pa);
            }
        }
        if(!paMapForUpdate.values().isEmpty()){
            try{
                update paMapForUpdate.values();
            } 
            catch (Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
        }      
    }

    /*
    * @author        Karen Mae Hung
    * @date          June 5, 2020
    * @description   DOO-4619 Method to create follow up case from Process Builder: TS_Follow-up Actions
    * @revision(s)   
    */
    public void createFollowUpActions(List<SObject> newList, Map<Id,SObject> oldMapItems){
        CustomLogging.push('createFollowUpActions', 'WorkOrderLineItemTriggerHandler');
        try{  
            List<Case> caseToCreate = new List<Case>();
            Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
            List<String> completedWOLI = new List<String>();

            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){
                if(oldWoli.get(newWoli.Id).Status != newWoli.Status && newWoli.Status == TS_Constants.STATUS_COMPLETED && newWoli.OpportunityType__c != null){
                    completedWOLI.add(newWoli.Id);
                }
            }

            //new case creation
            if(!completedWOLI.isEmpty()){
                //get business hours
                Map<String, String> countryBusinessHour = new Map<String, String>();
                String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT).getRecordTypeId();
                List<CountrySetting__c> cset =  [SELECT Id, Country__c, Business_Hours__c FROM CountrySetting__c WHERE RecordtypeId = :recordTypeId AND Active__c = true];
                if(!cset.isEmpty()){
                    for(CountrySetting__c countrySetting : cset){
                        countryBusinessHour.put(countrySetting.Country__c, countrySetting.Business_Hours__c);
                    }
                }
                
                for(WorkOrderLineItem woli :  [SELECT Id, CurrencyIsoCode, CommercialNote__c, OpportunityType__c, OpportunitySubType__c, ExecutingEngineer__c, WorkOrder.SalesOrganization__c, Case__r.ContactId, Case__r.AccountId, Case__c, AccountLocation__c
                                                FROM WorkOrderLineItem
                                                WHERE Id IN : completedWOLI]){
                    Case newCase = new Case();
                    newCase.BusinessHoursId = countryBusinessHour.containsKey(woli.WorkOrder.SalesOrganization__c) ? countryBusinessHour.get(woli.WorkOrder.SalesOrganization__c) : null;
                    newCase.CurrencyIsoCode = woli.CurrencyIsoCode;
                    newCase.Description = woli.CommercialNote__c;
                    newCase.Origin = TS_Constants.CASE_ORIGIN_EF;
                    newCase.Reporting_Engineer__c = woli.ExecutingEngineer__c;
                    newCase.SalesOrganization__c = woli.WorkOrder.SalesOrganization__c;
                    newCase.Subject = woli.OpportunityType__c + ': ' + woli.OpportunitySubType__c;
                    newCase.Type = TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE;
                    if(woli.Case__r == null){
                        newCase.AccountLocation__c = woli.AccountLocation__c;
                    }else{
                        newCase.AccountId = woli.Case__r.AccountId;
                        newCase.ParentId = woli.Case__c;
                        newCase.ContactId = woli.Case__r.ContactId;
                    }
                    caseToCreate.add(newCase);
                }
            }

            if(!caseToCreate.isEmpty()){
                insert caseToCreate;
            }

        }catch(Exception e){
            System.debug(e);
            CustomLogging.debugException(e);
            CustomLogging.pop();
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          June 8, 2020
    * @description   DOO-4616 Method to create Return Task Process Builder: TS_Create_Return_Needed
    * @revision(s)   
    */
    public void createReturnTask(List<SObject> newList, Map<Id,SObject> oldMapItems){
        CustomLogging.push('createReturnTask', 'WorkOrderLineItemTriggerHandler');
        
        List<WorkOrderLineItem> woliToCreate = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> forSLACalcList = new List<WorkOrderLineItem>();
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        Map<Id,Datetime> woliSLAMap = new Map<Id, Datetime>();
        Map<String, String> clickPriorityMap = new Map<String, String>();
        
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){
            if( newWoli.Status == TS_Constants.STATUS_COMPLETED && 
                oldWoli.get(newWoli.Id).Status != newWoli.Status &&
                newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK &&
                newWoli.ReturnNeeded__c == true &&
                newWoli.Return_task_processed__c == false
              ){                    
                    WorkOrderLineItem returnWoli = new WorkOrderLineItem();
                    returnWoli.AccountLocation__c = newWoli.AccountLocation__c;
                    returnWoli.Case__c = newWoli.Case__c;
                    returnWoli.Description = newWoli.Description;
                    //returnWoli.IsCoffeeRunning__c = newWoli.IsCoffeeRunning__c; DOO-4984 XEN REYES
                    returnWoli.IsCoffeeRunning__c = newWoli.CoffeeRunsAfterVisit__c;                    
                    returnWoli.OrderLineItem__c = newWoli.OrderLineItem__c;
                    returnWoli.PhysicalAsset__c = newWoli.PhysicalAsset__c;
                    returnWoli.PricebookEntryId = newWoli.PricebookEntryId ;
                    returnWoli.RelateTo__c = newWoli.Id;
                    returnWoli.ReturnNeeded__c = false;
                    returnWoli.ReturnTask__c = true;
                    returnWoli.ScheduleManually__c = true;
                    returnWoli.Status = TS_Constants.WOLI_STATUS_OPEN;
                    returnWoli.Subject = newWoli.Subject;
                    returnWoli.WorkOrderId = newWoli.WorkOrderId;
                    returnWoli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;
                
                    //CHECK RETURN NEEDED COMMENT
                    if( newWoli.Return_Needed_Comment__c != null && 
                        newWoli.Return_Needed_Comment__c != ''  &&
                        newWoli.ReturnNeeded__c == true
                      ){
                        returnWoli.Description = newWoli.Description +'\n \n'+  newWoli.Return_Needed_Comment__c;
                    }
                    else {
                        returnWoli.Description = newWoli.Description;
                    }                
                    //CHECK RETURN NEEDED S10 VALUE
                    if((newWoli.Return_Needed_S10__c == true && newWoli.WorkOrderType__c != TS_Constants.WO_TYPE_S15_1STLINECM) ||
                        newWoli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM ||
                        newWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI){

                        returnWoli.WorkOrdertype__c = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
                        returnWoli.EarlyStart__c = Datetime.now();

                        //CHECK IF SCHEDULE MANUALLY
                        if(returnWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI &&
                          (newWoli.WorkOrdertype__c == TS_Constants.WO_TYPE_S15_1STLINECM || newWoli.workorderType__c == TS_Constants.ORDER_S40)){
                            returnWoli.ScheduleManually__c = false;
                        }
                    }
                    else {
                        returnWoli.WorkOrderType__c = newWoli.WorkOrderType__c;
                    }         
                    //NEEDS SLA COMPUTATION
                    if((returnWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI && newWoli.WorkOrderType__c != TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI) ||
                        returnWoli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM){
                            forSLACalcList.add(returnWoli);
                    }
                    //FLAG ORIG WOLI RETURN TASK PROCESSED FOR WOLI MUTING
                    if(newWoli.Return_task_processed__c == false){                        
                        WorkOrderLineItem woli = new WorkOrderLineItem(Id = newWoli.Id, Return_task_processed__c = true);
                        woliToUpdate.add(woli);
                    }           
                    //Francis Allen Alindogan DOO-5195 01/15/2021 IF OT & RT ARE S40 COPY SLA FROM OT TO RT.
                    if(returnWoli.WorkOrderType__c == TS_Constants.ORDER_S40 && newWoli.WorkOrderType__c == TS_Constants.ORDER_S40){
                        returnWoli.SLADate__c = newWoli.SLADate__c;
                        returnWoli.ScheduleManually__c = true;
                    }
                    woliToCreate.add(returnWoli);                    
            }
        }

        Map<Id, WorkOrderLineItem> extWoliMap = extWoliNewMap;
        if(forSLACalcList != null && forSLACalcList.size() > 0 && extWoliMap != null){
            //CALCULATE SLA DATE
            woliSLAMap = DynamicFirstResponseCalculator.calculateSLADate(forSLACalcList,extWoliMap);
            //ASSIGN SLA
            if(woliSLAMap != null){
                for(WorkOrderLineItem woli : woliToCreate){
                    if(woli.RelateTo__c != null && woliSLAMap.containsKey(woli.RelateTo__c) && woli.SLADate__c == null){        
                        woli.SLADate__c = woliSLAMap.get(woli.RelateTo__c);
                    }
                }
            }
        }

        //DOO-4271 10.01.2020 Francis Allen Alindogan Stamp the response profile to the Original Task
        if(woliToCreate != null && woliToCreate.size() > 0 && extWoliMap != null){
            woliResponseMap = DynamicFirstResponseCalculator.calculateResponseProfile(woliToCreate,extWoliMap);                 
            //STAMP THE RESPONSE PROFILE TO THE ORIG TASK
            if(!woliResponseMap.isEmpty()){
                for(WorkOrderLineItem woli : woliToCreate){
                    if(woliResponseMap.get(woli.RelateTo__c) != null){
                        woli.ResponseProfile__c = woliResponseMap.get(woli.RelateTo__c);                        
                    }
                }
            }
        }        
        //GET CLICK PRIORITY MAP
        clickPriorityMap = getClickPriority(woliToCreate);        
        //ASSIGN CLICK PRIORITY TO THE RETURN TASK
        if(!clickPriorityMap.isEmpty() && !extWoliNewMap.isEmpty()){
            for(WorkOrderLineItem woli : woliToCreate){                                     
                if(extWoliNewMap.get(woli.RelateTo__c) != null && extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c != null && woliResponseMap.get(woli.RelateTo__c) != null ){                            
                    String key = extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c + woliResponseMap.get(woli.RelateTo__c);                               
                    woli.Click_Priority__c = clickPriorityMap.get(key);
                }
            }
        }                  
          
        if(woliToCreate != null && woliToCreate.size() > 0){        
            try{
                insert woliToCreate;                
                //CREATE MISSING PARTS AND SERVICE MATERIALS                
                createParts(woliToCreate, woliToUpdate, extWoliMap); //EXTWOLIMAP = OLD EXTWOLINEWMAP, BEFORE THE INSERT DML FOR RETURN TASK. THIS HAS RETAINED MAPPING FOR THE ORIG TASK
            }  
            catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();                
            }
        }                        
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          June 8, 2020
    * @description   DOO-4616 Method to create parts Process Builder: TS_Create_Return_Needed
    * @revision(s)   
    */
    public void createParts(List<WorkOrderLineItem> returnWoliList, List<WorkOrderLineItem> origWoliList, Map<Id,WorkOrderLineItem> extWoliMap ){        
        CustomLogging.push('createParts', 'WorkOrderLineItemTriggerHandler');        
        Set<Id> products = new Set<Id>();        
        Set<Id> parentWoliSet = new Set<Id>();        
        Set<Id> uniqueCases = new Set<Id>();    
        Set<String> salesOrgs = new Set<String>();
        Set<String> modifiedSalesOrgs = new Set<String>();
        Set<String> parentWoTypes = new Set<String>();        
        Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
        Map<String, APTS_Sales_Org_Data__c> sOrgMap = new Map<String, APTS_Sales_Org_Data__c>();        
        Map<String, CountrySetting__c> csMap = new Map<String, CountrySetting__c>();        
        Map<Id, Id> parentChildWoliMap = new Map<Id, Id>();        
        List<Case> caseList = new List<Case>();
        List<WorkOrderLineItem> matList = new List<WorkOrderLineItem>();
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<APTS_Sales_Org_Data__c> sOrgDataList = new List<APTS_Sales_Org_Data__c>();
        List<SObject> sObjToUpdate = new List<SObject>();
        List<WorkOrderLineItem> partsList = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> returnWoliListUpdate = new List<WorkOrderLineItem>();
        List<CountrySetting__c> csList = new List<CountrySetting__c>();
        Id reqPartRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_REGREQPART);
        Id servMatRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_REGSERVMAT);

        //SET PA WO SETS FOR WHERE CLAUSE
        for(WorkOrderLineItem woli : returnWoliList){            
            if(extWoliMap != null && woli.RelateTo__c != null && extWoliMap.containsKey(woli.RelateTo__c) && extWoliMap.get(woli.RelateTo__c) != null && extWoliMap.get(woli.RelateTo__c).WorkOrderType__c != null){                
                parentWoTypes.add(extWoliMap.get(woli.RelateTo__c).WorkOrderType__c);            
            }            
            if(extWoliNewMap != null && woli.Id != null && extWoliNewMap.containsKey(woli.Id) && extWoliNewMap.get(woli.Id) != null && extWoliNewMap.get(woli.Id).WorkOrder.SalesOrganization__c != null){                                 
                salesOrgs.add(extWoliNewMap.get(woli.Id).WorkOrder.SalesOrganization__c);             
                modifiedSalesOrgs.add(extWoliNewMap.get(woli.Id).WorkOrder.SalesOrganization__c.SubStringAfter('_'));             
            }            
            if(woli.RelateTo__c != null){
                parentWoliSet.add(woli.RelateTo__c);
                parentChildWoliMap.put(woli.RelateTo__c, woli.Id);            
            }            
        }        
        //GET ALL PARTS
        partsList = [SELECT Id, Case__c, WorkOrderId, ParentworkOrderLineItemId, PricebookEntryId, Quantity, Unit_Price__c, DirectToCustomer__c FROM WorkOrderLineItem WHERE ParentworkOrderLineItemId IN :parentWoliSet AND WorkOrderLineItemType__c =:TS_Constants.WOLI_STATUS_MISSING];               
        if(partsList != null && partsList.size() > 0 ){    
            //LOOP THROUGH MISSING PARTS
            for(WorkOrderLineItem parts : partsList){
                Id returnWoliId;
                if(parentChildWoliMap != null && parts.ParentWorkOrderLineItemId != null && parentChildWoliMap.containsKey(parts.ParentWorkOrderLineItemId)){
                    returnWoliId = parentChildWoliMap.get(parts.ParentWorkOrderLineItemId);
                }
                WorkOrderLineItem reqPart = new WorkOrderLineItem();
                reqPart.Case__c = parts.Case__c;        
                reqPart.WorkOrderId = parts.WorkOrderId;
                reqPart.WorkOrderlineItemType__c = TS_Constants.WOLI_STATUS_REQUIRED;         
                reqPart.Status = TS_Constants.WOLI_STATUS_OPEN;
                reqPart.ParentWorkOrderLineItemId = returnWoliId;
                reqPart.PricebookEntryId  = parts.PricebookEntryId;
                reqPart.Quantity = parts.Quantity;
                reqPart.RecordTypeId = reqPartRecordType;

                //DOO-4769 XEN REYES August 18, 2020
                reqPart.Unit_Price__c = parts.Unit_Price__c;
                reqPart.DirectToCustomer__c = parts.DirectToCustomer__c;
                
                matList.add(reqPart);                
            }
        }            
        //GET ALL COUNTRY SETTINGS
        csList = [SELECT Id, Active__c, Country__c, IsLabour__c, Product__c, WorkOrderType__c FROM CountrySetting__c WHERE Active__c = true AND Country__c IN: salesOrgs AND IsLabour__c = true AND WorkOrderType__c IN: parentWoTypes];                
        //SET ALL CS
        if(csList != null && csList.size() > 0){
            for(CountrySetting__c cs : csList){        
                    products.add(cs.Product__c);                                                
                    csMap.put(cs.Country__c + cs.WorkOrderType__c , cs);                                
            }    
            //GET ALL PRICE BOOK ENTRY
            pbeList = [SELECT Id, Product2Id, Sales_Organization__c FROM PricebookEntry WHERE IsActive = true AND Product2Id IN:products AND Sales_Organization__c IN:salesOrgs];            
            if(pbeList != null && pbeList.size() > 0){
                for(PricebookEntry pbe: pbeList){                    
                    pbeMap.put(pbe.Product2Id+pbe.Sales_Organization__c, pbe);
                }
            }                
            //GET ALL SALES ORG DATA
            sOrgDataList = [SELECT Id, APTS_Product__c, APTS_Sales_Org_Data_Name__c, APTS_Material_Pricing_Group_ID__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product__c IN:products AND APTS_Sales_Org_Data_Name__c IN:modifiedSalesOrgs];
            if(sOrgDataList != null && sOrgDataList.size() > 0){
                for(APTS_Sales_Org_Data__c sOrg: sOrgDataList){
                    sOrgMap.put(String.valueOf(sOrg.APTS_Product__c) + sOrg.APTS_Sales_Org_Data_Name__c, sOrg);
                }
            }
        }

        for(WorkOrderLineItem woli : returnWoliList){                            
            Boolean servMatEmpty = true;            
            //CHECK IF CS IS NULL, IF NULL THEN SKIP
            if(extWoliMap != null && woli.RelateTo__c != null && extWoliMap.containsKey(woli.RelateTo__c) && csList != null && csList.size() > 0){
                WorkOrderLineItem origWoliOld = extWoliMap.get(woli.RelateTo__c);                
                //SET SALES ORG
                String salesOrg;
                String modifSalesOrg;    
                if(origWoliOld.WorkOrder.SalesOrganization__c != null){
                    salesOrg = String.valueOf(origWoliOld.WorkOrder.SalesOrganization__c);
                    modifSalesOrg = salesOrg.SubStringAfter('_');
                }    

                String CSKey;
                if(salesOrg != null && origWoliOld.WorkOrderType__c != null){
                    CSKey = salesOrg + origWoliOld.WorkOrderType__c;
                }
                //LOOP THROUGH SERVICE MATERIALS
                for(CountrySetting__c cs : csList){
                    if(CSKey != null && csMap.containsKey(CSKey)){    
                        //GET WOLI PBENTRY                   
                        Id pbeId;                            
                        if(salesOrg != null && pbeList != null && pbeMap != null && pbeMap.containsKey(csMap.get(CSKey).Product__c + salesOrg) && pbeMap.get(csMap.get(CSKey).Product__c + salesOrg) != null && pbeMap.get(csMap.get(CSKey).Product__c + salesOrg).Id != null){
                            pbeId = pbeMap.get(csMap.get(CSKey).Product__c + salesOrg).Id;
                        }                                      
                        //GET PRODUCT ID STRING
                        String prodId;
                        if(csMap.get(CSKey) != null && csMap.get(CSKey).Product__c != null){
                                prodId = String.valueOf(csMap.get(CSKey).Product__c);                    
                        }        
                        //GET MATERIAL PRICING GROUP ID
                        String sOrgPriceGroup;
                        if(prodId != null && modifSalesOrg != null  && sOrgMap.containsKey(prodId + modifSalesOrg) && sOrgMap.get(prodId + modifSalesOrg) != null && sOrgMap.get(prodId + modifSalesOrg).APTS_Material_Pricing_Group_ID__c != null){                            
                            sOrgPriceGroup = String.valueOf(sOrgMap.get(prodId + modifSalesOrg).APTS_Material_Pricing_Group_ID__c);
                        }                  
                        //INTERFACE FOR CREATE DEFAULT LABOUR MATERIAL                    
                        WorkOrderLineItem newLabor = new WorkOrderLineItem();
                        newLabor.PricebookEntryId = pbeId;
                        newLabor.Case__c = woli.Case__c;
                        newLabor.ParentWorkOrderLineItemId = woli.Id;
                        newLabor.WorkOrderId = woli.WorkOrderId;
                        newLabor.RecordTypeId = servMatRecordType;
                        newLabor.Warranty__c = TS_Constants.WARRANTY_NONE;
                        newLabor.WorkOrderLineItemType__c = TS_Constants.TYPE_SERVICE;
                        newLabor.Quantity = 1;
                        newLabor.Discount = 0;
                        newLabor.IsLabour__c = true;                        
                        //WO PA
                        if(origWoliOld.PhysicalAsset__c == null){   
                            //CREATE DEFAULT LABOUR MATERIAL
                            servMatEmpty = false;                        
                            matList.add(newLabor); 
                        }
                        //WITH PA
                        else {  
                            //CHECK ACTIVE WARRANTY                
                            if(origWoliOld.PhysicalAsset__r.ActiveWarranty__c == true){                                           
                                //CHECK FOR ALWAYS CHARGEABLE                
                                if(sOrgPriceGroup == TS_Constants.SAP_03){                       
                                    //CREATE DEFAULT LABOUR MATERIAL
                                    servMatEmpty = false;
                                    matList.add(newLabor);                        
                                }
                                else {                                    
                                    //CREATE SERVICE MATERIAL UNDER WARRANTY                
                                    WorkOrderLineItem newServMatWar = new WorkOrderLineItem();
                                    newServMatWar.PricebookEntryId = pbeId;
                                    newServMatWar.Case__c = woli.Case__c;
                                    newServMatWar.ParentWorkOrderLineItemId = woli.Id;
                                    newServMatWar.WorkOrderId = woli.WorkOrderId;
                                    newServMatWar.RecordTypeId = servMatRecordType;
                                    newServMatWar.Warranty__c = TS_Constants.WARRANTY_K1;
                                    newServMatWar.WorkOrderLineItemType__c = TS_Constants.TYPE_SERVICE;
                                    newServMatWar.Quantity = 1;
                                    newServMatWar.Discount = 100;
                                    newServMatWar.IsLabour__c = true;
                                    servMatEmpty = false;
                                    matList.add(newServMatWar);                        
                                }
                            }
                            else {
                                //CHECK PHYSICAL ASSET UNDER CONTRACT        
                                Datetime dt = (Datetime) DateTime.now();                                                                
                                if(origWoliOld.PhysicalAsset__r.EndDate__c >= dt.date() &&
                                    (origWoliOld.PhysicalAsset__r.AssetStatus__c == TS_Constants.PA_STATUS_ACTIVATED ||
                                    origWoliOld.PhysicalAsset__r.AssetStatus__c == TS_Constants.PA_STATUS_PENDINGCANCELATION ||
                                    origWoliOld.PhysicalAsset__r.AssetStatus__c == TS_Constants.PA_STATUS_PENDINGACTIVATION )
                                ){                                    
                                    //CHECK FOR COVERAGE
                                    if(origWoliOld.PhysicalAsset__r.LabourChargeCoverage__c != null && origWoliOld.PhysicalAsset__r.LabourChargeCoverage__c != 0){                                     
                                        //CREATE SERVICE MATERIAL WITH COVERAGE                          
                                        WorkOrderLineItem newServMat = new WorkOrderLineItem();
                                        newServMat.PricebookEntryId = pbeId;
                                        newServMat.Case__c = woli.Case__c;
                                        newServMat.ParentWorkOrderLineItemId = woli.Id;
                                        newServMat.WorkOrderId = woli.WorkOrderId;
                                        newServMat.RecordTypeId = servMatRecordType;
                                        newServMat.Warranty__c = TS_Constants.WARRANTY_YR;
                                        newServMat.WorkOrderLineItemType__c = TS_Constants.TYPE_SERVICE;
                                        newServMat.Quantity = 1;
                                        newServMat.Discount = origWoliOld.PhysicalAsset__r.LabourChargeCoverage__c;
                                        newServMat.IsLabour__c = true;
                                        servMatEmpty = false;
                                        matList.add(newServMat);                        
                                    }
                                    else {                                                             
                                        //CREATE DEFAULT LABOUR MATERIAL                                                                       
                                        servMatEmpty = false;
                                        matList.add(newLabor);                        
                                    }   
                                }
                                else {                                                             
                                    //CREATE DEFAULT LABOUR MATERIAL                                    
                                    servMatEmpty = false;
                                    matList.add(newLabor);                        
                                }   
                            }
                        }
                        //DOO-5356 Pandian Sundaramoorthy April 9, 2021
                        WorkOrderLineItem retWoliUpdate = new WorkOrderLineItem(Id = woli.Id, ServiceMaterialsLoaded__c = true);
                		returnWoliListUpdate.add(retWoliUpdate);
                    }                 
                }             
            }

            //UPDATE RETURN NEEDED TASK PROCESSED
            if(servMatEmpty == true){
                WorkOrderLineItem retWoliUpdate = new WorkOrderLineItem(Id = woli.Id, Return_Needed_Parts__c = true);
                returnWoliListUpdate.add(retWoliUpdate);
            }                                    
            //TO AVOID DUPLICATE CASE IDS ON SOBJ UPDATE
            if(uniqueCases.contains(woli.Case__c) == false){                      
                //UPDATE CASE RETURN NEEDED FIELD
                //UPDATE CASE SUB STATUS
                Case woliCase = new Case(Id = woli.Case__c, CaseSubStatus__c = TS_Constants.CASE_SUBSTATUS_ORDEROPEN, ReturnNeeded__c = true);                    
                caseList.add(woliCase);
                uniqueCases.add(woli.Case__c);                                    
            }                    
        }  
        
        try {
            //NEW SERV MATERIALS FOR INSERT
            if(matList != null && matList.size() > 0){    
                insert matList;
            }
            //RETURN TASK FOR UPDATE
            if(returnWoliListUpdate != null && returnWoliListUpdate.size() > 0){
                sObjToUpdate.addAll((List<SObject>)(returnWoliListUpdate));
            }
            //PARENT CASES FOR UPDATE
            if(caseList != null && caseList.size() > 0){                 
                sObjToUpdate.addAll((List<SObject>)(caseList));         
            }
            //ORIG TASK FOR UPDATE
            if(origWoliList != null && origWoliList.size() > 0){
                sObjToUpdate.addAll((List<SObject>)(origWoliList));
            }
            if(sObjToUpdate != null && sObjToUpdate.size() > 0){
                update sObjToUpdate;
            }
        }
        catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          June 30, 2020
    * @description   DOO-4623 Populate product on WOLI, converted from Flows TS_Populate_Product_on_WOLI and TS_Populate Pricebook Entry - V3
    * @revision(s)   
    */
    public void populateProduct(List<SObject> newList){     
        CustomLogging.push('populateProduct', 'WorkOrderLineItemTriggerHandler');        
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> woliToUpdatePA = new List<WorkOrderLineItem>();
        Set<Id> paSet = new Set<Id>();
        Set<Id> cseSet = new Set<Id>();
        Set<Id> woSet = new Set<Id>();
        Map<Id, PhysicalAsset__c> paMap = new Map<Id, PhysicalAsset__c>();
        Map<Id, Case> cseMap = new Map<Id, Case>();
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>();
        Map<String,PricebookEntry> pbeMap = new Map<String,PricebookEntry>();
        Set<String> prodSet = new Set<String>();
        Set<String> pbookSet = new Set<String>();    
        
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){ 
            if(newWoli.Case__c != null && newWoli.WorkOrderId != null){                        
                //POPULATE PBE AFTER CONVERSION
                if(newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && newWoli.Created_Manually__c == true && newWoli.Populate_Pricebook__c == false){                               
                    woSet.add(newWoli.WorkOrderId);                                     
                    woliToUpdate.add(newWoli);           
                    cseSet.add(newWoli.Case__c); 
                }
                //POPULATE PBE AFTER ADDING SERVICE JOB (WITHOUT PA)
                else if(newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && newWoli.Is_Additional_Service_Job__c == true && newWoli.Populate_Pricebook__c == false && newWoli.PhysicalAsset__c == null && newWoli.Product__c != null){                                                                            
                    woSet.add(newWoli.WorkOrderId);
                    woliToUpdate.add(newWoli);                        
                    prodSet.add(newWoli.Product__c); 
                    
                }                
                //PRE-CHECKING FOR POPULATE PBE AFTER ADDING SERVICE JOB (WITH PA)            
                else if(newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && newWoli.Is_Additional_Service_Job__c == true && newWoli.Populate_Pricebook__c == false && newWoli.PhysicalAsset__c != null){                                                        
                    woSet.add(newWoli.WorkOrderId);                                
                    paSet.add(newWoli.PhysicalAsset__c);
                    woliToUpdatePA.add(newWoli);
                }     
            }       
        }
        
        if(cseSet != null){    
            cseMap = getWoliRelatedCaseMap(cseSet);
        }

         if(woSet != null){
            for(WorkOrder wo : [SELECT Id, Pricebook2Id FROM WorkOrder WHERE Id IN :woSet]){
                woMap.put(wo.Id, wo);  
            }
        }

        if(paSet != null && woliToUpdatePA != null && woliToUpdatePA.size() > 0){
            for(PhysicalAsset__c pa : [SELECT Id, Product__c FROM PhysicalAsset__c WHERE Id IN :paSet]){
                paMap.put(pa.Id, pa);  
                prodSet.add(pa.Product__c);
            }    
        }

        //POPULATE PBE AFTER ADDING SERVICE JOB (WITH PA)
        if(woliToUpdatePA != null && woliToUpdatePA.size() > 0){        
            for(WorkOrderLineItem newWoli : woliToUpdatePA){
                if(newWoli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && newWoli.Is_Additional_Service_Job__c == true && newWoli.Populate_Pricebook__c == false && newWoli.PhysicalAsset__c != null && paMap.get(newWoli.PhysicalAsset__c).Product__c != null && newWoli.Product2Id != paMap.get(newWoli.PhysicalAsset__c).Product__c){
                    woliToUpdate.add(newWoli);
                }
            }
        }
        
        //POPULATE PRICE BOOK ENTRY
        if(woliToUpdate != null && woliToUpdate.size() > 0 && woMap != null && woMap.size() > 0){               
            for(WorkOrderLineItem newWoli : woliToUpdate){                                                          
                if(cseMap != null && cseMap.size() > 0 && cseMap.get(newWoli.Case__c).ProductId != null){
                    prodSet.add(cseMap.get(newWoli.Case__c).ProductId);
                }            
                if(woMap.get(newWoli.WorkOrderId).Pricebook2Id != null){                                
                    pbookSet.add(woMap.get(newWoli.WorkOrderId).Pricebook2Id);
                }
            }            
            List<PricebookEntry> pbeList = [SELECT Id,Pricebook2Id, Product2Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id IN:pbookSet AND Product2Id IN:prodSet];                    
            for(PricebookEntry pbe : pbeList){        
                if(pbe.Pricebook2Id != null && pbe.Product2Id != null){                    
                    pbeMap.put(String.valueOf(pbe.Pricebook2Id) + String.valueOf(pbe.Product2Id), pbe);
                }                
            }

            //STAMP PBE TO WOLI
            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){              
                //ASSIGN PRODUCTID DEPENDING ON SCENARIO
                String ProductId;
                        
                //FROM CASE : POPULATE PBE AFTER CONVERSION
                if(newWoli.Created_Manually__c == true && cseMap.get(newWoli.Case__c) != null && cseMap.get(newWoli.Case__c).ProductId != null){
                    ProductId = String.valueOf(cseMap.get(newWoli.Case__c).ProductId);                    
                }
                //FROM WOLI : POPULATE PBE AFTER ADDING SERVICE JOB (WITHOUT PA)
                else if(newWoli.Is_Additional_Service_Job__c == true && newWoli.PhysicalAsset__c == null && newWoli.Product__c != null){
                    ProductId = String.valueOf(newWoli.Product__c);                    
                }
                //FROM PA : POPULATE PBE AFTER ADDING SERVICE JOB (WITH PA)    
                else if(newWoli.Is_Additional_Service_Job__c == true  && newWoli.PhysicalAsset__c != null && paMap.get(newWoli.PhysicalAsset__c) != null && paMap.get(newWoli.PhysicalAsset__c).Product__c != null){
                    ProductId = String.valueOf(paMap.get(newWoli.PhysicalAsset__c).Product__c);                                        
                }
                                
                if(woMap.get(newWoli.WorkOrderId).Pricebook2Id != null && ProductId != null && woliToUpdate.contains(newWoli)){ 
                    String Pricebook2Id = String.valueOf(woMap.get(newWoli.WorkOrderId).Pricebook2Id);
                    if(pbeMap.get(Pricebook2Id + ProductId) != null){                                                
                        newWoli.Populate_Pricebook__c = true;
                        newWoli.PricebookEntryId = pbeMap.get(Pricebook2Id + ProductId).Id;
                    }                
                }                
            }
        }
        CustomLogging.pop();        
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          July 01, 2020
    * @description   DOO - 4621 Set work time stamps on WOLI converted from PB TS_set_Work_time_stamps_on_WOLI
    * @revision(s)   
    */
    public void setWorkTimeStamps(List<SObject> newList, Map<Id,SObject> oldMapItems){     
        CustomLogging.push('setWorkTimeStamps', 'WorkOrderLineItemTriggerHandler');               
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){        
            //START WORK
            if(newWoli.Status == TS_Constants.WOLI_STATUS_STARTWORK && newWoli.StartDate__c != null && newWoli.Status != oldWoli.get(newWoli.Id).Status && newWoli.WorkOrderLineItemType__c == TS_Constants.TS_Type_Task){
                newWoli.StartedWorkTime__c = newWoli.StartDate__c;
            }
            //ON SITE
            if(newWoli.Status == TS_Constants.WOLI_STATUS_ONSITE && newWoli.StartDate__c != null && newWoli.Status != oldWoli.get(newWoli.Id).Status && newWoli.WorkOrderLineItemType__c == TS_Constants.TS_Type_Task){
                newWoli.OnsiteTimestamp__c = newWoli.StartDate__c;                
            }               
        }  
        CustomLogging.pop();        
    }

    /*
    * @author        Karen Mae Hung
    * @date          July 16, 2020
    * @description   DOO-4533 Method to check used part added that has material pricing group id of 05 and to stamp in in Physical Asset
    * @revision(s)   
    *                08/04/2020 DOO-4650 Francis Allen Alindogan added functionality to remove WF Suggestion
    *                08/28/2020 DOO-4675 DOO-4676 Francis Allen Alindogan added functionality to remove Waterfilter Task from MCO and create Opportunity/Case
    */
    public void stampWTSParts(List<SObject> newList,Map<Id,SObject> oldMapItems,Map<Id,SObject> newMapItems){
        CustomLogging.push('stampWTSPart', 'WorkOrderLineItemTriggerHandler');       
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        Map<Id,WorkOrderLineItem> newWoli = (Map<Id,WorkOrderLineItem>) newMapItems;        
        Map<String,String> paWoliMap = new Map<String, String>();
        try{
            //get completed WOLI's
            List<String> completedWOLI = new List<String>();
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){

                if(oldWoli.get(woli.Id).Status != woli.Status && woli.Status == TS_Constants.STATUS_COMPLETED && woli.WTSPerformed__c == true){
                    completedWOLI.add(woli.Id);
                    paWoliMap.put(woli.PhysicalAsset__c, woli.JDELineItemNumber__c);
                }
            }            
            if(!completedWOLI.isEmpty()){
                Map<String, List<String>> assetProductListMap = getWFparts(completedWOLI,newWoli);                
                //FOR WTS STAMPING
                if(assetProductListMap.keySet() != null){
                    List<PhysicalAsset__c> assetForUpdate = new List<PhysicalAsset__c>();
                    for(PhysicalAsset__c asset : [SELECT Id, Last_Used_WTS_Part_1__c,Last_Used_WTS_Part_2__c FROM PhysicalAsset__c WHERE Id IN :assetProductListMap.keySet()]){
                        for(Integer i = 0; i < 2; i++){
                            if(i == 0){
                                asset.Last_Used_WTS_Part_1__c = assetProductListMap.get(asset.Id)[i];
                            }else if(i == 1){
                                if(assetProductListMap.get(asset.Id).size() > 1){
                                    asset.Last_Used_WTS_Part_2__c = assetProductListMap.get(asset.Id)[i];
                                }else{
                                    asset.Last_Used_WTS_Part_2__c = null;  
                                }
                            }
                        }                        
                        assetForUpdate.add(asset);      
                    }

                    //FOR WTS FIELDS FLUSHING/REMOVAL DOO-4650 DOO-4675 DOO-4676
                    if(!assetForUpdate.isEmpty()){
                        update(assetForUpdate);
                        TS_QueueableProcesses cs = new TS_QueueableProcesses();
                        cs.METHOD_EVALUATE_COMPLETED_SAP05 = true;
                        cs.paSet = assetProductListMap.keySet();
                        cs.woliList = completedWOLI;
                        cs.extWoliNewMap = extWoliNewMap;
                        cs.woliReferenceMap = paWoliMap;
                        System.enqueueJob(cs);
                    }
                }
            }                        
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WoliTriggerHandlerException('Force to throw an exception');
            }

        }
        catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());       
        }        
        CustomLogging.pop();
    }

    /*
    * @author        Karen Mae Hung
    * @date          July 17, 2020
    * @description   reusable method to check WTSPerformed and get wf parts
    * @revision(s)   
    */

    public Map<String, List<String>> getWFparts(List<String> completedWOLI, Map<Id,WorkOrderLineItem> newMapItems){
        CustomLogging.push('getWFparts', 'WorkOrderLineItemTriggerHandler'); 
        
        Map<Id,WorkOrderLineItem> newWoli = (Map<Id,WorkOrderLineItem>) newMapItems;
        Map<String, List<String>> assetProductsMap = new Map<String, List<String>>();

        if(!completedWOLI.isEmpty()){
            //get used parts and products of completed WOLI's
            Map<String,String> orgProductMap = new Map<String,String>();
            Map<String,String> woliAssetMap = new Map<String,String>();
            List<String> prodList = new List<String>();
            for(WorkOrderLineItem usedPart : [SELECT Id,ParentWorkOrderLineItemId,ParentWorkOrderLineItem.PhysicalAsset__c, ParentWorkOrderLineItem.PhysicalAsset__r.Last_Used_WTS_Part_1__c, ParentWorkOrderLineItem.PhysicalAsset__r.Last_Used_WTS_Part_2__c, WorkOrder.SalesOrganization__c, Product2Id FROM WorkOrderLineItem 
                                            WHERE ParentWorkOrderLineItemId IN :completedWOLI
                                            AND WorkOrderLineItemType__c = :TS_Constants.TYPE_API_USEDPARTS ORDER BY CreatedDate DESC]){               
                orgProductMap.put(usedPart.WorkOrder.SalesOrganization__c + usedPart.Product2Id, usedPart.ParentWorkOrderLineItemId);
                prodList.add(usedPart.Product2Id);
                woliAssetMap.put(usedPart.ParentWorkOrderLineItemId, usedPart.ParentWorkOrderLineItem.PhysicalAsset__c);
            }
            

            //update parent WOLI of used part if pricing group is 'SAP_05'
            if(!prodList.isEmpty()){
                for(APTS_Sales_Org_Data__c orgData : [SELECT Id, APTS_Product__c, APTS_Sales_Org_Data_Name__c FROM APTS_Sales_Org_Data__c
                                                    WHERE APTS_Material_Pricing_Group_ID__c = :TS_Constants.SAP_05
                                                    AND APTS_Product__c IN :prodList]){
                    if(orgProductMap.containsKey('SAP_'+orgData.APTS_Sales_Org_Data_Name__c + orgData.APTS_Product__c)){
                        WorkOrderLineItem item = newWoli.get(orgProductMap.get('SAP_'+ orgData.APTS_Sales_Org_Data_Name__c + orgData.APTS_Product__c));
                        
                        if(Trigger.isBefore)item.WTSPerformed__c = true;

                        if(woliAssetMap.containsKey(item.Id) && Trigger.isAfter){
                            if(assetProductsMap.containsKey(woliAssetMap.get(item.Id))){
                                assetProductsMap.get(woliAssetMap.get(item.Id)).add(orgData.APTS_Product__c);       
                            }else{
                                assetProductsMap.put(woliAssetMap.get(item.Id), new List<String>{orgData.APTS_Product__c});    
                            }
                        }
                    }
                }
            }   
        }
        
        CustomLogging.pop();
        return assetProductsMap;
    }

    /*
    * @author        Karen Hung
    * @date          July 14, 2020
    * @description   DOO - 4529 Flag Replace WTS based on  WTS Suggestion Treshold
    * @revision(s)   
    */
    public void flagWFSuggestion (List<SObject> newList){
        CustomLogging.push('flagWFSuggestion', 'WorkOrderLineItemTriggerHandler');
        
        Map<String, Integer> countryThresholdMap= new Map<String, Integer>();
        Map<String, Boolean> countryMergeMap = new Map<String, Boolean>();
        Map<WorkOrderLineItem, String> woliWorkOrderMap = new Map<WorkOrderLineItem, String>();
        Map<WorkOrderLineItem, String> woliAssetMap = new Map<WorkOrderLineItem, String>();

        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            
             if((woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE || woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK) &&
                woli.WorkOrderType__c != TS_Constants.TYPE_S25_ROUTESALES && 
                woli.WorkOrderType__c != TS_Constants.WO_TYPE_S22_COUNTERREADINGFUP && 
                woli.WorkOrderType__c != TS_Constants.WO_TYPE_S15_1STLINECM && 
                woli.WorkOrderType__c != TS_Constants.ORDER_S40 && 
                woli.WorkOrderType__c != TS_Constants.ORDER_S41 &&
                woli.PhysicalAsset__c != null){
                
                woliAssetMap.put(woli, woli.PhysicalAsset__c);
                woliWorkOrderMap.put(woli,woli.WorkOrderId);
            }
        }

        if(woliAssetMap != null){

            //Karen Hung 07.09.2020 DOO-4866 check open s32
            Set<String> excludedStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED};
            List<WorkOrderLineItem> openS32List = [SELECT Id, PhysicalAsset__c FROM WorkOrderLineItem WHERE WorkOrderType__c = :TS_Constants.TYPE_S32_WATERFILTER
                                                  AND PhysicalAsset__c IN :woliAssetMap.values()
                                                  AND Id NOT IN :newList
                                                  AND Status NOT IN :excludedStatus];
            
            Set<String> assetwithS32 = new Set<String>();
            if(!openS32List.isEmpty()){
                for(WorkOrderLineItem lineItem : openS32List){
                    assetwithS32.add(lineItem.PhysicalAsset__c);
                }
            }
            
            //get sales org for Country Setting filter
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>([SELECT Id, SalesOrganization__c FROM WorkOrder WHERE Id IN :woliWorkOrderMap.values()]);
            Set<String> salesOrgSet = new Set<String>();
            for(WorkOrder wo: workOrderMap.values()){
                salesOrgSet.add(wo.SalesOrganization__c);         
            }

            //get contract trigger setting to check threshold
            List<CountrySetting__c> csList = [SELECT Id, Recordtype.Name, Merge_WTS__c, Country__c, WTS_Suggestion_Treshold__c from CountrySetting__c WHERE Active__c = true 
                                             AND Country__c IN :salesOrgSet
                                             AND (Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_CONTRACTTRIGGERSETTING OR Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MERGEWTSWITHPM)];
            if(!csList.isEmpty()){
                for(CountrySetting__c cset : csList){
                   if(cset.Recordtype.Name ==TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_CONTRACTTRIGGERSETTING){ //Contract Trigger Setting
                        countryThresholdMap.put(cset.Country__c, cset.WTS_Suggestion_Treshold__c != null ? Integer.valueOf(cset.WTS_Suggestion_Treshold__c) : 0);
                   }else{
                        countryMergeMap.put(cset.Country__c, cset.Merge_WTS__c);
                   }
                }
            } 

            Map<Id, PhysicalAsset__c> assetMap = new Map<Id, PhysicalAsset__c>( [SELECT Id, WTSPlanned__c, EndDate__c, IncludesPreventiveMaintenanceCoverage__c, IncludesWTSCoverage__c, Machine_Care__c, NextWTSDate__c, Last_Used_WTS_Part_1__c, Last_Used_WTS_Part_2__c, Last_Used_WTS_Part_1__r.Name, Last_Used_WTS_Part_2__r.Name, Last_Used_WTS_Part_1__r.ProductCode,Last_Used_WTS_Part_2__r.ProductCode 
                                                FROM PhysicalAsset__c
                                                WHERE Id IN :woliAssetMap.values()]);


            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){

                //Karen Hung 07.09.2020 DOO-4866 get assets with open s32
                Boolean withOpenS32 = false;
                if(assetwithS32 != null && assetwithS32.contains(woli.PhysicalAsset__c)){
                    withOpenS32 = true;
                }

                 //general criteria
                 if(woliAssetMap.containsKey(woli) &&
                  assetMap.containsKey(woliAssetMap.get(woli)) &&
                  woliWorkOrderMap.containsKey(woli) && 
                  workOrderMap.containsKey(woliWorkOrderMap.get(woli))){

                    PhysicalAsset__c assetRec = assetMap.get(woliAssetMap.get(woli));
					WorkOrder woRec = workOrderMap.get(woliWorkOrderMap.get(woli));

                    String partString = (assetRec.Last_Used_WTS_Part_1__c != null || assetRec.Last_Used_WTS_Part_2__c != null ? 
                                        ( '(' + (assetRec.Last_Used_WTS_Part_1__c != null ? (assetRec.Last_Used_WTS_Part_1__r.ProductCode + ' - ' + assetRec.Last_Used_WTS_Part_1__r.Name ) : '' ) +
                                        (assetRec.Last_Used_WTS_Part_1__c != null && assetRec.Last_Used_WTS_Part_2__c != null ? ' | ' : '' ) + 
                                        (assetRec.Last_Used_WTS_Part_2__c != null ? (assetRec.Last_Used_WTS_Part_2__r.ProductCode + ' - ' + assetRec.Last_Used_WTS_Part_2__r.Name ) : '' ) + ')') : '');
                    
                    //Karen Hung DOO-4820 always put 'Change WF....' on waterfilter suggestion if Workordertype= S32 or MCO Waterfilter (DOO-4890)
                    if(woli.WorkOrderType__c == TS_Constants.TYPE_S32_WATERFILTER ||
                       (woli.WorkOrderType__c ==TS_Constants.WO_TYPE_S20_MACHINECARE && (woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_WATERFILTER || woli.WorkOrderLineItemType__c.contains('W')))){

                        woli.Replace_WTS__c = true;
                        woli.Waterfilter_Suggestion__c = TS_Constants.SUGGESTION_2 + partString;

                    }else if(countryMergeMap.containsKey(woRec.SalesOrganization__c)){

                        Boolean withinThreshold = false;
                        withinThreshold =  (assetRec.WTSPlanned__c == false || (assetRec.WTSPlanned__c == true && withOpens32)) &&
                            			   countryThresholdMap.containsKey(woRec.SalesOrganization__c) &&
                                           assetRec.NextWTSDate__c != null &&
                                           assetRec.NextWTSDate__c.addDays(countryThresholdMap.get(woRec.SalesOrganization__c) * -1) <= Date.Today();
                                           

                        //Karen Hung DOO-4938 23.09.2020 added includes wts and transfered threshold checking in the variable | 07.09.2020 DOO-4866 added withOpenS32 in criteria
                        //DOO-4529 Allowed to change WF : if Merge WTS with PM = false on Tasks and S20 EXCEPT S25, S22, S15, S40, S41 and Non-MCO
                        if((countryMergeMap.get(woRec.SalesOrganization__c) == false || (countryMergeMap.get(woRec.SalesOrganization__c) == true && !assetRec.IncludesPreventiveMaintenanceCoverage__c)) &&
                           assetRec.IncludesWTSCoverage__c &&
                           withinThreshold && 
                           !(assetRec.Machine_Care__c != TS_Constants.MACHINE_CLEAN_OPERATING && woli.workorderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE) &&
                           assetRec.EndDate__c >= Date.today() &&
                           !(assetRec.NextWTSDate__c < Date.today() && !withOpens32)){
                        
                                woli.Replace_WTS__c = true;
                                woli.Waterfilter_Suggestion__c = TS_Constants.SUGGESTION_1 + partString;
                                                            

                        //KAREN HUNG DOO-4938 23.09.2020 added includes wts criteria
                        //DOO-4532 27.7.2020 Change WF... : if Merge WTS with PM = true on a PM Task
                        }else if(countryMergeMap.get(woRec.SalesOrganization__c) == true &&
                                assetRec.IncludesWTSCoverage__c && 
                                withinThreshold &&
                                woli.WorkOrderType__c == TS_Constants.TYPE_S30_PREVMAINTENANCE){

                                woli.Replace_WTS__c = true;
                                woli.Waterfilter_Suggestion__c = TS_Constants.SUGGESTION_2 + partString;
                        
                        //KAREN HUNG DOO-4938 23.09.2020 added includes wts, includes PM and withinThreshold criteria
                        //DOO-4673 27.7.2020 WF normally changed during PM : if Merge WTS with PM = true on non-PM Tasks  
                        }else if(countryMergeMap.get(woRec.SalesOrganization__c) == true &&
								assetRec.IncludesPreventiveMaintenanceCoverage__c &&
								assetRec.IncludesWTSCoverage__c &&
                                withinThreshold &&
                                woli.WorkOrdertype__c != TS_Constants.TYPE_S30_PREVMAINTENANCE &&
                                !(assetRec.Machine_Care__c != TS_Constants.MACHINE_CLEAN_OPERATING && woli.workorderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE) &&
                                assetRec.EndDate__c >= Date.Today() &&
                                !(assetRec.NextWTSDate__c < Date.today() && !withOpens32)){

                                woli.Waterfilter_Suggestion__c = TS_Constants.SUGGESTION_3 + partString;

                        }

                    }
   
                }

            }       
            
        }
        CustomLogging.pop();   
    }

    /*
    * @author        Karen Hung
    * @date          Aug 5, 2020
    * @description   DOO - 4631 Method to replace TS_RoutesalesRTWOLI workflow
    * @revision(s)   
    */
    public void populateRecordtypeId (List<SObject> newList){
        CustomLogging.push('populateRecordtypeId', 'WorkOrderLineItemTriggerHandler');
        String routeSalesRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECTYPE_ROUTESALES);
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.WorkOrderType__c == TS_Constants.TYPE_S25_ROUTESALES){
                woli.RecordtypeId = routeSalesRecordType;
            }   
        }
        CustomLogging.pop();    
    }
    
    /*
    * @author        Abram Vixen Reyes
    * @date          August 27, 2020
    * @description   DOO - 4743 Process builder to trigger: Fixed Costs and Warranty
    * @revision(s)   
    */
    public void SET_FIXED_COST_MATERIALS (List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id,SObject> oldMapItems){     
        CustomLogging.push('SET_FIXED_COST_MATERIALS', 'WorkOrderLineItemTriggerHandler');
    
        Map<Id,WorkOrderLineItem> oldWoli = (Map<Id,WorkOrderLineItem>) oldMapItems;
        Set<String> typesForFixedCost = new Set<String>{'S10','S30','S31','S32','S40','S41','S42','S43','S51','S52','S53'};
        List<Id> toProcess = new List<Id>();
    
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){
                        
            if((newWoli.Status == TS_Constants.WOLI_STATUS_SCHEDULED
                //DOO-5357 Pandian Sundaramoorthy April 8, 2021
               	|| newWoli.Status == TS_Constants.WOLI_STATUS_DISPATCHED
                || newWoli.Status == TS_Constants.WOLI_STATUS_RECEIVED)
                && newWoli.Status != oldWoli.get(newWoli.Id).Status 
                && newWoli.WorkOrderLineItemType__c == TS_Constants.TS_Type_Task
                && !newWoli.ReturnTask__c
                && !newWoli.ServiceMaterialsLoaded__c
                && typesForFixedCost.contains(newWoli.WorkOrderType__c)                
                ){
                toProcess.add(newWoli.Id);
            }           
        }
        
        if(!toProcess.isEmpty()){
            TS_FlowProcessor.executeFixCostFlow(toProcess, newMapItems);
        }
    
        CustomLogging.pop();        
    }
    
    /*
    * @author        Abram Vixen Reyes
    * @date          August 27, 2020
    * @description   DOO - 4743 Process builder to trigger: Fixed Costs and Warranty
    * @revision(s)   
    */
    public void EVALUATE_PARTS_WARRANTY (List<SObject> newList, Map<Id,SObject> oldMapItems){     
        CustomLogging.push('EVALUATE_PARTS_WARRANTY', 'WorkOrderLineItemTriggerHandler');
        
        try{
            
            Set<String> typesParentJobToEvaluate = new Set<String>{'S10','S30','S31','S32','S40','S41','S42','S43','S51','S52','S53'};
            Set<String> typePartsToEvaluate = new Set<String>{TS_Constants.TYPE_API_USEDPARTS, TS_Constants.TYPE_SERVICE, TS_Constants.WOLI_STATUS_MISSING};
            Set<String> countrySetTrim = new Set<String>();
            Set<Id> productIdSet = new Set<Id>();
            List<WorkOrderLineItem> toProcess = new List<WorkOrderLineItem>();
            List<Id> toCheckType = new List<Id>();
            
            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){                
                WorkOrderLineItem extWOLI = extWoliNewMap.get(newWoli.Id);                  
                if( newWoli.ParentWorkOrderLineItemId != null 
                   && newWoli.Quantity > 0
                   && typePartsToEvaluate.contains(newWoli.WorkOrderLineItemType__c)
                   && typesParentJobToEvaluate.contains(extWOLI.ParentWorkOrderLineItem.WorkOrderType__c)){
                       
                       toProcess.add(newWoli);
                       productIdSet.add(newWOLI.Product2Id);
                       countrySetTrim.add(extWOLI.WorkOrder.SalesOrganization__c.right(4));
                   }
            }
            
            if(!toProcess.isEmpty()){
                TS_FlowProcessor.executeWarrantyFlow(extWoliNewMap, toProcess, productIdSet, countrySetTrim, oldMapItems);
            }
            
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();        
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          Sep 09, 2020
    * @description   DOO - 4795 Method to populate Internal Order SAP from country default setting
    * @revision(s)   
    */
    public Map<Id, String> POPULATE_INTERNALORDERSAP(List<SObject> newList) {
        
        Map<Id, String> woliUpdateMap = new Map<Id,String>();        
        
        //GET ALL COUNTRY SETTING
        if(COUNTRYSETTING_INTERNALORDERSAP_MAP.isEmpty()){        
            List<CountrySetting__c> csList = [SELECT Country__c, Default_Internal_Order_SAP__c FROM CountrySetting__c    
                                              WHERE Active__c = true  
                                              AND RecordType.Name =: TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULTSAPINTERNALORDER];    
            if(!csList.isEmpty()){  
                for(CountrySetting__c cs : csList){ 
                    COUNTRYSETTING_INTERNALORDERSAP_MAP.put(cs.Country__c, cs);  
                }   
            }                       
        }
        //GET RECORD TYPE
        if (tsWOLIRecordType == null) {
            tsWOLIRecordType = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_API_NAME_WOLI, TS_Constants.TS_WOLI_RECORDTYPE_REGTASK);
        }                
        if(!COUNTRYSETTING_INTERNALORDERSAP_MAP.isEmpty()){                              
            //ASSIGN INTERNAL ORDER SAP
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){            
                if((String.isBlank(woli.InternalOrderSAP__c) || woli.InternalOrderSAP__c == null)&& woli.WorkOrderLineItemType__c == TS_Constants.TYPE_TASK && woli.RecordTypeId == tsWOLIRecordType && woli.WorkOrderType__c != TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && //CRITERIA
                   extWoliNewMap.get(woli.Id) != null && woli.Case__c != null && extWoliNewMap.get(woli.Id).Case__c != null &&  extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c != null && //NULL CHECKER
                   COUNTRYSETTING_INTERNALORDERSAP_MAP.get(extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c ) != null //CHECK IF WITHIN THE COUNTRY SETTINGS                
                  ){                            
                      woliUpdateMap.put(woli.Id, COUNTRYSETTING_INTERNALORDERSAP_MAP.get(extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c).Default_Internal_Order_SAP__c);
                  }
            }
        }        
        return woliUpdateMap;
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          Sep 10, 2020
    * @description   Helper method to perform WOLI update on the AFTER INSERT. Use this only on AFTER INSERT. Add new map for new fields to be updated
    * @revision(s)   
    */
    private void AFTERINSERT_WOLI_UPDATE(List<SObject> newList, Map<Id,String> JDELINEITEMNUMBER_MAP , Map<Id,String> INTERNALORDERSAP_MAP, Map<Id,String> THIRDPARTY_RESOURCE_MAP) {
        CustomLogging.push('AFTERINSERT_WOLI_UPDATE', 'WorkOrderLineItemTriggerHandler');
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            Boolean forUpdate = false;
            WorkOrderLineItem newWoli = new WorkOrderLineItem();
            newWoli.Id = woli.Id;
            newWoli.JDELineItemNumber__c = woli.WorkOrderLineItemNumber__c;
                  
            if(!JDELINEITEMNUMBER_MAP.isEmpty() && JDELINEITEMNUMBER_MAP.get(woli.Id) != null){                
                if(newWoli.JDELineItemNumber__c == null){
                    newWoli.JDELineItemNumber__c = JDELINEITEMNUMBER_MAP.get(woli.Id);
                }
                forUpdate = true;
            }
            
            if(!INTERNALORDERSAP_MAP.isEmpty() && INTERNALORDERSAP_MAP.get(woli.Id) != null){
                newWoli.InternalOrderSAP__c = INTERNALORDERSAP_MAP.get(woli.Id);                
                forUpdate = true;
            }
            
            if(!THIRDPARTY_RESOURCE_MAP.isEmpty() && THIRDPARTY_RESOURCE_MAP.get(woli.Id) != null){
                newWoli.ExecutingEngineer__c = THIRDPARTY_RESOURCE_MAP.get(woli.Id);
                newWoli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                forUpdate = true;
            }
            
            if(forUpdate == true){
                woliToUpdate.add(newWoli);
            }
        }
        if(!woliToUpdate.isEmpty()){
            try {
                update woliToUpdate;
            }
            catch (Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }         
        }
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          Sep 22, 2020
    * @description   Method to check appropriate action for S41 related tasks
                     DOO-4800 CANCEL CONTRACT ORDER WHEN CREATING S41 TASK                     
                     DOO-4801 CANCEL OPEN TASKS WHEN COMPLETING S41 TASK
    * @revision(s)   
    */
    public void cancelS41Related(List<SObject> newList, Map<Id,SObject> oldMapItems, Map<Id, String> JDELINEITEMNUMBER_MAP){
        CustomLogging.push('cancelS41Related', 'WorkOrderLineItemTriggerHandler');                    
        List<String> assetIds = new List<String>();                  
        Set<String> caseWoli = new Set<String>();
        Set<String> salesOrgSet = new Set<String>();         
        Map<Id, WorkOrderLineItem> oldWoli = new Map<Id, WorkOrderLineItem>();
        Map<String, String> paWoliMap = new Map<String, String>();        
        if(oldMapItems != null){
            oldWoli = (Map<Id, WorkOrderLineItem>) oldMapItems;
        }    
        
        //DOO-4800 CANCEL CONTRACT ORDER WHEN CREATING S41 TASK       
        if(Trigger.isInsert){        
            //GET ALL SALESORGS
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){            
                //CANCEL CONTRACT ORDER WHEN CREATING S41 TASK
                if( woli.WorkOrderType__c == TS_Constants.ORDER_S41 && extWoliNewMap.get(woli.Id).Case__r.SubType__c != TS_Constants.ORDER_INSTYPE_MOVEMENT && extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c != null){                       
                    salesOrgSet.add(extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c);                    
                }                                         
            }  
            //GET CSETTING
            if(!salesOrgSet.isEmpty() && salesOrgSet.size() > 0 && COUNTRYSETTING_CONTRACTTRIGGER_MAP.isEmpty()){
                List<CountrySetting__c> contractTriggerCSetting = [SELECT Id, Country__c, S41_Threshold__c, Active__c FROM CountrySetting__c    
                                                                   WHERE Active__c = true  
                                                                   AND Country__c IN :salesOrgSet
                                                                   AND Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_CONTRACTTRIGGERSETTING];    
                if(!contractTriggerCSetting.isEmpty()){  
                    for(CountrySetting__c CS_VAR : contractTriggerCSetting){ 
                        COUNTRYSETTING_CONTRACTTRIGGER_MAP.put(CS_VAR.Country__c, CS_VAR);  
                    }   
                }  
            }
            
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){                    
                if( !extWoliNewMap.isEmpty() && extWoliNewMap.get(woli.Id) != null && extWoliNewMap.get(woli.Id).PhysicalAsset__c != null && extWoliNewMap.get(woli.Id) != null && extWoliNewMap.get(woli.Id).Case__c != null && extWoliNewMap.get(woli.Id).Case__r.SubType__c != null && !COUNTRYSETTING_CONTRACTTRIGGER_MAP.isEmpty() && extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c != null && COUNTRYSETTING_CONTRACTTRIGGER_MAP.get(extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c).S41_Threshold__c != null && woli.Case__c != null && !JDELINEITEMNUMBER_MAP.isEmpty() && JDELINEITEMNUMBER_MAP.get(woli.Id) != null &&
                   woli.WorkOrderType__c == TS_Constants.ORDER_S41 && extWoliNewMap.get(woli.Id).Case__r.SubType__c != TS_Constants.ORDER_INSTYPE_MOVEMENT &&  woli.SLADate__c < Date.today().addDays(Integer.valueOf(COUNTRYSETTING_CONTRACTTRIGGER_MAP.get(extWoliNewMap.get(woli.Id).Case__r.SalesOrganization__c).S41_Threshold__c))){                       
                       assetIds.add(String.valueOf(extWoliNewMap.get(woli.Id).PhysicalAsset__c));            
                       paWoliMap.put(String.valueOf(extWoliNewMap.get(woli.Id).PhysicalAsset__c), JDELINEITEMNUMBER_MAP.get(woli.Id));
                   }                                         
            }  
            
            //CANCEL OPEN CONTRACT ORDER CASE
            if(!assetIds.isEmpty() && assetIds.size() > 0){                                       
                TS_QueueableProcesses cs = new TS_QueueableProcesses();
                cs.METHOD_CANCELCONTRACTORDER_S41 = true;
                cs.assetIds = assetIds;    
                cs.woliReferenceMap = paWoliMap;
                System.enqueueJob(cs);            
            }                    
        }
        
        
        //DOO-4801 CANCEL OPEN TASKS WHEN COMPLETING S41 TASK
        else if(Trigger.isUpdate){            
            for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){                            
                if( woli.WorkOrderType__c == TS_Constants.ORDER_S41 && woli.ReturnNeeded__c == false && woli.Return_Needed_S10__c == false && extWoliNewMap.get(woli.Id).Case__r.SubType__c != TS_Constants.ORDER_INSTYPE_MOVEMENT && woli.Status != oldWoli.get(woli.Id).Status && woli.Status == TS_Constants.STATUS_COMPLETED){                                           
                    caseWoli.add(String.valueOf(woli.Case__c));                    
                    paWoliMap.put(String.valueOf(woli.PhysicalAsset__c), woli.JDELineItemNumber__c);
                    assetIds.add(String.valueOf(woli.PhysicalAsset__c));            
                }                                         
            }  
            
            //CANCEL OPEN TASKS RELATED TO S41
            if(!caseWoli.isEmpty() && caseWoli.size() > 0){                                       
                TS_QueueableProcesses cs = new TS_QueueableProcesses();
                cs.METHOD_CANCELOPENTASK_S41 = true;  
                cs.woliReferenceMap = paWoliMap;  
                cs.assetIds = assetIds;               
                cs.caseWoli = caseWoli;                             
                System.enqueueJob(cs);            
            } 
        }
    }
    
    /*
    * @author        Abram Vixen Reyes
    * @date          October 21, 2020
    * @description   DOO - 4972 SF: Journey Trigger Work Order Line Item Rebuilding + Survey Invitation
    * @revision(s)   
    */
    public void SEND_EMAIL (List<SObject> newList, Map<Id,SObject> oldMapItems){     
        CustomLogging.push('SEND_EMAIL', 'WorkOrderLineItemTriggerHandler');
        
        try{
            
            Set<String> typesJobToEvaluate = new Set<String>{'S10','S15','S30','S31','S32','S60'}; //Should be the same with TS_AttachPDFTaskType Custom Label
                List<WorkOrderLineItem> toProcess = new List<WorkOrderLineItem>();
            
            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){                
                
                WorkOrderLineItem extWOLI = extWoliNewMap.get(newWoli.Id);
                WorkOrderLineItem oldWoli = (WorkOrderLineItem) (oldMapItems.get(newWoli.Id));
                
                if(newWoli.ParentWorkOrderLineItemId == null
                   && typesJobToEvaluate.contains(newWoli.WorkOrderType__c)
                   && newWoli.WorkOrderLineItemType__c == 'Task'
                   &&
                   // For Received in Mobile
                   ((newWoli.Status == 'Received' && newWoli.Sent_to_Mobile_Notif_Sent__c == false  
                   && oldWoli.Status != newWoli.Status) ||
                   // For Fulfillment Closure
                   (oldWoli.ReadytosendEmail__c != newWoli.ReadytosendEmail__c
                   && newWoli.ReadytosendEmail__c == true
                   && newWoli.Status == 'Completed'
                   && newWoli.Fulfillment_Notification_Sent__c == false
                   && extWOLI.Case__r.NoCaseClosureNotification__c == false))
                  ){
                      toProcess.add(newWoli);
                  }
            }
            
            if(!toProcess.isEmpty()){
                TS_SendEmail.SENDFROMWOLI(toProcess);
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();        
    }

    /*
    * @author        Francis Allen Alindogan
    * @date          Oct 30, 2020
    * @description   DOO-4624 Converted TS_OP_CO_Updates process builder to this method                     
    * @revision(s)   
    */
    public void OPCOUpdate(List<SObject> newList){
        CustomLogging.push('OPCOUpdate', 'WorkOrderLineItemTriggerHandler'); 
        List<PhysicalAsset__c> paList = new List<PhysicalAsset__c>();
        for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
            if(woli.OP_PCBchanged__c == true && woli.PhysicalAsset__c != null){
                PhysicalAsset__c pa = new PhysicalAsset__c(Id = woli.PhysicalAsset__c, OP_PCB_Changed__c = false);
                paList.add(pa);
            }            
        }
        
        if(!paList.isEmpty()){
            try {
                update paList;                
            } 
            catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }
        }
    }
    
    /*
    * @author        Karen Hung
    * @date          Nov 23, 2020
    * @description   DOO-5035/DOO-4629 TS_Service Request Notification for Engineer                     
    * @revision(s)   
    */
    public void serviceNotification(List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMap){
        CustomLogging.push('serviceNotification', 'WorkOrderLineItemTriggerHandler');
                
        //CHECK IF THERE'S A CHANGE IN EXECUTING ENGINEER
        Map<Id, WorkOrderLineItem> oldWOLI = (Map<Id, WorkOrderLineItem>) oldMap;
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>) newList){
			if(newWoli.ExecutingEngineer__c != null && 
               newWoli.ExecutingEngineer__c != oldWOLI.get(newWOLI.Id).ExecutingEngineer__c && 
               newWoli.Case__c != null){
                   
               	woliList.add(newWoli); 
            }
        }

        if(!woliList.isEmpty()){
            
            Map<Id, WorkOrderLineItem> extWoliNewMap2 = new Map<Id,WorkOrderLineItem>();        
            if (extWoliNewMap2.isEmpty() || !extWoliNewMap2.keySet().containsAll(newMapItems.keySet())) {
                extWoliNewMap2 = getExtWoliMap(newMapItems.keySet());
            }
            
            List<TS_WorkOrderNotificationEmail.TS_EmailAttributes> attList = new List<TS_WorkOrderNotificationEmail.TS_EmailAttributes>();
            
            for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>)newList){
                
                WorkOrderLineItem extWoli = extWoliNewMap2.get(newWoli.Id);
                               
                if(contactRec != null &&
                   extWoli.ExecutingEngineer__r.EmailAddress__c != null &&
                   extWoli.Case__r.Type == TS_Constants.TS_Case_Type_FieldService &&
                   (extWoli.ExecutingEngineer__r.UserProfile__c == TS_Constants.RESOURCE_USERPROFILE_THIRDPARTY || extWoli.ExecutingEngineer__r.UserProfile__c == TS_Constants.RESOURCE_USERPROFILE_TSRESOURCE) &&
                   extWoli.ExecutingEngineer__r.RelatedUser__c != null &&
                   extWoli.ExecutingEngineer__r.ActiveUser__c == true
                  ){

                      TS_WorkOrderNotificationEmail.TS_EmailAttributes emailAtt = new TS_WorkOrderNotificationEmail.TS_EmailAttributes();
                      emailAtt.emailTemplateName = 'TS_Work_Order_Notification';
                      emailAtt.emailAddress = extWoli.ExecutingEngineer__r.EmailAddress__c;
                      emailAtt.emailfromAddress = extWoli.Case__r.Default_From_Address__c;
                      emailAtt.hasEmailMessage = true;
                      emailAtt.targetRecipientId = contactRec.Id;
                      emailAtt.isTargetNotRecepient = true;
                      emailAtt.recordId = newWoli.Id;
                      
                      attList.add(emailAtt);
                  }          
            }
            
            if(!attList.isEmpty()){
                system.debug('Sending Email');
                TS_WorkOrderNotificationEmail.sendWorkOderEmail(attList);
                serviceNotifProcessed = true;
            }
        }
        
        CustomLogging.pop();
    }    
    
    /*
    * @author        Francis Allen Alindogan
    * @date          January 04, 2021
    * @description   Method to perform actions for third party operator
    * @revision(s)   
    */    
    public void checkIfThirdPartyResource(List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems){
        CustomLogging.push('checkIfThirdPartyResource', 'WorkOrderLineItemTriggerHandler');    
		Map<Id, WorkOrderLineItem> oldWoliMap = (Map<Id, WorkOrderLineItem>) oldMapItems;
        Map<Id, WorkOrderLineItem> newWoliMap = (Map<Id, WorkOrderLineItem>) newMapItems;
		
        for(WorkOrderLineItem newWoli : (List<WorkOrderLineItem>)newList){ 
               
            //CHECK IF THIRD PARTY OPERATOR
            if(((enabledFeatureMap.containsKey('DOO_5150_TS_EnableThirdPartyOperator') && enabledFeatureMap.get('DOO_5150_TS_EnableThirdPartyOperator')) &&
               (extWoliNewMap.get(newWoli.Id) != null && extWoliNewMap.get(newWoli.Id).AccountLocation__c != null && extWoliNewMap.get(newWoli.Id).AccountLocation__r.Third_Party_Resource__c != null))
               || Test.isRunningTest()){                           
                   
                   // DOO-5150 IF S15, AUTOMATICALY ASSIGN TO 3RD PARTY AND SEND SERVICE NOTIFICATION       
                   // DOO-5298 IF SEND TO THIRD PARTY IS TRUE
                   if(newWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && !serviceNotifProcessed && extWoliNewMap.get(newWoli.Id).Case__r.SendTo3rdParty__c == true){                       
				   //if(newWoli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && !serviceNotifProcessed){                                              
                       if(Trigger.IsUpdate && oldWoliMap.get(newWoli.Id).ExecutingEngineer__c != newWoli.ExecutingEngineer__c){                           
                        	newWoli.ExecutingEngineer__c = extWoliNewMap.get(newWoli.Id).AccountLocation__r.Third_Party_Resource__c;
							newWoli.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                       }
                       else if(Trigger.IsInsert){                           
                           THIRDPARTY_RESOURCE_MAP.put(newWoli.Id, extWoliNewMap.get(newWoli.Id).AccountLocation__r.Third_Party_Resource__c);
                       }                     
                   } 					                                     
               }
        }    
        CustomLogging.pop();
    }
}