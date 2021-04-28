/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Schedules job for APTS_CancelAgreementBatch
 * @Created Date: June 25, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      06.25.2018      Created
 * 
 **********************************************************************************/

global class APTS_CancelAgreementScheduler implements Schedulable {
    
  global void execute(SchedulableContext sc) {
    APTS_CancelAgreementBatch b = new APTS_CancelAgreementBatch();
    database.executebatch(b, 200);
  }
}