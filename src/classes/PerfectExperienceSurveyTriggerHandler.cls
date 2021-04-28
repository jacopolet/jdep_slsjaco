public without sharing class PerfectExperienceSurveyTriggerHandler implements ITriggerHandler{
	public static Boolean isTriggerDisabled = true;
    Map<Id, Perfect_Experience_Survey__c> oldMapPE = new Map<Id, Perfect_Experience_Survey__c>();
       
    public void beforeInsert(List<SObject> newListPE){
        populatePEScore((List<Perfect_Experience_Survey__c>) newListPE, (Map<Id, Perfect_Experience_Survey__c>) oldMapPE);
        
    } 
 
    public void beforeUpdate(List<SObject> newListPE, Map<Id, SObject> newMApPE, List<SObject> oldListPE, Map<Id, SObject> oldMapPE){
        populatePEScore((List<Perfect_Experience_Survey__c>) newListPE, (Map<Id, Perfect_Experience_Survey__c>) oldMapPE);
        
    }
 
    public void beforeDelete(List<SObject> oldListPE, Map<Id, SObject> oldMapPE){

    }
 
    public void afterInsert(List<SObject> newListPE, Map<Id, SObject> oldMapPE){
        maxValofTotalGrandScore((List<Perfect_Experience_Survey__c>) newListPE);
    }
 
    public void afterUpdate(List<SObject> newListPE , Map<Id, SObject> newMApPE, List<SObject> oldListPE, Map<Id, SObject> oldMapPE){
        maxValofTotalGrandScore((List<Perfect_Experience_Survey__c>) newListPE);
    }
 
    public void afterDelete(List<SObject> oldListPE, Map<Id, SObject> oldMapPE){

    }
 
    public void afterUndelete(List<SObject> newListPE, Map<Id, SObject> newMApPE){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().PerfectExperienceSurveyTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    public static void populatePEScore(List<Perfect_Experience_Survey__c> newListPE, Map<Id, Perfect_Experience_Survey__c> oldMapPE){
        CustomLogging.push('populatePEScore', 'PerfectExperienceSurveyTriggerHandler');
        try {
            List<Perfect_Experience_Score__c> listOfPEScore = new List<Perfect_Experience_Score__c>([SELECT Id, Name, Segment__c, Occasion__c, Category__c, Comm_Non_Comm__c , Category_Score__c
                                                                                                     FROM Perfect_Experience_Score__c]);
            Map<String, Perfect_Experience_Score__c> pESurveyScore = new Map<String, Perfect_Experience_Score__c>();
            for (Perfect_Experience_Survey__c pesurvey : newListPE) {
                for (Perfect_Experience_Score__c pescore : listOfPEScore) {
                    if(pesurvey.Comm_Non_Comm__c == pescore.Comm_Non_Comm__c) {
                        pESurveyScore.put(pescore.Category__c, pescore);
                    }
                }
                if (!oldMapPE.isEmpty()) {
                    Perfect_Experience_Survey__c oldPE = oldMapPE.get(pesurvey.Id);
                    if (pesurvey.Coffee__c != oldPE.Coffee__c || pesurvey.Tea__c != oldPE.Tea__c || pesurvey.Machine__c != oldPE.Machine__c || pesurvey.Milk__c != oldPE.Milk__c 
                        || pesurvey.Sugar__c != oldPE.Sugar__c || pesurvey.Cacao__c != oldPE.Cacao__c || pesurvey.Service_Training__c != oldPE.Service_Training__c 
                        || pesurvey.Cups_Glasses_Porcelain__c != oldPE.Cups_Glasses_Porcelain__c || pesurvey.Display_Accessoires__c != oldPE.Display_Accessoires__c || pesurvey.Barista_Station__c != oldPE.Barista_Station__c) {
                        pesurvey.Service_Training_Score__c = 0;
                        pesurvey.Cups_Glasses_Porcelain_Score__c = 0;
                        pesurvey.Display_Accessoires_Score__c = 0;
                        pesurvey.Coffee_Score__c = 0;
                        pesurvey.Tea_Score__c = 0;
                        pesurvey.Machine_Score__c = 0;
                        pesurvey.Milk_Score__c = 0;
                        pesurvey.Sugar_Score__c = 0;
                        pesurvey.Cacao_Score__c = 0;
                        if (pesurvey.Barista_Station__c == 'No' || pesurvey.Barista_Station__c == '' || pesurvey.Barista_Station__c == Null) {
                            if (pesurvey.Display_Accessoires__c <> Null) {
                                String[] displayandaccessoires = pesurvey.Display_Accessoires__c.split(';');
                                for(String daa : displayandaccessoires) {
                                    pesurvey.Display_Accessoires_Score__c += pESurveyScore.get(daa).Category_Score__c; 
                                }
                            }
                            pesurvey.Coffee_Score__c = pESurveyScore.get(pesurvey.Coffee__c).Category_Score__c;
                            pesurvey.Tea_Score__c = pESurveyScore.get(pesurvey.Tea__c).Category_Score__c;
                            pesurvey.Machine_Score__c = pESurveyScore.get(pesurvey.Machine__c).Category_Score__c;
                            pesurvey.Milk_Score__c = pESurveyScore.get(pesurvey.Milk__c).Category_Score__c;
                            pesurvey.Sugar_Score__c = pESurveyScore.get(pesurvey.Sugar__c).Category_Score__c;
                            pesurvey.Cacao_Score__c = pESurveyScore.get(pesurvey.Cacao__c).Category_Score__c;
                            pesurvey.Service_Training_Score__c = pESurveyScore.get(pesurvey.Service_Training__c).Category_Score__c;
                            pesurvey.Cups_Glasses_Porcelain_Score__c = pESurveyScore.get(pesurvey.Cups_Glasses_Porcelain__c).Category_Score__c;
                            
                        } else if (pesurvey.Barista_Station__c == 'Yes') {
                            pesurvey.Service_Training__c = 'Service Yes';
                            pesurvey.Service_Training_Score__c = 10;
                            pesurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
                            pesurvey.Cups_Glasses_Porcelain_Score__c = 15;
                            pesurvey.Display_Accessoires__c = 'Tea display;Cross sell display';
                            pesurvey.Display_Accessoires_Score__c = 5;
                            pesurvey.Coffee__c = 'Blend premium';
                            pesurvey.Coffee_Score__c = 20;
                            pesurvey.Tea__c = 'Tea - Premium';
                            pesurvey.Tea_Score__c = 15;
                            pesurvey.Machine__c = 'Machine Yes';
                            pesurvey.Machine_Score__c = 8;
                            pesurvey.Milk__c = 'Milk Yes';
                            pesurvey.Milk_Score__c = 10;
                            pesurvey.Sugar__c = 'Sugar Yes';
                            pesurvey.Sugar_Score__c = 10;
                            pesurvey.Cacao__c = 'Cacao Yes';
                            pesurvey.Cacao_Score__c = 7;
                        }
                    }
                } else {
                    if (pesurvey.Coffee__c != Null || pesurvey.Tea__c != Null || pesurvey.Machine__c != Null || pesurvey.Milk__c != Null || pesurvey.Sugar__c != Null || pesurvey.Cacao__c != Null || pesurvey.Service_Training__c != Null || pesurvey.Cups_Glasses_Porcelain__c !=  Null || pesurvey.Display_Accessoires__c != Null) {
                        pesurvey.Service_Training_Score__c = 0;
                        pesurvey.Cups_Glasses_Porcelain_Score__c = 0;
                        pesurvey.Display_Accessoires_Score__c = 0;
                        pesurvey.Coffee_Score__c = 0;
                        pesurvey.Tea_Score__c = 0;
                        pesurvey.Machine_Score__c = 0;
                        pesurvey.Milk_Score__c = 0;
                        pesurvey.Sugar_Score__c = 0;
                        pesurvey.Cacao_Score__c = 0;
                        if (pesurvey.Barista_Station__c == 'No' || pesurvey.Barista_Station__c == '' || pesurvey.Barista_Station__c == Null) {
                            if (pesurvey.Display_Accessoires__c <> Null) {
                                String[] displayandaccessoires = pesurvey.Display_Accessoires__c.split(';');
                                for(String daa : displayandaccessoires) {
                                    pesurvey.Display_Accessoires_Score__c += pESurveyScore.get(daa).Category_Score__c; 
                                }
                            }
                            pesurvey.Coffee_Score__c = pESurveyScore.get(pesurvey.Coffee__c).Category_Score__c;
                            pesurvey.Tea_Score__c = pESurveyScore.get(pesurvey.Tea__c).Category_Score__c;
                            pesurvey.Machine_Score__c = pESurveyScore.get(pesurvey.Machine__c).Category_Score__c;
                            pesurvey.Milk_Score__c = pESurveyScore.get(pesurvey.Milk__c).Category_Score__c;
                            pesurvey.Sugar_Score__c = pESurveyScore.get(pesurvey.Sugar__c).Category_Score__c;
                            pesurvey.Cacao_Score__c = pESurveyScore.get(pesurvey.Cacao__c).Category_Score__c;
                            pesurvey.Service_Training_Score__c = pESurveyScore.get(pesurvey.Service_Training__c).Category_Score__c;
                            pesurvey.Cups_Glasses_Porcelain_Score__c = pESurveyScore.get(pesurvey.Cups_Glasses_Porcelain__c).Category_Score__c;
                            
                        } else if (pesurvey.Barista_Station__c == 'Yes') {
                            pesurvey.Service_Training__c = 'Service Yes';
                            pesurvey.Service_Training_Score__c = 10;
                            pesurvey.Cups_Glasses_Porcelain__c = 'Cups / Glasses & Porcelain Yes';
                            pesurvey.Cups_Glasses_Porcelain_Score__c = 15;
                            pesurvey.Display_Accessoires__c = 'Tea display;Cross sell display';
                            pesurvey.Display_Accessoires_Score__c = 5;
                            pesurvey.Coffee__c = 'Blend premium';
                            pesurvey.Coffee_Score__c = 20;
                            pesurvey.Tea__c = 'Tea - Premium';
                            pesurvey.Tea_Score__c = 15;
                            pesurvey.Machine__c = 'Machine Yes';
                            pesurvey.Machine_Score__c = 8;
                            pesurvey.Milk__c = 'Milk Yes';
                            pesurvey.Milk_Score__c = 10;
                            pesurvey.Sugar__c = 'Sugar Yes';
                            pesurvey.Sugar_Score__c = 10;
                            pesurvey.Cacao__c = 'Cacao Yes';
                            pesurvey.Cacao_Score__c = 7;
                        }
                    }
                }
            }

        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    public static void maxValofTotalGrandScore(List<Perfect_Experience_Survey__c> newListPE) {
       CustomLogging.push('maxValofTotalGrandScore', 'PerfectExperienceSurveyTriggerHandler');
       try {
           for(Perfect_Experience_Survey__c pe : newListPE){
              if (pe.Total_Survey_Score__c > 100 ) {
                 pe.addError('Total Survey Score can only have maximum of 100 ');
              }
           }
       
       } catch (Exception e) {
           CustomLogging.debugException(e);
           CustomLogging.pop();      
           System.debug(e.getMessage() + '\n' + e.getStackTraceString());
       }
    }
}