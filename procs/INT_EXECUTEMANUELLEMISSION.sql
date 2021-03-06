SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_EXECUTEMANUELLEMISSION]
	@v_mis_idmission int,
	@v_tac_idsystemeexecution bigint = NULL,
	@v_tac_idbaseexecution bigint = NULL,
	@v_tac_idsousbaseexecution bigint = NULL,
	@v_tac_niveauexecution tinyint = NULL,
	@v_accesbase bit = NULL,
	@v_chg_orientation smallint = 0
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_mis_idetatmission tinyint,
	@v_mis_idtypemission tinyint,
	@v_chg_idcharge int,
	@v_tac_idtache int,
	@v_tac_position tinyint,
	@v_tac_idetattache tinyint,
	@v_tac_descriptionetat tinyint,
	@v_ata_idaction int,
	@v_orientation smallint,
	@v_tac_idordre int,
	@v_iag_idagv tinyint,
	@v_tag_idtypeagv tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_ADR_INCONNUE tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint,
	@CODE_KO_ETAT_MISSION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_FIN_INTEGRAL tinyint,
	@DESC_REVISION tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_RELANCE_INTERNE tinyint,
	@DESC_EXECUTION_MANUELLE tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_ATTENTE smallint,
	@ACTI_DEPOSE smallint,
	@ACTI_VIDANGE smallint
	
-- Déclaration des constantes types mission
DECLARE
	@TYPE_TRANSFERT_CHARGE tinyint	

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_FIN_INTEGRAL = 3
	SET @DESC_REVISION = 7
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_RELANCE_INTERNE = 11
	SET @DESC_EXECUTION_MANUELLE = 4
	SET @ACTI_ATTENTE = 1
	SET @ACTI_DEPOSE = 4
	SET @ACTI_VIDANGE = 8192
	SET @TYPE_TRANSFERT_CHARGE = 1

-- Initialisation des variables
	SET @v_transaction = 'EXECUTEMANUELLEMISSION'
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
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION, @v_mis_idtypemission = MIS_IDTYPEMISSION, @v_chg_idcharge = MIS_IDCHARGE, @v_iag_idagv = MIS_IDAGV, @v_tag_idtypeagv = IAG_IDTYPEAGV
		FROM INT_MISSION_VIVANTE LEFT OUTER JOIN INT_AGV ON IAG_IDAGV = MIS_IDAGV WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle du type de la mission
		IF @v_mis_idtypemission = @TYPE_TRANSFERT_CHARGE
		BEGIN
			-- Contrôle de l'état de la mission
			IF @v_mis_idetatmission = @ETAT_STOPPE
			BEGIN
				-- Récupération de la tâche à exécuter
				SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_position = TAC_POSITION, @v_tac_idetattache = TAC_IDETATTACHE, @v_tac_idordre = TAC_IDORDRE,
					@v_tac_descriptionetat = TAC_IDDESCRIPTIONETAT, @v_ata_idaction = TAC_IDACTION FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_mis_idmission
					AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) ORDER BY TAC_POSITION
				IF (@v_tac_idtache IS NOT NULL) AND ((@v_tac_idetattache = @ETAT_STOPPE) OR (@v_tac_idetattache IN (@ETAT_ENATTENTE, @ETAT_ENCOURS) AND @v_tac_descriptionetat IN (@DESC_RELANCE_MISSION, @DESC_RELANCE_INTERNE)))
				BEGIN
					IF ((@v_tac_idsystemeexecution IS NULL) OR (@v_tac_idbaseexecution IS NULL) OR (@v_tac_idsousbaseexecution IS NULL)
						OR EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_tac_idsystemeexecution AND ADR_IDBASE = @v_tac_idbaseexecution
						AND ADR_IDSOUSBASE = @v_tac_idsousbaseexecution AND ADR_TYPEADRESSE = 1))
					BEGIN
						IF @v_ata_idaction <> @ACTI_ATTENTE
						BEGIN
							-- Récupération de l'adresse initialie ou mise à jour de celle-ci
							IF ((@v_tac_idsystemeexecution IS NULL) OR (@v_tac_idbaseexecution IS NULL) OR (@v_tac_idsousbaseexecution IS NULL))
								SELECT @v_tac_idsystemeexecution = TAC_IDSYSTEMEEXECUTION, @v_tac_idbaseexecution = TAC_IDBASEEXECUTION, @v_tac_idsousbaseexecution = TAC_IDSOUSBASEEXECUTION
									FROM INT_TACHE_MISSION WHERE TAC_IDTACHE = @v_tac_idtache
							ELSE
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDTACHE = @v_tac_idtache AND TAC_IDSYSTEMEEXECUTION = @v_tac_idsystemeexecution
									AND TAC_IDBASEEXECUTION = @v_tac_idbaseexecution AND TAC_IDSOUSBASEEXECUTION = @v_tac_idsousbaseexecution)
								BEGIN
									UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution
										WHERE TAC_IDTACHE = @v_tac_idtache
									SET @v_error = @@ERROR
								END
							END
						END
						IF @v_error = 0
						BEGIN
							IF @v_ata_idaction = @ACTI_DEPOSE
							BEGIN
					  			EXEC @v_status = INT_TRANSFERCHARGE @v_tag_idtypeagv, @v_chg_idcharge, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, @v_tac_niveauexecution,
									@v_accesbase, @v_chg_orientation, NULL, NULL, NULL, NULL, 0, @v_tac_idtache
								SET @v_error = @@ERROR
								IF @v_status = @CODE_OK AND @v_error = 0
									SET @v_retour = @CODE_OK
								ELSE
									SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
							END
							ELSE IF @v_ata_idaction = @ACTI_VIDANGE
								EXEC @v_retour = SPV_VIDANGECHARGE @v_chg_idcharge
							ELSE 
								SET @v_retour = @CODE_OK
							IF @v_retour = @CODE_OK
							BEGIN
								-- Mise à jour de l'état de la tâche
								-- Suppression du rattachement aux ordres AGVs, s'il n'existe plus de tâches rattachées
								-- à ces ordres, ceux-ci sont passés dans l'état terminé
								UPDATE TACHE SET TAC_IDETAT = @ETAT_TERMINE, TAC_DSCETAT = @DESC_EXECUTION_MANUELLE, TAC_IDORDRE = NULL
									WHERE TAC_IDTACHE = @v_tac_idtache
								IF @@ERROR <> 0
									SET @v_retour = @CODE_KO_SQL
								ELSE
								BEGIN
									IF NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDORDRE = @v_tac_idordre)
									BEGIN
										UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_TERMINE, ORD_DSCETAT = @DESC_FIN_INTEGRAL
											WHERE ORD_IDORDRE = @v_tac_idordre
										IF @@ERROR <> 0
											SET @v_retour = @CODE_KO_SQL
									END
								END
								IF @v_retour = @CODE_OK AND @v_ata_idaction = @ACTI_ATTENTE AND EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_mis_idmission)
								BEGIN
									EXEC @v_status = INT_EXECUTEMANUELLEMISSION @v_mis_idmission, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
										@v_tac_niveauexecution, @v_accesbase, @v_chg_orientation
									SET @v_error = @@ERROR
									IF @v_status = @CODE_OK AND @v_error = 0
										SET @v_retour = @CODE_OK
									ELSE
										SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
								END
							END
						END
						ELSE
							SET @v_retour = @CODE_KO_SQL
					END
					ELSE
					BEGIN
						IF EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_tac_idsystemeexecution AND ADR_IDBASE = @v_tac_idbaseexecution
							AND ADR_IDSOUSBASE = @v_tac_idsousbaseexecution)
							SET @v_retour = @CODE_KO_INCOMPATIBLE
						ELSE
							SET @v_retour = @CODE_KO_ADR_INCONNUE
					END
				END
				ELSE
					SET @v_retour = @CODE_KO_ETAT_MISSION
			END
			ELSE
				SET @v_retour = @CODE_KO_ETAT_MISSION
		END
		ELSE
			SET @v_retour = @CODE_KO_INATTENDU
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



