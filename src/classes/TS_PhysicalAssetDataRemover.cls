/**
* @author        Karen Hung
* @date          10.30.2018
* @description   Class used to remove values in the field set of the Physical Asset when contract expires
* @revision(s)
*/
public with sharing class TS_PhysicalAssetDataRemover {

	/*to handle exception*/
	public class TS_PhysicalAssetDataRemoverException extends Exception {}
    public static Boolean hasException = false;

    /*To set ServicesFieldValues field set to null, called by the TS_PhysicalAssetUpdate_Batch*/
    public static List<PhysicalAsset__c> removeServicesFieldValues(List<PhysicalAsset__c> pAssetList){
    	CustomLogging.push('removeServicesFieldValues', 'TS_PhysicalAssetDataRemover');
    	 List<PhysicalAsset__c> paToUpdate = new List<PhysicalAsset__c>();

		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType paSchema = schemaMap.get('PhysicalAsset__c');
		Map<String, Schema.SObjectField> fieldMap = paSchema.getDescribe().fields.getMap();

    	 for(PhysicalAsset__c pAsset : pAssetList){
			 for(Schema.FieldSetMember fields :Schema.SObjectType.PhysicalAsset__c.fieldSets.getMap().get(TS_Constants.PA_SERVICESFIELDVALUES).getFields()) {
			 	Schema.DisplayType fielddataType = fieldMap.get(fields.getFieldPath()).getDescribe().getType();
			 	if(fielddataType !=  Schema.DisplayType.Boolean){
			 		pAsset.put(fields.getFieldPath(),null);
			 	}else{
			 		pAsset.put(fields.getFieldPath(),false); //for field with boolean datatype
			 	}
			 }
			 paToUpdate.add(pAsset);
    	 }

    	 CustomLogging.pop(); 
    	 return paToUpdate; 
    } 

	 /*To set OperationalDataFieldValues field set to null to be called by WOTriggerObjecthandler for deinstallation*/	
	public static List<PhysicalAsset__c> removeOperationalDataFieldValues(List<PhysicalAsset__c> phAssetList){
		CustomLogging.push('removeOperationalDataFieldValues', 'TS_PhysicalAssetDataRemover');
		List<PhysicalAsset__c> paToUpdate = new List<PhysicalAsset__c>();

		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType paSchema = schemaMap.get('PhysicalAsset__c');
		Map<String, Schema.SObjectField> fieldMap = paSchema.getDescribe().fields.getMap();
		 for(PhysicalAsset__c pAsset : phAssetList){
			 for(Schema.FieldSetMember fields :Schema.SObjectType.PhysicalAsset__c.fieldSets.getMap().get(TS_Constants.PA_OPERATIONALDATAFIELDVALUES).getFields()) {
			 	Schema.DisplayType fielddataType = fieldMap.get(fields.getFieldPath()).getDescribe().getType();
			 	if(fielddataType !=  Schema.DisplayType.Boolean){
			 		pAsset.put(fields.getFieldPath(),null);
			 	}else{
			 		pAsset.put(fields.getFieldPath(),false);	//for field with boolean datatype
			 	}

			 }
			 paToUpdate.add(pAsset);
		 }

	    CustomLogging.pop();
	    return paToUpdate;
	}

    /*To set OperationalDataFieldValues field set to null to be called by TS_Case Closure Automation process builder*/
    @InvocableMethod
    public static void removeOperationalDataFieldValuesInvocable(List<PhysicalAsset__c> phAssetList){
    	CustomLogging.push('removeOperationalDataFieldValues', 'TS_PhysicalAssetDataRemover');
    	 List<PhysicalAsset__c> paToUpdate = new List<PhysicalAsset__c>();

    	Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType paSchema = schemaMap.get('PhysicalAsset__c');
		Map<String, Schema.SObjectField> fieldMap = paSchema.getDescribe().fields.getMap();

    	 for(PhysicalAsset__c pAsset : phAssetList){
			 for(Schema.FieldSetMember fields :Schema.SObjectType.PhysicalAsset__c.fieldSets.getMap().get(TS_Constants.PA_OPERATIONALDATAFIELDVALUES).getFields()) {
			 	Schema.DisplayType fielddataType = fieldMap.get(fields.getFieldPath()).getDescribe().getType();
			 	if(fielddataType !=  Schema.DisplayType.Boolean){
			 		pAsset.put(fields.getFieldPath(),null);
			 	}else{
			 		pAsset.put(fields.getFieldPath(),false);	//for field with boolean datatype
			 	}
			 }
			 paToUpdate.add(pAsset);
    	 }

    	 try{

    	 	if(!paToUpdate.isEmpty() && Schema.sObjectType.PhysicalAsset__c.isUpdateable()){
			 	database.update(paToUpdate);	
			}

			if (Test.isRunningTest() && hasException) {
				throw new TS_PhysicalAssetDataRemoverException('Force to throw an exception');
			}

    	 }catch(Exception e){
    	 	System.debug('removeOperationalDataFieldValuesInvocable error: ' + e);
    	 }

        CustomLogging.pop();
    }
}