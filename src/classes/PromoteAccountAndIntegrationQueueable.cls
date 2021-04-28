public class PromoteAccountAndIntegrationQueueable implements Queueable{
    List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
    public PromoteAccountAndIntegrationQueueable (List<Apttus__APTS_Agreement__c> agreements) {
        if (agreements <> null) {
            this.agreeList = agreements;
        }
    }
    
    public void execute(QueueableContext context) {
        if (!agreeList.isEmpty()) {
            CustomLogging.push('PromoteAccountAndIntegration', 'SM_AgreementToAccount');
            
            Set<Id> AcctIds = new Set<Id>();
            Set<Id> AcctLocIds = new Set<Id>();
            Map<Id, Apttus__APTS_Agreement__c> errorMapId = new Map<Id,Apttus__APTS_Agreement__c>();
            
            for(Apttus__APTS_Agreement__c ag : agreeList){
                
                if(ag.APTS_Sold_To__c != null){ //Account field or Sold To field 
                    AcctIds.add(ag.APTS_Sold_To__c);
                    errorMapId.put(ag.APTS_Sold_To__c, ag);
                }
                
                if(ag.APTS_Bill_to_Party_Ingredients__c != null){ //Bill To Ingredients
                    AcctIds.add(ag.APTS_Bill_to_Party_Ingredients__c);
                    errorMapId.put(ag.APTS_Bill_to_Party_Ingredients__c, ag);
                }
                
                if(ag.APTS_Bill_to_Party_MachServ__c != null){ //Bill To Machine or Services
                    AcctIds.add(ag.APTS_Bill_to_Party_MachServ__c);
                    errorMapId.put(ag.APTS_Bill_to_Party_Ingredients__c, ag);
                }
                
                if(ag.APTS_Payer_Ingredients__c != null){ //Payer Ingredients
                    AcctIds.add(ag.APTS_Payer_Ingredients__c);
                    errorMapId.put(ag.APTS_Bill_to_Party_Ingredients__c, ag);
                }
                
                if(ag.APTS_Payer_Machines_Services__c != null){ //Payer Machine and Services
                    AcctIds.add(ag.APTS_Payer_Machines_Services__c);
                    errorMapId.put(ag.APTS_Bill_to_Party_Ingredients__c, ag);
                }
                
                if(ag.Apttus_CMConfig__LocationId__c != null){ //Location field (Account Location lookup)
                    AcctLocIds.add(ag.Apttus_CMConfig__LocationId__c);
                }
                
            }
            
            Id ProspectValidRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            Map<Id, Account> AcctMap;
            Map<Id, Apttus_Config2__AccountLocation__c> AccLocMap;
            if (Schema.sObjectType.Account.fields.Id.isAccessible() && Schema.sObjectType.Account.fields.SAP_Customer_ID__c.isAccessible() && Schema.sObjectType.Account.fields.RecordTypeId.isAccessible() && Schema.sObjectType.Account.fields.EPI_Field_Updated__c.isAccessible()) {
                AcctMap = new Map<Id, Account>([SELECT Id, SAP_Customer_ID__c, RecordTypeId, EPI_Field_Updated__c FROM Account WHERE RecordTypeId =: ProspectValidRTId AND SAP_Customer_ID__c = null AND Id in: AcctIds]);//(Id in: AgreeIdToSoldIdMap.values() OR Id in: AgreeIdToShipIdMap.values() OR Id in: AgreeIdToBillIdMap.values())]);
            }
            if (Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.Id.isAccessible() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.Shipping_Address_Validation_Code__c.isAccessible() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.Copy_of_Parent_Account__c.isAccessible() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.SAP_Customer_ID__c.isAccessible() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.RecordTypeId.isAccessible() && Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.EPI_Field_Updated__c.isAccessible()) {
                AccLocMap = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Shipping_Address_Validation_Code__c, Copy_of_Parent_Account__c, SAP_Customer_ID__c, RecordTypeId, EPI_Field_Updated__c FROM Apttus_Config2__AccountLocation__c WHERE Shipping_Address_Validation_Code__c != null AND SAP_Customer_ID__c =: null AND Copy_of_Parent_Account__c = FALSE AND Id in: AcctLocIds]); //AgreeIdToALocIdMap.values()]);
            }
            system.debug('AcctMap~ ' + AcctMap);
            system.debug('AccLocMap~ ' + AccLocMap);
            
            List<Integration_Log__c> iLogToInsert = new List<Integration_Log__c>();
            List<Account> AcctToUpdateRT = new List<Account>();
            List<Apttus_Config2__AccountLocation__c> AcctLocToUpdateRT = new List<Apttus_Config2__AccountLocation__c>();
            
            if(!AcctMap.isEmpty()){
                
                for(Apttus__APTS_Agreement__c ag : agreeList){
                    
                    //If condition is to determine if the same account is used for other account lookup field. Create one Integration Log for each same account used.
                    //Sold To or Account
                    if(ag.APTS_Sold_To__c != null){
                        if(AcctMap.get(ag.APTS_Sold_To__c) != null){
                            iLogToInsert.add(SM_AccountUtil.CreateIntegrationLogForAgreementAcc(ag.Id, AcctMap.get(ag.APTS_Sold_To__c).Id));
                            system.debug('Success ILOG for Sold To');
                            AcctToUpdateRT.add(AcctMap.get(ag.APTS_Sold_To__c));
                        }                   
                        
                    }
                    
                    //Bill To Ingredients
                    if(ag.APTS_Bill_to_Party_Ingredients__c != null && ag.APTS_Bill_to_Party_Ingredients__c != ag.APTS_Sold_To__c){
                        if(AcctMap.get(ag.APTS_Bill_to_Party_Ingredients__c) != null){
                            iLogToInsert.add(SM_AccountUtil.CreateIntegrationLogForAgreementAcc(ag.Id, AcctMap.get(ag.APTS_Bill_to_Party_Ingredients__c).Id));
                            system.debug('Success ILOG for Bill To Payer');
                            AcctToUpdateRT.add(AcctMap.get(ag.APTS_Bill_to_Party_Ingredients__c));
                        }                   
                        
                    }
                    
                    //Bill To Machine and Service
                    if(ag.APTS_Bill_to_Party_MachServ__c != null && ag.APTS_Bill_to_Party_MachServ__c != ag.APTS_Sold_To__c && ag.APTS_Bill_to_Party_MachServ__c != ag.APTS_Bill_to_Party_Ingredients__c){
                        if(AcctMap.get(ag.APTS_Bill_to_Party_MachServ__c) != null){
                            iLogToInsert.add(SM_AccountUtil.CreateIntegrationLogForAgreementAcc(ag.Id, AcctMap.get(ag.APTS_Bill_to_Party_MachServ__c).Id));
                            system.debug('Success ILOG for Bill To Machine & Service');
                            AcctToUpdateRT.add(AcctMap.get(ag.APTS_Bill_to_Party_MachServ__c));
                        }                   
                        
                    }
                    
                    //Payer Ingredients
                    if(ag.APTS_Payer_Ingredients__c != null && ag.APTS_Payer_Ingredients__c != ag.APTS_Sold_To__c && ag.APTS_Payer_Ingredients__c != ag.APTS_Bill_to_Party_Ingredients__c && ag.APTS_Payer_Ingredients__c != ag.APTS_Bill_to_Party_MachServ__c){
                        if(AcctMap.get(ag.APTS_Payer_Ingredients__c) != null){
                            iLogToInsert.add(SM_AccountUtil.CreateIntegrationLogForAgreementAcc(ag.Id, AcctMap.get(ag.APTS_Payer_Ingredients__c).Id));
                            system.debug('Success ILOG for Payer Ingredients');
                            AcctToUpdateRT.add(AcctMap.get(ag.APTS_Payer_Ingredients__c));
                        }                   
                        
                    }
                    
                    //Payer Machine and Service
                    if(ag.APTS_Payer_Machines_Services__c != null && ag.APTS_Payer_Machines_Services__c != ag.APTS_Sold_To__c && ag.APTS_Payer_Machines_Services__c != ag.APTS_Bill_to_Party_Ingredients__c && ag.APTS_Payer_Machines_Services__c != ag.APTS_Bill_to_Party_MachServ__c && ag.APTS_Payer_Machines_Services__c != ag.APTS_Payer_Ingredients__c){
                        if(AcctMap.get(ag.APTS_Payer_Machines_Services__c) != null){
                            iLogToInsert.add(SM_AccountUtil.CreateIntegrationLogForAgreementAcc(ag.Id, AcctMap.get(ag.APTS_Payer_Machines_Services__c).Id));
                            system.debug('Success ILOG for Payer Machine & Service');
                            AcctToUpdateRT.add(AcctMap.get(ag.APTS_Payer_Machines_Services__c));
                        }                   
                        
                    }
                    
                    //Create account location iLog
                    if(ag.Apttus_CMConfig__LocationId__c != null){
                        if(AccLocMap.get(ag.Apttus_CMConfig__LocationId__c) != null){
                            iLogToInsert.add(SM_AccountLocationUtil.CreateIntegrationLogForAgreement(ag.Id, AccLocMap.get(ag.Apttus_CMConfig__LocationId__c).Id));
                            system.debug('Success ILOG for Location');
                            AcctLocToUpdateRT.add(AccLocMap.get(ag.Apttus_CMConfig__LocationId__c));
                        }
                    }
                    
                }
                
            }//End of AcctMap
            
            try{
                
                if(!AcctToUpdateRT.isEmpty()){
                    
                    Id PromoRequestRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
                    for(Account a : AcctToUpdateRT){
                        a.RecordTypeId = PromoRequestRTId;
                        a.EPI_Field_Updated__c = true;
                        a.Promote_to_Customer_By__c = UserInfo.getUserId();
                        a.Promoted_to_Customer_at__c = datetime.now();
                    }
                    
                    if (Schema.sObjectType.Account.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Account.fields.EPI_Field_Updated__c.isUpdateable()) {
                        update AcctToUpdateRT;
                    }            
                }//End of AcctUpdate List
                
                if(!AcctLocToUpdateRT.isEmpty()){
                    
                    Id PromoRequestRTId = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
                    for(Apttus_Config2__AccountLocation__c al : AcctLocToUpdateRT){
                        al.RecordTypeId = PromoRequestRTId;
                        al.EPI_Field_Updated__c = true;
                    }
                    
                    
                    if (Schema.sObjectType.Apttus_Config2__AccountLocation__c.fields.RecordTypeId.isUpdateable()) {
                        update AcctLocToUpdateRT;
                    }                               
                }//End of AcctLoc List
                
                if(!iLogToInsert.isEmpty()){
                    if (Schema.sObjectType.Integration_Log__c.fields.Object_Id__c.isCreateable() && Schema.sObjectType.Integration_Log__c.fields.Object__c.isCreateable() &&
                        Schema.sObjectType.Integration_Log__c.fields.Account__c.isCreateable() && Schema.sObjectType.Integration_Log__c.fields.Integration_Status__c.isCreateable() &&
                        Schema.sObjectType.Integration_Log__c.fields.Agreement__c.isCreateable()) {
                            insert iLogToInsert;
                        }
                }
                
            }
            catch(Exception ex)
            {     
                CustomLogging.debugException(ex);
                CustomLogging.pop();      
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                if(ex.getTypeName() == 'System.DMLException'){
                    //errorMapId.get(dmlex.getDmlId(0)).addError('Error');
                    //DMLException dmlex = new DMLException();
                    //dmlex.setMessage('Error :S');
                    throw ex;
                }
                //Apttus__APTS_Agreement__c ErrorOnAgree = agreeList[0];
                //AcctToUpdateRT[0].addError('Error');
                
            }
        }
    }
}