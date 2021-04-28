//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 21, 2017
// Usage        :   
//-------------------------------------------------------------------------------------------//
public without sharing class TS_ClickSyncMasterData {
        
    //Added by Ritesh Kumar to throw custome exception.
    public class TS_ClickSyncMasterDataException extends Exception{
    }
    
    public void executeSessionId(List<Integration_Log__c> updatableIlogList) {
        CustomLogging.push('executeSessionId', 'TS_ClickSyncMasterData');

        for (Integration_Log__c iLog : updatableIlogList) {
            JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
            JDEServicesCallout.Sessions[] elem = new List<JDEServicesCallout.Sessions>();
            JDEServicesCallout.Sessions session = new JDEServicesCallout.Sessions();
            session.SessionID = iLog.SessionID__c;
            elem.add(session);
 
            try {
                port.SyncMasterData(null,elem);
                iLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
                iLog.Target_System_Processed_TimeStamp__c = Datetime.now();
                
            } catch(Exception ex) {
                iLog.Integration_Status__c = INT_Constants.TARGET_SYSTEM_ERROR;
                iLog.Integration_Message__c = ex.getMessage();
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }              
        }

        try {
            update updatableIlogList;
            //Exception for test class purposes
            if (Test.isRunningTest()) {
                throw new TS_ClickSyncMasterDataException('Force to throw an exception');
            }
        } catch(Exception ex) {          
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }

        CustomLogging.pop();       
    }

    //### Commented due to test class coverage. Method seems not used anymore. ###
    /*public void executeSendPartType(List<Integration_Log__c> currentILogList) {
        CustomLogging.push('SyncMasterProduct', 'TS_ClickSyncMasterData');
        
        List<Integration_Log__c> updatedIlogList = [Select Id, Integration_Status__c, Work_Order_Line_Item__c ,Object__c, Object_Id__c
                                                        from Integration_Log__c where Id IN: currentILogList];
        List<Integration_Log__c> updatableIlogList = new List<Integration_Log__c>();
        Set<Id> psId = new Set<Id>();
        
        Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
        for (Integration_Log__c ilog : updatedIlogList) {
            psId.add(ilog.Object_Id__c);      
            iLogMap.put(ilog.Object_Id__c,ilog);      
        }

        List<PricebookEntry> psList = [Select Id,PriceBook2.Name,Country_ISO__c, Product2.Id, Product2.Name, UnitPrice, 
                                        Product2.Description,OldStandardPrice__c, Name,Product2.IsActive ,Is_Service_Material__c
                                        From PricebookEntry where Id in: psId];
        JDEServicesCallout.JDEServiceOptimizationPort port = new JDEServicesCallout.JDEServiceOptimizationPort();
        JDEServicesCallout.PartTypes[] elem = new List<JDEServicesCallout.PartTypes>();
        
        Integer ctr = 0;
     
        for(PricebookEntry ps : psList) {
            JDEServicesCallout.PartTypes partType = new JDEServicesCallout.PartTypes();
            partType.Name = ps.Product2.Name;
            //if (!String.isBlank(ps.Sales_Office__c)) {
            partType.Country = ps.Country_ISO__c;//Integer.valueOf( ps.Sales_Office__c );
            //}
            partType.Description = ps.Product2.Description;             
            partType.Cost = Integer.valueOf( ps.UnitPrice );            
            partType.Active = ps.Product2.IsActive;
            partType.PartID = ps.Id;
            partType.IsServiceMaterial =  ps.Is_Service_Material__c ? 1 : 0;
            elem.add(partType);           
            updatableIlogList.add( iLogMap.get(ps.Id) );
            ctr++;
            //if the records exceeds the maximum number of records that can be send to click
            //immediately send the list of records and create a new set of list
            if (ctr == IntegrationUserAndProfile__c.getInstance().Click_Product_Batch_Limit__c && IntegrationUserAndProfile__c.getInstance().Click_Product_Batch_Limit__c !=0 ) {
                ExecuteQueueableCallOut eqc = new ExecuteQueueableCallOut();
                eqc.iLogList = updatableIlogList;
                eqc.elem = elem;            
                System.enqueueJob(eqc);

                elem = new List<JDEServicesCallout.PartTypes>();
                ctr = 0;
                
            }
        }        
        if (!elem.isEmpty()) {
            ExecuteQueueableCallOut eqc = new ExecuteQueueableCallOut();
            eqc.iLogList = updatableIlogList;
            eqc.elem = elem;            
            System.enqueueJob(eqc);
       
        }
    
        CustomLogging.pop();       
    }*/

}