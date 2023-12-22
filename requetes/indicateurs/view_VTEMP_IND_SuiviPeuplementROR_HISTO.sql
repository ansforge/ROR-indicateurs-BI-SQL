USE DATALAB
GO 

CREATE OR ALTER VIEW DLAB_002.VTEMP_IND_SuiviPeuplement_HISTO AS

/*
Description : Vue créée de maniére temporaire pour afficher les indicateurs de peuplement sur le tableau de bord PowerBI. 
Deux régions sont exclues des indicateurs à date car elles n'ont pas validé l'automatisation de leurs statistiques.
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
	,'-2' AS CodeDepartement
	,ChampActivite
	,CodeCategorieEG
	,TypePerimetre
	,SecteurEG
	,NB_EG_PerimetreFiness
	,NB_EG_PeuplementFinalise
	,NB_EG_PeuplementEnCours
	,NB_EG_PeuplementAFaire
	,DT_UPDATE_TECH
FROM DATALAB.DLAB_002.T_IND_SuiviPeuplementROR_HISTO
-- Récupération uniquement des précédents trimestres. Le trimestre en cours est calculé dans la 2nde partie de la requete.
WHERE DT_Reference <= CAST(DATEADD(qq, DATEDIFF(qq,0, GETDATE()), 0)-1 AS DATE)
UNION ALL
SELECT
	DT_Reference
	,Periodicite
	,CodeRegion
	,CodeDepartement
	,ChampActivite
	,ISNULL(CodeCategorieEG,'-1') AS CodeCategorieEG
	,TypePerimetre
	,SecteurEG
	,NB_EG_PerimetreFiness
	,NB_EG_PeuplementFinalise
	,NB_EG_PeuplementEnCours
	,NB_EG_PeuplementAFaire
	,GETDATE() AS DT_UPDATE_TECH
FROM DATALAB.DLAB_002.V_IND_SuiviPeuplementROR
WHERE CodeRegion in ('01','03','04','06','11','24','27','28','32','44','52','53','76','84','93','94')