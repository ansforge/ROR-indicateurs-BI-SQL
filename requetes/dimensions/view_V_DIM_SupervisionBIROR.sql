USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_SupervisionBIROR AS

WITH union_query AS (
SELECT
	'T_DIM_ActiviteOperationnelle' AS NomTable
	,'ROR Regionaux' AS SourceDonnees
	,CodeRegion
	,MAX(Meta_DateMiseJour) AS Max_MetaDateMiseJour
	,DT_UPDATE_TECH
	,COUNT(*) AS NB_Lignes
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Anomalies'
	,'ROR National'
	,CodeRegion
	,MAX(Date_UpdateAnomalie)
	,DT_UPDATE_TECH
	,COUNT(*)
-- Modifier la base de données lorsqu'un raffraichement supplémentaire du snapshot aura été réalisé
FROM BIROR_DWH.dbo.T_DIM_Anomalies
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_AutresPrestationsNonObligatoiresIncluses'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_AutresPrestationsNonObligatoiresIncluses
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_BoiteLettreMSS'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_BoiteLettreMSS
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_CapaciteHabitation'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_CapaciteHabitation
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_CapacitePriseCharge_AccueilOpe'
	,'ROR National'
	,CodeRegion
	,MAX(Date_MAJ)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_CapacitePriseCharge_AccueilOpe
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_CompetenceSpecifique'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_CompetenceSpecifique
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Contact'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Contact
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_DivisionTerritoriale'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_DivisionTerritoriale
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_EntiteGeographique'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_EntiteJuridique'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteJuridique
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Equipement'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Equipement
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_HebergementMutualise'
	,'ROR National'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_HebergementMutualise
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Horaires'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Horaires
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Lieu'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Lieu
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_LieuRealisationOffre'
	,'ROR National'
	,CodeRegion
	,MAX(Date_MAJ)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_LieuRealisationOffre
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_OrganisationInterne'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Professionnel'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Professionnel
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_SavoirFaire'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_SavoirFaire
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_SecteurPsychiatrique'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_SecteurPsychiatrique
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_SituationOpe_ExercicePro'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_SituationOpe_ExercicePro
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Tarif'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Tarif
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_DIM_Telecommunication'
	,'ROR Regionaux'
	,CodeRegion
	,MAX(Meta_DateMiseJour)
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Telecommunication
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_LIE_AideFinanciere'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_LIE_AideFinanciere
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_LIE_CompetencesRessources'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_LIE_CompetencesRessources
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_LIE_OrganisationInterne_NOS'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS
GROUP BY CodeRegion, DT_UPDATE_TECH
UNION ALL
SELECT
	'T_LIE_PrestationsNonObligatoiresIncluses'
	,'ROR Regionaux'
	,CodeRegion
	,NULL
	,DT_UPDATE_TECH
	,COUNT(*)
FROM BIROR_DWH_SNAPSHOT.dbo.T_LIE_PrestationsNonObligatoiresIncluses
GROUP BY CodeRegion, DT_UPDATE_TECH
)

SELECT
	NomTable
	,SourceDonnees
	,CodeRegion
	,Max_MetaDateMiseJour
	,DT_UPDATE_TECH
	,NB_Lignes
FROM union_query
WHERE DT_UPDATE_TECH NOT IN ('7777-12-31 00:00:00.000','9999-12-31 00:00:00.000','8888-12-31 00:00:00.000','1899-12-30 00:00:00.000','1899-12-29 00:00:00.000','1899-12-31 00:00:00.000')