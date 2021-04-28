/**
* Class Name : APTS_DeleteFireAndForget_Scheduler
* Description : Apex Class to schedule APTS_DeleteFireAndForgetIntLogsBatch Class
* Author : V. Shankaranarayanan (v.shankaranarayanan@accenture.com)
* Date Created : 09-05-2018
**/
global without sharing class APTS_DeleteFireAndForget_Scheduler implements Schedulable{

    /** Method Name : execute
    * Description : execute method of the scheduler class
    **/
    global void execute(SchedulableContext context){
        APTS_DeleteFireAndForgetIntLogsBatch batch = new APTS_DeleteFireAndForgetIntLogsBatch();
        Database.executeBatch(batch, 200);
    }
}