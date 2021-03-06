SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_PURGESYNOPTIQUE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de la purge des traces synoptique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_PURGESYNOPTIQUE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_sql nvarchar(4000),
	@v_base sysname,
	@v_date nvarchar(4000)

	BEGIN TRAN
	SET @v_error = 0
	SET @v_date = GETDATE()
	SET @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
	SET @v_sql = N'INSERT INTO ' + @v_base + '.dbo.MAGNETOSCOPE (MAG_DATE, MAG_CATEGORIE, MAG_TYPE, MAG_OBJET, MAG_TRACE)
		SELECT SYN_DATE, SYN_CATEGORIE, SYN_TYPE, SYN_OBJET, SYN_TRACE FROM SYNOPTIQUE
		WHERE DATEDIFF(second, SYN_DATE, @v_date) > 600 ORDER BY SYN_ID'
	EXEC sp_executesql @v_sql, N'@v_date nvarchar(4000)', @v_date = @v_date
	SET @v_error = @@ERROR
	IF @v_error = 0
	BEGIN
		DELETE SYNOPTIQUE WHERE DATEDIFF(second, SYN_DATE, @v_date) > 600
		SET @v_error = @@ERROR
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN


