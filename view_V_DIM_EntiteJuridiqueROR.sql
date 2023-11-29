USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_EntiteJuriqueROR AS

SELECT DISTINCT
	EJ.ID_EntiteJuridique
	,EJ.CodeRegion
	,CASE
		WHEN EJ.CodeRegion IN ('01','02','03','04','06') THEN CONCAT('97',RIGHT(EJ.CodeRegion,1))
		WHEN EJ.CodeRegion IN ('94') THEN '-2'
		ELSE LEFT(Adresse_CodePostal,2) 
	END AS CodeDepartement
	,categorieEG.DomaineROR
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteJuridique AS EJ
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EG
	ON EJ.ID_EntiteJuridique = eg.FK_EntiteJuridique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS categorieEG
	ON EG.FK_NOS_CategorieEG = categorieEG.ID_NOS
WHERE categorieEG.DomaineROR <> 'Non defini'
