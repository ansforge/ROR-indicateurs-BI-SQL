USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_SynchroRORVT AS

/*
Contexte : Vue contenant les donnees de syncrhonisation ROR VT retravaillees avec un croisement des donnees dans Finess
Version de la vue : 2.0
Notes derniere evolution : Modification de la structure de la table et intégration du périmètre SI APA
Sources : 
  - T_DIM_ImportSynchroRORVT (DATALAB)
  - V_DIM_SuiviPeuplementROR_EG (DATALAB)
  - dwh_structure (BICOEUR)
  - ref_commune (BICOEUR)
  - ref_departement (BICOEUR)
  - ref_region (BICOEUR)
Vue utilisee par :
  - V_IND_SynchroRORVT (DATALAB)
*/

WITH PeuplementROR AS (
	SELECT DISTINCT
	NumFINESS_EG
	,FIRST_VALUE(StatutPeuplement) OVER(PARTITION BY NumFINESS_EG ORDER BY StatutPeuplement ASC) AS StatutPeuplement
FROM DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_EG
WHERE FG_PerimetreSuiviPeuplement = '1'
)


, Requete AS (
SELECT
	COALESCE(r.cdregion_regi,vt.CodeRegion,'-2') AS CodeRegion
	, ISNULL(d.cddept_dept,'-2') AS CodeDepartement
	, vt.Finess
	, vt.NomEtablissement
	, CASE 
		WHEN s.categetab_stru IN ('463',	'340',	'359',	'214',	'165',	'180',	'219',	'258',	'403',	'442',
		'464',	'461',	'462',	'124',	'132',	'126',	'294',	'213',	'347',	'439',	'433',	'695',	'699',	'422',
		'230',	'268',	'603',	'197',	'228',	'606',	'696',	'697',	'190',	'354') THEN 'Non suivi'
		ELSE 'Historique'
	END AS TypePerimetre
	, CASE WHEN vt.Domaine = '4' THEN 'Handicap' ELSE vt.Domaine END AS DomaineVT
	, vt.EtatVT
	, CASE	
		WHEN EtatVT = 'Fermeture Définitive' THEN 'N'
		WHEN s.cdtypefermestruct_stru in ('DEF','ERR','NDI','CHP','EML') THEN 'N'
		WHEN s.categetab_stru in ('463','340',	'359',	'214',	'165',	'180',	'219',	'258',	'403',	'442',
        '464',	'461',	'462',	'124',	'132',	'126',	'294',	'213',	'347',	'439',	'433',	'695',	'699',	'422',
        '230',	'268',	'603',	'197',	'228',	'606',	'696',	'697',	'190',	'354') THEN 'N'
		ELSE 'O'
	  END as SuiviSynchronisationRORVT
	, vt.EtatSynchronisationROR
	, vt.DateSynchronisation
	, ISNULL(s.categetab_stru,'-1') AS CodeCategorieEG_Finess
	, CASE WHEN ror.NumFINESS_EG IS NOT NULL THEN 'O' ELSE 'N' END AS SuiviPeuplementROR
	, ror.StatutPeuplement AS StatutPeuplementROR
	, CASE 
		WHEN s.nmfinessetab_stru IS NULL THEN 'Non identifié'
		WHEN dtfermestruct_stru IS NOT NULL AND s.cdtypefermestruct_stru = 'PRO' THEN 'Fermeture provisoire'
		WHEN dtfermestruct_stru IS NOT NULL THEN 'Fermeture définitive'
		WHEN cdconstatcaducite_stru = 'O' THEN 'Caduc'
		WHEN dtouvertstruct_stru IS NULL THEN 'Autorisé'
		ELSE 'Ouvert'
	  END as EtatFiness
	, s.dtautorisation_stru AS DateAutorisationFiness
	, s.dtouvertstruct_stru AS DateOuvertureFiness
	, s.dtfermestruct_stru AS DateFermetureFiness
FROM DATALAB.DLAB_002.T_DIM_ImportSynchroRORVT AS vt
-- Croisement avec les données de suivi de peuplement pour récupérer le statut de peuplement des établissements
LEFT JOIN PeuplementROR AS ror
	ON vt.Finess = ror.NumFINESS_EG
-- Croisement avec les données Finess pour récupérer l'état de l'établissement
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS s
	ON vt.Finess = s.nmfinessetab_stru AND s.topsource_stru = 'FINESS'
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_commune as c
	ON s.idcommune_stru = c.idcommune_comm
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_departement as d
	ON c.iddepartement_comm = d.iddept_dept
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.ref_region as r
	ON d.idregion_dept = r.idregion_regi
WHERE s.categetab_stru NOT IN ('460','209')
-- Le périmètre de synchronisation pour les structures du périmètre SI APA est différent
UNION ALL
SELECT
	Finess.CodeRegion
	,Finess.CodeDepartement
	,Finess.NumFINESS_EG
	,Finess.DenominationEG_FINESS
	,'Domicile'
	, CASE WHEN vt.Domaine = '4' THEN 'Handicap' ELSE vt.Domaine END
	, vt.EtatVT
	, CASE WHEN vt.EtatVT = 'Fermeture Définitive' THEN 'N' ELSE 'O' END
	, vt.EtatSynchronisationROR
	, vt.DateSynchronisation
	, Finess.CodeCategorieEG_FINESS
	, CASE WHEN ror.NumFINESS_EG IS NOT NULL THEN 'O' ELSE 'N' END
	, ror.StatutPeuplement
	, CASE 
		WHEN Finess.DateOuvertureFINESS IS NULL THEN 'Autorisé'
		ELSE 'Ouvert'
	  END as EtatFiness
	, Finess.DateAutorisationFINESS
	, Finess.DateOuvertureFINESS
	, NULL
FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Finess
LEFT JOIN DATALAB.DLAB_002.T_DIM_ImportSynchroRORVT AS vt
	ON Finess.NumFINESS_EG = vt.Finess
LEFT JOIN PeuplementROR AS ror
	ON Finess.NumFINESS_EG = ror.NumFINESS_EG
WHERE CodeCategorieEG_FINESS IN ('460','209')
)

SELECT
	CodeRegion
	,CodeDepartement
	,Finess
	,NomEtablissement
	,TypePerimetre
	,DomaineVT
	,EtatVT
	,SuiviSynchronisationRORVT
	,EtatSynchronisationROR
	,DateSynchronisation
	,CodeCategorieEG_Finess
	,EtatFiness
	,DateAutorisationFiness
	,DateOuvertureFiness
	,DateFermetureFiness
	,SuiviPeuplementROR
	,StatutPeuplementROR
	, CAST(DATEADD(d,1,MAX(DateSynchronisation) OVER ()) AS date) AS DT_MAJ_Fichier
FROM Requete