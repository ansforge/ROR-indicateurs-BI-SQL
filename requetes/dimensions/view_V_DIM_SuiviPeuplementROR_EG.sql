USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_SuiviPeuplementROR_EG AS

/*
Description : Vue permettant de calculer le statut de peuplement au niveau Entité Géographique (établissement)
Sources : 
  - V_DIM_AutorisationFINESS (DATALAB)
  - V_REF_J55_CategorieEG (DATALAB)
  - V_DIM_SuiviPeuplementROR_UE (DATALAB)
  - T_DIM_EntiteGeographique (BIROR_DWH)
Vue utilisée par :
  - V_IND_SuiviPeuplementROR (DATALAB)
  - V_DIM_SynchroRORVT (DATALAB)
  - V_IND_QualiteROR (DATALAB)
  - Suivi_Peuplement_VFD (PowerBI)
*/

WITH perimetre_sanitaire AS (
SELECT CodeRegion
		,CodeDepartement
		,NumFINESS_EG
		,DateOuvertureFINESS
		,DenominationEG_FINESS
		,CodeCategorieEG_FINESS
		,TypePerimetreROR
		,DomaineROR
		,RIGHT(TypeAutorisation,3) AS TypeActivite
		,NB_ActiviteAutorisee
	FROM (
		SELECT 
			finess.CodeRegion
			,finess.CodeDepartement
			,finess.NumFINESS_EG
			,finess.DateOuvertureFINESS
			,finess.DenominationEG_FINESS
			,finess.CodeCategorieEG_FINESS
			,V_REF_J55_CategorieEG.TypePerimetreROR
			,V_REF_J55_CategorieEG.DomaineROR
			,finess.NB_AutorisationMCO
			,finess.NB_AutorisationPSY
			,finess.NB_AutorisationSMR
		FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS finess
		LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS V_REF_J55_CategorieEG
			ON finess.CodeCategorieEG_FINESS = V_REF_J55_CategorieEG.code
		-- Liste des catégories d'établissement sanitaire suivies dans le périmètre ROR
		WHERE finess.CodeCategorieEG_FINESS IN ('101','106','109','114','122','127','128','129',
		'131','141','146','156','161','166','292','355','362','365','366','412','415','425','430',
		'444','696','697','698','638')
	) AS sanitaire
	UNPIVOT
		(NB_ActiviteAutorisee FOR TypeAutorisation
			IN (NB_AutorisationMCO, NB_AutorisationPSY, NB_AutorisationSMR)
		) AS unpvt
	WHERE (NB_ActiviteAutorisee > 0) 
		-- L'autorisation de soin n'est pas obligatoire pour la description dans le ROR des établissements PSY ci-dessous
		OR (CodeCategorieEG_FINESS IN ('156','161', '166','292','366','412','415','425','430','444')
			AND TypeAutorisation = 'NB_AutorisationPSY'
			AND NB_ActiviteAutorisee = 0)
		-- L'autorisation de soin n'est pas obligatoire pour la description dans le ROR des établissements MCO ci-dessous
		OR (CodeCategorieEG_FINESS IN ('638')
			AND TypeAutorisation = 'NB_AutorisationMCO'
			AND NB_ActiviteAutorisee = 0)
)
	
SELECT
		perimetre_sanitaire.CodeRegion
		,CodeDepartement
		,perimetre_sanitaire.NumFINESS_EG
		,DateOuvertureFINESS
		,DenominationEG_FINESS
		,CodeCategorieEG_FINESS
		,TypePerimetreROR
		,DomaineROR
		,TypeActivite
		,eg.UniqueID AS IdentifiantTechniqueROR
		,eg.DenominationEG AS DenominationEG_ROR
		,CASE 
			WHEN COUNT(offres.ID_OrganisationInterne) > 0 AND COUNT(CASE WHEN FG_PeuplementFinalise = 1 THEN offres.ID_OrganisationInterne END) = COUNT(offres.ID_OrganisationInterne) THEN 'Finalise'
			WHEN COUNT(offres.ID_OrganisationInterne) > 0 AND COUNT(CASE WHEN FG_PeuplementEncours = 1 THEN offres.ID_OrganisationInterne END) > 0 THEN 'En cours'
			ELSE 'A faire'
		END AS StatutPeuplement
		,COUNT(offres.ID_OrganisationInterne) AS NB_offres
		,COUNT(CASE WHEN FG_PeuplementFinalise = 1 THEN offres.ID_OrganisationInterne END) AS NB_offresPeuplementFinalise
		,COUNT(CASE WHEN FG_PeuplementEncours = 1 THEN offres.ID_OrganisationInterne END) AS NB_offresPeuplementEnCours
	FROM perimetre_sanitaire
	LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS eg
		ON perimetre_sanitaire.NumFINESS_EG = eg.NumFINESS
	LEFT JOIN DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_UE AS offres
		ON eg.ID_EntiteGeographique = offres.FK_EntiteGeographique 
		AND perimetre_sanitaire.TypeActivite = offres.ChampActivite
	GROUP BY perimetre_sanitaire.CodeRegion
		,CodeDepartement
		,perimetre_sanitaire.NumFINESS_EG
		,DateOuvertureFINESS
		,DenominationEG_FINESS
		,CodeCategorieEG_FINESS
		,TypePerimetreROR
		,DomaineROR
		,TypeActivite
		,eg.UniqueID
		,eg.DenominationEG
	UNION ALL
	SELECT
		finess.CodeRegion
		,finess.CodeDepartement
		,finess.NumFINESS_EG AS NumFINESS_EG
		,finess.DateOuvertureFINESS
		,finess.DenominationEG_FINESS
		,finess.CodeCategorieEG_FINESS
		,V_REF_J55_CategorieEG.TypePerimetreROR
		,V_REF_J55_CategorieEG.DomaineROR
		,CASE 
			WHEN finess.CodeCategorieEG_FINESS IN ('202','207','381','500','501','502') THEN 'PA'
			WHEN finess.CodeCategorieEG_FINESS IN ('182','183','186','188','189','190','192','194'
			,'195','196','198','221','238','246','249','252','253','255','370','377','379'
			,'382','390','395','396','402','437','445','446','448','449') THEN 'PH'
			WHEN finess.CodeCategorieEG_FINESS IN ('209','354','460') THEN 'ESMS Domicile'
			WHEN finess.CodeCategorieEG_FINESS IN ('178','197','228','165','180','213','231','608') THEN 'Autres MS'
			WHEN finess.CodeCategorieEG_FINESS IN ('604','606') THEN 'Coordination'
			WHEN finess.CodeCategorieEG_FINESS IN ('603') THEN 'Ville' 
			ELSE 'Non défini'
		END AS TypeActivite
		,eg.UniqueID AS IdentifiantTechniqueROR
		,eg.DenominationEG AS DenominationEG_ROR
		,CASE 
			WHEN COUNT(offres.ID_OrganisationInterne) > 0 AND COUNT(CASE WHEN FG_PeuplementFinalise = 1 THEN offres.ID_OrganisationInterne END) = COUNT(offres.ID_OrganisationInterne) THEN 'Finalise'
			WHEN COUNT(offres.ID_OrganisationInterne) > 0 AND COUNT(CASE WHEN FG_PeuplementEncours = 1 THEN offres.ID_OrganisationInterne END) > 0 THEN 'En cours'
			ELSE 'A faire'
		END AS StatutPeuplement
		,COUNT(offres.ID_OrganisationInterne) AS NB_offres
		,COUNT(CASE WHEN FG_PeuplementFinalise = 1 THEN offres.ID_OrganisationInterne END) AS NB_offresPeuplementFinalise
		,COUNT(CASE WHEN FG_PeuplementEncours = 1 THEN offres.ID_OrganisationInterne END) AS NB_offresPeuplementEnCours
	FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS finess
	LEFT JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS V_REF_J55_CategorieEG
		ON finess.CodeCategorieEG_FINESS = V_REF_J55_CategorieEG.code
	LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS eg
		ON finess.NumFINESS_EG = eg.NumFINESS
	LEFT JOIN DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_UE AS offres
		ON eg.ID_EntiteGeographique = offres.FK_EntiteGeographique
	-- Liste des catégories d'établissement hors sanitaire suivies dans le périmètre ROR
	WHERE finess.CodeCategorieEG_FINESS IN ('165',	'178',	'180',	'182',	'183',	'186',	'188',	'189',	'190',
	'192',	'194',	'195',	'196',	'197',	'198',	'202',	'207',	'209',	'213',	'221',	'228',	'231',	'238',
	'246',	'249',	'252',	'253',	'255',	'354',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',
	'402',	'437',	'445',	'446',	'448',	'449',	'460',	'500',	'501',	'502',	'603',	'604',	'606',	'608',
	'617',	'618')
	GROUP BY finess.CodeRegion
		,finess.CodeDepartement
		,finess.NumFINESS_EG
		,finess.DateOuvertureFINESS
		,finess.DenominationEG_FINESS
		,finess.CodeCategorieEG_FINESS
		,V_REF_J55_CategorieEG.TypePerimetreROR
		,V_REF_J55_CategorieEG.DomaineROR
		,eg.UniqueID
		,eg.DenominationEG