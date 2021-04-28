public class APTS_SAPWSFunctions {

	public class HTTPS_Port {

		public String endpoint_x;
		public Map<String, String> inputHttpHeaders_x;
		public Map<String, String> outputHttpHeaders_x;
		public String clientCertName_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		public Integer timeout_x;
		private String[] ns_map_type_info = new String[] {'urn:sap-com:document:sap:rfc:functions', 'APTS_SAPWSStructure'};

		public APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element doATPSimulation(
		    String CONVERT_PARVW_AUART, APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN, APTS_SAPWSStructure.EXTENSIONIN_element EXTENSIONIN,
		    APTS_SAPWSStructure.MESSAGETABLE_element MESSAGETABLE, APTS_SAPWSStructure.ORDER_CCARD_element ORDER_CCARD, APTS_SAPWSStructure.ORDER_CCARD_EX_element ORDER_CCARD_EX,
		    APTS_SAPWSStructure.ORDER_CFGS_BLOB_element ORDER_CFGS_BLOB, APTS_SAPWSStructure.ORDER_CFGS_INST_element ORDER_CFGS_INST, APTS_SAPWSStructure.ORDER_CFGS_PART_OF_element ORDER_CFGS_PART_OF,
		    APTS_SAPWSStructure.ORDER_CFGS_REF_element ORDER_CFGS_REF, APTS_SAPWSStructure.ORDER_CFGS_VALUE_element ORDER_CFGS_VALUE, APTS_SAPWSStructure.ORDER_CONDITION_EX_element ORDER_CONDITION_EX,
		    APTS_SAPWSStructure.ORDER_INCOMPLETE_element ORDER_INCOMPLETE, APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN, APTS_SAPWSStructure.ORDER_ITEMS_OUT_element ORDER_ITEMS_OUT,
		    APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS, APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element ORDER_SCHEDULE_EX, APTS_SAPWSStructure.ORDER_SCHEDULE_IN_element ORDER_SCHEDULE_IN,
		    APTS_SAPWSStructure.PARTNERADDRESSES_element PARTNERADDRESSES) {

			APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element request_x = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element();
			request_x.CONVERT_PARVW_AUART = CONVERT_PARVW_AUART;
			request_x.ORDER_HEADER_IN = ORDER_HEADER_IN;
			request_x.EXTENSIONIN = EXTENSIONIN;
			request_x.MESSAGETABLE = MESSAGETABLE;
			request_x.ORDER_CCARD = ORDER_CCARD;
			request_x.ORDER_CCARD_EX = ORDER_CCARD_EX;
			request_x.ORDER_CFGS_BLOB = ORDER_CFGS_BLOB;
			request_x.ORDER_CFGS_INST = ORDER_CFGS_INST;
			request_x.ORDER_CFGS_PART_OF = ORDER_CFGS_PART_OF;
			request_x.ORDER_CFGS_REF = ORDER_CFGS_REF;
			request_x.ORDER_CFGS_VALUE = ORDER_CFGS_VALUE;
			request_x.ORDER_CONDITION_EX = ORDER_CONDITION_EX;
			request_x.ORDER_INCOMPLETE = ORDER_INCOMPLETE;
			request_x.ORDER_ITEMS_IN = ORDER_ITEMS_IN;
			request_x.ORDER_ITEMS_OUT = ORDER_ITEMS_OUT;
			request_x.ORDER_PARTNERS = ORDER_PARTNERS;
			request_x.ORDER_SCHEDULE_EX = ORDER_SCHEDULE_EX;
			request_x.ORDER_SCHEDULE_IN = ORDER_SCHEDULE_IN;
			request_x.PARTNERADDRESSES = PARTNERADDRESSES;
			APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response_x;
			Map<String, APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element> response_map_x = new Map<String, APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
			    this,
			    request_x,
			    response_map_x,
			    new String[] {endpoint_x,
			                  'http://sap.com/xi/WebService/soap1.1',
			                  'urn:sap-com:document:sap:rfc:functions',
			                  'BAPI_SALESORDER_SIMULATE',
			                  'urn:sap-com:document:sap:rfc:functions',
			                  'BAPI_SALESORDER_SIMULATE.Response',
			                  'APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element'
			                 }
			);
			response_x = response_map_x.get('response_x');
			return response_x;
		}
	}

	public class BAPI_SALESORDER_SIMULATE_Response_elementFuture extends System.WebServiceCalloutFuture {
		
		public APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element getValue() {
			
			APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element response = (APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element)System.WebServiceCallout.endInvoke(this);
			
			return response;
		}
	}

	public class AsyncHTTPS_Port {

		public String endpoint_x;
		public Map<String, String> inputHttpHeaders_x;
		public String clientCertName_x;
		public Integer timeout_x;
		private String[] ns_map_type_info = new String[] {'urn:sap-com:document:sap:rfc:functions', 'APTS_SAPWSStructure'};

		public APTS_SAPWSFunctions.BAPI_SALESORDER_SIMULATE_Response_elementFuture doAsyncATPSimulation(
		    System.Continuation continuation, String CONVERT_PARVW_AUART, APTS_SAPWSStructure.BAPISDHEAD ORDER_HEADER_IN,
		    APTS_SAPWSStructure.EXTENSIONIN_element EXTENSIONIN, APTS_SAPWSStructure.MESSAGETABLE_element MESSAGETABLE, APTS_SAPWSStructure.ORDER_CCARD_element ORDER_CCARD,
		    APTS_SAPWSStructure.ORDER_CCARD_EX_element ORDER_CCARD_EX, APTS_SAPWSStructure.ORDER_CFGS_BLOB_element ORDER_CFGS_BLOB, APTS_SAPWSStructure.ORDER_CFGS_INST_element ORDER_CFGS_INST,
		    APTS_SAPWSStructure.ORDER_CFGS_PART_OF_element ORDER_CFGS_PART_OF, APTS_SAPWSStructure.ORDER_CFGS_REF_element ORDER_CFGS_REF, APTS_SAPWSStructure.ORDER_CFGS_VALUE_element ORDER_CFGS_VALUE,
		    APTS_SAPWSStructure.ORDER_CONDITION_EX_element ORDER_CONDITION_EX, APTS_SAPWSStructure.ORDER_INCOMPLETE_element ORDER_INCOMPLETE, APTS_SAPWSStructure.ORDER_ITEMS_IN_element ORDER_ITEMS_IN,
		    APTS_SAPWSStructure.ORDER_ITEMS_OUT_element ORDER_ITEMS_OUT, APTS_SAPWSStructure.ORDER_PARTNERS_element ORDER_PARTNERS, APTS_SAPWSStructure.ORDER_SCHEDULE_EX_element ORDER_SCHEDULE_EX,
		    APTS_SAPWSStructure.ORDER_SCHEDULE_IN_element ORDER_SCHEDULE_IN, APTS_SAPWSStructure.PARTNERADDRESSES_element PARTNERADDRESSES) {
			
			APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element request_x = new APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_element();
			request_x.CONVERT_PARVW_AUART = CONVERT_PARVW_AUART;
			request_x.ORDER_HEADER_IN = ORDER_HEADER_IN;
			request_x.EXTENSIONIN = EXTENSIONIN;
			request_x.MESSAGETABLE = MESSAGETABLE;
			request_x.ORDER_CCARD = ORDER_CCARD;
			request_x.ORDER_CCARD_EX = ORDER_CCARD_EX;
			request_x.ORDER_CFGS_BLOB = ORDER_CFGS_BLOB;
			request_x.ORDER_CFGS_INST = ORDER_CFGS_INST;
			request_x.ORDER_CFGS_PART_OF = ORDER_CFGS_PART_OF;
			request_x.ORDER_CFGS_REF = ORDER_CFGS_REF;
			request_x.ORDER_CFGS_VALUE = ORDER_CFGS_VALUE;
			request_x.ORDER_CONDITION_EX = ORDER_CONDITION_EX;
			request_x.ORDER_INCOMPLETE = ORDER_INCOMPLETE;
			request_x.ORDER_ITEMS_IN = ORDER_ITEMS_IN;
			request_x.ORDER_ITEMS_OUT = ORDER_ITEMS_OUT;
			request_x.ORDER_PARTNERS = ORDER_PARTNERS;
			request_x.ORDER_SCHEDULE_EX = ORDER_SCHEDULE_EX;
			request_x.ORDER_SCHEDULE_IN = ORDER_SCHEDULE_IN;
			request_x.PARTNERADDRESSES = PARTNERADDRESSES;
			return (APTS_SAPWSFunctions.BAPI_SALESORDER_SIMULATE_Response_elementFuture) System.WebServiceCallout.beginInvoke(
			           this,
			           request_x,
			           APTS_SAPWSFunctions.BAPI_SALESORDER_SIMULATE_Response_elementFuture.class,
			           continuation,
			           new String[] {endpoint_x,
			                         'http://sap.com/xi/WebService/soap1.1',
			                         'urn:sap-com:document:sap:rfc:functions',
			                         'BAPI_SALESORDER_SIMULATE',
			                         'urn:sap-com:document:sap:rfc:functions',
			                         'BAPI_SALESORDER_SIMULATE.Response',
			                         'APTS_SAPWSStructure.BAPI_SALESORDER_SIMULATE_Response_element'
			                        }
			       );
		}
	}
}