USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_REF_J55_CategorieEG AS

SELECT 
	ID_NOS
	,Nomenclature_OID
	,Nomenclature_Nom
	,OID
	,Code
	,Libelle
	,CASE
		WHEN Code IN (	'165',	'166',	'180',	'213',	'231',	'608',	'638') THEN 'Nouveau périmètre 2024' 
		WHEN Code IN (	'178',	'197',	'228',	'603',	'604',	'606',	'617',	'618') THEN 'Nouveau périmètre 2023'
		WHEN Code IN (
		'101',	'106',	'109',	'114',	'122',	'127',	'128',	'129',	'131',	'141',	'146',	'156',
		'161',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',	'195',	'196',	'198',
		'202',	'207',	'209',	'221',	'238',	'246',	'249',	'252',	'253',	'255',	'292',	'354',
		'355',	'362',	'365',	'366',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',
		'402',	'412',	'415',	'425',	'430',	'437',	'444',	'445',	'446',	'448',	'449',	'460',
		'500',	'501',	'502',	'696',	'697',	'698') THEN 'Périmètre historique'
	ELSE 'Non suivi' END AS TypePerimetreROR
	,CASE 
		WHEN Code in (	'165',	'178',	'180',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',	'195',
		'196',	'197',	'198',	'202',	'207',	'209',	'213',	'221',	'228',	'231',	'238',	'246',	'249',	'252',
		'253',	'255',	'354',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',	'402',
		'437',	'445',	'446',	'448',	'449',	'460',	'500',	'501',	'502',	'608') THEN 'Medico-social'
		WHEN Code in (	'101',	'106',	'109',	'114',	'122',	'127',	'128',	'129',	'131',	'141',
		'146',	'156',	'161',	'166',	'292',	'355',	'362',	'365',	'366',	'412',	'415',	'425',
		'430',	'444',	'696',	'697',	'698',	'638') THEN 'Sanitaire'
		WHEN Code in (	'604',	'606') THEN 'Coordination'
		WHEN Code in (	'124',	'603',	'617',	'618',	'SA05',	'SA07',	'SA08',	'SA09') THEN 'Offre de ville'
		ELSE 'Non defini'
	END AS DomaineROR
FROM BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS
WHERE Nomenclature_OID = '1.2.250.1.213.3.3.65'
UNION ALL
SELECT
'-1'
,NULL
,NULL
,NULL
,'-1'
,NULL
,'Périmètre historique'
,'Non defini'