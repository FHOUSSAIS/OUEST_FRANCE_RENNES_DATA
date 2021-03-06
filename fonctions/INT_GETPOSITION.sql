SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETPOSITION](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge int, @v_position tinyint)
	RETURNS @getposition TABLE (POSITIONPROFONDEUR int NULL, RANG smallint NULL, POSITIONNIVEAU int NULL, COUCHE tinyint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_bas_type_magasin tinyint,
	@v_bas_rayonnage bit,
	@v_bas_gerbage bit,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_face bit,
	@v_chg_idgabarit tinyint,
	@v_chg_idemballage tinyint,
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_offsetprofondeur int,
	@v_offsetniveau int,
	@v_offsetcolonne int,
	@v_couche tinyint,
	@v_rang smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK

	SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_rayonnage = BAS_RAYONNAGE, @v_bas_gerbage = BAS_GERBAGE FROM BASE
		WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
	SELECT @v_chg_hauteur = CHG_HAUTEUR, @v_chg_largeur = CHG_LARGEUR, @v_chg_longueur = CHG_LONGUEUR, @v_chg_face = CHG_FACE,
		@v_chg_idgabarit = CHG_IDGABARIT, @v_chg_idemballage = CHG_IDEMBALLAGE
		FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge
	-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
	SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
		@v_chg_idgabarit, @v_chg_idemballage)
	SELECT @v_status = RETOUR, @v_offsetprofondeur = OFFSETPROFONDEUR, @v_offsetniveau = OFFSETNIVEAU, @v_offsetcolonne = OFFSETCOLONNE	
		FROM dbo.SPV_OFFSETADRESSE(@v_tag_idtypeagv, @v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, NULL, @v_accesbase, @v_bas_type_magasin,
		@v_bas_rayonnage, @v_bas_gerbage, 1, @v_chg_idcharge, @v_hauteur, @v_longueur, @v_position, 0)
	SET @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SELECT @v_couche = COUCHE, @v_rang = RANG
			FROM dbo.SPV_POSITIONCHARGE(@v_tag_idtypeagv, @v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_accesbase, @v_bas_gerbage, @v_hauteur, @v_longueur, @v_position,
			@v_offsetprofondeur, @v_offsetniveau)

		INSERT INTO @getposition SELECT @v_offsetprofondeur, @v_rang, @v_offsetniveau, @v_couche
	END
	RETURN
END







