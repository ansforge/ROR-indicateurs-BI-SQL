USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_ExigenceQualite_EX1_2 AS

SELECT
	-- Création d'un ID concatené car doublons ROR existants sur le numéro FINESS
    CONCAT(Finess.NumFINESS_EG,UniqueID) AS ID_StructureExigence
    ,Finess.NumFINESS_EG AS FK_NumFINESS
    ,EntiteGeographique.ID_EntiteGeographique AS FK_EntiteGeographique
    ,Finess.CodeRegion
    ,Finess.CodeDepartement
	,Finess.DenominationEG_FINESS
    ,Finess.CodeCategorieEG_FINESS
    ,Finess.DomaineROR
    ,Finess.DateAutorisationFINESS
    ,Finess.DateOuvertureFINESS
	,Finess.DateMajFINESS
	,Finess.TelephoneFINESS
	,Finess.EmailFINESS
    ,CASE WHEN ID_EntiteGeographique IS NOT NULL THEN 'Conforme' ELSE 'Ecart' END AS StatutExigence
FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Finess
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
    ON EntiteGeographique.NumFINESS = Finess.NumFINESS_EG
WHERE Finess.TypePerimetreROR = 'Périmètre historique' 
    AND ((Finess.DomaineROR = 'Sanitaire' AND (Finess.NB_AutorisationMCO > 0 OR Finess.NB_AutorisationPSY > 0 OR Finess.NB_AutorisationSMR > 0))
		OR Finess.DomaineROR = 'Medico-Social')