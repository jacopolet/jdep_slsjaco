public without sharing class SM_CollarWfoDistributionClass {
	@AuraEnabled
    public static Account saveCollarAndWfoPercentage(Id recordId, Decimal collar, Decimal wfo){
            Account acc = [Select Id, Blue_Collar__c, Work_from_office__c FROM Account WHERE Id = :recordId];
            if (collar != acc.Blue_Collar__c) {
                acc.Blue_Collar__c = collar;
                acc.White_Collar__c = 100 - collar;
            }
            
            if (wfo != acc.Work_from_office__c) {
                acc.Work_from_office__c = wfo;
                acc.Work_from_home__c = 100 - wfo;
            }
            update acc;
            return acc;
    }
}