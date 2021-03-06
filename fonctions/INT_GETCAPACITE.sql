SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETCAPACITE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_hauteur smallint, @v_largeur smallint, @v_longueur smallint, @v_face bit, @v_position tinyint)
	RETURNS smallint
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_capacite smallint

	SET @v_capacite = 0
	SET @v_longueur = CASE @v_face WHEN 0 THEN @v_longueur ELSE @v_largeur END
	SELECT @v_capacite = dbo.SPV_GETCHARGEADRESSE(@v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_tag_idtypeagv, @v_accesbase, NULL,
		@v_hauteur, @v_largeur, @v_longueur, @v_position, 0)
	RETURN @v_capacite

END


