/**
* @author        Rey Austral
* @date          9.28.2017           
* @description   Helper Class that will get the values of the dependent picklist
* @revision(s)
*/
public with sharing class TS_PicklistFieldHelper {
	 public static Map<String,TS_PicklistEntryWrapper> getDependentOptionsImpl(string objApiName , string contrfieldApiName , string depfieldApiName){
        system.debug(objApiName + '##' + contrfieldApiName + '###' + depfieldApiName);
           
        String objectName = objApiName.toLowerCase();
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,TS_PicklistEntryWrapper> objResults = new Map<String,TS_PicklistEntryWrapper>();
            //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        
        System.debug(objGlobalMap);

        if (!Schema.getGlobalDescribe().containsKey(objectName)){
            System.debug('OBJNAME NOT FOUND --.> ' + objectName);
            return null;
         }
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType==null){
            return objResults;
        }
        TS_Bitset bitSetObj = new TS_Bitset();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        //Check if picklist values exist
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            System.debug('FIELD NOT FOUND --.> ' + controllingField + ' OR ' + dependentField);
            return objResults;     
        }
        
        List<Schema.PicklistEntry> contrEntries = objFieldMap.get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> depEntries = objFieldMap.get(dependentField).getDescribe().getPicklistValues();
         objFieldMap = null;
        List<Integer> controllingIndexes = new List<Integer>();
        for(Integer contrIndex=0; contrIndex<contrEntries.size(); contrIndex++){            
            Schema.PicklistEntry ctrlentry = contrEntries[contrIndex];
            String label = ctrlentry.getValue();

            TS_PicklistEntryWrapper pickC = new TS_PicklistEntryWrapper();
            pickC.label = ctrlentry.getLabel();
            pickC.value = ctrlentry.getValue();
            pickC.dependentPickList = new List<TS_PicklistEntryWrapper>();

            objResults.put(label,pickC);
            controllingIndexes.add(contrIndex);
        }
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<PicklistEntryWrapper> objJsonEntries = new List<PicklistEntryWrapper>();
        for(Integer dependentIndex=0; dependentIndex<depEntries.size(); dependentIndex++){            
               Schema.PicklistEntry depentry = depEntries[dependentIndex];
               objEntries.add(depentry);
        } 
        objJsonEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objEntries), List<PicklistEntryWrapper>.class);
        List<Integer> indexes;
        System.debug(objJsonEntries);
        for (PicklistEntryWrapper objJson : objJsonEntries){
            System.debug('objJson.validFo');
            System.debug(objJson.validFor);
            if (objJson.validFor==null || objJson.validFor==''){
                continue;
            }
            indexes = bitSetObj.testBits(objJson.validFor,controllingIndexes);
            for (Integer idx : indexes){                
                String contrValue = contrEntries[idx].getValue();
                TS_PicklistEntryWrapper pickW = new TS_PicklistEntryWrapper();
                pickW.label = objJson.label;
                pickW.value = objJson.value;
                
                TS_PicklistEntryWrapper controlField = objResults.get(contrValue);
                controlField.dependentPickList.add(pickW);
            }
        }
        objEntries = null;
        objJsonEntries = null;
        system.debug('objResults--->' + objResults);
        return objResults;
    }

	public class PicklistEntryWrapper{
		public String active { get; set; }
		public String defaultValue { get; set; }
		public String label { get; set; }
		public String value { get; set; }
		public String validFor { get; set; }
	}
}