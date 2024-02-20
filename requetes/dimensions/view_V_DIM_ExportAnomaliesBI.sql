USE DATALAB 
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_ExportAnomaliesBI AS 

-- Exigence CO4
SELECT
UrlNOS_Thematique AS 'code.system'
,CodeNOS_Thematique AS 'code.code'
,DescriptionAnomalie AS 'description'
,RessourceAnomalie AS 'focus.reference'
,CO4.IdNat_Struct AS 'focus.identifier'
,UrlNOS_Action AS 'reasonCode.system'
,CodeNOS_Action AS 'reasonCode.code'
,CodeExigence AS 'input.ruleErrorId.value'
,CO4.CodeCategorieEG_ROR AS 'input.errorValue.value'
,CO4.CodeCategorieEG_FINESS AS 'input.proposedValue.value'
,FhirPathAnomalie AS 'input.pathElementError.value'
,SystemRequester AS 'input.systemRequester.value'
,IdentifierRequester AS 'input.identifierRequester.value'
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_ST2_CO4 AS CO4
CROSS JOIN DATALAB.DLAB_002.T_DIM_ImportExigenceQualiteROR AS exigence
WHERE StatutExigenceCO4 = 'Ecart' 
	AND exigence.CodeExigence = 'CO4' 
	AND CO4.NumFINESS_EG_ROR != '888888888'
/*********************************************************
Décommenter cette partie pour ajouter l'exigence CO1 dans la transmission des anomalies au ROR National
-- Exigence C01
UNION ALL
SELECT
	UrlNOS_Thematique AS 'code.system'
	,CodeNOS_Thematique AS 'code.code'
	,DescriptionAnomalie AS 'description'
	,RessourceAnomalie AS 'focus.reference'
	,CO1.IdentifiantOffre AS 'focus.identifier'
	,UrlNOS_Action AS 'reasonCode.system'
	,CodeNOS_Action AS 'reasonCode.code'
	,CodeExigence AS 'input.ruleErrorId.value'
	,NULL AS 'input.errorValue.value'
	,NULL AS 'input.proposedValue.value'
	,FhirPathAnomalie AS 'input.pathElementError.value'
	,SystemRequester AS 'input.systemRequester.value'
	,IdentifierRequester AS 'input.identifierRequester.value'
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CO1 AS CO1
CROSS JOIN DATALAB.DLAB_002.T_DIM_ImportExigenceQualiteROR AS exigence
WHERE StatutExigence = 'Ecart' 
	AND exigence.CodeExigence = 'CO1'
**********************************************************/
/*********************************************************
Décommenter cette partie pour ajouter l'exigence CP5 dans la transmission des anomalies au ROR National
-- Exigence CP5
SELECT
	UrlNOS_Thematique AS 'code.system'
	,CodeNOS_Thematique AS 'code.code'
	,DescriptionAnomalie AS 'description'
	,RessourceAnomalie AS 'focus.reference'
	,CP5.IdentifiantOffre AS 'focus.identifier'
	,UrlNOS_Action AS 'reasonCode.system'
	,CodeNOS_Action AS 'reasonCode.code'
	,CodeExigence AS 'input.ruleErrorId.value'
	,CASE 
		WHEN CodeNOS_CategorieOrganisation IS NULL THEN ''
		WHEN TemporaliteAccueil IS NULL THEN ''
	END AS 'input.errorValue.value'
	,NULL AS 'input.proposedValue.value'
	,FhirPathAnomalie AS 'input.pathElementError.value'
	,SystemRequester AS 'input.systemRequester.value'
	,IdentifierRequester AS 'input.identifierRequester.value'
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CP5_CP6 AS CP5
CROSS JOIN DATALAB.DLAB_002.T_DIM_ImportExigenceQualiteROR AS exigence
WHERE StatutExigenceCP5 = 'Ecart' 
	AND exigence.CodeExigence = 'CP5'
**********************************************************/