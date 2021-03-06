SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VOYANT
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Utilisation des voyants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VOYANT]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_vyt_id int,
	@v_vyt_sql varchar(8000),
	@v_row_count int,
	@TRAD_NO_RESULT int,
	@TRAD_TOO_MUCH_RESULT int
	
SET @TRAD_NO_RESULT = 3249
SET @TRAD_TOO_MUCH_RESULT = 3250
	
CREATE TABLE #RESULT (VYT_ID int, VYT_COULEUR int, VYT_TRADUCTION int)
CREATE TABLE #TMP (VYT_VALEUR int)

DECLARE c_voyant CURSOR LOCAL FOR SELECT VYT_ID, VYT_SQL FROM VOYANT
		WHERE VYT_SQL IS NOT NULL AND EXISTS (SELECT 1 FROM COULEUR WHERE COU_VOYANT = VYT_ID)
OPEN c_voyant
FETCH NEXT FROM c_voyant INTO @v_vyt_id, @v_vyt_sql
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		-- TRY /CATCH block to manage case when @v_vyt_sql is wrong
		INSERT INTO #TMP exec (@v_vyt_sql)

		SELECT @v_row_count = COUNT(*) FROM #TMP
		IF @v_row_count = 0
		BEGIN
			INSERT INTO #RESULT (VYT_ID, VYT_COULEUR, VYT_TRADUCTION)
				VALUES(@v_vyt_id, NULL, @TRAD_NO_RESULT)
		END
		ELSE IF @v_row_count > 1
		BEGIN
			INSERT INTO #RESULT (VYT_ID, VYT_COULEUR, VYT_TRADUCTION)
				VALUES(@v_vyt_id, NULL, @TRAD_TOO_MUCH_RESULT)
		END
		ELSE
		BEGIN
			INSERT INTO #RESULT (VYT_ID, VYT_COULEUR, VYT_TRADUCTION)
				select COU_VOYANT, COU_COULEUR, COU_TRADUCTION FROM COULEUR
					WHERE COU_VOYANT = @v_vyt_id AND COU_VALEUR = (select VYT_VALEUR from #TMP)
		END
	END TRY
	BEGIN CATCH
	END CATCH

	DELETE #TMP
	
	FETCH NEXT FROM c_voyant INTO @v_vyt_id, @v_vyt_sql
END
CLOSE c_voyant
DEALLOCATE c_voyant

select * from #RESULT
DROP TABLE #TMP
DROP TABLE #RESULT


