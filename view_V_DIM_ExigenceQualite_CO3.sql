USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ExigenceQualite_CO3 AS

WITH OrganisationInterneSensible AS (
    SELECT 
        OrganisationInterne.ID_OrganisationInterne
        ,OrganisationInterne.FK_EntiteGeographique
		,OrganisationInterne.CodeRegion
		-- Code Département de l'EG car le gestionnaire ROR est rattaché à l'établissement
		,EntiteGeographique.CodeDepartement
        ,OrganisationInterne.CodeNOS_TypeOI
        ,OrganisationInterne.NomOI
        ,OrganisationInterne.IdentifiantOI
        ,OrganisationInterne.UniteSensible
		,OrganisationInterne.UniqueID
        ,OrganisationInterne.UniqueID_OIParente
        ,CASE WHEN CodeNOS_ActiviteOperationnelle is not null THEN 'O' ELSE 'N' END AS FG_AO_MedecinePenitentiaire
    FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne as OrganisationInterne
    LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR as EntiteGeographique 
        ON OrganisationInterne.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS ActiviteOperationnelle
        ON ActiviteOperationnelle.FK_OrganisationInterne = OrganisationInterne.ID_OrganisationInterne 
		AND ActiviteOperationnelle.CodeNOS_ActiviteOperationnelle = '089'
    WHERE 
        /*Filtre des offres par nom contenant des mots-cles associes aux uhsi*/
        ((NomOI LIKE '%UHSI%' COLLATE French_CI_AI) 
        OR (NomOI LIKE '%UHSIR%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%Securisee Interregionale%' COLLATE French_CI_AI)   
        OR (NomOI LIKE '%Securite Inter-regionale%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%Securise%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%Detenus%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%USMP%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%penitentia%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%UHSA%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%Specialement Amenage%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%SMPR%' COLLATE French_CI_AI AND NomOI NOT LIKE '%readaptation%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%Service Medico-Psycologique%' COLLATE French_CI_AI)
        /*Filtre des offres par nom contenant des mots-cles associes aux ufdh et umdh*/
        OR (NomOI LIKE '%UFDH%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%UMDH%' COLLATE French_CI_AI)
        OR (NomOI LIKE '%NRBC%' COLLATE French_CI_AI) 
        OR (NomOI LIKE '%decontamination%' COLLATE French_CI_AI) 
        OR (NomOI LIKE '%contamines%' COLLATE French_CI_AI) 
        OR (NomOI LIKE '%decontamines%' COLLATE French_CI_AI) 
        OR (NomOI LIKE '%contamine%' COLLATE French_CI_AI)
        /*Ajout d'une condition OU pour les offres qui ne contiennent pas de mots-cles mais l'activite de medecine penitentaire*/
        OR CodeNOS_ActiviteOperationnelle is not null)
        /*Exclusion de l'offre de villet et des EPAHD qui contiennent des offres securisee Azheimer mais qui ne sont pas assimiles USHI*/
        AND CodeNOS_CategorieEG not in ('500','124','SA05','SA07','SA08','SA09')
        AND DateFermetureDefinitive is null
)

/*Identification des unites fontionnelles identifiees pour recuperation des offres*/
, OffreSensible AS (
    SELECT 
        Offre.CodeRegion
		,OrganisationInterneSensible.CodeDepartement
        ,Offre.ID_OrganisationInterne
        ,Offre.FK_EntiteGeographique
        ,Offre.NomOI AS NomOffre
        ,Offre.IdentifiantOI AS IdentifiantOffre
        ,Offre.UniteSensible
        ,CASE WHEN CodeNOS_ActiviteOperationnelle IS NOT NULL THEN 'O' ELSE 'N' END AS FG_AO_MedecinePenitentiaire
    FROM OrganisationInterneSensible 
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne as Offre
        ON OrganisationInterneSensible.UniqueID = Offre.UniqueID_OIParente
		AND OrganisationInterneSensible.CodeRegion = Offre.CodeRegion
    LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS ActiviteOperationnelle
        ON ActiviteOperationnelle.FK_OrganisationInterne = Offre.ID_OrganisationInterne AND CodeNOS_ActiviteOperationnelle = '089'
    WHERE OrganisationInterneSensible.CodeNOS_TypeOI = '3' AND Offre.DateFermetureDefinitive IS NULL
    /*Recuperation des offres directement identifiees comme USHI ou UFDH ou UMDH*/
    /*Exclusion des UE dont l'UF aurait ete identifie precedemment et donc deje recuperees dans la liste*/
    UNION
    SELECT
        CodeRegion
		,CodeDepartement
        ,ID_OrganisationInterne
        ,FK_EntiteGeographique
        ,NomOI
        ,IdentifiantOI
        ,UniteSensible
        ,FG_AO_MedecinePenitentiaire
    FROM OrganisationInterneSensible 
    WHERE CodeNOS_TypeOI = '4'
)

, PerimetreTotal AS (
    SELECT 
        CodeRegion
		,CodeDepartement
        ,ID_OrganisationInterne
        ,FK_EntiteGeographique
        ,NomOffre
        ,IdentifiantOffre
        ,UniteSensible
        ,FG_AO_MedecinePenitentiaire
        ,'O' AS TypeSensible
        ,CASE WHEN UniteSensible = '1' THEN 'O' ELSE 'N' END AS IdentificationSensibleROR
        ,CASE WHEN UniteSensible = '1' THEN 'Conforme' ELSE 'Ecart' END AS StatutExigence
    FROM OffreSensible
    UNION ALL
    SELECT 
        Offre.CodeRegion
		,EntiteGeographique.CodeDepartement
        ,Offre.ID_OrganisationInterne
        ,Offre.FK_EntiteGeographique
        ,Offre.NomOI
        ,Offre.IdentifiantOI
        ,Offre.UniteSensible
        ,'N'
        ,'N'
        ,'O'
        ,'Ecart'
    FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
    LEFT JOIN OffreSensible
        ON OffreSensible.IdentifiantOffre = Offre.IdentifiantOI
	LEFT JOIN DATALAB.DLAB_002.V_DIM_EntiteGeographiqueROR AS EntiteGeographique
		ON EntiteGeographique.ID_EntiteGeographique = Offre.FK_EntiteGeographique
    WHERE OffreSensible.IdentifiantOffre IS NULL
        AND Offre.UniteSensible = '1'
		AND Offre.CodeNOS_TypeOI = '4'
)

SELECT 
    ID_OrganisationInterne
	,FK_EntiteGeographique
	,CodeRegion
	,CodeDepartement
	,NomOffre
    ,IdentifiantOffre
	,UniteSensible
    ,FG_AO_MedecinePenitentiaire
    ,CASE WHEN NB_ActeSpecifiqueNRBC > 0 THEN 'O' ELSE 'N' END AS FG_AS_NRBC
	,TypeSensible
	,IdentificationSensibleROR
	,StatutExigence
FROM PerimetreTotal
LEFT JOIN (SELECT FK_OrganisationInterne, COUNT(CodeNOS) AS NB_ActeSpecifiqueNRBC
		FROM BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS
		WHERE TypeRelation = 'ActeSpecifique' AND CodeNOS in ('0006','0007','0008')
		GROUP BY FK_OrganisationInterne) AS ActeSpecifique
	ON ActeSpecifique.FK_OrganisationInterne = PerimetreTotal.ID_OrganisationInterne