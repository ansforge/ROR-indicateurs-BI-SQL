USE DATALAB
GO
CREATE OR ALTER VIEW DLAB_002.V_REF_Departement AS

SELECT
	ID_Departement
	,AK_Departement
	,TX_LibelleDepartement
	,FK_RegionInsee
	,TX_CodeSVGDepartement
FROM COMMUN_DWH.dbo.T_REF_Departement
INNER JOIN DATALAB.DLAB_002.V_REF_Region
	ON T_REF_Departement.FK_RegionInsee = V_REF_Region.Id_Region