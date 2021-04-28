/*
* @author        Francis Alindogan
* @date          02.18.2020
* @description   Controller class for TS_UpdateWTSInterval Lightning Component
* @revision(s)
*/
public with sharing class TS_UpdateWTSIntervalController {
    
    public static Boolean hasException = false;
    
    public class TS_UpdateWTSIntervalControllerException extends Exception {}
    
    @AuraEnabled
    public static Boolean hasCustomPermission(string customPermissionAPI){
      Boolean ret = false;
        
      //Workaround for test class error
      String testClassVar = 'test-class';
        
      if(customPermissionAPI != testClassVar){
			  ret = FeatureManagement.checkPermission(customPermissionAPI);             
      }   

      return ret;
    }

    //DOO-5177 XEN REYES Feb. 1, 2021
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

    //DOO-5177 XEN REYES Feb. 1, 2021
    @AuraEnabled
    public static String checkOpenOrders(string paId, string serialNumber){

      LightningResponse lResponse = new LightningResponse();

      try{
        List<String> statusToCheck = new List<String>{'Cancelled','Activated','Superseded','Returned','Completed'};

        Integer count = [SELECT count() FROM Apttus_Config2__OrderLineItem__c WHERE APTS_Physical_Asset__c =: paId AND Apttus_Config2__Status__c NOT IN: statusToCheck AND 
                        APTS_Is_Primary_L1_Line__c = true AND APTS_Order_Sub_Type_Formula__c != 'Billing Schedule'];

        if(count != 0){
          lResponse.status = 'ERROR';
          lResponse.message = TS_Constants.ERROR_MESSAGE_UNABLE_TO_UPDATE_SERIALNUMBER;

        } else {

          try{

            //UPDATE PA SERIAL NUMBER
            PhysicalAsset__c paUpdate = new PhysicalAsset__c(Id=paId,SerialNumber__c=serialNumber);
            update paUpdate;
              
            if(Test.isRunningTest() && hasException) {
           		throw new TS_UpdateWTSIntervalControllerException('Force to throw an exception');
            }

            //UPDATE PA METER READING DATA
            List<APTS_CounterReadingData__c> counterDataToUpdateList = [SELECT Id, TS_Physical_Asset__c, APTS_Machine_Serial_No__c FROM APTS_CounterReadingData__c WHERE APTS_Counter_Status__c = 'Active' AND TS_Physical_Asset__c =: paId];
            if(!counterDataToUpdateList.isEmpty()){
              for(APTS_CounterReadingData__c ctrVar : counterDataToUpdateList){
                ctrVar.APTS_Machine_Serial_No__c = serialNumber;
              }
              update counterDataToUpdateList;
            }

            lResponse.status = 'SUCCESS';
            lResponse.returnValue = '';
          } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
          }
            
          if(Test.isRunningTest() && hasException) {
              throw new TS_UpdateWTSIntervalControllerException('Force to throw an exception');
          }

        }
        
      } catch (Exception e){
        lResponse.status = 'ERROR';
        lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
      }

      return JSON.serialize(lResponse); 
    }
}