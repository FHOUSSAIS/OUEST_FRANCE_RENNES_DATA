SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_TRANSFERCHARGE]
	@v_tag_idtypeagv tinyint = NULL,
	@v_chg_idcharge int,
	@v_adr_idsysteme_depose bigint,
	@v_adr_idbase_depose bigint,
	@v_adr_idsousbase_depose bigint,
	@v_adr_niveau_depose tinyint = NULL,
	@v_accesbase bit = NULL,
	@v_chg_orientation_depose smallint,
	@v_chg_positionprofondeur_depose int = NULL,
	@v_chg_positionniveau_depose int = NULL,
	@v_chg_positioncolonne_depose int = NULL,
	@v_chg_position tinyint = NULL,
	@v_forcage bit = 0,
	@v_tac_idtache_depose int = NULL
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
	@v_adr_type bit,
	@v_adr_idsysteme_prise bigint,
	@v_adr_idbase_prise bigint,
	@v_adr_idsousbase_prise bigint,
	@v_adr_idtypemagasin_prise tinyint,
	@v_adr_idtypemagasin_depose tinyint,
	@v_adr_autorisation_prise bit,
	@v_adr_autorisation_depose bit,
	@v_adr_verification_prise bit,
	@v_adr_verification_depose bit,
	@v_adr_rayonnage_prise bit,
	@v_adr_rayonnage_depose bit,
	@v_adr_gerbage_prise bit,
	@v_adr_gerbage_depose bit,
	@v_adr_accumulation_prise bit,
	@v_adr_accumulation_depose bit,
	@v_chg_rang_prise smallint,
	@v_chg_rang_depose smallint,
	@v_chg_couche_prise tinyint,
	@v_chg_couche_depose tinyint,
	@v_chg_positionprofondeur_prise int,
	@v_chg_positionniveau_prise int,
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_emb_engagement smallint,
	@v_chg_rang_min smallint,
	@v_chg_rang_max smallint,
	@v_tac_positionniveau_depose int = NULL

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_INTERDIT tinyint,
	@CODE_KO_CHARGE tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint
	
-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENCOURS tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_TRANSFERT tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_CHARGE = 19
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @TYPE_AGV = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @ETAT_ENCOURS = 2
	SET @TYPE_TRANSFERT = 1

-- Initialisation des variables
	SET @v_transaction = 'TRANSFERCHARGE'
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
	-- Vérification de l'existence de la charge
	IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge)
	BEGIN
		-- Récupération des informations de l'adresse de prise
		-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
		SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR, @v_chg_positionprofondeur_prise = CHG_POSITIONPROFONDEUR, @v_chg_positionniveau_prise = CHG_POSITIONNIVEAU, @v_chg_rang_prise = CHG_RANG, @v_chg_couche_prise = CHG_COUCHE,
			@v_chg_position = ISNULL(@v_chg_position, CHG_POSITION), @v_adr_idsysteme_prise = ADR_IDSYSTEME, @v_adr_idbase_prise = ADR_IDBASE, @v_adr_idsousbase_prise = ADR_IDSOUSBASE,
			@v_adr_idtypemagasin_prise = ADR_IDTYPEMAGASIN, @v_adr_rayonnage_prise = ADR_RAYONNAGE, @v_adr_accumulation_prise = ADR_ACCUMULATION, @v_adr_gerbage_prise = ADR_GERBAGE, @v_adr_autorisation_prise = ADR_AUTORISATIONPRISE,
			@v_adr_verification_prise = ADR_VERIFICATION, @v_emb_engagement = EMB_ENGAGEMENT
			FROM INT_CHARGE_VIVANTE LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_IDEMBALLAGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE,
			CHG_IDGABARIT, CHG_IDEMBALLAGE) LEFT OUTER JOIN INT_ADRESSE ON ADR_IDSYSTEME = CHG_IDSYSTEME AND ADR_IDBASE = CHG_IDBASE AND ADR_IDSOUSBASE = CHG_IDSOUSBASE
			WHERE CHG_IDCHARGE = @v_chg_idcharge
		-- Contrôle de cohérence de l'adresse de prise
		IF @v_adr_idsysteme_prise IS NOT NULL AND @v_adr_idbase_prise IS NOT NULL AND @v_adr_idsousbase_prise IS NOT NULL
			AND @v_adr_idtypemagasin_prise IN (@TYPE_INTERFACE, @TYPE_STOCK, @TYPE_PREPARATION)
			AND @v_forcage = 0 AND (@v_adr_autorisation_prise = 0 OR @v_adr_verification_prise = 1)
			SELECT @v_retour = @CODE_KO_INTERDIT
		ELSE
		BEGIN
			-- Contrôle de l'accessibilité de la charge
			IF @v_forcage = 0 AND NOT ((@v_adr_idtypemagasin_prise IS NULL) OR (@v_adr_idtypemagasin_prise IN (@TYPE_INTERFACE, @TYPE_AGV)) OR (@v_adr_idtypemagasin_prise IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_adr_accumulation_prise = 0))
			BEGIN
				SELECT @v_chg_rang_min = MIN(CHG_RANG), @v_chg_rang_max = MAX(CHG_RANG) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme_prise
					AND CHG_IDBASE = @v_adr_idbase_prise AND CHG_IDSOUSBASE = @v_adr_idsousbase_prise AND CHG_COUCHE = @v_chg_couche_prise
				IF ((@v_adr_idtypemagasin_prise = @TYPE_PREPARATION) OR (@v_adr_idtypemagasin_prise = @TYPE_STOCK AND @v_adr_rayonnage_prise = 0 AND @v_adr_gerbage_prise = 0))
				BEGIN
					IF @v_chg_rang_prise NOT IN (@v_chg_rang_min, @v_chg_rang_max)
						SET @v_error = @CODE_KO_CHARGE
				END
				ELSE IF @v_adr_idtypemagasin_prise = @TYPE_STOCK AND @v_adr_rayonnage_prise = 0 AND @v_adr_gerbage_prise = 1
				BEGIN
					IF NOT (@v_chg_rang_prise IN (@v_chg_rang_min, @v_chg_rang_max) AND @v_chg_positionniveau_prise = (SELECT MAX(CHG_POSITIONNIVEAU) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme_prise AND CHG_IDBASE = @v_adr_idbase_prise
						AND CHG_IDSOUSBASE = @v_adr_idsousbase_prise AND CHG_RANG = @v_chg_rang_prise))
						SET @v_error = @CODE_KO_CHARGE
				END
				ELSE IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE,
					CHG_IDGABARIT, CHG_IDEMBALLAGE) WHERE CHG_IDCHARGE <> @v_chg_idcharge AND CHG_IDSYSTEME = @v_adr_idsysteme_prise
					AND CHG_IDBASE = @v_adr_idbase_prise AND CHG_IDSOUSBASE = @v_adr_idsousbase_prise
					AND (CHG_POSITIONPROFONDEUR + LONGUEUR) < @v_chg_positionprofondeur_prise)
					AND EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE <> @v_chg_idcharge AND CHG_IDSYSTEME = @v_adr_idsysteme_prise
					AND CHG_IDBASE = @v_adr_idbase_prise AND CHG_IDSOUSBASE = @v_adr_idsousbase_prise
					AND CHG_POSITIONPROFONDEUR > (@v_chg_positionprofondeur_prise + @v_longueur))
					SET @v_error = @CODE_KO_CHARGE
			END
			IF @v_error = 0
			BEGIN
				-- Récupération des informations de l'adresse de dépose
				SELECT @v_adr_type = ADR_TYPEADRESSE, @v_adr_idtypemagasin_depose = ADR_IDTYPEMAGASIN, @v_adr_autorisation_depose = ADR_AUTORISATIONDEPOSE, @v_adr_verification_depose = ADR_VERIFICATION,
					@v_adr_rayonnage_depose = ADR_RAYONNAGE, @v_adr_gerbage_depose = ADR_GERBAGE, @v_adr_accumulation_depose = ADR_ACCUMULATION
					FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme_depose AND ADR_IDBASE = @v_adr_idbase_depose AND ADR_IDSOUSBASE = @v_adr_idsousbase_depose
				-- Contrôle de cohérence de l'adresse de dépose
				IF @v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL
					AND @v_adr_idtypemagasin_depose IN (@TYPE_INTERFACE, @TYPE_STOCK, @TYPE_PREPARATION)
					AND @v_forcage = 0 AND (@v_adr_autorisation_depose = 0 OR @v_adr_verification_depose = 1)
					SELECT @v_retour = @CODE_KO_INTERDIT
				ELSE
				BEGIN
					IF @v_adr_idsysteme_depose IS NOT NULL AND @v_adr_idbase_depose IS NOT NULL AND @v_adr_idsousbase_depose IS NOT NULL
					BEGIN
						IF @v_forcage = 1 OR NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE INNER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
							INNER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE WHERE MIS_IDTYPEMISSION = @TYPE_TRANSFERT
							AND TAC_IDSYSTEMEEXECUTION = @v_adr_idsysteme_depose AND TAC_IDBASEEXECUTION = @v_adr_idbase_depose AND TAC_IDSOUSBASEEXECUTION = @v_adr_idsousbase_depose
							AND TAC_IDETATTACHE = @ETAT_ENCOURS AND ISNULL(TAC_ACCESBASE, 0) = ISNULL(@v_accesbase, 0))
						BEGIN		
							IF @v_adr_type = 1
							BEGIN
								IF @v_adr_idtypemagasin_depose IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_adr_accumulation_depose = 1
								BEGIN
									IF @v_chg_positionprofondeur_depose IS NULL OR @v_chg_positionniveau_depose IS NULL OR @v_chg_positioncolonne_depose IS NULL
									BEGIN
										SELECT @v_status = RETOUR, @v_chg_positionprofondeur_depose = OFFSETPROFONDEUR, @v_chg_positionniveau_depose = OFFSETNIVEAU, @v_chg_positioncolonne_depose = OFFSETCOLONNE
											FROM dbo.SPV_OFFSETADRESSE(@v_tag_idtypeagv, @v_adr_idsysteme_depose, @v_adr_idbase_depose, @v_adr_idsousbase_depose, @v_adr_niveau_depose, @v_accesbase, @v_adr_idtypemagasin_depose,
											@v_adr_rayonnage_depose, @v_adr_gerbage_depose, 1, @v_chg_idcharge, @v_hauteur, @v_longueur, @v_chg_position, @v_forcage)
										SET @v_error = @@ERROR
									END
									ELSE
										SET @v_status = @CODE_OK
									IF @v_status = @CODE_OK AND @v_error = 0
									BEGIN
										IF @v_tac_idtache_depose IS NOT NULL
											SELECT @v_tac_positionniveau_depose = TAC_OFFSETNIVEAU + CHG_POSITIONNIVEAU FROM INT_TACHE_MISSION CROSS APPLY INT_CHARGE_VIVANTE WHERE TAC_IDTACHE = @v_tac_idtache_depose AND CHG_IDCHARGE = @v_chg_idcharge
										SET @v_tac_positionniveau_depose = ISNULL(@v_tac_positionniveau_depose, @v_chg_positionniveau_depose)
										SELECT @v_chg_couche_depose = COUCHE, @v_chg_rang_depose = RANG
											FROM dbo.SPV_POSITIONCHARGE(@v_tag_idtypeagv, @v_adr_idsysteme_depose, @v_adr_idbase_depose, @v_adr_idsousbase_depose, @v_accesbase, @v_adr_gerbage_depose, @v_hauteur, @v_longueur, @v_chg_position,
											@v_chg_positionprofondeur_depose, @v_tac_positionniveau_depose)
										UPDATE CHARGE SET CHG_ADR_KEYSYS = @v_adr_idsysteme_depose, CHG_ADR_KEYBASE = @v_adr_idbase_depose, CHG_ADR_KEYSSBASE = @v_adr_idsousbase_depose,
											CHG_ORIENTATION = @v_chg_orientation_depose, CHG_POSX = ISNULL(@v_chg_positioncolonne_depose, 0), CHG_POSY = ISNULL(@v_chg_positionprofondeur_depose, 0), CHG_POSZ = ISNULL(@v_chg_positionniveau_depose, 0),
											CHG_COUCHE = @v_chg_couche_depose, CHG_RANG = @v_chg_rang_depose, CHG_DATELASTOPER = GETDATE(), CHG_POSITION = @v_chg_position
											WHERE CHG_ID = @v_chg_idcharge
										SET @v_error = @@ERROR
										IF @v_error = 0
											SET @v_retour = @CODE_OK
										ELSE
											SET @v_retour = @CODE_KO_SQL
									END
									ELSE
										SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
								END
								ELSE IF (@v_adr_idtypemagasin_depose IN (@TYPE_AGV, @TYPE_INTERFACE)) OR (@v_adr_idtypemagasin_depose = @TYPE_STOCK AND @v_adr_accumulation_depose = 0)
								BEGIN
									IF NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE, INT_MISSION_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme_depose AND CHG_IDBASE = @v_adr_idbase_depose
										AND CHG_IDSOUSBASE = @v_adr_idsousbase_depose AND MIS_IDCHARGE = CHG_IDCHARGE)
									BEGIN
										UPDATE CHARGE SET CHG_ADR_KEYSYS = NULL, CHG_ADR_KEYBASE = NULL, CHG_ADR_KEYSSBASE = NULL, CHG_ACONTROLER = 1
											FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme_depose AND CHG_ADR_KEYBASE = @v_adr_idbase_depose AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase_depose
										SET @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											UPDATE CHARGE SET CHG_ADR_KEYSYS = @v_adr_idsysteme_depose, CHG_ADR_KEYBASE = @v_adr_idbase_depose, CHG_ADR_KEYSSBASE = @v_adr_idsousbase_depose,
												CHG_ORIENTATION = @v_chg_orientation_depose, CHG_POSX = ISNULL(@v_chg_positioncolonne_depose, 0), CHG_POSY = ISNULL(@v_chg_positionprofondeur_depose, 0), CHG_POSZ = ISNULL(@v_chg_positionniveau_depose, 0),
												CHG_COUCHE = NULL, CHG_RANG = NULL, CHG_DATELASTOPER = GETDATE(), CHG_POSITION = @v_chg_position
												WHERE CHG_ID = @v_chg_idcharge
											SET @v_error = @@ERROR
											IF @v_error = 0
												SET @v_retour = @CODE_OK
											ELSE
												SET @v_retour = @CODE_KO_SQL
										END
									END
									ELSE
										SET @v_retour = @CODE_KO_INATTENDU
								END
								ELSE
									SET @v_retour = @CODE_KO_INATTENDU
							END
							ELSE
							BEGIN
								UPDATE CHARGE SET CHG_ADR_KEYSYS = @v_adr_idsysteme_depose, CHG_ADR_KEYBASE = @v_adr_idbase_depose, CHG_ADR_KEYSSBASE = @v_adr_idsousbase_depose,
									CHG_ORIENTATION = @v_chg_orientation_depose, CHG_POSX = ISNULL(@v_chg_positioncolonne_depose, 0), CHG_POSY = ISNULL(@v_chg_positionprofondeur_depose, 0), CHG_POSZ = ISNULL(@v_chg_positionniveau_depose, 0),
									CHG_COUCHE = NULL, CHG_RANG = NULL, CHG_DATELASTOPER = GETDATE(), CHG_POSITION = NULL
									WHERE CHG_ID = @v_chg_idcharge
								SET @v_error = @@ERROR
								IF @v_error = 0
									SET @v_retour = @CODE_OK
								ELSE
									SET @v_retour = @CODE_KO_SQL
							END
						END
						ELSE
							SET @v_retour = @CODE_KO_INATTENDU
					END
					ELSE IF @v_adr_idsysteme_depose IS NULL AND @v_adr_idbase_depose IS NULL AND @v_adr_idsousbase_depose IS NULL
					BEGIN
						UPDATE CHARGE SET CHG_ADR_KEYSYS = NULL, CHG_ADR_KEYBASE = NULL, CHG_ADR_KEYSSBASE = NULL,
							CHG_ORIENTATION = 0, CHG_POSX = 0, CHG_POSY = 0, CHG_POSZ = 0, CHG_COUCHE = NULL, CHG_RANG = NULL, CHG_DATELASTOPER = GETDATE(), CHG_POSITION = NULL
							WHERE CHG_ID = @v_chg_idcharge
						SET @v_error = @@ERROR
						IF @v_error = 0
							SET @v_retour = @CODE_OK
						ELSE
							SET @v_retour = @CODE_KO_SQL
					END
					ELSE
						SET @v_retour = @CODE_KO_ADR_INCONNUE
				END
			END
			ELSE
				SET @v_retour = @v_error
		END
	END
	ELSE
		SET @v_retour = @CODE_KO_INEXISTANT
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


