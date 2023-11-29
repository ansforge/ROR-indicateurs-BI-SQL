USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_AutorisationFINESS AS

SELECT
    idstructure_stru AS ID_StructureFINESS
	,r.cdregion_regi AS CodeRegion
    ,d.cddept_dept AS CodeDepartement
    ,etb.nmfinessetab_stru AS NumFINESS_EG
    ,etb.raisonsociale_stru AS DenominationEG_FINESS
    ,etb.categetab_stru AS CodeCategorieEG_FINESS
    ,etb.dtouvertstruct_stru AS DateOuvertureFINESS
	,etb.dtautorisation_stru AS DateAutorisationFINESS
	,etb.telephone_stru AS TelephoneFINESS
	,etb.email_stru AS EmailFINESS
	,etb.dtmaj_stru AS DateMajFINESS
	,CASE 
		WHEN etb.categetab_stru IN ('178','197','228','603','604','606','617','618') THEN 'Nouveau périmètre 2023'
		WHEN etb.categetab_stru IN (
		'101',	'106',	'109',	'114',	'122',	'127',	'128',	'129',	'131',	'141',	'146',	'156',
		'161',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',	'195',	'196',	'198',
		'202',	'207',	'209',	'221',	'238',	'246',	'249',	'252',	'253',	'255',	'292',	'354',
		'355',	'362',	'365',	'366',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',
		'402',	'412',	'415',	'425',	'430',	'437',	'444',	'445',	'446',	'448',	'449',	'460',
		'500',	'501',	'502',	'696',	'697',	'698') THEN 'Périmètre historique'
		ELSE 'Non suivi' 
	END AS TypePerimetreROR
	,CASE 
		WHEN etb.categetab_stru in ('178','182','183','186','188','189','190','192','194','195','196','197'
		,'198','202','207','209','221','228','238','246','249','252','253','255','354','370','377'
		,'379','381','382','390','395','396','402','437','445','446','448','449','460','500','501','502') THEN 'Medico-social'
		WHEN etb.categetab_stru in ('101','106','109','114','122','127','128','129','131','141','146','156'
	    ,'161','292','355','362','365','366','412','415','425','430','444','696','697','698') THEN 'Sanitaire'
		WHEN etb.categetab_stru in ('604','606') THEN 'Coordination'
		WHEN etb.categetab_stru in ('124','603','617','618','SA05','SA07','SA08','SA09') THEN 'Offre de ville'
		ELSE 'Non défini'
	END AS DomaineROR
    ,COUNT(CASE WHEN (cdforme_acts = '05' AND cdactivite_acts != '04') 
        OR cdactivite_acts IN ('01','02','03','07','09','10','11','12','13','14','15','16','17','18','19','80',
		'81','82','83','84','85','86','87','88') THEN nmautorisation_acts END) AS NB_AutorisationMCO
    ,COUNT(CASE WHEN cdactivite_acts in ('50','53','59','51','57','55','52','58','56','54') AND cdforme_acts != '05' THEN nmautorisation_acts END) AS NB_AutorisationSMR
    ,COUNT(CASE WHEN cdactivite_acts = '04' OR categetab_stru IN ('156','161','292','366','412','415','425','430','444') 
        THEN ISNULL(nmautorisation_acts,nmfinessetab_stru)END) AS NB_AutorisationPSY
    ,COUNT(CASE WHEN cdactivite_acts = '15' AND cdmodalite_acts = '09' THEN nmautorisation_acts END) AS NB_AutorisationReanimation
    ,COUNT(CASE WHEN cdactivite_acts = '15' AND cdmodalite_acts in ('10','98') THEN nmautorisation_acts END)  AS NB_AutorisationReanimationPediatrique
    ,COUNT(CASE WHEN cdactivite_acts = '03' AND cdmodalite_acts = '01' THEN nmautorisation_acts END) AS NB_AutorisationObstetrique
    ,COUNT(CASE WHEN cdactivite_acts = '03' AND cdmodalite_acts = '02' THEN nmautorisation_acts END) AS NB_AutorisationNeonat
    ,COUNT(CASE WHEN cdactivite_acts = '03' AND cdmodalite_acts = '03' THEN nmautorisation_acts END) AS NB_AutorisationSoinsInstensifsNeonat
    ,COUNT(CASE WHEN cdactivite_acts = '03' AND cdmodalite_acts = '04' THEN nmautorisation_acts END) AS NB_AutorisationReanimationNeonat
    ,COUNT(CASE WHEN cdactivite_acts = '14' AND cdmodalite_acts = '23' THEN nmautorisation_acts END) AS NB_AutorisationUrgences
	,COUNT(CASE WHEN cdactivite_acts = '14' AND cdmodalite_acts = '24' THEN nmautorisation_acts END) AS NB_AutorisationUrgencesPediatriques
FROM BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS etb
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.dwh_activitesoin AS act
    ON etb.idstructure_stru = act.idstructure_acts 
    -- Dans le cadre de la reforme des autorisations, toutes les autorisations actives apres le 1er mai 2021 sont automatiquement prolongees
    AND CAST(act.dtfin_acts AS DATE) >= '2021-05-01'
	AND act.topsource_acts = 'FINESS'
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_commune as c
    ON etb.idcommune_stru = c.idcommune_comm
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_departement as d
    ON c.iddepartement_comm = d.iddept_dept
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_region as r
    ON d.idregion_dept = r.idregion_regi
WHERE etb.topsource_stru = 'FINESS' 
    AND etb.typeidpm_stru = 'EG'
    AND etb.dtouvertstruct_stru IS NOT NULL
    AND etb.dtfermestruct_stru IS NULL
    AND ISNULL(etb.cdconstatcaducite_stru,'N') = 'N'
    AND d.cddept_dept != '975'
GROUP BY idstructure_stru
	,r.cdregion_regi
    ,d.cddept_dept
    ,etb.nmfinessetab_stru
    ,etb.raisonsociale_stru
    ,etb.categetab_stru
    ,etb.dtouvertstruct_stru
	,etb.dtautorisation_stru
	,etb.telephone_stru
	,etb.email_stru
	,etb.dtmaj_stru