global without sharing class SM_OptInFromSF {
	@InvocableMethod(label='Generate NBA for no Opt-In'
        			 description='This function returns recommendations for Opting in')
    global static List<List<Recommendation>> generateRecommendationforContact(List<generateOptIns> inputRequests){
        Map<String, APTS_SalesOrg_Settings__mdt> getsalesorgrecords = SM_GetMetadata.getsalesorgmetadatarec();
        List<List<Recommendation>> outputs = new List<List<Recommendation>>();
        List<Recommendation> recs = new List<Recommendation>(); 
        Set<String> contactIds = new Set<String>();
        for (generateOptIns inputRequest : inputRequests){
            if (inputRequest.contactId != null){
                contactIds.add(inputRequest.contactId);
            }
        }
        Id picId = [Select Id from ContentAsset where DeveloperName = 'NBA_picture'].Id;
        List<Contact> currentcontact = [Select Id, Consent_Status_Profiling__c, Consent_Status_Marketing__c, Name, Sales_Organization__c from Contact where Id IN :contactIds];
        if (currentcontact != null){
            for (Contact contactrec : currentcontact){
                if (contactrec.Consent_Status_Marketing__c == null && getsalesorgrecords.get(contactrec.Sales_Organization__c).Show_NBA__c == true){
                    Recommendation rec = new Recommendation(
                    Name = 'This contact did not provide email consent yet. After discussing this with your contact, do you want to send a personal message?',
                    Description = 'This contact did not provide email consent yet. After discussing this with your contact, do you want to send a personal message?',
                    ImageId = picId,
                    ActionReference = 'SM_OptIn1to1',
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
        @InvocableVariable(label='Contact ID')
        global String contactId;
    }
}