SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion des autorisations de prise / dépose du stock
--				=> Permet de gérer les mises en exploitation successives des allées de stock
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DSG_IHM_SETAUTORISATION]
	@v_AdrSys BIGINT,
	@v_AdrBase BIGINT,
	@v_AdrSsBase BIGINT,
	@v_AutPrise BIT,
	@v_AutDepose BIT
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

SET @ETATDMD_NEW = 0
SET @ETATDMD_ACCEPT = 1

SET @ETATTAC_ENATTENTE = 1
SET @ETATTAC_ENCOURS = 2

-- Initialisation des variables
SET @Retour = @CODE_OK

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Vérification si l'allée est utilisée en origine ou demande réorga non suspendue
IF @Retour = @CODE_OK 
	AND (@v_AutPrise = 0 OR @v_AutDepose = 0)
	AND EXISTS (SELECT 1 FROM SPC_DMD_REORGA_STOCK_GENERAL
					WHERE ((SDG_IDSYSTEME_PRISE = @v_AdrSys AND SDG_IDBASE_PRISE = @v_AdrBase AND SDG_IDSOUSBASE_PRISE = @v_AdrSsBase) 
							OR (SDG_IDSYSTEME_DEPOSE = @v_AdrSys AND SDG_IDBASE_DEPOSE = @v_AdrBase AND SDG_IDSOUSBASE_DEPOSE = @v_AdrSsBase))
							AND SDG_ETAT IN (@ETATDMD_NEW, @ETATDMD_ACCEPT))
BEGIN
	SET @Retour = @CODEERR_USED_REORGASTOCK
END

-- Vérification si l'allée n'est pas une destination de mission
IF @Retour = @CODE_OK 
	AND (@v_AutPrise = 0 OR @v_AutDepose = 0)
	AND EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDSYSTEMEEXECUTION = @v_AdrSys AND TAC_IDBASEEXECUTION = @v_AdrBase AND TAC_IDSOUSBASEEXECUTION = @v_AdrSsBase
							AND ((TAC_IDACTION = 4 AND TAC_IDETATTACHE IN (@ETATTAC_ENATTENTE, @ETATTAC_ENCOURS))
								 OR (TAC_IDACTION = 2 AND TAC_IDETATTACHE = @ETATTAC_ENCOURS)))
BEGIN
	SET @Retour = @CODEERR_USED_MISSION
END


IF @Retour = @CODE_OK 
BEGIN
	EXEC @Retour = INT_SETAUTORISATIONADRESSE 0, @v_AdrSys, @v_AdrBase,
						@v_AdrSsBase, NULL, @v_AutPrise, @v_AutDepose
END			

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		SET @ChaineTrace = 'Modification Autorisation Prise / Dépose Allée ' + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_AdrSys AND ADR_IDBASE=@v_AdrBase AND ADR_IDSOUSBASE=@v_AdrSsBase)+
					', AutPrise='+CONVERT(VARCHAR,@v_AutPrise)+', AutDepose='+CONVERT(VARCHAR,@v_AutDepose)					
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END

RETURN @Retour
END

