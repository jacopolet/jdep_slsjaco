/**
* @author        Marvin Gatchalian
* @date          19.April.2018
* @description   Test class for TS_DisasterRecoveryButtonController.
* @revision(s)
*/

@isTest
public class TS_DisasterRecoveryButtonController_Test {
    
    public static TS_DisasterRecoveryButtonController processButton = new TS_DisasterRecoveryButtonController(null);
    
    private static testMethod void TS_DisasterRecovery_Execute() {
                           
        Test.startTest();
           //System.assert(TS_DisasterRecoveryButtonController.executeDisaster() != null);
           TS_DisasterRecoveryButtonController.executeDisaster();
        Test.stopTest();
            
    }
}