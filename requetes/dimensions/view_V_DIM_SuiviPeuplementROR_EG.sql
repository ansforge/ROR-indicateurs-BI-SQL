USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_DIM_SuiviPeuplementROR_EG AS

/*
Contexte : Vue permettant de calculer le suivi du peuplement au niveau Entité Géographique (établissement)
Version de la vue : 1.4
Notes de la dernière évolution : modification de la jointure avec la vue V_DIM_SuiviPeuplementROR_UE pour gérer les cas où la catégorie EG n'est pas renseignée
Sources : 
  - V_DIM_CiblePeuplementROR_EG (DATALAB)
  - V_DIM_SuiviPeuplementROR_UE (DATALAB)
  - T_DIM_EntiteGeographique (BIROR_DWH)
  - T_REF_NOS (BIROR_DWH)
Vue utilisée par :
  - V_IND_SuiviPeuplementROR (DATALAB)
  - Suivi_Peuplement_VFD (PowerBI)
*/

SELECT
	ISNULL(finess.CodeRegion,ror.CodeRegion) AS CodeRegion
	,ISNULL(finess.NumFINESS_EG,ror.NumFINESS) AS NumFINESS_EG
	,finess.DT_OuvertureEG_FINESS
	,finess.DenominationEG_FINESS
	,ror.UniqueID AS IdentifiantTechniqueROR
	,ror.DenominationEG AS DenominationEG_ROR
	,ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) AS CodeCategorieEG
	,NOS_categ.Libelle AS LibelleCategorieEG
	,CASE 
		WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) in ('101','106','109','114','122','127','128','129','131','141','146','156','161','292','355','362',
		'365','366','412','415','425','430','444','696','697','698')
			THEN 'Sanitaire'
		WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) in ('178',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',	'195',	'196',	'197',	'198',	
		'202',	'207',	'209',	'221',	'228','238',	'246',	'249',	'252',	'253',	'255',	'354',	'370',	'377',	'379',	'381',	'382',	'390',	'395',	'396',	'402',
		'437',	'445',	'446',	'448',	'449','460',	'500',	'501',	'502')
			THEN 'Medico-social'
		WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) in ('604','606') 
			THEN 'Coordination'
		WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) in ('603') 
			THEN 'Offre de ville'
		ELSE 'Autre'
	END AS SecteurEG
    -- Redéfinition du champ d'activité pour les EG hors Finess possédant une catégorie EG
    ,CASE
        WHEN finess.ChampActivite IS NOT NULL THEN finess.ChampActivite
        WHEN ror.CodeNOS_CategorieEG IN ('202','207','381','500','501','502') THEN 'PA'
        WHEN ror.CodeNOS_CategorieEG IN ('182','183','186','188','189','190','192','194'
        ,'195','196','198','221','238','246','249','252','253','255','370','377','379'
        ,'382','390','395','396','402','437','445','446','448','449') THEN 'PH'
        WHEN ror.CodeNOS_CategorieEG IN ('209','354','460') THEN 'Services PAPH'
        WHEN ror.CodeNOS_CategorieEG IN ('178','197','228') THEN 'Autres MS'
        WHEN ror.CodeNOS_CategorieEG IN ('604','606') THEN 'Coordination'
        WHEN ror.CodeNOS_CategorieEG IN ('603') THEN 'Ville'
        -- Récupération des champs d'activité véhiculés au niveau des unités qui ne sont identifiés par la classification faite dans FINESS ou lorsque les 
        ELSE peuplement.ChampActivite
     END AS ChampActivite
	,finess.CodeDepartement
	,finess.LibelleDepartement
	,CASE WHEN finess.NumFINESS_EG is not null THEN 1 ELSE 0 END AS FG_PerimetreSuiviPeuplement
	,ISNULL(finess.TypePerimetre,'Non suivi') AS TypePerimetre
	,CASE 
		WHEN peuplement.NB_UE > 0 AND peuplement.NB_UE_PeuplementFinalise = peuplement.NB_UE THEN 'Finalise'
		WHEN peuplement.NB_UE > 0 AND peuplement.NB_UE_PeuplementEnCours > 0 THEN 'En cours'
		ELSE 'A faire'
	END AS StatutPeuplement
	,CASE 
		WHEN ror.UniqueID is null THEN NULL
		ELSE ISNULL(peuplement.NB_UE,0)
	END AS NB_UE
	,CASE
		WHEN ror.UniqueID is null THEN NULL
		ELSE ISNULL(peuplement.NB_UE_PeuplementFinalise,0)
	END AS NB_UE_PeuplementFinalise
	,CASE
		WHEN ror.UniqueID is null THEN NULL
		ELSE ISNULL(peuplement.NB_UE_PeuplementEnCours,0)
	END AS NB_UE_PeuplementEnCours
FROM DATALAB.DLAB_002.V_DIM_CiblePeuplementROR_EG as finess
-- Le Full join permet de récupérer le peuplement des champ d'activités autres que ceux définis à partir de la catégorie EG
FULL OUTER JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique as ror
	ON ror.NumFINESS = finess.NumFINESS_EG
FULL OUTER JOIN (
	SELECT
		FK_EntiteGeographique
		,ChampActivite
		,COUNT(ID_OrganisationInterne) as NB_UE
		,SUM(FG_PeuplementFinalise) as NB_UE_PeuplementFinalise
		,SUM(FG_PeuplementEncours) as NB_UE_PeuplementEnCours
	FROM DATALAB.DLAB_002.V_DIM_SuiviPeuplementROR_UE
	GROUP BY FK_EntiteGeographique,ChampActivite) AS peuplement 
	ON peuplement.FK_EntiteGeographique = ror.ID_EntiteGeographique
	AND (
    -- Gestion des unités MS qui ne sont pas distinguées au même niveau que celui fait pour calculer le périmètre cible de peuplement
        (CASE 
            WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) IN (
            '178',	'182',	'183',	'186',	'188',	'189',	'190',	'192',	'194',
            '195',	'196',	'197',	'198',	'202',	'207',	'209',	'221',	'228',
            '238',	'246',	'249',	'252',	'253',	'255',	'354',	'370',	'377',
            '379',	'381',	'382',	'390',	'395',	'396',	'402','437',
            '445',	'446',	'448',	'449','460',	'500',	'501',	'502') 
            THEN 'MS'
            ELSE finess.ChampActivite END) = 
    -- Gestion des unités pour les catégories EG du nouveau périmètre pour lesquelles les champs d'activités des unités sont différents
        (CASE 
            WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) IN (
            '604','606') THEN 'Coordination'
            WHEN ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) IN (
            '603') THEN 'Ville'
            ELSE peuplement.ChampActivite END)
    -- Permet aussi de gérer les cas où il n'y a pas de champ d'activité finess car l'établissement n'a pas de finess
        OR finess.ChampActivite is null
	-- Permet de gérer les cas où il n'y a pas de champ d'activité dans le ROR (aucune unité n'a été décrite) mais que l'établissement a bien été créé
        OR peuplement.ChampActivite is null)
	-- Jointure avec la NOS JDV_J55-CategorieEG-ROR pour les cas où la catégorie EG est différente ou n'existe pas dans le ROR. Dans ce cas pas de rapprochement FK_NOS possible
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_REF_NOS as NOS_categ
	ON ISNULL(finess.CodeCategorieEG, ror.CodeNOS_CategorieEG) = NOS_categ.Code AND NOS_categ.Nomenclature_OID = '1.2.250.1.213.3.3.65'