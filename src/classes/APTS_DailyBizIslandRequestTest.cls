/**************************************************************
* @Author: Keerthana
* @Company: Accenture
* @Description: Test class for APTS_AccountBizland
* @Created Date: OCT 08, 2018
* @Revisions:
*      <Name>                  <Date>          <Description>
*      Keerthana      Oct 10, 2018    Initial Version
* 
*************************************************************/
@isTest
private class APTS_DailyBizIslandRequestTest {
    
    
    static testMethod void testData(){
            
     /*   BizIsland_Request__c bizland = new BizIsland_Request__c();
        bizland.name = 'Bonsai Request '+Date.Today();
        Database.insert(bizland);*/
        //Code change - Lavanya
        APTS_DailyBizIslandRequest  instBiz = new APTS_DailyBizIslandRequest();
        instBiz.insertRecord();
        
    }
    }