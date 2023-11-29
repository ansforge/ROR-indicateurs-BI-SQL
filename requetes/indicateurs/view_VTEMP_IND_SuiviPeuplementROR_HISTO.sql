USE DATALAB
GO 

CREATE OR ALTER VIEW DLAB_002.VTEMP_IND_SuiviPeuplement_HISTO AS

/*
Contexte : Indicateurs de suivi du peuplement. Cette vue a été créée de maniére temporaire pour récupérer les données historiques dans un seul endroit, 
elle sera remplacée par la table d'historisation en cours de fiabilisation par Umanis.
Version : 1.8
Notes derniére évolution : Suppression des ajoutes manuels sur la région Nouvelle-Aquitaine à la suite de l'enregistrement manuel des statistiques dans la table HISTO
Sources : 
  - T_IND_SuiviPeuplementROR_HISTO
  - V_IND_SuiviPeuplementROR
Vue utilisée par :
  - PowerBI tableau de bord Suivi du Peuplement
*/

SELECT 
	DT_Reference
	,Periodicite
	,CodeRegion
	,ChampActivite
	,CodeCategorieEG
	,LibelleCategorieEG
	,TypePerimetre
	,SecteurEG
	,NB_EG_PerimetreFiness
	,NB_EG_PeuplementFinalise
	,NB_EG_PeuplementEnCours
	,NB_EG_PeuplementAFaire
	,DT_UPDATE_TECH
FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
-- Récupération uniquement des précédents trimestres. Le trimestre en cours est calculé dans la 2nde partie de la requete.
WHERE DT_Reference < '2023-10-01'
UNION ALL
SELECT
DT_Reference
	,Periodicite
	,CodeRegion
	,ChampActivite
	,ISNULL(CodeCategorieEG,'-1') AS CodeCategorieEG
	,LibelleCategorieEG
	,TypePerimetre
	,SecteurEG
	,NB_EG_PerimetreFiness
	,NB_EG_PeuplementFinalise
	,NB_EG_PeuplementEnCours
	,NB_EG_PeuplementAFaire
	,GETDATE() AS DT_UPDATE_TECH
FROM DATALAB.DLAB_002.V_IND_SuiviPeuplementROR
WHERE CodeRegion in ('01','03','04','06','11','24','27','28','32','44','52','53','76','84','93','94')