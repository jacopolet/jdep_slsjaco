/**
 * Class Name: AssetLineItemSharingTriggerHandler
 * @author: Alvin Lomod
 * Date: 25-Oct-2017
 * Requirement: Trigger for Asset Line Item object; KASM-228
 * @description: Handles the functions to be executed by the trigger (Mainly for sharing access)
 *               Created by S&M Team
 *
 */
 
 public without sharing class AssetLineItemSharingTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newMap){

    } 
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        OnAfterInsertShareAssetLineItemToPartnerUser((List<Apttus_Config2__AssetLineItem__c>)newList);
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        OnAfterUpdateShareAssetLineItemToPartnerUser((List<Apttus_Config2__AssetLineItem__c>)newList, (Map<Id, Apttus_Config2__AssetLineItem__c>)oldMap);
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().AssetLineItemTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
     * Method Name: OnAfterInsertShareAssetLineItemToPartnerUser
     * @author: Alvin Lomod
     * Date: 25-Oct-2017
     * Requirement: KASM-228
     * @description: Give access to related partner users under Asset Line Item's Sold To Account
     *
     */
   
    public static void OnAfterInsertShareAssetLineItemToPartnerUser(List<Apttus_Config2__AssetLineItem__c> ALIlist){
        CustomLogging.push('OnAfterInsertShareAssetLineItemToPartnerUser', 'AssetLineItemSharingTriggerHandler');
        Set<Id> SoldToIds = new Set<Id>(); //related Account
        Map<Id, Account> SoldToMap;
        
        List<Apttus_Config2__AssetLineItem__c> ValidALI = new List<Apttus_Config2__AssetLineItem__c>(); //ALI with Sold To values
        Set<Id> PartnerAccSetIds = new Set<Id>();
        Map<Id, List<User>> MapAccIdToPartnerUserList = new Map<Id, List<User>>();
        
        system.debug(ALIlist);
        
        for(Apttus_Config2__AssetLineItem__c ali : ALIlist){
            SoldToIds.add(ali.Apttus_Config2__AccountId__c);
        }
        
        if(SoldToIds.size() > 0){
        
            //Query needed to check related account fields. '__r' cannot get the value of the field due to apex limitation
            if(Schema.sObjectType.Account.fields.Name.isAccessible() &&
               Schema.sObjectType.Account.fields.Id.isAccessible() &&
               Schema.sObjectType.Account.fields.IsPartner.isAccessible()){
                       
                SoldToMap = new Map<Id, Account>([SELECT Id, Name, IsPartner FROM Account WHERE Id in: SoldToIds]);
                system.debug(SoldToMap);
            }
            
            for(Apttus_Config2__AssetLineItem__c ali : ALIlist){
                //if Sold to Account is a enabled as partner, map ALI to Account and put account ids in set
                if(ali.Apttus_Config2__AccountId__c != null && SoldToMap.get(ali.Apttus_Config2__AccountId__c).IsPartner){
                    ValidALI.add(ali);
                    PartnerAccSetIds.add(ali.Apttus_Config2__AccountId__c);
                }            
            }                                   
        
        }
        
        if(PartnerAccSetIds.size() > 0){
            //List<Contact> PartnerContactList = [SELECT Id, AccountId, Name FROM Contact WHERE AccountId in: PartnerAccSetIds];
            
            //Get all partner users related to all partner accounts
            List<User> PartnerUserList = new List<User>();
            if(Schema.sObjectType.User.fields.ContactId.isAccessible() &&
               Schema.sObjectType.User.fields.Id.isAccessible() &&
               Schema.sObjectType.User.fields.Name.isAccessible()){
                   
                PartnerUserList = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name, Name FROM User WHERE Contact.AccountId in: PartnerAccSetIds];
            }
            system.debug('Partner User List :' + PartnerUserList);
            
            List<Apttus_Config2__AssetLineItem__Share> ALIshareList = new List<Apttus_Config2__AssetLineItem__Share>();
            Apttus_Config2__AssetLineItem__Share ALIshare;
            
            //Put all asset line item share record into one list
            try{
                
                system.debug('VALID ALI '+ ValidALI);
                for(Apttus_Config2__AssetLineItem__c ali : ValidALI){
                    
                    for(User u : PartnerUserList){
                        if(u.Contact.AccountId == ali.Apttus_Config2__AccountId__c){
                            
                            ALIshare = new Apttus_Config2__AssetLineItem__Share();
                            ALIshare.ParentId = ali.Id;
                            ALIshare.UserOrGroupId = u.Id;
                            ALIshare.AccessLevel = 'Read';
                            ALIshare.RowCause = Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c; //To distinguish the Sharing Reason
                            
                            ALIshareList.add(ALIshare);
                        }
                    }
                    
                    system.debug('ALIShare Current Size: ' + ALIshareList.size());
                
                }
                
                system.debug('ALIShare Total Size: ' + ALIshareList.size());
                
                //insert asset line item user sharing
                if(Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.ParentId.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.UserOrGroupId.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.AccessLevel.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.RowCause.isCreateable()){
                       
                    insert ALIshareList;
                }
            
            }catch(Exception ex){
            
                CustomLogging.debugException(ex);
                CustomLogging.pop();      
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                
            }
            
        }    
    
    } //End of OnAfterInsertShareAssetLineItemToPartnerUser
     
    /**
     * Method Name: OnAfterUpdateShareAssetLineItemToPartnerUser
     * @author: Alvin Lomod
     * Date: 26-Oct-2017
     * Requirement: KASM-228
     * @description: Give access to related partner users under Asset Line Item's Sold To Account if change. Revoke access to partner users of the previous Sold To Account. 
     *
     */
   
    public static void OnAfterUpdateShareAssetLineItemToPartnerUser(List<Apttus_Config2__AssetLineItem__c> ALIlist, Map<Id, Apttus_Config2__AssetLineItem__c> ALIoldMap){
        CustomLogging.push('OnAfterUpdateShareAssetLineItemToPartnerUser', 'AssetLineItemSharingTriggerHandler');   
        Set<Id> NewSoldToIds = new Set<Id>(); //related Account - new value
        Set<Id> OldSoldToIds = new Set<Id>(); //related Account - old value
        
        Map<Id, Account> OldandNewSoldToMap; //To only have one query
        Map<Id, Account> NewSoldToMap = new Map<Id, Account>();
        //Map<Id, Account> OldSoldToMap = new Map<Id, Account>();
        
        List<Apttus_Config2__AssetLineItem__c> NewValidALI = new List<Apttus_Config2__AssetLineItem__c>(); //ALI with Sold To values to CREATE sharing
        Set<Id> OldValidALI = new Set<Id>(); //ALI with Sold To values to REVOKE sharing
                
        Set<Id> NewPartnerAccSetIds = new Set<Id>();
        Set<Id> OldPartnerAccSetIds = new Set<Id>();
        Map<Id, List<User>> MapAccIdToPartnerUserList = new Map<Id, List<User>>();
        
        List<Apttus_Config2__AssetLineItem__Share> RevokeALISharingList = new List<Apttus_Config2__AssetLineItem__Share>(); //list of ALI Sharing to delete
        List<Apttus_Config2__AssetLineItem__Share> NewALIshareList = new List<Apttus_Config2__AssetLineItem__Share>(); //list of ALI Sharing to create
        
        system.debug(ALIlist);
        system.debug(ALIoldMap);
        
        for(Apttus_Config2__AssetLineItem__c ali : ALIlist){
            //Get new Sold To Account value
            if(ali.Apttus_Config2__AccountId__c != ALIoldMap.get(ali.Id).Apttus_Config2__AccountId__c){
                
                if(ali.Apttus_Config2__AccountId__c != null){
                    NewSoldToIds.add(ali.Apttus_Config2__AccountId__c);
                }
                
                //If Sold To Account has a prior value, get Account Id.
                if(ALIoldMap.get(ali.Id).Apttus_Config2__AccountId__c != null){
                    OldSoldToIds.add(ALIoldMap.get(ali.Id).Apttus_Config2__AccountId__c);
                }
            }         
        }
        
        if(NewSoldToIds.size() > 0 || OldSoldToIds.size() > 0){
            
            //Query needed to check related account fields. '__r' cannot get the value of the field due to apex limitation
            if(Schema.sObjectType.Account.fields.Name.isAccessible() &&
               Schema.sObjectType.Account.fields.Id.isAccessible() &&
               Schema.sObjectType.Account.fields.IsPartner.isAccessible()){
                       
                OldandNewSoldToMap = new Map<Id, Account>([SELECT Id, Name, IsPartner FROM Account WHERE Id in: NewSoldToIds OR Id in: OldSoldToIds]);              
                system.debug(OldandNewSoldToMap);
                
            }
            
            //Split old and new Sold To Account
            //Compile all NEW Sold To Account Id
            for(Apttus_Config2__AssetLineItem__c ali : ALIlist){
                //if Sold to Account is a enabled as partner
                if(ali.Apttus_Config2__AccountId__c != null && 
                   OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).IsPartner &&
                   NewSoldToIds.contains(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id)){
                    
                    NewSoldToMap.put(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id, OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c));
                    NewPartnerAccSetIds.add(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id);
                    NewValidALI.add(ali);

                }            
            }
            
            //Compile all OLD Sold To Account Id
            for(Apttus_Config2__AssetLineItem__c ali : ALIoldMap.values()){
                //if Sold to Account is a enabled as partner
                if(ali.Apttus_Config2__AccountId__c != null && 
                   OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).IsPartner &&
                   OldSoldToIds.contains(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id)){
                
                        //OldSoldToMap.put(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id, OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c));
                        OldPartnerAccSetIds.add(OldandNewSoldToMap.get(ali.Apttus_Config2__AccountId__c).Id);
                        OldValidALI.add(ali.Id);

                }            
            }
        
        }
        
        if(NewPartnerAccSetIds.size() > 0 || OldPartnerAccSetIds.size() > 0){
        
            //Get all partner users related to all partner accounts
            List<User> PartnerUserList = new List<User>();
            if(Schema.sObjectType.User.fields.ContactId.isAccessible() &&
               Schema.sObjectType.User.fields.Id.isAccessible() &&
               Schema.sObjectType.User.fields.Name.isAccessible()){
                   
                PartnerUserList = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name, Name FROM User WHERE Contact.AccountId in: NewPartnerAccSetIds OR Contact.AccountId in: OldPartnerAccSetIds];
            
            }
            system.debug('Partner User List :' + PartnerUserList);
            
            //** START ~~ REVOKE Access Code Chunk ~~ START **//
            
            if(OldPartnerAccSetIds.size() > 0 && PartnerUserList.size() > 0){
            
                Set<Id> RevokeAccessPartnerUserIds = new Set<Id>();
                For(User u : PartnerUserList){
                    if(OldPartnerAccSetIds.contains(u.Contact.AccountId)){
                        RevokeAccessPartnerUserIds.add(u.Id);
                    }
                }
                
                //Query all sharing from old account
                if(Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.ParentId.isAccessible() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.UserOrGroupId.isAccessible() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.AccessLevel.isAccessible() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.RowCause.isAccessible()){
                
                    RevokeALISharingList = [SELECT Id, ParentId, UserOrGroupId, RowCause FROM Apttus_Config2__AssetLineItem__Share WHERE UserOrGroupId in: RevokeAccessPartnerUserIds AND ParentId in: OldValidALI AND Rowcause =: Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c];
                    system.debug('Revoke Sharing List: '+ RevokeALISharingList);
                    
                    //delete DML is at try catch
                
                }
                
            }
            
            //** END ~~ REVOKE Access Code Chunk ~~ END **//
            
            //** START ~~ CREATE Access Code Chunk ~~ START **//
            
            if(NewPartnerAccSetIds.size() > 0 && PartnerUserList.size() > 0){
            
                List<User> TempUserList = new List<User>(); //temporary holder of PartnerUserList for mapping
                List<Id> NewPartnerAccListIds = new List<Id>(NewPartnerAccSetIds); //copy set values to list for easier index
                
                //Group partner users per Account
                system.debug(NewPartnerAccListIds.size());
                for(Integer i = 0; i < NewPartnerAccListIds.size(); i++){
                    
                    for(User u : PartnerUserList){
                        if(u.Contact.AccountId == NewPartnerAccListIds[i] && NewPartnerAccSetIds.contains(u.Contact.AccountId)){
                            TempUserList.add(u);
                        }
                    }
                    
                    //map partner account to list of user
                    MapAccIdToPartnerUserList.put(NewPartnerAccListIds[i], TempUserList);
                    system.debug('User List Size ' + TempUserList.size());
                    system.debug('Map Acc to User ' + i + ' : ' + 'Account Id ~~'+ NewPartnerAccListIds[i] + ' Values ~~ ' + MapAccIdToPartnerUserList.get(NewPartnerAccListIds[i]));
                    TempUserList = new List<User>();
                }
                                            
                system.debug('New VALID ALI '+ NewValidALI);
                Apttus_Config2__AssetLineItem__Share ALIshare;
                for(Apttus_Config2__AssetLineItem__c ali : NewValidALI){
                    
                    for(User u : MapAccIdToPartnerUserList.get(ali.Apttus_Config2__AccountId__c)){
                        ALIshare = new Apttus_Config2__AssetLineItem__Share();
                        ALIshare.ParentId = ali.Id;
                        ALIshare.UserOrGroupId = u.Id;
                        ALIshare.AccessLevel = 'Read';
                        ALIshare.RowCause = Schema.Apttus_Config2__AssetLineItem__Share.RowCause.Asset_Line_Item_Apex_Sharing__c; //To distinguish the Sharing Reason
                        
                        NewALIshareList.add(ALIshare);
                    }
                
                }
            
            }
            
            //** END ~~ CREATE Access Code Chunk ~~ END **//
            
            //Put all asset line item share record into one list
            try{
                
                //Delete sharing from old related account first
                if(Apttus_Config2__AssetLineItem__Share.sObjectType.getDescribe().isDeletable()){
                            
                    delete RevokeALISharingList;
                }
                
                //insert asset line item user sharing
                if(Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.ParentId.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.UserOrGroupId.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.AccessLevel.isCreateable() &&
                   Schema.sObjectType.Apttus_Config2__AssetLineItem__Share.fields.RowCause.isCreateable()){
                       
                    insert NewALIshareList;
                }
            }catch(Exception ex){
            
                CustomLogging.debugException(ex);
                CustomLogging.pop();      
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                
            }
        }
        
    }
 
 }