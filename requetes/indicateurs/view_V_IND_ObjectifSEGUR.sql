USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_IND_ObjectifSEGUR AS

/*
Contexte : Vue calculant les objectifs SEGUR autour du ROR
Version de la vue : 2.0
Note de la dernière évolution : Modification de la requête pour calcul des objectifs 2023-2024
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
AND DT_Reference = '2023-06-30'
GROUP BY DT_Reference, CodeRegion, ChampActivite
)

, SI_APA AS (
	SELECT CodeRegion, CodeDepartement, CodeCategorieEG_FINESS, NumFINESS_EG, 'Pilotes' AS TypeDepartement
	FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS
	WHERE CodeDepartement IN ('07','80','64','65','66') AND CodeCategorieEG_FINESS IN ('209','460')
	UNION ALL
	SELECT CodeRegion, CodeDepartement, CodeCategorieEG_FINESS, NumFINESS_EG, 'Vague 1'
	FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS
	WHERE CodeDepartement IN ('46','73','85','89','973') AND CodeCategorieEG_FINESS IN ('209','460')
)

, synchronisationVT AS (
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
WHERE DT_Reference = '2023-06-30' ANd Domaine IN ('Grand Age','Handicap')
GROUP BY DT_Reference, CodeRegion, Domaine
)

SELECT 
	peuplement.CodeRegion
	, CASE 
		WHEN ChampActivite IN ('PA','PH') THEN CONCAT('2.3d ESMS ',ChampActivite)
		ELSE CONCAT('2.3d ES ',ChampActivite)
	END AS ReferenceObjectifSEGUR
	, 'Peuplement ROR' AS LibelleObjectifSEGUR
	, '2023-2024' AS AnneObjectifSEGUR
	, NULL AS CodeDepartement
	, peuplement.NB_EG_PerimetreFiness AS NB_EG_PerimetreReference
	, peuplement.NB_EG_PeuplementFinalise AS NB_EG_FinaliseReference
	, peuplement.DC_TauxPeuplement AS DC_TauxReference
	, peuplement.DC_ObjectifSEGUR
	, CASE 
		WHEN peuplement.DC_ObjectifSEGUR IS NULL THEN NULL
		WHEN ROUND(peuplement.DC_TauxPeuplement,2) >= ROUND(peuplement.DC_ObjectifSEGUR,2) THEN 0
		ELSE CEILING((peuplement.NB_EG_PerimetreFiness * peuplement.DC_ObjectifSEGUR) - peuplement.NB_EG_PeuplementFinalise)
	  END AS NB_ResteAFaireActuel
FROM peuplement
UNION ALL
SELECT 
	SI_APA.CodeRegion
	, '2.3d SI APA'
	, 'Peuplement ROR'
	, '2023-2024'
	, SI_APA.CodeDepartement
	, COUNT(SI_APA.NumFINESS_EG)
	, COUNT(CASE WHEN StatutPeuplement = 'Finalise' THEN peuplement.NumFINESS_EG END)
	, CASE 
		WHEN COUNT(SI_APA.NumFINESS_EG) = 0 THEN 0
		ELSE COUNT(CASE WHEN StatutPeuplement = 'Finalise' THEN peuplement.NumFINESS_EG END) / CAST(COUNT(SI_APA.NumFINESS_EG) AS decimal)
	END
	, CASE WHEN COUNT(SI_APA.NumFINESS_EG) = 0 THEN 0 ELSE MAX(1.0) END
	, COUNT(SI_APA.NumFINESS_EG) - COUNT(CASE WHEN StatutPeuplement = 'Finalise' THEN peuplement.NumFINESS_EG END)
FROM SI_APA
LEFT JOIN DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_EG AS peuplement
	ON SI_APA.NumFINESS_EG = peuplement.NumFINESS_EG
GROUP BY SI_APA.CodeRegion, SI_APA.CodeDepartement
UNION ALL
SELECT 
	CodeRegion
	,CONCAT('2.3e ',Domaine)
	, 'Synchronisation ROR/VT'
	, '2023-2024'
	, NULL
	, NB_EG_PerimetreSynchronisation
	, NB_EG_SynchronisationFinalise
	, DC_TauxSynchronisation
	, DC_ObjectifSEGUR
	, CASE 
		WHEN DC_ObjectifSEGUR IS NULL THEN NULL
		WHEN ROUND(DC_TauxSynchronisation,2) >= ROUND(DC_ObjectifSEGUR,2) THEN 0
		ELSE CEILING((NB_EG_PerimetreSynchronisation * DC_ObjectifSEGUR) - NB_EG_SynchronisationFinalise)
	  END
FROM synchronisationVT
UNION ALL
SELECT 
	CodeRegion
	, '2.3e SI APA'
	, 'Synchronisation ROR/VT'
	, '2023-2024'
	, CodeDepartement
	, SUM(NB_EG_PerimetreROR)
	, SUM(NB_EG_SynchronisationFinalise)
	, CASE 
		WHEN SUM(NB_EG_PerimetreROR) = 0 THEN 0
		ELSE SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreROR) AS decimal)
	END
	, CASE WHEN SUM(NB_EG_PerimetreROR) = 0 THEN 0 ELSE MAX(0.8) END
	, CASE 
		WHEN SUM(NB_EG_PerimetreROR) = 0 THEN NULL
		WHEN ROUND(SUM(NB_EG_SynchronisationFinalise) / CAST(SUM(NB_EG_PerimetreROR) AS decimal),2) >= 0.8 THEN 0
		ELSE CEILING((SUM(NB_EG_PerimetreROR) * 0.8) - SUM(NB_EG_SynchronisationFinalise))
	  END
FROM DATALAB.DLAB_002.T_IND_SynchroRORVT_HISTO
WHERE TypePerimetre = 'SI APA' AND CodeDepartement IN ('07','80','64','65','66') AND DT_Reference = '2023-09-30'
GROUP BY CodeRegion, CodeDepartement