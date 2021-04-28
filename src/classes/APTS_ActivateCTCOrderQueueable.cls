/**
    * Class Name : APTS_ActivateCTCOrderQueueable
    * Description : Queueable class used for activation of CTC orders
    * Author : Aarthi Pitchai
    * Date Created : 14-Apr-2021    
**/
public without sharing class APTS_ActivateCTCOrderQueueable implements Queueable {

    private Id orderID = null;
    private Id soldToAccountID = null;
    private string  ctcScenario = null;
    
    public APTS_ActivateCTCOrderQueueable(id orderID, id soldToAccountID, string ctcScenario) {
        this.orderID = orderID;
        this.soldToAccountID = soldToAccountID;
        this.ctcScenario = ctcScenario;
    }
    
    public void execute(QueueableContext context) {

        try {
            APTS_ContractChangeNewUXController.invokeAcceptOrderAPI(orderId);   
            APTS_ContractChangeNewUXController.updateAndSubmitOrder(orderId,soldToAccountID,ctcScenario);                                             
            APTS_ContractChangeNewUXController.removeCustomSettingsEntries(); 
        } catch(Exception ex) {            
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage(), 'Order', orderId, 'OM', false, false, null, true);
            
        }        
    }
}