USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ExigenceQualite_EX3_EX4_EX5 AS

WITH Offres AS (
	SELECT FK_EntiteGeographique
		, COUNT(DISTINCT CASE WHEN CodeNOS_ActiviteOperationnelle 
							IN ('121','122','123','124','125','126','127','129')
							THEN ID_OrganisationInterne END) AS NB_OffreReanimation
		, COUNT(DISTINCT CASE WHEN CodeNOS_ActiviteOperationnelle = '130'
							THEN ID_OrganisationInterne END) AS NB_OffreReanimationPediatrique
		, COUNT(DISTINCT CASE WHEN CodeNOS_ActiviteOperationnelle = '128'
						THEN ID_OrganisationInterne END) AS NB_OffreReanimationNeonat
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
	INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS ActiviteOperationnelle
		ON Offre.ID_OrganisationInterne = ActiviteOperationnelle.FK_OrganisationInterne 
	WHERE CodeNOS_ActiviteOperationnelle IN ('121','122','123','124','125','126','127','128','129','130')
	GROUP BY FK_EntiteGeographique
)

SELECT
	Autorisation.ID_StructureFINESS
    , Autorisation.CodeRegion
    , Autorisation.CodeDepartement
    , Autorisation.NumFINESS_EG
    , Autorisation.DenominationEG_FINESS
    , Autorisation.CodeCategorieEG_FINESS
	, Autorisation.DateMajFiness
    , EntiteGeographique.ID_EntiteGeographique AS FK_EntiteGeographique
	, Autorisation.DomaineROR
    , Autorisation.NB_AutorisationReanimation
    , Autorisation.NB_AutorisationReanimationPediatrique
    , Autorisation.NB_AutorisationReanimationNeonat
    , ISNULL(Offres.NB_OffreReanimation,0) AS NB_OffreReanimation
    , ISNULL(Offres.NB_OffreReanimationPediatrique,0) AS NB_OffreReanimationPediatrique
    , ISNULL(Offres.NB_OffreReanimationNeonat,0) AS NB_OffreReanimationNeonat
    , CASE 
        WHEN Autorisation.NB_AutorisationReanimation = 0 THEN NULL 
        WHEN ISNULL(Offres.NB_OffreReanimation,0) > 0 THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigenceEX3 
    , CASE 
        WHEN Autorisation.NB_AutorisationReanimationPediatrique = 0 THEN NULL 
        WHEN ISNULL(Offres.NB_OffreReanimationPediatrique,0) > 0 THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigenceEX4
    , CASE 
        WHEN Autorisation.NB_AutorisationReanimationNeonat = 0 THEN NULL 
        WHEN ISNULL(Offres.NB_OffreReanimationNeonat,0) > 0 THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigenceEX5
FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Autorisation
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique 
    ON Autorisation.NumFINESS_EG = EntiteGeographique.NumFINESS 
	AND EntiteGeographique.NumFINESS IS NOT NULL
LEFT JOIN Offres
    ON Offres.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
WHERE TypePerimetreROR <> 'Non suivi' 
	AND (NB_AutorisationReanimation > 0 OR NB_AutorisationReanimationPediatrique > 0 OR NB_AutorisationReanimationNeonat > 0)