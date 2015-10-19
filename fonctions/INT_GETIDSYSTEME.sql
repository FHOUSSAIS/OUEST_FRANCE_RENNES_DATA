SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDSYSTEME] (@v_cli_idclient tinyint, @v_sit_idsite tinyint, @v_sec_idsecteur tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_sec_idsecteur + @v_sit_idsite * POWER(2, 8) + @v_cli_idclient * POWER(2, 16)

END




