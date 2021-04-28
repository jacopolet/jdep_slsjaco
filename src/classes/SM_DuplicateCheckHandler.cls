public without sharing class SM_DuplicateCheckHandler {
	@InvocableMethod
    public static List<Boolean> findduplicate(List<variableReceiver> dupevalues){
        Boolean duplicatefound = false; 
        List<Account> accountlist = new List<Account>();
        List<Datacloud.FindDuplicatesResult> results;
        List<Boolean> result = new List<Boolean>();
        String maincity, maincountry, mainpostalcode, mainhousenumber, mainstreetonly, mainhousenumbersupplement;
        if (dupevalues != null){
            for (variableReceiver var : dupevalues){
                maincity = var.maincity;
                maincountry = var.maincountry;
                mainpostalcode = var.mainpostalcode;
                mainhousenumber = var.mainhousenumber;
                mainstreetonly = var.mainstreetonly;
                mainhousenumbersupplement = var.mainhousenumbersupplement;
            }
        }
        Account finddupe = new Account();
        finddupe.Main_City__c = maincity;
        finddupe.Main_Country__c = maincountry;
        finddupe.Main_House_Number__c = mainhousenumber;
        finddupe.Main_Street_Only__c = mainstreetonly;
        finddupe.House_Number_Supplement__c = mainhousenumbersupplement;
        finddupe.Main_Postal_Code__c = mainpostalcode;
        
        
        accountlist.add(finddupe);
        
        results = Datacloud.FindDuplicates.findDuplicates(accountlist);
        
		// Find the first duplicate result with a match result, then use the first match record.
		for (Datacloud.DuplicateResult dr : results[0].getDuplicateResults()) {
             if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                    duplicatefound = true;
                    break;
             }
             
        }

        result.add(duplicatefound);
        return result;
    }
    
    public class variableReceiver{
        @InvocableVariable
        public String maincity;
        
        @InvocableVariable
        public String maincountry;
        
        @InvocableVariable
        public String mainpostalcode;
        
        @InvocableVariable
        public String mainhousenumber;
        
        @InvocableVariable
        public String mainstreetonly;
        
        @InvocableVariable
        public String mainhousenumbersupplement;
    }
}