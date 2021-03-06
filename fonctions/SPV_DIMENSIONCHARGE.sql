SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DIMENSIONCHARGE
-- Paramètre d'entrée	: @v_chg_hauteur : Hauteur
--			  @v_chg_largeur : Largeur
--			  @v_chg_longueur : Longueur
--			  @v_chg_face : Face
--			  @v_chg_idgabarit : Identifiant gabarit
--			  @v_chg_idemballage : Identifiant emballage
-- Paramètre de sortie	: @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
-- Descriptif		: Calcul des dimensions d'une charge
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DIMENSIONCHARGE](@v_chg_hauteur smallint, @v_chg_largeur smallint, @v_chg_longueur smallint,
	@v_chg_face bit, @v_chg_idgabarit tinyint, @v_chg_idemballage tinyint)
	RETURNS @dimensioncharge TABLE (HAUTEUR smallint NULL, LONGUEUR smallint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_gbr_hauteur smallint,
	@v_gbr_longueur smallint,
	@v_emb_hauteur smallint,
	@v_emb_longueur smallint

	SELECT @v_gbr_hauteur = GBR_HAUTEUR, @v_gbr_longueur = CASE @v_chg_face WHEN 0 THEN GBR_LONGUEUR ELSE GBR_LARGEUR END FROM GABARIT WHERE GBR_ID = @v_chg_idgabarit
	SELECT @v_emb_hauteur = EMB_HAUTEUR, @v_emb_longueur = CASE @v_chg_face WHEN 0 THEN EMB_LONGUEUR ELSE EMB_LARGEUR END FROM EMBALLAGE WHERE EMB_ID = @v_chg_idemballage
	SET @v_hauteur = ISNULL(@v_chg_hauteur, ISNULL(@v_gbr_hauteur, @v_emb_hauteur))
	SET @v_longueur = CASE @v_chg_face WHEN 0 THEN ISNULL(@v_chg_longueur, 0) ELSE ISNULL(@v_chg_largeur, 0) END
	SET @v_longueur = CASE WHEN @v_longueur > ISNULL(@v_gbr_longueur, 0) THEN @v_longueur ELSE ISNULL(@v_gbr_longueur, 0) END
	SET @v_longueur = CASE WHEN @v_longueur > ISNULL(@v_emb_longueur, 0) THEN @v_longueur ELSE ISNULL(@v_emb_longueur, 0) END
	
	INSERT INTO @dimensioncharge SELECT @v_hauteur, @v_longueur
	RETURN
END

