SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_CANCELMISSION]
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
	@v_retour int,
	@v_mis_idetatmission tinyint,
	@v_tac_idtache int,
	@v_tac_idordre int

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
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_ANNULATION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13 
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ANNULATION = 9

-- Initialisation des variables
	SET @v_transaction = 'CANCELMISSION'
	SET @v_error = 0
	SET @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle de l'état de la mission
		IF @v_mis_idetatmission IN (@ETAT_ENATTENTE, @ETAT_SUSPENDU)
		BEGIN
			DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDTACHE, TAC_IDORDRE
				FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			OPEN c_tache
			FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				UPDATE TACHE SET TAC_IDETAT = @ETAT_ANNULE, TAC_DSCETAT = @DESC_ANNULATION, TAC_IDORDRE = NULL
					WHERE TAC_IDTACHE = @v_tac_idtache
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_tac_idordre IS NOT NULL AND NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDORDRE = @v_tac_idordre)
					BEGIN
						UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_ANNULE, ORD_DSCETAT = @DESC_ANNULATION
							WHERE ORD_IDORDRE = @v_tac_idordre
						SET @v_error = @@ERROR
					END
				END
				ELSE
					SET @v_retour = @CODE_KO_SQL
				FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
			END
			CLOSE c_tache
			DEALLOCATE c_tache
			IF @v_error = 0
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = @CODE_KO_SQL
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


