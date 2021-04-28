/**
* @author        Catherine Kia Aragon
* @date          11.07.2019        
* @description   Generates Keys
* @revision(s)   N/A
*/
public class KeyGenerator {
    /**
    * @author        Catherine Kia Aragon
    * @date          11.07.2019        
    * @description   Generates GUID(Globally Unique Identifier) key
    * @revision(s)   N/A
    */
    public static String generateGUID(){
        Blob b = Crypto.generateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        return guid;
    }
}