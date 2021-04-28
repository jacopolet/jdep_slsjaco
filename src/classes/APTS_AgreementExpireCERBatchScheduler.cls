/*************************************************************
@Name: APTS_AgreementExpireCERBatchScheduler
@Author: Pranjal Mittal
@CreateDate: 08-03-2018
@Description: 
@UsedBy: 
******************************************************************/

global class APTS_AgreementExpireCERBatchScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		APTS_AgreementExpireCERBatch b = new APTS_AgreementExpireCERBatch();
		database.executebatch(b, 200);
	}
}