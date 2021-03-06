SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_GENERATIONSEQUENCE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Génération des séquences
--			  synoptiques
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 13/07/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 02/04/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Suppression de l'utilisation de @@SERVERNAME
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_GENERATIONSEQUENCE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_sequence bit,
	@v_sql varchar(8000),
	@v_base sysname

	BEGIN TRAN
	SELECT @v_error = 0
	SELECT @v_sequence = 0
	IF EXISTS (SELECT 1 FROM SYNOPTIQUE)
		SELECT @v_sequence = 1
	ELSE
	BEGIN
		SELECT @v_base = REPLACE(DB_NAME(), '_DATA', '_LOG')
		CREATE TABLE #TABLE (MAG_ID bigint)
		SELECT @v_sql = 'SELECT MAG_ID FROM ' + @v_base + '.dbo.MAGNETOSCOPE WHERE MAG_ID = (SELECT MAX(MAG_ID) FROM ' + @v_base + '.dbo.MAGNETOSCOPE) AND MAG_TRACE = ''END'''
		INSERT INTO #TABLE EXEC (@v_sql)
		IF NOT EXISTS (SELECT 1 FROM #TABLE)
			SELECT @v_sequence = 1
		DROP TABLE #TABLE
	END
	IF @v_sequence = 1
	BEGIN
		EXEC SPV_IMAGE
		EXEC SPV_TEXTE
		INSERT INTO SYNOPTIQUE (SYN_DATE, SYN_TYPE, SYN_TRACE) VALUES (GETDATE(), 0, 'BEGIN')
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			INSERT INTO SYNOPTIQUE (SYN_DATE, SYN_CATEGORIE, SYN_TYPE, SYN_OBJET, SYN_TRACE) EXEC SPV_SEQUENCE 0
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO SYNOPTIQUE (SYN_DATE, SYN_TYPE, SYN_TRACE) VALUES (GETDATE(), 0, 'END')
				SELECT @v_error = @@ERROR
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN


