USE DATALAB
GO 

CREATE OR ALTER VIEW DLAB_002.V_DIM_VolumetrieNOS AS

WITH union_query AS (
SELECT 
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Acte Specifique' AS TypeNOS
	, asp.CodeNOS
	, asp_nos.Libelle AS LibelleNOS
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS AS asp
	ON oi.ID_OrganisationInterne = asp.FK_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS asp_nos
	ON asp_nos.ID_NOS = asp.FK_NOS
WHERE asp.TypeRelation = 'ActeSpecifique' 
	AND oi.CodeRegion not in ('-1','-2','-3')
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Activite Operationnelle'
	, CodeNOS_ActiviteOperationnelle
	, ao_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle AS ao
	ON ao.FK_OrganisationInterne =  oi.ID_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS ao_nos
	ON ao_nos.ID_NOS = ao.FK_NOS_ActiviteOperationnelle
WHERE oi.CodeRegion not in ('-1','-2','-3')
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Equipement'
	, e.CodeNOS_TypeEquipement
	, es_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Equipement AS e
	ON e.FK_OrganisationInterne = oi.ID_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS es_nos
	ON e.FK_NOS_TypeEquipement = es_nos.ID_NOS
WHERE oi.CodeRegion not in ('-1','-2','-3') 
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Categorie Organisation'
	, oi.CodeNOS_CategorieOrganisation
	, co_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS co_nos
	ON oi.FK_NOS_CategorieOrganisation = co_nos.ID_NOS
WHERE oi.CodeRegion not in ('-1','-2','-3') 
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Mode PeC'
	, oi.CodeNOS_ModePriseEnCharge
	, mpc_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS mpc_nos
	ON oi.FK_NOS_ModePriseEnCharge = mpc_nos.ID_NOS
WHERE oi.CodeRegion not in ('-1','-2','-3')
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Public PeC'
	, ppc.CodeNOS
	, ppc_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS AS ppc
	ON oi.ID_OrganisationInterne = ppc.FK_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS ppc_nos
	ON ppc_nos.ID_NOS = ppc.FK_NOS
WHERE ppc.TypeRelation = 'PublicPrisEnCharge' 
	AND oi.CodeRegion not in ('-1','-2','-3')
	AND oi.DateFermetureDefinitive IS NULL
UNION ALL
SELECT
	ID_OrganisationInterne
	, oi.CodeRegion
	, oi.NomOI
	, oi.IdentifiantOI
	, oi.FK_EntiteGeographique
	, 'Specialisation PeC'
	, spc.CodeNOS
	, spc_nos.Libelle
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS AS spc
	ON oi.ID_OrganisationInterne = spc.FK_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS spc_nos
	ON spc_nos.ID_NOS = spc.FK_NOS
WHERE spc.TypeRelation = 'SpecialisationPriseEnCharge' 
	AND oi.CodeRegion not in ('-1','-2','-3') 
	AND oi.DateFermetureDefinitive IS NULL
)
, nombre_ao AS (
	SELECT
		FK_OrganisationInterne
		, COUNT(ID_ActiviteOperationnelle) AS NB_ActiviteOp
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle
	GROUP BY FK_OrganisationInterne
)

SELECT
	union_query.CodeRegion
	,region.Libelle AS LibelleRegion
	, eg.ID_EntiteGeographique
	, ISNULL(eg.DenominationEG, eg.NomOperationnel) AS DenominationEG
	, eg.IdNat_Struct
	, eg. CodeNOS_CategorieEG
	, categorieEG.Libelle AS LibelleNOS_CategorieEG
	, ID_OrganisationInterne
	, NomOI
	, union_query.IdentifiantOI
	, ca_nos.LibelleCourt AS ChampActivite
	, TypeNOS
	, union_query.CodeNOS
	, LibelleNOS
	, NB_ActiviteOp
FROM union_query
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS eg	
	ON union_query.FK_EntiteGeographique = eg.ID_EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS categorieEG
	ON eg.FK_NOS_CategorieEG = categorieEG.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS AS ca
	ON union_query.ID_OrganisationInterne = ca.FK_OrganisationInterne
	AND ca.TypeRelation = 'ChampActivite'
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS ca_nos
	ON ca_nos.ID_NOS = ca.FK_NOS
LEFT JOIN nombre_ao
	ON nombre_ao.FK_OrganisationInterne = union_query.ID_OrganisationInterne
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS AS region
	ON region.Code = eg.CodeRegion AND region.Nomenclature_OID = '1.2.250.1.213.2.25'