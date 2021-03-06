SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_LANGUE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion de la langue
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 18/05/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 24/03/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Gestion des noms de langue en standard
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_LANGUE]
	@v_action smallint,
	@v_lan_id varchar(3),
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
		IF NOT EXISTS (SELECT 1 FROM LANGUE WHERE LAN_ID = @v_lan_id AND LAN_ACTIF = 1)
		BEGIN
			UPDATE LANGUE SET LAN_ACTIF = 1 WHERE LAN_ID = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO LIBELLE (LIB_TRADUCTION, LIB_LANGUE, LIB_LIBELLE) SELECT LIB_TRADUCTION, @v_lan_id, ''
					FROM LIBELLE WHERE LIB_LANGUE = 'FRA'
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
		IF NOT EXISTS (SELECT 1 FROM UTILISATEUR WHERE UTI_LANGUE = @v_lan_id)
		BEGIN
			DELETE LIBELLE WHERE LIB_LANGUE = @v_lan_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE LANGUE SET LAN_ACTIF = 0 WHERE LAN_ID = @v_lan_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
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

