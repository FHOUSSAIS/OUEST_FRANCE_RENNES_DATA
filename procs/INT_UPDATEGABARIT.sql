SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

CREATE PROCEDURE [dbo].[INT_UPDATEGABARIT]
	@v_gbr_idgabarit tinyint,
	@v_gbr_hauteur smallint,
	@v_gbr_largeur smallint,
	@v_gbr_longueur smallint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13

-- Initialisation des variables
	SET @v_transaction = 'UPDATEGABARIT'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	-- Contrôle de l'existence du gabarit
	IF EXISTS (SELECT 1 FROM INT_GABARIT WHERE GBR_IDGABARIT = @v_gbr_idgabarit)
	BEGIN
		UPDATE GABARIT SET GBR_HAUTEUR = @v_gbr_hauteur, GBR_LARGEUR = @v_gbr_largeur, GBR_LONGUEUR = @v_gbr_longueur
			WHERE GBR_ID = @v_gbr_idgabarit
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
	ELSE
		SET @v_retour = @CODE_KO_INEXISTANT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

