USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ChargementBIROR AS
SELECT 
	CodeRegion
	,MAX(DT_UPDATE_TECH) AS DT_UPDATE_TECH
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_OrganisationInterne
WHERE CodeRegion not in ('-1','-2','-3')
GROUP BY CodeRegion