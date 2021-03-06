SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDBASE] (@v_tmg_idtypemagasin tinyint, @v_magasin smallint, @v_allee tinyint, @v_couloir smallint, @v_cote tinyint, @v_rack tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_rack + @v_cote * POWER(2, 8) + @v_couloir * POWER(2, 16)
		+ @v_allee * POWER(CONVERT(bigint, 2), 32) + @v_magasin * POWER(CONVERT(bigint, 2), 40)
		+ @v_tmg_idtypemagasin * POWER(CONVERT(bigint, 2), 56)

END






