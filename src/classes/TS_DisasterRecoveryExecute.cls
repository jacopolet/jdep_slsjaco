/**
* @author        Marvin Gatchalian
* @date          12.April.2018
* @description   Apex class used to generates List of Case, Wo and Woli to be inserted.
* @revision(s)
*/

public without sharing class TS_DisasterRecoveryExecute {
    
    Map <String, Pricebook2> orgPriceBookMap = new Map <String, Pricebook2>(); 
    Map <Id, List<Pricebookentry>> productIdPbeMap = new Map <Id, List<Pricebookentry>>(); 
    Map <Id, Case> localDrIdCaseMap = new  Map <Id, Case>(); 
    Map <Id, WorkOrder> localDrIdWoMap = new  Map <Id, WorkOrder>(); 
    Map <Id, Disaster_Recovery__c> drIdMap = new Map <Id, Disaster_Recovery__c>();
                     
           
    
    public Map <Id, Case> generateCaseList (List<Disaster_Recovery__c> drRecords) {
        Map <Id, Case> drCaseToBeInsertedMap = new Map <Id, Case> ();
        Set <String> salesOrg = new Set <String>();
        Set <Id> productId = new Set <Id>();
        
        if (!drRecords.isEmpty()) {
            for (Disaster_Recovery__c eachDR : drRecords) {
            	drIdMap.put(eachDR.id, eachDR);
            	
                if (eachDR.TS_Case_Reference__c == null)
                    drCaseToBeInsertedMap.put(eachDR.id, createCaseFromDrRecord(eachDR));
                    
                salesOrg.add(eachDR.SalesOrganization__c);
                productId.add(eachDR.ProductID__c);
            }
        }
        
        for (Pricebook2 eachPB :[Select Sales_Organization__c, Id from Pricebook2 
                                 Where IsActive = true And Sales_Organization__c in :salesOrg ]) {
            orgPriceBookMap.put(eachPB.Sales_Organization__c, eachPB);
        }
        
        for (Pricebookentry eachPBE :[Select Id, Product2Id, Sales_Organization__c from Pricebookentry 
                                      Where IsActive = true And Product2Id in :productId
                                      AND  pricebook2.IsStandard = false]) {
            if (productIdPbeMap.containsKey(eachPBE.Product2Id))                            
            	productIdPbeMap.get(eachPBE.Product2Id).add(eachPBE);
            else
            	productIdPbeMap.put(eachPBE.Product2Id, new List<Pricebookentry> {eachPBE});
        }
        
        return drCaseToBeInsertedMap;
    }
    
    public Map <Id, WorkOrder> generateWorkOrderList ( Map <Id, Case> drIdCaseMap){
        Map <Id, WorkOrder> drIdWorkOrderToBeInsertedMap = new Map <Id, WorkOrder> ();
        List <Disaster_Recovery__c> drToBeUpdated = new List <Disaster_Recovery__c>();
        localDrIdCaseMap = drIdCaseMap;
        
        if (!localDrIdCaseMap.keySet().isEmpty()) {
            for (Id drId : localDrIdCaseMap.keySet()) {
            	if (drIdMap.containsKey(drId)) {
            		Disaster_Recovery__c drRecord = drIdMap.get(drId);

	                drRecord.TS_Case_Reference__c = localDrIdCaseMap.get(drId).Id;
	                drToBeUpdated.add(drRecord);
	                if (drRecord.WorkOrderRequired__c && drRecord.TS_Work_Order_Reference__c == null)
	                    drIdWorkOrderToBeInsertedMap.put (drRecord.Id, createWorkOrderFromDrRecord(drRecord));  
            	}
            }
        }
        
        try {
            if (!drToBeUpdated.isEmpty() && Schema.sObjectType.Disaster_Recovery__c.isUpdateable())
                update drToBeUpdated;
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        return drIdWorkOrderToBeInsertedMap;
    }
    
    public Map <Id, WorkOrderLineItem> generateWorkOrderLineItemList ( Map <Id, WorkOrder> drIdWoMap){
        Map <Id, WorkOrderLineItem> drIdWoliToBeInsertedMap = new Map <Id, WorkOrderLineItem> ();
        List <Disaster_Recovery__c> drToBeUpdated = new List <Disaster_Recovery__c>();
        localDrIdWoMap = drIdWoMap;
        
        if (!drIdWoMap.keySet().isEmpty()) {

            for (Id drId : drIdWoMap.keySet()) {
            	if (drIdMap.containsKey(drId)) {
            		Disaster_Recovery__c drRecord = drIdMap.get(drId);
            		
	                drRecord.TS_Work_Order_Reference__c = drIdWoMap.get(drId).Id;
	                drToBeUpdated.add(drRecord);
	                if (drRecord.WorkOrderRequired__c && drRecord.TS_Work_Order_Line_Item_Reference__c == null)
	                    drIdWoliToBeInsertedMap.put (drRecord.Id, createWorkOrderLineItemFromDrRecord(drRecord)); 
            	}  
            }
        }

        try {
            if (!drToBeUpdated.isEmpty() && Schema.sObjectType.Disaster_Recovery__c.isUpdateable())
                update drToBeUpdated;
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        return drIdWoliToBeInsertedMap;
    }
    
    public void updateFinalDrRecords ( Map <Id, WorkOrderLineItem> drIdWoliMap){
        List <Disaster_Recovery__c> drToBeUpdated = new List <Disaster_Recovery__c>();
        if (!drIdWoliMap.keySet().isEmpty()) {
            
            for (id drId : drIdWoliMap.keySet()) {
            	if (drIdMap.containsKey(drId)) {
            		Disaster_Recovery__c drRecord = drIdMap.get(drId);
	                drRecord.TS_Work_Order_Line_Item_Reference__c = drIdWoliMap.get(drId).Id;
	                drToBeUpdated.add(drRecord);
            	}
            	if (drIdWoliMap.get(drId).status == TS_Constants.WOLI_STATUS_SCHEDULED &&
            		drIdWoliMap.get(drId).WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI &&
            		drIdWoliMap.get(drId).ServiceMaterialsLoaded__c == false){
            	}
            }
        }
        
        try {
            if (!drToBeUpdated.isEmpty() && Schema.sObjectType.Disaster_Recovery__c.isUpdateable())
                update drToBeUpdated;
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    private Case createCaseFromDrRecord (Disaster_Recovery__c drRecord){
        Id caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, 'Field Service Default');
        Case cse = new Case();
        cse.RecordTypeId = caseRecTypeId;
        cse.SalesOrganization__c = drRecord.SalesOrganization__c;
        //cse.Owner  = Use default case owner, but it must be stamped using an assignment rule.
        cse.Status = drRecord.CaseStatus__c;
        cse.Default_Owner_by_Country_Setting__c = 'Queue';      // Need to update documentation
        cse.Type = TS_Constants.CASE_TYPE_FIELDSERVICE;
        cse.SubType__c = drRecord.WorkOrderType__c;
        cse.ContactId = drRecord.Contact__c;
        cse.Customer_Case_ID__c = drRecord.Customer_Case_ID__c; //Karen Hung 16.10.2018 KTS-2266
        cse.Subject = drRecord.Subject__c;
        cse.Description = drRecord.Description__c;
        cse.PhysicalAsset__c = drRecord.Physical_Asset__c;
        cse.PO_Number__c = drRecord.Physical_Asset__r.PONumberMachines__c;
        cse.ProductId =  drRecord.ProductID__c;
        cse.CoffeeIsRunning__c = drRecord.CoffeeIsRunning__c;
        cse.Fault_Configuration__c = drRecord.FaultConfiguration__c;
        cse.AccountLocation__c = drRecord.AccountLocationID__c;
        cse.RequiresCostEstimate__c = drRecord.RequiresCostEstimate__c;
        cse.CostIndicationAsDiscussed__c = drRecord.CostIndicationAsDiscussed__c;
        cse.Origin = TS_Constants.CASE_ORIGIN_DR;
        cse.CreatedOrderedManually__c = drRecord.WorkOrderRequired__c;  // Do not Forget to include CasetriggerHanlder changes 
        																// To exclude Disaster Recory Origin in case validation
        cse.CompletionCode__c = drRecord.CompletionCode__c;  // Need to Update document, 
        													 // changed picklist value from 0140 – Completed, Fixed By Phone
       														 // to 140 – Completed, Fixed By Phone and API name to 140		 

        cse.DefectCodes__c = drRecord.DefectCode__c;    // Pickist need to be aligned witn Case object. 
        cse.Fault_Code__c = drRecord.FaultCode__c; 		// Pickist need to be aligned witn Case object. 
        cse.FaultLocationCategory__c = drRecord.FaultLocationCategory__c; // Pickist need to be aligned witn Case object. 
        
        cse.InternalSolution__c = drRecord.InternalSolution__c;
        cse.External_Solution__c = drRecord.ExternalSolution__c;
        
        cse.RequestorName__c = drRecord.RequestorName__c;
        cse.RequestorEmail__c = drRecord.RequestorEmail__c;
        cse.CreatedDate = drRecord.RegistrationDate__c;  // Need to update the document
        cse.TS_Disaster_Recovery_Id__c = drRecord.id;
        if (drRecord.CaseStatus__c == TS_Constants.STATUS_CLOSED)
        	cse.ClosedDate = drRecord.RegistrationDate__c.addMinutes(10);   //Need to update documentation

        //XEN REYES Jan. 23, 2019 KTS-2196: This is to ensure that even if the default owner is Individual, the case will be routed to the correct queue.
        cse.AssignToQueue__c = true;
        cse.TS_IsGeneratedFromBatch__c = true;

        system.debug ('Marvin +++ cse:' + cse);
        return cse;
    }
    
    private WorkOrder createWorkOrderFromDrRecord (Disaster_Recovery__c drRecord){
        WorkOrder wo = new WorkOrder();
        wo.CaseId = drRecord.TS_Case_Reference__c;
        wo.SalesOrganization__c = drRecord.SalesOrganization__c;   // Need to update documentation
        system.debug ('Marvin +++  drRecord.TS_Case_Reference__c:' +  drRecord.TS_Case_Reference__c);
        
        wo.Status = TS_Constants.STATUS_OPEN;
        
        if (drRecord.SalesOrganization__c != null) 
            if (orgPriceBookMap.containsKey(drRecord.SalesOrganization__c))
                wo.Pricebook2Id = orgPriceBookMap.get(drRecord.SalesOrganization__c).Id;
        
        wo.OwnerId = localDrIdCaseMap.get(drRecord.id).OwnerId;
        
        system.debug ('Marvin +++ wo.Pricebook2Id:' + wo.Pricebook2Id);
        system.debug ('Marvin +++ wo:' + wo);
                
        return wo;
    }
    
    private WorkOrderLineItem createWorkOrderLineItemFromDrRecord (Disaster_Recovery__c drRecord){
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Case__c = drRecord.TS_Case_Reference__c;
        woli.WorkOrderId = localDrIdWoMap.get(drRecord.id).id;
        
        system.debug ('Marvin +++ localDrIdWoMap: ' + localDrIdWoMap);
        system.debug ('Marvin +++ localDrIdWoMap.get(drRecord.id).Status: ' + localDrIdWoMap.get(drRecord.id).Status);
        
        //woli.Status = localDrIdWoMap.get(drRecord.id).Status;
        woli.Status = drRecord.WorkOrderStatus__c; // Need to update the docu
        //woli.StartDate__c = drRecord.ActualStartDate__c;   //Need to Update Documentation
        woli.WorkOrderType__c = drRecord.WorkOrderType__c;
        woli.WorkOrderLineItemType__c = TS_Constants.TYPE_TASK;
        woli.AccountLocation__c = drRecord.AccountLocationID__c;
        woli.Subject = drRecord.Subject__c;
        woli.PhysicalAsset__c = drRecord.Physical_Asset__c;    // Need to Update the document
        woli.Description = drRecord.Description__c;
        woli.SLADate__c = localDrIdWoMap.get(drRecord.id).Case.SLADate__c;
        system.debug ('Marvin +++ drRecord.TS_Case_Reference__r.SLADate__c: ' + drRecord.TS_Case_Reference__r.SLADate__c);
        system.debug ('Marvin +++ localDrIdWoMap.get(drRecord.id).Case.SLADate__c: ' + localDrIdWoMap.get(drRecord.id).Case.SLADate__c);
        
        //XEN REYES 9.20.2018 KTS-2179
        woli.DisasterRecovery__c = true;
        
        if(drRecord.Click__c){
            woli.RequiredEngineer__c = drRecord.ExecutingEngineer__c;
            woli.BookAppointmentStart__c = drRecord.ActualStartDate__c;
            woli.BookAppointmentFinish__c = drRecord.ActualEndDate__c;
        } else {
            woli.ExecutingEngineer__c = drRecord.ExecutingEngineer__c;
            woli.StartDate__c = drRecord.ActualStartDate__c;
            woli.EndDate__c = drRecord.ActualEndDate__c;
        }

        woli.IsCoffeeRunning__c = drRecord.CoffeeIsRunning__c;   // Need to update the docs.
        woli.RepeatVisit__c = localDrIdWoMap.get(drRecord.id).Case.RepeatVisit__c;
        
        if (drRecord.Physical_Asset__c != null) { 
            woli.Building__c = drRecord.Physical_Asset__r.Building__c;
            woli.Floor__c = drRecord.Physical_Asset__r.Floor__c;
            woli.SmokingArea__c = drRecord.Physical_Asset__r.SmokingArea__c;
            woli.Area__c = drRecord.Physical_Asset__r.Area__c;
            woli.CustomerReference__c = drRecord.Physical_Asset__r.CustomerReferenceNumber__c;
        }
        
        If (drRecord.ProductID__c != null) {
            If (productIdPbeMap.containsKey(drRecord.ProductID__c)) {
            	for (Pricebookentry eachPbe :productIdPbeMap.get(drRecord.ProductID__c)) {
            		system.debug ('Marvin +++ drRecord.SalesOrganization__c:' + drRecord.SalesOrganization__c);
            		system.debug ('Marvin +++ eachPbe.Sales_Organization__c:' + eachPbe.Sales_Organization__c);
            		if (drRecord.SalesOrganization__c == eachPbe.Sales_Organization__c)
                		woli.PricebookEntryId = eachPbe.Id;
            	}
            }
    	}
        
        system.debug ('Marvin +++ productIdPbeMap.get(drRecord.ProductID__c).Id:' + productIdPbeMap.get(drRecord.ProductID__c));
        system.debug ('Marvin +++ productIdPbeMap:' + productIdPbeMap);
                
        return woli;
    }
    
}