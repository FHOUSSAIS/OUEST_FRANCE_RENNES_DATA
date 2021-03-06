SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_RESTARTMISSION]
	@v_mis_idmission int
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
	@v_mis_idetatmission tinyint,
	@v_tac_idtache int,
	@v_tac_idetattache tinyint,
	@v_iag_idagv tinyint,
	@v_ord_idordre int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint,
	@CODE_KO_ETAT_MISSION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_RELANCE_INTERNE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_STOPPE = 3
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_RELANCE_INTERNE = 11

-- Initialisation des variables
	SET @v_transaction = 'RESTARTMISSION'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION, @v_iag_idagv = MIS_IDAGV FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle de l'état de la mission
		IF @v_mis_idetatmission IN (@ETAT_STOPPE, @ETAT_SUSPENDU)
		BEGIN
			-- Récupération de la tâche à relancer
			SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_idetattache = TAC_IDETATTACHE,
				@v_ord_idordre = TAC_IDORDRE FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
				ORDER BY TAC_POSITION
			IF (@v_tac_idtache IS NOT NULL) AND ((@v_mis_idetatmission = @ETAT_STOPPE AND @v_tac_idetattache = @ETAT_STOPPE)
				OR (@v_mis_idetatmission = @ETAT_SUSPENDU AND @v_tac_idetattache = @ETAT_SUSPENDU))
			BEGIN
				IF @v_mis_idetatmission = @ETAT_STOPPE
				BEGIN
					UPDATE TACHE SET TAC_OFSPROFONDEUR = NULL, TAC_OFSNIVEAU = NULL, TAC_OFSCOLONNE = NULL WHERE TAC_IDTACHE = @v_tac_idtache
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_status = SPV_RELANCEORDRE @v_iag_idagv, @v_ord_idordre, @v_mis_idmission, @DESC_RELANCE_MISSION
						SET @v_error = @@ERROR
						IF @v_status IN (@CODE_KO, @CODE_OK) AND @v_error = 0
							SET @v_retour = @CODE_OK
						ELSE
							SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
					END
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE IF @v_mis_idetatmission = @ETAT_SUSPENDU
				BEGIN
					UPDATE TACHE SET TAC_IDETAT = @ETAT_ENATTENTE, TAC_DSCETAT = @DESC_RELANCE_MISSION
						WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETAT IN (@ETAT_SUSPENDU, @ETAT_TERMINE)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_status = SPV_DESAFFINEEXECUTION @v_mis_idmission
						SET @v_error = @@ERROR
						IF NOT (@v_status = @CODE_OK AND @v_error = 0)
							SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
						ELSE
							SET @v_retour = @CODE_OK
					END
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
			END
			ELSE
				SET @v_retour = @CODE_KO_ETAT_MISSION
		END
		ELSE
			SET @v_retour = @CODE_KO_ETAT_MISSION
	END
	ELSE
		SET @v_retour = @CODE_KO_MISSION_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


