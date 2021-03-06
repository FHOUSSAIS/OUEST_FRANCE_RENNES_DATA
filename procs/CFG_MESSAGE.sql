SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_MESSAGE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_mes_id : Identifiant message
--			  @v_mes_nom : Nom
--			  @v_mes_actif : Actif
--			  @v_mes_libelle : Libellé
--			  @v_mes_description : Commentaire
--			  @v_lan_id : Identifiant langue
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_tra_idlibelle : Identifiant traduction libellé
--			  @v_tra_idcomment : Identifiant traduction commentaire
-- Descriptif		: Gestion des messages
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 05/12/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_MESSAGE]
	@v_action smallint,
	@v_mes_id int out,
	@v_mes_nom varchar(64),
	@v_mes_actif bit,
	@v_mes_libelle varchar(8000),
	@v_mes_description varchar(8000),
	@v_lan_id varchar(3),
	@v_tra_libelle int out,
	@v_tra_description int out,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_mes_libelle, @v_tra_libelle out
		IF @v_error = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_mes_description, @v_tra_description out
			IF @v_error = 0
			BEGIN
				INSERT INTO MESSAGE (MES_ID, MES_NOM, MES_ACTIF, MES_SYSTEME, MES_TRADUCTION, MES_DESCRIPTION, MES_EMISSION, MES_RECEPTION)
					SELECT (SELECT CASE SIGN(MIN(MES_ID)) WHEN -1 THEN MIN(MES_ID) - 1 ELSE -1 END FROM MESSAGE),
					@v_mes_nom, 1, 0, @v_tra_libelle, @v_tra_description, 1, 0
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		UPDATE LIBELLE SET LIB_LIBELLE = @v_mes_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_libelle
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE LIBELLE SET LIB_LIBELLE = @v_mes_description WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_description
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE MESSAGE SET MES_ACTIF = @v_mes_actif WHERE MES_ID = @v_mes_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE MESSAGE SET MES_NOM = @v_mes_nom WHERE MES_ID = @v_mes_id
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE ABONNEMENT WHERE ABN_MESSAGE = @v_mes_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DELETE MESSAGE WHERE MES_ID = @v_mes_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_description out
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_libelle out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

