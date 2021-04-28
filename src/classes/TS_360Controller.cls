/*
* @author        Xen Reyes
* @date          12.3.2018
* @description   Controller class for TS_Machine360Card/TS_Service360 Lightning Component
* @revision(s)
*/
public with sharing class TS_360Controller {

	public class LocationsWrapper{

        @AuraEnabled public Apttus_Config2__AccountLocation__c accountLocation;
        @AuraEnabled public List<PhysicalAsset__c> physicalAssetList;
        @AuraEnabled public Integer assetSize;
        @AuraEnabled public Map<Id, List<Case>> assetCaseSize;
		@AuraEnabled public Map<Id, List<Case>> assetCaseSizeNonS10;
       
        public LocationsWrapper(Apttus_Config2__AccountLocation__c accountLocation, List<PhysicalAsset__c> physicalAssetList, Integer assetSize, Map<Id, List<Case>> assetCaseSize, Map<Id, List<Case>> assetCaseSizeNonS10){
            this.accountLocation = accountLocation;
            this.physicalAssetList = physicalAssetList;
            this.assetSize = assetSize;
            this.assetCaseSize = assetCaseSize;
			this.assetCaseSizeNonS10 = assetCaseSizeNonS10;
        }
    }

    @AuraEnabled
	public static List<LocationsWrapper> locationsAndMachines (String accId, String sObjectName, String accLocIdStr){

		Map<Id, Apttus_Config2__AccountLocation__c> accLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>();
		Map<Id, List<PhysicalAsset__c>> accLocAssetListMap = new Map<Id, List<PhysicalAsset__c>>();
		Map<Id, List<Case>> assetIdOpenCaseMap= new Map<Id, List<Case>>();
		Map<Id, List<Case>> assetIdOpenCaseMapNonS10 = new Map<Id, List<Case>>();
		List<PhysicalAsset__c> allAssetList = new List<PhysicalAsset__c>();
		List<LocationsWrapper> locWrapList = new List<LocationsWrapper>();
		Set<Id> accLocListId = new Set<Id>();
		Set<Id> assetIdSet = new Set<Id>();
		Id machineId = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');

		if(sObjectName == 'Contact' || sObjectName == 'Account'){
			accLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Name, Apttus_Config2__AccountId__c FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__AccountId__c =: accId ORDER BY Name]);

			if(!accLocMap.values().isEmpty()){
				for(Apttus_Config2__AccountLocation__c accLoc : accLocMap.values()){
					accLocListId.add(accLoc.Id);
				}

				if(!accLocListId.isEmpty()){
					allAssetList = [SELECT Id, Name, AccountLocation__c, ProductDescription__c, ServiceWindow__c, toLabel(ResponseTime__c), Area__c, Building__c, CustomerReferenceNumber__c, Floor__c, HouseNumber__c, PostalCode__c, SerialNumber__c, Street__c, UniqueNumber__c FROM PhysicalAsset__c WHERE AccountLocation__c IN: accLocListId AND AssetStatus__c IN ('Activated', 'Pending Cancellation') AND RecordTypeId =: machineId ORDER BY Name];
				}
			}
		} else if(sObjectName == 'Apttus_Config2__AccountLocation__c'){

			accLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Name, Apttus_Config2__AccountId__c FROM Apttus_Config2__AccountLocation__c WHERE Id =: accLocIdStr ORDER BY Name]);

			allAssetList = [SELECT Id, Name, AccountLocation__c, ProductDescription__c, ServiceWindow__c, toLabel(ResponseTime__c), Area__c, Building__c, CustomerReferenceNumber__c, Floor__c, HouseNumber__c, PostalCode__c, SerialNumber__c, Street__c, UniqueNumber__c FROM PhysicalAsset__c WHERE AccountLocation__c =: accLocIdStr AND AssetStatus__c IN ('Activated', 'Pending Cancellation') AND RecordTypeId =: machineId ORDER BY Name];
		}


		if(!allAssetList.isEmpty()){
			for(PhysicalAsset__c ps : allAssetList){
				if(accLocAssetListMap.containsKey(ps.AccountLocation__c)){
					accLocAssetListMap.get(ps.AccountLocation__c).add(ps);
				} else {
					accLocAssetListMap.put(ps.AccountLocation__c, new List<PhysicalAsset__c>{ps});
				}

				assetIdSet.add(ps.Id);
			}

			//XEN REYES KTS-2597 Feb. 14, 2019 */
			List<Case> openCasesPerAsset = [SELECT Id, PhysicalAsset__c, SubType__c FROM Case WHERE PhysicalAsset__c IN: assetIdSet AND Status != 'Closed' AND Status != 'Canceled'];
			if(!openCasesPerAsset.isEmpty()){
				
				for(Case cs : openCasesPerAsset){
					
					//XEN REYES DOO-2698 Nov. 22, 2019 */
					if(cs.SubType__c == 'S10' || cs.SubType__c == 'S15'){
						if(assetIdOpenCaseMap.containsKey(cs.PhysicalAsset__c)){
							assetIdOpenCaseMap.get(cs.PhysicalAsset__c).add(cs);
						} else {
							assetIdOpenCaseMap.put(cs.PhysicalAsset__c, new List<Case>{cs});
						}
					} else {
						if(assetIdOpenCaseMapNonS10.containsKey(cs.PhysicalAsset__c)){
							assetIdOpenCaseMapNonS10.get(cs.PhysicalAsset__c).add(cs);
						} else {
							assetIdOpenCaseMapNonS10.put(cs.PhysicalAsset__c, new List<Case>{cs});
						}
					}
				}
			}

			if(!accLocAssetListMap.values().isEmpty()){

				for(Id accLocId : accLocAssetListMap.keySet()){
					LocationsWrapper lwrap = new LocationsWrapper(	accLocMap.get(accLocId),
																	accLocAssetListMap.get(accLocId),
																	accLocAssetListMap.get(accLocId).size(),
																	assetIdOpenCaseMap,
																	assetIdOpenCaseMapNonS10);
					locWrapList.add(lwrap);
				}
			}
		}

		return locWrapList;
	}

	@AuraEnabled
	public static String getRecordTypeCR(){
		return TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Registration);          
	}

	public class AllInfoWrapper{

        @AuraEnabled public Map<String,TS_PicklistEntryWrapper> caseTypeSubtype {get; set;}
        @AuraEnabled public List<Schema.PicklistEntry> caseStatus {get; set;}
        @AuraEnabled public List<Schema.PicklistEntry> woliStatus {get; set;}
        @AuraEnabled public List<Schema.PicklistEntry> woliTypes {get; set;}
    }

	@AuraEnabled
	public static String getAllInfoService360(){
		
		AllInfoWrapper result = new AllInfoWrapper();
		result.caseTypeSubtype = TS_360Controller.getPLvalueOption3('Case', 'Type', 'SubType__c');
		result.caseStatus = TS_360Controller.picklistValuesHelper('Case', 'Status');
		result.woliStatus = TS_360Controller.picklistValuesHelper('WorkOrderLineItem', 'Status');
		result.woliTypes = TS_360Controller.picklistValuesHelper('WorkOrderLineItem', 'WorkOrderType__c');

		System.debug(result);
		return JSON.serialize(result);
	}

	public static Map<String,TS_PicklistEntryWrapper> getPLvalueOption3(String objectName, String controllingField, String dependentField) {
        CustomLogging.push('getPLvalueOption3', 'TS_360Controller');
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.DescribeFieldResult F = objFieldMap.get(controllingField).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        
        Schema.DescribeFieldResult F1 = objFieldMap.get(dependentField).getDescribe();
        Schema.sObjectField T1 = F1.getSObjectField();
        CustomLogging.pop();
        return TS_HL_FieldDescribeUtil.getDependentOptionsImpl2(T1, T);
    }

    public static List<Schema.PicklistEntry> picklistValuesHelper(String objectName, String fieldName){
    	
    	Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        Schema.DescribeFieldResult F = objFieldMap.get(fieldName).getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        List<Schema.PicklistEntry> contrEntries = T.getDescribe().getPicklistValues();

        return contrEntries;
    }

	@AuraEnabled
	public static String getRecords(String assetId, String objName, Boolean isCustomer, Boolean isComplaint, Boolean isFS, String itemType, String status, String startDate, String endDate){
		
		List<sObject> sobjList = new List<sObject>();
		String caseFields = 'ContactId, Contact.Name, toLabel(SubType__c), Status, SLADate__c, CaseNumber, Subject, Description, CancelationReason__c';
		String woliFields = 'JDELineItemNumber__c, toLabel(WorkOrderType__c), TaskDueDate__c, Status, ExecutingEngineer__c, ExecutingEngineer__r.EmployeeFirstName__c, ExecutingEngineer__r.EmployeeLastName__c, Subject, Description, MachineNotes__c, ExternalCompletionNote__c, InternalCompletionNote__c, CancelationReason__c';
		String queryString;

		//DATE FORMATS
		if(startDate != null && startDate != ''){
			List<String> split = startDate.split('-');
			if(split[1].length() != 2){
				split[1] = '0' + split[1];
			}
			startDate = split[0] + '-' + split[1] + '-' + split[2];
		}

		if(endDate != null && endDate != ''){
			List<String> split = endDate.split('-');
			if(split[1].length() != 2){
				split[1] = '0' + split[1];
			}
			endDate = split[0] + '-' + split[1] + '-' + split[2];
		}

		if(objName == 'Case'){

			Id recId;
			if(isCustomer){
				recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care').getRecordTypeId();
			} else if(isComplaint){
				recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
			} else if(isFS){
				recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Field Service Default').getRecordTypeId();
			}

			//QUERY FOR CASE
			queryString = 'SELECT Id, ' + caseFields +  ' FROM ' + 'Case WHERE RecordTypeId = \'' + recId + '\' AND PhysicalAsset__c = \'' + assetId + '\'' + ( (itemType != '' && itemType != null) ? ' AND SubType__c = \'' + itemType + '\'' : '') + ( (status != '' && status != null) ? ' AND Status = \'' + status + '\'' : '') + ((startDate != '' && startDate != null) ? ' AND CreatedDate >= ' + startDate + 'T00:00:00Z' : '') + ((endDate != '' && endDate != null) ? ' AND ClosedDate <= ' + endDate + 'T23:59:59Z' : '') + (isFS ? ' AND CompletionCode__c = \'140\'' : '') + ' ORDER BY CreatedDate DESC';

		} else if(objName == 'WorkOrderLineItem'){
			
			Id fsTaskId;
			Id crTaskId;
			Id opTaskId;
			Id rsTaskId;
			
			List<RecordType> woliRecTypes = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'WorkOrderLineItem'];

			if(!woliRecTypes.isEmpty()){
				for(RecordType rec : woliRecTypes){
					if(rec.Name == 'Register Task'){
						fsTaskId = rec.Id;
					} else if(rec.Name == 'Counter Reading Task'){
						crTaskId = rec.Id;
					} else if(rec.Name == 'Operating Task'){
						opTaskId = rec.Id;
					} else if(rec.Name == 'Routesales Task'){
						rsTaskId = rec.Id;
					}
				}
				
			}

			//QUERY FOR WORKORDERLINEITEM							
			queryString = 'SELECT Id, ' + woliFields +  ' FROM ' + 'WorkOrderLineItem WHERE (RecordTypeId = \'' + fsTaskId + '\' OR RecordTypeId = \'' + crTaskId + '\' OR RecordTypeId = \'' + opTaskId + '\' OR RecordTypeId = \'' + rsTaskId + '\') AND PhysicalAsset__c = \'' + assetId + '\'' + ((itemType != '' && itemType != null) ? ' AND WorkOrderType__c = \'' + itemType + '\'' : '') + ((status != '' && status != null) ? ' AND Status = \'' + status + '\'' : '') + ((startDate != '' && startDate != null) ? ' AND StartDate__c >= ' + startDate + 'T00:00:00Z' : '') + ((endDate != '' && endDate != null) ? ' AND EndDate__c <= ' + endDate + 'T23:59:59Z' : '') + ' ORDER BY CreatedDate DESC';
		}

		try{
			
			System.debug(queryString);
			
			if(queryString != null){
				sobjList = Database.query(queryString);
			}
			
			return JSON.serialize(sobjList);

		} catch (Exception e){
			return JSON.serialize(e);
		}
		
		//return queryString;
	}

}