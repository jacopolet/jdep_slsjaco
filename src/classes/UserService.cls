public inherited sharing class UserService {
	public static Boolean recordTypeNotServiceProvider(Account acct) {
		Boolean accountNotServiceProvider = false;
		if (acct.RecordTypeId != SM_Constants.recordTypeIdAccountServiceProvider) {
			accountNotServiceProvider = true;
		}
		return accountNotServiceProvider;
	}
}