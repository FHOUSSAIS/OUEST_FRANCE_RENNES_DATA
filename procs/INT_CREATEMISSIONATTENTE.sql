SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_CREATEMISSIONATTENTE]
	@v_mis_idmission int out,
	@v_mis_idagv tinyint,
	@v_tac_idsysteme bigint,
	@v_tac_idbase bigint,
	@v_tac_idsousbase bigint,
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
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_INCORRECT tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_ATTENTE smallint
	
-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_MOUVEMENT tinyint
	
-- Déclaration des constantes d'états de missions
DECLARE
	@ETAT_ENATTENTE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_INCORRECT = 11
	SET @ACTI_ATTENTE = 1
	SET @TYPE_MOUVEMENT = 3
	SET @ETAT_ENATTENTE = 1

-- Initialisation des variables
	SET @v_transaction = 'CREATEMISSIONATTENTE'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO
	SET @v_mis_idmission = NULL

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	IF @v_mis_idagv IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE LEFT OUTER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
			WHERE MIS_IDTYPEMISSION = @TYPE_MOUVEMENT AND MIS_IDAGV = @v_mis_idagv AND TAC_IDACTION = @ACTI_ATTENTE
			AND TAC_IDSYSTEMEEXECUTION = @v_tac_idsysteme AND TAC_IDBASEEXECUTION = @v_tac_idbase AND TAC_IDSOUSBASEEXECUTION = @v_tac_idsousbase)
			AND NOT EXISTS (SELECT 1 FROM INT_AGV WHERE IAG_IDAGV = @v_mis_idagv AND IAG_IDBASEDESTINATION = @v_tac_idbase)
		BEGIN
			EXEC @v_status = INT_CREATEMISSION @v_mis_idmission = @v_mis_idmission out, @v_mis_idagv = @v_mis_idagv
			SET @v_error = @@ERROR
			IF @v_status = @CODE_OK AND @v_error = 0
			BEGIN
				EXEC @v_status = INT_ADDTACHEMISSION @v_tac_idtache out, @v_mis_idmission, @v_tac_idsystemeexecution = @v_tac_idsysteme, @v_tac_idbaseexecution = @v_tac_idbase, @v_tac_idsousbaseexecution = @v_tac_idsousbase,
					@v_tac_idaction = @ACTI_ATTENTE, @v_tac_idoptionaction = @v_tac_idoptionaction
				SET @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
			END
			ELSE
				SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
		END
		ELSE
		BEGIN
			SELECT @v_mis_idmission = MIS_IDMISSION FROM INT_MISSION_VIVANTE LEFT OUTER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
				WHERE MIS_IDTYPEMISSION = @TYPE_MOUVEMENT AND MIS_IDAGV = @v_mis_idagv AND TAC_IDACTION = @ACTI_ATTENTE AND TAC_IDETATTACHE = @ETAT_ENATTENTE
				AND TAC_IDSYSTEMEEXECUTION = @v_tac_idsysteme AND TAC_IDBASEEXECUTION = @v_tac_idbase AND TAC_IDSOUSBASEEXECUTION = @v_tac_idsousbase
			IF @v_mis_idmission IS NOT NULL
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = @CODE_KO_EXISTANT
		END
	END
	ELSE
		SET @v_retour = @CODE_KO_INCORRECT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


