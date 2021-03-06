SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SECTEUR
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_sec_id : Identifiant
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des secteurs
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

CREATE PROCEDURE [dbo].[CFG_SECTEUR]
	@v_action smallint,
	@v_sec_id tinyint out,
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
	@v_error smallint,
	@v_cli_id tinyint,
	@v_sit_id tinyint,
	@v_sys_systeme bigint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		SELECT @v_sec_id = 1
		IF NOT EXISTS (SELECT 1 FROM SECTEUR WHERE SEC_ID = @v_sec_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO SECTEUR (SEC_ID, SEC_IDTRADUCTION) VALUES (@v_sec_id, @v_tra_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT TOP 1 @v_cli_id = CLI_ID FROM CLIENT
					SELECT TOP 1 @v_sit_id = SIT_ID FROM SITE
					IF @v_cli_id IS NOT NULL AND @v_sit_id IS NOT NULL
					BEGIN
						SELECT @v_sys_systeme = dbo.INT_GETIDSYSTEME(@v_cli_id, @v_sit_id, @v_sec_id)
						INSERT INTO SYSTEME (SYS_SYSTEME, SYS_CLIENT, SYS_SITE, SYS_SECTEUR) VALUES (@v_sys_systeme, @v_cli_id, @v_sit_id, @v_sec_id)
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = 0
					END
					ELSE
						SELECT @v_retour = 0
				END
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM SYSTEME, BASE WHERE SYS_SECTEUR = @v_sec_id AND BAS_SYSTEME = SYS_SYSTEME)
		BEGIN
			DELETE SYSTEME
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE SECTEUR WHERE SEC_ID = @v_sec_id
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

