USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_ExigenceQualite_CO2 AS

WITH OffreMaternite AS (
    SELECT
        Offre.ID_OrganisationInterne
        ,Offre.CodeRegion
        ,Offre.IdentifiantOI AS IdentifiantOffre
        ,Offre.FK_EntiteGeographique
        ,Offre.NomOI AS NomOffre
		,Offre.CodeNOS_TypeMaternite
        ,TypeMaternite.Libelle AS TypeMaternite
        ,CONCAT(Offre.CodeNOS_ModePriseEnCharge,' - ', ModePriseEnCharge.Libelle) AS ModePriseEnCharge
        ,COUNT(CASE WHEN AO.CodeNOS_ActiviteOperationnelle in ('100','260') THEN Offre.ID_OrganisationInterne END) AS NB_AO_Obstetrique
        ,COUNT(CASE WHEN AO.CodeNOS_ActiviteOperationnelle = '094' THEN Offre.ID_OrganisationInterne END) AS NB_AO_Neonat
        ,COUNT(CASE WHEN AO.CodeNOS_ActiviteOperationnelle = '369' THEN Offre.ID_OrganisationInterne END) AS NB_AO_SoinsIntensifsNeonat
        ,COUNT(CASE WHEN AO.CodeNOS_ActiviteOperationnelle = '128' THEN Offre.ID_OrganisationInterne END) AS NB_AO_ReanimationNeonat
        ,CASE WHEN COUNT(CASE WHEN AO.CodeNOS_ActiviteOperationnelle in ('100','260') THEN Offre.ID_OrganisationInterne END) > 0 THEN 'O' ELSE 'N' END AS FG_OffreMaternite
        ,CASE WHEN (Offre.NomOI LIKE '%maternite%' COLLATE French_CI_AI) THEN 'O' ELSE 'N' END AS FG_NomContientMaternite
    FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS AO
        ON Offre.ID_OrganisationInterne = AO.FK_OrganisationInterne
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as TypeMaternite
        ON Offre.FK_NOS_TypeMaternite = TypeMaternite.ID_NOS
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as ModePriseEnCharge
        ON Offre.FK_NOS_ModePriseEnCharge = ModePriseEnCharge.ID_NOS
    WHERE Offre.CodeNOS_TypeOI = '4'
		-- 14 Hospitalisation Kangourou, 28 - Hospitalisation Complete, 29 - Hospitalisation de Jour, 30 - Hospitalisation de Nuit, 34 - Hospitalisation de Semaine
		AND Offre.CodeNOS_ModePriseEnCharge in ('14','28','29','30','34') 
		-- 094 Néonatologie, 100 Obstétrique, 128 Réanimation spécialisée néonatale, 260 Urgences spécialisées obstétricales, 369 Soins intensifs spécialisés néonatalogique
		AND (AO.CodeNOS_ActiviteOperationnelle in ('094','100','128','260','369') 
			OR Offre.CodeNOS_TypeMaternite IS NOT NULL)
		AND Offre.DateFermetureDefinitive IS NULL
    GROUP BY Offre.CodeRegion
    , Offre.ID_OrganisationInterne
    , Offre.IdentifiantOI
    , Offre.FK_EntiteGeographique
    , Offre.NomOI
	, Offre.CodeNOS_TypeMaternite
    , TypeMaternite.Libelle
    , CONCAT(Offre.CodeNOS_ModePriseEnCharge,' - ', ModePriseEnCharge.Libelle)
)

,AgregationEtablissement AS (
SELECT 
	EntiteGeographique.CodeRegion
	,EntiteGeographique.ID_EntiteGeographique
	,COUNT(CASE WHEN OffreMaternite.NB_AO_Obstetrique > 0 THEN ID_OrganisationInterne END) AS NB_OffreMaternite
	,COUNT(CASE WHEN OffreMaternite.NB_AO_Neonat > 0 THEN ID_OrganisationInterne END) AS NB_OffreHospitNeonat
	,COUNT(CASE WHEN OffreMaternite.NB_AO_SoinsIntensifsNeonat > 0 THEN ID_OrganisationInterne END) AS NB_OffreHospitSoinsIntensifsNeonat
	,COUNT(CASE WHEN OffreMaternite.NB_AO_ReanimationNeonat > 0 THEN ID_OrganisationInterne END) AS NB_OffreHospitReanimationNeonat
	,COUNT(CASE WHEN OffreMaternite.FG_NomContientMaternite = 'O' THEN ID_OrganisationInterne END) AS NB_OffreNomContientMaternite
	,CASE 
		WHEN COUNT(CASE WHEN OffreMaternite.NB_AO_Obstetrique > 0 AND OffreMaternite.CodeNOS_TypeMaternite IS NOT NULL THEN ID_OrganisationInterne END) > 0 THEN 'O' 
		ELSE 'N' END AS FG_OffreMaterniteAvecType
	,CASE 
		WHEN COUNT(CASE WHEN OffreMaternite.CodeNOS_TypeMaternite = '04' THEN ID_OrganisationInterne END) > 0 THEN 'Type 3'
		WHEN COUNT(CASE WHEN OffreMaternite.CodeNOS_TypeMaternite = '03' THEN ID_OrganisationInterne END) > 0 THEN 'Type 2B'
		WHEN COUNT(CASE WHEN OffreMaternite.CodeNOS_TypeMaternite = '02' THEN ID_OrganisationInterne END) > 0 THEN 'Type 2A'
		WHEN COUNT(CASE WHEN OffreMaternite.CodeNOS_TypeMaternite = '01' THEN ID_OrganisationInterne END) > 0 THEN 'Type 1'
	 ELSE 'Aucun' END AS TypeMaterniteDeclare
	,CASE 
		WHEN MAX(ISNULL(Finess.NB_AutorisationReanimationNeonat,0)) > 0 THEN 'Type 3'
		WHEN MAX(ISNULL(Finess.NB_AutorisationSoinsInstensifsNeonat,0)) > 0 THEN 'Type 2B'
		WHEN MAX(ISNULL(Finess.NB_AutorisationNeonat,0)) > 0 THEN 'Type 2A'
		WHEN MAX(ISNULL(Finess.NB_AutorisationObstetrique,0)) > 0 THEN 'Type 1'
	ELSE 'Non autorise' END AS TypeMaterniteAutorise
FROM OffreMaternite
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
    ON OffreMaternite.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Finess
	ON EntiteGeographique.NumFiness = Finess.NumFINESS_EG
GROUP BY EntiteGeographique.CodeRegion, EntiteGeographique.ID_EntiteGeographique
)

SELECT 
	CodeRegion
	,ID_EntiteGeographique
	,NB_OffreMaternite
	,NB_OffreHospitNeonat
	,NB_OffreHospitSoinsIntensifsNeonat
	,NB_OffreHospitReanimationNeonat
	,NB_OffreNomContientMaternite
	,FG_OffreMaterniteAvecType
	,TypeMaterniteDeclare
	,TypeMaterniteAutorise
	,CASE 
		WHEN NB_OffreHospitReanimationNeonat = 0 AND NB_OffreHospitSoinsIntensifsNeonat = 0 AND NB_OffreHospitNeonat = 0 AND NB_OffreMaternite = 0 
		AND TypeMaterniteDeclare = 'Aucun' AND NB_OffreNomContientMaternite = 0 THEN 'Conforme'
		WHEN NB_OffreHospitReanimationNeonat > 0 AND NB_OffreHospitSoinsIntensifsNeonat > 0 AND NB_OffreHospitNeonat > 0 AND NB_OffreMaternite > 0
		AND TypeMaterniteDeclare = 'Type 3' AND TypeMaterniteAutorise = TypeMaterniteDeclare AND NB_OffreNomContientMaternite > 0 THEN'Conforme'
		WHEN NB_OffreHospitReanimationNeonat = 0 AND NB_OffreHospitSoinsIntensifsNeonat > 0 AND NB_OffreHospitNeonat > 0 AND NB_OffreMaternite > 0
		AND TypeMaterniteDeclare = 'Type 2B' AND TypeMaterniteAutorise = TypeMaterniteDeclare AND NB_OffreNomContientMaternite > 0 THEN 'Conforme'
		WHEN NB_OffreHospitReanimationNeonat = 0 AND NB_OffreHospitSoinsIntensifsNeonat = 0 AND NB_OffreHospitNeonat > 0 AND NB_OffreMaternite > 0
		AND TypeMaterniteDeclare = 'Type 2A' AND TypeMaterniteAutorise = TypeMaterniteDeclare AND NB_OffreNomContientMaternite > 0 THEN 'Conforme'
		WHEN NB_OffreHospitReanimationNeonat = 0 AND NB_OffreHospitSoinsIntensifsNeonat = 0 AND NB_OffreHospitNeonat = 0 AND NB_OffreMaternite > 0 
		AND TypeMaterniteDeclare = 'Type 1' AND TypeMaterniteAutorise = TypeMaterniteDeclare AND NB_OffreNomContientMaternite > 0 THEN 'Conforme'
	 ELSE 'Ecart' END AS StatutExigence
FROM AgregationEtablissement