SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_DLL
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_dll_id : Identifiant
--			  @v_tra_id : Identifiant traduction
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des dlls
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 25/09/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 05/04/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Finalisation du synoptique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_DLL]
	@v_action smallint,
	@v_dll_id varchar(32),
	@v_tra_id int out,
	@v_lan_id varchar(3),
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
		IF NOT EXISTS (SELECT 1 FROM DLL WHERE DLL_ID = @v_dll_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO DLL (DLL_ID, DLL_TRADUCTION) VALUES (@v_dll_id, @v_tra_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
		ELSE
			SELECT @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_TRADUCTION = @v_tra_id AND LIB_LANGUE = @v_lan_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM OPERATION WHERE OPE_DLL = @v_dll_id)
			UNION (SELECT 1 FROM SPECIFIQUE WHERE SPE_DLL = @v_dll_id))
		BEGIN
			DELETE DLL WHERE DLL_ID = @v_dll_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
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

