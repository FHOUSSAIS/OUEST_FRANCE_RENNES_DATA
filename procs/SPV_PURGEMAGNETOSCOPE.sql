SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_PURGEMAGNETOSCOPE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de la purge des traces magnétoscope
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_PURGEMAGNETOSCOPE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_par_val varchar(128),
	@v_sql varchar(8000),
	@v_base sysname

	SELECT @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
	SELECT @v_par_val = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'PURGE_TRCMAGNETO'
	SELECT @v_sql = 'DELETE ' + @v_base + '.dbo.MAGNETOSCOPE WHERE MAG_DATE < GETDATE() - CONVERT(int, ' + @v_par_val + ')'
	EXEC (@v_sql)


