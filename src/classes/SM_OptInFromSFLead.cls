global without sharing class SM_OptInFromSFLead {
	@InvocableMethod(label='Generate NBA for no Opt-In Lead'
        			 description='This function returns recommendations for Opting in')
    global static List<List<Recommendation>> generateRecommendationforLead(List<generateOptIns> inputRequests){
        Map<String, APTS_SalesOrg_Settings__mdt> getsalesorgrecords = SM_GetMetadata.getsalesorgmetadatarec();
        List<List<Recommendation>> outputs = new List<List<Recommendation>>();
        List<Recommendation> recs = new List<Recommendation>(); 
        Set<String> leadIds = new Set<String>();
        for (generateOptIns inputRequest : inputRequests){
            if (inputRequest.leadid != null){
                leadIds.add(inputRequest.leadid);
            }
        }
        List<Lead> currentlead = [Select Id, Consent_Status_Profiling__c, Consent_Status_Marketing__c, Name, Sales_Organization__c  from Lead where Id IN :leadIds];
        if (currentlead != null){
            for (Lead leadrec : currentlead){
                if ((leadrec.Consent_Status_Profiling__c == null || leadrec.Consent_Status_Marketing__c == null) && getsalesorgrecords.get(leadrec.Sales_Organization__c).Show_NBA__c == true){
                    Recommendation rec = new Recommendation(
                    Name = 'This contact did not provide email consent yet. After discussing this with your contact, do you want to send a personal message?',
                    Description = 'This contact did not provide email consent yet. After discussing this with your contact, do you want to send a personal message?',                      
                    ActionReference = 'SM_OptIn1to1Lead',
                    AcceptanceLabel = 'Yes, send opt-in email',
                    RejectionLabel = 'No, not now'    
                	);
                    recs.add(rec);
                }
            }
            outputs.add(recs);
        }
        return outputs; 
    }
    
    global class generateOptIns {
        @InvocableVariable(label='Lead Id')
        global String leadid;
    }
}