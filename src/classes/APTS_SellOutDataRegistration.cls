global without sharing class APTS_SellOutDataRegistration 
{
    public static Id customerAccountId;
    public static final string JDECUSTOMERCOMMUNITY = System.Label.JDE_Customer_Community;
    public APTS_SellOutDataRegistration() {
        system.debug('APTS_SellOutDataRegistration--');
    }

    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        system.debug('confirmpassword--');
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        system.debug('container Enabled--');
        Auth.AuthConfiguration authConfig;
        try{
            authConfig = new Auth.AuthConfiguration(communityUrl,'');
            system.debug('authConfig.isCommunityUsingSiteAsContainer()--'+ authConfig.isCommunityUsingSiteAsContainer());
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', null, 'BIR', false, false, null, true);}
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        system.debug('validate password--');
        try{
            if(!Test.isRunningTest()) {
                Site.validatePassword(u, password, confirmPassword);
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', null, 'BIR', false, false, null, true);}
        return;
    }
    
    @AuraEnabled
    public static String selfRegister(String firstname, String lastname, String email, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword){
        Savepoint sp = null;
        String emailid = null;
        
        try {
            sp = Database.setSavepoint();
            
            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }
            
            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }
            
            Account account = [select Id, Name from Account where SAP_Customer_ID__c =:accountId ];
            Profile communityProfile = [SELECT Id FROM PROFILE WHERE Name =: JDECUSTOMERCOMMUNITY ];
            customerAccountId = account.Id;
            String url = String.valueof(System.URL.getSalesforceBaseURL().gethost());
            String domainname = url.substringBefore('-');
            if(String.isNotBlank(domainname))
                {
                   emailid = email + '.' + domainname;
                }else{
                        emailid = email;
                     }
            
            User portalUser = new User();
            portalUser.Username = emailid;
            portalUser.put('Email',email);
            portalUser.FirstName = firstname;
            portalUser.LastName = lastname;
            portalUser.ProfileId = communityProfile.Id;
            portalUser.CommunityNickname = firstname.substring(0,1)+ lastname;
            String networkId = Network.getNetworkId();
            
            
            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null && siteAsContainerEnabled(Network.getLoginUrl(networkId))) {
                portalUser.put('UserPreferencesHideS1BrowserUI',true);
            }
            
            system.debug('user--'+ portalUser);
            
            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    portalUser.put(sof, thisField.get('value'));
                }
            }
            system.debug('includePassword--'+ includePassword);          
            if (includePassword) {    
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
                validatePassword(portalUser, password, confirmPassword);
            }
            else {
                password = null;
            }
            
            system.debug(portalUser);
            system.debug('customerAccountId '+ accountId);
            system.debug(password);
            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId = Site.createPortalUser(portalUser, customerAccountId, password);
            system.debug('userId --'+ userId );
            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';           
            }
            if (userId != null) { 
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                        aura.redirect(lgn);
                    }
                }
                else {
                    ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                        aura.redirect(confirmRef);
                    }
                    
                }
            }
            return null;
        }
        catch (Exception ex) {
            system.debug('exception--'+ ex);
            system.debug('line #'+ ex.getLineNumber());
            Database.rollback(sp);
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', null, 'BIR', false, false, null, true);
            return ex.getMessage();            
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        try{
            if(!Test.isRunningTest()) {
                if (fieldSet != null) {
                    for (Schema.FieldSetMember f : fieldSet.getFields()) {
                        Map<String, Object> fieldDetail = new Map<String, Object>();
                        fieldDetail.put('dbRequired', f.getDBRequired());
                        fieldDetail.put('fieldPath', f.getFieldPath());
                        fieldDetail.put('label', f.getLabel());
                        fieldDetail.put('required', f.getRequired());
                        fieldDetail.put('type', f.getType());
                        fieldDetail.put('value', '');   // client will populate
                        extraFields.add(fieldDetail);
                    }}}
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', null, 'BIR', false, false, null, true);}
        return extraFields;
    }
    @AuraEnabled
    global static boolean validateSAPId(string SAPId){
        system.debug('SAPId == > '+SAPId);
        boolean validuser = false;
        try{
            if(string.isNotBlank(SAPId)){
                list<Account> lstAcc = [select Id, Name from Account where SAP_Customer_ID__c =:SAPId ];
                if(!lstAcc.isEmpty()){
                    validuser = true;
                    customerAccountId = lstAcc[0].Id;
                    system.debug('customerAccountId --'+ customerAccountId );
                }
            } 
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', null, 'BIR', false, false, null, true);}   
        return validuser;
    }
}