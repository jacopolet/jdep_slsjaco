//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 21, 2017
// Usage        :   Apex Class to Queue all the callout to click software, instead of using @future
// Changes      :   2017-05-31 Rey AUstral - Comment out Get Available Function
// 					2018-01-31 Xen Reyes - recreate execute method in @future to avoid chaining of queueable jobs, to be used by Sales Triggered Cases.
//-------------------------------------------------------------------------------------------//
global with sharing class ClickSoapApiCallout implements Queueable, Database.AllowsCallouts {
    public List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
  
    
    global void execute(QueueableContext qc){
        CustomLogging.push('execute', 'ClickSoapApiCallout');
        String OPERATING_TASKTYPE = 'operatingtask';
        String COUNTER_TASKTYPE = 'counterreading';
        String ROUTESALES_TASKTYPE = 'routesales';

        List<Integration_Log__c> forTaskCreateOrUpdateList = new List<Integration_Log__c>();
        List<Integration_Log__c> forSyncMasterSessionIdList = new List<Integration_Log__c>();
        List<Integration_Log__c> forClickNotificationList = new List<Integration_Log__c>();
        List<Integration_Log__c> forClickAttachment = new List<Integration_Log__c>();
        List<Integration_Log__c> forRouteSalesTaskList = new List<Integration_Log__c>();
        List<Integration_Log__c> forOperatingTaskList = new List<Integration_Log__c>(); 
        List<Integration_Log__c> forCounterTaskList = new List<Integration_Log__c>();

        //XEN REYES Jan. 8, 2020
        List<Integration_Log__c> forRouteOperatingTaskList = new List<Integration_Log__c>();
        List<Integration_Log__c> forRouteOperatingTaskList_items = new List<Integration_Log__c>();
        
        try{
            List<Integration_Log__c> updatableIlogList = [SELECT Id, Integration_Status__c, Work_Order_Line_Item__c , Object__c, 
                                                          SessionID__c,CSoft_Start__c,CSoft_Finish__c, Useful_Container__c, Work_Order__c
                                                          FROM Integration_Log__c WHERE Id IN: iLogList];

            System.debug('updatableIlogList: ' + updatableIlogList);
    
            for(Integration_Log__c iLog : updatableIlogList) {
                if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATETASK){
                    forTaskCreateOrUpdateList.add(iLog);
                } else if(iLog.Object__c == INT_Constants.CLICK_SESSIONID){
                    forSyncMasterSessionIdList.add(iLog);
                } else if(iLog.Object__c == INT_Constants.CLICK_ATTACHMENT){
                    forClickAttachment.add(iLog);
                } else if(iLog.Object__c == INT_Constants.CLICK_NOTIFICATION){
                    forClickNotificationList.add(iLog);            
                } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK){
                    forOperatingTaskList.add(iLog);
                } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK){
                    forCounterTaskList.add(iLog);
                } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_ROUTESALES_TASK){
                    forRouteSalesTaskList.add(iLog);
                
                //XEN REYES Jan. 8, 2020
                } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK){
                    forRouteOperatingTaskList.add(iLog);
                } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM){
                    forRouteOperatingTaskList_items.add(iLog);
                }
            }

            TS_ClickTaskCreateOrUpdate taskController = new TS_ClickTaskCreateOrUpdate();
            if (!forTaskCreateOrUpdateList.isEmpty()) {           
                taskController.executeTaskCreateUpdate(forTaskCreateOrUpdateList);
            }
            
            if (!forOperatingTaskList.isEmpty()) {
                taskController.executeOperationalTask(forOperatingTaskList, OPERATING_TASKTYPE );
            }
            
            if (!forCounterTaskList.isEmpty()) {
                taskController.executeOperationalTask(forCounterTaskList, COUNTER_TASKTYPE);
            }
            
            if (!forRouteSalesTaskList.isEmpty()) {         
                taskController.executeOperationalTask(forRouteSalesTaskList, ROUTESALES_TASKTYPE);
            }
    
            if (!forClickNotificationList.isEmpty()) {           
                taskController.executeClickNotification(forClickNotificationList);
            }

            //XEN REYES Jan. 8, 2020
            if (!forRouteOperatingTaskList.isEmpty()) {         
                taskController.executeOperationalTask_Route(forRouteOperatingTaskList);
            }

            if (!forRouteOperatingTaskList_items.isEmpty()) {         
                taskController.executeOperationalTask_RouteItem(forRouteOperatingTaskList_items);
            }

            TS_ClickSyncMasterData syncController = new TS_ClickSyncMasterData();
            if (!forSyncMasterSessionIdList.isEmpty()) {            
                syncController.executeSessionId(forSyncMasterSessionIdList);
            }
            
            TS_ClickAttachment ca = new TS_ClickAttachment();
            if (!forClickAttachment.isEmpty()) { 
                ca.AttachFile(forClickAttachment);
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
    }
	
    //XEN REYES - For Sales Triggered Cases 1/31
    //Update this if there is a change in execute method
    @future(callout=true)
    public static void execute2(List<Id> iLogList){
        String OPERATING_TASKTYPE = 'operatingtask';
        String COUNTER_TASKTYPE = 'counterreading';
        String ROUTESALES_TASKTYPE = 'routesales';

        List<Integration_Log__c> forTaskCreateOrUpdateList = new List<Integration_Log__c>();
        List<Integration_Log__c> forSyncMasterSessionIdList = new List<Integration_Log__c>();
        List<Integration_Log__c> forClickNotificationList = new List<Integration_Log__c>();
        List<Integration_Log__c> forClickAttachment = new List<Integration_Log__c>();
        List<Integration_Log__c> forOperatingTaskList = new List<Integration_Log__c>();
        List<Integration_Log__c> forCounterTaskList = new List<Integration_Log__c>();
        List<Integration_Log__c> forRouteSalesTaskList = new List<Integration_Log__c>();

        //XEN REYES Jan. 8, 2020
        List<Integration_Log__c> forRouteOperatingTaskList = new List<Integration_Log__c>();
        List<Integration_Log__c> forRouteOperatingTaskList_items = new List<Integration_Log__c>();

        List<Integration_Log__c> updatableIlogList = [SELECT Id, Integration_Status__c, Work_Order_Line_Item__c ,Object__c, 
                                                      SessionID__c,CSoft_Start__c,CSoft_Finish__c, Useful_Container__c, Work_Order__c
                                                      FROM Integration_Log__c WHERE Id IN: iLogList];
        
        for(Integration_Log__c iLog : updatableIlogList) {
            if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATETASK){
                forTaskCreateOrUpdateList.add(iLog);
            } else if(iLog.Object__c == INT_Constants.CLICK_SESSIONID){
                forSyncMasterSessionIdList.add(iLog);
            } else if(iLog.Object__c == INT_Constants.CLICK_ATTACHMENT){
                forClickAttachment.add(iLog);
            } else if(iLog.Object__c == INT_Constants.CLICK_NOTIFICATION){
                forClickNotificationList.add(iLog);            
            } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK){
                forOperatingTaskList.add(iLog);
            } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK){
                forCounterTaskList.add(iLog);
            } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_ROUTESALES_TASK){
                forRouteSalesTaskList.add(iLog);
            
            //XEN REYES Jan. 8, 2020
            } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK){
                forRouteOperatingTaskList.add(iLog);
            } else if(iLog.Object__c == INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM){
                forRouteOperatingTaskList_items.add(iLog);
            }
        }

        TS_ClickTaskCreateOrUpdate taskController = new TS_ClickTaskCreateOrUpdate();
        if (!forTaskCreateOrUpdateList.isEmpty()) {           
            taskController.executeTaskCreateUpdate(forTaskCreateOrUpdateList);
        }

        if (!forOperatingTaskList.isEmpty()) {           
            taskController.executeOperationalTask(forTaskCreateOrUpdateList, OPERATING_TASKTYPE );
        }

        if (!forCounterTaskList.isEmpty()) {           
            taskController.executeOperationalTask(forTaskCreateOrUpdateList, COUNTER_TASKTYPE);
        }

        if (!forRouteSalesTaskList.isEmpty()) {         

            taskController.executeOperationalTask(forRouteSalesTaskList, ROUTESALES_TASKTYPE);
        }
        
        if (!forClickNotificationList.isEmpty()) {           
            taskController.executeClickNotification(forClickNotificationList);
        }

        //XEN REYES Jan. 8, 2020
        if (!forRouteOperatingTaskList.isEmpty()) {         
            taskController.executeOperationalTask_Route(forRouteOperatingTaskList);
        }

        if (!forRouteOperatingTaskList_items.isEmpty()) {         
            taskController.executeOperationalTask_RouteItem(forRouteOperatingTaskList);
        }
        
        TS_ClickSyncMasterData syncController = new TS_ClickSyncMasterData();
        if (!forSyncMasterSessionIdList.isEmpty()) {       
            syncController.executeSessionId(forSyncMasterSessionIdList);
        }
        
        TS_ClickAttachment ca = new TS_ClickAttachment();
        if (!forClickAttachment.isEmpty()) { 
            ca.AttachFile(forClickAttachment);
        }
    }    
}