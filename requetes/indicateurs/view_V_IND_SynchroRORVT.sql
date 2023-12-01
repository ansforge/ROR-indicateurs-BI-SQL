USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_IND_SynchroRORVT AS

/*
Contexte : Indicateurs de synchronisation ROR-VT calculés par Domaine et Code Region à partir de la liste détaillée des établissements transmis par VT
Version : 2.0
Notes de la derniere evolution : Modification de la structure de table et ajout des données SI APA
Sources de données : 
 - T_DIM_ImportSynchroROR_VT (DATALAB)
 - V_DIM_SynchroRORVT (DATALAB)
 - T_IND_SuiviPeuplementROR_HISTO (DATALAB)
Vue utilisée par : 
 - VTEMP_IND_SynchroRORVT_HISTO (DATALAB)
Evolutions à venir : Les sources utilisées ont pour vocation à évoluer lorsque la vue aura été historisée (cf. commentaires)
*/


WITH PerimetreVT AS (
	SELECT
		CodeRegion
		,CodeDepartement
		,DomaineVT
		,TypePerimetre
		,CodeCategorieEG_Finess
		,COUNT(DISTINCT Finess) AS NB_EG_PerimetreVT
		,COUNT(DISTINCT CASE WHEN EtatSynchronisationROR = 'Mise à jour de l’offre active' THEN Finess END) AS NB_EG_SynchronisationFinalise
		,DT_MAJ_Fichier
	FROM DATALAB.DLAB_002.V_DIM_SynchroRORVT
	-- Identification de la date de mise à jour du fichier à partir de la dernière date de synchronisation disponible
	WHERE 
		(EtatVT IS NULL OR EtatVT <> 'Fermeture définitive')
		AND (EtatFiness IS NULL OR EtatFiness NOT IN ('Fermeture définitive'))
		AND TypePerimetre <> 'Domicile'
	GROUP BY CodeRegion, CodeDepartement, DomaineVT, TypePerimetre, CodeCategorieEG_Finess, DT_MAJ_Fichier
)

, PerimetreROR AS (
	SELECT 
		CodeRegion
		,CodeDepartement
		,CodeCategorieEG_FINESS
		,COUNT(NumFINESS_EG) AS NB_EG
	FROM DATALAB.DLAB_002.V_DIM_AutorisationFINESS AS Finess
	INNER JOIN DATALAB.DLAB_002.V_REF_J55_CategorieEG AS CategorieEG_NOS
		ON Finess.CodeCategorieEG_FINESS = CategorieEG_NOS.Code
	WHERE CategorieEG_NOS.TypePerimetreROR != 'Non suivi'
	GROUP BY CodeRegion, CodeDepartement ,CodeCategorieEG_FINESS
)

SELECT
	CAST(DATEADD(q,1,DATEADD(qq, DATEDIFF(qq,0, DT_MAJ_Fichier), 0))-1 as date) AS DT_Reference
	,'trimestre' AS Periodicite
	,PerimetreVT.CodeRegion
	,PerimetreVT.CodeDepartement
	,PerimetreVT.DomaineVT
	,PerimetreVT.TypePerimetre
	,PerimetreVT.CodeCategorieEG_Finess
	,ISNULL(PerimetreROR.NB_EG,0) AS Nb_EG_PerimetreROR
	,PerimetreVT.NB_EG_PerimetreVT
	,PerimetreVT.NB_EG_SynchronisationFinalise
	,PerimetreVT.DT_MAJ_Fichier
FROM PerimetreVT
LEFT JOIN PerimetreROR
	ON PerimetreVT.CodeRegion = PerimetreROR.CodeRegion
	AND PerimetreVT.CodeDepartement = PerimetreROR.CodeDepartement
	AND PerimetreVT.CodeCategorieEG_Finess = PerimetreROR.CodeCategorieEG_FINESS
UNION ALL
SELECT
	CAST(DATEADD(q,1,DATEADD(qq, DATEDIFF(qq,0, DT_MAJ_Fichier), 0))-1 as date) AS DT_Reference
	,'trimestre' AS Periodicite
	,CodeRegion
	,CodeDepartement
	,'-3'
	,TypePerimetre
	,CodeCategorieEG_Finess
	,COUNT(DISTINCT Finess) AS NB_EG_PerimetreROR
	,COUNT(DISTINCT CASE WHEN EtatVT IS NOT NULL THEN Finess END) AS NB_EG_PerimetreVT
	,COUNT(DISTINCT CASE WHEN EtatSynchronisationROR = 'Mise à jour de l’offre active' THEN Finess END) AS NB_EG_SynchronisationFinalise
	,DT_MAJ_Fichier
FROM DATALAB.DLAB_002.V_DIM_SynchroRORVT
WHERE TypePerimetre = 'Domicile'
GROUP BY CodeRegion, CodeDepartement, TypePerimetre, CodeCategorieEG_Finess, DT_MAJ_Fichier