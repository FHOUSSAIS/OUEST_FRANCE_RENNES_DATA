SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_POSITIONCHARGE
-- Paramètre d'entrée	: @v_tag_idtypeagv : Identifiant type AGV
--			  @v_adr_idsysteme : Clé système
--			  @v_adr_idbase : Clé base
--			  @v_adr_idsousbase : Clé sous-base
--			  @v_accesbase : Côté accès base
--			  @v_bas_gerbage : Gerbage
--			  @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  @v_chg_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
-- Paramètre de sortie	: PROFONDEUR : Offset profondeur
--			  NIVEAU : Offset niveau
--			  COUCHE : Couche
--			  RANG : Rang
-- Descriptif		: Calcul des positions d'une charge
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_POSITIONCHARGE](@v_tag_idtypeagv tinyint, @v_adr_idsysteme bigint, @v_adr_idbase bigint,
	@v_adr_idsousbase bigint, @v_accesbase bit, @v_bas_gerbage bit, @v_hauteur smallint, @v_longueur smallint, @v_chg_position tinyint,
	@v_chg_positionprofondeur smallint, @v_chg_positionniveau smallint)
	RETURNS @positioncharge TABLE (PROFONDEUR smallint NULL, NIVEAU smallint NULL, COUCHE tinyint NULL, RANG smallint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_tag_fourche smallint,
	@v_couche tinyint,
	@v_rang smallint,
	@v_delta smallint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint

-- Définition des constantes
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2

	-- Vérification des informations AGV
	IF @v_tag_idtypeagv IS NULL
		SELECT TOP 1 @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_TYPE_OUTIL IN (1, 2) ORDER BY TAG_FOURCHE DESC
	ELSE
		SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		IF @v_longueur < @v_tag_fourche AND ISNULL(@v_chg_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
			SET @v_delta = CASE @v_chg_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
				WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_longueur END
		ELSE
			SET @v_delta = 0
		IF ISNULL(@v_accesbase, 0) = 0
			SET @v_chg_positionprofondeur = @v_chg_positionprofondeur + @v_delta
		ELSE
			SET @v_chg_positionprofondeur = @v_chg_positionprofondeur - @v_longueur - @v_delta
	END	
	IF @v_bas_gerbage = 1
		SET @v_couche = 1
	ELSE
		SELECT @v_couche = STR_COUCHE FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme
			AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase AND STR_COTE = @v_chg_positionniveau
	IF @v_bas_gerbage = 0
		SELECT @v_rang = ISNULL(CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN MAX(CHG_RANG) + 1 ELSE MIN(CHG_RANG) - 1 END, 1) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme
			AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche)
			SELECT TOP 1 @v_rang = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN MAX(CHG_RANG) ELSE MIN(CHG_RANG) END
				+ CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN 1 ELSE -1 END * CASE WHEN @v_chg_positionniveau = 0 THEN 1 ELSE 0 END
				FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme
				AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche
		ELSE
			SET @v_rang = 1
	END

	INSERT INTO @positioncharge SELECT @v_chg_positionprofondeur, @v_chg_positionniveau, @v_couche, @v_rang
	RETURN
END

