USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_SuiviPeuplementROR_UE AS

/*
Contexte : Vue permettant de vérifier les critéres de peuplement ANS au niveau unité
Version de la vue : 1.3
Notes de la dernière évolution : Suppression du critères de peuplement Catégorie Organisation pour les unités PSY
Sources :
  - T_DIM_ActiviteOperationnelle (BIROR_DWH)
  - T_DIM_Contact (BIROR_DWH)
  - T_DIM_Telecommunication (BIROR_DWH)
  - T_DIM_OrganisationInterne (BIROR_DWH)
  - T_DIM_EntiteGeographique (BIROR_DWH)
  - T_LIE_OrganisationInterne_NOS (BIROR_DWH)
  - T_DIM_Lieu (BIROR_DWH)
  - T_REF_NOS (BIROR_DWH)
Vue utilisée par :
  - V_DIM_SuiviPeuplementROR_EG (DATALAB)
  - Suivi_Pleuplement_VFD (PowerBI)
*/

WITH 
/*Comptabilisation du nombre d'activités opérationnelles décrites dans chaque unité*/
count_ao AS (
SELECT
	FK_OrganisationInterne
	/*Si le code de l'activité opérationnelle ne correspond à aucune valeur dans le NOS alors la FK sera = -1 (non rapproché), ou -2 (non renseigné), ou -3 (non pertinent)
	  Cela permet de vérifier que les valeurs envoyées font bien partie de la nomenclature nationale*/
	,COUNT(DISTINCT CASE WHEN FK_NOS_ActiviteOperationnelle not in ('-1','-3','-2') THEN CodeNOS_ActiviteOperationnelle END) AS NB_ActiviteOperationnelleNOS
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_ActiviteOperationnelle
GROUP BY FK_OrganisationInterne
)
/*Comptabilisation du nombre de contacts rattachés à chaque unité*/
,count_contact AS (
SELECT
	ct.FK_StructureParente
	/*idem, exclusion des FK pour s'assurer que le code NOS envoyé correspond bien à une valeur dans la nomenclature associée */
	,COUNT(DISTINCT CASE WHEN ((ct.CodeNOS_FonctionContact IS NOT NULL AND ct.FK_NOS_FonctionContact not in ('-1','-3')) 
	OR (ct.OIDNOS_NatureContact IS NOT NULL AND ct.FK_NOS_NatureContact not in ('-1','-3'))) 
	AND tl.CodeNOS_Canal IS NOT NULL 
	AND tl.AdresseTelecom IS NOT NULL 
	AND tl.CodeNOS_NiveauConfidentialite IS NOT NULL THEN FK_ContactParent END) as NB_ContactPeuple
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Contact as ct
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Telecommunication as tl ON ct.ID_Contact = tl.FK_ContactParent
WHERE ct.TypeParent = 'OI'
GROUP BY ct.FK_StructureParente
)

,all_joins as 
(SELECT
	oi.CodeRegion
	,oi.FK_EntiteGeographique
	,eg.UniqueID AS IdentifiantTechniqueROR_EG
	,eg.DenominationEG
	,eg.NumFINESS as NumFINESS_EG
	,oi.ID_OrganisationInterne
	,oi.IdentifiantOI
	,oi.CodeNOS_TypeOI as CodeNOS_TypeOI
	,type_oi.Libelle as LibelleNOS_TypeOI
	,oi.NomOI
    ,nos_champ_act.LibelleCourt as ChampActivite
	,oi.CodeNOS_ModePriseEnCharge as CodeNOS_ModePriseEnCharge
	,mode_pec.Libelle as LibelleNOS_ModePriseEnCharge
	,oi.CodeNOS_CategorieOrganisation as CodeNOS_CategorieOrganisation
	,cat_orga.libelle as LibelleNOS_CategorieOrganisation
	,oi.AgeMinPatientele
	,oi.AgeMaxPatientele
	,lieuOI.LibelleVoie
	,lieuOI.LieuDit
	,lieuOI.Localite
	,lieuOI.CodePostal
	/*Si aucune AO ou aucun contact n'a été peuplé alors l'unité ne figurera pas dans les CTE respectifs, ISNULL() permet de gérer ce cas */
	,ISNULL(count_ao.NB_ActiviteOperationnelleNOS,0) as NB_ActiviteOperationnelleNOS
	,ISNULL(count_contact.NB_ContactPeuple,0) as NB_ContactPeuple
	/*Traitement des "flags" comme suit : si les critéres attendus sont respectés alors le Flag = 1 sinon Flag = 0*/
	,CASE 
		WHEN oi_champ_act.CodeNOS IS NOT NULL AND nos_champ_act.ID_NOS IS NOT NULL THEN 1
		ELSE 0
	END as FG_ChampActivite
	,CASE 
		WHEN oi.CodeNOS_ModePriseEnCharge IS NOT NULL AND mode_pec.ID_NOS IS NOT NULL THEN 1
		ELSE 0
	END as FG_ModePEC
	,CASE 
		WHEN oi.AgeMinPatientele IS NOT NULL AND oi.AgeMaxPatientele IS NOT NULL THEN 1
		ELSE 0
	END as FG_Patientele
	,CASE 
		WHEN ISNULL(count_ao.NB_ActiviteOperationnelleNOS,0) > 0 THEN 1
		ELSE 0
	END as FG_AO
	,CASE 
		/*Seules les unités PSY et PAPH (catégorie EG 209,354,460) sont concernées ici, la valeur NULL est ajoutée au Flag pour les unités non concernées*/
		WHEN (eg.CodeNOS_CategorieEG not in ('209','354','460') OR eg.CodeNOS_CategorieEG is null) THEN NULL
		WHEN oi.CodeNOS_CategorieOrganisation IS NOT NULL AND oi.FK_NOS_CategorieOrganisation not in ('-1','-3') THEN 1
		ELSE 0
	END as FG_CategorieOrga
	,CASE 
		WHEN (lieuOI.LibelleVoie IS NOT NULL OR lieuOI.LieuDit IS NOT NULL) AND lieuOI.Localite IS NOT NULL AND lieuOI.CodePostal IS NOT NULL THEN 1
		ELSE 0
	END as FG_Adresse
	,CASE 
		WHEN ISNULL(count_contact.NB_ContactPeuple,0) > 0 THEN 1
		ELSE 0
	END as FG_Contact
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne as oi
INNER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique as eg 
	ON oi.FK_EntiteGeographique = eg.ID_EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_LIE_OrganisationInterne_NOS as oi_champ_act 
	ON oi.ID_OrganisationInterne = oi_champ_act.FK_OrganisationInterne AND oi_champ_act.TypeRelation = 'ChampActivite'
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Lieu as lieuOI 
	ON oi.ID_OrganisationInterne = lieuOI.FK_StructureParente AND TypeAppartenance = 'OI'
-- Tables CTE
LEFT JOIN count_ao ON oi.ID_OrganisationInterne = count_ao.FK_OrganisationInterne
LEFT JOIN count_contact ON oi.ID_OrganisationInterne = count_contact.FK_StructureParente
-- Tables NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as nos_champ_act ON oi_champ_act.FK_NOS = nos_champ_act.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as mode_pec ON oi.FK_NOS_ModePriseEnCharge = mode_pec.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as type_oi ON oi.FK_NOS_TypeOI = type_oi.ID_NOS
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as cat_orga ON oi.FK_NOS_CategorieOrganisation = cat_orga.ID_NOS
WHERE oi.CodeRegion not in ('-1','-2','-3') AND oi.CodeNOS_TypeOI = '4' AND oi.DateFermetureDefinitive is null
)

SELECT
	CodeRegion
	,FK_EntiteGeographique
	,IdentifiantTechniqueROR_EG
	,DenominationEG
	,NumFINESS_EG
	,NomOI
	,ID_OrganisationInterne
	,IdentifiantOI
	,LibelleNOS_TypeOI
	,ChampActivite
	,LibelleNOS_ModePriseEnCharge
	,LibelleNOS_CategorieOrganisation
	,AgeMinPatientele
	,AgeMaxPatientele
	,LibelleVoie
	,LieuDit
	,CodePostal
	,Localite
	,NB_ActiviteOperationnelleNOS
	,NB_ContactPeuple
	,FG_ChampActivite
	,FG_CategorieOrga
	,FG_AO
	,FG_ModePEC
	,FG_Patientele
	,FG_Adresse
	,FG_Contact
	,CASE
		WHEN FG_ChampActivite = 1
		--Gestion du cas des unités PSY et PAPH dont la catégorie d'organisation est obligatoire
		AND (FG_CategorieOrga = 1 OR FG_CategorieOrga IS NULL)
		AND FG_AO = 1
		AND FG_ModePEC = 1
		AND FG_Patientele = 1
		AND FG_Adresse = 1
		AND FG_Contact = 1 THEN 'Finalise'
		WHEN (FG_ChampActivite = 1
		OR FG_CategorieOrga = 1
		OR FG_AO = 1
		OR FG_ModePEC = 1
		OR FG_Patientele = 1
		OR FG_Adresse = 1
		OR FG_Contact = 1) THEN 'En cours'
		ELSE 'A faire'
	END AS StatutPeuplement
	,CASE
		WHEN FG_ChampActivite = 1
		--Gestion du cas des unités PSY et PAPH dont la catégorie d'organisation est obligatoire
		AND (FG_CategorieOrga = 1 OR FG_CategorieOrga IS NULL)
		AND FG_AO = 1
		AND FG_ModePEC = 1
		AND FG_Patientele = 1
		AND FG_Adresse = 1
		AND FG_Contact = 1 THEN 1
		ELSE 0
	END AS FG_PeuplementFinalise
	/*Le Flag peuplement en cours = 1 seulement si au moins un des flags est = 1 et que l'ensemble des flags ne sont pas = 1*/
	,CASE
		WHEN (FG_ChampActivite = 1
		OR FG_CategorieOrga = 1
		OR FG_AO = 1
		OR FG_ModePEC = 1
		OR FG_Patientele = 1
		OR FG_Adresse = 1
		OR FG_Contact = 1) AND NOT
		(FG_ChampActivite = 1
		AND (FG_CategorieOrga = 1 OR FG_CategorieOrga IS NULL)
		AND FG_AO = 1
		AND FG_ModePEC = 1
		AND FG_Patientele = 1
		AND FG_Adresse = 1
		AND FG_Contact = 1) THEN 1
		ELSE 0
	END AS FG_PeuplementEncours
FROM all_joins