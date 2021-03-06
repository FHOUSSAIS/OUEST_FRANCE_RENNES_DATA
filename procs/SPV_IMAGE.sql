SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_IMAGE
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Calcul de la valeur des images dynamiques
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 20/10/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 28/11/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Optimisation du calcul des valeurs
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_IMAGE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_img_id int,
	@v_img_sql varchar(8000),
	@v_charindex int,
	@v_sql varchar(8000)

	SELECT @v_sql = ''
	CREATE TABLE #TMP (TMP_ID integer, TMP_VALEUR varchar(32))
	DECLARE c_image CURSOR LOCAL FOR SELECT IMG_ID, IMG_SQL FROM IMAGE WHERE IMG_SQL IS NOT NULL AND IMG_TYPE = 0 AND IMG_VISIBLE = 1
	OPEN c_image
	FETCH NEXT FROM c_image INTO @v_img_id, @v_img_sql
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @v_charindex = CHARINDEX('SELECT', @v_img_sql)
		IF @v_charindex > 0
		BEGIN
			SELECT @v_sql = 'SELECT ' + CONVERT(varchar, @v_img_id) + ', ' + SUBSTRING(@v_img_sql, @v_charindex + 7, LEN(@v_img_sql) - 7)
			INSERT INTO #TMP (TMP_ID, TMP_VALEUR) EXEC (@v_sql)
		END
		FETCH NEXT FROM c_image INTO @v_img_id, @v_img_sql
	END
	CLOSE c_image
	DEALLOCATE c_image
	UPDATE IMAGE SET IMG_VALEUR = (SELECT TOP 1 TMP_VALEUR FROM #TMP WHERE TMP_ID = IMG_ID)
	DROP TABLE #TMP


