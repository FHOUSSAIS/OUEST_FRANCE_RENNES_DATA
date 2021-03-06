SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETSTOCKABILITE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge int, @v_position tinyint)
	RETURNS bit
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_stockabilite bit,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_face bit,
	@v_chg_idgabarit tinyint,
	@v_chg_idemballage tinyint,
	@v_hauteur smallint,
	@v_longueur smallint

	SET @v_stockabilite = 0
	SELECT @v_chg_hauteur = CHG_HAUTEUR, @v_chg_largeur = CHG_LARGEUR, @v_chg_longueur = CHG_LONGUEUR, @v_chg_face = CHG_FACE,
		@v_chg_idgabarit = CHG_IDGABARIT, @v_chg_idemballage = CHG_IDEMBALLAGE
		FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge
	-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
	SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
		@v_chg_idgabarit, @v_chg_idemballage)
	SELECT @v_stockabilite = dbo.SPV_GETCHARGEADRESSE(@v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_tag_idtypeagv, @v_accesbase, @v_chg_idcharge,
		@v_hauteur, @v_chg_largeur, @v_longueur, @v_position, 0)
	RETURN @v_stockabilite

END







