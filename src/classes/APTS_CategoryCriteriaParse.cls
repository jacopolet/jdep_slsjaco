/**
* Class Name : APTS_CategoryCriteriaParse 
* Description :  Apex Class used for parsing in APTS_VolumeAssumptionObligation Class
* Author : Vigitha
* Date Created : 04/16/2018
**/
public class APTS_CategoryCriteriaParse {
    public String sObjectName;
    public String sObjectLabel;
    public String searchText;
    public Filter filter;
    public List<String> fields;
    public String exprStr;

    public class Filter {
        public List<Predicates> predicates;
        public Boolean hasRHSFields;
        public String condExpr;
        public String childFilter;
    }

    public class Predicates {
        public Integer RowNum;
        public String RHSSObjectName;
        public String RHSFieldType;
        public String RHSFieldName;
        public String RHSFieldLabel;
        public String RHSChildFilterName;
        public String RefFieldName;
        public String OffsetValue;
        public String LHSSObjectName;
        public String LHSChildFilterName;
        public String FieldValue;
        public String FieldType;
        public String FieldName;
        public String FieldLabel;
        public String CompOper;
        public String BoolOper;
    }
    public static APTS_CategoryCriteriaParse parse(String jsonInput) {
        return (APTS_CategoryCriteriaParse) System.JSON.deserialize(jsonInput, APTS_CategoryCriteriaParse.class);
    }

}