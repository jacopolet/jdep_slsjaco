global without sharing class APTS_SelloutDataForgotPassword {

    public APTS_SelloutDataForgotPassword() {

    }

    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
           
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            aura.redirect(checkEmailRef);
            return null;
        }
        catch (Exception ex) {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(),'Apex',ex.getStackTraceString(),'Site',null,'BIR',false,false,null,true);
            return ex.getMessage();
        }
    }
}