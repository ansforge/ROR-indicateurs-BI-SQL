USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_REF_Region AS

SELECT
	ID_Region
	,AK_RegionInsee
	,TX_LibelleRegion
	,TX_CodeSVGRegion
FROM COMMUN_DWH.dbo.T_REF_Region
WHERE AK_RegionInsee in ('01','02','03','04','06','11','24','27','28','32','44','52','53','75','76','84','93','94')
UNION ALL
SELECT
	'0'
	,'00'
	,'National'
	,'0'