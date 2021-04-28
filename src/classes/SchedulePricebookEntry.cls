//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 21, 2017
// Usage        :   Apex Class to schedule sending of session id to click software
//-------------------------------------------------------------------------------------------//
global class SchedulePricebookEntry implements Schedulable {
    public static Boolean hasException = false;
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    *               4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
    ******************************************************************************/ 
    public class TS_SchedulerException extends Exception {

    }

    global void execute(SchedulableContext SC) {
        //Database.executeBatch(new BatchJob_PriceBookEntry());
        createIntegrationLog();
        Datetime currentDate = System.now();
        Datetime computedDate= currentDate.addMinutes(Integer.valueOf( IntegrationUserAndProfile__c.getInstance().ClickPriceBookEntryScheduleDuration__c) );
        
        String day = string.valueOf(computedDate.day());
        String month = string.valueOf(computedDate.month());
        String hour = string.valueOf(computedDate.hour());
        String minute = string.valueOf(computedDate.minute());
        String second = string.valueOf(computedDate.second());
        String year = string.valueOf(computedDate.year());
        
        String strJobName = 'SchedulePricebookEntry-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new SchedulePricebookEntry());
    }

    public void createIntegrationLog() {
        CustomLogging.push('createIntegrationLog', 'SchedulePricebookEntry');
        
        List<PricebookEntry> priceEntryList = [SELECT Id, Product2.Name, Sales_Organization__c, Country_ISO__c, Is_Country_Standard_Price__c, 
                                                Is_Service_Material__c, UnitPrice, OldStandardPrice__c,Is_price_changed__c 
                                                From Pricebookentry
                                                Where Is_Country_Standard_Price__c= true and Is_price_changed__c = true];

        List<PricebookEntry> toUpdatePriceEntryList  = new  List<PricebookEntry>();
        List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();
        for(PricebookEntry pe : priceEntryList) {
            if (pe.UnitPrice != pe.OldStandardPrice__c) {
               
                integLogsList.add(new Integration_Log__c(Object_Id__c = pe.Id,
                                                         Object__c = INT_Constants.CLICK_SYNCMASTERPRODUCT,
                                                         Integration_Status__c = INT_Constants.INITIAL,                                                           
                                                         Triggered_Timestamp__c = Datetime.now()));
                
                pe.OldStandardPrice__c = pe.UnitPrice;
                toUpdatePriceEntryList.add(pe);
            }
        }
        
        if(!toUpdatePriceEntryList.isEmpty() && Schema.sObjectType.PricebookEntry.isUpdateable()) {
            try {
                if (Test.isRunningTest() && hasException) {
                    throw new TS_SchedulerException('Force to throw an exception');
                }
                update toUpdatePriceEntryList;
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
            
        }
        
        if (!integLogsList.isEmpty() && IntegrationTriggerSettings__c.getInstance().IntegrationLogTrigger__c == true && Schema.sObjectType.Integration_Log__c.isCreateable()) {
            try {
                if (Test.isRunningTest() && hasException) {
                    throw new TS_SchedulerException('Force to throw an exception');
                }
                insert integLogsList; 
            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }
        }
        CustomLogging.pop();
    }
}