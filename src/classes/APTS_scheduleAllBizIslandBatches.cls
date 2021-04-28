/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Scheduler to run all the BizIsland batch jobs
 * @Created Date: Oct 9, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana          10.15.2018       Created
 **********************************************************************************/
global without sharing class APTS_scheduleAllBizIslandBatches implements Schedulable { /*** PI fix # 190230 ****/
    global void execute(SchedulableContext sc) {
        APTS_AccountBizIsland Acc = new APTS_AccountBizIsland();
        Database.executeBatch(Acc,200);
    }
}