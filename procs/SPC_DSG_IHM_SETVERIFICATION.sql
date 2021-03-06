SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion des verification de stock
-- @v_AdrSys
-- @v_AdrBase
-- @v_AdrSsBase : Clé d'adressage
-- @v_Verification : 0 ne pas vérifier / 1 à verifier
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DSG_IHM_SETVERIFICATION]
	@v_AdrSys BIGINT,
	@v_AdrBase BIGINT,
	@v_AdrSsBase BIGINT,
	@v_Verification BIT
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODEERR_PASPERMIS INT,
		@CODEERR_USED_REORGASTOCK INT,
		@CODE_OK INT,
		@ETATDMD_NEW TINYINT,
		@ETATDMD_ACCEPT TINYINT,
		@ETATTAC_ENATTENTE TINYINT,
		@ETATTAC_ENCOURS TINYINT,
		@CODEERR_USED_MISSION INT

-- Déclaration de variables
DECLARE @Retour INT,
		@ChaineTrace VARCHAR(500)

-- Initialisation des constantes
SET @CODEERR_PASPERMIS = -1710
SET @CODEERR_USED_REORGASTOCK = -1724
SET @CODEERR_USED_MISSION = -1725
SET @CODE_OK = 0

SET @ETATTAC_ENATTENTE = 1
SET @ETATTAC_ENCOURS = 2

-- Initialisation des variables
SET @Retour = @CODE_OK

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC @Retour = INT_SETVERIFICATIONADRESSE @v_AdrSys, @v_AdrBase, @v_AdrSsBase, @v_Verification

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		SET @ChaineTrace = 'Modification Vérification Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_AdrSys AND ADR_IDBASE=@v_AdrBase AND ADR_IDSOUSBASE=@v_AdrSsBase)+
					', Vérif='+CONVERT(VARCHAR,@v_Verification)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END

RETURN @Retour
END

