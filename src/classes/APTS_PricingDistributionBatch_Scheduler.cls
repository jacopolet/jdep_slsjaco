/**
* Class Name : APTS_PricingDistributionBatch_Scheduler 
* Description : Apex Class to schedule APTS_PricingDistributionBatch Class
* Author : Nagavi Babu (nagavi.babu@accenture.com)
* Date Created : 04/02/2018
**/
global without sharing class APTS_PricingDistributionBatch_Scheduler implements Schedulable{
       
    /** Method Name : execute
    * Description : execute method of the scheduler class
    **/
    global void execute(SchedulableContext context){
        APTS_PricingDistributionBatch batch = new APTS_PricingDistributionBatch();
        Database.executeBatch(batch,Integer.valueOf(System.Label.APTS_Pricing_scheduler_batch_size));
    }
}