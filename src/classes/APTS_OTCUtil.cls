/*******************************************************************************************
Name            : APTS_OTCUtil 
Created By      : Amit
Created Date    : 02/19/2018
Description     : 
Test Class      : 
********************************************************************************************/
/*** PI fix # 190225****/
public without sharing class APTS_OTCUtil {

/*
Method: getsObjectAccess
Description: Method takes sObject name as String and returns if current user has Edit/ Create/ Delete access on passed sObject
             This is mandetory to check DML access on current user, before running any busniess logic that will lead to DML operation
*/ 
public static DescribeSObjectResult getsObjectAccess(string sObjectName){
    DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
    return objResult;
}

/*
Method: getRecordLevelAccess
Description: Method accepts Record Id and returns user’s access to a set of records or single record.
HasAllAccess; HasDeleteAccess; HasEditAccess; HasReadAccess ; HasTransferAccess; MaxAccessLevel.
Method is useful to access on custom build page, access of records can be hadled dynamically.
*/
public static map<string,UserRecordAccess> getRecordLevelAccess(set<string> recId){
    map<string,UserRecordAccess> mapRecAccess =  new map<string,UserRecordAccess>();
    list<UserRecordAccess> lstUsrAccess = new list<UserRecordAccess>();
    lstUsrAccess =  [SELECT HasAllAccess,HasDeleteAccess,HasEditAccess,HasReadAccess,recordId 
                     FROM UserRecordAccess where recordId IN :recId and userId=:Userinfo.getUserId()];
    if(!lstUsrAccess.isEmpty()){
        for(UserRecordAccess usr : lstUsrAccess){
            mapRecAccess.put(usr.recordId,usr);
        }
    } 
    return mapRecAccess;
}
/*
Method: describeFields
Description : Method accepts sobject name as string and returns description of field definition. Method can be used to 
get the picklist value of field dynamically or label of field is Accessable/ Creatable.
E.g Map<String, Schema.DescribeFieldResult>  fieldType = describeFields(String sObjectName);
fieldType.fieldType.get('FieldAPI').getType().name(); // returns the data type of field.
fieldType.get(FieldAPI).getPicklistValues(); // will return picklist field value.

*/
public static Map<String, Schema.DescribeFieldResult> describeFields(String sObjectName) {
    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<String>{sObjectName});
    Map<String, Schema.DescribeSObjectResult> childObjects = new Map<String, Schema.DescribeSObjectResult>();
    Map<String, Schema.DescribeFieldResult> fieldResults = new Map<String, Schema.DescribeFieldResult>();
    //describe object
    for(Schema.SObjectField field : results[0].fields.getMap().values()) {
        Schema.DescribeFieldResult fResult = field.getDescribe();
        fieldResults.put(fResult.getName().toLowerCase(), fResult);
    }
    return fieldResults;
}
/*
Method : getRecordTypeDetails
Description: Method accepts sObject as string and return record type for defined sObejct dynamically.
*/
 public  static map<string,Id> getRecordTypeDetails(string sObjName){
    
    Schema.DescribeSObjectResult sobjectResult = Schema.getGlobalDescribe().get(sObjName).getDescribe();
    
    Map<String,Id> mapofObjectRecordTypeNameandId = new Map<String,Id>();
    List<Schema.RecordTypeInfo> recordTypeInfo = new list<Schema.RecordTypeInfo>();
        recordTypeInfo = sobjectResult.getRecordTypeInfos();
    
    for(Schema.RecordTypeInfo info : recordTypeInfo){
        if(!info.getName().equalsIgnoreCase('Master'))
            mapofObjectRecordTypeNameandId.put(info.getName(),info.getRecordTypeId());
    }
    
    return mapofObjectRecordTypeNameandId;
}
/*
Method: getPicklistValues
Description: Method accepts sobject API and FieldAPI name as string and returns th picklist value for the defined field value.
*/
public static list<SelectOption> getPicklistValues (SObject obj, String fld)
{
    list<SelectOption> options = new list<SelectOption>();

    // Get the object type of the SObject.
    Schema.sObjectType objType = obj.getSObjectType();

     // Describe the SObject using its object type.
     Schema.DescribeSObjectResult objDescribe = objType.getDescribe();   

     // Get a map of fields for the SObject
     map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 

     // Get the list of picklist values for this field.
     list<Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();

     // Add these values to the selectoption list.
     for (Schema.PicklistEntry a : values)
     { 
        options.add(new SelectOption(a.getLabel(), a.getValue())); 
     }
     return options;
}

public class SelectOption {
    public SelectOption(String value, String label) {
        this.value = value;
        this.label = label;
        this.disabled = false;
        this.escapeItem = false;
    }

    public SelectOption(String value, String label, Boolean isDisabled) {
        this.value = value;
        this.label = label;
        this.disabled = isDisabled;
        this.escapeItem = false;
    }

    @AuraEnabled
    public String label { get;set; }
    @AuraEnabled
    public String value { get;set; }
    @AuraEnabled
    public Boolean disabled { get;set; }
    @AuraEnabled
    public Boolean escapeItem { get;set; }

}
public class sObjectAccess{
    public boolean isEdit;
    public boolean isCreatable;
    public boolean isDelete;
}
}