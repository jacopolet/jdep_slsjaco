/*************************************************************
@Name: APTS_LineItemsPricingSch
@Author: Raul Orozco
@CreateDate: 13-06-2018
@Description: Scheduler class for Line items pricing batch. 
@UsedBy: N/A
******************************************************************/
global without sharing class APTS_LineItemsPricingSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		APTS_LineItemsPricingBatch obj = new APTS_LineItemsPricingBatch();      
		Database.executebatch(obj,8);
	}
}