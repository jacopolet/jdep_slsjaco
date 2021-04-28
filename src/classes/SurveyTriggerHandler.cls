/**
* @author        Marvin Gatchalian
* @date          05.29.2018           
* @description   Class responsible for the trigger business logic of Survey object
* @revision(s)   8.3.2018 Paul Aguiling KTS-1981: Added validateSurveyInterviewee()
*/

public with sharing class SurveyTriggerHandler implements ITriggerHandler {
    
    Private Static User CURRENTUSER = null;
    
    public void BeforeInsert(List<SObject> newList) {
        CustomLogging.push('BeforeInsert', 'SurveyTriggerHandler');
        Map <Id, Survey__c> pAssetSurveyMap = new Map <Id, Survey__c> ();
        List <Survey__c> filteredSurvey = new List <Survey__c>();
        
        try {  
            if (CURRENTUSER == null)
                CURRENTUSER = getUsers();
            
            // Please re-use this loop for future any requirements         
            for (Survey__c eachSurvey: (List<Survey__c>) newList) {
                setSalesOrgAnd(eachSurvey);
                if (eachSurvey.Machine__c != null && eachSurvey.ParentSurvey__c != null) {
                    pAssetSurveyMap.put (eachSurvey.Machine__c, eachSurvey);
                    filteredSurvey.add(eachSurvey);
                }
            }
            if (!pAssetSurveyMap.keySet().isEmpty())
                setInveviewee(pAssetSurveyMap, filteredSurvey);
            

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
     
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {  
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        CustomLogging.push('AfterInsert', 'SurveyTriggerHandler');

        try {  
            CountFaultScore(newList, newMapItems, null);
            //validateSurveyInterviewee(newList, null);//KTS-1981

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'SurveyTriggerHandler');
        try {  
            CountFaultScore(newList, newMapItems, oldMapItems);
            validateSurveyInterviewee(newList, oldMapItems);//KTS-1981

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();        
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){
        
    }
    
    public Boolean IsDisabled() {
        return false;
    }
    
    private void setSalesOrgAnd (Survey__c currentRecord) {
        currentRecord.Country__c = CURRENTUSER.Sales_Organization__c;
    }
    
    private User getUsers() {       
        List<User> userList = [Select Id,Sales_Organization__c from User where id=: Userinfo.getUserid()];       
        return !userList.isEmpty() ? userList.get(0) : null;
    }
    
    private void setInveviewee (Map <Id, Survey__c> pAssetSurveyMap, List <Survey__c> filteredSurvey) {
        Set <Id> allParent = new Set <Id> ();
        Set <Id> allowedParent = new Set <Id> ();
        
        for (Survey__c eachPA :filteredSurvey) {
            allParent.add(eachPA.ParentSurvey__c);
        }
        if (!allParent.isEmpty()) {
            for (Survey__c eachParent :[Select id, SurveyType__c From Survey__c Where id in :allParent]) {
                //Make correction is if statement. 
                //Changed vale Health & Safety Check to Health & Safety Customer Check.
                //By Ritesh Kumar 
                if (eachParent.SurveyType__c == 'Health & Safety Customer Check') {
                    allowedParent.add(eachParent.id);
                }
            }
        }
        
        if (!allowedParent.isEmpty()) {
            List <PhysicalAsset__c> allPA = [Select id, OP_LastPerformingOperator__c from PhysicalAsset__c
                                             Where id in :pAssetSurveyMap.keySet()];
            
            for (PhysicalAsset__c eachPA :allPA) {
                Survey__c relatedSurvey = pAssetSurveyMap.get(eachPA.id);
                if (allowedParent.contains(relatedSurvey.ParentSurvey__c))
                    relatedSurvey.Interviewee__c = eachPA.OP_LastPerformingOperator__c;
            }
            
        }
    }
    
    
    private void CountFaultScore (List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
        //Health & Safety: Freshbrew = Freshbrew_Check (Field Set) = Freshbrew Check (Survey Type)
        Set <String> faultCollection = new Set <String>();
        Map <Id, Integer> surveyFalseCountMap = new Map <Id, Integer>();

        //Re-initialize map to access All Survey__c attributes
        Map <Id, Survey__c> newSurvey = ( Map<Id, Survey__c>) newMapItems;
        Map <Id, Survey__c> oldSurvey = ( Map<Id, Survey__c>) oldMapItems;
        
        for (Survey__c eachSurvey: (List<Survey__c>) newList) {
            String surveyType = eachSurvey.SurveyType__c;
            String surveyTypeFieldSet = ConvertToAPINameFormat(surveyType);
            
            if (eachSurvey.Requires_Survey_Score__c) {
                if (Schema.SObjectType.Survey__c.fieldSets.getMap().containsKey(surveyTypeFieldSet)) {
                    List <Schema.FieldSetMember> relatedFields = Schema.SObjectType.Survey__c.fieldSets.getMap().get(surveyTypeFieldSet).getFields();
                    
                    for(Schema.FieldSetMember fields :relatedFields) {
                        if (Trigger.isInsert && Trigger.isAfter) {
                            if (eachSurvey.get(fields.getFieldPath()) == 'False'){
                                faultCollection.add(fields.getFieldPath());
                            } 
                            surveyFalseCountMap.put (eachSurvey.Id, faultCollection.size());
                        }
                             
                        if (Trigger.isUpdate && Trigger.isAfter){
                            Survey__c surveyOld = (Survey__c) oldMapItems.get(eachSurvey.id);

                            //Francis Alindogan 06/13/2018 DOO-323 Added new criteria for cancelled surveys
                            if(eachSurvey.get(fields.getFieldPath()) != surveyOld.get(fields.getFieldPath()) || //surveys with attribute changes
                                oldSurvey.get(eachSurvey.Id).Status__c != TS_Constants.ORDER_CANCELED && newSurvey.get(eachSurvey.Id).Status__c == TS_Constants.ORDER_CANCELED //surveys with cancelled status
                              ) {
                                for (Schema.FieldSetMember fieldsInner :relatedFields) {
                                    if (eachSurvey.get(fieldsInner.getFieldPath()) == 'False')
                                        faultCollection.add(fieldsInner.getFieldPath());
                                }
                                surveyFalseCountMap.put (eachSurvey.Id, faultCollection.size());
                            }
                        } 
                    }
                }
            }
            
        }

        if (!surveyFalseCountMap.keySet().isEmpty()) {
            List <Survey__c> getSurveyRecordsToBeUpdated = updateScoreFromSurveySettings (surveyFalseCountMap, newMapItems);

            if (!getSurveyRecordsToBeUpdated.isEmpty() && Schema.sObjectType.Survey__c.isUpdateable()) {
                update getSurveyRecordsToBeUpdated;
                
                List <Survey__c> parentSurveyToUpdate = calculcateParentAverageScore(getSurveyRecordsToBeUpdated);
                if (!parentSurveyToUpdate.isEmpty() && Schema.sObjectType.Survey__c.isUpdateable())
                    update parentSurveyToUpdate;
            }
        }
            
        
    }
    
    private List <Survey__c> calculcateParentAverageScore (List <Survey__c> surveyUpdated) {
        Set<Id> parentIds = new Set<Id>();
        List <Survey__c> childSurvey = new List <Survey__c>();
        List <Survey__c> parentSurvey = new List <Survey__c>();
        for (Survey__c eachSurvey :surveyUpdated) {
            if (eachSurvey.ParentSurvey__c != null)
                parentIds.add(eachSurvey.ParentSurvey__c);
        }
        
        Map<Id, List<Survey__c>> parentIdChildsMap = new Map<Id, List<Survey__c>> ();
        if (!parentIds.isEmpty()) {
            //Francis Alindogan 06/13/2018 DOO-323 To remove surveys with cancelled status from parent average computation
            childSurvey = [Select id, Score__c, ParentSurvey__c From Survey__c Where ParentSurvey__c = :parentIds And Status__c != :TS_Constants.ORDER_CANCELED];
            for (Survey__c eachChild :childSurvey) {
                if (parentIdChildsMap.containsKey(eachChild.ParentSurvey__c))
                    parentIdChildsMap.get(eachChild.ParentSurvey__c).add(eachChild);
                else
                    parentIdChildsMap.put(eachChild.ParentSurvey__c, new List <Survey__c> {eachChild});
            }
        }
        
        if (!parentIdChildsMap.keySet().isEmpty()) {
            Decimal aveTotalScore = 0;
             
            for (Id eachParentId :parentIdChildsMap.keySet()) {
                Survey__c pSurvey = new Survey__c();
                pSurvey.id = eachParentId;
                Integer numberOfChild = parentIdChildsMap.get(eachParentId).size();
                
                for (Survey__c eachChild :parentIdChildsMap.get(eachParentId)) {
                    if (eachChild.Score__c != null)
                        aveTotalScore = aveTotalScore + eachChild.Score__c;
                }
                if (numberOfChild != 0) {
                    aveTotalScore = aveTotalScore / numberOfChild;
                    pSurvey.Average_Score__c = aveTotalScore;
                    parentSurvey.add(pSurvey);
                }
            }
            
        }
        
        Return parentSurvey;
        
    }
    
   
    private List <Survey__c> updateScoreFromSurveySettings (Map <Id, Integer> surveyFalseCountMap, Map<Id, SObject> newMapItems) {
        //Get Product by via Physical Asset
            
        Set <Id> productIds = new Set<Id>();
        List<String> surveyTypes = new List<String>();
        
        Map <Decimal, List<String>> faultRankingSurveyTypeCountryMap = new Map <Decimal,  List<String>>();
        Map <Decimal, List<String>> faultRankingSurveyTypeCountryProductMap = new Map <Decimal,  List<String>>(); //Added by Karen Hung for scenario with product
       // Map <String, Survey__c> ProductSurveyTypeSurveyMap = new Map <String, Survey__c>();
        Map <String, List<Survey__c>> surveyTypeSurveysMap = new Map <String, List<Survey__c>>();
        Map <String, List<Survey__c>> surveyTypeCountrySurveysMap = new Map <String, List<Survey__c>>();
        Map <String, List<Survey__c>> surveyTypeCountryProductSurveysMap = new Map <String, List<Survey__c>>(); //Added by Karen Hung for scenario with product
        
        //Surveys being inserted/updated
        List<Survey__c> surveysExt = [Select Machine__c, Machine__r.Product__c, SurveyType__c, Score__c, Average_Score__c, 
                                      ParentSurvey__c, Country__c  
                                      From Survey__c Where id in :surveyFalseCountMap.keySet()];
        
                                      
        for (Survey__c eachSurvey :surveysExt) {
            //String prodAndSurveyType = String.valueOf(eachSurvey.Machine__r.Product__c) + String.valueOf(eachSurvey.SurveyType__c);
            String surveyType = String.valueOf(eachSurvey.SurveyType__c);           
 
            surveyTypes.add(eachSurvey.SurveyType__c);
            //ProductSurveyTypeSurveyMap.put(prodAndSurveyType, eachSurvey);

            //Karen Hung 12/14/2018 add scenario for those with products
            if(eachSurvey.Machine__c !=null && eachSurvey.Machine__r.Product__c !=null){ // with products
                productIds.add(eachSurvey.Machine__r.Product__c);
                String surveyTypeCountryProduct = String.valueOf(eachSurvey.SurveyType__c) + String.valueOf(eachSurvey.Country__c) + eachSurvey.Machine__r.Product__c;
                if(surveyTypeCountryProductSurveysMap.containsKey(surveyTypeCountryProduct)){
                    surveyTypeCountryProductSurveysMap.get(surveyTypeCountryProduct).add(eachSurvey);    
                }else{
                    surveyTypeCountryProductSurveysMap.put(surveyTypeCountryProduct, new List<Survey__c> {eachSurvey});    
                }

            }else{ //without products

                String surveyTypeCountry = String.valueOf(eachSurvey.SurveyType__c) + String.valueOf(eachSurvey.Country__c);
                if (surveyTypeSurveysMap.containsKey(surveyTypeCountry)){
                    surveyTypeCountrySurveysMap.get(surveyTypeCountry).add(eachSurvey);
                    //surveyTypeSurveysMap.get(surveyType).add(eachSurvey);
                }else{ 
                    surveyTypeCountrySurveysMap.put(surveyTypeCountry, new List<Survey__c> {eachSurvey});
                    //surveyTypeSurveysMap.put(surveyType, new List<Survey__c> {eachSurvey});
                }
            }
        }
          
        //List <Survey_Settings__c> faultRankings = [Select Id, FaultRanking__c, SurveyType__c, Product__c From Survey_Settings__c 
        //                           Where SurveyType__c = :surveyTypes And Active__c = true 
        //                           And Product__c = :productIds And SurveySetting__c = 'Fault Ranking'];
                                     
        List <Survey_Settings__c> faultRankings = [Select Id, FaultRanking__c, SurveyType__c, Product__c, Country__c 
                                                   From Survey_Settings__c 
                                                   Where SurveyType__c IN :surveyTypes And Active__c = true 
                                                   And SurveySetting__c = 'Fault Ranking'];

        for (Survey_Settings__c eachRaking :faultRankings) {
            //String prodAndSurveyType = String.ValueOf(eachRaking.Product__c) + String.ValueOf(eachRaking.SurveyType__c);
            //String surveyType = String.ValueOf(eachRaking.SurveyType__c);
            String surveyTypeCountry = String.ValueOf(eachRaking.SurveyType__c) + String.ValueOf(eachRaking.Country__c);
            String surveyTypeCountryProduct = String.ValueOf(eachRaking.SurveyType__c) + String.ValueOf(eachRaking.Country__c) + eachRaking.Product__c;
            
            if(productIds.contains(eachRaking.Product__c)){
                //Karen Hung 12/14/18 added fault ranking mapping for those with product           
                if (faultRankingSurveyTypeCountryProductMap.containsKey(eachRaking.FaultRanking__c)){
                    faultRankingSurveyTypeCountryProductMap.get(eachRaking.FaultRanking__c).add(surveyTypeCountryProduct);     
                }else{
                    faultRankingSurveyTypeCountryProductMap.put(eachRaking.FaultRanking__c, new List <String> {surveyTypeCountryProduct});
                }
            }else{
                // fault mapping without product
                if (faultRankingSurveyTypeCountryMap.containsKey(eachRaking.FaultRanking__c)){
                    faultRankingSurveyTypeCountryMap.get(eachRaking.FaultRanking__c).add(surveyTypeCountry);     
                }else{
                    faultRankingSurveyTypeCountryMap.put(eachRaking.FaultRanking__c, new List <String> {surveyTypeCountry});
                }
            }
        }            
        
        Map<Decimal, List<Survey_Settings__c>> faultRankingScoreMap = new Map<Decimal,  List<Survey_Settings__c>>();
        
        List <Survey_Settings__c> scoreMatrix = [Select Id, NumberOfFalseResponses__c, Operator__c, Score__c, FaultRanking__c
                                                   From Survey_Settings__c 
                                                   Where Active__c = true 
                                                   And (FaultRanking__c IN :faultRankingSurveyTypeCountryMap.keySet() OR FaultRanking__c IN :faultRankingSurveyTypeCountryProductMap.keySet())
                                                   And SurveySetting__c = 'Score Matrix'];
        
        for (Survey_Settings__c eachScore :scoreMatrix) {
            //Get Survey Record
            if (faultRankingScoreMap.containsKey(eachScore.FaultRanking__c)){
                faultRankingScoreMap.get(eachScore.FaultRanking__c).add(eachScore);
            }else{
                faultRankingScoreMap.put(eachScore.FaultRanking__c, new List<Survey_Settings__c> {eachScore} );
            }
        }
        
        List <Survey__c> surveyToBeUpdated = new List <Survey__c>();
        Map<Id, Survey__c> surveyToBeUpdatedMap = new Map<Id, Survey__c>(); //Karen Hung KTS-2701 ALM 6933

        //Karen Hung for with product scenario
        for(Decimal eachFaultProdRank : faultRankingSurveyTypeCountryProductMap.keySet()){
            List<String> allProdAndSurvey;
            allProdAndSurvey =  faultRankingSurveyTypeCountryProductMap.get(eachFaultProdRank);           
            for (String eachSurveyType :allProdAndSurvey) {
                if (surveyTypeCountryProductSurveysMap.containsKey(eachSurveyType)) {
                    List<Survey__c> surveyList = surveyTypeCountryProductSurveysMap.get(eachSurveyType);

                    for(Survey__c currentSurvey :surveyList) {
                        Integer countFalse = surveyFalseCountMap.get(currentSurvey.id);
                        List<Survey_Settings__c> scoreMatrixFromMap = new List<Survey_Settings__c>();
                        if (faultRankingScoreMap.containsKey(eachFaultProdRank)) {
                            scoreMatrixFromMap =  faultRankingScoreMap.get(eachFaultProdRank);
                            
                            for (Survey_Settings__c eachScore :scoreMatrixFromMap) {
                                if (eachScore.Operator__c == 'Equals') {
                                    if (eachScore.NumberOfFalseResponses__c == countFalse){ 
                                        currentSurvey.Score__c = eachScore.Score__c;
                                        surveyToBeUpdated.add(currentSurvey); 
                                    }
                                }else {
                                    if (countFalse >= eachScore.NumberOfFalseResponses__c){ 
                                        currentSurvey.Score__c = eachScore.Score__c;
                                        surveyToBeUpdated.add(currentSurvey);
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }                          
        }
        


        //without product
        for (Decimal eachFaultRank :faultRankingSurveyTypeCountryMap.keySet()) {
            List<String> allProdAndSurvey;
            allProdAndSurvey =  faultRankingSurveyTypeCountryMap.get(eachFaultRank);           
            for (String eachSurveyType :allProdAndSurvey) {
                if (surveyTypeCountrySurveysMap.containsKey(eachSurveyType)) {
                    //Survey__c currentSurvey = ProductSurveyTypeSurveyMap.get(eachSurveyType);
                    List<Survey__c> surveyList = surveyTypeCountrySurveysMap.get(eachSurveyType);

                    for(Survey__c currentSurvey :surveyList) {
                        Integer countFalse = surveyFalseCountMap.get(currentSurvey.id);
                        List<Survey_Settings__c> scoreMatrixFromMap = new List<Survey_Settings__c>();
                        if (faultRankingScoreMap.containsKey(eachFaultRank)) {
                            scoreMatrixFromMap =  faultRankingScoreMap.get(eachFaultRank);
                            
                            for (Survey_Settings__c eachScore :scoreMatrixFromMap) {
                                if (eachScore.Operator__c == 'Equals') {
                                    if (eachScore.NumberOfFalseResponses__c == countFalse){ 
                                        currentSurvey.Score__c = eachScore.Score__c;
                                        surveyToBeUpdated.add(currentSurvey); 
                                    }
                                }
                                else {
                                    if (countFalse >= eachScore.NumberOfFalseResponses__c){ 
                                        currentSurvey.Score__c = eachScore.Score__c;
                                        surveyToBeUpdated.add(currentSurvey);
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }                           
        }
        
        surveyToBeUpdatedMap.putAll(surveyToBeUpdated); //Karen Hung KTS-2701 ALM 6933 put list in a map to avoid duplicates

        return surveyToBeUpdatedMap.values(); //Karen Hung KTS-2701 ALM 6933
    }
    
    private String ConvertToAPINameFormat (String strName) {
        String convertedString = '';
        convertedString = strName.Replace(' ', '_');
        return convertedString;
    }

    /**
    * @author        Paul Aguiling
    * @date          08.3.2018
    * @description   KTS-1981: Method that assures the survey interviewee lookup and interviewee email fields populated
    * @revision(s)
    */
    public void validateSurveyInterviewee(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('validateSurveyInterviewee', 'SurveyTriggerHandler');

        //Insert Scenario
        //if (oldMapItems == null) {
        //    for (Survey__c srvy: (List<Survey__c>) newList) {
        //        if ((Label.TS_SurveyType_MethodologyCheck.equals(srvy.SurveyType__c) 
        //            || Label.TS_SurveyType_TechnicalServiceCheck.equals(srvy.SurveyType__c) 
        //            || Label.TS_SurveyType_WalkAlongReport.equals(srvy.SurveyType__c)
        //            || Label.TS_SurveyType_CentralWarehouseCheck.equals(srvy.SurveyType__c)
        //            || Label.TS_SurveyType_CarStockCheck.equals(srvy.SurveyType__c)) 
        //            && (srvy.Interviewee__c == null || srvy.Interviewee_Email__c == null)) {

        //            //Display error when interview fields are empty
        //            srvy.addError(TS_Constants.ERRORMSG_SURVEYINT_03);                 
        //        }
        //    }
        ////Update Scenario
        //} else {

        //Update Scenario
        List<Id> survyIds = new List<Id>();
        Map<Id, String> survyMap = new Map<Id, String>();

        for (Survey__c srvy: (List<Survey__c>) newList) {
            Survey__c oldSurv = (Survey__c) oldMapItems.get(srvy.Id);
            
            //Check if survey will be submitted
            if (oldSurv.Status__c != srvy.Status__c
                && Label.TS_Status_Completed.equals(srvy.Status__c)) {
                //Check for child survey interviewee details when health and safety survey type is submitted
                if (Label.TS_SurveyType_HealthSafetyCustomerCheck.equals(srvy.SurveyType__c)) {
                    survyIds.add(srvy.Id);
                //Check for interviewee details for other survey type when submitted
                } else if (srvy.Interviewee__c == null || srvy.Interviewee_Email__c == null) {
                    srvy.addError(TS_Constants.ERRORMSG_SURVEYINT_01);
                }
            }
        }

        //Before submitting the Health & Safety Customer Check. We need to crosscheck if any related records 
        //have the interviewee lookup and the interviewee email fields populated for the following child survey types
        if (!survyIds.isEmpty()) {
            for (Survey__c srvy : [SELECT Id,  
                                   (SELECT Id, ParentSurvey__r.Interviewee__c, ParentSurvey__r.Interviewee_Email__c,
                                   Interviewee__c, Interviewee_Email__c, SurveyType__c FROM Surveys__r) 
                                   FROM Survey__c 
                                   WHERE Id IN :survyIds]) {
                for (Survey__c srveyChild : srvy.Surveys__r) {
                    if (Label.TS_SurveyType_NonCoffeeMachineCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_InstantsCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_FreshbrewCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_LiquidCoffeeCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_EspressoCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_DEKitchenCheck.equals(srveyChild.SurveyType__c)
                        || Label.TS_SurveyType_CustomerWarehouseCheck.equals(srveyChild.SurveyType__c)) {

                        Boolean isBreak = false; //Determine if inner loop should break

                        //Add error for empty interviewee and interviewee email
                        /* if (srveyChild.ParentSurvey__r.Interviewee__c == null 
                            || srveyChild.ParentSurvey__r.Interviewee_Email__c == null
                            || srveyChild.Interviewee__c == null
                            || srveyChild.Interviewee_Email__c == null) {
                            survyMap.put(srvy.Id, TS_Constants.ERRORMSG_SURVEYINT_01);
                            isBreak = true;
                        } */
                        if (srveyChild.Interviewee__c == null
                            || srveyChild.Interviewee_Email__c == null) {
                            survyMap.put(srvy.Id, TS_Constants.ERRORMSG_SURVEYINT_01);
                            isBreak = true;
                        }

                        //Proceed to next iteration of outer loop
                        if (isBreak) {
                            break;
                        }
                    }
                }
            }

            //Use the trigger.newList to able to use SObject.addError on the record
            for (Survey__c srvy: (List<Survey__c>) newList) {
                if (survyMap.get(srvy.Id) != null) {
                    srvy.addError(survyMap.get(srvy.Id));
                }
            }
        }

        CustomLogging.pop();
    }
}