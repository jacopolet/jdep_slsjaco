/**
* @author        Adrian Reyes
* @date          05.01.2018
* @description   Class used to bulkify queries before executing Technical Specialist flow
* @revision(s)
*/
	
global with sharing class TS_TechSpecialistFlowProcessor {
	/**
    * @author        Adrian Reyes
    * @date          05.01.2018           
    * @description   Method called from TS_Technical Specialist process builder
    * @revision(s)
    */
    @InvocableMethod
    global static void executeTechSpecialistFlow(List<Id> caseIDs) {
    	CustomLogging.push('executeTechSpecialistFlow', 'TS_TechSpecialistFlowProcessor');
        List<Case> cases = [SELECT Id, PhysicalAsset__c, SalesOrganization__c, SubType__c, IsEscalated, TechnicalInspectionNeeded__c FROM Case WHERE Id IN: caseIDs];
        List<Case> caseToProcess = new List<Case>();
        Map<String,CountrySetting__c> techSpecialistSettings = new Map<String,CountrySetting__c>();
        Set<Id> physicalAssetIDs = new Set<Id>();
        Set<String> caseSubTypes = new Set<String>{Label.TS_Case_SubType_CorrectMaintAPI, Label.TS_Case_SubType_1stLineCorrectMaint};
        
        for(CountrySetting__c techSpecialistSetting: [SELECT Country__c, CaseSubtype__c, Max_Visits_Treshhold__c, Treshold_Days__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'Technical_Specialist_Indicator' AND Active__c = true])
            techSpecialistSettings.put(techSpecialistSetting.Country__c, techSpecialistSetting);
        
        for(Case c: cases)
            physicalAssetIDs.add(c.PhysicalAsset__c);
        
        Map<Id,PhysicalAsset__c> physicalAssetMap = new Map<Id,PhysicalAsset__c>([SELECT (SELECT SalesOrganization__c, SubType__c, Created_Date__c FROM Cases__r WHERE SubType__c IN: caseSubTypes) FROM PhysicalAsset__c WHERE Id IN: physicalAssetIDs]);

        for(Case c: cases){
            c.Technical_Specialist_Counter__c = 0;

            for(Case assetCase: physicalAssetMap.get(c.PhysicalAsset__c).Cases__r){
                
                //XR KTS-1997 22.08.2018
                if(techSpecialistSettings.containsKey(c.SalesOrganization__c)){
                    Integer thresholdDays = Integer.valueOf(techSpecialistSettings.get(c.SalesOrganization__c).Treshold_Days__c) * -1;
                    if(assetCase.Created_Date__c > Date.today().addDays(thresholdDays) && assetCase.SalesOrganization__c == c.SalesOrganization__c && assetCase.SubType__c == c.SubType__c)
                        c.Technical_Specialist_Counter__c++;
                }
            }
        }
        
        try {
        	if(!cases.isEmpty()){
        		Map<String, Object> params = new Map<String, Object>();
        		params.put('cases', cases);
                params.put('techSpecialistSettings', techSpecialistSettings.values());
        		Flow.Interview.TS_Technical_Specialist_Indicator techSpecialistFlow = new Flow.Interview.TS_Technical_Specialist_Indicator(params);
    			techSpecialistFlow.start();
        	}
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

    	CustomLogging.pop();
    }
}