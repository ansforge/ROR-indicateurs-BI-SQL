USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_ExigenceQualite_CO1
AS

WITH OffresUrgences AS (
SELECT
	Offre.ID_OrganisationInterne
	,Offre.CodeRegion
	,Offre.IdentifiantOI AS IdentifiantOffre
	,Offre.FK_EntiteGeographique
	,Offre.NomOI AS NomOffre
	,SUM(CASE WHEN CodeNOS_ActiviteOperationnelle = '157' THEN 1 ELSE 0 END) AS NB_AO_Urgences
	,SUM(CASE WHEN CodeNOS_ActiviteOperationnelle = '249' THEN 1 ELSE 0 END) AS NB_AO_UrgencesPediatriques
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS ActiviteOperationnelle
	ON Offre.ID_OrganisationInterne = ActiviteOperationnelle.FK_OrganisationInterne
WHERE Offre.CodeNOS_TypeOI = '4' 
	AND Offre.DateFermetureDefinitive IS NULL 
	AND CodeNOS_ActiviteOperationnelle in ('157','249') 
	AND Offre.CodeNOS_ModePriseEnCharge = '33'
GROUP BY Offre.ID_OrganisationInterne, Offre.CodeRegion, Offre.IdentifiantOI, Offre.NomOI ,Offre.FK_EntiteGeographique
)

SELECT 
	OffresUrgences.ID_OrganisationInterne
	,OffresUrgences.CodeRegion
	,OffresUrgences.IdentifiantOffre
	,OffresUrgences.FK_EntiteGeographique
	,OffresUrgences.NomOffre
	,OffresUrgences.NB_AO_Urgences
	,OffresUrgences.NB_AO_UrgencesPediatriques
	,ISNULL(Autorisation.NB_AutorisationUrgences,0) AS NB_AutorisationUrgences
	,ISNULL(Autorisation.NB_AutorisationUrgencesPediatriques,0) AS NB_AutorisationUrgencesPediatriques
	,Autorisation.DateMajFiness
	,CASE 
		WHEN (OffresUrgences.NomOffre LIKE '%urgence%' COLLATE French_CI_AI) 
		OR (OffresUrgences.NomOffre LIKE '%urgences%' COLLATE French_CI_AI) THEN 'O' 
		ELSE 'N' 
	END FG_ConformiteNomOffre
	,CASE 
		WHEN OffresUrgences.NB_AO_Urgences > 0 AND ISNULL(Autorisation.NB_AutorisationUrgences,0) > 0 
			AND OffresUrgences.NB_AO_UrgencesPediatriques > 0 AND ISNULL(Autorisation.NB_AutorisationUrgencesPediatriques,0) > 0 THEN 'O'
		WHEN OffresUrgences.NB_AO_Urgences > 0 AND ISNULL(Autorisation.NB_AutorisationUrgences,0) > 0
			AND OffresUrgences.NB_AO_UrgencesPediatriques = 0 THEN 'O'
		WHEN OffresUrgences.NB_AO_UrgencesPediatriques > 0 AND ISNULL(Autorisation.NB_AutorisationUrgencesPediatriques,0) > 0 
			AND OffresUrgences.NB_AO_Urgences = 0 THEN 'O'
		ELSE 'N' 
	END AS FG_ConformiteAutorisationSoin
	,CASE 
		WHEN ((OffresUrgences.NomOffre LIKE '%urgence%' COLLATE French_CI_AI) 
			OR (OffresUrgences.NomOffre LIKE '%urgences%' COLLATE French_CI_AI))
			AND ((OffresUrgences.NB_AO_Urgences > 0 AND ISNULL(Autorisation.NB_AutorisationUrgences,0) > 0 
				AND OffresUrgences.NB_AO_UrgencesPediatriques > 0 AND ISNULL(Autorisation.NB_AutorisationUrgencesPediatriques,0) > 0 )
			OR (OffresUrgences.NB_AO_Urgences > 0 AND ISNULL(Autorisation.NB_AutorisationUrgences,0) > 0
				AND OffresUrgences.NB_AO_UrgencesPediatriques = 0)
			OR (OffresUrgences.NB_AO_UrgencesPediatriques > 0 AND ISNULL(Autorisation.NB_AutorisationUrgencesPediatriques,0) > 0 
				AND OffresUrgences.NB_AO_Urgences = 0))
			THEN 'Conforme' 
		ELSE 'Ecart'
	END AS StatutExigence
FROM OffresUrgences
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
	ON OffresUrgences.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
-- Recuperation des autorisations FINESS au niveau etablissement
LEFT JOIN DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Autorisation
	ON EntiteGeographique.NumFiness = Autorisation.NumFINESS_EG
WHERE TypePerimetreROR <> 'Non suivi'


