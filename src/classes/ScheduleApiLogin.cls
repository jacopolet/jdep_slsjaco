//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 21, 2017
// Usage        :   Apex Class to schedule sending of session id to click software
//-------------------------------------------------------------------------------------------//
global class ScheduleApiLogin implements Schedulable {
    public static Boolean hasException = false;
    public class ScheduleApiLoginException extends Exception {  }
    
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'ScheduleApiLogin');
        
        try{
            System.enqueueJob(new QueueableAPILogin());
            Datetime currentDate = System.now();
            Datetime computedDate= currentDate.addMinutes(Integer.valueOf( IntegrationUserAndProfile__c.getInstance().Click_Session_Id_Duration__c) );
            
            String day = string.valueOf(computedDate.day());
            String month = string.valueOf(computedDate.month());
            String hour = string.valueOf(computedDate.hour());
            String minute = string.valueOf(computedDate.minute());//IntegrationUserAndProfile__c.getInstance().Click_Session_Id_Duration__c);
            String second = string.valueOf(computedDate.second());
            String year = string.valueOf(computedDate.year());
            
            String strJobName = 'ScheduleApiLogin-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
            String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
            System.schedule(strJobName, strSchedule, new ScheduleApiLogin());
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new ScheduleApiLoginException('Force to throw an exception');
            }
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
    }
}