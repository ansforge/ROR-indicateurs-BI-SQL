USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_CiblePeuplementROR_EG AS

/*
Contexte : Vue permettant de récupérer les données du Finess et de les retravailler selon les besoins du suivi de peuplement
Version de la vue : 2.0
Sources : 
  - dwh_activitesoin (BICOEUR)
  - dwh_structure (BICOEUR)
  - ref_commune (BICOEUR)
  - ref_departement (BICOEUR)
  - ref_region (BICOEUR)
Vue utilisée par :
  - V_DIM_QualiteROR_FINESS_EG
  - V_DIM_SuiviPeuplementROR_EG
Evolutions à venir : Ajout de l'état de FINESS et récupération de l'ensemble des structures même celles dans un état autre que Ouvert
*/

-- Gestion des etablissements avec autorisations
WITH query as (
SELECT DISTINCT
	r.cdregion_regi AS CodeRegion
	,r.lbadapteregion_regi AS LibelleRegion
	,etb.nmfinessetab_stru AS NumFINESS_EG
	,etb.dtouvertstruct_stru AS DT_OuvertureEG_FINESS
	,etb.dtautorisation_stru AS DT_AutorisationEG_FINESS
	,etb.raisonsociale_stru AS DenominationEG_FINESS
	,etb.categetab_stru AS CodeCategorieEG
	,etb.libcategetab_stru AS LibelleCategorieEG
	,etb.nmfinessej_stru AS NumFINESS_EJ
	,d.cddept_dept AS CodeDepartement
	,d.lbcourtdept_dept AS LibelleDepartement
	,CASE
		-- Les établissements avec une autorisation de forme HAD sont catégorisés dans le champ d'activité MCO
		WHEN act.cdforme_acts = '05' AND act.cdactivite_acts != '04' THEN 'MCO'
		WHEN act.cdactivite_acts in ('50','53','59','51','57','55','52','58','56','54') THEN 'SMR'
		WHEN act.cdactivite_acts in ('01','02','03','07','09','10','11','12','13','14','15','16','17','18','19','80'
		,'81','82','83','84','85','86','87','88') THEN 'MCO'
		WHEN act.cdactivite_acts = '04' THEN 'PSY'
	END AS ChampActivite
	,'Sanitaire' AS SecteurEG
	,CASE 
		WHEN act.cdactivite_acts = '15' AND act.cdmodalite_acts = '09' THEN 1
		ELSE 0
	END AS FG_AutorisationRea
	,CASE 
		WHEN act.cdactivite_acts = '15' AND act.cdmodalite_acts in ('10','98') THEN 1
		ELSE 0
	END AS FG_AutorisationReaPed
	,etb.dtmaj_stru AS DT_MAJ_Finess
FROM BICOEUR_DWH_SNAPSHOT.dbo.dwh_activitesoin AS act
INNER JOIN BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS etb 
	ON etb.nmfinessetab_stru = act.nmfinesset_acts
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_commune as c
	ON etb.idcommune_stru = c.idcommune_comm
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_departement as d
	ON c.iddepartement_comm = d.iddept_dept
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_region as r
	ON d.idregion_dept = r.idregion_regi
WHERE etb.topsource_stru = 'FINESS' 
	AND etb.typeidpm_stru = 'EG'
	AND act.topsource_acts = 'FINESS'
	AND CAST(act.dtfin_acts AS DATE) >= '2021-05-01'
	AND act.cdactivite_acts in ('01','02','03','04','07','09','10','11','12','13','14','15','16','17','18'
	,'19','51','50','52','53','54','55','56','57','58','59','80','81','82','83','84','85','86','87','88')
	AND etb.categetab_stru in ('101','106','109','114','122','127','128','129','131','141','146','156'
	,'161','292','355','362','365','366','412','415','425','430','444','696','697','698') 
	AND etb.dtouvertstruct_stru IS NOT NULL
	AND etb.dtfermestruct_stru IS NULL
	AND (etb.cdconstatcaducite_stru IS NULL OR etb.cdconstatcaducite_stru = 'N')
	AND d.cddept_dept != '975'
UNION
-- Gestion des établissements sans autorisations (traitement des etablissements dans la categorie PSY sans autorisation PSY)
SELECT DISTINCT
	r.cdregion_regi
	,r.lbadapteregion_regi
	,etb.nmfinessetab_stru
	,etb.dtouvertstruct_stru
	,etb.dtautorisation_stru
	,etb.raisonsociale_stru
	,etb.categetab_stru
	,etb.libcategetab_stru
	,etb.nmfinessej_stru
	,d.cddept_dept
	,d.lbcourtdept_dept
	,CASE 
		WHEN etb.categetab_stru in ('156','161','292','366','412','415','425','430','444') THEN 'PSY'
		WHEN etb.categetab_stru in ('209','354','460') THEN 'Services PAPH'
		WHEN etb.categetab_stru in ('202','207','381','500','501','502') THEN 'PA'
		WHEN etb.categetab_stru in ('182','183','186','188','189','190','192','194','195','196','198','221'
		,'238','246','249','252','253','255','370','377','379','382','390','395','396','402','437','445'
		,'446','448','449') THEN 'PH'
		WHEN etb.categetab_stru in ('178','197','228') THEN 'Autres MS'
		WHEN etb.categetab_stru in ('604','606') THEN 'Coordination'
		WHEN etb.categetab_stru in ('603','617','618') THEN 'Ville'
	ELSE 'Autre' END
	,CASE 
		WHEN etb.categetab_stru in ('178','182','183','186','188','189','190','192','194','195','196','197'
		,'198','202','207','209','221','228','238','246','249','252','253','255','354','370','377'
		,'379','381','382','390','395','396','402','437','445','446','448','449','460','500','501','502') THEN 'Medico-social'
		WHEN etb.categetab_stru in ('156','161','292','366','412','415','425','430','444') 
			THEN 'Sanitaire'
		WHEN etb.categetab_stru in ('604','606') THEN 'Coordination'
		WHEN etb.categetab_stru in ('603','617','618') THEN 'Offre de ville'
		ELSE 'Autre'
	END
	,0
	,0
	,etb.dtmaj_stru
FROM BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS etb
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_commune as c
	ON etb.idcommune_stru = c.idcommune_comm
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_departement as d
	ON c.iddepartement_comm = d.iddept_dept
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_region as r
	ON d.idregion_dept = r.idregion_regi
WHERE etb.topsource_stru = 'FINESS' 
	AND etb.typeidpm_stru = 'EG'
	AND etb.categetab_stru in ('156',	'161',	'178',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',	'195',	'196',	'197',	'198',	'202',	'207',	'209',	'221',
'228',	'238',	'246',	'249',	'252',	'253',	'255',	'292',	'354',	'366',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',	'402',	'412',	'415',	'425',
'430',	'437',	'444',	'445',	'446',	'448',	'449',	'460',	'500',	'501',	'502',	'603',	'604','606','617','618')
	AND etb.dtouvertstruct_stru IS NOT NULL
	AND etb.dtfermestruct_stru IS NULL
	AND (etb.cdconstatcaducite_stru IS NULL OR etb.cdconstatcaducite_stru = 'N')
	AND d.cddept_dept != '975'
)

SELECT 
	CodeRegion
	,LibelleRegion
	,NumFINESS_EG
	,DT_OuvertureEG_FINESS
	,DT_AutorisationEG_FINESS
	,DenominationEG_FINESS
	,CodeCategorieEG
	,LibelleCategorieEG
	,NumFINESS_EJ
	,CodeDepartement
	,LibelleDepartement
	,ChampActivite
	,SecteurEG
	,CASE 
		WHEN CodeCategorieEG in ('178','197','228','603','604','606','617','618') THEN 'Nouveau périmètre'
		ELSE 'Périmètre historique'
	END AS TypePerimetre
	-- Aggregation pour ne conserver qu'un Flag par champ d'activite (un champs d'activite peut avoir plusieurs activites associees hors reanimation)
	,MAX(FG_AutorisationRea) AS FG_AutorisationRea
	,MAX(FG_AutorisationReaPed) AS FG_AutorisationReaPed
	,DT_MAJ_Finess
FROM query
GROUP BY CodeRegion
	,LibelleRegion
	,NumFINESS_EG
	,DT_OuvertureEG_FINESS
	,DT_AutorisationEG_FINESS
	,DenominationEG_FINESS
	,CodeCategorieEG
	,LibelleCategorieEG
	,NumFINESS_EJ
	,CodeDepartement
	,LibelleDepartement
	,ChampActivite
	,SecteurEG
	,DT_MAJ_Finess