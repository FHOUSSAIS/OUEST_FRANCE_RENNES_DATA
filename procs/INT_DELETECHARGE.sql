SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_DELETECHARGE]
	@v_chg_idcharge int
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
	@v_chg_idsysteme bigint,
	@v_chg_idbase bigint,
	@v_chg_idsousbase bigint,
	@v_chg_positionprofondeur int,
	@v_chg_positionniveau int,
	@v_chg_rang smallint,
	@v_chg_couche tinyint,
	@v_longueur smallint,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit,
	@v_bas_rayonnage bit,
	@v_bas_gerbage bit,
	@v_chg_rang_min smallint,
	@v_chg_rang_max smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_INEXISTANT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_CHARGE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_INEXISTANT = 4
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_CHARGE = 19
	SET @TYPE_AGV = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4

-- Initialisation des variables
	SET @v_transaction = 'DELETECHARGE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la charge
	IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_chg_idcharge)
		BEGIN
			SELECT @v_chg_idsysteme = CHG_IDSYSTEME, @v_chg_idbase = CHG_IDBASE, @v_chg_idsousbase = CHG_IDSOUSBASE, @v_chg_positionprofondeur = CHG_POSITIONPROFONDEUR,
				@v_chg_positionniveau = CHG_POSITIONNIVEAU, @v_chg_rang = CHG_RANG, @v_chg_couche = CHG_COUCHE, @v_longueur = LONGUEUR, @v_bas_type_magasin = ADR_IDTYPEMAGASIN, @v_bas_accumulation = ADR_ACCUMULATION,
				@v_bas_rayonnage = ADR_RAYONNAGE, @v_bas_gerbage = ADR_GERBAGE FROM INT_CHARGE_VIVANTE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE,
				CHG_IDGABARIT, CHG_IDEMBALLAGE), INT_ADRESSE WHERE CHG_IDCHARGE = @v_chg_idcharge and ADR_IDSYSTEME = CHG_IDSYSTEME
				AND ADR_IDBASE = CHG_IDBASE AND ADR_IDSOUSBASE = CHG_IDSOUSBASE
			-- Contrôle de l'accessibilité de la charge
			IF NOT ((@v_bas_type_magasin IS NULL) OR (@v_bas_type_magasin IN (@TYPE_INTERFACE, @TYPE_AGV)) OR (@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 0))
			BEGIN
				SELECT @v_chg_rang_min = MIN(CHG_RANG), @v_chg_rang_max = MAX(CHG_RANG) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_chg_idsysteme
					AND CHG_IDBASE = @v_chg_idbase AND CHG_IDSOUSBASE = @v_chg_idsousbase AND CHG_COUCHE = @v_chg_couche
				IF ((@v_bas_type_magasin = @TYPE_PREPARATION) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 0))
				BEGIN
					IF @v_chg_rang NOT IN (@v_chg_rang_min, @v_chg_rang_max)
						SET @v_error = @CODE_KO_CHARGE
				END
				ELSE IF @v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 1
				BEGIN
					IF NOT (@v_chg_rang IN (@v_chg_rang_min, @v_chg_rang_max) AND @v_chg_positionniveau = (SELECT MAX(CHG_POSITIONNIVEAU) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_chg_idsysteme AND CHG_IDBASE = @v_chg_idbase
						AND CHG_IDSOUSBASE = @v_chg_idsousbase AND CHG_RANG = @v_chg_rang))
					SET @v_error = @CODE_KO_CHARGE
				END
				ELSE IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE,
					CHG_IDGABARIT, CHG_IDEMBALLAGE) WHERE CHG_IDCHARGE <> @v_chg_idcharge AND CHG_IDSYSTEME = @v_chg_idsysteme
					AND CHG_IDBASE = @v_chg_idbase AND CHG_IDSOUSBASE = @v_chg_idsousbase
					AND (CHG_POSITIONPROFONDEUR + LONGUEUR) < @v_chg_positionprofondeur)
					AND EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE <> @v_chg_idcharge AND CHG_IDSYSTEME = @v_chg_idsysteme
					AND CHG_IDBASE = @v_chg_idbase AND CHG_IDSOUSBASE = @v_chg_idsousbase
					AND CHG_POSITIONPROFONDEUR > (@v_chg_positionprofondeur + @v_longueur))
					SET @v_error = @CODE_KO_CHARGE
			END
			IF @v_error = 0
			BEGIN
				UPDATE CHARGE SET CHG_TODESTROY = 1 WHERE CHG_ID = @v_chg_idcharge
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = @CODE_KO_SQL
			END
			ELSE
				SET @v_retour = @v_error
		END
		ELSE
			SET @v_retour = @CODE_KO_EXISTANT
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


