SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_MAGNETOSCOPE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_debut : Horodate de début
--			  @v_fin : Horodate de fin
-- Paramètre de sortie	: 
-- Descriptif		: Exportation des données magnétoscopes
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_MAGNETOSCOPE]
	@v_action tinyint,
	@v_debut varchar(17),
	@v_fin varchar(17)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_sql varchar(8000),
	@v_base sysname,
	@v_lan_id varchar(3),
	@v_section tinyint,
	@v_min bigint,
	@v_max bigint

	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF
	IF @v_action = 0
	BEGIN 
		SELECT @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
		CREATE TABLE #MAGNETOSCOPE (SECTION varchar(4), IDENTIFIANT bigint, TYPE tinyint, DATA varchar(8000))
		SELECT @v_sql = 'SELECT MAX(MAG_ID) FROM ' + @v_base + '.dbo.MAGNETOSCOPE WHERE MAG_DATE <= CONVERT(datetime, ''' + @v_debut + ''') AND MAG_TYPE = 0 AND MAG_TRACE = ''BEGIN'''
		CREATE TABLE #INDEX (MAG_ID bigint)
		INSERT INTO #INDEX (MAG_ID) EXEC (@v_sql)
		SELECT @v_min = MAG_ID FROM #INDEX
		IF @v_min IS NOT NULL
		BEGIN
			DELETE #INDEX
			SELECT @v_sql = 'SELECT MAX(MAG_ID) FROM ' + @v_base + '.dbo.MAGNETOSCOPE WHERE MAG_DATE <= CONVERT(datetime, ''' + @v_fin + ''')'
			INSERT INTO #INDEX (MAG_ID) EXEC (@v_sql)
			SELECT @v_max = MAG_ID FROM #INDEX
			IF @v_max IS NOT NULL
			BEGIN
				SELECT @v_sql = 'SELECT ''2'', MAG_ID, CASE MAG_TYPE WHEN 1 THEN 2 ELSE CASE MAG_TRACE WHEN ''BEGIN'' THEN 0 WHEN ''END'' THEN 0 ELSE 1 END END, '
					+ 'CONVERT(varchar, MAG_DATE, 103) + '' '' + CONVERT(varchar, MAG_DATE, 114) + CHAR(11) + '
					+ 'CONVERT(varchar, MAG_CATEGORIE) + CHAR(11) + '
					+ 'CONVERT(varchar, MAG_OBJET) + CHAR(11) + '
					+ 'REPLACE(MAG_TRACE, CHAR(10), CHAR(9))'
					+ ' FROM ' + @v_base + '.dbo.MAGNETOSCOPE WHERE MAG_ID BETWEEN ' + CONVERT(varchar, @v_min) + ' AND ' + CONVERT(varchar, @v_max)
					+ ' ORDER BY MAG_ID'
				INSERT INTO #MAGNETOSCOPE (SECTION, IDENTIFIANT, TYPE, DATA) EXEC (@v_sql)
				IF EXISTS (SELECT 1 FROM #MAGNETOSCOPE)
				BEGIN
					INSERT INTO #MAGNETOSCOPE (SECTION, IDENTIFIANT, TYPE, DATA) SELECT '0', 1, NULL, PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'TRONCON'
					INSERT INTO #MAGNETOSCOPE (SECTION, IDENTIFIANT, TYPE, DATA) SELECT '0', 2, NULL, CONVERT(varchar, MIN(IDENTIFIANT))
						FROM #MAGNETOSCOPE WHERE TYPE IN (1, 2)
					INSERT INTO #MAGNETOSCOPE (SECTION, IDENTIFIANT, TYPE, DATA) SELECT '0', 3, NULL, CONVERT(varchar, MAX(IDENTIFIANT))
						FROM #MAGNETOSCOPE WHERE TYPE IN (1, 2)
					INSERT INTO #MAGNETOSCOPE (SECTION, IDENTIFIANT, TYPE, DATA) SELECT '1', IDENTIFIANT, NULL, DATA
						FROM #MAGNETOSCOPE WHERE TYPE = 0 ORDER BY IDENTIFIANT
				END
			END
		END
		DROP TABLE #INDEX
		SELECT SECTION, IDENTIFIANT, CASE TYPE WHEN 1 THEN 0 WHEN 2 THEN 1 ELSE TYPE END TYPE, DATA FROM #MAGNETOSCOPE ORDER BY SECTION, IDENTIFIANT
		DROP TABLE #MAGNETOSCOPE
	END
	ELSE IF @v_action = 1
	BEGIN
		SELECT LIB_LANGUE, LIB_TRADUCTION, CASE LTRIM(RTRIM(LIB_LIBELLE)) WHEN '' THEN dbo.INT_GETLIBELLE(LIB_TRADUCTION, (SELECT PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE')) ELSE LIB_LIBELLE END LIB_LIBELLE
				FROM LANGUE, LIBELLE WHERE LAN_ACTIF = 1 AND LIB_LANGUE = LAN_ID
	END


