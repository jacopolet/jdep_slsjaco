/*
 * @Author: Amit
 * @Description : Class to save the field values edit from VF page APTS_udpateFieldSet using 
 * 				  APTS_CustomPLIFieldSetupdate Fieldset on PLI object 
 * Version :v1
 * */
public without sharing class APTS_updateFieldsFromFieldSet {
    
    public Apttus_Config2__PriceListItem__c obj{get;set;}
    
    public APTS_updateFieldsFromFieldSet(ApexPages.StandardController sc){
        //Instead of instanciating a new object, use the existing record from the Standard Controller
        obj = (Apttus_Config2__PriceListItem__c)sc.getRecord();
        
    }
    
    //Alternatively, if there is no extra logic in customSave, you could remove this, and call
    //The StandardController's save method instead.
    public PageReference save(){
        Database.SaveResult results = Database.update(obj, false);
        if(!results.isSuccess()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,string.valueOf(results.errors)));
            return null;
        }
        else{
            return new PageReference('/'+results.getId());
        }
        
            
    }
}