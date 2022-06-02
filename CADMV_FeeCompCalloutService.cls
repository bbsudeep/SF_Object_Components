public with sharing class CADMV_FeeCompCalloutService {

    

    /**************************************************************************************************

     * Method Name - calculateRegulatoryTransFee

     * Params - CADMV_parentRecrdId

     * Description - Used to create Regulatory Transaction Fee for all the BLA/IA/Exam/Fingerprint r etc.

     * ***************************************************************************************************/

     

    @InvocableMethod(label='Calculate Regulatory Transaction Fee' description='Returns the response after creating the Regulatory Transaction Fee')

    public static List<List<String>> calculateRegulatoryTransFeeGeneric(List<Id> CADMV_parentRecrdId)

    {

        List<String> responseMessageList=new List<String>();

        String sObjName = CADMV_parentRecrdId[0].getSObjectType().getDescribe().getName();

        if(sObjName == CADMV_AppConstants.BLA_API_NAME){

            createFeesForBLA(CADMV_parentRecrdId[0]);        

        }else if( sObjName == CADMV_AppConstants.IA_API_NAME){   

            createFeesForIA(CADMV_parentRecrdId[0]);

        }else if( sObjName == CADMV_AppConstants.EXAM_API_NAME){

            createFeesForExam(CADMV_parentRecrdId[0]);

        }

        responseMessageList.add((String)Schema.getGlobalDescribe().get(sObjName).getDescribe().getLabel());

        return new List<List<String>>{responseMessageList};

      }

    

    /**************************************************************************************************

* Method Name - createFeesGeneric

* Params - CADMV_FeeCompWrapper

* Description - Used by all to create RTF and RTFI records for BLA/IA/Exam/Fingerprint etc.

* ***************************************************************************************************/

    @TestVisible

    Private Static Void createFeesGeneric(CADMV_FeeCompWrapper outputWrapper)

    {

        List<CADMV_FeeCompWrapper.ResponseRecordsWrapper> recordsList = new List<CADMV_FeeCompWrapper.ResponseRecordsWrapper>();

        List<RegulatoryTrxnFeeItem> regTrxnFeeItemList = new List<RegulatoryTrxnFeeItem>();

        recordsList = outputWrapper.ResponseRecords;

        try{

            if(recordsList != null && !recordsList.isEmpty())

            {

                RegulatoryTrxnFee regTrxnFee = new RegulatoryTrxnFee();

                if(outputWrapper.AppRecordType == CADMV_AppConstants.BLA)

                {

                    regTrxnFee.CADMV_Type__c = CADMV_AppConstants.APPLICATION_FEE;

                }   

                else if(outputWrapper.AppRecordType == CADMV_AppConstants.EXAM)

                {

                    regTrxnFee.CADMV_Type__c = CADMV_AppConstants.EXAM_FEE;

                    regTrxnFee.Person_Examination__c = outputWrapper.ApplicationId; //Just replace this with examID. I have moved ParentID to below 

                }

                else if(outputWrapper.AppRecordType == CADMV_AppConstants.FINGERPRINT)

                {

                    regTrxnFee.CADMV_Type__c = CADMV_AppConstants.FINGERPRINT_CARD;

                }

                

                regTrxnFee.ParentRecordId = outputWrapper.ApplicationId;

                regTrxnFee.AccountId = outputWrapper.AccountId; 

                regTrxnFee.CalculationDate = system.now();

                regTrxnFee.Person_Examination__c = outputWrapper.PersonExam != null ? outputWrapper.PersonExam : null;

                

                regTrxnFee.Status = CADMV_AppConstants.DUE;

                insert Security.stripInaccessible(AccessType.CREATABLE, new List<RegulatoryTrxnFee> { regTrxnFee }).getRecords(); //SAST

                

                for(CADMV_FeeCompWrapper.ResponseRecordsWrapper record : recordsList )

                {

                    RegulatoryTrxnFeeItem regTrxnFeeItem = new RegulatoryTrxnFeeItem();

                    regTrxnFeeItem.RegulatoryTrxnFeeId = regTrxnFee.Id;

                    regTrxnFeeItem.CADMV_CalculationInformation__c = record.CalculationInformation;

                    regTrxnFeeItem.FeeAmount = record.Amount ;

                    regTrxnFeeItem.CADMV_DisplayName__c = record.DisplayName;

                    regTrxnFeeItem.CADMV_FeeCode__c = String.valueOf(record.FeeCode); 

                    regTrxnFeeItem.CADMV_Refundable__c = record.Refundable; 

                    regTrxnFeeItem.CADMV_FeeAmountWaived__c = record.AmountWaived;

                    

                    regTrxnFeeItemList.add(regTrxnFeeItem);

                }

                if(!regTrxnFeeItemList.isEmpty())

                {

                    insert Security.stripInaccessible(AccessType.CREATABLE, regTrxnFeeItemList).getRecords(); //SAST

                }

            }

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

    }

    

    /**************************************************************************************************

    * Method Name - createFeesForBLA

    * Params - BLA Id

    * Description - Used to create request to Red Hat via mulesoft to get calulated fees.

    * ***************************************************************************************************/

    Public Static void createFeesForBLA(String businessLicenseAppId)

    {        

        CADMV_FeeCompWrapper.RequestRecordsWrapper inputWrapper = new CADMV_FeeCompWrapper.RequestRecordsWrapper();

        CADMV_FeeCompWrapper outputWrapper = new CADMV_FeeCompWrapper();

        List<RegulatoryTrxnFee> updateRegTrxnFeeList = new List<RegulatoryTrxnFee>();

        try {

            List<RegulatoryTrxnFee> oldRegTrxnFeeList = [

                SELECT id, ParentRecordId, CADMV_OverrideFeeRecalculation__c, Status 

                FROM RegulatoryTrxnFee 

                WHERE ParentRecordId =:businessLicenseAppId 

                    AND 

                    (

                        Status =: CADMV_AppConstants.DUE 

                        OR 

                        Status =: CADMV_AppConstants.DRAFT

                    ) 

                    AND 

                    CADMV_Type__c =: CADMV_AppConstants.APPLICATION_FEE

                WITH SECURITY_ENFORCED

            ];

                

            for(RegulatoryTrxnFee regFee : oldRegTrxnFeeList) {

                if(regFee.CADMV_OverrideFeeRecalculation__c == false)

                {

                    regFee.Status = 'Canceled';

                    updateRegTrxnFeeList.add(regFee);

                }

            }

            if((updateRegTrxnFeeList != null && !updateRegTrxnFeeList.isEmpty()) || oldRegTrxnFeeList.isEmpty())

            {

                BusinessLicenseApplication businessLicense = [

                    SELECT Id, Name, LicenseType.Name, ApplicationType,CADMV_NumberofAutoPlates__c,

                        CADMV_RenewalPeriodEndDate__c,CADMV_NewVehicles__c,Is_Autobroker_Endorsement__c,

                        CADMV_NumberofMotorcyclePlates__c,AccountId,County__c,sitecity,SitePostalCode, 

                        LicenseTypeId,  LicensePermitNameId

                    FROM BusinessLicenseApplication

                    WHERE Id =:businessLicenseAppId 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                Integer periodEndVal;

                Integer classroomVal;

                Integer branchVal;

                Integer renewalPer;

                if(businessLicense.LicensePermitNameId != null){

                    BusinessLicense periodEnd = [

                        SELECT PeriodEnd 

                        FROM BusinessLicense 

                        WHERE Id =: businessLicense.LicensePermitNameId

                        WITH SECURITY_ENFORCED

                    ];

                    

                    if(periodEnd!=null && periodEnd.PeriodEnd !=null)

                        periodEndVal= (system.today()).daysBetween(Date.valueOf(periodEnd.PeriodEnd)) != null?(system.today()).daysBetween(Date.valueOf(periodEnd.PeriodEnd)) : null;

                }

                if(businessLicense.AccountId != null){

                    Integer classroom = [

                        SELECT COUNT() 

                        FROM Account 

                        WHERE ParentId =: businessLicense.AccountId 

                        AND Type = 'Classroom'

                        WITH SECURITY_ENFORCED

                    ];

                    classroomVal = classroom != null?classroom:null; 

                    

                    Integer branch = [

                        SELECT COUNT() 

                        FROM Account 

                        WHERE ParentId =: businessLicense.AccountId

                            AND Type = 'Branch'

                        WITH SECURITY_ENFORCED    

                    ];

                    branchVal = branch != null?branch:null;

                }

                if(businessLicense.LicenseTypeId != null){

                    RegulatoryAuthorizationType renPer = [

                        SELECT CADMV_FirstRenewalLicensePeroid__c 

                        FROM RegulatoryAuthorizationType 

                        WHERE Id=: businessLicense.LicenseTypeId 

                        WITH SECURITY_ENFORCED

                        LIMIT 1

                    ];

                    renewalPer = renPer.CADMV_FirstRenewalLicensePeroid__c != null?Integer.valueOf((renPer.CADMV_FirstRenewalLicensePeroid__c)/12):null;

                }

                inputWrapper.TriggerType= CADMV_AppConstants.APPLICATION;

                inputWrapper.LicenseType= businessLicense.LicenseType.Name;

                inputWrapper.ApplicationType= businessLicense.ApplicationType;

                inputWrapper.EffectiveDate = (businessLicense.ApplicationType==CADMV_AppConstants.RENEWAL && businessLicense.CADMV_RenewalPeriodEndDate__c > System.Today())?businessLicense.CADMV_RenewalPeriodEndDate__c.date():System.Today();

                inputWrapper.NumberOfBranches = branchVal;

                inputWrapper.RenewalPeriod = renewalPer;

                inputWrapper.NumberOfLocations = branchVal+1 ;

                inputWrapper.VehicleCategories= businessLicense.CADMV_NewVehicles__c;

                inputWrapper.LateRenewal= (businessLicense.ApplicationType==CADMV_AppConstants.RENEWAL && businessLicense.CADMV_RenewalPeriodEndDate__c < System.Today())?true:false;

                //inputWrapper.SchoolOperatororInstructorisOwner= false;

                inputWrapper.NumberofClassrooms = classroomVal;

                //inputWrapper.ExamTaken = false;

                //inputWrapper.NumberofAttempts;

                //inputWrapper.Reschedule= false;

                //inputWrapper.AcquisitionDate;

                inputWrapper.AutobrokerEndorsement = businessLicense.Is_Autobroker_Endorsement__c;

                inputWrapper.NumberofAutoPlates = businessLicense.CADMV_NumberofAutoPlates__c!=null ? businessLicense.CADMV_NumberofAutoPlates__c.intValue():0;

                inputWrapper.NumberofMotorcyclePlates = businessLicense.CADMV_NumberofMotorcyclePlates__c!=null ? businessLicense.CADMV_NumberofMotorcyclePlates__c.intValue():0;

                inputWrapper.DaysAfterExpiration = periodEndVal;

                inputWrapper.County= businessLicense.County__c;

                inputWrapper.Zip= businessLicense.SitePostalCode ;

                inputWrapper.City= businessLicense.sitecity;

                //inputWrapper.NumberofRequests;

                HttpResponse response = sendFeeRequestData(inputWrapper);

                if(response!=null)

                {

                    outputWrapper = (CADMV_FeeCompWrapper) JSON.deserialize(response.getBody(),CADMV_FeeCompWrapper.Class);

                    outputWrapper.ApplicationId = businessLicenseAppId;

                    outputWrapper.AccountId = businessLicense.AccountId;

                    outputWrapper.AppRecordType = CADMV_AppConstants.BLA;

                    createFeesGeneric(outputWrapper);

                    

                    update Security.stripInaccessible(AccessType.UPDATABLE, updateRegTrxnFeeList).getRecords(); //SAST

                }

                else

                {

                    CADMV_Utility.debug(CADMV_AppConstants.NULL_RESPONSE);

                }

            }

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

    }

    

    /**************************************************************************************************

    * Method Name - createFeesForIA

    * Params - IA Id

    * Description - Used to create request to Red Hat via mulesoft to get calulated fees.

    * ***************************************************************************************************/

    public static void createFeesForIA(String individualLicenseAppId)

    {        

        // System.debug('>>IA:'+individualLicenseAppId);

        CADMV_FeeCompWrapper.RequestRecordsWrapper inputWrapper = new CADMV_FeeCompWrapper.RequestRecordsWrapper();

        CADMV_FeeCompWrapper outputWrapper = new CADMV_FeeCompWrapper();

        //List<RegulatoryTrxnFee> updateRegTrxnFeeList = new List<RegulatoryTrxnFee>();

        List<RegulatoryTrxnFee> updateRegTrxnFeeList = new List<RegulatoryTrxnFee>();

        try{

            List<RegulatoryTrxnFee> oldRegTrxnFeeList = [

                SELECT id, ParentRecordId, CADMV_OverrideFeeRecalculation__c, Status 

                FROM RegulatoryTrxnFee 

                WHERE ParentRecordId =:individualLicenseAppId

                    AND 

                    (

                        Status =: CADMV_AppConstants.DUE 

                        OR 

                        Status =: CADMV_AppConstants.DRAFT

                    ) 

                    AND CADMV_Type__c =: CADMV_AppConstants.APPLICATION_FEE

                WITH SECURITY_ENFORCED

            ];

            for(RegulatoryTrxnFee regFee : oldRegTrxnFeeList)

            {

                if(regFee.CADMV_OverrideFeeRecalculation__c == false)

                {

                    //updateRegTrxnFeeList.add(regFee);

                    regFee.Status = 'Canceled';

                    updateRegTrxnFeeList.add(regFee);

                }

            }

            // System.debug('>>> oldRegTrxnFeeList:'+oldRegTrxnFeeList);

            if(updateRegTrxnFeeList != null && !updateRegTrxnFeeList.isEmpty() || oldRegTrxnFeeList.isEmpty())

            {

                IndividualApplication individualLicense = [

                    SELECT Id, Name, LicenseType.Name, ApplicationType,

                        CADMV_RenewalPeriodEndDate__c,AccountId

                    FROM IndividualApplication

                    WHERE Id =:individualLicenseAppId 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                if(individualLicense != null){

                    // System.debug('>>> indi'+individualLicense);

                    List<RegulatoryTrxnFee> examFeeList = new List<RegulatoryTrxnFee>([

                        SELECT Id,CADMV_Type__c,Person_Examination__r.CADMV_Individual_Application__c, Status 

                        FROM RegulatoryTrxnFee 

                        WHERE Person_Examination__r.CADMV_Individual_Application__c =:individualLicenseAppId

                            AND CADMV_Type__c =: CADMV_AppConstants.EXAM_FEE 

                            AND Status =: CADMV_AppConstants.PAID

                        WITH SECURITY_ENFORCED    

                    ]);

                    

                    inputWrapper.TriggerType= CADMV_AppConstants.APPLICATION;

                    inputWrapper.LicenseType= individualLicense.LicenseType.Name;

                    inputWrapper.ApplicationType= individualLicense.ApplicationType;

                    inputWrapper.EffectiveDate = (individualLicense.ApplicationType==CADMV_AppConstants.RENEWAL && individualLicense.CADMV_RenewalPeriodEndDate__c > System.Today())?individualLicense.CADMV_RenewalPeriodEndDate__c.date():System.Today();

                    //inputWrapper.NumberOfBranches = to be added;

                    //inputWrapper.RenewalPeriod = to be added;

                    //inputWrapper.NumberOfLocations = to be added;

                    //inputWrapper.VehicleCategories= individualLicense.CADMV_NewVehicles__c;

                    inputWrapper.LateRenewal= (individualLicense.ApplicationType==CADMV_AppConstants.RENEWAL && individualLicense.CADMV_RenewalPeriodEndDate__c < System.Today())?true:false;

                    inputWrapper.SchoolOperatororInstructorisOwner= false; //PENDING

                    //inputWrapper.NumberofClassrooms = to be added;

                    inputWrapper.ExamTaken = !examFeeList.isEmpty() ? true : false;

                    //inputWrapper.NumberofAttempts;

                    //inputWrapper.Reschedule= false;

                    //inputWrapper.AcquisitionDate;

                    //inputWrapper.AutobrokerEndorsement = individualLicense.Is_Autobroker_Endorsement__c;

                    //inputWrapper.NumberofAutoPlates = individualLicense.CADMV_NumberofAutoPlates__c!=null ? individualLicense.CADMV_NumberofAutoPlates__c.intValue():0;

                    //inputWrapper.NumberofMotorcyclePlates = individualLicense.CADMV_NumberofMotorcyclePlates__c!=null ? individualLicense.CADMV_NumberofMotorcyclePlates__c.intValue():0;

                    //inputWrapper.DaysAfterExpiration = to be added;

                    //inputWrapper.County= individualLicense.County__c;

                    //inputWrapper.Zip= individualLicense.SitePostalCode ;

                    //inputWrapper.City= individualLicense.sitecity;

                    //inputWrapper.NumberofRequests;

                    // System.debug('In IA Input Wrapper '+inputWrapper);

                    HttpResponse response = sendFeeRequestData(inputWrapper);

                    if(response!=null)

                    {

                        outputWrapper = (CADMV_FeeCompWrapper) JSON.deserialize(response.getBody(),CADMV_FeeCompWrapper.Class);

                        outputWrapper.ApplicationId = individualLicenseAppId;

                        outputWrapper.AccountId = individualLicense.AccountId;

                        outputWrapper.AppRecordType = CADMV_AppConstants.BLA;

                        createFeesGeneric(outputWrapper);

                        

                        update Security.stripInaccessible(AccessType.UPDATABLE, updateRegTrxnFeeList).getRecords(); //SAST

                    }

                    else

                    {

                        CADMV_Utility.debug(CADMV_AppConstants.NULL_RESPONSE); 

                    }

                }

            }

            

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

    }

    /**************************************************************************************************

    * Method Name - createFeesForExam

    * Params - IA Id

    * Description - Used to create request to Red Hat via mulesoft to get calulated fees.

    * ***************************************************************************************************/

    public static void createFeesForExam(String examAppId)

    {        

        CADMV_FeeCompWrapper.RequestRecordsWrapper inputWrapper = new CADMV_FeeCompWrapper.RequestRecordsWrapper();

        CADMV_FeeCompWrapper outputWrapper = new CADMV_FeeCompWrapper();

        try{

            PersonExamination examRecord = [

                SELECT Id, Name , CADMV_Exam_Attempt__c, CADMV_Individual_Application__c, CADMV_Business_License_Application__c

                FROM PersonExamination

                WHERE Id =:examAppId 

                WITH SECURITY_ENFORCED

                LIMIT 1

            ];

            String accountId;

            

            if(examRecord != null){

                Id applicationId = examRecord.CADMV_Business_License_Application__c != null ? examRecord.CADMV_Business_License_Application__c : examRecord.CADMV_Individual_Application__c != null ? examRecord.CADMV_Individual_Application__c : '';

                String sobjectType = applicationId.getSObjectType().getDescribe().getName();

                if(applicationId != null){

                    if(sobjectType == CADMV_AppConstants.BLA_API_NAME){

                        // System.debug('>>>Exam BLA');

                        BusinessLicenseApplication businessLicense = [

                            SELECT Id, Name, LicenseType.Name, ApplicationType,AccountId

                            FROM BusinessLicenseApplication

                            WHERE Id =:applicationId 

                            WITH SECURITY_ENFORCED

                            LIMIT 1

                        ];

                        

                        inputWrapper.LicenseType= businessLicense.LicenseType.Name;

                        inputWrapper.ApplicationType= businessLicense.ApplicationType;

                        accountId = businessLicense.AccountId;

                    }

                    else if(sobjectType == CADMV_AppConstants.IA_API_NAME){

                        // System.debug('>>>Exam IA');

                        IndividualApplication individualLicense = [

                            SELECT Id,AccountId,LicenseType.Name, ApplicationType 

                            FROM IndividualApplication

                            WHERE Id =: applicationId 

                            WITH SECURITY_ENFORCED

                            LIMIT 1

                        ];

                        inputWrapper.LicenseType= individualLicense.LicenseType.Name;

                        inputWrapper.ApplicationType= individualLicense.ApplicationType;

                        accountId = individualLicense.AccountId;

                    }

                    inputWrapper.TriggerType= CADMV_AppConstants.EXAM; 

                    inputWrapper.EffectiveDate = System.Today();

                    inputWrapper.NumberofAttempts = examRecord.CADMV_Exam_Attempt__c != null ? Integer.valueOf(examRecord.CADMV_Exam_Attempt__c) : 0;

                    inputWrapper.Reschedule = false; //Defaulting it ftoFalse as the functionality is not yet build  

                    //inputWrapper.NumberOfBranches = to be added;

                    //inputWrapper.RenewalPeriod = to be added;

                    //inputWrapper.NumberOfLocations = to be added;

                    //inputWrapper.VehicleCategories= examRecord.CADMV_NewVehicles__c;

                    //inputWrapper.LateRenewal= (examRecord.ApplicationType==CADMV_AppConstants.RENEWAL && businessLicense.CADMV_RenewalPeriodEndDate__c < System.Today())?true:false;

                    //inputWrapper.SchoolOperatororInstructorisOwner= false;

                    //inputWrapper.NumberofClassrooms = to be added;

                    //inputWrapper.ExamTaken = false;

                    

                    //inputWrapper.AcquisitionDate;

                    //inputWrapper.AutobrokerEndorsement = businessLicense.Is_Autobroker_Endorsement__c;

                    //inputWrapper.NumberofAutoPlates = businessLicense.CADMV_NumberofAutoPlates__c!=null ? businessLicense.CADMV_NumberofAutoPlates__c.intValue():0;

                    //inputWrapper.NumberofMotorcyclePlates = businessLicense.CADMV_NumberofMotorcyclePlates__c!=null ? businessLicense.CADMV_NumberofMotorcyclePlates__c.intValue():0;

                    //inputWrapper.DaysAfterExpiration = to be added;

                    //inputWrapper.County= businessLicense.County__c;

                    //inputWrapper.Zip= businessLicense.SitePostalCode ;

                    //inputWrapper.City= businessLicense.sitecity;

                    //inputWrapper.NumberofRequests; 

                    HttpResponse response = sendFeeRequestData(inputWrapper);

                    if(response!=null)

                    {

                        outputWrapper = (CADMV_FeeCompWrapper) JSON.deserialize(response.getBody(),CADMV_FeeCompWrapper.Class);

                        outputWrapper.PersonExam = examAppId;

                        outputWrapper.ApplicationId = applicationId;

                        outputWrapper.AccountId = accountId;

                        outputWrapper.AppRecordType = CADMV_AppConstants.EXAM;

                        createFeesGeneric(outputWrapper);

                    }

                    else

                    {

                        CADMV_Utility.debug(CADMV_AppConstants.NULL_RESPONSE);

                    }

                }

            }

            

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

    }

    /**************************************************************************************************

    * Method Name - createFeesForFringerprint 

    * Params - accountId and applicationId

    * Description - Used to create request to Red Hat via mulesoft to get calulated fees.  

    * ***************************************************************************************************/

    public static void createFeesForFingerprint(String accountId, Id applicationId)

    {        

        // system.debug('>>> Fee creation'+accountId+', App:'+applicationId);

        Boolean noRecalculation = false;

        CADMV_FeeCompWrapper.RequestRecordsWrapper inputWrapper = new CADMV_FeeCompWrapper.RequestRecordsWrapper();

        CADMV_FeeCompWrapper outputWrapper = new CADMV_FeeCompWrapper();

        List<RegulatoryTrxnFee> updateRegTrxnFeeList = new List<RegulatoryTrxnFee>();

        List<RegulatoryTrxnFeeItem> deleteRegTrxnFeeItemsList = new List<RegulatoryTrxnFeeItem>();

        HttpResponse response = new HttpResponse();

        try{

            List<RegulatoryTrxnFee> oldRegTrxnFeeList = [

                SELECT Id, ParentRecordId, CADMV_OverrideFeeRecalculation__c, Status, 

                    (

                        SELECT Id 

                        FROM RegulatoryTrxnFeeItems

                    )

                FROM RegulatoryTrxnFee 

                WHERE ParentRecordId =:applicationId 

                    AND 

                    (

                        Status =: CADMV_AppConstants.DUE 

                        OR 

                        Status =: CADMV_AppConstants.DRAFT

                    ) 

                    AND CADMV_Type__c =: CADMV_AppConstants.FINGERPRINT_CARD

                WITH SECURITY_ENFORCED

            ];

            // System.debug('Fee:'+oldRegTrxnFeeList);

            for(RegulatoryTrxnFee regFee : oldRegTrxnFeeList)

            {

                if(regFee.CADMV_OverrideFeeRecalculation__c == false)

                {

                    regFee.Status = 'Canceled';

                    updateRegTrxnFeeList.add(regFee);

                    /*if(regFee.RegulatoryTrxnFeeItems != null && !regFee.RegulatoryTrxnFeeItems.isEmpty()){

                        deleteRegTrxnFeeItemsList.addAll(regFee.RegulatoryTrxnFeeItems);

                    }*/

                }else if(regFee.CADMV_OverrideFeeRecalculation__c == true){

                    NoRecalculation = true;

                }

            }

            // system.debug('>>> Delete:'+updateRegTrxnFeeList+' NoREcalc:'+NoRecalculation);

            String sobjectType = applicationId.getSObjectType().getDescribe().getName();

            if(NoRecalculation == false && sobjectType == CADMV_AppConstants.BLA_API_NAME){

                // System.debug('>>> BLA');

                BusinessLicenseApplication businessLicense = [

                    SELECT Id, Name, LicenseType.Name, ApplicationType,CADMV_NumberofAutoPlates__c,

                        CADMV_RenewalPeriodEndDate__c,CADMV_NewVehicles__c,Is_Autobroker_Endorsement__c,

                        CADMV_NumberofMotorcyclePlates__c,AccountId

                    FROM BusinessLicenseApplication

                    WHERE Id =:applicationId 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                inputWrapper.TriggerType= CADMV_AppConstants.FINGERPRINT;

                inputWrapper.LicenseType= businessLicense.LicenseType.Name;

                //inputWrapper.ApplicationType= businessLicense.ApplicationType;

                inputWrapper.EffectiveDate = System.Today();

                response = sendFeeRequestData(inputWrapper);

                outputWrapper = (CADMV_FeeCompWrapper) JSON.deserialize(response.getBody(),CADMV_FeeCompWrapper.Class);

                

            } else if(NoRecalculation == false && sobjectType == CADMV_AppConstants.IA_API_NAME){

                // System.debug('>>> IA');

                IndividualApplication individualLicense = [

                    SELECT Id,AccountId,LicenseType.Name, ApplicationType 

                    FROM IndividualApplication

                    WHERE Id =: applicationId 

                    WITH SECURITY_ENFORCED

                    LIMIT 1

                ];

                

                inputWrapper.TriggerType= CADMV_AppConstants.FINGERPRINT;

                inputWrapper.LicenseType= individualLicense.LicenseType.Name;

                //inputWrapper.ApplicationType= individualLicense.ApplicationType;

                inputWrapper.EffectiveDate = System.Today();

                response = sendFeeRequestData(inputWrapper);

                outputWrapper = (CADMV_FeeCompWrapper) JSON.deserialize(response.getBody(),CADMV_FeeCompWrapper.Class);

            }

            // System.debug('>>> after app check:'+outputWrapper);

            if(response!=null)

            {

                outputWrapper.ApplicationId = applicationId;

                outputWrapper.AccountId = accountId;

                outputWrapper.AppRecordType = CADMV_AppConstants.FINGERPRINT;

                createFeesGeneric(outputWrapper);  

                

                update Security.stripInaccessible(AccessType.UPDATABLE, updateRegTrxnFeeList).getRecords(); //SAST

                //delete deleteRegTrxnFeeItemsList;

            }

            else

            {

                CADMV_Utility.debug(CADMV_AppConstants.NULL_RESPONSE);

            }

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

    }

    /**************************************************************************************************

* Method Name - sendFeeRequestData

* Params - CADMV_FeeCompWrapper.RequestRecordsWrapper

* Description - Used to make callout to Red Hat via mulesoft to get calculate fees in the resopnse.

* ***************************************************************************************************/

    Public Static HttpResponse sendFeeRequestData(CADMV_FeeCompWrapper.RequestRecordsWrapper inputWrapper)

    {

        String requestBody = '';

        HttpResponse response = new HttpResponse();

        try{

            CADMV_CalloutUtility.HeaderAndEndpointWrapper headerAndEndpoints = new CADMV_CalloutUtility.HeaderAndEndpointWrapper();

            headerAndEndpoints = CADMV_CalloutUtility.getEndpointAndHeaderDetails(CADMV_AppConstants.FEECALLOUT);

            List<CADMV_RequestHeaderWrapper> headers = headerAndEndpoints.listofheaders;

            requestBody = JSON.serialize(inputWrapper); 

            // system.debug('inputWrapper-'+JSON.serializePretty(inputWrapper));       

            // system.debug('Body-'+JSON.serializePretty(requestBody));

            response = CADMV_CalloutUtility.sendRequest(headerAndEndpoints.endpointURL,requestBody,CADMV_AppConstants.REQUEST_METHOD_POST,headers,NULL,CADMV_AppConstants.CADMV_FEECOMPCALLOUTSERVICE_CLASS,CADMV_AppConstants.SEND_FEEREQUEST_DATA);

            CADMV_CalloutUtility.logCalloutStatus(CADMV_AppConstants.CADMV_FEECOMPCALLOUTSERVICE_CLASS,CADMV_AppConstants.SEND_FEEREQUEST_DATA, CADMV_AppConstants.FEECALLOUT, requestBody, response);

        }catch(Exception ex){

            CADMV_Utility.debug('ex'+ex.getLineNumber());

            CADMV_CreateErrorLogException.logApplicationError(ex);

        }

        if(response.getStatusCode() == 200 || response.getStatusCode() == 201) 

        {       

            return response;

        }

        else{

            return null;

        }

    }

    

}