USE DATALAB
GO

CREATE OR ALTER VIEW DLAB_002.V_DIM_ExigenceQualite_RE1_2 AS

WITH DateMAJ_OrganisationInterne AS (
	SELECT
		ID_OrganisationInterne
		,Meta_DateMiseJour
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne
	UNION ALL
	SELECT
		FK_StructureParente
		,MAX(Meta_DateMiseJour)
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Contact
	WHERE TypeParent = 'OI'
	GROUP BY FK_StructureParente
	UNION ALL 
	SELECT
		FK_StructureParente
		,MAX(Meta_DateMiseJour)
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_Telecommunication
	WHERE TypeParent = 'OI'
	GROUP BY FK_StructureParente
)

, Offre AS (
	SELECT 
		Offre.ID_OrganisationInterne
		,FK_EntiteGeographique
		,MAX(DateMAJ_OrganisationInterne.Meta_DateMiseJour) AS MaxDateMiseJour
	FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne AS Offre
	INNER JOIN DateMAJ_OrganisationInterne
	ON Offre.ID_OrganisationInterne = DateMAJ_OrganisationInterne.ID_OrganisationInterne
	WHERE DateFermetureDefinitive IS NULL AND CodeNOS_TypeOI = '4'
	GROUP BY Offre.ID_OrganisationInterne, FK_EntiteGeographique
)

SELECT
	ID_EntiteGeographique
    ,CodeRegion
    ,FORMAT(EntiteGeographique.Meta_DateMiseJour,'yyyy-MM-dd HH\:mm') AS DateMAJ_EG
	,FORMAT(MAX(Offre.MaxDateMiseJour),'yyyy-MM-dd HH\:mm') AS DateDerniereMAJ_Offre
	,DATEADD(year, -1, CAST(DT_UPDATE_TECH as date)) AS DateLimiteConformite
	,CASE 
		WHEN COUNT(ID_OrganisationInterne) = 0 THEN 0
		WHEN COUNT(ID_OrganisationInterne) < 8 THEN 1
		ELSE CAST(ROUND(COUNT(ID_OrganisationInterne) * 0.25,0) AS INT)
	END AS NB_Offre_MajPourConformiteExigence
	,COUNT(CASE WHEN Offre.MaxDateMiseJour > DATEADD(year, -1, CAST(DT_UPDATE_TECH as date)) THEN ID_OrganisationInterne END) AS NB_Offre_MajConforme
	,CASE 
		WHEN COUNT(ID_OrganisationInterne) < 8 THEN NULL
		ELSE ROUND(COUNT(CASE 
						WHEN Offre.MaxDateMiseJour > DATEADD(year, -1, CAST(DT_UPDATE_TECH as date)) 
						THEN ID_OrganisationInterne
						END) / CAST(COUNT(ID_OrganisationInterne) AS DECIMAL),2)
	 END AS TX_Offre_MajConforme
	,CASE 
		WHEN COUNT(ID_OrganisationInterne) = 0 THEN 'Conforme'
		WHEN COUNT(ID_OrganisationInterne) < 8 
		    AND COUNT(CASE 
                WHEN Offre.MaxDateMiseJour > DATEADD(year, -1, CAST(DT_UPDATE_TECH as date)) 
                THEN ID_OrganisationInterne END) >= 1 THEN 'Conforme'
		WHEN ROUND(COUNT(CASE 
						WHEN Offre.MaxDateMiseJour > DATEADD(year, -1, CAST(DT_UPDATE_TECH as date)) 
						THEN ID_OrganisationInterne 
						END) / CAST(COUNT(ID_OrganisationInterne) AS DECIMAL),2) >= 0.25 THEN 'Conforme'
		ELSE 'Ecart'
	END AS StatutExigence
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS EntiteGeographique
LEFT JOIN Offre
	ON EntiteGeographique.ID_EntiteGeographique = Offre.FK_EntiteGeographique
WHERE DateFermeture IS NULL 
	AND (CodeNOS_CategorieEG IS NULL OR CodeNOS_CategorieEG NOT IN ('SA05','SA07','SA08','SA09'))
GROUP BY ID_EntiteGeographique
    ,CodeRegion
	,EntiteGeographique.Meta_DateMiseJour
	,DT_UPDATE_TECH