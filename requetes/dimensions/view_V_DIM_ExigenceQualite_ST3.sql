USE DATALAB
GO
CREATE OR ALTER VIEW V_DIM_ExigenceQualite_ST3 AS

WITH base AS (
SELECT 
	ID_EntiteJuridique AS ID_Structure
	,'EJ' AS TypeStructure
	,CodeRegion
	,CASE
		WHEN CodeRegion IN ('01','02','03','04','06') THEN CONCAT('97',RIGHT(CodeRegion,1))
		WHEN CodeRegion IN ('94') THEN '-2'
		ELSE LEFT(Adresse_CodePostal,2) 
	END AS CodeDepartement
	,IdNat_Struct
	,NumFINESS
	,NumSIREN AS NumSIREN_SIRET
	,NumEJ_RPPS_ADELI_Rang AS Num_RPPS_ADELI_Rang
	,RaisonSociale AS NomStructure
	,NULL AS CodeNOS_CategorieEG
	,DateCreation
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteJuridique
WHERE DateFermeture IS NULL AND RIGHT(UniqueID,3) != 'ejv'
UNION ALL
SELECT 
	ID_EntiteGeographique
	,'EG'
	,EntiteGeographique.CodeRegion
	,CASE WHEN EntiteGeographique.CodeRegion IN ('01','02','03','04','06') THEN LEFT(Lieu.CodeNOS_CommuneCog,3) ELSE LEFT(Lieu.CodeNOS_CommuneCog,2) END
	,IdNat_Struct
	,NumFINESS
	,NumSIRET
	,NumEG_RPPS_ADELI_Rang
	,DenominationEG
	,CodeNOS_CategorieEG
	,DateOuverture
FROM BIROR_DWH_SNAPSHOT.dbo.T_DIM_EntiteGeographique as EntiteGeographique
LEFT JOIN BIROR_DWH_SNAPSHOT.dbo.T_DIM_Lieu AS Lieu
	ON Lieu.FK_StructureParente = EntiteGeographique.ID_EntiteGeographique AND Lieu.TypeAppartenance = 'EG'
WHERE DateFermeture IS NULL AND CodeNOS_CategorieEG NOT IN ('SA05','SA07','SA08','SA09')
)

SELECT
	ID_Structure
	,CodeRegion
	,CodeDepartement
	,TypeStructure
	,IdNat_Struct
	,NumFINESS
	,NumSIREN_SIRET
	,Num_RPPS_ADELI_Rang
	,NomStructure
	,CodeNOS_CategorieEG
	,DateCreation
	,COUNT(*) OVER(PARTITION BY IdNat_Struct, CodeRegion) - 1 AS NB_Doublon
    , CASE 
        WHEN COUNT(*) OVER(PARTITION BY IdNat_Struct, CodeRegion) = 1 THEN 'Conforme' 
		ELSE 'Ecart'
    END AS StatutExigence
FROM base