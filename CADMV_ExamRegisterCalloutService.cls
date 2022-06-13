public with sharing class CADMV_ExamRegisterCalloutService {

    

    @InvocableMethod(label='Send Exam Details' description='Send Exam Registartion Details to AKTE')

    public static List<String> sendExamDetails(List<flowOutput> registrationDetails){

        String finRequestBody = CADMV_AppConstants.NULL_EMPTY_STRING;

        List<String> finalMessageFlow = new List<String>();

		List<String> futureCalloutInput = new List<String>();

        try{

        if(!registrationDetails.isEmpty()){

            CADMV_ExamRegistrationReqWrapper finalReqWrap = generateExamData(registrationDetails);

            finRequestBody = JSON.serialize(finalReqWrap);

			futureCalloutInput.add(finRequestBody);

			futureCalloutInput.add(registrationDetails.get(0).personExamId);

            examRegistrationCallout(futureCalloutInput);

            

        }

        }catch(Exception ex){

            system.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

        return finalMessageFlow;

    }

    public static CADMV_ExamRegistrationReqWrapper generateExamData(List<flowOutput> registrationDetails){

        CADMV_ExamRegistrationReqWrapper wrapObj = new CADMV_ExamRegistrationReqWrapper();

        List<CADMV_ExamRegistrationReqWrapper.ExamHistList> examWrpList = new List<CADMV_ExamRegistrationReqWrapper.ExamHistList> ();

		CADMV_ExamRegistrationReqWrapper.ExamHistList examWrp = new CADMV_ExamRegistrationReqWrapper.ExamHistList ();

        if(registrationDetails !=null){

                wrapObj.aliceAppId = registrationDetails.get(0).driverLicenseNumber;

                

                Date contactDOB = registrationDetails.get(0).contactDOB;

                

                wrapObj.dob = String.valueOf(contactDOB.month())+'/'+String.valueOf(contactDOB.day())+'/'+String.valueOf(contactDOB.year());

                wrapObj.firstName = registrationDetails.get(0).contactFN;

                wrapObj.lastName = registrationDetails.get(0).contactLN;

                wrapObj.state = registrationDetails.get(0).contactState;

                examWrp.easeTestId = 'X1';

                examWrp.easeStatusIndicator = '1';

                examWrpList.add(examWrp);

                wrapObj.examHistList = examWrpList;

        }

        return wrapObj;

    }

    public static void createCustomNotification(String personExamId,String calloutResult){

        PersonExamination personExamObj = [

            SELECT ContactId,ExaminationId,Examination.Name,CADMV_Business_License_Application__c,

                CADMV_Exam_Date_for_Checklist__c,CADMV_Exam_Date_Time__c,CADMV_Exam_Date_Time_Format__c,

                CADMV_Exam_Date_Time_Text__c,CADMV_Individual_Application__c,CADMV_Business_License_Application__r.Id,

                CADMV_Business_License_Application__r.CADMV_Application_Checklist_Status__c,

                CADMV_Individual_Application__r.Id,CADMV_Individual_Application__r.CADMV_Application_Checklist_Status__c 

            FROM PersonExamination 

            WHERE Id =:personExamId

            WITH SECURITY_ENFORCED

        ];

      User loggedInUser = new User(); 

	  Messaging.CustomNotification bellNotification = new Messaging.CustomNotification();

	  Set<String> finalUserId = new Set<String>();

	  String setApplicationId = CADMV_AppConstants.NULL_EMPTY_STRING;

	  

        if(personExamObj != null && personExamObj.ContactId != null){

			loggedInUser = [

                SELECT id,ContactId,IsActive

                FROM User 

                WHERE ContactId =: personExamObj.ContactId 

                AND IsActive = true

                WITH SECURITY_ENFORCED

            ];

            CustomNotificationType templateInfoDetail = [

                SELECT Id, DeveloperName 

                FROM CustomNotificationType 

                WHERE DeveloperName =: CADMV_AppConstants.EXAM_NOTIFICATION

                WITH SECURITY_ENFORCED

            ];

			setApplicationId = personExamObj.CADMV_Business_License_Application__c != null ? personExamObj.CADMV_Business_License_Application__r.Id : personExamObj.CADMV_Individual_Application__r.Id;

			String finalRefData = '{"type": "comm__namedPage","attributes": {"name": "ApplicationChecklist__c","recordId": "'+setApplicationId+'"}}';

            String notificationTitle = CADMV_AppConstants.NOTIFICATION_TITLE;

			finalUserId.add(loggedInUser.Id);

			

			bellNotification.setTitle(notificationTitle);

			bellNotification.setNotificationTypeId(templateInfoDetail.Id);

			bellNotification.setTargetPageRef(finalRefData);

            if(calloutResult == 'Success'){

                String successMsgBody = 'Your '+personExamObj.Examination.Name+' has been confirmed for '+personExamObj.CADMV_Exam_Date_for_Checklist__c+' '+personExamObj.CADMV_Exam_Date_Time_Text__c+' '+personExamObj.CADMV_Exam_Date_Time_Format__c+'.';

				bellNotification.setBody(successMsgBody);

				bellNotification.send(finalUserId);

				if(personExamObj.CADMV_Business_License_Application__c !=null){

					BusinessLicenseApplication blaObj = new BusinessLicenseApplication();

					blaObj.Id = personExamObj.CADMV_Business_License_Application__r.Id;

					String checklistValue = personExamObj.CADMV_Business_License_Application__r.CADMV_Application_Checklist_Status__c;

					blaObj.CADMV_Application_Checklist_Status__c ='{"ScheduleTakeExam":"In Progress",'+checklistValue.mid(1,checklistValue.length());

					

                    update Security.stripInaccessible(AccessType.UPDATABLE, new List<BusinessLicenseApplication> { blaObj }).getRecords(); //SAST

				}else{

					IndividualApplication blaObj = new IndividualApplication();

					blaObj.Id = personExamObj.CADMV_Individual_Application__r.Id;

					String checklistValue = personExamObj.CADMV_Individual_Application__r.CADMV_Application_Checklist_Status__c;

					blaObj.CADMV_Application_Checklist_Status__c ='{"ScheduleTakeExam":"In Progress",'+checklistValue.mid(1,checklistValue.length());

					

                    update Security.stripInaccessible(AccessType.UPDATABLE, new List<IndividualApplication> { blaObj }).getRecords(); //SAST

				}

		    }else{

				String errorMsgBody = 'Your Exam registration failed, please try again.';

				bellNotification.setBody(errorMsgBody);

				bellNotification.send(finalUserId);

			}

        }

    }

	@future (callout = true)

	public static void examRegistrationCallout(List<String> futureCalloutInput){

		CADMV_CalloutUtility.HeaderAndEndpointWrapper headerAndEndpoints = new CADMV_CalloutUtility.HeaderAndEndpointWrapper();

        CADMV_ExamRegistrationResWrapper outputWrapper = new CADMV_ExamRegistrationResWrapper();

		    headerAndEndpoints = CADMV_CalloutUtility.getEndpointAndHeaderDetails(CADMV_AppConstants.EXAMCALLOUT);

            List<CADMV_RequestHeaderWrapper> headers = headerAndEndpoints.listofheaders;

            HttpResponse response = CADMV_CalloutUtility.sendRequest(headerAndEndpoints.endpointURL,futureCalloutInput[0],CADMV_AppConstants.REQUEST_METHOD_POST,headers,NULL,CADMV_AppConstants.CADMV_EXAMCALLOUTSERVICE_CLASS,CADMV_AppConstants.SEND_EXAMDETAILS_DATA);

            CADMV_CalloutUtility.logCalloutStatus(CADMV_AppConstants.CADMV_EXAMCALLOUTSERVICE_CLASS,CADMV_AppConstants.SEND_EXAMDETAILS_DATA, CADMV_AppConstants.EXAMCALLOUT, futureCalloutInput[0], response);

            

            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) 

            {

                outputWrapper = (CADMV_ExamRegistrationResWrapper) JSON.deserialize(response.getBody(),CADMV_ExamRegistrationResWrapper.Class);

                system.debug('response.getBody()-'+response.getBody());

                system.debug('output Wrapper-'+JSON.serializePretty(outputWrapper));

				createCustomNotification(futureCalloutInput[1],'Success');

            }else{

                system.debug('FAIL');

				createCustomNotification(futureCalloutInput[1],'Fail');

            }

	}

    

    public class FlowOutput {

        @InvocableVariable

        public String driverLicenseNumber;

        @InvocableVariable

        public Date contactDOB;

        @InvocableVariable

        public String contactFN;

        @InvocableVariable

        public String contactLN;

        @InvocableVariable

        public String contactState;

		@InvocableVariable

        public String personExamId;

    }

}