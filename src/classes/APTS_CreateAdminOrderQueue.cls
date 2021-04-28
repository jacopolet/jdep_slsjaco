/***
 * Change history
 * v100 - Aftab
***/
public class APTS_CreateAdminOrderQueue implements Queueable {
    Apttus__APTS_Agreement__c processAgr ;

    public APTS_CreateAdminOrderQueue(Apttus__APTS_Agreement__c agr)
    {
        processAgr = agr;
    }
    public void execute(QueueableContext context) {
        if(processAgr != null){
            Account oAccount = [SELECT Id,
                                        Apttus_Config2__BillingPreferenceId__c,
                                        Apttus_Config2__PaymentTermId__c,
                                        Language__c,
                                        Sales_Organization__c,
                                        Division__c,
                                        Distribution_Channel__c,
                                        Bill_To_Payer_Account__c,
                                        Related_Payer_Account__c
                                        FROM Account
                                        WHERE Id =: processAgr.Apttus__Account__c
                                        LIMIT 1];
            //system.debug('$$$$ processAgr '+processAgr);
            APTS_CLMUtil.createAdminOrder(processAgr, oAccount);
            APTS_CLMUtil.agreementAdminChanges(processAgr, oAccount);
        }
    }
}