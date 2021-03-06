SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_TEXTE
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Calcul de la valeur des textes dynamiques
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_TEXTE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_txt_id int,
	@v_txt_sql varchar(8000),
	@v_charindex int,
	@v_sql varchar(8000)

	SELECT @v_sql = ''
	CREATE TABLE #TMP (TMP_ID integer, TMP_VALEUR varchar(128))
	DECLARE c_texte CURSOR LOCAL FOR SELECT TXT_ID, TXT_SQL FROM TEXTE WHERE TXT_SQL IS NOT NULL AND TXT_TYPE = 0 AND TXT_VISIBLE = 1
	OPEN c_texte
	FETCH NEXT FROM c_texte INTO @v_txt_id, @v_txt_sql
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @v_charindex = CHARINDEX('SELECT', @v_txt_sql)
		IF @v_charindex > 0
		BEGIN
			SELECT @v_sql = 'SELECT ' + CONVERT(varchar, @v_txt_id) + ', ' + SUBSTRING(@v_txt_sql, @v_charindex + 7, LEN(@v_txt_sql) - 7)
			INSERT INTO #TMP (TMP_ID, TMP_VALEUR) EXEC (@v_sql)
		END
		FETCH NEXT FROM c_texte INTO @v_txt_id, @v_txt_sql
	END
	CLOSE c_texte
	DEALLOCATE c_texte
	UPDATE TEXTE SET TXT_VALEUR = (SELECT TOP 1 TMP_VALEUR FROM #TMP WHERE TMP_ID = TXT_ID)
	DROP TABLE #TMP


