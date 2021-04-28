/*
 *Created by: Karen Hung 
 *Date: 26.09.2019 DOO-858, DOO-2185
 *Description: Apex Controller for TS_MDMAdminFlow lightning component 
 * 
*/
public without sharing class TS_MDMAdminFlowController {
    
    public class TS_MDMAdminFlowControllerException extends Exception {}
    public static Boolean hasException = false;
    
	/**check if user is third party*/ //Karen Hung 27/01/2021 DOO-5152
    @AuraEnabled
    public static string checkThirdParty(){
    	LightningResponse lResponse = new LightningResponse();
        try{
            
            String userId = UserInfo.getUserId();
            List<Resource__c> resourceList = [SELECT Id, RLS_Portal_User__c FROM Resource__c WHERE RelatedUser__c =:userId AND RLS_Portal_User__c = TRUE];
			lResponse.returnValue = JSON.serialize(resourceList);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
		return JSON.serialize(lResponse);   
    }
    
    /**check if user has create or edit operating schedule permission*/ //Karen Hung 14/04/2021 DOO-5055
    @AuraEnabled
    public static string checkCreateEditPermission(){
    	LightningResponse lResponse = new LightningResponse();
        try{
            
            String userId = UserInfo.getUserId();
            List<Resource__c> resourceList = [SELECT Id FROM Resource__c WHERE RelatedUser__c =:userId AND Create_Edit_OPG_Schedule__c = TRUE];
			lResponse.returnValue = JSON.serialize(resourceList);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
		return JSON.serialize(lResponse);   
    }

    /**get recordtype values**/ //Karen Hung 27/01/2021 DOO-5152
	@AuraEnabled
    public static Map<String,String> recordTypes(String sObj){
		        
		Map <String, String> recordtypemap = new Map<String, String>();
        SObjectType selectedsObject = Schema.getGlobalDescribe().get(sObj);            
        List<Schema.RecordTypeInfo> recordtypes = selectedsObject.getDescribe().getRecordTypeInfos();                
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master' && rt.isAvailable()){
            	recordtypemap.put(rt.getName(),rt.getRecordTypeId());	    
            }               
        }
		return recordtypemap;
    }
    
    /**to get accountlocation additional details*/
    @AuraEnabled
    public static string getDetails(String recordId){
        
        LightningResponse lResponse = new LightningResponse();
       	
        //Machine Count Info // Karen Hung 20.04.2020 DOO-4366 added TS_Constants.MACHINE_CLEAN_OPERATING
		List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c 
                                         FROM PhysicalAsset__c
                                         WHERE AccountLocation__c = :recordId
                                         AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                         AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                         AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                         AND MothballAssetIndicator__c = FALSE];
        
        //Route Count Info
        List<Route__c> routeList = [SELECT Id, Account_Location__c 
                                    FROM Route__c 
                                    WHERE Account_Location__c = :recordId];
       
        //Machine with Route Line Item Info
        Set<String> paWithRoute = new Set<String>();
        if(!paList.isEmpty()){
            for(Route_Line_Item__c rli : [SELECT Id, PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList]){
                paWithRoute.add(rli.PhysicalAssetId__c);
            }
        }
        
        AccountLocationWrapper alWrap = new AccountLocationWrapper();
        alWrap.machineCount = paList.size();
        alWrap.routeCount = routeList.size();
        alWrap.machineWORouteCount = paList.size() - paWithRoute.size();
        
        lResponse.returnValue = JSON.serialize(alWrap);
        
        return JSON.serialize(lResponse);       
    }
    
    /*returns list of unassigned machines*/
    @AuraEnabled
    public static string getUnassignedMachines(String recordId, Integer offset){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            //active assets in account location with machine care // Karen Hung 20.04.2020 DOO-4366 added TS_Constants.MACHINE_CLEAN_OPERATING
            List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c 
                                            FROM PhysicalAsset__c
                                            WHERE AccountLocation__c = :recordId
                                            AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                            AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                            AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                            AND MothballAssetIndicator__c = FALSE];
            
            List<PhysicalAsset__c> unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, EndDate__c, Machine_Care__c
                                                      FROM PhysicalAsset__c
                                                      WHERE Id IN :paList 
                                                      AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)
                                                      ORDER BY CreatedDate DESC];

            lResponse.returnValue = JSON.serialize(unassignedList);
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*returns all machines without daily operating schedule*/
    @AuraEnabled
    public static string getNoOpSched(String recordId, Integer offset){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
			            
            //get without opsched // Karen Hung 20.04.2020 DOO-4366 added TS_Constants.MACHINE_CLEAN_OPERATING
            List<PhysicalAsset__c> withoutOpsched = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, SalesOrganization__c, EndDate__c, Machine_Care__c
                                                    FROM PhysicalAsset__c
                                                    WHERE AccountLocation__c = :recordId
                                                    AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                    AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                    AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                    AND MothballAssetIndicator__c = FALSE
                                                    AND Id NOT IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c 
                                                                    WHERE OperatingReady__c = true)];

            lResponse.returnValue = JSON.serialize(withoutOpsched);
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*returns all routes related to account location record*/
    @AuraEnabled
    public static string getRoutes(String recordId, Integer offset){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            List<Route__c> routeList = [SELECT Id, Account_Location__c, Name, Unique_Route_Number__c, No_of_Machines__c, Has_Stock_Location__c, Preferred_Operator__c,Required_Operator__c,Required_Operator__r.Name,Preferred_Operator__r.Name, CurrencyIsoCode, OwnerId, Owner.Name FROM Route__c WHERE Account_Location__c = :recordId ORDER BY CreatedDate DESC];
            //LIMIT 20
            //OFFSET :offset];
                                        
            lResponse.returnValue = JSON.serialize(routeList);

        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*returns all route line items related to account location record*/
    @AuraEnabled
    public static string getRouteItems(String recordId, Integer offset, String routeId){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            //Karen Hung Feb 25, 2020
            /* String query = 'SELECT Id, Name, PhysicalAssetId__c,PhysicalAssetId__r.Name,PhysicalAssetId__r.Building__c,PhysicalAssetId__r.Floor__c,PhysicalAssetId__r.Area__c,PhysicalAssetId__r.CustomerReferenceNumber__c, RouteId__c,RouteId__r.Name,Storage_Location__c, CurrencyIsoCode ' + 'FROM Route_Line_Item__c ' + 'WHERE PhysicalAssetId__r.AssetStatus__c IN  (\'Activated\',\'Pending Cancellation\') AND RouteId__r.Account_Location__c = ' + '\'' + recordId +'\''; */
            // Karen Hung 20.04.2020 DOO-4366 added Machine Clean Operating
            String query = 'SELECT Id, Name, PhysicalAssetId__c,PhysicalAssetId__r.Name,PhysicalAssetId__r.SalesOrganization__c,PhysicalAssetId__r.Building__c,PhysicalAssetId__r.Floor__c,PhysicalAssetId__r.Area__c,PhysicalAssetId__r.CustomerReferenceNumber__c, RouteId__c,RouteId__r.Name,Storage_Location__c,PhysicalAssetId__r.EndDate__c,PhysicalAssetId__r.Machine_Care__c,CurrencyIsoCode ' + 'FROM Route_Line_Item__c ' 
            + 'WHERE PhysicalAssetId__r.AssetStatus__c IN (\'Activated\',\'Pending Cancellation\') ' 
            + ' AND PhysicalAssetId__r.MothballAssetIndicator__c = false ' 
            + ' AND PhysicalAssetId__r.Recordtype.Name = \'Machine\' '
            + ' AND PhysicalAssetId__r.Machine_Care__c IN (\'Full Operating\',\'Comfort Operating\',\'Machine Clean Operating\') '
            + ' AND RouteId__r.Account_Location__c = ' + '\'' + recordId +'\'';

            System.debug(query);

            if(routeId != null){
                query = query + ' AND RouteId__c = ' +'\'' + routeId + '\'';
            }
            
            query = query + ' ORDER BY CreatedDate DESC';
            
            if(offset != null){
                query = query + ' LIMIT 20 OFFSET ' + offset;
            }
                        
            lResponse.returnValue = JSON.serialize(Database.query(query));

        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*returns all customer holidays account location record*/
    @AuraEnabled
    public static string getHolidays(String recordId, Integer offset){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            List<Customer_Holiday__c> holidayList = [SELECT Id, Name, Day__c, From__c, OwnerId, Owner.Name
                                       				 FROM Customer_Holiday__c
                                        			 WHERE Account_Location__c = :recordId
                                                     ORDER BY CreatedDate DESC];                                   
                                                      //LIMIT 20
                                                      //OFFSET :offset];
            
            lResponse.returnValue = JSON.serialize(holidayList);

        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*for record deletion*/
    @AuraEnabled
    public static void deleteRecord(String recordId, String objectName){
        CustomLogging.push('deleteRecord', 'TS_MDMAdminFlowController');
        try{
            
            String query = 'SELECT Id FROM ' + objectName + ' WHERE Id=' + '\''+recordId+'\'';
            delete(Database.query(query));
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*to update Route*/
    @AuraEnabled
    public static void updateRouteItemRecord(List<String> recordIds, String routeId){
        CustomLogging.push('updateRouteItemRecord', 'TS_MDMAdminFlowController');
        try{
			
            List<Route_Line_Item__c> toUpdate = new List<Route_Line_Item__c>();
            for(List<Route_Line_Item__c> itemList : [SELECT Id, RouteId__c from Route_Line_Item__c WHERE Id IN :recordIds]){
                for(Route_Line_Item__c item : itemList){
                    item.RouteId__c = routeId;
                }
                toUpdate.addAll(itemList);
            }
            update toUpdate;
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*to mass assign machine to Route*/
    @AuraEnabled
    public static void assignMachines(List<String> recordIds, String routeId){
        CustomLogging.push('updateRouteItemRecord', 'TS_MDMAdminFlowController');
        try{
			List<Route_Line_Item__c> toInsertList = new List<Route_Line_Item__c>();
            for(PhysicalAsset__c pAsset : [SELECT Id, Name from PhysicalAsset__c WHERE Id IN :recordIds]){
                Route_Line_Item__c item = new Route_Line_Item__c();
                item.Name = pAsset.Name;
                item.RouteId__c = routeId;
                item.PhysicalAssetId__c = pAsset.Id;
                toInsertList.add(item);
            }
            
            insert toInsertList;
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*to mass update Physical Assets*/
    //Karen Hung DOO-2900 added MothballExpirationDate__c
    @AuraEnabled
    public static void updateMachines (List<String> recordIds, String building, Boolean smokingArea, String floor, String customerReference, String area, Boolean mothball, Date mothballExp, String connected, Boolean pcbChanged, String counterReading, String preferredOp, String lastOp, String machineCare){
        CustomLogging.push('updateMachines', 'TS_MDMAdminFlowController');
        try{
			List<PhysicalAsset__c> toUpdate = new List<PhysicalAsset__c>();
            for(List<PhysicalAsset__c> itemList : [SELECT Id,Building__c,SmokingArea__c,Floor__c,CustomerReferenceNumber__c,Area__c,MothballAssetIndicator__c,MothballExpirationDate__c,Connected__c,OP_PCB_Changed__c,CounterReading__c,OP_PreferredOperator__c,OP_LastPerformingOperator__c,MachineCareHours__c from PhysicalAsset__c WHERE Id IN :recordIds]){
                for(PhysicalAsset__c item : itemList){
                    
                    if(building != null && building !=''){
                        item.Building__c= building;
                    }
                    
                    if(smokingArea == true || smokingArea == false){
                        item.SmokingArea__c = smokingArea;
                    }
                    
                    if(floor != null && floor != ''){
                    	item.Floor__c = floor;   
                    }
                    
                    if(customerReference != null && customerReference != ''){
                    	item.CustomerReferenceNumber__c = customerReference;   
                    }
                    
                    if(area != null && area != ''){
                    	item.Area__c = area;   
                    }
                    
                    if(mothball == true || mothball == false){
                    	item.MothballAssetIndicator__c = mothball;   
                    }
                    
                    if(mothballExp != null){
                        item.MothballExpirationDate__c = mothballExp;
                    }
                    if(connected != '--None--'){
                    	item.Connected__c = connected;   
                    }
                    
                    if(pcbChanged == true || pcbChanged == false){
                    	item.OP_PCB_Changed__c = pcbChanged;   
                    }
                    
                    if(counterReading != '--None--'){
                    	item.CounterReading__c = counterReading;   
                    }
                    
                    if(preferredOp != null && preferredOp != ''){
                    	item.OP_PreferredOperator__c = preferredOp;   
                    }
                    
                    if(lastOp != null && lastOp != ''){
                    	item.OP_LastPerformingOperator__c = lastOp;   
                    }
                    
                    if(machineCare != null){
                    	item.MachineCareHours__c = Decimal.valueOf(machineCare);   
                    }
                }
                toUpdate.addAll(itemList);
            }
            update toUpdate;
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*inline edit Route*/
    @AuraEnabled
    public static void updateRoutes(List<Route__c> routes){
        CustomLogging.push('updateRoute', 'TS_MDMAdminFlowController');
        try{
			
			update routes;
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*inline edit Route*/
    @AuraEnabled
    public static void updateRouteLines(List<Route_Line_Item__c> routeItems){
        CustomLogging.push('updateRouteLines', 'TS_MDMAdminFlowController');
        try{
			
			update routeItems;
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*inline edit Customer Holiday*/
    @AuraEnabled
    public static void updateHolidays(List<Customer_Holiday__c> holidays){
        CustomLogging.push('updateHolidays', 'TS_MDMAdminFlowController');
        try{
			
			update holidays;
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
    /*inline edit Physical Asset*/
    @AuraEnabled
    public static void updateMachinesInline(List<PhysicalAsset__c> machines){
        CustomLogging.push('updateMachinesInline', 'TS_MDMAdminFlowController');
        try{
			
			update machines;
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            } 
        }catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());    
        }
        
        CustomLogging.pop();    
    }
    
	/*returns list of routes in all routelineitems*/
    @AuraEnabled
    public static string getRoutePicklist (String recordId) {
        CustomLogging.push('getRoutePicklist', 'TS_MDMAdminFlowController');
        
        LightningResponse lResponse = new LightningResponse();
        
        Set<Id> routeIds = new Set<Id>();
        
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            for(Route_Line_Item__c routeItem : [SELECT Id, RouteId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__c = :recordId]){
            	routeIds.add(routeItem.RouteId__c);	    
            }
            
            List<Route__c> routeList = [SELECT Id, Name FROM Route__c WHERE Id IN :routeIds];
                                        
            lResponse.returnValue = JSON.serialize(routeList);

        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        CustomLogging.pop(); 
        return JSON.serialize(lResponse);      
    }

    /*check if the current user has access to change the machine details in Route Assignment tab */
    @AuraEnabled
    public static string check_TS_UpdateMachineDetailsMTTO (String recordId) {
        CustomLogging.push('check_TS_UpdateMachineDetailsMTTO', 'TS_MDMAdminFlowController');
        
        LightningResponse lResponse = new LightningResponse();
                
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
            Boolean hasCustomPermission = FeatureManagement.checkPermission('TS_UpdateMachineDetailsMTTO');
            lResponse.returnValue = JSON.serialize(String.valueOf(hasCustomPermission));

        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        CustomLogging.pop(); 
        return JSON.serialize(lResponse);      
    }

    /*response format*/
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
    
    /*for account location details*/
    public class AccountLocationWrapper{
        @AuraEnabled public Integer machineCount; ///{get;set;}
        @AuraEnabled public Integer routeCount; //{get;set;}
        @AuraEnabled public Integer machineWORouteCount; //{get;set;}
    }

    @AuraEnabled
    public static String executeRecalculationBatch(String postalCode, String countryCode, String thirdPartyResource, String filterType){

        LightningResponse lResponse = new LightningResponse();

        try{
            String thirdPartyRsrcName;            
            if(thirdPartyResource != null && thirdPartyResource.length() > 5 && filterType.toLowerCase() == '3po'){
                Resource__c thirdPartyRsrc = [SELECT Name FROM Resource__c WHERE RelatedUser__c =:thirdPartyResource LIMIT 1];
                if(thirdPartyRsrc != null && thirdPartyRsrc.Name != null){
                    thirdPartyRsrcName = thirdPartyRsrc.Name;
                }
            }

            //GET DATA
            //List<TS_Hierarchy_Derivation__mdt> get_postCodes = [SELECT Id, District__c, District__r.Label, Postal_Code__c, Country_Code__c FROM TS_Hierarchy_Derivation__mdt WHERE Postal_Code__c =: postalCode AND Country_Code__c =: countryCode LIMIT 1];
            List<TS_District__mdt> get_district = [SELECT Id, Label, Country_Code__c FROM TS_District__mdt WHERE Id IN (SELECT District__c FROM TS_Hierarchy_Derivation__mdt WHERE Postal_Code__c =: postalCode.left(4) AND Country_Code__c =: countryCode)];

            String teamName;
            String districtLabel;
            Boolean isNordicsParam = false;

            if(!get_district.isEmpty()){      
                String countryCodeQuery = get_district[0].Country_Code__c;
                districtLabel =  get_district[0].Label;

                teamName = countryCodeQuery + ' - ' + districtLabel;
                if(countryCodeQuery == 'NO' || countryCodeQuery == 'DK') isNordicsParam = true;

            }

            //CHECK IF THE SAME JOB IS RUNNING
            List<AsyncApexJob> calculationJob = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing', 'Queued', 'Holding') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_OperatingOptimizerCalculator_Batch') 
                                                LIMIT 1000];

            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\') LIMIT 1000');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\') LIMIT 1000');

            if(calculationJob.isEmpty() && (batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && !Test.isRunningTest() && teamName != null){
                TS_OperatingOptimizerCalculator_Batch batchCalculator_var = new TS_OperatingOptimizerCalculator_Batch(teamName);
                batchCalculator_var.isNordics = isNordicsParam;
                batchCalculator_var.thirdPartyResource = thirdPartyResource;
               	batchCalculator_var.filterType = filterType;
                Database.executeBatch(batchCalculator_var, 100);

                lResponse.status = TS_Constants.RECALCULATE_SUCCESS;
                if(thirdPartyRsrcName != null){
                    lResponse.message = TS_Constants.RECALCULATE_SUCCESS_MESSAGE + ' ' + thirdPartyRsrcName; 
                }
                else {
                    lResponse.message = TS_Constants.RECALCULATE_SUCCESS_MESSAGE + ' ' + districtLabel; 
                }
                
            } else {
                lResponse.status = TS_Constants.RECALCULATE_ERROR;
                lResponse.message = TS_Constants.RECALCULATE_ERROR_MESSAGE;
            }

        } catch (Exception e){
            lResponse.status = TS_Constants.RECALCULATE_ERROR;
            lResponse.message = e.getMessage();
        }
        
        return JSON.serialize(lResponse);
    }
    
    @AuraEnabled
    public static String checkFlag(String featureFlag){
        CustomLogging.push('checkFlag', 'TS_MDMAdminFlowController');
        LightningResponse lResponse = new LightningResponse();
        try{
        	List<TS_Feature_Flag__mdt> featureFlags =  new List<TS_Feature_Flag__mdt>();
            featureFlags = [SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName = :featureFlag AND Enable__c = true];
            lResponse.returnValue = JSON.serialize(featureFlags);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
             
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
       
        CustomLogging.pop(); 
        return JSON.serialize(lResponse);
    }
    
    
    /*returns all machines with daily operating schedule*/
    @AuraEnabled
    public static string getWithOpSched(String recordId){
        
        LightningResponse lResponse = new LightningResponse();
        
        try{
            			                       
            List<OperatingSchedule__c> opsList = new List<OperatingSchedule__c>();    
            opsList = [SELECT Id, Name, PhysicalAsset__r.Name, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c,PhysicalAsset__r.EndDate__c,
                       SM_1_Monday__c, SM_1_Tuesday__c, SM_1_Wednesday__c, SM_1_Thursday__c, SM_1_Friday__c, SM_1_Saturday__c, SM_1_Sunday__c, SM_2_Monday__c, SM_2_Tuesday__c, SM_2_Wednesday__c, SM_2_Thursday__c, SM_2_Friday__c, SM_2_Saturday__c, SM_2_Sunday__c,
                       C_1_Monday__c, C_1_Tuesday__c, C_1_Wednesday__c, C_1_Thursday__c, C_1_Friday__c, C_1_Saturday__c, C_1_Sunday__c, C_2_Monday__c, C_2_Tuesday__c, C_2_Wednesday__c, C_2_Thursday__c, C_2_Friday__c, C_2_Saturday__c, C_2_Sunday__c,
                       LM_1_Monday__c,LM_1_Tuesday__c,LM_1_Wednesday__c,LM_1_Thursday__c,LM_1_Friday__c,LM_1_Saturday__c,LM_1_Sunday__c,LM_2_Monday__c,LM_2_Tuesday__c,LM_2_Wednesday__c,LM_2_Thursday__c,LM_2_Friday__c,LM_2_Saturday__c,LM_2_Sunday__c
                       FROM OperatingSchedule__c
                       WHERE OperatingReady__c = true
                       AND PhysicalAsset__r.AccountLocation__c = :recordId
                       AND PhysicalAsset__r.Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                       AND PhysicalAsset__r.AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                       AND PhysicalAsset__r.Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                       AND PhysicalAsset__r.MothballAssetIndicator__c = false];
            
            

            lResponse.returnValue = JSON.serialize(opsList);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*evaluate RLI's if to create operating schedule or not*/
	@AuraEnabled
    public static String evaluateAssignments(String recordId, String evalMode){
    	LightningResponse lResponse = new LightningResponse();
        
       try{
            
            
            Map<String,String> assetSchedMap = new Map<String,String>();
           
			//invoked from Machines without Operating Schedule
           if(evalMode == 'Machine'){
                 Map<Id, PhysicalAsset__c> assetMap = new Map<Id, PhysicalAsset__c>([SELECT Id FROM PhysicalAsset__c
                                                                                    WHERE AccountLocation__c = :recordId
                                                                                    AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                                                    AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                                                    AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                                                    AND MothballAssetIndicator__c = FALSE
                                                                                    AND Id NOT IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c 
                                                                                                    WHERE OperatingReady__c = true)]);
				
               for(OperatingSchedule__c opsched : [SELECT Id,PhysicalAsset__c,Active__c FROM OperatingSchedule__c WHERE PhysicalAsset__c IN :assetMap.keySet() ORDER BY Active__c DESC, CreatedDate DESC]){
                   if(!assetSchedMap.containsKey(opsched.PhysicalAsset__c)){
                       assetSchedMap.put(opSched.PhysicalAsset__c, opsched.Id);
                   }  
               }    
               system.debug('Machine');
           }else{
               List<Route_Line_Item__c> rliList = new List<Route_Line_Item__c>();
               rliList = [SELECT Id, PhysicalAssetId__c 
                          FROM Route_Line_Item__c 
                          WHERE PhysicalAssetId__r.AssetStatus__c IN ('Activated','Pending Cancellation')
                          AND PhysicalAssetId__r.MothballAssetIndicator__c = false 
                          AND PhysicalAssetId__r.Recordtype.Name = 'Machine'
                          AND PhysicalAssetId__r.Machine_Care__c IN ('Full Operating','Comfort Operating','Machine Clean Operating')
                          AND RouteId__r.Account_Location__c = :recordId];
               
               if(!rliList.isEmpty()){
                   Map<Id, PhysicalAsset__c> assetMap = new Map<Id, PhysicalAsset__c>([SELECT Id FROM PhysicalAsset__c WHERE Id IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE Id IN :rliList)]);
                   for(OperatingSchedule__c opsched : [SELECT Id,PhysicalAsset__c,Active__c FROM OperatingSchedule__c WHERE PhysicalAsset__c IN :assetMap.keySet() ORDER BY Active__c DESC, CreatedDate DESC]){
                       if(!assetSchedMap.containsKey(opsched.PhysicalAsset__c)){
                           assetSchedMap.put(opSched.PhysicalAsset__c, opsched.Id);
                       }  
                   }    
               }    
               
           }                  
            
            system.debug(assetSchedMap);
            lResponse.returnValue = JSON.serialize(assetSchedMap);
           
            if (Test.isRunningTest() && hasException) {
                throw new TS_MDMAdminFlowControllerException('Force to throw an exception');
            }
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
       
        
        return JSON.serialize(lResponse);
    }

}