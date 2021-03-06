SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_TRANSFERBATTERIE]
	@v_iag_idagv tinyint = NULL,
	@v_bat_id tinyint = NULL,
	@v_adr_idsysteme_depose bigint = NULL,
	@v_adr_idbase_depose bigint = NULL,
	@v_adr_idsousbase_depose bigint = NULL
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
	@v_adr_idtypemagasin_depose	tinyint,
	@v_coe_id smallint,
	@v_coe_type tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_PLEIN tinyint,
	@CODE_KO_ACTION_INCORRECTE_5 tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_ENERGIE tinyint
	
-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_PARAM = 8
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_PLEIN = 17
	SET @CODE_KO_ACTION_INCORRECTE_5 = 25
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @TYPE_AGV = 1
	SET @TYPE_ENERGIE = 6
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3

-- Initialisation des variables
	SET @v_transaction = 'TRANSFERBATTERIE'
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
	-- Vérification de l'existence de la batterie
	IF ((@v_bat_id IS NULL) OR EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_ID = @v_bat_id))
	BEGIN
		IF @v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL
			SELECT @v_adr_idtypemagasin_depose = ADR_IDTYPEMAGASIN FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme_depose
				AND ADR_IDBASE = @v_adr_idbase_depose AND ADR_IDSOUSBASE = @v_adr_idsousbase_depose
		IF ((@v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL AND @v_adr_idtypemagasin_depose IS NOT NULL)
			OR (@v_adr_idsysteme_depose IS NULL AND @v_adr_idbase_depose IS NULL AND @v_adr_idsousbase_depose IS NULL))
		BEGIN
			IF @v_bat_id IS NOT NULL AND @v_iag_idagv IS NOT NULL AND @v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL
			BEGIN
				SELECT @v_coe_id = COE_ID, @v_coe_type = COE_TYPE FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_idsysteme_depose AND COE_ADRBASE = @v_adr_idbase_depose AND COE_ADRSSBASE = @v_adr_idsousbase_depose
				IF @v_adr_idtypemagasin_depose = @TYPE_ENERGIE AND @v_coe_type = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
				BEGIN
					IF @v_iag_idagv = (SELECT TOP 1 CRE_IDAGV FROM CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ = @v_coe_id)
					BEGIN
						IF @v_bat_id IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv)
						BEGIN
							UPDATE BATTERIE SET BAT_INFO_AGV = NULL, BAT_CONFIG_OBJ_ENERGIE = @v_coe_id, BAT_DATELASTOPER = GETDATE() WHERE BAT_ID = @v_bat_id
							SET @v_error = @@ERROR
							IF @v_error = 0
								SET @v_retour = @CODE_OK
							ELSE
								SET @v_retour = @CODE_KO_SQL
						END
						ELSE
							SET @v_retour = @CODE_KO_ACTION_INCORRECTE_5
					END
					ELSE
						SET @v_retour = @CODE_KO_PARAM
				END
				ELSE
					SET @v_retour = @CODE_KO_INCOMPATIBLE
			END
			ELSE IF @v_bat_id IS NOT NULL AND @v_iag_idagv IS NOT NULL AND @v_adr_idsysteme_depose IS NULL AND @v_adr_idbase_depose IS NULL AND @v_adr_idsousbase_depose IS NULL
			BEGIN
				IF @v_bat_id IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv)
				BEGIN
					UPDATE BATTERIE SET BAT_INFO_AGV = @v_iag_idagv, BAT_CONFIG_OBJ_ENERGIE = NULL, BAT_DATELASTOPER = GETDATE() WHERE BAT_ID = @v_bat_id
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE
					SET @v_retour = @CODE_KO_ACTION_INCORRECTE_5
			END
			ELSE IF @v_bat_id IS NOT NULL AND @v_iag_idagv IS NULL AND @v_adr_idsysteme_depose IS NULL AND @v_adr_idbase_depose IS NULL AND @v_adr_idsousbase_depose IS NULL
			BEGIN
				UPDATE BATTERIE SET BAT_INFO_AGV = NULL, BAT_CONFIG_OBJ_ENERGIE = NULL, BAT_DATELASTOPER = GETDATE() WHERE BAT_ID = @v_bat_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = @CODE_KO_SQL
			END
			ELSE IF @v_bat_id IS NULL AND @v_iag_idagv IS NULL AND @v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL
			BEGIN
				SELECT @v_coe_id = COE_ID, @v_coe_type = COE_TYPE FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_idsysteme_depose AND COE_ADRBASE = @v_adr_idbase_depose AND COE_ADRSSBASE = @v_adr_idsousbase_depose
				IF @v_adr_idtypemagasin_depose = @TYPE_ENERGIE AND @v_coe_type = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE = @v_coe_id)
					BEGIN
						SELECT TOP 1 @v_iag_idagv = CRE_IDAGV FROM CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ = @v_coe_id
						SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) AND ((BAT_INFO_AGV = @v_iag_idagv) OR (BAT_INFO_AGV IS NULL)) ORDER BY BAT_INFO_AGV DESC, BAT_CONFIG_OBJ_ENERGIE
						IF @v_iag_idagv IS NOT NULL
						BEGIN
							IF @v_bat_id IS NOT NULL
							BEGIN
								UPDATE BATTERIE SET BAT_INFO_AGV = NULL, BAT_CONFIG_OBJ_ENERGIE = @v_coe_id, BAT_DATELASTOPER = GETDATE() WHERE BAT_ID = @v_bat_id
								SET @v_error = @@ERROR
								IF @v_error = 0
									SET @v_retour = @CODE_OK
								ELSE
									SET @v_retour = @CODE_KO_SQL
							END
							ELSE
								SET @v_retour = @CODE_KO_ACTION_INCORRECTE_5
						END
						ELSE
							SET @v_retour = @CODE_KO_PARAM
					END
					ELSE
						SET @v_retour = @CODE_KO_PLEIN
				END
				ELSE
					SET @v_retour = @CODE_KO_INCOMPATIBLE
			END
			ELSE
				SET @v_retour = @CODE_KO_INCORRECT
		END
		ELSE
			SET @v_retour = @CODE_KO_ADR_INCONNUE
	END
	ELSE
		SET @v_retour = @CODE_KO_ACTION_INCORRECTE_5
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

