USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_ExigenceQualite_CP5_CP6 AS

SELECT
    Offre.ID_OrganisationInterne
    ,Offre.FK_EntiteGeographique
    ,Offre.CodeRegion
    ,Offre.NomOI AS NomOffre
    ,Offre.IdentifiantOI AS IdentifiantOffre
	,EntiteGeographique.CodeNOS_CategorieEG
    ,Offre.CodeNOS_ModePriseEnCharge
	,ModePriseEnCharge.Libelle AS LibelleNOS_ModePriseEnCharge
    ,Offre.CodeNOS_CategorieOrganisation
	,CategorieOrganisation.Libelle AS LibelleNOS_CategorieOrganisation
    ,TemporaliteAccueil.Libelle AS TemporaliteAccueil
    ,Offre.NbPlacesInstallees
    -- Regle exigence CP5
    ,CASE
        WHEN EntiteGeographique.CodeNOS_CategorieEG NOT IN ('183','186','194','195','255','390','395','437','202','207','500','501','502') 
            OR (EntiteGeographique.CodeNOS_CategorieEG IN ('202','207','500','501','502') AND Offre.CodeNOS_ModePriseEnCharge <> '46') 
            THEN NULL
        WHEN Offre.CodeNOS_CategorieOrganisation IS NOT NULL AND Offre.CodeNOS_TemporaliteAccueil IS NOT NULL
            THEN 'Conforme' 
        ELSE 'Ecart'
    END AS StatutExigenceCP5
    -- Regle exigence CP6
    ,CASE
        WHEN Offre.CodeNOS_CategorieOrganisation = '25' THEN NULL
		WHEN Offre.NbPlacesInstallees > 0 THEN 'Conforme'
        ELSE 'Ecart'
    END AS StatutExigenceCP6
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
    ON Offre.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS ModePriseEnCharge
    ON Offre.FK_NOS_ModePriseEnCharge = ModePriseEnCharge.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS CategorieOrganisation
    ON Offre.FK_NOS_CategorieOrganisation = CategorieOrganisation.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS TemporaliteAccueil
    ON Offre.FK_NOS_TemporaliteAccueil = TemporaliteAccueil.ID_NOS
WHERE Offre.CodeNOS_TypeOI = '4' 
    AND Offre.DateFermetureDefinitive IS NULL
    AND Offre.CodeNOS_ModePriseEnCharge in ('46','47','48') 
    AND EntiteGeographique.CodeNOS_CategorieEG IN ('178','182','183','186','188','189','190','192'
		,'194','195','196','197','198','202','207','209','221','228','238','246','249','252','253'
		,'255','354','370','377','379','381','382','390','395','396','402','437','445','446','448'
		,'449','460','500','501','502')
	AND (Offre.CodeNOS_CategorieOrganisation != '38' OR Offre.CodeNOS_CategorieOrganisation IS NULL)