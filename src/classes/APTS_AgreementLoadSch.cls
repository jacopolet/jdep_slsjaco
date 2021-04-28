/*************************************************************
@Name: APTS_AgreementLoadSch
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Scheduler class for Agreement load batch. 
@UsedBy: N/A
******************************************************************/
global class APTS_AgreementLoadSch implements Schedulable {
    global void execute(SchedulableContext sc) {
        APTS_LineItemsPricingBatch obj = new APTS_LineItemsPricingBatch();
        Database.executebatch(obj,8);
    }
}