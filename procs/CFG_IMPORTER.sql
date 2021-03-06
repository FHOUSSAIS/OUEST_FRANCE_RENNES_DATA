SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_IMPORTER
-- Paramètre d'entrées	: @v_file : Fichier source de l'import
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Importation de la configuration
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 3.00
-- Date			: 23/05/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 4.00
-- Date			: 26/09/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Vérification de l'accessibilité du fichier
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_IMPORTER]
	@v_file varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_commande varchar(255),
	@v_serveur sysname,
	@v_base sysname,
	@v_exists int

	SELECT @v_retour = 113
	SELECT @v_error = 0
	SELECT @v_exists = 0
	EXEC master.dbo.xp_fileexist @v_file, @v_exists out
	IF @v_exists = 1
	BEGIN
		SELECT @v_serveur = @@SERVERNAME
		SELECT @v_base = DB_NAME()
		SELECT @v_commande = 'sqlcmd -S ' + @v_serveur + ' -E -d ' + @v_base + ' -i "' + @v_file + '"'
		EXEC @v_retour = master.dbo.xp_cmdshell @v_commande, no_output
		SELECT @v_error = @@ERROR
		IF ((@v_error = 0) AND (@v_retour <> 0))
			SELECT @v_error = @v_retour
	END
	ELSE
		SELECT @v_retour = 907
	RETURN @v_error

