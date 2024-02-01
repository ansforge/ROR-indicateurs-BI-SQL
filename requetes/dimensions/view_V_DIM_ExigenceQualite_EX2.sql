USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ExigenceQualite_EX2 AS 

SELECT
    ID_EntiteGeographique
    ,CodeRegion
	,CASE 
        WHEN Ror.DateFermeture IS NULL THEN 'Ouvert'
		WHEN Ror.CodeNOS_TypeFermeture = 'PRO' THEN 'Fermé provisoirement'
        ELSE 'Fermé définitivement'
    END AS EtatROR
	,Ror.DateFermeture AS DateFermetureROR
	,CASE 
        WHEN Finess.nmfinessetab_stru IS NULL  THEN 'Non rapproché'
        WHEN Finess.cdconstatcaducite_stru = 'O' THEN 'Caduc'
		WHEN Finess.dtfermestruct_stru IS NULL THEN 'Ouvert'
		WHEN Finess.cdtypefermestruct_stru = 'PRO' THEN 'Fermé provisoirement'
		WHEN Finess.dtfermestruct_stru IS NOT NULL THEN 'Fermé définitivement'
    END AS EtatFiness
	,Finess.dtfermestruct_stru AS DateFermetureFiness
    ,CASE 
		WHEN Finess.nmfinessetab_stru IS NULL AND Ror.DateFermeture IS NULL THEN 'Ecart'
		WHEN (Finess.dtfermestruct_stru IS NOT NULL OR Finess.cdconstatcaducite_stru = 'O') 
			AND Ror.DateFermeture IS NULL THEN 'Ecart'
		WHEN Finess.dtfermestruct_stru IS NULL AND Ror.DateFermeture IS NOT NULL THEN 'Ecart'
		WHEN Finess.cdtypefermestruct_stru = 'PRO' AND Ror.CodeNOS_TypeFermeture <> 'PRO' THEN 'Ecart'
		WHEN Finess.cdtypefermestruct_stru = 'DEF' AND Ror.CodeNOS_TypeFermeture <> 'DEF' THEN 'Ecart'
		ELSE 'Conforme' END AS StatutExigence
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique AS Ror
LEFT JOIN BICOEUR_DWH_SNAPSHOT.dbo.dwh_structure AS Finess
	ON Ror.NumFINESS = Finess.nmfinessetab_stru
	AND Finess.topsource_stru = 'FINESS'
	AND Finess.typeidpm_stru = 'EG'
WHERE Ror.NumFINESS IS NOT NULL 
	AND Ror.CodeRegion NOT IN ('-1','-2','-3')