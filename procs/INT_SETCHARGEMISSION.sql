SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETCHARGEMISSION]
	@v_mis_idmission int,
	@v_chg_code_new varchar(8000)
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
	@v_transaction varchar,
	@v_error int,
	@v_retour int,
	@v_mis_idetatmission tinyint,
	@v_chg_code_old varchar(8000),
	@v_chg_idcharge_old int,
	@v_chg_idcharge_new int,
	@v_chg_idsysteme_old bigint,
	@v_chg_idbase_old bigint,
	@v_chg_idsousbase_old bigint,
	@v_chg_idsysteme_new bigint,
	@v_chg_idbase_new bigint,
	@v_chg_idsousbase_new bigint,
	@v_chg_positioncolonne int,
	@v_chg_positionprofondeur int,
	@v_chg_positionniveau int,
	@v_tym_idtypemission tinyint,
	@v_tac_idtache int,
	@v_tac_position tinyint,
	@v_tac_descriptionetat tinyint,
	@v_ata_idaction int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_MISSION_INCONNUE int,
	@CODE_KO_ETAT_MISSION int,
	@CODE_KO_INTERDIT tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@DESC_DEFAUT_ACTION_SECONDAIRE tinyint,
	@ACTI_KO bit

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_IDENTIFICATION smallint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_TRANSFERT tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_STOPPE = 3
	SET @ETAT_TERMINE = 5
	SET @DESC_DEFAUT_ACTION_SECONDAIRE = 14
	SET @ACTI_IDENTIFICATION = 8
	SET @ACTI_KO = 1
	SET @TYPE_TRANSFERT = 1

-- Initialisation des variables
	SELECT @v_transaction = 'SETCHARGEMISSION'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION, @v_chg_idcharge_old = MIS_IDCHARGE, @v_tym_idtypemission = MIS_IDTYPEMISSION
		FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle du type de la mission
		IF @v_tym_idtypemission = @TYPE_TRANSFERT
		BEGIN
			-- Contrôle de l'état de la mission
			IF @v_mis_idetatmission = @ETAT_STOPPE
			BEGIN
				-- Vérification et récupération de l'action à valider
				SELECT TOP 1 @v_tac_idtache = ATA_IDTACHE, @v_tac_position = TAC_POSITION, @v_ata_idaction = ATA_IDACTION, @v_tac_descriptionetat = TAC_IDDESCRIPTIONETAT
					FROM INT_TACHE_MISSION, INT_ACTION_TACHE WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETATTACHE = @ETAT_TERMINE
					AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDACTION = @ACTI_IDENTIFICATION AND ATA_IDETATACTION = @ACTI_KO
					AND ATA_VALIDATION = 1 ORDER BY TAC_POSITION, ATA_IDTYPEACTION
				IF @v_tac_idtache IS NOT NULL AND @v_tac_descriptionetat = @DESC_DEFAUT_ACTION_SECONDAIRE
				BEGIN
					SELECT @v_chg_code_old = CHG_CODE, @v_chg_idsysteme_old = CHG_IDSYSTEME, @v_chg_idbase_old = CHG_IDBASE, @v_chg_idsousbase_old = CHG_IDSOUSBASE,
						@v_chg_positionprofondeur = CHG_POSITIONPROFONDEUR, @v_chg_positionniveau = CHG_POSITIONNIVEAU, @v_chg_positioncolonne = CHG_POSITIONCOLONNE FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge_old
					SELECT @v_chg_idcharge_new = CHG_IDCHARGE, @v_chg_idsysteme_new = CHG_IDSYSTEME, @v_chg_idbase_new = CHG_IDBASE, @v_chg_idsousbase_new = CHG_IDSOUSBASE
						FROM INT_CHARGE_VIVANTE WHERE CHG_CODE = @v_chg_code_new
					IF ((@v_chg_code_old IS NULL) AND (@v_chg_idcharge_new IS NULL))
					BEGIN
						UPDATE CHARGE SET CHG_IDCLIENT = @v_chg_code_new WHERE CHG_ID = @v_chg_idcharge_old
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = @CODE_OK
						ELSE
							SELECT @v_retour = @CODE_KO_SQL
					END
					ELSE
					BEGIN
						IF ISNULL(@v_chg_code_new, '') <> ISNULL(@v_chg_code_old, '')
						BEGIN
							IF @v_chg_idcharge_new IS NOT NULL
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_chg_idcharge_new)
								BEGIN
									UPDATE CHARGE SET CHG_ADR_KEYSYS = NULL, CHG_ADR_KEYBASE = NULL, CHG_ADR_KEYSSBASE = NULL,
										CHG_POSX = 0, CHG_POSY = 0, CHG_POSZ = 0, CHG_ACONTROLER = 1 WHERE CHG_ID = @v_chg_idcharge_old
									SELECT @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										UPDATE CHARGE SET CHG_ADR_KEYSYS = @v_chg_idsysteme_old, CHG_ADR_KEYBASE = @v_chg_idbase_old, CHG_ADR_KEYSSBASE = @v_chg_idsousbase_old,
											CHG_POSX = @v_chg_positioncolonne, CHG_POSY = @v_chg_positionprofondeur, CHG_POSZ = @v_chg_positionniveau WHERE CHG_ID = @v_chg_idcharge_new
										SELECT @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											UPDATE MISSION SET MIS_IDCHARGE = @v_chg_idcharge_new WHERE MIS_IDMISSION = @v_mis_idmission
											SELECT @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												IF @v_chg_idsysteme_new IS NOT NULL AND @v_chg_idbase_new IS NOT NULL AND @v_chg_idsousbase_new IS NOT NULL
												BEGIN
													UPDATE ADRESSE SET ADR_AVERIFIER = 1 WHERE ADR_SYSTEME = @v_chg_idsysteme_new AND ADR_BASE = @v_chg_idbase_new
														AND ADR_SOUSBASE = @v_chg_idsousbase_new
													SELECT @v_error = @@ERROR
													IF @v_error = 0
														SELECT @v_retour = @CODE_OK
													ELSE
														SELECT @v_retour = @CODE_KO_SQL
												END
												ELSE
													SELECT @v_retour = @CODE_OK
											END
											ELSE
												SELECT @v_retour = @CODE_KO_SQL
										END
										ELSE
											SELECT @v_retour = @CODE_KO_SQL
									END
									ELSE
										SELECT @v_retour = @CODE_KO_SQL
								END
								ELSE
									SELECT @v_retour = @CODE_KO_EXISTANT
							END
							ELSE
								SELECT @v_retour = @CODE_KO_INEXISTANT
						END
						ELSE
							SELECT @v_retour = @CODE_OK
					END
					IF @v_retour = @CODE_OK
					BEGIN
						UPDATE ASSOCIATION_TACHE_ACTION_TACHE SET ATA_VALIDATION = 0 WHERE ATA_IDTACHE = @v_tac_idtache AND ATA_IDACTION = @v_ata_idaction
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION, INT_ACTION_TACHE WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETATTACHE = @ETAT_TERMINE
								AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDETATACTION = @ACTI_KO AND ATA_VALIDATION = 1)
							BEGIN
								UPDATE CHARGE SET CHG_AVALIDER = 0 WHERE CHG_ID = @v_chg_idcharge_old
								SELECT @v_error = @@ERROR
								IF @v_error = 0
									SELECT @v_retour = @CODE_OK
								ELSE
									SELECT @v_retour = @CODE_KO_SQL
							END
						END
						ELSE
							SELECT @v_retour = @CODE_KO_SQL
					END
				END
				ELSE
					SELECT @v_retour = @CODE_KO_INATTENDU
			END
			ELSE
				SELECT @v_retour = @CODE_KO_ETAT_MISSION
		END
		ELSE
			SELECT @v_retour = @CODE_KO_INTERDIT
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

