/*************************************************************
@Name: APTS_RSOProductCatalogBatch
@Author: Raul Orozco
@CreateDate: 17-05-2018
@Description: RSO Product Catalog batch Scheduler. 
@UsedBy: 
******************************************************************/
global class APTS_RSOProductCatalogSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		APTS_RSOProductCatalogBatch obj = new APTS_RSOProductCatalogBatch();
		database.executebatch(obj);
	}
}