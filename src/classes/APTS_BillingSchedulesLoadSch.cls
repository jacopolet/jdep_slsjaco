global class APTS_BillingSchedulesLoadSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		APTS_BillingSchedulesLoadBatch obj = new APTS_BillingSchedulesLoadBatch();
		Database.executeBatch(obj);
	}
}