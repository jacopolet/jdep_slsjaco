/**
* Class Name   : APTS_DeleteOpenOrdersBatch_Scheduler
* Description  : Apex Class to schedule APTS_DeleteOpenOrdersBatch Class
* Author       : Hariharan
* Date Created : 04/04/2018
**/
global without sharing class APTS_DeleteOpenOrdersBatch_Scheduler implements Schedulable{
 /** Method Name : execute
 * Description   : execute method of the scheduler class
 **/ 
  global void execute(SchedulableContext context){     
   APTS_DeleteOpenOrdersBatch  batch = new APTS_DeleteOpenOrdersBatch();
        Database.executeBatch(batch, 200);
    }
}