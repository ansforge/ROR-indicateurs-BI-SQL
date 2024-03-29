USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_EntiteGeographiqueROR AS

SELECT
    EntiteGeographique.ID_EntiteGeographique
    ,EntiteGeographique.IdNat_Struct
    ,EntiteGeographique.UniqueID AS IdentifiantTechniqueROR
	,EntiteGeographique.NumFINESS
    ,EntiteGeographique.FK_EntiteJuridique
    ,EntiteGeographique.DenominationEG
    ,EntiteGeographique.CodeNOS_CategorieEG
    ,EntiteGeographique.FK_NOS_CategorieEG
	,EntiteGeographique.CodeRegion
    ,CASE 
		WHEN EntiteGeographique.CodeRegion IN ('01','02','03','04','06') THEN LEFT(Lieu.CodeNOS_CommuneCog,3)
		ELSE LEFT(Lieu.CodeNOS_CommuneCog,2) 
	END AS CodeDepartement
	,ContactTelephone.AdresseTelecom AS TelephoneResponsableEG
	,ContactEmail.AdresseTelecom AS EmailResponsableEG
	,EntiteGeographique.DateFermeture
	,EntiteGeographique.CodeNOS_TypeFermeture
	,EntiteGeographique.Meta_DateMiseJour AS DateMajROR
    ,CASE 
		WHEN COUNT(ID_OrganisationInterne) = 0 THEN '0 offre'
		WHEN COUNT(ID_OrganisationInterne) >= 8 THEN '8 offres ou plus' 
		ELSE '1-7 offres' 
	END AS TypeVolumetrieOffre
    ,COUNT(ID_OrganisationInterne) AS NB_Offre
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS OrganisationInterne
    ON OrganisationInterne.FK_EntiteGeographique = EntiteGeographique.ID_EntiteGeographique
	AND OrganisationInterne.CodeNOS_TypeOI = '4'
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Lieu AS Lieu
    ON EntiteGeographique.ID_EntiteGeographique = Lieu.FK_StructureParente
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Telecommunication AS ContactEmail
	ON EntiteGeographique.ID_EntiteGeographique = ContactEmail.FK_StructureParente
	AND ContactEmail.TypeParent = 'EG' 
	AND (ContactEmail.CodeNOS_FonctionContact = '01' OR ContactEmail.CodeNOS_NatureContact = '10')
	ANd ContactEmail.CodeNOS_Canal = '3'
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Telecommunication AS ContactTelephone
	ON EntiteGeographique.ID_EntiteGeographique = ContactTelephone.FK_StructureParente
	AND ContactTelephone.TypeParent = 'EG' 
	AND (ContactTelephone.CodeNOS_FonctionContact = '01' OR ContactTelephone.CodeNOS_NatureContact = '10')
	ANd ContactTelephone.CodeNOS_Canal = '2'
GROUP BY EntiteGeographique.ID_EntiteGeographique
    ,EntiteGeographique.IdNat_Struct
    ,EntiteGeographique.UniqueID
	,EntiteGeographique.NumFINESS
    ,EntiteGeographique.FK_EntiteJuridique
    ,EntiteGeographique.DenominationEG
    ,EntiteGeographique.CodeNOS_CategorieEG
    ,EntiteGeographique.FK_NOS_CategorieEG
	,EntiteGeographique.CodeRegion
    ,CASE 
		WHEN EntiteGeographique.CodeRegion IN ('01','02','03','04','06') THEN LEFT(Lieu.CodeNOS_CommuneCog,3)
		ELSE LEFT(Lieu.CodeNOS_CommuneCog,2) 
	END
	,ContactTelephone.AdresseTelecom
	,ContactEmail.AdresseTelecom
	,EntiteGeographique.DateFermeture
	,EntiteGeographique.CodeNOS_TypeFermeture
	,EntiteGeographique.Meta_DateMiseJour
	,EntiteGeographique.DT_UPDATE_TECH