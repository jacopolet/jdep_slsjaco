public without sharing class SM_ResendEmailOrderConfirmation {
    @InvocableMethod
    public static void resendOrderConfirmation(List<Id> orderRecId) {
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__Order__c> orderRecs = new List<Apttus_Config2__Order__c>();
        orderRecs = [Select Id, APTS_Order_Confirmation_Status__c FROM Apttus_Config2__Order__c WHERE Id IN :orderRecId];
        for (Apttus_Config2__Order__c orderRec : orderRecs) {
            orderRec.APTS_Order_Confirmation_Status__c = 'Resend Order Confirmation';
            orderList.add(orderRec);
        }
        
        if (!orderList.isEmpty()) {
            APTS_OrderUtils.stopOrderTrigger();
            update orderList;
        }
    }
}