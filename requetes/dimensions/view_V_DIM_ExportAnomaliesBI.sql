USE DATALAB 
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_ExportAnomaliesBI AS 
SELECT
UrlNOS_Thematique AS 'code.system'
,CodeNOS_Thematique AS 'code.code'
,DescriptionAnomalie AS 'description'
,RessourceAnomalie AS 'focus.reference'
,eg.IdNat_Struct AS 'focus.identifier'
,UrlNOS_Action AS 'reasonCode.system'
,CodeNOS_Action AS 'reasonCode.code'
,CodeExigence AS 'input.ruleErrorId.value'
,CO4.CodeCategorieEG_ROR AS 'input.errorValue.value'
,CO4.CodeCategorieEG_FINESS AS 'input.proposedValue.value'
,FhirPathAnomalie AS 'input.pathElementError.value'
,SystemRequester AS 'input.systemRequester.value'
,IdentifierRequester AS 'input.identifierRequester.value'
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_ST2_CO4 AS CO4
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS eg
	ON CO4.ID_EntiteGeographique = eg.ID_EntiteGeographique
CROSS JOIN DATALAB.DLAB_002.T_DIM_ImportExigenceQualiteROR AS exigence
WHERE StatutExigenceCO4 = 'Ecart' 
	AND exigence.CodeExigence = 'CO4' 
	AND CO4.NumFINESS_EG_ROR != '888888888'