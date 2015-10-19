SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_CREATEMISSIONPRISE]
	@v_mis_idmission int out,
	@v_mis_iddemande varchar(20) = NULL,
	@v_mis_priorite int = 0,
	@v_mis_dateecheance datetime = NULL,
	@v_mis_idcharge int = NULL,
	@v_mis_idagv tinyint = NULL,
	@v_mis_idlegende int = NULL,
	@v_mis_decharge bit = 0,
	@v_mis_idtypeagv tinyint = NULL,
	@v_mis_idtypeoutil tinyint = NULL,
	@v_tac_affinage tinyint = 0,
	@v_tac_idsystemeexecution bigint = NULL,
	@v_tac_idbaseexecution bigint = NULL,
	@v_tac_idsousbaseexecution bigint = NULL,
	@v_tac_idsystemeaffinage bigint = NULL,
	@v_tac_idbaseaffinage bigint = NULL,
	@v_tac_idsousbaseaffinage bigint = NULL,
	@v_tac_accesbase bit = NULL,
	@v_tac_idoptionaction tinyint = NULL
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
	@v_status int,
	@v_retour int,
	@v_tac_idtache int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_PRISE smallint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @ACTI_PRISE = 2

-- Initialisation des variables
	SELECT @v_transaction = 'CREATEMISSIONPRISE'
	SELECT @v_error = 0
	SELECT @v_status = @CODE_KO
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	EXEC @v_status = INT_CREATEMISSION @v_mis_idmission out, @v_mis_iddemande, @v_mis_priorite, @v_mis_dateecheance, @v_mis_idcharge, @v_mis_idagv, @v_mis_idlegende, @v_mis_decharge,
		@v_mis_idtypeagv, @v_mis_idtypeoutil
	SELECT @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		EXEC @v_status = INT_ADDTACHEMISSION @v_tac_idtache out, @v_mis_idmission, @v_tac_affinage, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
			@v_tac_idsystemeaffinage, @v_tac_idbaseaffinage, @v_tac_idsousbaseaffinage, @v_tac_accesbase, @v_tac_idaction = @ACTI_PRISE, @v_tac_idoptionaction = @v_tac_idoptionaction
		SELECT @v_error = @@ERROR
		IF @v_status = @CODE_OK AND @v_error = 0
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	END
	ELSE
		SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


