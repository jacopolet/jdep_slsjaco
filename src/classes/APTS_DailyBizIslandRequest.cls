/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Handles the DailyBizIslandRecord Creation
 * @Created Date: Oct 9, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul              10.09.2018       Created
 **********************************************************************************/


public without sharing class APTS_DailyBizIslandRequest /*** PI fix # 190215 ****/
{
     public void insertRecord()
     {
         BizIsland_Request__c BizReq=new BizIsland_Request__c();
         Date d=system.today();
         BizReq.name='Bonsai Request'+' '+d;
         insert BizReq;
     }
}