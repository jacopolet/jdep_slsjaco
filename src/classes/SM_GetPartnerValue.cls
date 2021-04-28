//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   Dec 09 2020
// Usage        :   Get IsPartner value becuase IsPartner field is not usable in FLOW
//
//-------------------------------------------------------------------------------------------//
global without sharing class SM_GetPartnerValue {
    @InvocableMethod
    public static List<Boolean> SM_GetPartnerValueboolean(List<Id> input) {
        List<Boolean> getpartnerboolean = new List<Boolean>();
        List<Account> getaccountrec = new List<Account>();
        if (!input.isEmpty()){
           	getaccountrec = [Select Id, IsPartner from Account where ID IN :input Limit 1];
            if (!getaccountrec.isEmpty()){
                for (Account a : getaccountrec){
                    getpartnerboolean.add(a.IsPartner);
                }
            }
        }
        return getpartnerboolean;
    }
}