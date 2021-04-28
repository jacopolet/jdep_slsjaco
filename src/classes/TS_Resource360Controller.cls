/*
* @author        Xen Reyes
* @date          8.08.2018
* @description   Controller class for TS_Resource360 Lightning Component
* @revision(s)
*/
public with sharing class TS_Resource360Controller {
    
    @AuraEnabled
    public static String getSuggestedEngineers(String postalCode, String salesOrg){

        CustomLogging.push('getSuggestedEngineers', 'TS_Resource360Controller');

        LightningResponse lResponse = new LightningResponse();
        Set<Id> resourceIdSet = new Set<Id>();
        Id postCodeTrimId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Postal Code Trim').getRecordTypeId();
        Integer trimNum = 0;
        String postCodeToSearch;

        /*
        * @author        Ritesh Kumar
        * @date          22.08.2018
        * @description   Made changes according to KTS-2092. 
        * @revision(s)
        */

        //To map the priority filed with EngineerRouting.Resource__c
        Map<Id,Integer> priorityIndexMap = new Map<Id,Integer>();

        //To map the Recource object to priority Index
        Map <Integer, List<Resource__c>> PriorityMap = new Map <Integer, List<Resource__c>>(); 

        //TO sort the priority
        List<Integer> sortedNumber = new List<Integer>();

        try{

            //XEN REYES - April 15, 2019 - ALM 6741
            List<CountrySetting__c> cs = [SELECT Id, NumberofCharacters__c FROM CountrySetting__c WHERE (RecordTypeId =: postCodeTrimId AND Active__c = true AND Country__c =: salesOrg) LIMIT 1];
        
            if(!cs.isEmpty()){
                trimNum = Integer.valueOf(cs[0].NumberofCharacters__c);
            }

            if(trimNum != 0){
                postCodeToSearch = postalCode.mid(0, trimNum);
            }

            //List<EngineerRouting__c> engrRoutingList = [SELECT Id, Resource__c FROM EngineerRouting__c WHERE (PostalCode__c =: postCodeToSearch AND SalesOrganization__c =: salesOrg AND Active__c = true)];
            List<EngineerRouting__c> engrRoutingList = [SELECT Id, Resource__c,Priority__c FROM EngineerRouting__c WHERE (PostalCode__c =: postCodeToSearch AND SalesOrganization__c =: salesOrg AND Active__c = true) ORDER BY Priority__c ASC NULLS LAST];//Changed the query as per KTS-2092 By Ritesh Kumar
            if(!engrRoutingList.isEmpty()){
                for(EngineerRouting__c er : engrRoutingList){
                    //Commented by Ritesh Kumar
                    //resourceIdSet.add(er.Resource__c);
                    if(er.Resource__c != null){
                        priorityIndexMap.put(er.Resource__c,(Integer)er.Priority__c);
                    }
                }
            }

            //List<Resource__c> listResource = [SELECT Id, Name, Team__c, EmployeeFirstName__c, EmployeeLastName__c, EmailAddress__c FROM Resource__c WHERE Sales_Organization__c =: salesOrg AND Id IN: resourceIdSet];
            //lResponse.returnValue = JSON.serialize(listResource);
            
            //Added by Ritesh Kumar for KTS-2092, Edited query( added fields and changed to SalesOrg__c) by Karen Hung for KTS-2373 12/5/2018
            for(Resource__c resource :[SELECT Id, Name, Team__c, EmployeeFirstName__c, EmployeeLastName__c, EmailAddress__c, Phone__c, Skills__c FROM Resource__c WHERE SalesOrg__c =: salesOrg AND Id IN: priorityIndexMap.keySet()]){
                if(priorityIndexMap.containsKey(resource.Id)){
                    if(PriorityMap.containsKey(priorityIndexMap.get(resource.Id))){
                        List<Resource__c> tempList = priorityMap.get(priorityIndexMap.get(resource.Id));
                        tempList.add(resource);
                        PriorityMap.put(priorityIndexMap.get(resource.Id),tempList);
                    }else{
                        PriorityMap.put(priorityIndexMap.get(resource.Id),new list<Resource__c> {resource});
                    }
                }
            }
            
            if(PriorityMap != null){
                sortedNumber.addAll(PriorityMap.keySet());
            }

            sortedNumber.sort();
            List<Resource__c> listResource1 = new List<Resource__c>();
            for(Integer i : sortedNumber){
               if(i != null){
                    listResource1.addAll(PriorityMap.get(i));
               }
                
            }

            //adding null Priority.
            if(sortedNumber.contains(null)){
                listResource1.addAll(PriorityMap.get(null));
            }

            lResponse.returnValue = JSON.serialize(listResource1);
        
        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();

            CustomLogging.debugException(e);
            CustomLogging.pop();
        }

        CustomLogging.pop();
        return JSON.serialize(lResponse);   
    }

    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;

        public LightningResponse(){
            this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }
}