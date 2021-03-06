SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_EXECUTEREGLEZONE
-- Paramètre d'entrée	: @v_iag_id : Identifiant de l'AGV
--			  @v_sql : SQL
--			  @v_variable : Liste de toutes les variables de la règle
--			  format : 'V1,V2,V3,...,Vn,'
--			  @v_critere : Liste de tous les critÞres de la règle
--			  format : 'C1,C2,C3,...,Cn,'
-- Paramètre de sortie	:
-- Descriptif		: Exécution d'une règle d'attribution de zone
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EXECUTEREGLEZONE] @v_iag_id tinyint, @v_sql varchar(8000), @v_variable varchar(4000), @v_critere varchar(4000)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- dÚclaration des variables
DECLARE
	@v_select varchar(8000),
	@v_idcritere integer,
	@v_idvariable integer,
	@v_charindex int

	IF EXISTS (SELECT 1 FROM ZONE WHERE ZNE_TYPE = 1)
	BEGIN
		IF ((@v_critere IS NOT NULL) OR (@v_variable IS NOT NULL))
		BEGIN
			SELECT @v_select = 'SELECT *'
			-- Modification de la requête avec les critères utilisés
			IF @v_critere IS NOT NULL
			BEGIN
				SELECT @v_charindex = CHARINDEX(',', @v_critere)
				WHILE @v_charindex > 1
				BEGIN
					SELECT @v_idcritere = SUBSTRING(@v_critere, 1, @v_charindex - 1)
					IF EXISTS (SELECT 1 FROM CRITERE WHERE CRI_IDCRITERE = @v_idcritere AND CRI_DONNEE = 1)
						SELECT @v_select = @v_select + ', (SELECT CONVERT(bigint, CRZ_VALUE) FROM CRITERE_ZONE WHERE CRZ_IDCRITERE = '
							+ CONVERT(varchar, @v_idcritere) + ' AND CRZ_IDZONE = ZNE_ID) CRITERE' + REPLACE(CONVERT(varchar, @v_idcritere),'-', '_') + 'C'
					ELSE					
						SELECT @v_select = @v_select + ', (SELECT CRZ_VALUE FROM CRITERE_ZONE WHERE CRZ_IDCRITERE = '
							+ CONVERT(varchar, @v_idcritere) + ' AND CRZ_IDZONE = ZNE_ID) CRITERE' + REPLACE(CONVERT(varchar, @v_idcritere),'-', '_') + 'C'
					SELECT @v_critere = SUBSTRING(@v_critere, @v_charindex + 1, LEN(@v_critere) - @v_charindex)
					SELECT @v_charindex = CHARINDEX(',', @v_critere)
				END
			END
			-- Modification de la requête avec les variables utilisées
			IF @v_variable IS NOT NULL
			BEGIN
				SELECT @v_charindex = CHARINDEX(',', @v_variable)
				WHILE @v_charindex > 1
				BEGIN
					SELECT @v_idvariable = SUBSTRING(@v_variable, 1, @v_charindex - 1)
					SELECT @v_select = @v_select + ', (SELECT VAR_VALUE FROM VARIABLE WHERE VAR_ID = '
						+ CONVERT(varchar, @v_idvariable) + ') VARIABLE' + REPLACE(CONVERT(varchar, @v_idvariable),'-', '_') + 'V'
					SELECT @v_variable = SUBSTRING(@v_variable, @v_charindex + 1, LEN(@v_variable) - @v_charindex)
					SELECT @v_charindex = CHARINDEX(',', @v_variable)
				END
			END
			SELECT @v_select = @v_select + ' FROM ZONE WHERE ZNE_TYPE = 1'
			IF CHARINDEX('ORDER BY', @v_sql) = 1
				EXEC ('SELECT TOP 1 ZNE_ID FROM (' + @v_select + ') Tmp ' + @v_sql)
			ELSE
				EXEC ('SELECT TOP 1 ZNE_ID FROM (' + @v_select + ') Tmp WHERE ' + @v_sql)
		END
		ELSE
		BEGIN
			IF @v_sql IS NULL
				SELECT @v_sql = 'SELECT TOP 1 ZNE_ID FROM ZONE WHERE ZNE_TYPE = 1'
			ELSE
			BEGIN
				IF CHARINDEX('ORDER BY', @v_sql) = 1
					SELECT @v_sql = 'SELECT TOP 1 ZNE_ID FROM ZONE WHERE ZNE_TYPE = 1 ' + @v_sql
				ELSE
					SELECT @v_sql = 'SELECT TOP 1 ZNE_ID FROM ZONE WHERE ZNE_TYPE = 1 AND ' + @v_sql
			END
			EXEC (@v_sql)
		END
	END
	ELSE
		SELECT NULL ZNE_ID


