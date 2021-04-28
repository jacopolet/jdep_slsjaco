public with sharing class APTS_CustomLookupController {

    @AuraEnabled
    public static List<sObject> getLookupResults(String objectName, String searchKeyword, String displayFieldName, String extraFields, String extraFilters, String prepopulateId) {
        String searchKey = '%' + searchKeyWord + '%';
        String displayFieldNameSafe = String.escapeSingleQuotes(displayFieldName);
        String extraFieldsSafe = String.isBlank(extraFields) ? null : String.escapeSingleQuotes(extraFields);
        String extraFiltersSafe = String.isBlank(extraFilters) ? 'Id != null' : extraFilters;
        String ObjectNameSafe = String.escapeSingleQuotes(objectName);

        String sQuery = 'SELECT Id, ' + displayFieldNameSafe;
        if (extraFieldsSafe != null) sQuery += ', ' + extraFieldsSafe;
        sQuery += ' FROM ' + ObjectNameSafe;
        if (prepopulateId == null) {
            sQuery += ' WHERE ' + displayFieldNameSafe + ' LIKE :searchKey AND ' + extraFiltersSafe + ' ORDER BY ' + displayFieldNameSafe + ' ASC LIMIT 10';
        } else {
            sQuery += ' WHERE Id = :prepopulateId';
        }

        System.debug(sQuery);
        return Database.query(sQuery);
    }
}