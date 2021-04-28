/* Karen Hung 05.11.2019 DOO-2659
 * for lightning component
 */

public without sharing class TS_SyncToClickController {
    	    
    public class TS_SyncToClickControllerException extends Exception {}
    public static Boolean hasException = false;
    
    /*update product record based on existing lightning action*/
    @AuraEnabled
    public static String updateProduct(String recordId){
        CustomLogging.push('updateProduct', 'TS_SyncToClickController');
        Profile p = [select id,Name from Profile where id=:Userinfo.getProfileid()];	
        Boolean hasCustomPermission = FeatureManagement.checkPermission('TS_SyncProductToClick');
        LightningResponse lResponse = new LightningResponse();
        
        try{
            if(hasCustomPermission || p.Name == 'System Administrator'){
                
                Product2 product = [SELECT Id, Name, APTS_Material_Type__c FROM Product2 WHERE Id =:recordId];
                if(product.APTS_Material_Type__c == 'ZSPR' || product.APTS_Material_Type__c == 'ZSER'){
                    List<Product2> prodList = new List<Product2>();
                    for(Product2 prod : [SELECT ID,Confirmation__c,TS_SyncToClick__c FROM Product2 WHERE Id = :recordId]){
                        prod.Confirmation__c= 'Are you sure you want to re-trigger Click?';
                        prod.TS_SyncToClick__c = prod.TS_SyncToClick__c != null ? prod.TS_SyncToClick__c + 1 : 1;
                        prodList.add(prod);
                    }
                    
                    update prodList;
                    
                    lResponse.status = 'SUCCESS';
                    lResponse.message = 'Product successfully synced to Click';                    
                }else{
                    lResponse.status = 'ERROR';
                    lResponse.message = 'The material type of this product is not relevant for synchronization.';    
                }
                
            }else{
                lResponse.status = 'ERROR';
                lResponse.message = 'You are not allowed to update this record.';          
            }
            
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_SyncToClickControllerException('Unable to update the record. Please contact System Administrator.');
            }  
            
        }catch(Exception e){               
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();     
        }
        
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
}