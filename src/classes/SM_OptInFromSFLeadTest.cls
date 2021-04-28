@isTest
public without sharing class SM_OptInFromSFLeadTest {
	private static testMethod void optinLead() {

        List<DataUsePurpose> duplist = new List<DataUsePurpose>();
        DataUsePurpose dup = new DataUsePurpose();
        dup.Name = 'marketing';
        duplist.add(dup);
        
        DataUsePurpose dup1 = new DataUsePurpose();
        dup1.Name = 'survey';
        duplist.add(dup1);
        
        DataUsePurpose dup2 = new DataUsePurpose();
        dup2.Name = 'profiling';
        duplist.add(dup2);
       
        insert duplist;
        
        Lead lead1 = new Lead();
        
        lead1.FirstName = 'Jed';
        lead1.LastName = 'Samaniego';
        lead1.Phone = '+31302979111';
        lead1.Email = 'test123@gmail.com';
        lead1.Company = 'Kead123123123';
        lead1.Sales_Organization__c = 'SAP_0111';
                
        insert lead1;

        Individual ind1 = new Individual();
        ind1.FirstName = lead1.FirstName;
        ind1.LastName = lead1.LastName;
        ind1.Related_To__c = lead1.Id;
        insert ind1;

    

        Lead updateLead = [Select Id, IndividualId from Lead where Id = :lead1.Id];
        updateLead.IndividualId = ind1.Id;
        update updateLead;

        List<String> ids = new List<String>();
        ids.add(updateLead.Id);
        
        SM_OptInFromSFLead.generateOptIns generateoptinrec = new  SM_OptInFromSFLead.generateOptIns();
        generateoptinrec.leadid = updateLead.Id;
        List<SM_OptInFromSFLead.generateOptIns> goptin = new List<SM_OptInFromSFLead.generateOptIns>();
        goptin.add(generateoptinrec);
        
        SM_OptInFromSFLead.generateRecommendationforLead(goptin);
        Lead l = [Select Id, Consent_Status_Marketing__c FROM Lead WHERE Id = :updateLead.Id];
        System.assert(l.Consent_Status_Marketing__c == null);
    }
}