SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETVALIDATIONCHARGE]
	@v_chg_idcharge_old int,
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
	@v_chg_code_old varchar(8000),
	@v_chg_idcharge_new int,
	@v_chg_idsysteme_old bigint,
	@v_chg_idbase_old bigint,
	@v_chg_idsousbase_old bigint,
	@v_chg_idsysteme_new bigint,
	@v_chg_idbase_new bigint,
	@v_chg_idsousbase_new bigint,
	@v_chg_positioncolonne int,
	@v_chg_positionprofondeur int,
	@v_chg_positionniveau int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13

-- Initialisation des variables
	SELECT @v_transaction = 'SETVALIDATIONCHARGE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO
	
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la charge
	IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge_old)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_chg_idcharge_old)
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
				UPDATE CHARGE SET CHG_AVALIDER = 0 WHERE CHG_ID = @v_chg_idcharge_old
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = @CODE_OK
				ELSE
					SELECT @v_retour = @CODE_KO_SQL
			END
		END
		ELSE
			SET @v_retour = @CODE_KO_EXISTANT
	END
	ELSE
		SELECT @v_retour = @CODE_KO_INEXISTANT					
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

