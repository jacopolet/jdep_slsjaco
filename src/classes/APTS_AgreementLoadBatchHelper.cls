/*************************************************************
@Name: APTS_AgreementLoadBatchHelper
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Helper class for Agreement loader batch process. 
@UsedBy: APTS_AgreementLoadBatch
******************************************************************/
public class APTS_AgreementLoadBatchHelper {

  //Calculate price for product configuration
  public static void repriceProductConfigurations(List<Apttus_Config2__ProductConfiguration__c> lstProductConfig, Boolean apiToUse, Integer timesPricing){
    //Variables declaration
    List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
    Boolean hasPendingItems;
    Savepoint savePnt;
    Apttus_CPQApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO;
    Apttus_CpqApi.CPQ.UpdatePriceResponseDO result;
    Apttus_CpqApi.CPQ.FinalizeCartRequestDO request;
    Apttus_CpqApi.CPQ.FinalizeCartResponseDO response;
    Apttus_Config2.CPQStruct.PricePendingInfo pricingInfo;
    Id cartId;
    Integer counter;

    // c)  For each agreement get configuration
    if(lstProductConfig.size() > 0){
      for(Apttus_Config2__ProductConfiguration__c currentConfig : lstProductConfig){
        savePnt = Database.setSavepoint();
        try{
          if(apiToUse){
            //d)  Get pricing for configuration
            hasPendingItems = true;
            cartId =currentConfig.Id;

            system.debug(Logginglevel.ERROR,'Limits before start pricing::::::' + getLimits());
            
            // create the update price request
            objUpdatePriceRequestDO = new Apttus_CPQApi.CPQ.UpdatePriceRequestDO();
            
            // add request parameters
            objUpdatePriceRequestDO.CartId = cartId;

            counter = 0;

            do{
              // update price for the cart
              result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);

              hasPendingItems = result.IsPricePending;

              system.debug(Logginglevel.ERROR,'Limits after pricing::::::' + getLimits());

              if(!hasPendingItems){
                break;
              }else{
                counter++;
              }            
            }while(counter < timesPricing);
          }else{
            counter = 0;

            system.debug(Logginglevel.ERROR,'Limits before start pricing::::::' + getLimits());
            
            do{
              pricingInfo = Apttus_Config2.PricingWebService.updatePriceForCart(currentConfig.Id);
              system.debug(Logginglevel.ERROR,'Pricing result::::::' + pricingInfo);
              system.debug(Logginglevel.ERROR,'Limits after pricing::::::' + getLimits());
              if(!pricingInfo.IsPricePending && !pricingInfo.IsTotalPricePending){
                break;
              }else{
                counter++;
              }
            }while(counter < timesPricing);            
          }
          
        }Catch(Exception e){
          Database.rollback(savePnt);
          system.debug(Logginglevel.ERROR,'Exception repriceProductConfigurations:::::' + e.getMessage() + '<>' +  e.getStackTraceString());
          lstErrorLogs.add(createBatchErrorObject(e, currentConfig.Id, 'Apttus_Config2__ProductConfiguration__c','Reprice product config batch error'));
          continue;
        }
      }

      //Log errors
      if(lstErrorLogs.size() > 0){
        createBatchErrorLogs(lstErrorLogs);
      }
    }
  }

  //Calculate price for line items
  public static void repriceLineItems(List<Apttus_Config2__LineItem__c> lstLineItems){
    //Variables declaration
    List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
    Boolean pricingResult;
    Savepoint savePnt;

    //For each line item reprice
    if(lstLineItems.size() > 0){
      for(Apttus_Config2__LineItem__c currentLI : lstLineItems){
        savePnt = Database.setSavepoint();
        try{
          system.debug(Logginglevel.ERROR,'currentLI::::::' + currentLI.Id);
          system.debug(Logginglevel.ERROR,'Limits before start pricing::::::' + getLimits());
          
          pricingResult = Apttus_Config2.PricingWebService.computeBasePriceForItemColl(currentLI.Apttus_Config2__ConfigurationId__c, Integer.ValueOf(currentLI.Apttus_Config2__LineNumber__c));
            
          system.debug(Logginglevel.ERROR,'Pricing result::::::' + pricingResult);
          system.debug(Logginglevel.ERROR,'Limits after pricing::::::' + getLimits());
        }Catch(Exception e){
          Database.rollback(savePnt);
          system.debug(Logginglevel.ERROR,'Exception repriceLineItems:::::' + e.getMessage() + '<>' +  e.getStackTraceString());
          lstErrorLogs.add(createBatchErrorObject(e, currentLI.Id, 'Apttus_Config2__LineItem__c','Reprice line item batch error'));
          continue;
        }
      }

      //Log errors
      if(lstErrorLogs.size() > 0){
        createBatchErrorLogs(lstErrorLogs);
      }
    }
  }

  //Calculate totals for product configurations
  public static void processProductConfigurations(List<Apttus_Config2__ProductConfiguration__c> lstProductConfig, Boolean apiToUse){
    //Variables declaration
    List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
    Integer listIndex = 0;
    Set<Id> setAgreementsIdUpdate = new Set<Id>();
    Id cartId;
    Boolean pricingCartResult;

    if(lstProductConfig.size() > 0){
      for(Apttus_Config2__ProductConfiguration__c currentConfig : lstProductConfig){
        try{
          pricingCartResult = true;

          //system.debug(Logginglevel.ERROR,'currentConfig:::::' + currentConfig.Id);
          
          //13/09: Rahul to remove Cart Total API call from finalize job.
          //if(apiToUse){
           // pricingCartResult = Apttus_Config2.PricingWebService.computeTotalPriceForCart(currentConfig.Id);
         // }

          //system.debug(Logginglevel.ERROR,'pricingCartResult:::::' + pricingCartResult);
          
          //if(pricingCartResult){
            //e)  Finalize pricing configuration
                  // finalize the cart if the cart has no pending items for pricing
                  // Apttus_Config2.CPQWebService.finalizeConfiguration(currentConfig.Id); SAI SAGAR - SEP 10th 2018 - COMMENTED AS WE ARE USING NEW API PROVIDED BY APTTUS
                 //Apttus_CMConfig.CMConfigWebService.finalizeConfiguration(currentConfig.Id);   [RG]: 27/08/2018 -- Comented the code as we are not using this API.
                  //Agreements to update
                system.debug(Logginglevel.ERROR,'currentConfig:::::' + currentConfig.Id);
                 
                Apttus_CpqApi.CPQ.FinalizeCartRequestDO request = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
                request.CartId = currentConfig.Id;
                Apttus_CpqApi.CPQ.FinalizeCartResponseDO response = Apttus_CpqApi.CPQWebService.finalizeCart(request);               
                                  
                setAgreementsIdUpdate.add(currentConfig.Apttus_CMConfig__AgreementId__c);
          //}          
        }Catch(Exception e){
          system.debug(Logginglevel.ERROR,'Exception processAgreements:::::' + e.getMessage() + '<>' +  e.getStackTraceString());
          lstErrorLogs.add(createBatchErrorObject(e, currentConfig.Id,'Apttus_Config2__ProductConfiguration__c','Product config finalization batch error'));
          continue;
        }
        listIndex++;
      }

      //f)  Activate agreements b
      if(setAgreementsIdUpdate.size() > 0){
        updateAgreementList(setAgreementsIdUpdate,lstErrorLogs);
      }

      //Log errors
      if(lstErrorLogs.size() > 0){
        createBatchErrorLogs(lstErrorLogs);
      }
    }
  }

  public static void createCERRecords(List<Apttus__APTS_Agreement__c> lstAgreements){
    //Variables declaration
    List<APTS_Error_Object__c> lstErrorLogs = new List<APTS_Error_Object__c>();
    List<Apttus__APTS_Agreement__c> lstAgreementsToUpdate = new List<Apttus__APTS_Agreement__c>();

    for(Apttus__APTS_Agreement__c currentAgreement : lstAgreements){
      try{
        APTS_ManageCER.manageCERRecords(new List<Apttus__APTS_Agreement__c>{currentAgreement},'Agreement','Update');
        lstAgreementsToUpdate.add(currentAgreement);
      }catch(Exception e){
        lstErrorLogs.add(createBatchErrorObject(e, '', 'Apttus__APTS_Agreement__c','CER records batch creation error'));
      }      
    }

    //Update flag in agreements
    if(lstAgreementsToUpdate.size() > 0){
      for(Apttus__APTS_Agreement__c currentAgreement : lstAgreementsToUpdate){
        currentAgreement.APTS_CER_Batch_Executed__c = true;
      }

      update lstAgreementsToUpdate;
    }
  }

  public static void modifyTriggers(Set<String> setTriggers,String action){
    //Get the list of triggers    
    String tempFields = '';

    for(String current : setTriggers){
      tempFields += current + ',';
    }

    String fields = tempFields.removeEnd(',');

    //Get trigger configuration
    Id userProfileId = userinfo.getProfileId();
    
    // If the Entry for Current User is in Trigger Settings Assing Current UserId
    if(TriggerSettings__c.getInstance() != null && TriggerSettings__c.getInstance().Id != null){
        userProfileId = TriggerSettings__c.getInstance().SetupOwnerId;
    }
    
    String query;

    if(Test.isRunningTest()){
      query = 'SELECT ' + fields + ' FROM TriggerSettings__c LIMIT 1 ';
    }else{
      query = 'SELECT ' + fields + ' FROM TriggerSettings__c WHERE SetupOwnerId = :userProfileId LIMIT 1 ';
    }

    TriggerSettings__c  obj = Database.query(query);

    if(obj != null){
      //Determine action to take on triggers : activate - deactivate
      Boolean value = 'Activate'.equals(action) ? true : false;

      for(String current : setTriggers){
        obj.put(current,value);
      }
      update obj;
    }    
  }

  public static void createBatchErrorLogs(List<APTS_Error_Object__c> lstErrorLogs){
    insert lstErrorLogs;
  }

  public static void updateAgreementList(Set<Id> setAgreementIdUpdate,List<APTS_Error_Object__c> lstErrorLogs){
    //Get agreements info
    List<Apttus__APTS_Agreement__c> lstAgreementsUpdate =
    [
      SELECT Id, Apttus__Status__c, 
      Apttus__Status_Category__c,
      APTS_AgreementBatchLoadExecuted__c
      FROM Apttus__APTS_Agreement__c
      WHERE Id IN :setAgreementIdUpdate
    ];

    for(Apttus__APTS_Agreement__c currentAgreement : lstAgreementsUpdate){
      //Activate agreements
      currentAgreement.Apttus__Status__c = 'Activated';
      currentAgreement.Apttus__Status_Category__c = 'In Effect';

          //Mark batch successful execution
          currentAgreement.APTS_AgreementBatchLoadExecuted__c = true;
    }

    Database.SaveResult[] srList = Database.update(lstAgreementsUpdate, false);

    // Iterate through each returned result
    for (Database.SaveResult sr : srList) {
        if (sr.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully updated agreement. Agreement Id: ' + sr.getId());
        }
        else {
            // Operation failed, so get all errors                
            for(Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');                    
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Account fields that affected this error: ' + err.getFields());

                lstErrorLogs.add(new APTS_Error_Object__c(
                                    APTS_Error_Date__c = System.today(),
                                    APTS_Error_Description__c = 'Error updating Account, product config finalization batch',
                                    APTS_Error_Level__c = 'Error',
                                    APTS_Error_Name__c = 'APTS_AgreementLoadBatchHelper',
                                    APTS_Parent_ID__c = sr.getId(),
                                    APTS_Stream__c = 'CLM',
                                    APTS_Parent_Object_Name__c = 'Apttus__APTS_Agreement__c',
                                    APTS_Description_Of_Error__c = err.getStatusCode() + ': ' + err.getMessage()
                                  ));
            }
        }
    }    
  }

  public static APTS_Error_Object__c createBatchErrorObject(Exception e, Id parentId,String objectName,String errorDescription){
    String errorMessage = e.getMessage() + '<>' +  e.getStackTraceString();
    return new APTS_Error_Object__c(
      APTS_Error_Date__c = System.today(),
      APTS_Error_Description__c = errorDescription,
      APTS_Error_Level__c = 'Error',
      APTS_Error_Name__c = 'APTS_AgreementLoadBatchHelper',
      APTS_Parent_ID__c = parentId,
      APTS_Stream__c = 'CLM',
      APTS_Parent_Object_Name__c = objectName,
      APTS_Description_Of_Error__c = errorMessage.length() > 32768 ? errorMessage.substring(0,32768) : errorMessage
    );
  }

  static private string getLimits(){        
        string limitstring = '';        
        limitstring += 'Query Limits: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
        limitstring += 'DML Rows Limits: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';
        limitstring += 'Heap Size Limits: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
        limitstring += 'Query Return Limits: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';      
        limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
        limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();    
        limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();
        limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
        limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();    
        limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();     
        limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();     
        
        return limitstring;
        
    }
           
}