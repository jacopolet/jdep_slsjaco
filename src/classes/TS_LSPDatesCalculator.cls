/**
* @author        Adrian Reyes
* @date          02.07.2018
* @description   Class used to calculate LSP dates on case when all related work order line items are scheduled
* @revision(s)
*/

global with sharing class TS_LSPDatesCalculator {
    /**
    * @author        Adrian Reyes
    * @date          02.07.2018           
    * @description   Method used to calculate LSP dates on case when all related work order line items are scheduled
    * @revision(s)
    */
    @InvocableMethod
    global static void calculateLSPDates(List<Id> workOrderIDs) {
        CustomLogging.push('calculateLSPDates', 'TS_LSPDatesCalculator');

        try {
            //Retrieve country scheduling rules and default business hours
            Map<String,CountrySetting__c> countrySchedulingRuleMap = new Map<String,CountrySetting__c>();
            for(CountrySetting__c countrySetting: [SELECT Country__c, RoundTrip__c, DeliveryOffset__c, PickupOffset__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'Country_Scheduling_Rules' AND Active__c = true])
                countrySchedulingRuleMap.put(countrySetting.Country__c + '-' + countrySetting.RoundTrip__c, countrySetting);
            
            Map<String,CountrySetting__c> countryDefaultBusinessHoursMap = new Map<String,CountrySetting__c>();
            for(CountrySetting__c countrySetting: [SELECT Country__c, Business_Hours__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'CountryDefaultBusinessHours' AND Active__c = true])
                countryDefaultBusinessHoursMap.put(countrySetting.Country__c, countrySetting);
            
            List<WorkOrder> workOrders = [SELECT CaseId, S40_Scheduled_Date__c, S41ScheduledDate__c, S43ScheduledDate__c, Includes_Round_Trip__c FROM WorkOrder WHERE Id IN: workOrderIDs];
            Set<Id> caseIDs = new Set<Id>();
            for(WorkOrder workOrder: workOrders)
                caseIDs.add(workOrder.CaseId);
            
            Map<Id,Case> caseMap = new Map<Id,Case>([SELECT SalesOrganization__c, SubType__c FROM Case WHERE Id IN: caseIDs]);
            for(WorkOrder workOrder: workOrders){
                Case c = caseMap.get(workOrder.CaseId);
                CountrySetting__c countrySchedulingRule = countrySchedulingRuleMap.get(c.SalesOrganization__c + '-' + workOrder.Includes_Round_Trip__c);
                CountrySetting__c countryDefaultBusinessHours = countryDefaultBusinessHoursMap.get(c.SalesOrganization__c);
                
                //Calculate LSP dates
                c.PlannedDeliveryDate__c = getDeliveryDate(workOrder, c, countrySchedulingRule, countryDefaultBusinessHours);
                c.PlannedPickUpDate__c = getPickUpDate(workOrder, c, countrySchedulingRule, countryDefaultBusinessHours);
                c.PlannedMovementDate__c = getMovementDate(workOrder, c, countrySchedulingRule, countryDefaultBusinessHours);
            }

            //Update cases
            if(Schema.sObjectType.Case.isUpdateable())
                update caseMap.values();
                
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.07.2018           
    * @description   Method used to calculate Delivery Date
    * @revision(s)
    */
    static Date getDeliveryDate(WorkOrder workOrder, Case c, CountrySetting__c countrySchedulingRule, CountrySetting__c countryDefaultBusinessHours) {
        CustomLogging.push('getDeliveryDate', 'TS_LSPDatesCalculator');
        DateTime deliveryDate;
        //Integer deliveryOffset = Integer.valueOf(countrySchedulingRule.DeliveryOffset__c * -1);
        Integer deliveryOffset = Integer.valueOf(countrySchedulingRule.DeliveryOffset__c);
        if (c.SubType__c == Label.TS_Order_S40 || c.SubType__c == Label.TS_Case_SubType_Swap) {
            //deliveryDate = workOrder.S40_Scheduled_Date__c.addDays(deliveryOffset);
            deliveryDate = workOrder.S40_Scheduled_Date__c;
        } else if (c.SubType__c == Label.TS_WOTOrderType_Conversion) {
            //deliveryDate = workOrder.S43ScheduledDate__c.addDays(deliveryOffset);
            deliveryDate = workOrder.S43ScheduledDate__c;
        } else {
            return null;
        }
        
        DateTime nextStartDate = BusinessHours.nextStartDate(countryDefaultBusinessHours.Business_Hours__c, deliveryDate);
        deliveryDate = deliveryDate.date() != nextStartDate.date() ? BusinessHours.add(countryDefaultBusinessHours.Business_Hours__c, nextStartDate, -1000) : nextStartDate;
        deliveryDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, deliveryDate, deliveryOffset, false);
        //deliveryDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, deliveryDate, -1);
        CustomLogging.pop();
        return deliveryDate.date();
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.07.2018           
    * @description   Method used to calculate Pick-Up Date
    * @revision(s)
    */
    static Date getPickUpDate(WorkOrder workOrder, Case c, CountrySetting__c countrySchedulingRule, CountrySetting__c countryDefaultBusinessHours) {
        CustomLogging.push('getPickUpDate', 'TS_LSPDatesCalculator');
        DateTime pickUpDate;
        Integer pickUpOffset = Integer.valueOf(countrySchedulingRule.PickupOffset__c);
        if(c.SubType__c == Label.TS_Order_S41 || c.SubType__c == Label.TS_Case_SubType_Swap) {
            //pickUpDate = workOrder.S41ScheduledDate__c.addDays(pickUpOffset);
            pickUpDate = workOrder.S41ScheduledDate__c;
        } else {
            return null;
        }
        
        pickUpDate = BusinessHours.nextStartDate(countryDefaultBusinessHours.Business_Hours__c, pickUpDate);
        pickUpDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, pickUpDate, pickUpOffset, true);
        //pickUpDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, pickUpDate, 1);
        CustomLogging.pop();
        return pickUpDate.date();
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.07.2018           
    * @description   Method used to calculate Movement Date
    * @revision(s)
    */
    static Date getMovementDate(WorkOrder workOrder, Case c, CountrySetting__c countrySchedulingRule, CountrySetting__c countryDefaultBusinessHours) {
        CustomLogging.push('getMovementDate', 'TS_LSPDatesCalculator');
        DateTime movementDate;
        Integer pickUpOffset = Integer.valueOf(countrySchedulingRule.PickupOffset__c);
        if(c.SubType__c == Label.TS_Order_Instype_Movement) {
            //movementDate = workOrder.S41ScheduledDate__c.addDays(pickUpOffset);
            movementDate = workOrder.S41ScheduledDate__c;
        } else {
            return null;
        }
        
        movementDate = BusinessHours.nextStartDate(countryDefaultBusinessHours.Business_Hours__c, movementDate);
        movementDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, movementDate, pickUpOffset, true);
        //movementDate = getNextBusinessDay(countryDefaultBusinessHours.Business_Hours__c, movementDate, 1);
        CustomLogging.pop();
        return movementDate.date();
    }
    
    ///**
    //* @author        Adrian Reyes
    //* @date          02.07.2018           
    //* @description   Method used to get next business day
    //* @revision(s)
    //*/
    //static DateTime getNextBusinessDay(Id businessHoursId, DateTime targetDate, Integer numberOfDays) {
    //    CustomLogging.push('getNextBusinessDay', 'TS_LSPDatesCalculator');
    //    while(!BusinessHours.isWithin(businessHoursId, targetDate))
    //        targetDate = targetDate.addDays(numberOfDays);
        
    //    CustomLogging.pop();
    //    return targetDate;
    //}

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.27.2018           
    * @description   Method used to get business day
    * @revision(s)
    */
    public static DateTime getNextBusinessDay(Id businessHoursId, DateTime targetDate, Integer offSet, Boolean isNextDay) {
        CustomLogging.push('getNextBusinessDay', 'TS_LSPDatesCalculator');

        Integer num1 = isNextDay? 1 : -1; //Add additional day when isNextDay is true. Otherwise, subtract.
        Integer num2 = isNextDay? 2 : -2; //Add additional day when isNextDay is true. Otherwise, subtract.
        Integer newOffSet = offSet != null? offSet : 0;
        DateTime newTargetDate = targetDate;

        //Use offset param to indicate the loop count
        for (Integer i = 1; i <= newOffSet; i++) {
            newTargetDate = newTargetDate.addDays(num1); //Deduct or add 1 day before calculating business day

            //Check for days falling on weekends in 24/7 business hours 
            if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(num1);
            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(num2);
            } 

            //Check the working day after validating weekend dates
            while(!BusinessHours.isWithin(businessHoursId, newTargetDate)) {
                newTargetDate = newTargetDate.addDays(num1);
            }
        }

        CustomLogging.pop();
        return newTargetDate;
    }

}