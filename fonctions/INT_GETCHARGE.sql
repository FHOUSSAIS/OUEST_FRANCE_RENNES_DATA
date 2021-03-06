SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETCHARGE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_accesbase bit)
	RETURNS int
AS
BEGIN
	
-- Déclaration des variables
DECLARE
	@v_chg_idcharge int,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Définition des constantes
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4

	SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION
		FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
	IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
		SELECT TOP 1 @v_chg_idcharge = CHG_IDCHARGE FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase ORDER BY CASE ISNULL(@v_accesbase, 0) WHEN 0 THEN CHG_POSITIONPROFONDEUR ELSE -CHG_POSITIONPROFONDEUR END, CHG_COUCHE DESC, CHG_POSITIONNIVEAU DESC
	ELSE IF ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
		SELECT TOP 1 @v_chg_idcharge = CHG_IDCHARGE FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase
	RETURN @v_chg_idcharge

END








