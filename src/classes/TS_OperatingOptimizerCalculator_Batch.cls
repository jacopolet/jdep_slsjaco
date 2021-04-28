/**
* @author        Abram Vixen Reyes
* @date          Nov. 17, 2019
* @description   Batch class to calculate values in Operating Optimizer per Route
* @revision(s)
*/
global without sharing class TS_OperatingOptimizerCalculator_Batch implements Database.Batchable<Apttus_Config2__AccountLocation__c>, Database.Stateful {
    public List<Apttus_Config2__AccountLocation__c> aclocList = new List<Apttus_Config2__AccountLocation__c>();
      public Set<String> postCode_set = new Set<String>();    
      public Map<String, Map<Integer, Decimal>> accLoc_map = new Map<String, Map<Integer, Decimal>>();
      public Map<String, String> set_task_types_map = new Map<String, String>{'NL' => 'SAP_0111', 'DK' => 'SAP_0975', 'NO' => 'SAP_6864'};
      public Map<String, String> postal_district_map = new Map<String, String>(); 
      public List<String> unfinishedTeams = new List<String>(); 
      public Boolean isNordics = false;  
      public String thirdPartyResource;
      public String thirdPartyResourceName;
      public String filterType;            
      public String team_var;
      public String salesOrg;
        
      global class BucketizeWrapper{
          public Map<String, String> Buckets; //bucket number, x(y)        
          public Integer TTL;     
          public Integer STTL;     
          public Integer S15;     
          public Integer EOD_Cancel;
      }
      
      global TS_OperatingOptimizerCalculator_Batch(String team){
    
          //GET ALL POST CODES
          team_var = team;
          String subStr = team.substringAfter(' - ');
          salesOrg = set_task_types_map.get(team.substringBefore(' - '));
                          
          List<TS_Hierarchy_Derivation__mdt> get_postCodes = [SELECT Id, District__c, Postal_Code__c, District__r.Label FROM TS_Hierarchy_Derivation__mdt WHERE District__r.Label =: subStr];
          if(!get_postCodes.isEmpty()){
              for(TS_Hierarchy_Derivation__mdt var: get_postCodes){
                  String postStr = var.Postal_Code__c + '%';
                  postCode_set.add(postStr);                
                  postal_district_map.put(var.Postal_Code__c, var.District__r.Label);
              }
          }        
      }
  
      global System.Iterable<Apttus_Config2__AccountLocation__c> start(Database.BatchableContext BC) {                          
          if(thirdPartyResource != null && thirdPartyResource.length() > 5){                
              aclocList = [SELECT Id,Third_Party_Resource__r.Name FROM Apttus_Config2__AccountLocation__c WHERE Account_Location_Status__c = 'Valid' AND Id IN (SELECT Account_Location__c FROM Route__c) AND (Third_Party_Resource__r.Name =:thirdPartyResource OR Third_Party_Resource__r.RelatedUser__c =:thirdPartyResource)];                    
              if(!aclocList.isEmpty()){
                  thirdPartyResourceName = aclocList[0].Third_Party_Resource__r.Name;
              }                
          }
          else {                
              aclocList = [SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__PostalCode__c LIKE :postCode_set AND Account_Location_Status__c = 'Valid' AND Mini_Sales_Organization__c =: salesOrg AND Id IN (SELECT Account_Location__c FROM Route__c)];                                    
          }         
          return aclocList;                
      }
  
      global void execute(Database.BatchableContext BC, List<Apttus_Config2__AccountLocation__c> accLoc_List) {        
          if(!accLoc_List.isEmpty() && team_var != null && filterType != null){
              accLoc_map.putAll(TS_OperatingOptimizerCalculator_Execute.calculateMTTO(accLoc_List, team_var, isNordics, filterType));    
          }        
      }
  
      global void finish(Database.BatchableContext BC) {       
          CustomLogging.push('finish', 'TS_OperatingOptimizerCalculator_Batch');
  
          String nameVar;
          if(thirdPartyResourceName != null){
              nameVar = thirdPartyResourceName;
          }
          else {
              nameVar = team_var;
          }
          
          List<Last_Synchronization_OPG__c> opg_var_list = [SELECT Id FROM Last_Synchronization_OPG__c WHERE Name =: nameVar];
          Last_Synchronization_OPG__c opg_var_new = new Last_Synchronization_OPG__c();
          
          if(!opg_var_list.isEmpty()) {
              opg_var_new.Id = opg_var_list[0].Id;
          } else {
              opg_var_new.Name = nameVar;
          }
          
          opg_var_new.Last_Sync_Date__c = System.now();
          
          //GET JSON Small Large Cups MTTO        
          List<Route__c> routeList = new List<Route__c>();
          if(!aclocList.isEmpty()){
              routeList = [SELECT Account_Location__r.Third_Party_Resource__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, 
                           Cups__c, Large__c, Small__c, MTTO_All__c, MCO__c,
                           Cups_3rd_Party__c, Small_3rd_Party__c, MTTO_3rd_Party__c,
                           Cups_JDEOnly__c, Small_JDEOnly__c, Large_JDEOnly__c, MTTO_JDEOnly__c,
                           Cups_Bucketize_All_Actual__c,Small_Bucketize_All_Actual__c,Large_Bucketize_All_Actual__c,
                           Cups_Bucketize_JDEOnly_Actual__c,Small_Bucketize_JDEOnly_Actual__c,Large_Bucketize_JDEOnly_Actual__c,
                           Cups_Bucketize_3rdParty_Actual__c,Small_Bucketize_3rdParty_Actual__c
                           FROM Route__c 
                           WHERE Account_Location__c IN: aclocList];              
          }
                            
          Integer currentYear = System.Today().year();
          Integer nextYear = currentYear + 1;
          Map<String, BucketizeWrapper> initialActualsJSONMap = new Map<String,BucketizeWrapper>(); //ROUTEID+ROUTEFIELDNAME+MONTH, BUCKET           
          Map<String, Map<String, Map<String,BucketizeWrapper>>> districtActualsJSONMap = new Map<String, Map<String, Map<String,BucketizeWrapper>>>(); //DISTRICT/RESOURCE, (MTTO/SMALL/CUPS), MONTH, BUCKET                      
          Map<String, Map<String, Map<String,Object>>> resourceMTTOJSONMap  = new Map<String, Map<String, Map<String,Object>>>(); //RESOURCE, (MTTO/SMALL/CUPS), (DAY_1,DAY_2...), (MTTO/COUNT)    
          Map<String, Map<String, Map<String,Object>>> districtRouteJSONMap = new Map<String, Map<String, Map<String,Object>>>(); //DISTRICT, (MTTO/SMALL/CUPS), (DAY_1,DAY_2...), (MTTO/COUNT)   
          Set<String> monthSet = new Set<String>{'January '+currentYear, 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'January '+nextYear};                        
          Set<String> bucketSet = new Set<String>{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q'};                                        
          Set<String> routeFieldSet = new Set<String>();
          if(filterType == 'all'){            
              routeFieldSet = new Set<String>{'Large_Bucketize_All_Actual__c', 'Small_Bucketize_All_Actual__c', 'Cups_Bucketize_All_Actual__c', 'Large_Bucketize_JDEOnly_Actual__c', 'Small_Bucketize_JDEOnly_Actual__c', 'Cups_Bucketize_JDEOnly_Actual__c'};                           
          }
          else if(filterType == '3po'){             
              routeFieldSet = new Set<String>{'Small_Bucketize_3rdParty_Actual__c', 'Cups_Bucketize_3rdParty_Actual__c'};
          }
                 
          String defaultBucketizeJSON = '{"January '+nextYear+'":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"December":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"November":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"October":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"September":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"August":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"July":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"June":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"May":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"April":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"March":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"February":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}},"January '+currentYear+'":{"TTL":0,"STTL":0,"S15":0,"EOD_Cancel":0,"Buckets":{"Q":"0(0)","P":"0(0)","O":"0(0)","N":"0(0)","M":"0(0)","L":"0(0)","K":"0(0)","J":"0(0)","I":"0(0)","H":"0(0)","G":"0(0)","F":"0(0)","E":"0(0)","D":"0(0)","C":"0(0)","B":"0(0)","A":"0(0)"}}}';        
              
          if(!routeList.isEmpty() && filterType != null){
              for(Route__c r : routeList){               
                  for(String routeFieldName : routeFieldSet){
                      Map<String,Object> ActualsPlaceHolder = new Map<String, Object>();
                      if(routeFieldName == 'Large_Bucketize_All_Actual__c') ActualsPlaceHolder = r.Large_Bucketize_All_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large_Bucketize_All_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Small_Bucketize_All_Actual__c') ActualsPlaceHolder = r.Small_Bucketize_All_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_Bucketize_All_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Cups_Bucketize_All_Actual__c') ActualsPlaceHolder  = r.Cups_Bucketize_All_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_Bucketize_All_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Large_Bucketize_JDEOnly_Actual__c') ActualsPlaceHolder = r.Large_Bucketize_JDEOnly_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large_Bucketize_JDEOnly_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Small_Bucketize_JDEOnly_Actual__c') ActualsPlaceHolder = r.Small_Bucketize_JDEOnly_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_Bucketize_JDEOnly_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Cups_Bucketize_JDEOnly_Actual__c') ActualsPlaceHolder  = r.Cups_Bucketize_JDEOnly_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_Bucketize_JDEOnly_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);                   
                      else if(routeFieldName == 'Small_Bucketize_3rdParty_Actual__c') ActualsPlaceHolder = r.Small_Bucketize_3rdParty_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_Bucketize_3rdParty_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);
                      else if(routeFieldName == 'Cups_Bucketize_3rdParty_Actual__c') ActualsPlaceHolder  = r.Cups_Bucketize_3rdParty_Actual__c != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_Bucketize_3rdParty_Actual__c) : (Map<String, Object>)JSON.deserializeUntyped(defaultBucketizeJSON);                   
                                          
                      for(String monthName : monthSet){
                          if(ActualsPlaceHolder.containsKey(monthName)){
                              Map<String, Object> currentMonthMap  = (Map<String, Object>) ActualsPlaceHolder.get(monthName);
                              Map<String, Object> currentBucketizeWrapperMap = (Map<String, Object>) currentMonthMap;                                                                                
                              Map<String, String> bucketsMap = new Map<String, String>();
                              BucketizeWrapper bw = new BucketizeWrapper();
                              bw.EOD_Cancel = Integer.valueOf(currentMonthMap.get('EOD_Cancel'));
                              bw.TTL = Integer.valueOf(currentMonthMap.get('TTL'));
                              bw.STTL = Integer.valueOf(currentMonthMap.get('STTL'));
                              bw.S15 = Integer.valueOf(currentMonthMap.get('S15'));
                              
                              for(String bucketName : bucketSet){                                
                                  Map<String, Object> currentBucketMap = (Map<String, Object>) currentBucketizeWrapperMap.get('Buckets');                          	
                                  if(currentBucketMap.containsKey(bucketName)){
                                      String tempBucket = String.valueOf(currentBucketMap.get(bucketName));                        	
                                      bucketsMap.put(bucketName, tempBucket);    
                                  }     
                              }//END BUCKETS					                    
                              bw.Buckets = bucketsMap;
                              
                              //ADD TO INITIAL MAP TO BE REFERENCED ON LATER LOOP
                              String key = r.Id + '-' + routeFieldName + '-' + monthName;
                              initialActualsJSONMap.put(key, bw);
                          }                                                  
                      }//END MONTHS        
                  }//END ROUTE FIELD NAME
              }//END ROUTE
          }    
                                  
          if(!routeList.isEmpty() && filterType != null){   
              system.debug('ACL:' +aclocList);
              system.debug('RL:' +routeList);        
              system.debug('Filter:' +filterType);
              system.debug('Nordics:' +isNordics);
              for(Route__c r : routeList){                      
                  if(filterType == 'all'){                                
                           //FOR STANDARD S/C COUNT
                        if(r.Account_Location__r.Apttus_Config2__PostalCode__c != null && postal_district_map.get(r.Account_Location__r.Apttus_Config2__PostalCode__c.substringBefore(' ')) != null){                                    
                          String currentDistrict = postal_district_map.get(r.Account_Location__r.Apttus_Config2__PostalCode__c.substringBefore(' '));    
                          
                          if(!districtRouteJSONMap.isEmpty() && districtRouteJSONMap.containsKey(currentDistrict)){                             
                              //FOR NL
                              if(!isNordics){    
                                  //FOR ALL AND JDE ONLY                               
                                  if(r.Large__c != null && r.Small__c != null && r.Cups__c != null && r.MTTO_All__c != null &&
                                     r.Large_JDEOnly__c != null && r.Small_JDEOnly__c != null && r.Cups_JDEOnly__c != null && r.MTTO_JDEOnly__c != null){
                                      
                                      //PLACEHOLDER FOR OLD VALUES
                                      Map<String,Object> LargePlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(r.Large__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                            
                                      Map<String,Object> SmallPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(r.Small__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                
                                      Map<String,Object> CupsPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(r.Cups__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups__c) :  new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                
                                      Map<String,Object> MTTOPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_All__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_All__c) :  new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                                        
                                      Map<String,Object> LargeJDEPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(r.Large_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                            
                                      Map<String,Object> SmallJDEPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(r.Small_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                
                                      Map<String,Object> CupsJDEPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(r.Cups_JDEOnly__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_JDEOnly__c) :  new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                
                                      Map<String,Object> MTTOJDEPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_JDEOnly__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_JDEOnly__c) :  new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                                                                                            
                                                                                                                                                                                                                                                 
                                      //SUMMARIZE VALUES PER DISTRICT
                                      for(Integer i = 1; i<15; i++){                                        
                                          String day_api = 'day_'+i;        
                                          //ALL VALUES
                                          if(districtRouteJSONMap.get(currentDistrict).get('Large_All__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Large_All__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Large_All__c').get(day_api)) + Integer.valueOf(LargePlaceHolder.get(day_api)));
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('Small_All__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Small_All__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Small_All__c').get(day_api)) + Integer.valueOf(SmallPlaceHolder.get(day_api)));
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('Cups_All__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Cups_All__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Cups_All__c').get(day_api)) + Integer.valueOf(CupsPlaceHolder.get(day_api)));                        
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('MTTO_All__c') != null){
                                             districtRouteJSONMap.get(currentDistrict).get('MTTO_All__c').put(day_api,  (Decimal)districtRouteJSONMap.get(currentDistrict).get('MTTO_All__c').get(day_api) + (Decimal)MTTOPlaceHolder.get(day_api));                                                                                                                                                     
                                          }
                                          //JDE ONLY VALUES
                                          if(districtRouteJSONMap.get(currentDistrict).get('Large_JDEOnly__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Large_JDEOnly__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Large_JDEOnly__c').get(day_api)) + Integer.valueOf(LargeJDEPlaceHolder.get(day_api)));
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('Small_JDEOnly__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Small_JDEOnly__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Small_JDEOnly__c').get(day_api)) + Integer.valueOf(SmallJDEPlaceHolder.get(day_api)));
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('Cups_JDEOnly__c') != null){
                                              districtRouteJSONMap.get(currentDistrict).get('Cups_JDEOnly__c').put(day_api,  Integer.valueOf(districtRouteJSONMap.get(currentDistrict).get('Cups_JDEOnly__c').get(day_api)) + Integer.valueOf(CupsJDEPlaceHolder.get(day_api)));                        
                                          }
                                          if(districtRouteJSONMap.get(currentDistrict).get('MTTO_JDEOnly__c') != null){
                                             districtRouteJSONMap.get(currentDistrict).get('MTTO_JDEOnly__c').put(day_api,  (Decimal)districtRouteJSONMap.get(currentDistrict).get('MTTO_JDEOnly__c').get(day_api) + (Decimal)MTTOJDEPlaceHolder.get(day_api));                                                                                                                                                     
                                          }
                                      }                                       		
                                  }                                                                                                                                                                
                              }
                              //FOR NORDICS
                              else {                                                                
                                  if(r.MCO__c != null){
                                      //PLACEHOLDER FOR OLD VALUES                                    
                                      Map<String,Object> MCOPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(r.MCO__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MCO__c) :  new Map<String, Object>{'nordics_1' => 0.00, 'nordics_2' => 0.00, 'nordics_3' => 0.00, 'nordics_4' => 0.00, 'nordics_5' => 0.00, 'nordics_6' => 0.00, 'nordics_7' => 0.00, 'nordics_8' => 0.00, 'nordics_9' => 0.00, 'nordics_10' => 0.00, 'nordics_11' => 0.00, 'nordics_12' => 0.00};                                            
                          
                                      //SUMMARIZE VALUES PER DISTRICT
                                      for(Integer i = 1; i<13; i++){
                                          String day_api = 'nordics_'+i;                                                                                               
                                          districtRouteJSONMap.get(currentDistrict).get('MCO__c').put(day_api,  (Decimal)districtRouteJSONMap.get(currentDistrict).get('MCO__c').get(day_api) + (Decimal)MCOPlaceHolder.get(day_api));                         
                                      }                                        
                                  }
                              }
                          } 
                          else {                    
                              //INITIALIZE MAP PER DISCTIRCT                                                                                                         
                              //FOR NL
                              if(!isNordics){
                                  //FOR ALL AND JDE ONLY
                                  if(r.Large__c != null && r.Small__c != null && r.Cups__c != null && r.MTTO_All__c != null && 
                                     r.Large_JDEOnly__c != null && r.Small_JDEOnly__c != null && r.Cups_JDEOnly__c != null && r.MTTO_JDEOnly__c != null){
                                      Map<String,Map<String, Object>> initialMap = new Map<String,Map<String,Object>>{
                                          'Large_All__c' => (Map<String, Object>)JSON.deserializeUntyped(r.Large__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'Small_All__c' => (Map<String, Object>)JSON.deserializeUntyped(r.Small__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'Cups_All__c'  => (Map<String, Object>)JSON.deserializeUntyped(r.Cups__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'MTTO_All__c'  => (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_All__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_All__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},
                                          'Large_JDEOnly__c' => (Map<String, Object>)JSON.deserializeUntyped(r.Large_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Large_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'Small_JDEOnly__c' => (Map<String, Object>)JSON.deserializeUntyped(r.Small_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'Cups_JDEOnly__c'  => (Map<String, Object>)JSON.deserializeUntyped(r.Cups_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},                            
                                          'MTTO_JDEOnly__c'  => (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_JDEOnly__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_JDEOnly__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0}                                     
                                      };
                                      districtRouteJSONMap.put(currentDistrict,initialMap);                                                                               									
                                  }                                                            								
                              }
                              //FOR NORDICS
                              else {
                                  if(r.MCO__c != null){
                                      Map<String,Map<String, Object>> initialMap = new Map<String,Map<String,Object>>{
                                          'MCO__c' => (Map<String, Object>)JSON.deserializeUntyped(r.MCO__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MCO__c) : new Map<String, Object>{'nordics_1' => 0.00, 'nordics_2' => 0.00, 'nordics_3' => 0.00, 'nordics_4' => 0.00, 'nordics_5' => 0.00, 'nordics_6' => 0.00, 'nordics_7' => 0.00, 'nordics_8' => 0.00, 'nordics_9' => 0.00, 'nordics_10' => 0.00, 'nordics_11' => 0.00, 'nordics_12' => 0.00}                                            
                                      };
                                      districtRouteJSONMap.put(currentDistrict,initialMap); 
                                      
                                  }
                              }                                                        
                          }                                                 
                      }
                  }
                  
                  //FOR THIRD PARTY OPERATOR
                  else if(filterType == '3po'){
                      if(r.Account_Location__r.Third_Party_Resource__r.Name != null){                       
                          //SUMMARIZE VALUES PER ROUTE                    
                          if(!resourceMTTOJSONMap.isEmpty() && resourceMTTOJSONMap.containsKey(r.Account_Location__r.Third_Party_Resource__r.Name)){
                              if(r.MTTO_3rd_Party__c != null && r.Small_3rd_Party__c != null && r.Cups_3rd_Party__c != null){                                  
                                  //VALUES FROM NEW LOOP
                                  Map<String,Object> MTTOPlaceHolderNew  = (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_3rd_Party__c) != null  ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_3rd_Party__c)  : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                  Map<String,Object> SmallPlaceHolderNew = (Map<String, Object>)JSON.deserializeUntyped(r.Small_3rd_Party__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_3rd_Party__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                  Map<String,Object> CupsPlaceHolderNew  = (Map<String, Object>)JSON.deserializeUntyped(r.Cups_3rd_Party__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_3rd_Party__c)  : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                  //VALUES FROM PREVIOUS LOOP
                                  Map<String,Object> placeHolderOld = resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name) != null  ? resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};                                                                    
                                  for(Integer i = 1; i<15; i++){
                                      String apiName = 'day_'+i;                                                                
                                      //FOR 3PO S/C COUNT
                                      resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('Small_3rdParty__c').put(apiName, Integer.valueOf(resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('Small_3rdParty__c').get(apiName)) + Integer.valueOf(SmallPlaceHolderNew.get(apiName)));
                                      resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('Cups_3rdParty__c').put(apiName,  Integer.valueOf(resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('Cups_3rdParty__c').get(apiName))  + Integer.valueOf(CupsPlaceHolderNew.get(apiName)));                                                                                    
                                      //FOR 3PO MTTO
                                      resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('MTTO_3rdParty__c').put(apiName, (Decimal)resourceMTTOJSONMap.get(r.Account_Location__r.Third_Party_Resource__r.Name).get('MTTO_3rdParty__c').get(apiName)   + (Decimal)MTTOPlaceHolderNew.get(apiName));                                
                                  }                          
                              }                        
                          }
                          //INITIALIZE MAP PER ROUTE      
                          else {                                                  
                              if(r.MTTO_3rd_Party__c != null && r.Small_3rd_Party__c != null && r.Cups_3rd_Party__c != null){
                                  Map<String,Map<String, Object>> initialMap = new Map<String,Map<String,Object>>{
                                      'MTTO_3rdParty__c' =>  (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_3rd_Party__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.MTTO_3rd_Party__c)  : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},
                                      'Small_3rdParty__c' => (Map<String, Object>)JSON.deserializeUntyped(r.Small_3rd_Party__c) != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Small_3rd_Party__c) : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0},
                                      'Cups_3rdParty__c'  => (Map<String, Object>)JSON.deserializeUntyped(r.Cups_3rd_Party__c)  != null ? (Map<String, Object>)JSON.deserializeUntyped(r.Cups_3rd_Party__c)  : new Map<String, Object>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0}
                                  };
                                  //FOR 3PO S/C COUNT & MTTO
                                  resourceMTTOJSONMap.put(r.Account_Location__r.Third_Party_Resource__r.Name, initialMap);                                                              
                              }                            
                          }                                        
                        }
                  }
                  
                  String currentDistrict;
                  if(filterType == 'all'){
                      currentDistrict = postal_district_map.get(r.Account_Location__r.Apttus_Config2__PostalCode__c.substringBefore(' '));    
                  }
                  else if(filterType == '3po'){
                      currentDistrict = thirdPartyResourceName;
                  }
                  
                  //SUMMARIZE FOR BUCKETIZE ACTUALS                                             
                  if(!isNordics){							                            
                      //IF DISTRICT EXIST
                      if(districtActualsJSONMap.containsKey(currentDistrict)){                        
                          for(String routeFieldName : routeFieldSet){                            
                              //IF DISTRICT EXIST, IF TASK TYPE EXIST
                              if(districtActualsJSONMap.get(currentDistrict).containsKey(routeFieldName)){                                                                                
                                  for(String monthName : monthSet){                                               
                                      String key = r.Id + '-' + routeFieldName + '-' + monthName;	                                                                                
                                      ///IF DISTRICT EXIST, IF TASK TYPE EXIST, IF MONTH EXIST
                                      if(districtActualsJSONMap.get(currentDistrict).get(routeFieldName).containsKey(monthName)){                                                                                                                                                                                                                                                                                    
                                          for(String bucketName : bucketSet){                                                                                                                                                             
                                              ///IF DISTRICT EXIST, IF TASK TYPE EXIST, IF MONTH EXIST, IF BUCKET EXIST
                                              if(districtActualsJSONMap.get(currentDistrict).get(routeFieldName).get(monthName).Buckets.containsKey(bucketName)){                                                                                                
                                                  //GET SUM MONTH/BUCKET
                                                  BucketizeWrapper oldBW = new BucketizeWrapper();
                                                  oldBW = districtActualsJSONMap.get(currentDistrict).get(routeFieldName).get(monthName);
                                                                                                                                                  
                                                  //SUM MONTH ATTRIBUTES
                                                  Integer x_Old;
                                                  Integer y_Old;
                                                  List<String> xySplit_old = new List<String>();
                                                  if(oldBW.Buckets != null && oldBW.Buckets.containsKey(bucketName) && oldBW.Buckets.get(bucketName) != null){
                                                      xySplit_old = oldBW.Buckets.get(bucketName).split('\\(');      
                                                  }
                                                  else {
                                                      xySplit_old = '0(0)'.split('\\(');       
                                                  }                                                  
                                                  x_Old = Integer.valueOf(xySplit_Old[0]);
                                                  if(xySplit_Old.size() > 1){
                                                      y_Old = Integer.valueOf(xySplit_Old[1].remove(')'));        
                                                  }
                                                  else {
                                                      y_Old = 0;
                                                  }
                                                  
                                                  //GET NEW MONTH/BUCKET                                                       
                                                  BucketizeWrapper newBW = new BucketizeWrapper();                                                		
                                                  if(initialActualsJSONMap.containsKey(key)){
                                                      newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                                  }
                                                  else {
                                                      Map<String, String> newBuckets = new Map<String, String>();       
                                                      newBuckets.put(bucketName, '0(0)');
                                                      newBW.TTL = 0;
                                                      newBW.STTL = 0;
                                                      newBW.S15 = 0;
                                                      newBW.EOD_Cancel = 0;                                                    
                                                      newBW.Buckets = newBuckets;                                                    
                                                  }                                                                                                                
                                                  
                                                  //NEW MONTH ATTRIBUTES
                                                  Integer x_New;
                                                  Integer y_New;
                                                  
                                                  List<String> xySplit_New = new List<String>();                                                
                                                  if(newBW.Buckets != null && newBW.Buckets.containsKey(bucketName) && newBW.Buckets.get(bucketName) != null){
                                                      xySplit_New = newBW.Buckets.get(bucketName).split('\\(');      
                                                  }
                                                  else {
                                                      xySplit_New = '0(0)'.split('\\(');       
                                                  }                     
                                                  
                                                  x_New = Integer.valueOf(xySplit_New[0]);
                                                  if(xySplit_new.size() > 1){
                                                      y_New = Integer.valueOf(xySplit_new[1].remove(')'));        
                                                  }
                                                  else {
                                                      y_New = 0;
                                                  }
                                                  
                                                  //ADD THE PREVIOUS TO THE NEW
                                                  BucketizeWrapper combinedBW = new BucketizeWrapper();
                                                  combinedBW = oldBW;                                                
                                                  Integer x_Combined = x_New + x_Old; 
                                                  Integer y_Combined = y_New + y_Old;
                                                  String  xy_Combined = x_Combined+'('+ y_Combined +')';
                                                  combinedBW.Buckets.put(bucketName, xy_Combined);
                                                                                                  
                                                  //ADD MONTH LEVEL
                                                  Map<String, BucketizeWrapper> initialMonthMap = districtActualsJSONMap.get(currentDistrict).get(routeFieldName);
                                                  initialMonthMap.put(monthName, combinedBW);
                                                                                                                                                  
                                                  //ADD TASK TYPE LEVEL
                                                  Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = districtActualsJSONMap.get(currentDistrict);
                                                  initialTaskTypeMap.put(routeFieldName, initialMonthMap);
                                                                                                  
                                                  //ADD DISTRICT LEVEL
                                                  districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                                                                       
                                              }                                                                                                                                               
                                              //IF DISTRICT EXIST, IF TASK TYPE EXIST, IF MONTH EXIST, IF BUCKET IS NEW
                                              else {                                                
                                                  //ADD BUCKET                                                        
                                                  BucketizeWrapper newBW = new BucketizeWrapper();
                                                  if(initialActualsJSONMap.containsKey(key)){
                                                      newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                                  }
                                                  else {
                                                      Map<String, String> newBuckets = new Map<String, String>();       
                                                      newBuckets.put(bucketName, '0(0)');
                                                      newBW.TTL = 0;
                                                      newBW.STTL = 0;
                                                      newBW.S15 = 0;
                                                      newBW.EOD_Cancel = 0;
                                                      newBW.Buckets = newBuckets;                                                                                                                                                    
                                                  }
                                                  
                                                  //GET CURRENT BUCKET
                                                  BucketizeWrapper currentBW = districtActualsJSONMap.get(currentDistrict).get(routeFieldName).get(monthName);
                                                  currentBW.Buckets.put(bucketName, newBW.Buckets.get(bucketName));
                                                  
                                                  //ADD MONTH LEVEL
                                                  Map<String, BucketizeWrapper> initialMonthMap = districtActualsJSONMap.get(currentDistrict).get(routeFieldName);                                                
                                                  initialMonthMap.put(monthName, currentBW);                                                
                                                                                                  
                                                  //ADD TASK TYPE LEVEL
                                                  Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = districtActualsJSONMap.get(currentDistrict);                                                
                                                  initialTaskTypeMap.put(routeFieldName, initialMonthMap);
                                                  
                                                  //ADD DISTRICT LEVEL
                                                  districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                                                                                                                      
                                              }                                              
                                          }   
                                          
                                          //ADD TTL AND EOD_CANCEL                                                
                                          //GET SUM MONTH/BUCKET
                                          BucketizeWrapper oldBW = new BucketizeWrapper();
                                          oldBW = districtActualsJSONMap.get(currentDistrict).get(routeFieldName).get(monthName);
                                          
                                          BucketizeWrapper newBW = new BucketizeWrapper();
                                          newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                          if(initialActualsJSONMap.containsKey(key)){
                                              //ADD THE PREVIOUS TO THE NEW
                                              BucketizeWrapper combinedBW = new BucketizeWrapper();
                                              combinedBW = oldBW;
                                              combinedBW.TTL = newBW.TTL + oldBW.TTL;
                                              combinedBW.STTL = newBW.STTL + oldBW.STTL;
                                              combinedBW.S15 = newBW.S15 + oldBW.S15;
                                              combinedBW.EOD_Cancel = newBW.EOD_Cancel + oldBW.EOD_Cancel;
                                              combinedBW.Buckets = oldBW.Buckets;
                                              
                                              //ADD MONTH LEVEL
                                              Map<String, BucketizeWrapper> initialMonthMap = districtActualsJSONMap.get(currentDistrict).get(routeFieldName);
                                              initialMonthMap.put(monthName, combinedBW);
                                              
                                              //ADD TASK TYPE LEVEL
                                              Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = districtActualsJSONMap.get(currentDistrict);
                                              initialTaskTypeMap.put(routeFieldName, initialMonthMap);                                                                                        
                                              
                                              //ADD DISTRICT LEVEL
                                              districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                        
                                          }                                                
                                      }
                                      //IF DISTRICT EXIST, IF TASK TYPE EXIST, IF MONTH NEW
                                      else {                                        
                                          //INITIATE ALL BUCKETS
                                          for(String bucketName : bucketSet){                                                     
                                              //ADD BUCKET LEVEL
                                              BucketizeWrapper newBW = new BucketizeWrapper();
                                              if(initialActualsJSONMap.containsKey(key)){
                                                  newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                              }
                                              else {
                                                  Map<String, String> newBuckets = new Map<String, String>();       
                                                  newBuckets.put(bucketName, '0(0)');
                                                  newBW.TTL = 0;
                                                  newBW.STTL = 0;
                                                  newBW.S15 = 0;
                                                  newBW.EOD_Cancel = 0;
                                                  newBW.Buckets = newBuckets;                                                        
                                              }
                                              
                                              //ADD MONTH LEVEL
                                              Map<String, BucketizeWrapper> initialMonthMap = new Map<String, BucketizeWrapper>();
                                              initialMonthMap.put(monthName, newBW);
                                              
                                              //ADD TASK TYPE LEVEL
                                              Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = new Map<String, Map<String, BucketizeWrapper>>();
                                              initialTaskTypeMap.put(routeFieldName, initialMonthMap);
                                              
                                              //ADD DISTRICT LEVEL
                                              districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                                                                                                                                                                                                           
                                          }                                                
                                      }                                                                                            
                                  }//END LOOP MONTH
                              }
                              //IF DISTRICT EXIST, IF TASK TYPE NEW
                              else {                                
                                  for(String monthName : monthSet){ 
                                      String key = r.Id + '-' + routeFieldName + '-' + monthName;	                                       
                                      //INITIATE ALL BUCKETS
                                      for(String bucketName : bucketSet){                                                     
                                          //ADD BUCKET LEVEL
                                          BucketizeWrapper newBW = new BucketizeWrapper();
                                          if(initialActualsJSONMap.containsKey(key)){
                                              newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                          }
                                          else {
                                              Map<String, String> newBuckets = new Map<String, String>();       
                                              newBuckets.put(bucketName, '0(0)');
                                              newBW.TTL = 0;
                                              newBW.STTL = 0;
                                              newBW.S15 = 0;
                                              newBW.EOD_Cancel = 0;
                                              newBW.Buckets = newBuckets;                                                        
                                          }
                                          
                                          //ADD MONTH LEVEL
                                          Map<String, BucketizeWrapper> initialMonthMap = new Map<String, BucketizeWrapper>();
                                          initialMonthMap.put(monthName, newBW);
                                          
                                          //ADD TASK TYPE LEVEL
                                          Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = new Map<String, Map<String, BucketizeWrapper>>();
                                          initialTaskTypeMap.put(routeFieldName, initialMonthMap);
                                          
                                          //ADD DISTRICT LEVEL
                                          districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                                                                                                                         
                                      }
                                  }//END LOOP MONTH
                              }                                                                                    
                          }//END LOOP TASK TYPE                                                                                   
                      }   
                      //IF DISTRICT NEW
                      else {                        
                          for(String routeFieldName : routeFieldSet){                                               
                              for(String monthName : monthSet){ 
                                  String key = r.Id + '-' + routeFieldName + '-' + monthName;	                                                   
                                  //INITIATE ALL BUCKETS
                                  for(String bucketName : bucketSet){                                                     
                                      //ADD BUCKET LEVEL
                                      BucketizeWrapper newBW = new BucketizeWrapper();
                                      if(initialActualsJSONMap.containsKey(key)){
                                          newBW = (BucketizeWrapper) initialActualsJSONMap.get(key);
                                      }
                                      else {                                                                                                                      
                                          Map<String, String> newBuckets = new Map<String, String>();       
                                          newBuckets.put(bucketName, '0(0)');
                                          newBW.TTL = 0;
                                          newBW.STTL = 0;
                                          newBW.S15 = 0;
                                          newBW.EOD_Cancel = 0;
                                          newBW.Buckets = newBuckets;                                                        
                                      }                                    
                                      
                                      //ADD MONTH LEVEL
                                      Map<String, BucketizeWrapper> initialMonthMap = new Map<String, BucketizeWrapper>();
                                      
                                      //IF MONTHS HAVE BEEN SET FOR THIS DISTRICT + ROUTE INCLUDE THAT IN CURRENT RUN
                                      if(!districtActualsJSONMap.isEmpty() &&
                                         districtActualsJSONMap.containsKey(currentDistrict) && 
                                         districtActualsJSONMap.get(currentDistrict).containsKey(routeFieldName)){
                                             initialMonthMap = districtActualsJSONMap.get(currentDistrict).get(routeFieldName);                                           
                                         }                                    
                                      initialMonthMap.put(monthName, newBW);
                                      
                                      //ADD TASK TYPE LEVEL                                                       
                                      Map<String, Map<String, BucketizeWrapper>> initialTaskTypeMap = new Map<String, Map<String, BucketizeWrapper>>();
                                      //IF TASK TYPE HAVE BEEN SET FOR THIS DISTRICT + ROUTE INCLUDE THAT IN CURRENT RUN
                                      if(!districtActualsJSONMap.isEmpty() &&
                                         districtActualsJSONMap.containsKey(currentDistrict)){
                                             initialTaskTypeMap = districtActualsJSONMap.get(currentDistrict);                                           
                                         }
                                      initialTaskTypeMap.put(routeFieldName, initialMonthMap);
                                      
                                      //ADD DISTRICT LEVEL
                                      districtActualsJSONMap.put(currentDistrict, initialTaskTypeMap);//DISTRICT, (MTTO/SMALL/CUPS), MONTH, BUCKET                                                                                                                                                         
                                  }
                              }                               
                          }                                    			
                      }                                                            
                  }
              }//END ROUTE LOOP      
              
              system.debug('Initialized Route:' +JSON.serialize(initialActualsJSONMap));
              system.debug('Finalized Route:' +JSON.serialize(districtActualsJSONMap));
                          
              //STAMP TO LAST SYNCHRONIZATION OPG OBJECT
              if(filterType == 'all'){            
                  if(districtRouteJSONMap.get(team_var.substringAfter('- ')) != null){
                      //FOR ALL S/C COUNT
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Large_All__c') != null){                    
                          opg_var_new.put('Large_All__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Large_All__c')));
                      }
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Cups_All__c') != null){                    
                          opg_var_new.put('Cups_All__c' ,JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Cups_All__c')));
                      }
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Small_All__c') != null){                    
                          opg_var_new.put('Small_All__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Small_All__c')));
                      }
                      //FOR JDE S/C COUNT
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Large_JDEOnly__c') != null){                    
                          opg_var_new.put('Large_JDEOnly__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Large_JDEOnly__c')));
                      }
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Cups_JDEOnly__c') != null){                    
                          opg_var_new.put('Cups_JDEOnly__c' ,JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Cups_JDEOnly__c')));
                      }
                      if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Small_JDEOnly__c') != null){                    
                          opg_var_new.put('Small_JDEOnly__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('Small_JDEOnly__c')));
                      }
                      
                      if(!isNordics){
                          //FOR ALL MTTO
                          if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MTTO_All__c') != null){
                              opg_var_new.put('MTTO_All__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MTTO_All__c')));
                            }                    
                          if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MTTO_JDEOnly__c') != null){
                              opg_var_new.put('MTTO_JDEOnly__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MTTO_JDEOnly__c')));
                            }                    
                                                                          
                          //FOR ACTUALS                                                
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Cups_Bucketize_All_Actual__c') != null){
                              opg_var_new.put('Cups_Bucketize_All_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Cups_Bucketize_All_Actual__c')));
                            }                    
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Large_Bucketize_All_Actual__c') != null){
                              opg_var_new.put('Large_Bucketize_All_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Large_Bucketize_All_Actual__c')));
                            }  
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Small_Bucketize_All_Actual__c') != null){
                              opg_var_new.put('Small_Bucketize_All_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Small_Bucketize_All_Actual__c')));
                            }  
                          
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Cups_Bucketize_JDEOnly_Actual__c') != null){
                              opg_var_new.put('Cups_Bucketize_JDEOnly_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Cups_Bucketize_JDEOnly_Actual__c')));
                            }                    
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Large_Bucketize_JDEOnly_Actual__c') != null){
                              opg_var_new.put('Large_Bucketize_JDEOnly_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Large_Bucketize_JDEOnly_Actual__c')));
                            }  
                          if(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Small_Bucketize_JDEOnly_Actual__c') != null){
                              opg_var_new.put('Small_Bucketize_JDEOnly_Actual__c',JSON.serialize(districtActualsJSONMap.get(team_var.substringAfter('- ')).get('Small_Bucketize_JDEOnly_Actual__c')));
                            }  
                                                  
                      }                                                                                
                      //FOR ALL MCO
                      else {
                          if(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MCO__c') != null){
                              opg_var_new.put('MCO__c',JSON.serialize(districtRouteJSONMap.get(team_var.substringAfter('- ')).get('MCO__c')));                    
                          }         
                      }                  
                  }
              }
  
              else if(filterType == '3po'){                      
                  if(resourceMTTOJSONMap.get(thirdPartyResourceName)!= null){
                      //FOR 3PO S/C COUNT     
                      if(resourceMTTOJSONMap.get(thirdPartyResourceName).get('Cups_3rdParty__c') != null){
                          opg_var_new.put('Cups_3rdParty__c',  JSON.serialize(resourceMTTOJSONMap.get(thirdPartyResourceName).get('Cups_3rdParty__c')));    
                      }
                      if(resourceMTTOJSONMap.get(thirdPartyResourceName).get('Small_3rdParty__c') != null){
                          opg_var_new.put('Small_3rdParty__c', JSON.serialize(resourceMTTOJSONMap.get(thirdPartyResourceName).get('Small_3rdParty__c')));                 
                      }                            
                      //FOR 3PO MTTO
                      if(resourceMTTOJSONMap.get(thirdPartyResourceName).get('MTTO_3rdParty__c') != null){
                          opg_var_new.put('MTTO_3rdParty__c',  JSON.serialize(resourceMTTOJSONMap.get(thirdPartyResourceName).get('MTTO_3rdParty__c')));    
                      }    
                      
                      //FOR ACTUALS                                                
                      if(districtActualsJSONMap.get(thirdPartyResourceName).get('Cups_Bucketize_3rdParty_Actual__c') != null){
                          opg_var_new.put('Cups_Bucketize_3rdParty_Actual__c',JSON.serialize(districtActualsJSONMap.get(thirdPartyResourceName).get('Cups_Bucketize_3rdParty_Actual__c')));
                      }                    
                      
                      if(districtActualsJSONMap.get(thirdPartyResourceName).get('Small_Bucketize_3rdParty_Actual__c') != null){
                          opg_var_new.put('Small_Bucketize_3rdParty_Actual__c',JSON.serialize(districtActualsJSONMap.get(thirdPartyResourceName).get('Small_Bucketize_3rdParty_Actual__c')));
                      }  
                  }
              }                                                                             
              try {                       
                  upsert opg_var_new;  
                  
                  if(!unfinishedTeams.isEmpty()){   
                      Database.executeBatch(new TS_OperatingOptimizerCalculator_Batch(unfinishedTeams[0]));
                  }
              }
              catch(Exception ex) {
                  CustomLogging.debugException(ex);
                  CustomLogging.pop();
                  System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
              }          
         } 
          
          String newTeam = null;         
          if(!unfinishedTeams.isEmpty()){           
              if(unfinishedTeams[0] != null){
                  newTeam = unfinishedTeams[0];            
              }
              unfinishedTeams.remove(0);               
          }
          
          system.debug('Processed: ' + nameVar);
          system.debug('To process: ' + newTeam);
          system.debug('Remaining: ' + JSON.serialize(unfinishedTeams));
                                                   
          try {                 
              
              if(newTeam != null && filterType != null){           
                  TS_OperatingOptimizerCalculator_Batch batchCalculator_var = new TS_OperatingOptimizerCalculator_Batch(newTeam);
                  batchCalculator_var.isNordics = isNordics;
                  batchCalculator_var.thirdPartyResource = thirdPartyResource;
                  batchCalculator_var.filterType = filterType;
                  batchCalculator_var.unfinishedTeams = unfinishedTeams;
                  Database.executeBatch(batchCalculator_var, 100);
              }
          }
          catch(Exception ex) {
              CustomLogging.debugException(ex);
              CustomLogging.pop();
              System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
          }         
      }    
  }