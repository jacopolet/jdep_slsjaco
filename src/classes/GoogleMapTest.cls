/**
    * @author        Alvin Lomod
    * @date          02.02.2018 - Alvin Lomod KASM-628        
    * @description   Test Class of Google Map Apex Class
    * @revision(s)   
    */
@isTest
private class GoogleMapTest{
    
    private static testMethod void CallAllMethods(){
        
        //GoogleMap gm = new GoogleMap();
        List<Account> pAccList = GoogleMap.getProspectAccounts();
        List<Account> cAccList = GoogleMap.getCustomerAccounts();
        List<Lead> ldList = GoogleMap.getLeads();
        List<Opportunity> oppList = GoogleMap.getOpportunities();
        String hostURL = GoogleMap.getHostURL();
        
        system.assertEquals(pAccList.size(), 0);
        system.assertEquals(cAccList.size(), 0);
        system.assertEquals(ldList.size(), 0);
        system.assertEquals(oppList.size(), 0);
        system.assert(hostURL != Null);
        
        
    }

}