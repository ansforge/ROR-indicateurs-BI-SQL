USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ExigenceQualite_ST2_CO4 AS 

SELECT
    EntiteGeographique.CodeRegion
    ,ID_EntiteGeographique
	,EntiteGeographique.IdNat_Struct
	,EntiteGeographique.NumFINESS AS NumFINESS_EG_ROR
	,Finess.nmfinessetab_stru AS NumFINESS_EG_FINESS
    ,EntiteJuridique.NumFINESS AS NumFINESS_EJ_ROR
    ,Finess.nmfinessej_stru AS NumFINESS_EJ_FINESS
    ,EntiteGeographique.CodeNOS_CategorieEG AS CodeCategorieEG_ROR
    ,Finess.categetab_stru AS CodeCategorieEG_FINESS
    -- Regle exigence ST2
    ,CASE 
        WHEN EntiteJuridique.NumFINESS = Finess.nmfinessej_stru THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigenceST2
    -- Regle exigence CO4
    , CASE
        WHEN EntiteGeographique.CodeNOS_CategorieEG IN ('SA05','SA07','SA08','SA09') THEN NULL
		WHEN EntiteGeographique.CodeNOS_CategorieEG = Finess.categetab_stru THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigenceCO4
    , Finess.dtmaj_stru AS DT_MAJ_Finess
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteJuridique AS EntiteJuridique
    ON EntiteGeographique.FK_EntiteJuridique = EntiteJuridique.ID_EntiteJuridique
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS Finess 
    ON EntiteGeographique.NumFINESS = Finess.nmfinessetab_stru
	AND Finess.topsource_stru = 'FINESS' 
    AND Finess.typeidpm_stru = 'EG'
WHERE EntiteGeographique.NumFINESS IS NOT NULL
	AND EntiteGeographique.CodeRegion NOT IN ('-1','-2','-3')
	AND (EntiteGeographique.DateFermeture IS NULL 
		OR (EntiteGeographique.DateFermeture IS NOT NULL 
			AND EntiteGeographique.CodeNOS_TypeFermeture = 'PRO'))