SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE  PROCEDURE [dbo].[INT_SETPARAMETRE]
	@v_par_idparametre varchar(16),
	@v_par_valeur varchar(128)
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
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INCONNU = 7
	SELECT @CODE_KO_SQL = 13

-- Initialisation des variables
	SELECT @v_transaction = 'SETPARAMETRE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence du paramètre
	IF EXISTS (SELECT 1 FROM INT_PARAMETRE WHERE PAR_IDPARAMETRE = @v_par_idparametre)
	BEGIN
		UPDATE PARAMETRE SET PAR_VAL = @v_par_valeur WHERE PAR_NOM = @v_par_idparametre
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @CODE_KO_SQL
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INCONNU
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


