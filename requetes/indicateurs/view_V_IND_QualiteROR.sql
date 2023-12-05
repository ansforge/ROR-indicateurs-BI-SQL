USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_IND_QualiteROR AS



WITH aggregation AS (
-- Exigence Qualite EX1.2
SELECT
	CONCAT('EX1.2|',CodeRegion,'|',CodeDepartement,'|',DomaineROR) AS ID_IndicateurQualiteROR
    ,'EX1.2' AS CodeExigence
	,CodeRegion
    ,CodeDepartement
    ,DomaineROR
    ,COUNT(ID_StructureExigence) AS NB_PerimetreExigence
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN ID_StructureExigence END) AS NB_EcartsExigence
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_EX1_2
GROUP BY CodeRegion, CodeDepartement, DomaineROR
UNION ALL
-- Exigence Qualite EX2
SELECT
	CONCAT('EX2|', EX2.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'EX2'
	,EX2.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(EX2.ID_EntiteGeographique)
    ,COUNT(CASE WHEN EX2.StatutExigence = 'Ecart' THEN EX2.ID_EntiteGeographique END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_EX2 AS EX2
INNER JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON EX2.ID_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY EX2.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite EX3
SELECT
	CONCAT('EX3|',CodeRegion,'|',CodeDepartement,'|',DomaineROR)
    ,'EX3'
	,CodeRegion
    ,CodeDepartement
    ,DomaineROR
    ,COUNT(ID_StructureFINESS)
    ,COUNT(CASE WHEN StatutExigenceEX3 = 'Ecart' THEN ID_StructureFINESS END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_EX3_EX4_EX5
WHERE StatutExigenceEX3 IS NOT NULL
GROUP BY CodeRegion, CodeDepartement, DomaineROR
UNION ALL
-- Exigence Qualite EX4
SELECT
	CONCAT('EX4|',CodeRegion,'|',CodeDepartement,'|',DomaineROR)
    ,'EX4'
	,CodeRegion
    ,CodeDepartement
    ,DomaineROR
    ,COUNT(ID_StructureFINESS)
    ,COUNT(CASE WHEN StatutExigenceEX4 = 'Ecart' THEN ID_StructureFINESS END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_EX3_EX4_EX5
WHERE StatutExigenceEX4 IS NOT NULL
GROUP BY CodeRegion, CodeDepartement, DomaineROR
UNION ALL
-- Exigence Qualite EX5
SELECT
	CONCAT('EX5|',CodeRegion,'|',CodeDepartement,'|',DomaineROR)
    ,'EX5'
	,CodeRegion
    ,CodeDepartement
    ,DomaineROR
    ,COUNT(ID_StructureFINESS)
    ,COUNT(CASE WHEN StatutExigenceEX5 = 'Ecart' THEN ID_StructureFINESS END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_EX3_EX4_EX5
WHERE StatutExigenceEX5 IS NOT NULL
GROUP BY CodeRegion, CodeDepartement, DomaineROR
UNION ALL
-- Exigence Qualite ST2
SELECT
	CONCAT('ST2|', ST2.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'ST2'
	,ST2.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(ST2.ID_EntiteGeographique)
    ,COUNT(CASE WHEN ST2.StatutExigenceST2 = 'Ecart' THEN ST2.ID_EntiteGeographique END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_ST2_CO4 AS ST2
INNER JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON ST2.ID_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
WHERE ST2.StatutExigenceST2 IS NOT NULL
GROUP BY ST2.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite ST3
SELECT
	CONCAT('ST3|', ST3.CodeRegion,'|', ST3.CodeDepartement,'|', ISNULL(NOSCategorieEG.DomaineROR, 'Non defini'))
    ,'ST3'
	,ST3.CodeRegion
    ,ST3.CodeDepartement
    ,ISNULL(NOSCategorieEG.DomaineROR, 'Non defini')
    ,COUNT(ID_Structure)
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN ID_Structure END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_ST3 AS ST3
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteJuridique AS EntiteJuridique
	ON ST3.ID_Structure = EntiteJuridique.ID_EntiteJuridique 
	AND ST3.TypeStructure = 'EJ'
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON ST3.ID_Structure = EntiteGeographique.ID_EntiteGeographique
	AND ST3.TypeStructure = 'EG'
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY ST3.CodeRegion, ST3.CodeDepartement, ISNULL(NOSCategorieEG.DomaineROR, 'Non defini')
UNION ALL
-- Exigence Qualite RE1.2
SELECT
	CONCAT('RE1.2|', RE1_2.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'RE1.2'
	,RE1_2.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(RE1_2.ID_EntiteGeographique)
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN RE1_2.ID_EntiteGeographique END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_RE1_2 AS RE1_2
INNER JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON RE1_2.ID_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY RE1_2.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CP5
SELECT
	CONCAT('CP5|', CP5.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CP5'
	,CP5.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(ID_OrganisationInterne)
    ,COUNT(CASE WHEN StatutExigenceCP5 = 'Ecart' THEN ID_OrganisationInterne END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CP5_CP6 AS CP5
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CP5.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
WHERE StatutExigenceCP5 IS NOT NULL
GROUP BY CP5.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CP5
SELECT
	CONCAT('CP6|', CP6.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CP6'
	,CP6.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(ID_OrganisationInterne)
    ,COUNT(CASE WHEN StatutExigenceCP6 = 'Ecart' THEN ID_OrganisationInterne END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CP5_CP6 AS CP6
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CP6.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
WHERE StatutExigenceCP6 IS NOT NULL
GROUP BY CP6.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CP4
SELECT
    CONCAT('CP4|', CodeRegion,'|',CodeDepartement,'|', ISNULL(SecteurEG,'Non defini'))
    ,'CP4'
	,CodeRegion
    ,CodeDepartement
    ,ISNULL(SecteurEG,'Non defini')
    ,COUNT(NumFINESS_EG)
    ,COUNT(CASE WHEN StatutPeuplement <> 'Finalise' THEN NumFINESS_EG END)
FROM DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_EG
WHERE FG_PerimetreSuiviPeuplement = '1'
GROUP BY CodeRegion, CodeDepartement, ISNULL(SecteurEG,'Non defini')
UNION ALL
-- Exigence Qualite CO1
SELECT
    CONCAT('CO1|', CO1.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CO1'
	,CO1.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(ID_OrganisationInterne)
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN ID_OrganisationInterne END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CO1 AS CO1
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CO1.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY CO1.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CO2
SELECT
    CONCAT('CO2|', CO2.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CO2'
	,CO2.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(CO2.ID_EntiteGeographique)
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN CO2.ID_EntiteGeographique END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CO2 AS CO2
INNER JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CO2.ID_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY CO2.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CO3
SELECT
	CONCAT('CO3|', CO3.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CO3'
	,CO3.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(ID_OrganisationInterne)
    ,COUNT(CASE WHEN StatutExigence = 'Ecart' THEN ID_OrganisationInterne END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_CO3 AS CO3
LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CO3.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
GROUP BY CO3.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
UNION ALL
-- Exigence Qualite CO4
SELECT
	CONCAT('CO4|', CO4.CodeRegion,'|', EntiteGeographique.CodeDepartement,'|', NOSCategorieEG.DomaineROR)
    ,'CO4'
	,CO4.CodeRegion
    ,EntiteGeographique.CodeDepartement
    ,NOSCategorieEG.DomaineROR
    ,COUNT(CO4.ID_EntiteGeographique)
    ,COUNT(CASE WHEN StatutExigenceCO4 = 'Ecart' THEN CO4.ID_EntiteGeographique END)
FROM DATALAB.DLAB_002.V_DIM_ExigenceQualite_ST2_CO4 AS CO4
INNER JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
    ON CO4.ID_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS NOSCategorieEG
    ON EntiteGeographique.FK_NOS_CategorieEG = NOSCategorieEG.ID_NOS
WHERE CO4.StatutExigenceCO4 IS NOT NULL
GROUP BY CO4.CodeRegion, EntiteGeographique.CodeDepartement, NOSCategorieEG.DomaineROR
)

SELECT 
	CONCAT(ID_IndicateurQualiteROR,'|',CAST(DATEADD(dd, -(DATEPART(dw, GETDATE()) + @@DATEFIRST -2) % 7,GETDATE()) AS date)) AS ID_IndicateurQualiteROR
	,CAST(DATEADD(dd, -(DATEPART(dw, GETDATE()) + @@DATEFIRST -2) % 7,GETDATE()) AS date) AS DT_Reference
	,'hebdomadaire' AS Periodicite
	,CodeExigence
	,CodeRegion
	,ISNULL(CodeDepartement,'-2') AS CodeDepartement
	,DomaineROR
	,NB_PerimetreExigence
	,NB_EcartsExigence
	,GETDATE() AS DT_UPDATE_TECH
FROM aggregation
UNION ALL
SELECT
	CONCAT(CodeExigence,'|00|-3|',DomaineROR,'|',CAST(DATEADD(dd, -(DATEPART(dw, GETDATE()) + @@DATEFIRST -2) % 7,GETDATE()) AS date))
	,CAST(DATEADD(dd, -(DATEPART(dw, GETDATE()) + @@DATEFIRST -2) % 7,GETDATE()) AS date)
	,'hebdomadaire'
	,CodeExigence
	,'00'
	,'-3'
	,DomaineROR
	,SUM(NB_PerimetreExigence)
	,SUM(NB_EcartsExigence)
	,GETDATE()
FROM aggregation
GROUP BY CodeExigence, DomaineROR
