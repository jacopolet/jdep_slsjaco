/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Test class for APTS_IndexContractTriggerHandler
 * @Created Date: May 7, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      June 8, 2018     Initial Version
 * 
 *************************************************************/
@isTest
private class APTS_IndexContractTriggerHandlerTest {
    
    
    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        
        system.runAs(testUser){
        insert new TriggerSettings__c(APTS_IndexContractTrigger__c = true);
            
            Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
            insert oAcc;
            
            Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
            oAgg.APTS_Language__c='English';
            insert oAgg;
        }
        
        
    }
	private static testMethod void rollUptoAggStandardIndexation() {
	    Apttus__APTS_Agreement__c oAgg = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
	    User testUser = [SELECT Id FROM User LIMIT 1];
	    APTS_Index_Contract__c oIndexCont = new APTS_Index_Contract__c();
	    oIndexCont.APTS_Contract__c = oAgg.id;
	    oIndexCont.APTS_Index_Type__c = 'Standard Indexation';
	    oIndexCont.APTS_Start_Date__c=System.today();
        oIndexCont.APTS_Indexation_Category__c= 'Technical Services';
	    test.startTest();
        system.runAs(testUser){
            insert oIndexCont;
            oIndexCont.APTS_Index_Type__c = 'Non-Standard Indexation';
            update oIndexCont;
            oIndexCont.APTS_Index_Type__c = 'Standard Indexation';
            update oIndexCont;
            delete oIndexCont;
            undelete oIndexCont;
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_Non_Standard_Deal_Indexation__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        system.assertEquals(FALSE, oAggCheck.APTS_Non_Standard_Deal_Indexation__c);
	}
        
    private static testMethod void rollUptoAggnonStandardIndexation() {
	    Apttus__APTS_Agreement__c oAgg = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
	    User testUser = [SELECT Id FROM User LIMIT 1];
        APTS_Index_Contract__c oIndexCont1 = new APTS_Index_Contract__c();
	    oIndexCont1.APTS_Contract__c = oAgg.id;
	    oIndexCont1.APTS_Index_Type__c = 'Non-Standard Indexation';
        oIndexCont1.APTS_Indexation_Category__c= 'Technical Services';
	     oIndexCont1.APTS_Start_Date__c=System.today();
         insert oIndexCont1;

         APTS_Index_Contract__c oIndexCont2 = new APTS_Index_Contract__c();
         oIndexCont2.APTS_Contract__c = oAgg.id;
         oIndexCont2.APTS_Index_Type__c = 'Non-Standard Indexation';
         oIndexCont2.APTS_Indexation_Category__c= 'Technical Services';
         oIndexCont2.APTS_Start_Date__c=System.today();
         insert oIndexCont2;

	    APTS_Index_Contract__c oIndexCont = new APTS_Index_Contract__c();
	    oIndexCont.APTS_Contract__c = oAgg.id;
	    oIndexCont.APTS_Index_Type__c = 'Non-Standard Indexation';
	    oIndexCont.APTS_Start_Date__c=System.today();
        oIndexCont.APTS_Indexation_Category__c= 'Technical Services';
	    test.startTest();
        system.runAs(testUser){
            insert oIndexCont;
            oIndexCont.APTS_Index_Type__c = 'No Indexation';
            oAgg.APTS_IndexationRelatedListDetails__c='abc|';
            update oAgg;
            update oIndexCont;
            delete oIndexCont;
            delete oIndexCont1;
            delete oIndexCont2;
            undelete oIndexCont;
        }
        Apttus__APTS_Agreement__c oAggCheck = [SELECT Id, APTS_Non_Standard_Deal_Indexation__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        system.assertEquals(TRUE, oAggCheck.APTS_Non_Standard_Deal_Indexation__c);
	}

}