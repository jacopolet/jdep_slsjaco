/**
* Class Name : APTS_ProdDistributionBatch_Scheduler 
* Description : Apex Class to schedule APTS_ProductRedistributionBatch Class
* Author : Nagavi Babu (nagavi.babu@accenture.com)
* Date Created : 04/02/2018
**/
global without sharing class APTS_ProdDistributionBatch_Scheduler implements Schedulable{

    /** Method Name : execute
    * Description : execute method of the scheduler class
    **/
    global void execute(SchedulableContext context){
        APTS_ProductRedistributionBatch batch = new APTS_ProductRedistributionBatch();
        Database.executeBatch(batch,Integer.valueOf(System.Label.APTS_Product_scheduler_batch_size));
    }
}