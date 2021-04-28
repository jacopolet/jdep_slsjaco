/**
* @author        Rey Austral
* @date          24.3.2017           
* @description   Class responsible for generic method related to TS components
* @revision(s)   6.29.2017 Paul Aguiling - Added getWorkingDate and getBusinessHours methods
*                12.04.2017 Paul Aguiling - Added getRecordTypeNameById()
*                06.29.2017 Paul Aguiling - [KTS-1775]: Added resendTaskIntegLog()
*/
public without sharing class TS_UtilityClass {
    
     public static Integration_Log__c populateIntLogValues(String objectName, Id objectId, Id orderId, Id accountId){
        
        Integration_Log__c intLog = new Integration_Log__c();
        intLog.Object__c = objectName;
        intLog.Object_Id__c = objectId;
        intLog.Order__c = orderId;
        intLog.Account__c = accountId;
        intLog.Integration_Status__c = INT_Constants.PAUSED;
        
        return intLog;
                
    }
    
    /**
    * @author        Kimiko Roberto
    * @date          4.12.2017           
    * @description   This method will return the record type id by Name
    * @revision(s)
    */
    public static Id getRecordTypeIdByName(String objApiName, String rtName) {
        CustomLogging.push('getRecordTypeByName', 'TS_UtilityClass');
        Id recordTypeId = Schema.getGlobalDescribe().get(objApiName).getDescribe().getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        CustomLogging.pop();
        return recordTypeId;      
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          12.04.2017           
    * @description   This method will return the record type name using id
    * @revision(s)
    */
    public static String getRecordTypeNameById(String objApiName, Id rtId) {
        CustomLogging.push('getRecordTypeNameById', 'TS_UtilityClass');
        String recordTypeName = Schema.getGlobalDescribe().get(objApiName).getDescribe().getRecordTypeInfosById().get(rtId).getName();
        CustomLogging.pop();
        return recordTypeName;      
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          6.29.2017           
    * @description   This method will return the working date based on business hours
    * @revision(s)
    */
    public static Date getWorkingDate(Id businessHoursId, Date oldDate) {
        CustomLogging.push('getWorkingDate', 'TS_UtilityClass');
        Date newDate = oldDate;

        //Check if date is holiday or weekend
        if (!BusinessHours.isWithin(businessHoursId, oldDate)) {

            //Check for days falling on weekends in 24/7 business hours 
            if (Label.TS_SLA_Saturday.equals(getReadableDay(oldDate))) {
                oldDate = oldDate.addDays(2);
            } else if (Label.TS_SLA_Sunday.equals(getReadableDay(oldDate))) {
                oldDate = oldDate.addDays(1);
            }

            //Get the next working date
            newDate = BusinessHours.nextStartDate(businessHoursId, oldDate).date();
        }

        CustomLogging.pop();
        return newDate;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          6.29.2017           
    * @description   This method will return the list of business hours based on Sales Organization
    * @revision(s)
    */
    public static Map<String, Id> getBusinessHours(List<String> salesOrg) {
        CustomLogging.push('getBusinessHours', 'TS_UtilityClass');
        Map<String, Id> resultMap = new Map<String, Id>();
        Set<String> checkName = new Set<String>();

        //Iterate list of business hours
        for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours
                                 WHERE Name IN :salesOrg]) {

            //Check for unique names and add to resultMap
            if (checkName.add(bh.Name)) {
                resultMap.put(bh.Name, bh.Id);
            }
        }

        CustomLogging.pop();
        return resultMap;
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          6.29.2017           
    * @description   This method will return the day
    * @revision(s)
    */
    public static String getReadableDay(Date d) {
        CustomLogging.push('getReadableDay', 'TS_UtilityClass');
        Datetime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        CustomLogging.pop();

        //returns day in String
        return dt.format('EEEE'); 
    } 

    /**
    * @author        Rey Austral
    * @date          9.8.2017           
    * @description   This method will create a file and insert to an object
    * @revision(s)
    */
    public static ContentVersion convertToFile(Blob physicalFile, String fileName, String fileTitle) {
        CustomLogging.push('getReadableDay', 'TS_UtilityClass');
       
        ContentVersion fileConvert = new ContentVersion();
        fileConvert.VersionData = physicalFile;
        fileConvert.Title = fileTitle;
        fileConvert.PathOnClient = fileName;
        fileConvert.ContentLocation = 'S';
        return fileConvert; 
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          02.27.2018          
    * @description   [KTS-1501]: Method used for retrieving time based on business hours specifically
    *                            for contract triggered cases (Preventive maintenance and WTS). Used in
    *                            WaterFilterChangeConTriggerBatch and PrevMaintenanceConTriggerBatch class
    * @revision(s)
    */
    public static Time getBusinessHoursLatestTime(CountrySetting__c cSet, Date dte) {
        CustomLogging.push('getBusinessHoursLatestTime', 'PrevMaintenanceConTriggerBatch');

        //Set default time via date today
        Datetime myDateTime = datetime.now();
        Time newTime =  myDateTime.timeGmt();

        //Check country setting if it has result
        if (cSet != null) {
            if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.MondayEndTime.addSeconds(-1);
            } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.TuesdayEndTime.addSeconds(-1);
            } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.WednesdayEndTime.addSeconds(-1);
            } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.ThursdayEndTime.addSeconds(-1);
            } else if (Label.TS_SLA_Friday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.FridayEndTime.addSeconds(-1);
            } else if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.SaturdayEndTime != null ? cSet.Business_Hours__r.SaturdayEndTime.addSeconds(-1) : newTime;
            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(dte))) {
                newTime = cSet.Business_Hours__r.SundayEndTime != null? cSet.Business_Hours__r.SundayEndTime.addSeconds(-1) : newTime;
            }
        }

        CustomLogging.pop();
        return newTime;
    }

     /**
    * @author        Archi Delphinanto
    * @date          2 May 2017          
    * @description   To define if an SFDC object is accessible by the current APEX user
    * @usage         1) TS_UtilityClass.isSObjectAccessible(new String[] {'Case',  'Workorderlineitem'}) which returns TRUE if user has permit to access for all of the objects 
    *                2) TS_UtilityClass.isSObjectAccessible(new String[] {'Case', 'WorkOrder'}) which returns False if user has no permit to access on one or more  of the objects
    *                3) TS_UtilityClass.isSObjectAccessible(new String[] {'Case2', 'WorkOrder'}) which returns False if one or more  of the objects do not exist
    * @revision(s)
    */
    public static Boolean isSObjectAccessible(List<String> sobjectnameList) {
        CustomLogging.push('isSObjectAccessible', 'TS_UtilityClass');
        boolean isaccessible = false;

        try{
            for (String sobjectname: sobjectnameList){
                isaccessible = Schema.getGlobalDescribe().get(sobjectname).getDescribe().isAccessible() ;
                if (!isaccessible) {
                    return false;
                }
            }

       } catch(Exception ex) {
            isaccessible = false;
            CustomLogging.debugException(ex);
            //CustomLogging.pop();
        }        
        CustomLogging.pop();
        return isaccessible;        
    }

    /**
    * @author        Archi Delphinanto
    * @date          2 May 2017          
    * @description   To define if an SFDC object is queryable by the current APEX user
    * @usage         1) TS_UtilityClass.isSObjectQueryable(new String[] {'Case',  'Workorderlineitem'}) which returns TRUE if user has permit to query for all of the objects 
    *                2) TS_UtilityClass.isSObjectQueryable(new String[] {'Case', 'WorkOrder'}) which returns False if user has no permit to query on one or more  of the objects
    *                3) TS_UtilityClass.isSObjectQueryable(new String[] {'Case2', 'WorkOrder'}) which returns False if one or more  of the objects do not exist
    * @revision(s)
    */
    public static Boolean isSObjectQueryable(List<String> sobjectnameList) {
        CustomLogging.push('isSObjectQueryable', 'TS_UtilityClass');
        boolean isQueryable = false;

        try{
            for (String sobjectname: sobjectnameList){
                isQueryable = Schema.getGlobalDescribe().get(sobjectname).getDescribe().isQueryable() ;
                if (!isQueryable) {
                    return false;
                }
            }

       } catch(Exception ex) {
            isQueryable = false;
            CustomLogging.debugException(ex);
           //CustomLogging.pop();
        }        
        CustomLogging.pop();
        return isQueryable;        
    }

    /**
    * @author        Archi Delphinanto
    * @date          2 May 2017          
    * @description   To define if an SFDC object is createable by the current APEX user
    * @usage         1) TS_UtilityClass.isSObjectCreateable(new String[] {'Case',  'Workorderlineitem'}) which returns TRUE if user has permit to create for all of the objects 
    *                2) TS_UtilityClass.isSObjectCreateable(new String[] {'Case', 'WorkOrder'}) which returns False if user has no permit to create on one or more  of the objects
    *                3) TS_UtilityClass.isSObjectCreateable(new String[] {'Case2', 'WorkOrder'}) which returns False if one or more  of the objects do not exist
    * @revision(s)
    */
    public static Boolean isSObjectCreateable(List<String> sobjectnameList) {
        CustomLogging.push('isSObjectCreateable', 'TS_UtilityClass');
        boolean isCreateable = false;

        try{
            for (String sobjectname: sobjectnameList){
                isCreateable = Schema.getGlobalDescribe().get(sobjectname).getDescribe().isCreateable() ;
                if (!isCreateable) {
                    return false;
                }
            }

       } catch(Exception ex) {
            isCreateable = false;
            CustomLogging.debugException(ex);
            //CustomLogging.pop();
        }        
        CustomLogging.pop();
        return isCreateable;        
    }
    
    /**
    * @author        Adrian Reyes
    * @date          3 May 2017          
    * @description   To define if an SFDC object is updateable by the current APEX user
    * @usage         1) TS_UtilityClass.isSObjectUpdateable(new String[] {'Case',  'Workorderlineitem'}) which returns TRUE if user has permit to update for all of the objects 
    *                2) TS_UtilityClass.isSObjectUpdateable(new String[] {'Case', 'WorkOrder'}) which returns False if user has no permit to update on one or more  of the objects
    *                3) TS_UtilityClass.isSObjectUpdateable(new String[] {'Case2', 'WorkOrder'}) which returns False if one or more  of the objects do not exist
    * @revision(s)
    */
    public static Boolean isSObjectUpdateable(List<String> sobjectnameList) {
        CustomLogging.push('isSObjectUpdateable', 'TS_UtilityClass');
        boolean isUpdateable = false;

        try{
            for (String sobjectname: sobjectnameList){
                isUpdateable = Schema.getGlobalDescribe().get(sobjectname).getDescribe().isUpdateable() ;
                if (!isUpdateable) {
                    return false;
                }
            }

       } catch(Exception ex) {
            isUpdateable = false;
            CustomLogging.debugException(ex);
            //CustomLogging.pop();
        }        
        CustomLogging.pop();
        return isUpdateable;        
    }
    
    /**
    * @author        Adrian Reyes
    * @date          3 May 2017          
    * @description   To define if an SFDC object is deletable by the current APEX user
    * @usage         1) TS_UtilityClass.isSObjectDeletable(new String[] {'Case',  'Workorderlineitem'}) which returns TRUE if user has permit to delete for all of the objects 
    *                2) TS_UtilityClass.isSObjectDeletable(new String[] {'Case', 'WorkOrder'}) which returns False if user has no permit to delete on one or more  of the objects
    *                3) TS_UtilityClass.isSObjectDeletable(new String[] {'Case2', 'WorkOrder'}) which returns False if one or more  of the objects do not exist
    * @revision(s)
    */
    public static Boolean isSObjectDeletable(List<String> sobjectnameList) {
        CustomLogging.push('isSObjectDeletable', 'TS_UtilityClass');
        boolean isDeletable = false;

        try{
            for (String sobjectname: sobjectnameList){
                isDeletable = Schema.getGlobalDescribe().get(sobjectname).getDescribe().isDeletable() ;
                if (!isDeletable) {
                    return false;
                }
            }

       } catch(Exception ex) {
            isDeletable = false;
            CustomLogging.debugException(ex);
            //CustomLogging.pop();
        }        
        CustomLogging.pop();
        return isDeletable;        
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          06.29.2018          
    * @description   [KTS-1775]: Method responsible to Initiate updates from related objects 
    * @revision(s)
    */
    public static void resendTaskIntegLog(String objectAPIName, String relatedAPIFieldName, List<SObject> newObjectList, Map<Id, SObject> oldObjectMap) {
        CustomLogging.push('resendTaskIntegLog', 'TS_UtilityClass');
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap();
        List<WorkOrderLineItem> woliToUpdate = new List<WorkOrderLineItem>();
        Map<Id,List<WorkOrderLineItem>> woliMap = new Map<Id, List<WorkOrderLineItem>>(); //ID of Selected Object => Woli Record
        List<String> listofIds = new List<String>();

        //Collect list of id from the related object
        for (SObject newObj: (List<SObject>) newObjectList) {
            listofIds.add('\'' + (String) newObj.get('Id') + '\'');
        }
 
        //Dynamically query the task from the related object using the relatedAPIFieldName (ex. accountlocation__c)
        String query = 'SELECT Id, PerformIntegrationLog__c, ' + relatedAPIFieldName 
                    + ' FROM WorkOrderLineItem ' 
                    + ' WHERE (STATUS != \'Completed\' OR STATUS = \'Canceled\') '
                    + ' AND WorkOrderType__c IN (\'S10\') '
                    + ' AND WorkOrderLineItemType__c = \'Task\' ' 
                    + ' AND ' + relatedAPIFieldName + ' IN ' + listofIds;

        System.debug('### query #### ' + query);
        List<SObject> woliList = Database.query(query);
        System.debug('### woliList #### ' + woliList);

        //Check if the list is not empty
        if (woliList != null && !woliList.isEmpty()) {

            //Iterate result query then map the related object Id as key and work order line record as value
            for (SObject woliObj: (List<SObject>) woliList) {
                Id objId = (String) woliObj.get(relatedAPIFieldName);
                WorkOrderLineItem woliRec = (WorkOrderLineItem) woliObj;

                if (woliMap.containsKey(objId)) {
                    woliMap.get(objId).add(woliRec);
                } else {
                    woliMap.put(objId, new List<Workorderlineitem>{woliRec});
                }
            }

            //Iterate list of child related records
            for (SObject newObj: (List<SObject>) newObjectList) {
                SObject oldObj = oldObjectMap.get((String) newObj.get('Id'));

                //Iterate list of custom/standard fields related to the child object
                for(Schema.SObjectField sfield : fieldMap.Values()) {
                    Schema.DescribeFieldResult  dfield = sfield.getDescribe();

                    //Check fields that are only updateable. This will avoid the system fields
                    if (dfield.isUpdateable() && newObj.get(dfield.getName()) != oldObj.get(dfield.getName())) {                    
                        //Stamp the field + updated value to parent task field to retrigger the integration log creation
                        String newResultValue = newObj.get(dfield.getName()) != null? String.valueOf(newObj.get(dfield.getName())) : '';
                        
                        //Collect tasks to be updated when theres update to related objects
                        for (WorkOrderLineItem woli: (List<WorkOrderLineItem>) woliMap.get((String) newObj.get('Id'))) {
                            WorkOrderLineItem newWoli = new WorkOrderLineItem();
                            newWoli.Id = woli.Id;
                            newWoli.PerformIntegrationLog__c = dfield.getName() + newResultValue;
                            woliToUpdate.add(newWoli);
                        }

                        break;
                    }
                }
            }

            System.debug('### woliToUpdate #### ' + woliToUpdate);
            //Update parent task of child related objects
            if (!woliToUpdate.isEmpty() && Schema.sObjectType.Workorderlineitem.isUpdateable()) {
                update woliToUpdate;
            }
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          1 Oct 2018
    * @description   Return: Map of SAP Country Codes and Service Planning Queue
    * @revision(s)
    */
    public static Map<String, String> countrySAPCodeUtility() {
        return new Map<String, String>{'SAP_0333' => 'BE Service Planning',
                                        'SAP_0975' => 'DK Service Planning',
                                        'SAP_6864' => 'NO Service Planning',
                                        'SAP_0976' => 'SE Service Planning',
                                        'SAP_0111' => 'NL Service Planning',
                                        'SAP_0080' => 'ES Service Planning',
                                        'SAP_6712' => 'DE Service Planning',
                                        'SAP_6750' => 'UK Service Planning'
                                        };     
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          1 Oct 2018
    * @description   Return: Map of Service Planning Queues
    * @revision(s)
    */
    public static Map<String, String> queueNameIdMapUtility() {

        Map<String, String> queueNameIdMap = new  Map<String, String>();

        try{
            List<Group> servicePlanningQueues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name LIKE '%Service Planning'];
            if(!servicePlanningQueues.isEmpty()){
                for(Group gr : servicePlanningQueues){
                    queueNameIdMap.put(gr.Name, gr.Id);
                }
            }
        } catch(Exception e){
            System.debug(e);
        }
        
        return queueNameIdMap;     
    }
    
    /******************************************************************************
	* Karen Hung DOO-5268
	* 9.3.2021  to return pricebookentry map (Product+SalesOrg => PricebokEntry) 
	******************************************************************************/
    public static Map <String, PricebookEntry> createPriceBookEntryMap(List<OperatingSchedule__c> osl) {
        CustomLogging.push('createPriceBookEntryMap', 'TS_UtilityClass');
        Map<String, PricebookEntry> prMap = new Map <String, PricebookEntry> ();
		
        try{
            Set<ID> productSet = new set<ID> ();
            Set<String> salesOrganizationSet = new Set<String> ();
            for (OperatingSchedule__c os: osl) {
                productSet.add(os.PhysicalAsset__r.Product__c);
                salesOrganizationSet.add(os.PhysicalAsset__r.SalesOrganization__c);
            }

        	//GET PRICEBOOK ENTRY
            List<PricebookEntry> pbeList;
       		if (!(productSet.isEmpty() || salesOrganizationSet.isEmpty())) {

           		for (PricebookEntry pbe: [SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c, MeanTimeToOperateC__c, MeanTimeToOperateLM__c, MeanTimeToOperateSM__c, MTTO_FO_Cups_Bucket__c, MTTO_FO_Large_Bucket__c, MTTO_FO_Small_Bucket__c,
                                      	  MTTO_MCO_Bottles_Bucket__c, MTTO_MCO_Descaling_Bucket__c, MTTO_MCO_Ingredients_Bucket__c, MTTO_MCO_Large_Bucket__c, MTTO_MCO_PM_Bucket__c, MTTO_MCO_Waterfilter_Bucket__c,
                                      	  MTTO_MCO_Bottles__c, MTTO_MCO_Descaling__c, MTTO_MCO_Ingredients__c, MTTO_MCO_Large__c, MTTO_MCO_PM__c, MTTO_MCO_Waterfilter__c
                                      	  FROM PricebookEntry
                                      	  WHERE Product2Id IN: productSet AND Sales_Organization__c IN: salesOrganizationSet ORDER BY Sales_Organization__c ASC
                ]) {
                	String pbeMapKey = String.valueOf(pbe.Product2Id) + pbe.Sales_Organization__c;

                	prMap.put(pbeMapKey, pbe);
            	}

        	}
        }catch(Exception ex) {
        	CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }

        CustomLogging.pop();
        return prMap;
    }
    
    
    /******************************************************************************
	* Karen Hung DOO-5268
	* 11.3.2021  API Mapping of activity buckets
	******************************************************************************/
    public static Map<String,String> mcoActivityBucketAPIMap(){
        return new Map<String, String>{	'Large' => 'MTTO_MCO_Large_Bucket__c', 
                                        'Preventive Maintenance' => 'MTTO_MCO_PM_Bucket__c', 
                                        'Waterfilter' => 'MTTO_MCO_Waterfilter_Bucket__c', 
                                        'Descaling' => 'MTTO_MCO_Descaling_Bucket__c', 
                                        'Bottle' => 'MTTO_MCO_Bottles_Bucket__c', 
                                        'Ingredients' => 'MTTO_MCO_Ingredients_Bucket__c'};       
        
    }
    
     /******************************************************************************
	* Karen Hung DOO-5268
	* 11.3.2021  Mapping of Letter to activity type
	******************************************************************************/
    public static Map<String,String> letterActivityMap(){
        return new Map<String, String>{		'L' => 'Large', 
                                            'P' => 'Preventive Maintenance', 
                                            'W' => 'Waterfilter', 
                                            'D' => 'Descaling', 
                                            'B' => 'Bottle', 
                                            'I' => 'Ingredients'};     
    }
    
    /******************************************************************************
	* Karen Hung DOO-5268
	* 11.3.2021  Mapping of Letter to MTTO MCO API in PricebookEntry
	******************************************************************************/
    public static Map<String,String> letterMTTOAPIMap(){
        return new Map<String, String>{		'L' => 'MTTO_MCO_Large__c', 
                                            'P' => 'MTTO_MCO_PM__c', 
                                            'W' => 'MTTO_MCO_Waterfilter__c', 
                                            'D' => 'MTTO_MCO_Descaling__c', 
                                            'B' => 'MTTO_MCO_Bottles__c', 
                                            'I' => 'MTTO_MCO_Ingredients__c'};     
    }
    
            
	
    /******************************************************************************
	* Karen Hung DOO-5268
	* 11.3.2021  to return Operating  bucket string for multiple/combination activity
	******************************************************************************/
    public static String operatingBucket(String taskCombo, PricebookEntry pbe){
        CustomLogging.push('operatingBucket', 'TS_UtilityClass');
    	String OPG_Bucket = '';
        
        List<Decimal> woliMTTOs = new List<Decimal>();
		
        Map<Decimal, String> mttoActivityMap = new Map<Decimal, String>();
        
        //get the mtto mco values and sort
        for(Integer i=0; i<taskCombo.length(); i++){
           //get api field counterpart per letter
            String mttoAPI = letterMTTOAPIMap().get(taskCombo?.substring(i, i+1));
            Decimal mttoValue = (Decimal) pbe?.get(mttoAPI); 
            if(mttoValue !=null) {
                woliMTTOs.add(mttoValue);
				mttoActivityMap.put(mttoValue, letterActivityMap().get(taskCombo?.substring(i, i+1)));
            }
        }
        
        if(woliMTTOs.size() > 0 ){
        	woliMTTOs.sort();
            
            //get the last index(biggest) of mtto bucket values
            Decimal largestValue = woliMTTOs.size() > 0 ? woliMTTOs[woliMTTOs.size()-1] : null;
            String activity =  mttoActivityMap.get(largestValue);
            OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap().get(activity))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap().get(activity))) : '';        
        }
         
        CustomLogging.pop();
        return OPG_Bucket;
    }
    
     /******************************************************************************
	* Karen Hung DOO-5271
	* 15.3.2021  processes bucket calculation of price book entries
	******************************************************************************/    
    public static List<PricebookEntry> processMTTOBucket(List<PricebookEntry> pbelist){
        CustomLogging.push('processMTTOBucket', 'TS_UtilityClass'); 
    	List<PricebookEntry> pbes = new List<PricebookEntry>();
        
        Map<String, Schema.SObjectField> schemaPricebookEntryMap = Schema.SObjectType.PricebookEntry.fields.getMap();
        Set<Schema.SObjectField> schemaPricebookEntryFields = new Set<Schema.SObjectField>();
        Set<String> pbeFieldsStrings = new Set<String>();
        Map<String, Schema.SObjectField> strBucketAPISchemaMap = new  Map<String, Schema.SObjectField>();
        
        //Mapping of mtto API to mtto bucket fields
        Map<String, String> mttoBucketAPIMap = new Map<String, String>{  'MeanTimeToOperateC__c' => 'MTTO_FO_Cups_Bucket__c',
            															 'MeanTimeToOperateLM__c' => 'MTTO_FO_Large_Bucket__c',
                                                                         'MeanTimeToOperateSM__c' => 'MTTO_FO_Small_Bucket__c',
                                                                         'MTTO_MCO_Bottles__c' => 'MTTO_MCO_Bottles_Bucket__c',
                                                                         'MTTO_MCO_Descaling__c' => 'MTTO_MCO_Descaling_Bucket__c',
                                                                         'MTTO_MCO_Ingredients__c' => 'MTTO_MCO_Ingredients_Bucket__c',
                                                                         'MTTO_MCO_Large__c' => 'MTTO_MCO_Large_Bucket__c',
                                                                         'MTTO_MCO_PM__c' => 'MTTO_MCO_PM_Bucket__c',
                                                                         'MTTO_MCO_Waterfilter__c' => 'MTTO_MCO_Waterfilter_Bucket__c'};
                                                                            
        //GET schema of MTTO bucket values
        for(Schema.SObjectField schm : schemaPricebookEntryMap.values()){
            if(mttoBucketAPIMap.values().contains(String.valueOf(schm))){
            	strBucketAPISchemaMap.put(String.valueOf(schm), schm);	    
            }
        }
        
        Set<String> salesOrgSet = new Set<String>();
        for(PricebookEntry pbe : pbeList){
        	salesOrgSet.add(pbe.Sales_Organization__c);
        }
        
        Map<CountrySetting__c, String> csetBucketMap = new Map<CountrySetting__c, String>();
        List<CountrySetting__c> bucketList = [SELECT Id,Bucket__c, Maximum__c,Minimum__c,Country__c FROM CountrySetting__c WHERE Active__c = true and Recordtype.Name='Country Operating Invoice Bucket' AND Country__c IN :salesOrgSet];
        if(bucketList.size() > 0){
            for(CountrySetting__c cset : bucketList){
                csetBucketMap.put(cset, cset.Bucket__c);
            }	    
        }
         
        for(PricebookEntry pbeRec : pbeList){
            for(String mttoAPIField: mttoBucketAPIMap.keySet()){
 
                String bucketAPI = mttoBucketAPIMap.get(mttoAPIField);
                
                //if mtto field is populated and != 0, get the correct bucket value based on country setting
                if(pbeRec.get(mttoAPIField) != null && pbeRec.get(mttoAPIField) != 0){
                	
                    Decimal mttoValue = (Decimal) pbeRec.get(mttoAPIField);
                    
                    //initial value of bucket field
                    pbeRec.put(strBucketAPISchemaMap.get(bucketAPI), null);
                    
                    if(!csetBucketMap.isEmpty()){
                        //evaluate to which bucket mtto will fall
                        for(CountrySetting__c bucketCSET : csetBucketMap.keySet()){
                            if(bucketCSET.Country__c == pbeRec.Sales_Organization__c && mttoValue >= bucketCSET.Minimum__c && mttoValue <= bucketCSET.Maximum__c){
                                pbeRec.put(strBucketAPISchemaMap.get(bucketAPI), bucketCSET.Bucket__c);
                            }    
                        }           
                    }                               
                    
                
                //if mtto api field is blank or 0, set the bucket field to null
                }else{
                    pbeRec.put(strBucketAPISchemaMap.get(bucketAPI), null);    
                } 
            }
            pbes.add(pbeRec);
        }           
        
        CustomLogging.pop();
        return pbes;
    }
    
    /******************************************************************************
	* Karen Hung DOO-5271
	* 15.3.2021  processes bucket calculation of all price book entries called by Recalculate PBE Buckets flow
	******************************************************************************/     
    @InvocableMethod
    public static void recalculatePBEBuckets(){
    	CustomLogging.push('recalculatePBEBuckets', 'TS_UtilityClass');
        try{
            List<PricebookEntry> pbes = new List<PricebookEntry>();
            pbes = [SELECT Id, Sales_Organization__c, MeanTimeToOperateLM__c, MTTO_FO_Large_Bucket__c, MeanTimeToOperateC__c, MTTO_FO_Cups_Bucket__c, MeanTimeToOperateSM__c, MTTO_FO_Small_Bucket__c,
                    MTTO_MCO_Bottles__c,MTTO_MCO_Bottles_Bucket__c, MTTO_MCO_Descaling__c, MTTO_MCO_Descaling_Bucket__c,MTTO_MCO_Ingredients__c,MTTO_MCO_Ingredients_Bucket__c, MTTO_MCO_Large__c, MTTO_MCO_Large_Bucket__c, MTTO_MCO_PM__c,MTTO_MCO_PM_Bucket__c, MTTO_MCO_Waterfilter__c, MTTO_MCO_Waterfilter_Bucket__c 
                    FROM PricebookEntry WHERE MeanTimeToOperateLM__c != null OR MTTO_MCO_Large__c !=null];
            
            List<PricebookEntry> pbeToUpdate = processMTTOBucket(pbes);
            if(pbeToUpdate.size() > 0){
                database.update(pbeToUpdate);   
            }
            
        }catch(Exception ex){
        	CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();
    }
}