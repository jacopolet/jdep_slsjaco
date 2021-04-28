/*************************************************************
@Name: APTS_GenerateExtnlOrdBillingScheduler
@Author: Aswathy Sunil
@CreateDate: 23-11-2018
@Description: 
@UsedBy: 
******************************************************************/

global class APTS_GenerateExtnlOrdBillingScheduler  implements Schedulable {
  global void execute(SchedulableContext sc) {
    APTS_GenerateExtnlOrderBillingSchedule ba = new APTS_GenerateExtnlOrderBillingSchedule();
    database.executebatch(ba, 200);
  }
}