USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_IND_SuiviPeuplementROR AS

/*
Contexte : Vue agregee permettant de calculer les indicateurs de suivi du peuplement
Version de la vue : 1.3
Notes derniere evolution : Remplacement de la source INIT par la table HISTO + correctif sur le calcul de date utilie dans la jointure avec la table HISTO
Sources : 
  - V_DIM_SuiviPeuplementROR_EG
  - T_IND_SuiviPeuplementROR_HISTO
Vue utilisee par :
  - VTEMP_IND_SuiviPeuplementROR_HISTO
  - Traitement d'historisation sur la table V_IND_SuiviPeuplementROR_HISTO
*/


SELECT
	actuel.DT_Reference
	,actuel.Periodicite
	,actuel.CodeRegion
	,actuel.ChampActivite
	,actuel.CodeCategorieEG
	,actuel.LibelleCategorieEG
	,actuel.SecteurEG
	,actuel.TypePerimetre
	,actuel.NB_EG_PerimetreFiness
	,actuel.NB_EG_PeuplementFinalise
	,actuel.NB_EG_PeuplementEnCours
	,actuel.NB_EG_PeuplementAFaire
	-- Si la categorie d'EG n'existait pas dans les chiffres de la periode precedente (aucun etablissement ou perimetre non suivi) alors la valeur de la colonne est NULL
	,CASE 
		WHEN histo.NB_EG_PerimetreFiness is null THEN NULL
		ELSE actuel.NB_EG_PerimetreFiness - histo.NB_EG_PerimetreFiness
	END AS NB_VariationPerimetreFiness
	-- Idem condition precedente
	,CASE 
		WHEN histo.NB_EG_PeuplementFinalise is null THEN NULL
		ELSE actuel.NB_EG_PeuplementFinalise - histo.NB_EG_PeuplementFinalise
	END AS NB_VariationPeuplementFinalise
FROM (
	SELECT
		-- Calcul du trimetre de reference (dernier jour du trimetre) e partir de la date du jour e laquelle la requete tourne
		CAST(DATEADD(q,1,DATEADD(qq, DATEDIFF(qq,0, GETDATE()), 0))-1 as date) AS DT_Reference
		,'trimestre' AS Periodicite
		,CodeRegion
		,ChampActivite
		,CodeCategorieEG
		,LibelleCategorieEG
		,SecteurEG
		,TypePerimetre
		,COUNT(*) AS NB_EG_PerimetreFiness
		,COUNT(CASE WHEN StatutPeuplement = 'Finalise' THEN NumFINESS_EG END) AS NB_EG_PeuplementFinalise
		,COUNT(CASE WHEN StatutPeuplement = 'En cours' THEN NumFINESS_EG END) AS NB_EG_PeuplementEnCours
		,COUNT(CASE WHEN StatutPeuplement = 'A faire' THEN NumFINESS_EG END) AS NB_EG_PeuplementAFaire
	FROM DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_EG
	-- Filtre sur le flag pour recuperer de la table source uniquement le perimetre suivi
	WHERE FG_PerimetreSuiviPeuplement = 1
	GROUP BY CodeRegion
	,ChampActivite
	,CodeCategorieEG
	,LibelleCategorieEG
	,TypePerimetre
	,SecteurEG) AS actuel
-- Jointure avec la table historisee pour calculer les variations entre les periodes
LEFT JOIN DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO AS histo
	ON actuel.CodeRegion = histo.CodeRegion 
	AND actuel.ChampActivite = histo.ChampActivite
	AND actuel.CodeCategorieEG = histo.CodeCategorieEG
	-- Filtre sur le trimestre precedent a celui du jour ou la requete tourne
	AND histo.DT_Reference = CAST(DATEADD(qq, DATEDIFF(qq,0, GETDATE()), 0)-1 AS DATE)