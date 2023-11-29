USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_IND_SynchroRORVT AS

/*
Contexte : Indicateurs de synchronisation ROR-VT calculés par Domaine et Code Region à partir de la liste détaillée des établissements transmis par VT
Version : 1.6
Notes de la derniere evolution : Ajout d'une règle pour le Domaine = 4
Sources de données : 
 - T_DIM_ImportSynchroROR_VT (DATALAB)
 - V_DIM_SynchroRORVT (DATALAB)
 - T_IND_SuiviPeuplementROR_HISTO (DATALAB)
Vue utilisée par : 
 - VTEMP_IND_SynchroRORVT_HISTO (DATALAB)
Evolutions à venir : Les sources utilisées ont pour vocation à évoluer lorsque la vue aura été historisée (cf. commentaires)
*/

-- CTE permettant de concevoir la base de la table avec l'ensemble des Domaines pour chaque région et d'identifier les dates de référence
WITH actuel AS (
    -- Distinct nécessaire car la source V_DIM_SynchroRORVT possède plusieurs lignes par établissements dont les données ne sont pas utilisées pour les indicateurs
	SELECT DISTINCT
		CASE -- Evol : Condition à supprimer lorsque les données de Janvier 2023 auront été envoyées
			WHEN CAST(DATEADD(d,1,MaxDateSynchroVT) as date) = '2023-01-05' THEN '2022-12-31'
			WHEN CAST(DATEADD(d,1,MaxDateSynchroVT) as date) = '2023-07-03' THEN '2023-06-30'
			ELSE CAST(DATEADD(q,1,DATEADD(qq, DATEDIFF(qq,0, MaxDateSynchroVT), 0))-1 as date) 
		END AS DT_Reference
        ,CodeRegion
		,DomaineVT
		,Finess
		,NomEtablissement
		,CategorieEG_Finess
		,LibelleCategorieEG_Finess
		,EtatSynchronisationROR
		,CAST(DATEADD(d,1,MaxDateSynchroVT) as date) AS DT_MAJ_Fichier
	FROM DATALAB.DLAB_002.V_DIM_SynchroRORVT
	-- Identification de la date de mise à jour du fichier à partir de la dernière date de synchronisation disponible
	CROSS JOIN ( 
		SELECT MAX(DateSynchronisation) AS MaxDateSynchroVT
		FROM DATALAB.DLAB_002.V_DIM_SynchroRORVT
	) AS MaxDate
	WHERE 
        EtatVT <> 'Fermeture Définitive' 
        AND EtatFiness not in ('Fermé DEF','Fermé ERR','Fermé CHP','Fermé NDI','Fermé EML')
        -- Exclusion des catégories d'établissements dont le peuplement n'est pas suivi dans le ROR et incohérentes pour les indicateurs
        AND CategorieEG_Finess NOT IN ('463',	'340',	'359',	'214',	'165',	'180',	'219',	'258',	'403',	'442',
        '464',	'461',	'462',	'124',	'132',	'126',	'294',	'213',	'347',	'439',	'433',	'695',	'699',	'422',
        '230',	'268',	'603',	'197',	'228',	'606',	'696',	'697',	'190',	'460',	'354',	'209')
),

-- CTE permettant de concevoir la base de la table avec l'ensemble des Domaines pour chaque région
base AS (
SELECT DISTINCT
	DT_Reference 
	,CodeRegion
	,cj.Domaine
	,CASE cj.Domaine
		WHEN 'Grand Age' THEN 'PA'
		WHEN 'Handicap' THEN 'PH'
		WHEN 'Sanitaire' THEN 'SMR'
		ELSE NULL
	END AS DomaineCorrespondanceROR
	,DT_MAJ_Fichier
FROM actuel
CROSS JOIN (
	SELECT DISTINCT CASE WHEN Domaine = '4' THEN 'Handicap' ELSE Domaine END AS Domaine
	FROM DATALAB.DLAB_002.T_DIM_ImportSynchroRORVT
) AS cj
)

SELECT
	base.DT_Reference
	,'trimestre' AS Periodicite
	,base.CodeRegion
	,base.Domaine
	,ISNULL(actuel.CategorieEG_Finess,'-1') AS CategorieEG_Finess
	,actuel.LibelleCategorieEG_Finess
	,COUNT(actuel.Finess) AS NB_EG_PerimetreSynchroVT
	-- Gestion du cas où la cible VT était égale à 0 au 30/06/2022 (cf. hypothèse objectifs SEGUR 2023) :
	-- remplacement par le périmètre de peuplement ROR sur le champ activité concerné
	,COALESCE(MAX(ror.NB_EG_PerimetreFiness),MAX(ror_agg.NB_EG_PerimetreFiness),0) AS NB_EG_PerimetreFiness
	,CASE
		-- Identification des régions n'utilisant pas certains modules VT
		WHEN base.CodeRegion in ('06') THEN NULL
		WHEN base.Domaine = 'Grand Age' AND base.CodeRegion in ('04','03','94') THEN NULL
		WHEN CONCAT(base.CodeRegion, base.Domaine) in (
			SELECT CONCAT(CodeRegion,Domaine)
			FROM DATALAB.DLAB_002.T_IND_SynchroRORVT_HISTO
			WHERE DT_Reference = '2022-06-30' AND NB_EG_PerimetreSynchroVT = 0
			) 
			-- Dans les cas où le champ d'activité ne figure plus dans le périmètre alors la cible sera nulle dans la table source
			-- L'historique des données de peuplement commence au 2nd trimestre 2022, ainsi toutes les cibles sont nulles
			THEN COALESCE(MAX(ror.NB_EG_PerimetreFiness),MAX(ror_agg.NB_EG_PerimetreFiness),0) 
		ELSE COUNT(actuel.Finess)
	END AS NB_EG_PerimetreSynchroVT_Calcule
	,CASE
		-- Identification des régions n'utilisant pas certains modules VT
		WHEN base.CodeRegion in ('06') THEN NULL
		WHEN base.Domaine = 'Grand Age' AND base.CodeRegion in ('04','03','94') THEN NULL
		ELSE COUNT(CASE WHEN EtatSynchronisationROR = 'Mise à jour de l’offre active' THEN actuel.Finess END) 
	END AS NB_EG_SynchronisationFinalise
	,base.DT_MAJ_Fichier
FROM base
LEFT JOIN actuel
	ON actuel.CodeRegion = base.CodeRegion 
	AND actuel.DomaineVT = base.Domaine
-- Jointure avec les indicateurs de peuplement ROR agrégés au niveau catégorie EG
LEFT JOIN (
	SELECT 
		CodeRegion
		,ChampActivite
		,CodeCategorieEG
		,DT_Reference
		,SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
	FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
	GROUP BY CodeRegion,ChampActivite,CodeCategorieEG, DT_Reference
	) AS ror
	ON ror.CodeRegion = base.CodeRegion
	AND ror.ChampActivite = base.DomaineCorrespondanceROR 
	AND ror.CodeCategorieEG = actuel.CategorieEG_Finess
	AND ror.DT_Reference = base.DT_Reference
	AND actuel.CategorieEG_Finess IS NOT NULL
-- Jointure avec les indicateurs de peuplement ROR agrégés au niveau champ activité pour les cas où aucun établissement n'a été créé dans VT
LEFT JOIN (
	SELECT 
		CodeRegion
		,ChampActivite
		,DT_Reference
		,SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
	FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
	GROUP BY CodeRegion,ChampActivite, DT_Reference
	) AS ror_agg
	ON ror_agg.CodeRegion = base.CodeRegion
	AND ror_agg.ChampActivite = base.DomaineCorrespondanceROR 
	AND ror_agg.DT_Reference = base.DT_Reference
	AND actuel.CategorieEG_Finess IS NULL
GROUP BY base.DT_Reference,base.CodeRegion,base.Domaine,actuel.CategorieEG_Finess,actuel.LibelleCategorieEG_Finess, base.DT_MAJ_Fichier