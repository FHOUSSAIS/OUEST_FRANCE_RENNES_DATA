SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: LIB_SQLTRADUCTION
-- Paramètre d'entrée	: @v_sql_source : SQL à modifier
--			  @v_lan_id : Identifiant langue
-- Paramètre de sortie	: @v_sql_destination : SQL modifié
-- Descriptif		: Modification dynamique des requêtes utilisant la langue
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 28/01/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_SQLTRADUCTION]
	@v_sql_source varchar(8000),
	@v_lan_id varchar(3),
	@v_sql_destination varchar(8000) out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_sql_temp varchar(8000),
	@v_i int,
	@v_j int,
	@v_p int,
	@v_q int,
	@v_r int

	SELECT @v_sql_destination = ''
	SELECT @v_p = CHARINDEX('LIB_LANGUE', @v_sql_source)
	IF @v_p IS NOT NULL
	BEGIN
		WHILE @v_p <> 0
		BEGIN
			SELECT @v_sql_temp = SUBSTRING(@v_sql_source, @v_p, LEN(@v_sql_source) - @v_p + 1)
			SELECT @v_i = 1
			SELECT @v_j = 0
			SELECT @v_q = 0
			SELECT @v_r = 0
			WHILE @v_i <= LEN(@v_sql_temp)
			BEGIN
				IF SUBSTRING(@v_sql_temp, @v_i, 1) = '='
				BEGIN
					IF @v_q = 0
						SELECT @v_q = @v_i
				END
				ELSE IF SUBSTRING(@v_sql_temp, @v_i, 1) = ''''
				BEGIN
					IF @v_j = 0
						SELECT @v_j = 1
					ELSE
					BEGIN
						SELECT @v_r = @v_i
						BREAK
					END
				END
				SELECT @v_i = @v_i + 1
			END
			IF ((@v_q <> 0) AND (@v_r <> 0))
			BEGIN
				IF LEN(REPLACE(SUBSTRING(@v_sql_temp, @v_q, @v_r - @v_q + 1), ' ', '')) = 6
				BEGIN
					SELECT @v_sql_destination = @v_sql_destination + SUBSTRING(@v_sql_source, 1, @v_p + @v_q - 1) + ' ''' + @v_lan_id + ''''
					SELECT @v_sql_source = SUBSTRING(@v_sql_source, @v_p + @v_r, LEN(@v_sql_source) - @v_p - @v_r + 1)
				END
				ELSE
				BEGIN
					SELECT @v_sql_destination = @v_sql_destination + SUBSTRING(@v_sql_source, 1, @v_p + 9)
					SELECT @v_sql_source = SUBSTRING(@v_sql_source, @v_p + 10, LEN(@v_sql_source) - @v_p - 9)
				END
				SELECT @v_p = CHARINDEX('LIB_LANGUE', @v_sql_source)
			END
			ELSE
				BREAK
		END
	END
	SELECT @v_sql_destination = @v_sql_destination + @v_sql_source
	SELECT @v_sql_source = @v_sql_destination
	SELECT @v_sql_destination = ''
	SELECT @v_p = CHARINDEX('GETLIBELLE', @v_sql_source)
	IF @v_p IS NOT NULL
	BEGIN
		WHILE @v_p <> 0
		BEGIN
			SELECT @v_sql_temp = SUBSTRING(@v_sql_source, @v_p, LEN(@v_sql_source) - @v_p + 1)
			SELECT @v_i = 1
			SELECT @v_j = 0
			SELECT @v_q = 0
			SELECT @v_r = 0
			WHILE @v_i <= LEN(@v_sql_temp)
			BEGIN
				IF SUBSTRING(@v_sql_temp, @v_i, 1) = ','
					SELECT @v_q = @v_i
				ELSE IF SUBSTRING(@v_sql_temp, @v_i, 1) = '('
					SELECT @v_j = @v_j + 1
				ELSE IF SUBSTRING(@v_sql_temp, @v_i, 1) = ')'
				BEGIN
					SELECT @v_j = @v_j - 1
					IF @v_j = 0
					BEGIN
						SELECT @v_r = @v_i
						BREAK
					END
				END
				SELECT @v_i = @v_i + 1
			END
			IF ((@v_q <> 0) AND (@v_r <> 0))
			BEGIN
				SELECT @v_sql_destination = @v_sql_destination + SUBSTRING(@v_sql_source, 1, @v_p + @v_q - 1) + ' ''' + @v_lan_id + ''')'
				SELECT @v_sql_source = SUBSTRING(@v_sql_source, @v_p + @v_r, LEN(@v_sql_source) - @v_p - @v_r + 1)
				SELECT @v_p = CHARINDEX('GETLIBELLE', @v_sql_source)
			END
			ELSE
				BREAK
		END
	END
	SELECT @v_sql_destination = @v_sql_destination + @v_sql_source

