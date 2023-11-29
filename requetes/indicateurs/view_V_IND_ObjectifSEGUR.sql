USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_IND_ObjectifSEGUR AS

/*
Contexte : Vue calculant les objectifs SEGUR autour du ROR
Version de la vue : 0.3
Note de la dernière évolution : ajout des chiffres de la région Grand Est
Sources : 
  - T_IND_SuiviPeuplementROR_HISTO (DATALAB)
  - VTEMP_IND_SynchroRORVT_HISTO (DATALAB)
  - V_IND_SuiviPeuplementROR (DATALAB)
Vue utilisée par :
  - Suivi_Peuplement_VFD (PowerBI)
Evolutions à venir : Remplacement de la source VTEMP_IND_SynchroRORVT_HISTO lorsqu'elle aura été créée
*/

WITH peuplement AS (
SELECT 
	DT_Reference
	, CodeRegion
	, SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
	, SUM(NB_EG_PeuplementFinalise) AS NB_EG_PeuplementFinalise
	, CASE 
		WHEN SUM(NB_EG_PerimetreFiness) = 0 THEN 0
		ELSE SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL)
	END AS DC_TauxPeuplement
	, CASE 
		WHEN DT_Reference <> '2022-06-30' THEN NULL
		WHEN SUM(NB_EG_PerimetreFiness) = 0 THEN 0.3
		WHEN SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL) < 0.6
			THEN SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL) + 0.3
		ELSE NULL
	 END AS DC_ObjectifSEGUR
FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
WHERE ChampActivite in ('PA','PH') AND TypePerimetre = 'Périmètre historique'
GROUP BY DT_Reference, CodeRegion
)

, synchronisation AS (
SELECT 
	DT_Reference
	, CodeRegion
	, SUM(NB_EG_PerimetreSynchroVT_Calcule) AS NB_EG_PerimetreSynchroVT_Calcule
	, SUM(NB_EG_SynchronisationFinalise) AS NB_EG_SynchronisationFinalise
	, CASE 
		WHEN SUM(NB_EG_PerimetreSynchroVT_Calcule) = 0 THEN 0
		ELSE SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreSynchroVT_Calcule) as DECIMAL)
	END AS DC_TauxSynchronisation
	, CASE 
		WHEN DT_Reference <> '2022-06-30' THEN NULL
		WHEN SUM(NB_EG_PerimetreSynchroVT_Calcule) = 0 THEN 0.3
		WHEN SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreSynchroVT_Calcule) as DECIMAL) > 0.7 
			THEN 1
		ELSE SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreSynchroVT_Calcule) as DECIMAL) + 0.3
	 END AS DC_ObjectifSEGUR
FROM DATALAB.DLAB_002.T_IND_SynchroRORVT_HISTO
WHERE Domaine in ('Grand Age','Handicap')
GROUP BY DT_Reference,CodeRegion
)

SELECT 
	peuplement.CodeRegion
	, 'II.3.D.2' AS ReferenceObjectifSEGUR
	, 'Peuplement ROR' AS LibelleObjectifSEGUR
	, peuplement.NB_EG_PerimetreFiness AS NB_EG_PerimetreReference
	, peuplement.NB_EG_PeuplementFinalise AS NB_EG_FinaliseReference
	, peuplement.DC_TauxPeuplement AS DC_TauxReference
	, peuplement.DC_ObjectifSEGUR
	, CASE WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		ELSE peuplement_actuel.NB_EG_PerimetreFiness END AS NB_EG_PerimetreActuel
	, CASE WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		ELSE peuplement_actuel.NB_EG_PeuplementFinalise END AS NB_EG_FinaliseActuel
	, CASE WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		ELSE peuplement_actuel.DC_TauxPeuplement END AS DC_TauxActuel
	, CASE 
		WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		WHEN peuplement_actuel.DC_TauxPeuplement >= ROUND(peuplement.DC_ObjectifSEGUR,2) THEN 0
		ELSE ROUND((peuplement_actuel.NB_EG_PerimetreFiness * peuplement.DC_ObjectifSEGUR) - peuplement_actuel.NB_EG_PeuplementFinalise,0)
	  END AS NB_ResteAFaireActuel
FROM peuplement
LEFT JOIN peuplement AS peuplement_t1_2023
	ON peuplement.CodeRegion = peuplement_t1_2023.CodeRegion AND peuplement_t1_2023.DT_Reference = '2023-03-31'
LEFT JOIN (
	SELECT 
		CodeRegion
		-- Ajout des chiffres au 31/05/2023 pour les régions NAQ et GES
		, CASE WHEN CodeRegion = '75' THEN 2463
			WHEN CodeRegion = '44' THEN 909
			ELSE SUM(NB_EG_PeuplementFinalise) END AS NB_EG_PeuplementFinalise
		, CASE WHEN CodeRegion = '75' THEN 2557
			ELSE SUM(NB_EG_PerimetreFiness) END AS NB_EG_PerimetreFiness
		, CASE WHEN CodeRegion = '75' THEN 2463/CAST(2557 AS DECIMAL)
			WHEN CodeRegion = '44' THEN 909 / CAST(SUM(NB_EG_PerimetreFiness) AS DECIMAL)
			ELSE SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) AS DECIMAL) END AS DC_TauxPeuplement
	FROM DATALAB.DLAB_002.V_IND_SuiviPeuplementROR
	WHERE ChampActivite in ('PA','PH') 
		AND TypePerimetre = 'Périmètre historique' 
		AND CodeRegion in ('01','03','04','06','11','27','28','32','44','52','75','76','84','94') 
	GROUP BY CodeRegion
) AS peuplement_actuel
	ON peuplement.CodeRegion = peuplement_actuel.CodeRegion
WHERE peuplement.DT_Reference = '2022-06-30'
UNION ALL
SELECT 
	synchronisation.CodeRegion
	, 'II.3.D.3'
	, 'Synchronisation ROR/VT'
	, synchronisation.NB_EG_PerimetreSynchroVT_Calcule
	, synchronisation.NB_EG_SynchronisationFinalise
	, synchronisation.DC_TauxSynchronisation
	, synchronisation.DC_ObjectifSEGUR
	, synchro_actuel.NB_EG_PerimetreSynchroVT_Calcule
	, synchro_actuel.NB_EG_SynchronisationFinalise
	, synchro_actuel.DC_TauxSynchronisation
	,  CASE
		WHEN ROUND(synchro_actuel.DC_TauxSynchronisation,2) >= ROUND(synchronisation.DC_ObjectifSEGUR,2) THEN 0
		ELSE ROUND((synchro_actuel.NB_EG_PerimetreSynchroVT_Calcule * synchronisation.DC_ObjectifSEGUR) - synchro_actuel.NB_EG_SynchronisationFinalise,0)
	  END
FROM synchronisation
LEFT JOIN synchronisation AS synchro_t1_2023
	ON synchronisation.CodeRegion = synchro_t1_2023.CodeRegion 
	AND synchro_t1_2023.DT_Reference = '2023-03-31'
LEFT JOIN (
	SELECT
		CodeRegion
		, SUM(NB_EG_PerimetreSynchroVT_Calcule) AS NB_EG_PerimetreSynchroVT_Calcule
		, SUM(NB_EG_SynchronisationFinalise) AS NB_EG_SynchronisationFinalise
		, CASE 
			WHEN SUM(NB_EG_PerimetreSynchroVT_Calcule) = 0 THEN 0
			ELSE SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreSynchroVT_Calcule) as DECIMAL)
		END AS DC_TauxSynchronisation
	FROM DATALAB.DLAB_002.V_IND_SynchroRORVT
	WHERE Domaine in ('Grand Age','Handicap')
	GROUP BY CodeRegion
) AS synchro_actuel
	ON synchronisation.CodeRegion = synchro_actuel.CodeRegion 
WHERE synchronisation.DT_Reference = '2022-06-30'