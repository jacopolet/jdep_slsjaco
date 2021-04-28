/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Scheduler to run the TGBtach jobs on weekly batches
 * @Created Date: Jan 24, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul          01.24.2019       Created
 **********************************************************************************/
global without sharing  class APTS_TGBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
   
      APTS_TGBatch TGB = new APTS_TGBatch();
      Database.executeBatch(TGB,200);
        }
}