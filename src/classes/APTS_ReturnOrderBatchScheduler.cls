/**
* Class Name : APTS_ReturnOrderBatchScheduler
* Description : 
* Author : Sneha Jaiwant
* Date Created : 11/03/2020
**/
global without sharing class APTS_ReturnOrderBatchScheduler implements Schedulable{

    /** Method Name : execute
    * Description : execute method of the scheduler class
    **/
    global void execute(SchedulableContext context){
    
    APTS_ReturnOrderBatch b = new APTS_ReturnOrderBatch();
    database.executebatch(b, 1);   
     }
}