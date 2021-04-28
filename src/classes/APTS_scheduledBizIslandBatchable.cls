/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Scheduler to Create BizIsland Record
 * @Created Date: Oct 9, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul              10.09.2018       Created
 **********************************************************************************/
global class APTS_scheduledBizIslandBatchable implements Schedulable {
   global void execute(SchedulableContext sc) {
      APTS_DailyBizIslandRequest myCLass = new APTS_DailyBizIslandRequest();
      myClass.insertRecord();
   }
}