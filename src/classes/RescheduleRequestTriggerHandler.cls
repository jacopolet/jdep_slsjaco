/**
* @author        Adrian Reyes
* @date          02.26.2018           
* @description   Class responsible for the trigger business logic of Reschedule Request
* @revision(s)   7.13.2018 Paul Aguiling: KTS-1935 Updated updateCase()
*/
public without sharing class RescheduleRequestTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newItems) {
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems) {
        updateCase(newList);
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems) {
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems) {
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().RescheduleRequest__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.26.2018          
    * @description   Method to update case's early start and SLA dates and reschedule related work order line items
    * @revision(s)
    */
    void updateCase(List<SObject> newList) {
        CustomLogging.push('updateCase', 'RescheduleRequestTriggerHandler');
        Set<Id> caseIDs = new Set<Id>();
        List<RescheduleRequest__c> rescheduleRequests = new List<RescheduleRequest__c>();
        for(RescheduleRequest__c rescheduleRequest: (List<RescheduleRequest__c>) newList){
            if(rescheduleRequest.RescheduleSource__c == Label.TS_RescheduleSourceOrder && rescheduleRequest.Case__c != null && rescheduleRequest.PickingDate__c != null){
                caseIDs.add(rescheduleRequest.Case__c);
                rescheduleRequests.add(rescheduleRequest);
            }
        }
        
        if(!rescheduleRequests.isEmpty()){
            Map<Id,Case> caseMap = new Map<Id,Case>([SELECT SalesOrganization__c, SubType__c, EarlyStartDate__c, SLADate__c, ActualDeliveryDate__c, ActualPickUpDate__c, (SELECT Id FROM WorkOrderLineItems__r WHERE Status !=: Label.TS_WOLI_Status_Completed) FROM Case WHERE Id IN: caseIDs]);
            Map<String,CountrySetting__c> countryScheduleDateTimeSettingsMap = TS_SalesTriggerController.getCountryScheduleDateTimeSettingsMap();
            Map<String,CountrySetting__c> countryDefaultBusinessHoursMap = TS_SalesTriggerController.getCountryDefaultBusinessHoursMap();
            Map<String,String> orderTypeMap = new Map<String,String>{Label.TS_Order_S40 => Label.TS_Order_Instype_Installation, Label.TS_Order_S41 => Label.TS_Order_Instype_DeInstallation, Label.TS_Case_SubType_Swap => Label.TS_Case_SubType_Swap, Label.TS_Order_Instype_Movement => Label.TS_Order_Instype_Movement, Label.TS_WOTOrderType_Conversion => Label.TS_WOTOrderType_Conversion};
            List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
            for(RescheduleRequest__c rescheduleRequest: rescheduleRequests){
                Case c = caseMap.get(rescheduleRequest.Case__c);
                CountrySetting__c countryScheduleDateTimeSettings = countryScheduleDateTimeSettingsMap.get(c.SalesOrganization__c + '-' + orderTypeMap.get(c.SubType__c));
                CountrySetting__c countryDefaultBusinessHours = countryDefaultBusinessHoursMap.get(c.SalesOrganization__c);
                
                //Update case dates
                //JAN 24, 2019 XEN REYES
                if(c.ActualDeliveryDate__c == null){
                    c.PlannedDeliveryDate__c = null;    
                }

                if(c.ActualPickUpDate__c == null){
                    c.PlannedPickUpDate__c = null;    
                }
                
                c.PickingDate__c = rescheduleRequest.PickingDate__c;
                c.EarlyStartDate__c = rescheduleRequest.RequestedActivityDate__c != null ? DateTime.newInstance(rescheduleRequest.RequestedActivityDate__c.year(), rescheduleRequest.RequestedActivityDate__c.month(), rescheduleRequest.RequestedActivityDate__c.day(), 8, 0, 0) : c.EarlyStartDate__c;
                c.SLADate__c = rescheduleRequest.RequestedActivityDate__c != null ? DateTime.newInstance(rescheduleRequest.RequestedActivityDate__c.addDays(4), Time.newInstance(17, 0, 0, 0)) : c.SLADate__c;
                c.LSPScheduleDate__c = TS_SalesTriggerController.getLSPScheduleDate(c, countryScheduleDateTimeSettings, countryDefaultBusinessHours);
				
                if(rescheduleRequest.RequestedActivityDate__c != null){ //XEN REYES Nov 1 2018
                    c.CustomerScheduleDate__c = TS_SalesTriggerController.getCustomerScheduleDate(c, countryScheduleDateTimeSettings, countryDefaultBusinessHours);

                    //KTS-1935: Change the customer schedule and lsp date to today if calculated date is in the past - START
                    //KTS-2257: Include equal to today in the criteria, not just greater than. XEN REYES Feb 11, 2019
                    if (Date.today() >= c.CustomerScheduleDate__c) {
                        c.ScheduleManually__c = true;
                        c.CustomerScheduleDate__c = TS_UtilityClass.getWorkingDate(countryDefaultBusinessHours.Business_Hours__c, Date.today());
                    }
                }

                c.ActualDeliveryDate__c = rescheduleRequest.ExpectedDeliveryDate__c != null ? rescheduleRequest.ExpectedDeliveryDate__c : c.ActualDeliveryDate__c;

                //KTS-2257: Include equal to today in the criteria, not just greater than. XEN REYES Feb 11, 2019
                if (Date.today() >= c.LSPScheduleDate__c) {
                    Time lspScheduleTime = Time.newInstance(Integer.valueOf(countryScheduleDateTimeSettings.LSPScheduleTimeOffset__c), 0, 0, 0);
                    Date lspSched = TS_UtilityClass.getWorkingDate(countryDefaultBusinessHours.Business_Hours__c, Date.today());
                    c.LSPScheduleDate__c = DateTime.newInstance(lspSched, lspScheduleTime);
                }
                //KTS-1935: Change the customer schedule and lsp date to today if calculated date is in the past - END

                //Update work order line items
                if(rescheduleRequest.RequestedActivityDate__c != null){
                    for(WorkOrderLineItem workOrderLineItem: c.WorkOrderLineItems__r){
                        workOrderLineItem.EarlyStart__c = c.EarlyStartDate__c;
                        workOrderLineItem.SLADate__c = c.SLADate__c;
                        workOrderLineItem.EarliestAppointmentTime__c = null;
                        workOrderLineItem.LatestAppointmentTime__c = null;
                        workOrderLineItem.Reschedule__c = true;
                        workOrderLineItems.add(workOrderLineItem);
                    }
                }
            }
            
            if(Schema.sObjectType.Case.isUpdateable())
            	update caseMap.values();
            
            if(Schema.sObjectType.WorkOrderLineItem.isUpdateable())
            	update workOrderLineItems;
        }
        
        CustomLogging.pop();
    }
}