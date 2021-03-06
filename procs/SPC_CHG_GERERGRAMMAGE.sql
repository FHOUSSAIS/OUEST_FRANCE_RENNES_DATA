SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Configuration du sens d'enroulement
	-- @p_IdGrammage		: Grammage
	-- @p_CodeGrammage		: CODE IFRA
	-- @p_LibelleGrammage	: Libellé 
	-- @p_CodeAction		: Action (Création/Modification/Suppression)
-- =============================================
CREATE PROCEDURE [dbo].[SPC_CHG_GERERGRAMMAGE]
	@p_IdGrammage TINYINT = NULL,
	@p_CodeGrammage VARCHAR(6),
	@p_LibelleGrammage VARCHAR(50),
	@p_CodeAction TINYINT -- 1 = Création, 2 = Suppression
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODE_OK INT = 0
DECLARE @PROCSTOCK VARCHAR(128) = 'SPC_CHG_GERERGRAMMAGE',
		@MONITOR VARCHAR(128) = 'Gest.IHM'
DECLARE @ACTION_CREATION	TINYINT = 1,
		@ACTION_SUPPRESSION TINYINT = 2		
DECLARE @CODE_KO_GRAMMAGE_IFRA		INT = -6735, -- Suppression Interdite : Grammage IFRA	
		@CODE_KO_GRAMMAGEEXISTANT	INT = -6736, -- Création Interdite : Grammage Existant	
		@CODE_KO_GRAMMAGE_UTILISE	INT = -6737 -- Suppression Interdite : Bobines restantes en Stock sur ce code grammage

-- Déclaration des variables 
DECLARE @Retour INT = @CODE_OK
DECLARE @ChaineTrace VARCHAR(500)

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Si Création d'un grammage
IF @p_CodeAction = @ACTION_CREATION
BEGIN
	-- Vérification si le grammage existe déjà
	IF EXISTS (SELECT 1 FROM SPC_CHG_GRAMMAGE
					WHERE SCG_CODE = @p_CodeGrammage
						AND SCG_GRAMMAGE >= 100)
	BEGIN
		SET @Retour = @CODE_KO_GRAMMAGEEXISTANT
	END
	
	-- Création du nouveau grammage
	IF @Retour = @CODE_OK
	BEGIN
		-- recherche dernier IdGrammage
		SELECT @p_IdGrammage = MAX(SCG_GRAMMAGE) FROM SPC_CHG_GRAMMAGE
		IF @p_IdGrammage < 100
			SET @p_IdGrammage = 100
		ELSE
			SET @p_IdGrammage = @p_IdGrammage + 1
			
		INSERT INTO SPC_CHG_GRAMMAGE
			(SCG_GRAMMAGE, SCG_IDTRADUCTION, SCG_CODE)
			VALUES (@p_IdGrammage, @p_LibelleGrammage, @p_CodeGrammage)
		SET @Retour = @@ERROR
		
		SET @ChaineTrace = @PROCSTOCK + ' : Création Grammage = @p_IdGrammage' + CONVERT(varchar,ISNULL(@p_IdGrammage,-1))
		EXEC INT_ADDTRACESPECIFIQUE @MONITOR, 'SUIVI', @ChaineTrace
	END
END

-- Si Suppression d'un grammage
IF @p_CodeAction = @ACTION_SUPPRESSION
BEGIN
	-- On ne peut pas supprimer les codes IFRA, uniquement les codes créées manuellement
	IF @p_IdGrammage < 100
	BEGIN
		SET @Retour = @CODE_KO_GRAMMAGE_IFRA
	END
	
	-- Pas de suppression possible si des bobines sont rattachées à ce code
	IF @Retour = @CODE_OK
		AND EXISTS (SELECT 1 FROM SPC_CHARGE_BOBINE WHERE SCB_GRAMMAGE = @p_IdGrammage)
	BEGIN
		SET @Retour = @CODE_KO_GRAMMAGE_UTILISE
	END
	
	-- Suppression du code grammage
	IF @Retour = @CODE_OK
	BEGIN
		DELETE FROM SPC_CHG_GRAMMAGE
			WHERE SCG_GRAMMAGE = @p_IdGrammage
		SET @Retour = @@ERROR
		
		SET @ChaineTrace = @PROCSTOCK + ' : Suppression @p_IdGrammage=' + CONVERT(varchar,ISNULL(@p_IdGrammage,-1))
		EXEC INT_ADDTRACESPECIFIQUE @MONITOR, 'SUIVI', @ChaineTrace
	END
END

RETURN @Retour
END

