//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral/Kimiko Roberto - Accenture
// Created Date :   March 17, 2017
// Usage        :   Handler of the Integration Log Trigger
// Revision:
//              :   4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
//              :   7.16.2018 Paul Aguiling KTS-1675: Updated executeCallouts()
//-------------------------------------------------------------------------------------------//
public without sharing class IntegrationLogTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = true;
    public static Boolean isAccountIlog = false;
    
    public void BeforeInsert(List<SObject> newIntegrationLogList){                
        // Added as part of security best practice, CRUD check on the object 
        Boolean hasCreateRightOnIntegrationLog  = TS_UtilityClass.isSObjectCreateable(new String[] {'Integration_Log__c'});      
        if(hasCreateRightOnIntegrationLog )      prepareSendingRecordToSAP(newIntegrationLogList);        
    }
    
    
    public void BeforeUpdate(List<SObject> newIntegrationLogList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldIntegrationLogMap){        
        //Commented out - VC1/2/2018 - Design to be reevaluated
        //prepareSendingChildRecordToSAP(newIntegrationLogList);
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    
    public void AfterInsert(List<SObject> newIntegrationLogList, Map<Id, SObject> newItems){
        // Added as part of security best practice, CRUD check on the object 
        //Boolean hasCreateRightOnIntegrationLog  = TS_UtilityClass.isSObjectCreateable(new String[] {'Integration_Log__c'});   
  
        //if(hasCreateRightOnIntegrationLog )  executeCallouts(newIntegrationLogList);
         executeCallouts(newIntegrationLogList);
    }
    
    public void AfterUpdate(List<SObject> newIntegrationLogList , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldIntegrationLogMap){
       
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
         
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           March 17, 2017
    * @description    Muting process, disable the function of the trigger if the user settings is false          
    ******************************************************************************/ 
    public Boolean IsDisabled() {
        System.debug('STATUS: ' + IntegrationTriggerSettings__c.getInstance().IntegrationLogTrigger__c);
        if (IntegrationTriggerSettings__c.getInstance().IntegrationLogTrigger__c == true && !isAccountIlog) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           March 17, 2017
    * @description    Update records to ready to be sent to SAP if it meets the criteria          
    ******************************************************************************/  
    private void prepareSendingRecordToSAP(List<SObject> newIntegrationLogList){
        Set<Id> hasParentToGetSet = new Set<Id>();
        Set<Id> recordIdSet = new Set<Id>();
        List<Integration_Log__c> hasParentRecordList = new List<Integration_Log__c>();
        List<Integration_Log__c> integLogList = new List<Integration_Log__c>();        
        
        for(SObject sObj : newIntegrationLogList) {
            //Cast sobj as Integration_Log__c type
            Integration_Log__c integ = (Integration_Log__c)sObj;
            
            if(integ.Integration_Status__c == INT_Constants.INITIAL) {
                //collect parent ids
                //Commented out - VC1/2/2018 - Design to be reevaluated
                // if(integ.Parent_Integration_Log__c != null) {
                //     hasParentToGetSet.add(integ.Parent_Integration_Log__c);
                //     hasParentRecordList.add(integ);
                // } else {
                    //set as true if parent is null and status is Initial
                    integ.Ready_To_Be_Sent__c = true;
                //}             
            }
        }
        
        //Commented out - VC1/2/2018 - Design to be reevaluated
        //check if there are records to be process
        // if (!hasParentToGetSet.isEmpty()) {
        //     //map parent ids
        //     Map<Id, Integration_Log__c>integLogMap = new Map<Id, Integration_Log__c>([SELECT Id, 
        //                                                                               Parent_Integration_Log__c, 
        //                                                                               Parent_Integration_Log__r.Integration_Status__c,
        //                                                                               Integration_Status__c,
        //                                                                               Ready_To_Be_Sent__c
        //                                                                               FROM Integration_Log__c
        //                                                                               WHERE Id IN: hasParentToGetSet
        //                                                                              ]);
            
        //     //iterate from list of records that has parent and has initial status
        //     //get map values to get parent properties             
        //     if(integLogMap != null && !integLogMap.isEmpty()) {
        //         for(SObject sObj : hasParentRecordList) {                    
        //             Integration_Log__c integ = (Integration_Log__c)sObj;
                    
        //             if(integLogMap.containsKey(integ.Parent_Integration_Log__c)) {
        //                 if (integLogMap.get(integ.Parent_Integration_Log__c).Integration_Status__c == INT_Constants.TARGET_SYSTEM_SUCCESS) {
        //                     integ.Ready_To_Be_Sent__c = true;    
        //                 } else {
        //                     integ.Integration_Status__c = INT_Constants.WAITING_ON_PARENT_INTEGRATION;
        //                 }
        //             }                
        //         } 
        //     }   
        // }        
    }
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           March 17, 2017
    * @description    Update child records to ready to be sent to SAP if it meets the criteria
    * Revision        : Marvin Gatchalian: 4-5-2018 - As per comment above from calling event before update 
    *                                                  this method is to be reevaluate thus commeting it out for the mean time        
    ******************************************************************************/
    /*  
    private void prepareSendingChildRecordToSAP(List<SObject> newIntegrationLogList){
        CustomLogging.push('prepareSendingChildRecordToSAP','IntegrationLogTriggerHandler');
        List<Integration_Log__c> integLogList = new List<Integration_Log__c>();
        Set<Id> integratedRecordSet = new Set<Id>();
        //collect all the records that has target system success and if the record has no parent then update the ready to be sent
        for(SObject sObj : newIntegrationLogList) {
            //Cast sobj as Integration_Log__c type
            Integration_Log__c integ = (Integration_Log__c)sObj;
            if (integ.Integration_Status__c == INT_Constants.TARGET_SYSTEM_SUCCESS) {
                integratedRecordSet.add(integ.Id);
            } else if (integ.Integration_Status__c == INT_Constants.INITIAL && integ.Parent_Integration_Log__c == null) {
                integ.Ready_To_Be_Sent__c = true;
            }
        }
        //collect child records with waiting of parent integration from list of records that has parent status of Target System Success
        if (!integratedRecordSet.isEmpty()) {
            integLogList = [SELECT Id,
                            Integration_Status__c
                            FROM Integration_Log__c 
                            WHERE Parent_Integration_Log__c IN: integratedRecordSet
                            AND Integration_Status__c =: INT_Constants.WAITING_ON_PARENT_INTEGRATION];
            
            //set Ready_To_Be_Sent__c to true
            if(!integLogList.isEmpty()) {
                for(Integration_Log__c integ : integLogList ) {                
                    integ.Ready_To_Be_Sent__c = true;
                }
                try {
                    update integLogList;
                } catch (Exception ex) {
                    CustomLogging.debugException(ex);
                    CustomLogging.pop();
                }
            }  
        } 
        CustomLogging.pop();
    } 
    */
    
    /******************************************************************************
    * @author         Rey Austral
    * @date           March 17, 2017
    * @description    Execute a SOAP Callout when certain criteria has been satisfied
    * @changes        2018-01-31 Xen Reyes - provide an alternative way of calling click call out  
                      March 2018 Archi - add integration for operating task and counter reading        
    ******************************************************************************/  

    private void executeCallouts(List<SObject> newIntegrationLogList){
        List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
        List<Integration_Log__c> forSyncMasterProductList = new List<Integration_Log__c>();
        List<Integration_Log__c> forClickAttachment = new List<Integration_Log__c>();
        List<Integration_Log__c> forUserCreateUpdate = new List<Integration_Log__c>();//KTS-1675: User Creation Mapping


        for(SObject sObj : newIntegrationLogList){
            Integration_Log__c intLog = (Integration_Log__c) sObj;
            if((intLog.Object__c == INT_Constants.WOLI_CREATEUPDATETASK || intLog.Object__c == INT_Constants.CLICK_SESSIONID 
                || intLog.Object__c == INT_Constants.CLICK_NOTIFICATION || intLog.Object__c == INT_Constants.CLICK_GETAVAILABLESLOTS
                || intLog.Object__c == INT_Constants.CLICK_ATTACHMENT || intLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK
                || intLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK ||  intLog.Object__c ==  INT_Constants.WOLI_CREATEUPDATE_ROUTESALES_TASK
                
                //XEN REYES Jan. 8, 2020
                || intLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK
                || intLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM

                ) 
                && intLog.Integration_Status__c == INT_Constants.INITIAL) {
                    iLogList.add(intLog);
                } 

            if (intLog.Object__c == INT_Constants.CLICK_SYNCMASTERPRODUCT) {
                forSyncMasterProductList.add(intLog);
            }
            
            if(intLog.Object__c == 'Work Order Line Item - Attachment'){
                forClickAttachment.add(intLog);
            }

            //KTS-1675: User Creation Mapping
            if (TS_Constants.CLICK_USERCREATE.equals(intLog.Object__c)
                || TS_Constants.CLICK_USERDELETE.equals(intLog.Object__c)) {
                forUserCreateUpdate.add(intLog);
            }
        }

        System.debug('Limits >>> ' + Limits.getQueueableJobs());
        
        if (!iLogList.isEmpty()) {
            System.debug('Limits >>> ' + Limits.getQueueableJobs());
            System.debug('iLogList >>> ' + iLogList);
            List<Id> integIdList = new List<Id>();
            
            if(WorkOrderTriggerObjectHandler.fromSalesTrigger){

                //Callout in @future if Sales Triggered Case - Xen Reyes 1.31.2018
                System.debug('entered from salestrigger ' );
                for(Integration_Log__c iLogId : iLogList){
                    integIdList.add(iLogId.Id);
                }
                ClickSoapApiCallout.execute2(integIdList);
                
            } else {
                
                System.debug('entered from non salestrigger ' );
                ClickSoapApiCallout csa = new ClickSoapApiCallout();
                csa.iLogList = iLogList; // this also process Click photo attachment
                System.enqueueJob(csa);
            }
            
        }

        if (!forSyncMasterProductList.isEmpty()) {  
            //TS_ClickSyncMasterData syncController = new TS_ClickSyncMasterData();          
            //syncController.executeSendPartType(forSyncMasterProductList);
            
            //Code below should be enabled upon deploying of KTS-1028 Story
            System.debug('KTS-1028 QueueableJobs Limits >>> ' + Limits.getQueueableJobs());
            TS_PriceBookEntrySyncToClick syncController = new TS_PriceBookEntrySyncToClick();
            syncController.executeSendPartType(forSyncMasterProductList);
        }

        //KTS-1675: User Creation Mapping -- START
        if (!forUserCreateUpdate.isEmpty()) {  
            System.debug('KTS-1028 QueueableJobs Limits ### ' + Limits.getQueueableJobs());
            TS_SendUserCreateorUpdateToClick sendUserClick = new TS_SendUserCreateorUpdateToClick();
            sendUserClick.executeUserCreateOrUpdate(forUserCreateUpdate);
        }
        //KTS-1675: User Creation Mapping -- END
        
        /* by Archi, it is included in ClickSoapApiCallout csa above
        if(!forClickAttachment.isEmpty()){
            
        }
        */
    }
   
}