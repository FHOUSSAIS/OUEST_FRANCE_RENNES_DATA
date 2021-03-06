SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_CLIENT
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_cli_id : Identifiant
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des clients
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 22/07/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 01/02/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Système d'adressage
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_CLIENT]
	@v_action smallint,
	@v_cli_id tinyint out,
	@v_lan_id varchar(3),
	@v_tra_id int out,
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_cli_id = 1
		IF NOT EXISTS (SELECT 1 FROM CLIENT WHERE CLI_ID = @v_cli_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO CLIENT (CLI_ID, CLI_IDTRADUCTION) VALUES (@v_cli_id, @v_tra_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM SYSTEME, BASE WHERE SYS_CLIENT = @v_cli_id AND BAS_SYSTEME = SYS_SYSTEME)
		BEGIN
			DELETE SYSTEME
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE CLIENT WHERE CLI_ID = @v_cli_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

