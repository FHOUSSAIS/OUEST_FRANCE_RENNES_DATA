SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETAFFECTATIONADRESSEENERGIE]
	@v_action smallint,
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_iag_idagv tinyint
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
	@v_coe_id smallint,
	@v_coe_type tinyint,
	@v_coe_rack tinyint
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ACTION_INCORRECTE_4 tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de symboles
DECLARE
	@SYMB_BATTERIE varchar(32)

-- Déclaration des constantes de menus contextuels
DECLARE
	@MENU_BATTERIE int

-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_ACTION_INCORRECTE_4 = 24
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @SYMB_BATTERIE = 'BATTERIE'
	SET @MENU_BATTERIE = 1
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3

-- Initialisation des variables
	SET @v_transaction = 'SETAFFECTATIONADRESSEENERGIE'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	IF @v_action IN (0, 1)
	BEGIN
		SELECT @v_coe_id = COE_ID, @v_coe_type = COE_TYPE, @v_coe_rack = COE_RACK FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_idsysteme AND COE_ADRBASE = @v_adr_idbase AND COE_ADRSSBASE = @v_adr_idsousbase
		IF (@v_coe_id IS NOT NULL)
		BEGIN
			IF @v_action = 0
			BEGIN
				IF EXISTS (SELECT 1 FROM INT_AGV WHERE IAG_IDAGV = @v_iag_idagv)
				BEGIN
					IF @v_coe_type = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_ID = 2 * @v_iag_idagv - 1)
						BEGIN
							INSERT INTO BATTERIE (BAT_ID, BAT_INFO_AGV, BAT_CONFIG_OBJ_ENERGIE, BAT_SYMBOLE, BAT_MENU_CONTEXTUEL, BAT_DATELASTOPER) SELECT 2 * @v_iag_idagv - 1, NULL, NULL, @SYMB_BATTERIE, @MENU_BATTERIE, GETDATE()
							SET @v_error = @@ERROR
							IF @v_error <> 0
								SET @v_retour = @CODE_KO_SQL
						END
						IF @v_error = 0 AND NOT EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_ID = 2 * @v_iag_idagv)
						BEGIN
							INSERT INTO BATTERIE (BAT_ID, BAT_INFO_AGV, BAT_CONFIG_OBJ_ENERGIE, BAT_SYMBOLE, BAT_MENU_CONTEXTUEL, BAT_DATELASTOPER) SELECT 2 * @v_iag_idagv, NULL, NULL, @SYMB_BATTERIE, @MENU_BATTERIE, GETDATE()
							SET @v_error = @@ERROR
							IF @v_error <> 0
								SET @v_retour = @CODE_KO_SQL
						END
						UPDATE BATTERIE SET BAT_CONFIG_OBJ_ENERGIE = NULL WHERE BAT_ID IN (SELECT TOP 1 BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv))
						SET @v_error = @@ERROR
						IF @v_error <> 0
							SET @v_retour = @CODE_KO_SQL
						IF @v_error = 0 AND EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE = @v_coe_id)
						BEGIN
							UPDATE BATTERIE SET BAT_INFO_AGV = NULL, BAT_CONFIG_OBJ_ENERGIE = @v_coe_id WHERE BAT_ID = (SELECT TOP 1 BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) ORDER BY BAT_INFO_AGV)
							SET @v_error = @@ERROR
							IF @v_error <> 0
								SET @v_retour = @CODE_KO_SQL
						END
						IF @v_error = 0 AND EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack AND COE_ID <> @v_coe_id))
						BEGIN
							UPDATE BATTERIE SET BAT_INFO_AGV = NULL, BAT_CONFIG_OBJ_ENERGIE = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack AND COE_ID <> @v_coe_id) WHERE BAT_ID = (SELECT TOP 1 BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) AND BAT_CONFIG_OBJ_ENERGIE IS NULL)
							SET @v_error = @@ERROR
							IF @v_error <> 0
								SET @v_retour = @CODE_KO_SQL
						END
						IF @v_error = 0
						BEGIN
							DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDAGV = @v_iag_idagv
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack)
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									UPDATE BATTERIE SET BAT_CONFIG_OBJ_ENERGIE = NULL WHERE BAT_ID NOT IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) AND BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack)
									SET @v_error = @@ERROR
									IF @v_error = 0
									BEGIN
										INSERT INTO CONFIG_RSV_ENERGIE (CRE_IDOBJ, CRE_IDAGV) VALUES (@v_coe_id, @v_iag_idagv)
										SET @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											INSERT INTO CONFIG_RSV_ENERGIE (CRE_IDOBJ, CRE_IDAGV) SELECT COE_ID, @v_iag_idagv FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack AND COE_ID <> @v_coe_id
											SET @v_error = @@ERROR
											IF @v_error = 0
												SET @v_retour = @CODE_OK
											ELSE
												SET @v_retour = @CODE_KO_SQL
										END
										ELSE
											SET @v_retour = @CODE_KO_SQL					
									END
									ELSE
										SET @v_retour = @CODE_KO_SQL					
								END
								ELSE
									SET @v_retour = @CODE_KO_SQL
							END
							ELSE
								SET @v_retour = @CODE_KO_SQL
						END
					END
					ELSE
					BEGIN
						DELETE BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDAGV = @v_iag_idagv AND CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_TYPE = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME)
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ = @v_coe_id AND CRE_IDAGV = @v_iag_idagv)
								BEGIN
									INSERT INTO CONFIG_RSV_ENERGIE (CRE_IDOBJ, CRE_IDAGV) VALUES (@v_coe_id, @v_iag_idagv)
									SET @v_error = @@ERROR
									IF @v_error = 0
										SET @v_retour = @CODE_OK
									ELSE
										SET @v_retour = @CODE_KO_SQL
								END
								ELSE
									SET @v_retour = @CODE_OK
							END
							ELSE
								SET @v_retour = @CODE_KO_SQL
						END
						ELSE
							SET @v_retour = @CODE_KO_SQL
					END
				END
				ELSE
					SET @v_retour = @CODE_KO_ACTION_INCORRECTE_4
			END
			ELSE IF @v_action = 1
			BEGIN
				DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DECLARE c_batterie CURSOR LOCAL FAST_FORWARD FOR SELECT CEILING(CONVERT(FLOAT, BAT_ID) / 2) FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_RACK = @v_coe_rack)
					OPEN c_batterie
					FETCH NEXT FROM c_batterie INTO @v_iag_idagv
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						DELETE BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv)
						SET @v_error = @@ERROR
						FETCH NEXT FROM c_batterie INTO @v_iag_idagv
					END
					CLOSE c_batterie
					DEALLOCATE c_batterie
					IF @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
			END
		END
		ELSE
			SET @v_retour = @CODE_KO_ADR_INCONNUE
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

