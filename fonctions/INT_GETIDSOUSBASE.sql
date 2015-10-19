SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDSOUSBASE] (@v_profondeur tinyint, @v_niveau tinyint, @v_colonne tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_colonne + @v_niveau * POWER(2, 8) + @v_profondeur * POWER(2, 16)

END








