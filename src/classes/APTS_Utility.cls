/**
 * Description: This apex class is utility class.
 * Created By - Ankit Shah
 * Created Date - 28th March, 2017
*/
public without sharing class APTS_Utility {
    
    /**
        This method will retrun all fields of provided object.
        @params -
        objectName - object api name
     */
    public static String getObjectFields(String objectName){

        String query;
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
    
            for(String fieldName : fieldMap.keyset()){
                if(String.isBlank(commaSepratedFields)){
                    commaSepratedFields = fieldName;
                }else{
                    commaSepratedFields = commaSepratedFields + ', ' + fieldName;
                }
            }
            query = commaSepratedFields;
            //query = 'select ' + commaSepratedFields + ' from ';
        } catch (System.Exception ex) {            
            system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
            query = '';
        }

        return query;
    } 
}