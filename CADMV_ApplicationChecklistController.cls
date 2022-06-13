/*

* Create By : Karthik P

* Created On : 01/10/2022

* Description : This is used to get data for Application Checklist page 

*/

global without sharing class CADMV_ApplicationChecklistController implements vlocity_ins.VlocityOpenInterface2 {

    public Boolean invokeMethod(String methodName,Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        System.debug('invokeMethod--> inputMap' + JSON.serialize(inputMap));

        if(methodName.equals('ChecklistStatus')) {

            setOwnerChecklistStatus(inputMap, outMap, options);

        } else if(methodName.equals('SubmitCertificates')) {

            submitDealerEducationCertificates(inputMap, outMap, options);

        } else if(methodName.equals('UpdateCertificateStatus')) {

            updateCertificateStatus(inputMap, outMap, options);

        } else if(methodName.equals('OwnerHoldStatus')) {

            setOwnerAppHoldStatus(inputMap, outMap, options);

        } else if(methodName.equals('searchAccountName')) {

            searchAccountName(inputMap, outMap, options);

        } else if(methodName.equals('searchPersonAccounts')) {

            searchPersonAccounts(inputMap, outMap, options);

        } else if(methodName.equals('setVerifyCode')) {

            setVerificationCode(inputMap, outMap, options);

        } else if(methodName.equals('verifyContactEmployment')) {

            verifyContactEmployment(inputMap, outMap, options);

        } else if(methodName.equals('createCE')) {

            createCE(inputMap, outMap, options);

        } else if(methodName.equals('createACR')) {

            createACR(inputMap, outMap, options);

        }

        else if(methodName.equals('updateChkList')) {

            updateChkList(inputMap, outMap, options);

        }else if(methodName.equals('getAllExaminers')){

            markContractUploadCompletion(inputMap, outMap, options);

        }

        System.debug('invokeMethod--> outMap' + JSON.serialize(outMap));

        return true;

    }

    /*

* Method used to create contact employment.

*/ 

    public static void createCE(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

    	Object cntctEmp = (Object) inputMap.get('MergedAccountContactRelations');

        Boolean isParticipantCE = inputMap.get('IsParticipantCE') != null ? true : false;

        if(isParticipantCE)

            cntctEmp = (Object) inputMap.get('PMergedAccountContactRelations');

        System.debug('createCE-->' + JSON.serialize(cntctEmp));

        List<vlocity_ins__ContactEmployment__c> ceLst = new List<vlocity_ins__ContactEmployment__c>();

        String accountId = String.valueOf(inputMap.get('SVNewAccountId'));

        String conEmpId = String.valueOf(inputMap.get('conEmpId'));

        if(cntctEmp instanceof List<Object>) {

            List<Object> ceMapLst = (List<Object>) cntctEmp;

            for(Object ceMapObj:ceMapLst) {

                Map<String,Object> ceMap = (Map<String,Object>)ceMapObj;

            	ceLst.add(createCEObj(ceMap,accountId,conEmpId));

            }

        } else {

            Map<String,Object> ceMap = (Map<String,Object>)cntctEmp;

            ceLst.add(createCEObj(ceMap,accountId,conEmpId));

        }

        if(!ceLst.isEmpty()) {

            upsert Security.stripInaccessible(AccessType.CREATABLE, ceLst).getRecords(); //SAST

        }

    }

    /*

* Method used to create contact employment.

*/ 

    public static void createACR(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

    	Object cntctEmp = (Object) inputMap.get('MergedAccountContactRelations');

        List<AccountContactRelation> acrLst = new List<AccountContactRelation>();

        String accountId = String.valueOf(inputMap.get('acrAccountId'));

        Boolean isNonParticipant = true;

        if(inputMap.get('isNonParticipant') != null) 

            isNonParticipant = false;

        if(cntctEmp instanceof List<Object>) {

            List<Object> acrMapLst = (List<Object>) cntctEmp;

            for(Object acrMapObj:acrMapLst) {

                Map<String,Object> acrMap = (Map<String,Object>)acrMapObj;

                acrLst.add(createACRObj(acrMap,accountId,isNonParticipant));

            }

        } else {

            Map<String,Object> acrMap = (Map<String,Object>)cntctEmp;

            acrLst.add(createACRObj(acrMap,accountId,isNonParticipant));

        }

        if(!acrLst.isEmpty()) {

            insert Security.stripInaccessible(AccessType.CREATABLE, acrLst).getRecords(); //SAST

        }

    }

    /*

* Method used to create account contact relation.

*/ 

    public static vlocity_ins__ContactEmployment__c createCEObj(Map<String,Object> ceMap, String accountId, String conEmpId) { 

        vlocity_ins__ContactEmployment__c ceObj = new vlocity_ins__ContactEmployment__c();

        if(!String.isEmpty(conEmpId))

            ceObj.Id = conEmpId;

        ceObj.vlocity_ins__EmployerId__c = accountId;

        ceObj.vlocity_ins__ContactId__c = String.valueOf(ceMap.get('PersonContactId'));

        ceObj.CADMV_OwnerVerificationCode__c = String.valueOf(ceMap.get('PersonVerificationCode'));

        ceObj.vlocity_ins__Title__c = 'Owner';

        if(ceMap.get('PersonRole') != null)

        	ceObj.CADMV_Roles__c = String.valueOf(ceMap.get('PersonRole'));

        

        if(ceMap.get('PersonStartDate') != null)

        	ceObj.vlocity_ins__StartDate__c = Date.valueOf(String.valueOf(ceMap.get('PersonStartDate')));

        else 

            ceObj.vlocity_ins__StartDate__c = System.today();

        return ceObj;

    }

    /*

* Method used to create account contact relation.

*/ 

    public static AccountContactRelation createACRObj(Map<String,Object> acrMap, String accountId, Boolean isNonParticipant) {        

        AccountContactRelation acrObj = new AccountContactRelation();

        acrObj.AccountId = accountId;

        acrObj.ContactId = String.valueOf(acrMap.get('eContactId'));        

        acrObj.Roles = String.valueOf(acrMap.get('eRoleOwner'));

        acrObj.StartDate = Date.valueOf(String.valueOf(acrMap.get('eStartDate')));

        acrObj.IsActive = true;

        acrObj.CADMV_NonParticipating__c = isNonParticipant;

        return acrObj;

    }

    /*

* Method used to verify and confirm the employment.

*/ 

    public static void verifyContactEmployment(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        Map<String,Object> verConEmpMap = (Map<String,Object>)inputMap.get('OwnerVerification');

        

        List<vlocity_ins__ContactEmployment__c> ceLst = [

            SELECT Id, vlocity_ins__ContactId__c,vlocity_ins__EmployerId__c,vlocity_ins__EmployerId__r.ParentId,vlocity_ins__Occupation__c, vlocity_ins__StartDate__c  

            FROM vlocity_ins__ContactEmployment__c 

            WHERE vlocity_ins__ContactId__r.Email =:UserInfo.getUserEmail()

                AND vlocity_ins__EmployerId__r.CADMV_OwnerOneTimePasscode__c =: String.valueOf(verConEmpMap.get('OneTimePassocde'))

                AND CADMV_OwnerVerificationCode__c =: String.valueOf(verConEmpMap.get('OwnerVerificationCode'))

                AND vlocity_ins__ContactId__r.Phone =: String.valueOf(verConEmpMap.get('OwnerPhone'))

                AND vlocity_ins__Status__c = 'In Progress' 

            WITH SECURITY_ENFORCED 

        ];

        if(!ceLst.isEmpty()) {

            ceLst.get(0).vlocity_ins__Status__c = 'Verified';            

            update Security.stripInaccessible(AccessType.UPDATABLE, new List<vlocity_ins__ContactEmployment__c> { ceLst.get(0) }).getRecords(); //SAST

            List<AccountContactRelation> acrLst = new List<AccountContactRelation>();

            acrLst.add(new AccountContactRelation(

                AccountId=ceLst.get(0).vlocity_ins__EmployerId__c,

                ContactId=ceLst.get(0).vlocity_ins__ContactId__c,

                StartDate=ceLst.get(0).vlocity_ins__StartDate__c,

                Roles=ceLst.get(0).vlocity_ins__Occupation__c,

                IsActive=true

            ));

            

            List<AccountContactRelation> nonParticipants = [

                SELECT Id, CADMV_NonParticipating__c 

                FROM AccountContactRelation 

                WHERE AccountId=:ceLst.get(0).vlocity_ins__EmployerId__r.ParentId

                    AND ContactId=:ceLst.get(0).vlocity_ins__ContactId__c 

                WITH SECURITY_ENFORCED

            ];

            if(!nonParticipants.isEmpty()) {

                nonParticipants.get(0).CADMV_NonParticipating__c = false;

				

                update Security.stripInaccessible(AccessType.UPDATABLE, new List<AccountContactRelation> { nonParticipants.get(0) }).getRecords(); //SAST

            } else {

            	acrLst.add(new AccountContactRelation(

                    AccountId=ceLst.get(0).vlocity_ins__EmployerId__r.ParentId,

                    ContactId=ceLst.get(0).vlocity_ins__ContactId__c,                                                                     

                    IsActive=true

                ));

            }  

			

            if(!acrLst.isEmpty()) {

                insert Security.stripInaccessible(AccessType.CREATABLE, acrLst).getRecords(); //SAST

            }

            outMap.put('OwnerExists', true);

        } else {

           outMap.put('OwnerExists', false);

        }

	}

    /*

* Method used to get existing person account

*/

    public static void setVerificationCode(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        Object tPersonAccountsObj = (Object) inputMap.get('TPersonAccounts');

        Boolean isParticipantCE = inputMap.get('IsParticipantCE') != null ? true : false;

        if(isParticipantCE)

            tPersonAccountsObj = (Object) inputMap.get('PTPersonAccounts');

        if(tPersonAccountsObj instanceof List<Object>) {

            List<Object> tPersonAccountsLst = (List<Object>) tPersonAccountsObj;

            Set<String> eIds = new Set<String>();

            for(Object personAccount : tPersonAccountsLst) {

                Map<String,Object> accObj = (Map<String,Object>) personAccount;

                accObj.put('PersonVerificationCode', 'OCE-' + Math.roundToLong(Math.random() * 100000000));                

            }    

        } else {

            Map<String,Object> accObj = (Map<String,Object>) tPersonAccountsObj;

            accObj.put('PersonVerificationCode', 'OCE-' + Math.roundToLong(Math.random() * 100000000));

            if(isParticipantCE)

            	outMap.put('PTPersonAccounts',accObj);

            else 

            	outMap.put('TPersonAccounts',accObj);

            

        }

    }

    /*

* Method used to get existing person account

*/

    public static void searchPersonAccounts(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        Object tPersonAccountsObj = (Object) inputMap.get('TPersonAccounts');

        Boolean isParticipantCE = inputMap.get('IsParticipantCE') != null ? true : false;

        if(isParticipantCE)

            tPersonAccountsObj = (Object) inputMap.get('PTPersonAccounts'); 

        if(tPersonAccountsObj instanceof List<Object>) {

            List<Object> tPersonAccountsLst = (List<Object>) tPersonAccountsObj;

            Set<String> eIds = new Set<String>();

            for(Object personAccount : tPersonAccountsLst) {

                Map<String,Object> accObj = (Map<String,Object>) personAccount;                

                eIds.add(String.valueOf(accObj.get('PersonEmail')));

            }

            List<Account> accLst = [

                SELECT Id, PersonContactId, PersonEmail 

                FROM Account 

                WHERE PersonEmail = :eIds 

                WITH SECURITY_ENFORCED

            ];

            if(!accLst.isEmpty()) {

                for(Object personAccount : tPersonAccountsLst) {

                    Map<String,Object> accObj = (Map<String,Object>) personAccount;

                    for(Account accntObj: accLst) {

                        if(accntObj.PersonEmail.equals(String.valueOf(accObj.get('PersonEmail')))) {

                            accObj.put('PersonAccountId', accntObj.Id);

                            accObj.put('PersonContactId', accntObj.PersonContactId);

                        } 

                    }

                }

            }

        } else {

            Map<String,Object> accObj = (Map<String,Object>) tPersonAccountsObj;

            System.debug('TPersonAccount-->' + JSON.serialize(accObj));

            

            List<Account> accLst = [

                SELECT Id, PersonContactId, PersonEmail 

                FROM Account 

                WHERE PersonEmail = :String.valueOf(accObj.get('PersonEmail')) 

                WITH SECURITY_ENFORCED

            ];

            if(!accLst.isEmpty()) {  

                if(accLst.get(0).PersonEmail.equals(String.valueOf(accObj.get('PersonEmail')))) {

                    accObj.put('PersonAccountId', accLst.get(0).Id);

                    accObj.put('PersonContactId', accLst.get(0).PersonContactId);

                }                    

            }

            System.debug('TPersonAccount or PTPersonAccounts-->' + JSON.serialize(accObj));

            if(isParticipantCE)

            	outMap.put('PTPersonAccounts',accObj);

            else 

            	outMap.put('TPersonAccounts',accObj);

        }

    }

    

    //Method to retreive the Account Names from the Account object to see if the account is available

    //Written by Pallavi as part of User story 7535 ETP Examiner Employer's Information this method is added in the EmployerInformation OmniScript

    public static void searchAccountName(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        String empNm = '%' + String.valueOf(inputMap.get('SearchEmployer')) + '%';

        List<Map<String,Object>> empLst = new List<Map<String,Object>>();

        

        for(Account accObj: [

            SELECT Id,Name,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,Phone 

            FROM Account 

            WHERE Name LIKE :empNm 

            WITH SECURITY_ENFORCED

        ]) {

            Map<String,Object> empMap = new Map<String,Object>();

            empMap.put('AccountName', accObj.Name);

            empMap.put('EmployerName', accObj.Name);

            empMap.put('Address', accObj.ShippingStreet);

            empMap.put('City', accObj.ShippingCity);

            empMap.put('State', accObj.ShippingState);

            empMap.put('Zipcode', accObj.ShippingPostalCode);

            empMap.put('TelephoneNumber', accObj.Phone);

            empMap.put('EmployerAccountId', accObj.Id);

            empLst.add(empMap);

        }

        

        outMap.put('options', empLst);        

    }

    

    /*

* Method used to update certificate status

*/

    public static void updateCertificateStatus(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {

        Map<String,Object> dlrCert = (Map<String,Object>) inputMap.get('ScheduleDealerEducationCourse');

        Map<String,Object> certSearch = (Map<String,Object>) dlrCert.get('CertificateSearch');

        Map<String,Object> prwCert = (Map<String,Object>) certSearch.get('PreviewCertificate');

        CADMV_EducationProviderCourseRecipient__c cert = new CADMV_EducationProviderCourseRecipient__c();

        cert.Id = String.valueOf(prwCert.get('recipientId'));

        cert.CADMV_VerificationStatus__c = String.valueOf(inputMap.get('actionType'));

        

        update Security.stripInaccessible(AccessType.UPDATABLE, new List<CADMV_EducationProviderCourseRecipient__c> { cert }).getRecords(); //SAST

    }

    

    /*

* Method used to set owner application hold status

*/

    public static void setOwnerAppHoldStatus(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {

        String usrCntctId = String.valueOf(inputMap.get('userContactId'));  

        Object ownerDetailsObj = (Object)inputMap.get('ownerDetails'); 

        Object ownerHolds = (Object)inputMap.get('appOwnerHolds'); 

        if(ownerDetailsObj instanceof List<Object>) {

            List<Map<String,Object>> ownerLst = (List<Map<String,Object>>) ownerDetailsObj;             

            for(Map<String,Object> owner:ownerLst){

                if(ownerHolds instanceof List<Object>) {

                    List<Map<String,Object>> holdLst = (List<Map<String,Object>>) ownerHolds;

                    for(Map<String,Object> holds : holdLst) {

                        if(String.valueOf(owner.get('ownerAccountId')).equals(String.valueOf(holds.get('ownerAccountId')))) {

                            owner.put('hasOpenHold', true);

                        }

                    }

                } else {

                    Map<String,Object> appHold = (Map<String,Object>) ownerHolds;   

                    if(appHold != null) {

                        if(String.valueOf(owner.get('ownerAccountId')).equals(String.valueOf(appHold.get('ownerAccountId')))) {

                            owner.put('hasOpenHold', true);

                        }

                    }

                }

                String ownerId = String.valueOf(owner.get('ownerId'));

                System.debug('1. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

                if(ownerId.equals(usrCntctId)) 

                    owner.put('isLoggedInUser', true);

                else 

                    owner.put('isLoggedInUser', false);

            }

        } else {            

            Map<String,Object> appOwner = (Map<String,Object>) ownerDetailsObj;

            String ownerId = String.valueOf(appOwner.get('ownerId'));

            if(ownerHolds instanceof List<Object>) {

                List<Map<String,Object>> appHoldsLst = (List<Map<String,Object>>) ownerHolds;

                /*if(appHoldsLst.isEmpty()) {

appOwner.put('hasOpenHold', false);

}*/

                for(Map<String,Object> holds : appHoldsLst) {

                    if(String.valueOf(appOwner.get('ownerAccountId')).equals(String.valueOf(holds.get('ownerAccountId')))) {

                        appOwner.put('hasOpenHold', true);

                    }

                }

            } else {

                Map<String,Object> appHold = (Map<String,Object>) ownerHolds;   

                if(appHold != null) {

                    if(String.valueOf(appHold.get('ownerAccountId')).equals(String.valueOf(appOwner.get('ownerAccountId')))) {

                        appOwner.put('hasOpenHold', true);

                    }

                }

            }

            System.debug('2. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

            if(ownerId.equals(usrCntctId)) 

                appOwner.put('isLoggedInUser', true);

            else 

                appOwner.put('isLoggedInUser', false);

        }

    }

    /*

* Method used to submit dealer education certificates

*/

    public static void submitDealerEducationCertificates(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {

        Map<String,Object> dlrEduCerts = (Map<String,Object>)inputMap.get('DealerEducationCertificateDetails');

        Map<String,Object> crseDtls = (Map<String,Object>) dlrEduCerts.get('TrnCourse-Block');

        CourseOffering CrseOffr = new CourseOffering();

        CrseOffr.CourseNameId = String.valueOf(crseDtls.get('CourseId'));

        CrseOffr.Name = String.valueOf(crseDtls.get('CourseName'));

        CrseOffr.StartDate = Date.valueOf(String.valueOf(dlrEduCerts.get('StartDate')));

        CrseOffr.EndDate = Date.valueOf(String.valueOf(dlrEduCerts.get('EndDate')));

        CrseOffr.CADMV_CourseCurriculamCertificateNumber__c = String.valueOf(dlrEduCerts.get('CertificateNumber'));

        

        insert Security.stripInaccessible(AccessType.CREATABLE, new List<CourseOffering> { CrseOffr }).getRecords(); //SAST

        

        Object recipients = (Object) dlrEduCerts.get('Recipients');

        List<CADMV_EducationProviderCourseRecipient__c> recLst = new List<CADMV_EducationProviderCourseRecipient__c>();

        if(recipients instanceof List<Object>) {

            List<Object> recsLst = (List<Object>) recipients;

            for(Object recObj : recsLst) {

                Map<String,Object> recMap = (Map<String,Object>) recObj;

                recLst.add(setRecipient(recMap,CrseOffr.Id));

            }

        } else {

            recLst.add(setRecipient((Map<String,Object>)recipients,CrseOffr.Id));

        }

        if(!recLst.isEmpty()) {

            insert Security.stripInaccessible(AccessType.CREATABLE, recLst).getRecords(); //SAST      

        } 

    }

    /*

* Method used to create edication provider course recipient object

*/

    public static CADMV_EducationProviderCourseRecipient__c setRecipient(Map<String,Object> recipient, Id crseOffrId) {

        CADMV_EducationProviderCourseRecipient__c recObj = new CADMV_EducationProviderCourseRecipient__c();

        recObj.CADMV_FirstName__c = String.valueOf(recipient.get('RecipientFirstName'));

        recObj.CADMV_LastName__c = String.valueOf(recipient.get('RecipientLastName'));

        recObj.CADMV_MiddleName__c = String.valueOf(recipient.get('RecipientMiddleName'));

        recObj.CADMV_DateOfBirth__c = Date.valueOf(String.valueOf(recipient.get('RecipientDOB')));

        recObj.CADMV_DriversLicenseIdentificationNumber__c = String.valueOf(recipient.get('IdentityNumber'));

        recObj.CADMV_CourseOffering__c = crseOffrId;

        return recObj;

        

    }

    

    //Update CheckList

   public static void  updateChkList(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {        

        String recId = String.valueOf(inputMap.get('appRecId'));

        String application =String.valueOf(inputMap.get('appNumber'));

        String RemovedChk='';

        If(application.startsWith('BLA') )

        {

            BusinessLicenseApplication blapp = [

                SELECT id,cadmv_application_checklist_status__c 

                FROM BusinessLicenseApplication 

                WHERE id=:recId 

                WITH SECURITY_ENFORCED

                LIMIT 1

            ];

            

            String chkList=blApp.CADMV_Application_Checklist_Status__c;

            RemovedChk=chkList.replace('ReviewAndCertify','ReviewEdited'); 

            BusinessLicenseApplication Bla=new BusinessLicenseApplication();

            Bla.Id=recId;

            Bla.Status='Completing Requirement';

            Bla.CADMV_Application_Checklist_Status__c=RemovedChk;

			

            update Security.stripInaccessible(AccessType.UPDATABLE, new List<BusinessLicenseApplication> { Bla }).getRecords(); //SAST

        }

        else if(application.startsWith('IA'))

        {

            IndividualApplication ilApp=[

                SELECT id,cadmv_application_checklist_status__c 

                FROM IndividualApplication 

                WHERE id=:recId 

                WITH SECURITY_ENFORCED 

                LIMIT 1

            ];

            String chkList1=ilApp.CADMV_Application_Checklist_Status__c;

            RemovedChk=chkList1.replace('ReviewAndCertify','ReviewEdited'); 

            IndividualApplication IA= new IndividualApplication();

            IA.id=recId;

            IA.CADMV_Application_Checklist_Status__c=RemovedChk;

            IA.Status='Completing Requirement';

			

            update Security.stripInaccessible(AccessType.UPDATABLE, new List<IndividualApplication> { IA }).getRecords(); //SAST

        }

         outMap.put('RemovedChk', RemovedChk);      

       

    }

    

    //Update CheckList End

   

    /*

* Method used to set owner level checklist status

*/

    public static void setOwnerChecklistStatus(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) {

        String usrCntctId = String.valueOf(inputMap.get('userContactId'));

        //String checklistType = String.valueOf(inputMap.get('checklistType'));

        //--- US 7383-- variable to compare with JSON -- //

        String checklistType = 'ReviewAndCertify';

        List<String> ReviewCompleted = new List<String>();        

        try {

            Object appVerifiedOwners = (Object)inputMap.get('VerifiedOwners');

            if(appVerifiedOwners != null) {

               if(appVerifiedOwners instanceof List<Object>) {

                   List<Object> appOwnersLst = (List<Object>)appVerifiedOwners;

                   for(Object appOwnerObj: appOwnersLst) {

                      Map<String,Object> appOwnerMap = (Map<String,Object>)appOwnerObj;

                      if(usrCntctId.equals(String.valueOf(appOwnerMap.get('ContactId'))))

                       	appOwnerMap.put('isCurrentUser', true); 

                      else 

                        appOwnerMap.put('isCurrentUser', false);  

                   }

                } else {

                    Map<String,Object> appOwnerMap = (Map<String,Object>)appVerifiedOwners;

                    if(usrCntctId.equals(String.valueOf(appOwnerMap.get('ContactId'))))

                       appOwnerMap.put('isCurrentUser', true);                     

                    outMap.put('VerifiedOwners', appOwnerMap);

                } 

            }

            Object appOwnerHolds = (Object)inputMap.get('appOwnerHolds');            

            if(appOwnerHolds != null) {

                if(appOwnerHolds instanceof List<Object>) {

                    List<Object> appHoldsLst = (List<Object>)appOwnerHolds;

                    if(!appHoldsLst.isEmpty()) {

                        outMap.put('isOpenHolds', true);

                    } else {

                        outMap.put('isOpenHolds', false);

                    }

                } else {

                    outMap.put('isOpenHolds', true);

                }

            }

            if(inputMap.get('ChecklistStatus') != null) {            

                Map<String,Object> checklistStatusMap = (Map<String,Object>)inputMap.get('ChecklistStatus'); 

                if(checklistStatusMap != null) {  

                    Map<String,Object> completeChecklist = (Map<String,Object>)inputMap.get('CompleteChecklist');                

                    Object ownerDetailsObj = (Object)inputMap.get('ownerDetails');   

                    if(ownerDetailsObj instanceof List<Object>) {                    

                        List<Map<String,Object>> ownerLst = (List<Map<String,Object>>) ownerDetailsObj;                    

                        for(Map<String,Object> owner:ownerLst){

                            String ownerId = String.valueOf(owner.get('ownerId'));

                            Map<String,String> checklistStatus = new Map<String,String>();

                            for(String statusKey : checklistStatusMap.keySet()){

                                if(statusKey.contains(ownerId)){

                                    checklistStatus.put(statusKey.split('-')[0], 'Completed');

                                    //--- US 7383-- adding if condition to sort the rows having JSON same as ChecklistType var -- //

                                    if(statusKey.contains(checklistType)){

                                        ReviewCompleted.add(statusKey.split('-')[1]);

                                    }

                                }   

                            }

                            owner.put('ChecklistStatus', checklistStatus);

                            System.debug('3. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

                            if(ownerId.equals(usrCntctId)) 

                                owner.put('isLoggedInUser', true);

                            else 

                                owner.put('isLoggedInUser', false);

                        }   

                        

                        //--- US 7383-- pass the value to IP based on the number of owners and review completed owners-- //

                        if(ReviewCompleted.size() == ownerLst.size()){

                            outMap.put('CompletedReviewCertify', 'Completed');

                        }

                        else if(ownerLst.size()-ReviewCompleted.size() == 1){

                            outMap.put('CompletedReviewCertify', 'Final');

                        }

                        else{

                            outMap.put('CompletedReviewCertify', 'Pending');

                        }

                        outMap.put('ownerDetailsMap', ownerLst);

                    } 

                    else {

                        Map<String,Object> ownerObj = (Map<String,Object>) ownerDetailsObj;            

                        String ownerId = String.valueOf(ownerObj.get('ownerId'));

                        Map<String,String> checklistStatus = new Map<String,String>();

                        for(String statusKey : checklistStatusMap.keySet()){

                            if(statusKey.contains(ownerId)){

                                checklistStatus.put(statusKey.split('-')[0], 'Completed');

                                //--- US 7383-- adding if condition to sort the rows having JSON same as ChecklistType var -- //

                                if(statusKey.contains(checklistType)){

                                    ReviewCompleted.add(statusKey.split('-')[1]);

                                }

                            }                

                        }    

                        System.debug('4. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

                        if(ownerId.equals(usrCntctId)) 

                            ownerObj.put('isLoggedInUser', true);

                        else 

                            ownerObj.put('isLoggedInUser', false);

                        

                        

                        List<String> ownerlst = new List<String>();

                        ownerlst.add(ownerId);

                        

                        //--- US 7383-- pass the value to IP based on the number of owners and review completed owners-- //                        

                        if(ReviewCompleted.size() == ownerLst.size()){

                            outMap.put('CompletedReviewCertify', 'Completed');

                        }

                        else if(ownerLst.size()-ReviewCompleted.size() == 1){

                            outMap.put('CompletedReviewCertify', 'Final');

                        }

                        else{

                            outMap.put('CompletedReviewCertify', 'Pending');

                        }

                        ownerObj.put('ChecklistStatus', checklistStatus); 

                        outMap.put('ownerDetailsMap', ownerObj);

                    }   

                    

                    //if(!String.isEmpty(completeChecklist)) {   

                    if(completeChecklist != null) {                 

                        outMap.put('enableReviewCertify', true);

                        System.debug('completeChecklist-->' + completeChecklist);

                        Map<String,Object> compCheckMap = completeChecklist;//(Map<String,Object>) JSON.deserializeUntyped(completeChecklist);

                        for(String compCheck : compCheckMap.keySet()) {  

                            if(compCheck.endsWith('-OWNER')) {

                                List<String> splitOwner = compCheck.split('-');

                                if(ownerDetailsObj instanceof List<Object>) {

                                    List<Map<String,Object>> ownerLst = (List<Map<String,Object>>) ownerDetailsObj;

                                    for(Map<String,Object> owner:ownerLst){

                                        String ownerId = String.valueOf(owner.get('ownerId'));

                                        String liveScanResults = String.valueOf(owner.get('ownerLiveScanResult'));  

                                        if(compCheckMap.get(compCheck) instanceof Boolean) {

                                            if('LiveScanResults'.equals(splitOwner[0]) && !'Results Found'.equals(liveScanResults)) {

                                                outMap.put('enableReviewCertify', false);

                                            } else if(!checklistStatusMap.containsKey(splitOwner[0] + '-' + ownerId)) {

                                                outMap.put('enableReviewCertify', false);

                                            }

                                        } else {

                                            Boolean expVal = validateExpression(compCheckMap, compCheck, inputMap);

                                            if(expVal = true) {

                                                if(!checklistStatusMap.containsKey(splitOwner[0] + '-' + ownerId)) {

                                                    outMap.put('enableReviewCertify', false);

                                                }

                                            }

                                        }

                                    }

                                } else {

                                    Map<String,Object> ownerObj = (Map<String,Object>) ownerDetailsObj; 

                                    String ownerId = String.valueOf(ownerObj.get('ownerId'));

                                    String liveScanResults = String.valueOf(ownerObj.get('ownerLiveScanResult')); 

                                    if(compCheckMap.get(compCheck) instanceof Boolean) {

                                        if('LiveScanResults'.equals(splitOwner[0]) && !'Results Found'.equals(liveScanResults)) {

                                            outMap.put('enableReviewCertify', false);

                                        } else if(!checklistStatusMap.containsKey(splitOwner[0] + '-' + ownerId)) {

                                            outMap.put('enableReviewCertify', false);

                                        }

                                    } else {

                                        Boolean expVal = validateExpression(compCheckMap, compCheck, inputMap);

                                        if(expVal = true) {

                                            if(!checklistStatusMap.containsKey(splitOwner[0] + '-' + ownerId)) {

                                                outMap.put('enableReviewCertify', false);

                                            }

                                        }

                                    }

                                }

                            } else {                             

                                if(compCheckMap.get(compCheck) instanceof Boolean) {

                                    if(!checklistStatusMap.containsKey(compCheck)) {

                                        outMap.put('enableReviewCertify', false);

                                    }

                                } else {

                                    Boolean expVal = validateExpression(compCheckMap, compCheck, inputMap);

                                    if(expVal = true) {

                                        if(!checklistStatusMap.containsKey(compCheck)) {

                                            outMap.put('enableReviewCertify', false);

                                        }

                                    }

                                }

                            }

                        }

                    }

                }

            } 

            else {            

                Object ownerDetailsObj = (Object)inputMap.get('ownerDetails');

                if(ownerDetailsObj instanceof List<Object>) {

                    List<Map<String,Object>> ownerLst = (List<Map<String,Object>>) ownerDetailsObj;

                    for(Map<String,Object> owner:ownerLst){   

                        String ownerId = String.valueOf(owner.get('ownerId'));

                        System.debug('5. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

                        if(ownerId.equals(usrCntctId)) 

                            owner.put('isLoggedInUser', true);

                        else 

                            owner.put('isLoggedInUser', false);

                    }

                    outMap.put('ownerDetailsMap', ownerLst);

                } else {

                    Map<String,Object> ownerObj = (Map<String,Object>) ownerDetailsObj;            

                    String ownerId = String.valueOf(ownerObj.get('ownerId'));  

                    System.debug('6. usrCntctId-- '+usrCntctId+' --ownerId-- '+ownerId);

                    if(ownerId.equals(usrCntctId)) 

                        ownerObj.put('isLoggedInUser', true);

                    else 

                        ownerObj.put('isLoggedInUser', false);     

                    outMap.put('ownerDetailsMap', ownerObj);

                }  

            }  

        }catch(Exception exp) {

            System.debug('Exception in SetOwner--' + exp.getStackTraceString());

            System.debug('Exception in SetOwner--' + exp.getMessage() + '--' + exp.getLineNumber());

        }

    }

    /*

* Method used to validate expression for checklist status

*/

    public static Boolean validateExpression(Map<String,Object> compCheckMap, String compCheck, Map<String,Object> inputMap) {

        Boolean rtnVal = true;

        Map<String,Object> groupExpMap = (Map<String,Object>) compCheckMap.get(compCheck);

        Map<String,Object> groupExp = (Map<String,Object>) groupExpMap.get('group');

        validateGroup(groupExp, inputMap);

        return rtnVal;

    }

    

    /*

* Method used to validate expression group

*/

    public static Boolean validateGroup(Map<String,Object> groupExp, Map<String,Object> inputMap) {

        Boolean rtnVal = true;

        List<Object> rules = (List<Object>) groupExp.get('rules');

        String oprtr = String.valueOf(groupExp.get('operator'));

        List<Boolean> expResults = new List<Boolean>();

        if(rules.size() > 1) {

            for(Object rule : rules) {

                Map<String,Object> ruleMap = (Map<String,Object>) rule;

                if(ruleMap.containsKey('group')) {

                    Map<String,Object> groupMap = (Map<String,Object>)ruleMap.get('group');

                    expResults.add(validateGroup(groupMap, inputMap));

                } else {

                    String ruleFld = String.valueOf(ruleMap.get('field'));

                    String cndtn = String.valueOf(ruleMap.get('condition'));

                    String data = String.valueOf(ruleMap.get('data'));

                    System.debug('ruleFld value-->' + String.valueOf(inputMap.get(ruleFld)));

                    if(cndtn.equals('=')) {

                        if(data.equals(String.valueOf(inputMap.get(ruleFld)))) {

                            expResults.add(true);

                        } else {

                            expResults.add(false); 

                        }

                    } else if(cndtn.equals('<>')) {

                        if(!data.equals(String.valueOf(inputMap.get(ruleFld)))) {

                            expResults.add(true);

                        } else {

                            expResults.add(false);

                        }

                    }

                }

            }

            if(oprtr.equalsIgnoreCase('AND')) {

                if(expResults.contains(false)) {

                    rtnVal = false;

                }  

            } else if(oprtr.equalsIgnoreCase('OR')) {

                if(!expResults.contains(true)) {

                    rtnVal = false; 

                }

            }

        } else {

            for(Object rule : rules) {

                Map<String,Object> ruleMap = (Map<String,Object>) rule;

                if(ruleMap.containsKey('group')) {

                    Map<String,Object> groupMap = (Map<String,Object>)ruleMap.get('group');

                    expResults.add(validateGroup(groupMap, inputMap));

                } else {

                    String ruleFld = String.valueOf(ruleMap.get('field'));

                    String cndtn = String.valueOf(ruleMap.get('condition'));

                    String data = String.valueOf(ruleMap.get('data')); 

                    if(cndtn.equals('=')) {

                        if(data.equals(String.valueOf(inputMap.get(ruleFld)))) {

                            expResults.add(true);

                        } else {

                            expResults.add(false); 

                        }

                    } else if(cndtn.equals('<>')) {

                        if(!data.equals(String.valueOf(inputMap.get(ruleFld)))) {

                            expResults.add(true);

                        } else {

                            expResults.add(false);

                        }

                    }

                }

            }

            if(expResults.contains(false)) {

                rtnVal = false;

            } 

        }

        return rtnVal;

    }

	

	 /*

* Method used to determine the examiner contract upload completion from checklist status

*/  public static void markContractUploadCompletion(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){

    String checklistStatusStr = (String) inputMap.get('checklistStatusJSON');

    

     Object allExaminers = (Object)inputMap.get('ETPExaminers');

            if(allExaminers != null) {

               if(allExaminers instanceof List<Object>) {

                   List<Object> appOwnersLst = (List<Object>)allExaminers;

                   for(Object appOwnerObj: appOwnersLst) {

                      Map<String,Object> appOwnerMap = (Map<String,Object>)appOwnerObj;

                      if(appOwnerMap.containsKey('AccExaminerId') && checklistStatusStr.contains(String.valueOf(appOwnerMap.get('AccExaminerId')))){

                        appOwnerMap.put('UploadComplete', true);

                        appOwnerMap.put('NoExaminerRecord', false); }

                      else if(appOwnerMap.containsKey('AccExaminerId') && !checklistStatusStr.contains(String.valueOf(appOwnerMap.get('AccExaminerId')))){

                          appOwnerMap.put('UploadComplete', false);

                          appOwnerMap.put('NoExaminerRecord', false);

                      }

                     else {

                        appOwnerMap.put('NoExaminerRecord', true);  

                        

                        }

                   }

                } else {

                    Map<String,Object> appOwnerMap = (Map<String,Object>)allExaminers;

                    if(appOwnerMap.containsKey('AccExaminerId') && checklistStatusStr.contains(String.valueOf(appOwnerMap.get('AccExaminerId')))){

                       appOwnerMap.put('UploadComplete', true); 

                        appOwnerMap.put('NoExaminerRecord', false); }

                     else if(appOwnerMap.containsKey('AccExaminerId') && !checklistStatusStr.contains(String.valueOf(appOwnerMap.get('AccExaminerId')))){

                          appOwnerMap.put('UploadComplete', false);

                           appOwnerMap.put('NoExaminerRecord', false); 

                      }

                     else {

                        appOwnerMap.put('NoExaminerRecord', true);  

                        

                        }                      

                    outMap.put('ETPExaminers', appOwnerMap);

                } 

            }

}

}

