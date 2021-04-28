/**
* Class Name : APTS_MeterRdngDtDeltSchedule
* Description : Schedulable Class which will run on every day and call the Batch class APTS_MeterReadingDataDelete                     
* Author : Kiruthika Pachaimaal
* Date Created : 12/05/2018
**/
global class APTS_MeterRdngDtDeltSchedule implements Schedulable{
    /**
    * Method Name : global void execute(SchedulableContext ctx)
    * Description : Execute Method which is scheduled to execute the batch daily to delete the 30 days old "Meter Reading Data" Records 
    * Author : Kiruthika Pachaimaal
    * Date Created : 12/05/2018
    **/
    global void execute(SchedulableContext ctx){
      String soql = 'Select Id, Name, APTS_Status__c from APTS_Meter_Reading_Data__c where APTS_Status__c = \'Completed\' and LastModifiedDate >= :dateValue limit 1';
      APTS_MeterReadingDataDelete batch = new APTS_MeterReadingDataDelete(soql);
      Database.executebatch(batch, 200);  
    }
}