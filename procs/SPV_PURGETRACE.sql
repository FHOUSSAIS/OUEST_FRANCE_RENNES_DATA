SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_PURGETRACE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de la purge des traces
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_PURGETRACE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_base sysname,
	@v_sql nvarchar(4000),
	@v_parameter nvarchar(4000),
	@v_trace_table sysname,
	@v_trace_id sysname,
	@v_trace_date sysname,
	@v_trace_parametre varchar(128),
	@v_count nvarchar(4000),
	@v_par_val varchar(128)
	
	SET @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
	SET @v_parameter = N'@v_count nvarchar(4000) out'
	SELECT @v_par_val = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'MAXROWCOUNT'
	DECLARE c_trace CURSOR LOCAL FAST_FORWARD FOR SELECT TRACE_TABLE, TRACE_ID, TRACE_DATE, ISNULL(PAR_VAL, 30) FROM (
		SELECT 'TRACE_ATTRIBUTION' TRACE_TABLE, 'TAT_ID' TRACE_ID, 'TAT_DATE' TRACE_DATE, 'PURGE_TRCATTRIB' TRACE_PARAMETRE
		UNION SELECT 'TRACE_CHARGE' TRACE_TABLE, 'TRC_ID' TRACE_ID, 'TRC_DATE' TRACE_DATE, 'PURGE_TRCCHG' TRACE_PARAMETRE
		UNION SELECT 'TRACE_DEFAUT' TRACE_TABLE, 'TRD_ID' TRACE_ID, 'TRD_DATE' TRACE_DATE, 'PURGE_TRCDEFAUT' TRACE_PARAMETRE
		UNION SELECT 'TRACE_ENTREE_SORTIE' TRACE_TABLE, 'TRE_ID' TRACE_ID, 'TRE_DATE' TRACE_DATE, 'PURGE_TRCENTSORT' TRACE_PARAMETRE
		UNION SELECT 'TRACE_EXPLOITATION' TRACE_TABLE, 'TEX_ID' TRACE_ID, 'TEX_DATE' TRACE_DATE, 'PURGE_TRCEXPLOIT' TRACE_PARAMETRE
		UNION SELECT 'TRACE_LOGICIEL' TRACE_TABLE, 'TRL_ID' TRACE_ID, 'TRL_DATE' TRACE_DATE, 'PURGE_TRCLOGICIE' TRACE_PARAMETRE
		UNION SELECT 'TRACE_MISSION' TRACE_TABLE, 'TMI_ID' TRACE_ID, 'TMI_DATE' TRACE_DATE, 'PURGE_TRCMISSION' TRACE_PARAMETRE
		UNION SELECT 'TRACE_ORDRE_AGV' TRACE_TABLE, 'TRO_ID' TRACE_ID, 'TRO_DATE' TRACE_DATE, 'PURGE_TRCORDRE' TRACE_PARAMETRE
		UNION SELECT 'TRACE_SPECIFIQUE' TRACE_TABLE, 'TRS_ID' TRACE_ID, 'TRS_DATE' TRACE_DATE, 'PURGE_TRCSPECIFI' TRACE_PARAMETRE
		UNION SELECT 'TRACE_VARIABLE_AUTOMATE' TRACE_TABLE, 'TRV_ID' TRACE_ID, 'TRV_DATE' TRACE_DATE, 'PURGE_TRCVARAUTO' TRACE_PARAMETRE
		UNION SELECT 'TRACE_ZONE' TRACE_TABLE, 'TRZ_ID' TRACE_ID, 'TRZ_DATE' TRACE_DATE, 'PURGE_TRCZONE' TRACE_PARAMETRE
		) TRACE LEFT OUTER JOIN PARAMETRE ON PAR_NOM = TRACE_PARAMETRE
	OPEN c_trace
	FETCH NEXT FROM c_trace INTO @v_trace_table, @v_trace_id, @v_trace_date, @v_trace_parametre
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @v_trace_table = 'TRACE_LOGICIEL'
			SET @v_trace_table = @v_base + '..' + @v_trace_table

		SET @v_sql = 'DELETE ' + @v_trace_table + ' WHERE ' + @v_trace_date + ' < GETDATE() - ' + @v_trace_parametre
		IF @v_trace_table = 'TRACE_CHARGE'
			SET @v_sql = @v_sql + ' AND NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ID = TRC_IDCHARGE)'
		ELSE IF @v_trace_table = 'TRACE_MISSION'
			SET @v_sql = @v_sql + ' AND NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDMISSION = TMI_IDMISSION)'
		ELSE IF @v_trace_table = 'TRACE_ORDRE_AGV'
			SET @v_sql = @v_sql + ' AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDORDRE = TRO_IDORDRE)'
 		EXEC(@v_sql)
 		
 		SET @v_sql = N'SELECT @v_count = COUNT(*) FROM ' + @v_trace_table
 		EXEC sp_executesql @v_sql, @v_parameter, @v_count = @v_count out
 		IF CONVERT(bigint, @v_count) > CONVERT(bigint, @v_par_val)
 		BEGIN
 			SET @v_sql = 'DELETE ' + @v_trace_table + ' WHERE ' + @v_trace_id + ' IN (SELECT TOP ' + CONVERT(varchar, CONVERT(bigint, @v_count) - CONVERT(bigint, @v_par_val)) + ' ' + @v_trace_id + ' FROM ' + @v_trace_table
			IF @v_trace_table = 'TRACE_CHARGE'
				SET @v_sql = @v_sql + ' WHERE NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ID = TRC_IDCHARGE)'
			ELSE IF @v_trace_table = 'TRACE_MISSION'
				SET @v_sql = @v_sql + ' WHERE NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDMISSION = TMI_IDMISSION)'
			ELSE IF @v_trace_table = 'TRACE_ORDRE_AGV'
				SET @v_sql = @v_sql + ' WHERE NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDORDRE = TRO_IDORDRE)'
 			SET @v_sql = @v_sql + ' ORDER BY ' + @v_trace_id + ')'
	 		EXEC(@v_sql)
 		END
		FETCH NEXT FROM c_trace INTO @v_trace_table, @v_trace_id, @v_trace_date, @v_trace_parametre
	END
	CLOSE c_trace
	DEALLOCATE c_trace
