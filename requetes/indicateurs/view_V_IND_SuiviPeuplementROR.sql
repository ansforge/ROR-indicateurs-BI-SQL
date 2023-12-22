USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_IND_SuiviPeuplementROR AS

/*
Description : Vue d'agregation permettant de calculer les indicateurs de suivi du peuplement
Sources : 
  - V_DIM_SuiviPeuplementROR_EG
Vue utilisee par :
  - VTEMP_IND_SuiviPeuplementROR_HISTO
  - Traitement d'historisation sur la table T_IND_SuiviPeuplementROR_HISTO
*/

SELECT
	-- Calcul du trimetre de reference (dernier jour du trimetre) a partir de la date du jour
	CAST(DATEADD(q,1,DATEADD(qq, DATEDIFF(qq,0, GETDATE()), 0))-1 as date) AS DT_Reference
	,'trimestre' AS Periodicite
	,CodeRegion
	,CodeDepartement
	,ChampActivite
	,CodeCategorieEG
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
,CodeDepartement
,ChampActivite
,CodeCategorieEG
,TypePerimetre
,SecteurEG