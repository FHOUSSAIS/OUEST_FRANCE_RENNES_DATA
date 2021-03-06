SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETDESTINATIONMISSION]
	@v_mis_idmission int,
	@v_tac_idsysteme bigint,
	@v_tac_idbase bigint,
	@v_tac_idsousbase bigint,
	@v_tac_accesbase bit = NULL
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
	@v_tac_idetattache tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ADR_INCONNUE tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint,
	@CODE_KO_ETAT_MISSION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13
	SELECT @CODE_KO_ADR_INCONNUE = 28
	SELECT @CODE_KO_MISSION_INCONNUE = 31
	SELECT @CODE_KO_ETAT_MISSION = 32
	SELECT @ETAT_STOPPE = 3
	SELECT @ETAT_TERMINE = 5
	SELECT @ETAT_ANNULE = 6

-- Initialisation des variables
	SELECT @v_transaction = 'SETDESTINATIONMISSION'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle de l'état de la mission
		IF @v_mis_idetatmission = @ETAT_STOPPE
		BEGIN
			-- Contrôle de l'existence de l'adresse
			IF EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_tac_idsysteme AND ADR_IDBASE = @v_tac_idbase AND ADR_IDSOUSBASE = @v_tac_idsousbase)
			BEGIN
				-- Récupération de la tâche à modifier
				SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_idetattache = TAC_IDETATTACHE
					FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
					ORDER BY TAC_POSITION
				IF (@v_tac_idtache IS NOT NULL) AND (@v_tac_idetattache = @ETAT_STOPPE)
				BEGIN
					UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsysteme, TAC_IDADRBASE = @v_tac_idbase, TAC_IDADRSSBASE = @v_tac_idsousbase,
						TAC_ACCES_BASE = @v_tac_accesbase, TAC_OFSPROFONDEUR = NULL, TAC_OFSNIVEAU = NULL, TAC_OFSCOLONNE = NULL
						WHERE TAC_IDTACHE = @v_tac_idtache
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = @CODE_OK
					ELSE
						SELECT @v_retour = @CODE_KO_SQL
				END
				ELSE
					SELECT @v_retour = @CODE_KO_ETAT_MISSION
			END
			ELSE
				SELECT @v_retour = @CODE_KO_ADR_INCONNUE
		END
		ELSE
			SELECT @v_retour = @CODE_KO_ETAT_MISSION
	END
	ELSE
		SELECT @v_retour = @CODE_KO_MISSION_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour



