USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_IND_ObjectifSEGUR AS

/*
Description : Vue d'agregation permettant de calculer les objectifs SEGUR sur les indicateurs ROR et synchronisationVT
Sources : 
  - T_IND_SuiviPeuplementROR_HISTO (DATALAB)
  - VTEMP_IND_SynchroRORVT_HISTO (DATALAB)
  - V_IND_SuiviPeuplementROR (DATALAB)
Vue utilisée par :
  - Suivi_Peuplement_VFD (PowerBI)
*/

WITH peuplement AS (
SELECT 
	DT_Reference
	, CodeRegion
	, ChampActivite
	, SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
	, SUM(NB_EG_PeuplementFinalise) AS NB_EG_PeuplementFinalise
	, CASE 
		WHEN SUM(NB_EG_PerimetreFiness) = 0 THEN 0
		ELSE SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL)
	END AS DC_TauxPeuplement
	, CASE 
		WHEN SUM(NB_EG_PerimetreFiness) = 0 THEN 0.85
		WHEN SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL) >= 0.95
			THEN 1.0
		WHEN ROUND(SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL),2) >= 0.85
			THEN SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL) + 0.05
		ELSE 0.85
	 END AS DC_ObjectifSEGUR
FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
WHERE ChampActivite in ('PA','PH','MCO','PSY') AND TypePerimetre = 'Périmètre historique'
GROUP BY DT_Reference, CodeRegion, ChampActivite
)

, perimetre_SI_APA AS (
SELECT 
	DT_Reference
	, CodeRegion
	, CodeDepartement
	, SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
FROM DATALAB.DLAB_002.T_IND_ImportPerimetreSI_APA
GROUP BY DT_Reference, CodeRegion, CodeDepartement
)

, peuplement_SI_APA AS (
SELECT 
	DT_Reference
	, CodeRegion
	, CodeDepartement
	, SUM(NB_EG_PerimetreFiness) AS NB_EG_PerimetreFiness
	, SUM(NB_EG_PeuplementFinalise) AS NB_EG_PeuplementFinalise
	, CASE 
		WHEN SUM(NB_EG_PerimetreFiness) = 0 THEN 0
		ELSE SUM(NB_EG_PeuplementFinalise) / CAST(SUM(NB_EG_PerimetreFiness) as DECIMAL)
	END AS DC_TauxPeuplement
FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
WHERE CodeCategorieEG IN ('209','460') 
	AND CodeDepartement IN ('07','80','64','65','66','46','73','85','89','973')
GROUP BY DT_Reference, CodeRegion, CodeDepartement
)

,synchronisationVT AS (
SELECT
	DT_Reference
	, CodeRegion
	, Domaine
	, SUM(NB_EG_PerimetreVT) AS NB_EG_PerimetreSynchronisation
	, ISNULL(SUM(NB_EG_SynchronisationFinalise),0) AS NB_EG_SynchronisationFinalise
	, CASE 
		WHEN SUM(NB_EG_PerimetreVT) = 0 THEN 0
		ELSE ISNULL(SUM(NB_EG_SynchronisationFinalise),0) / CAST(SUM(NB_EG_PerimetreVT) as DECIMAL)
	END AS DC_TauxSynchronisation
	, CASE 
		WHEN SUM(NB_EG_PerimetreVT) = 0 THEN 0
		WHEN ISNULL(SUM(NB_EG_SynchronisationFinalise),0) / CAST(SUM(NB_EG_PerimetreVT) as DECIMAL) >= 0.95
			THEN 1.0
		WHEN ROUND(ISNULL(SUM(NB_EG_SynchronisationFinalise),0) / CAST(SUM(NB_EG_PerimetreVT) as DECIMAL),2) >= 0.5
			THEN ISNULL(SUM(NB_EG_SynchronisationFinalise),0) / CAST(SUM(NB_EG_PerimetreVT) as DECIMAL) + 0.05
		ELSE 0.5
	 END AS DC_ObjectifSEGUR
FROM DATALAB.DLAB_002.T_IND_SynchroRORVT_HISTO
WHERE Domaine IN ('Grand Age','Handicap') AND TypePerimetre = 'Historique'
GROUP BY DT_Reference, CodeRegion, Domaine
)

, synchronisationVT_SI_APA AS (
	SELECT
		DT_Reference
		, CodeRegion
		, CodeDepartement
		, SUM(NB_EG_PerimetreROR) AS NB_EG_PerimetreSynchronisation
		, ISNULL(SUM(NB_EG_SynchronisationFinalise),0) AS NB_EG_SynchronisationFinalise
		, CASE 
			WHEN SUM(NB_EG_PerimetreROR) = 0 THEN 0
			ELSE SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreROR) AS decimal)
		END AS DC_TauxSynchronisation
	FROM DATALAB.DLAB_002.T_IND_SynchroRORVT_HISTO
	WHERE TypePerimetre = 'Domicile' AND CodeDepartement IN ('07','80','64','65','66')
	GROUP BY DT_Reference, CodeRegion, CodeDepartement
)

, objectifs AS (
-- Objectifs SEGUR ROR perimetre historique
SELECT 
	peuplement.CodeRegion
	, CASE 
		WHEN peuplement.ChampActivite IN ('PA','PH') THEN CONCAT('2.3d ESMS ',peuplement.ChampActivite)
		ELSE CONCAT('2.3d ES ',peuplement.ChampActivite)
	END AS ReferenceObjectifSEGUR
	, 'Peuplement ROR' AS LibelleObjectifSEGUR
	, '2023-2024' AS AnneObjectifSEGUR
	, '-3' AS CodeDepartement
	, peuplement.NB_EG_PerimetreFiness AS NB_EG_PerimetreReference
	, peuplement.NB_EG_PeuplementFinalise AS NB_EG_FinaliseReference
	, peuplement.DC_TauxPeuplement AS DC_TauxReference
	, peuplement.DC_ObjectifSEGUR
	, CEILING((peuplement.NB_EG_PerimetreFiness * peuplement.DC_ObjectifSEGUR) - peuplement.NB_EG_PeuplementFinalise) AS NB_ResteAFaireReference
	, peuplement_actuel.NB_EG_PerimetreFiness AS NB_EG_PerimetreActuel
	, peuplement_actuel.NB_EG_PeuplementFinalise AS NB_EG_FinaliseActuel
	, peuplement_actuel.DC_TauxPeuplement AS DC_TauxActuel
	, CASE 
		WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		WHEN ROUND(peuplement_actuel.DC_TauxPeuplement,2) >= ROUND(peuplement.DC_ObjectifSEGUR,2) THEN 0
		ELSE CEILING((peuplement_actuel.NB_EG_PerimetreFiness * peuplement.DC_ObjectifSEGUR) - peuplement_actuel.NB_EG_PeuplementFinalise)
	  END AS NB_ResteAFaireActuel
FROM peuplement
LEFT JOIN peuplement AS peuplement_actuel
	ON peuplement.CodeRegion = peuplement_actuel.CodeRegion AND peuplement.ChampActivite = peuplement_actuel.ChampActivite 
	AND peuplement_actuel.DT_Reference = '2023-12-31'
WHERE peuplement.DT_Reference = '2023-06-30'
-- Objectifs SEGUR ROR SI APA
UNION ALL
SELECT 
	perimetre_SI_APA.CodeRegion
	, '2.3d SI APA'
	, 'Peuplement ROR'
	, '2023-2024'
	, perimetre_SI_APA.CodeDepartement
	, perimetre_SI_APA.NB_EG_PerimetreFiness
	, NULL
	, NULL
	, CASE WHEN perimetre_SI_APA.NB_EG_PerimetreFiness = 0 THEN 0 ELSE 1.0 END
	, NULL
	, peuplement_SI_APA_actuel.NB_EG_PerimetreFiness
	, CASE WHEN perimetre_SI_APA.CodeRegion IN ('75') THEN NULL ELSE peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise END
	-- Recalcul du taux de peuplement en fonction de l'hypothese prise dans les objectifs SEGUR 
	, CASE 
		WHEN (perimetre_SI_APA.CodeRegion IN ('75') OR perimetre_SI_APA.NB_EG_PerimetreFiness = 0) THEN NULL
		WHEN peuplement_SI_APA_actuel.NB_EG_PerimetreFiness <= perimetre_SI_APA.NB_EG_PerimetreFiness THEN peuplement_SI_APA_actuel.DC_TauxPeuplement
		WHEN peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise > perimetre_SI_APA.NB_EG_PerimetreFiness THEN 1.0
		ELSE peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise / CAST(perimetre_SI_APA.NB_EG_PerimetreFiness as DECIMAL) END
	, CASE
		WHEN (perimetre_SI_APA.CodeRegion IN ('75') OR perimetre_SI_APA.NB_EG_PerimetreFiness = 0) THEN NULL 
		WHEN peuplement_SI_APA_actuel.NB_EG_PerimetreFiness <= perimetre_SI_APA.NB_EG_PerimetreFiness 
			AND ROUND(peuplement_SI_APA_actuel.DC_TauxPeuplement,2) < 1.0 
			THEN peuplement_SI_APA_actuel.NB_EG_PerimetreFiness - peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise
		WHEN peuplement_SI_APA_actuel.NB_EG_PerimetreFiness > perimetre_SI_APA.NB_EG_PerimetreFiness 
			AND ROUND(peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise / CAST(perimetre_SI_APA.NB_EG_PerimetreFiness as DECIMAL),2) < 1.0 
			THEN perimetre_SI_APA.NB_EG_PerimetreFiness - peuplement_SI_APA_actuel.NB_EG_PeuplementFinalise
		ELSE 0 END 
FROM perimetre_SI_APA
LEFT JOIN peuplement_SI_APA AS peuplement_SI_APA_actuel
	ON perimetre_SI_APA.CodeDepartement = peuplement_SI_APA_actuel.CodeDepartement
	AND peuplement_SI_APA_actuel.DT_Reference = '2023-12-31'
-- Objectifs SEGUR SynchronisationVT perimetre historique
UNION ALL
SELECT 
	synchronisationVT.CodeRegion
	,CONCAT('2.3e ', synchronisationVT.Domaine)
	, 'Synchronisation ROR/VT'
	, '2023-2024'
	, '-3'
	, synchronisationVT.NB_EG_PerimetreSynchronisation
	, synchronisationVT.NB_EG_SynchronisationFinalise
	, synchronisationVT.DC_TauxSynchronisation
	, synchronisationVT.DC_ObjectifSEGUR
	, CEILING((synchronisationVT.NB_EG_PerimetreSynchronisation * synchronisationVT.DC_ObjectifSEGUR) - synchronisationVT.NB_EG_SynchronisationFinalise)
	, ISNULL(synchronisationVT_actuel.NB_EG_PerimetreSynchronisation,0)
	, ISNULL(synchronisationVT_actuel.NB_EG_SynchronisationFinalise,0)
	, ISNULL(synchronisationVT_actuel.DC_TauxSynchronisation,0)
	, CASE 
		WHEN synchronisationVT.DC_ObjectifSEGUR = 0 THEN 0
		WHEN ROUND(synchronisationVT_actuel.DC_TauxSynchronisation,2) >= ROUND(synchronisationVT.DC_ObjectifSEGUR,2) THEN 0
		ELSE CEILING((synchronisationVT_actuel.NB_EG_PerimetreSynchronisation * synchronisationVT.DC_ObjectifSEGUR) - synchronisationVT_actuel.NB_EG_SynchronisationFinalise)
	  END
FROM synchronisationVT
LEFT JOIN synchronisationVT AS synchronisationVT_actuel
	ON synchronisationVT.CodeRegion = synchronisationVT_actuel.CodeRegion AND synchronisationVT.Domaine = synchronisationVT_actuel.Domaine 
	AND synchronisationVT_actuel.DT_Reference = '2023-12-31'
WHERE synchronisationVT.DT_Reference = '2023-06-30'
-- Objectifs SEGUR SynchronisationVT SI APA
UNION ALL
SELECT 
	synchronisationVT_SI_APA.CodeRegion
	, '2.3e SI APA'
	, 'Synchronisation ROR/VT'
	, '2023-2024'
	, synchronisationVT_SI_APA.CodeDepartement
	, synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation
	, synchronisationVT_SI_APA.NB_EG_SynchronisationFinalise
	, synchronisationVT_SI_APA.DC_TauxSynchronisation
	, CASE WHEN synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation = 0 THEN 0 ELSE 0.8 END AS DC_ObjectifSEGUR
	, CEILING((synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation * 0.8) - synchronisationVT_SI_APA.NB_EG_SynchronisationFinalise)
	, synchronisationVT_SI_APA_actuel.NB_EG_PerimetreSynchronisation
	, synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise
	-- Recalcul du taux de peuplement en fonction de l'hypothese prise dans les objectifs SEGUR 
	, CASE 
		WHEN synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation = 0 THEN NULL
		WHEN synchronisationVT_SI_APA_actuel.NB_EG_PerimetreSynchronisation <= synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation 
			THEN synchronisationVT_SI_APA_actuel.DC_TauxSynchronisation
		WHEN synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise > synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation THEN 1.0
		ELSE synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise / CAST(synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation as DECIMAL) END
	, CASE 
		WHEN synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation = 0 THEN NULL
		WHEN synchronisationVT_SI_APA_actuel.NB_EG_PerimetreSynchronisation <= synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation
			AND ROUND(synchronisationVT_SI_APA_actuel.DC_TauxSynchronisation,2) < 0.8 
			THEN CEILING((synchronisationVT_SI_APA_actuel.NB_EG_PerimetreSynchronisation * 0.8) - synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise)
		WHEN synchronisationVT_SI_APA_actuel.NB_EG_PerimetreSynchronisation > synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation 
			AND ROUND(synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise / CAST(synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation as DECIMAL),2) < 0.8 
			THEN CEILING((synchronisationVT_SI_APA.NB_EG_PerimetreSynchronisation * 0.8) - synchronisationVT_SI_APA_actuel.NB_EG_SynchronisationFinalise)
		ELSE 0
	  END
FROM synchronisationVT_SI_APA
LEFT JOIN synchronisationVT_SI_APA AS synchronisationVT_SI_APA_actuel
	ON synchronisationVT_SI_APA.CodeRegion = synchronisationVT_SI_APA_actuel.CodeRegion 
	AND synchronisationVT_SI_APA.CodeDepartement = synchronisationVT_SI_APA_actuel.CodeDepartement 
	AND synchronisationVT_SI_APA_actuel.DT_Reference = '2023-12-31'
WHERE synchronisationVT_SI_APA.DT_Reference = '2023-09-30'
)

SELECT
	CodeRegion
    ,ReferenceObjectifSEGUR
    ,LibelleObjectifSEGUR
    ,AnneObjectifSEGUR
    ,CodeDepartement
    ,NB_EG_PerimetreReference
    ,NB_EG_FinaliseReference
    ,DC_TauxReference
    ,DC_ObjectifSEGUR
    ,NB_ResteAFaireReference
    ,NB_EG_PerimetreActuel
    ,NB_EG_FinaliseActuel
    ,DC_TauxActuel
    ,NB_ResteAFaireActuel
FROM objectifs
UNION ALL 
SELECT 
	'00'
	,ReferenceObjectifSEGUR
    ,LibelleObjectifSEGUR
    ,AnneObjectifSEGUR
	,'-3'
	, SUM(NB_EG_PerimetreReference)
	, SUM(NB_EG_FinaliseReference)
	, ROUND(SUM(NB_EG_FinaliseReference) / CAST(SUM(NB_EG_PerimetreReference) AS decimal),2)
	, CASE 
		WHEN ReferenceObjectifSEGUR = '2.3d SI APA' THEN 1
		WHEN ReferenceObjectifSEGUR = '2.3e SI APA' THEN 0.8
		ELSE ROUND((SUM(NB_EG_FinaliseReference) + SUM(NB_ResteAFaireReference)) / CAST(SUM(NB_EG_PerimetreReference) AS decimal),2)
	END
	, SUM(NB_ResteAFaireReference)
	, SUM(NB_EG_PerimetreActuel)
	, SUM(NB_EG_FinaliseActuel)
	, ROUND(SUM(NB_EG_FinaliseActuel) / CAST(SUM(NB_EG_PerimetreActuel) AS decimal),2)
	, SUM(NB_ResteAFaireActuel)
FROM objectifs
GROUP BY ReferenceObjectifSEGUR, LibelleObjectifSEGUR, AnneObjectifSEGUR