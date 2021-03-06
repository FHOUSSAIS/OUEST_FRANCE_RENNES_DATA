SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ITEM
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_ite_x : Position x
--			  @v_ite_y : Position y
--			  @v_ite_theta : Position theta
--			  @v_ite_interface : Interface
--			  @v_ite_variable_automate : Variable automate
--			  @v_ite_entree_sortie : Entrée/sortie
--			  @v_ite_legende : Légende
--			  @v_ite_menu_contextuel : Menu contextuel
--			  @v_ite_vue : Vue
--			  @v_asi_valeur : Valeur de l'association
--			  @v_asi_traduction : Identifiant de traduction de l'association
--			  @v_asi_libelle : Libellé de l'association
--			  @v_asi_symbole : Symbole de l'association
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_ite_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des items
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ITEM]
	@v_action smallint,
	@v_ssaction smallint,
	@v_ite_id int out,
	@v_ite_x int,
	@v_ite_y int,
	@v_ite_theta int,
	@v_ite_interface int,
	@v_ite_variable_automate int,
	@v_ite_entree_sortie int,
	@v_ite_legende int,
	@v_ite_menu_contextuel int,
	@v_ite_vue int,
	@v_asi_valeur varchar(32),
	@v_asi_traduction int,
	@v_asi_libelle varchar(8000),
	@v_asi_symbole varchar(32),
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
		IF @v_ssaction = 0
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO ITEM (ITE_X, ITE_Y, ITE_THETA, ITE_VISIBLE, ITE_TRADUCTION, ITE_LEGENDE)
					VALUES (-1, -1, -1, 0, @v_tra_id, 6)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_ite_id = SCOPE_IDENTITY()
					SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_SYMBOLE_ITEM WHERE ASI_ITEM = @v_ite_id AND ASI_VALEUR = @v_asi_valeur)
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_asi_libelle, @v_asi_traduction out
				IF @v_error = 0
				BEGIN
					INSERT INTO ASSOCIATION_SYMBOLE_ITEM (ASI_ITEM, ASI_VALEUR, ASI_TRADUCTION, ASI_SYMBOLE)
						VALUES (@v_ite_id, @v_asi_valeur, @v_asi_traduction, @v_asi_symbole)
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
			BEGIN
				SELECT @v_asi_traduction = ASI_TRADUCTION FROM ASSOCIATION_SYMBOLE_ITEM
					WHERE ASI_ITEM = @v_ite_id AND ASI_VALEUR = @v_asi_valeur
				EXEC @v_error = dbo.LIB_LIBELLE @v_asi_traduction, @v_lan_id, @v_asi_libelle, @v_retour out
				IF @v_error = 0
				BEGIN
					UPDATE ASSOCIATION_SYMBOLE_ITEM SET ASI_SYMBOLE = @v_asi_symbole
						WHERE ASI_ITEM = @v_ite_id AND ASI_VALEUR = @v_asi_valeur
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			UPDATE ITEM SET ITE_INTERFACE = @v_ite_interface, ITE_VARIABLE_AUTOMATE = @v_ite_variable_automate,
				ITE_ENTREE_SORTIE = @v_ite_entree_sortie, ITE_LEGENDE = @v_ite_legende, ITE_MENU_CONTEXTUEL = @v_ite_menu_contextuel,
				ITE_VUE = @v_ite_vue WHERE ITE_ID = @v_ite_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 1 OR @v_ssaction = 2
		BEGIN
			IF ((@v_ssaction = 1) AND NOT EXISTS (SELECT 1 FROM ITEM WHERE ITE_ID = @v_ite_id AND ITE_VISIBLE = 1)) OR (@v_ssaction = 2)
			BEGIN
				UPDATE ITEM SET ITE_X = @v_ite_x, ITE_Y = @v_ite_y, ITE_THETA = @v_ite_theta, ITE_VISIBLE = 1 WHERE ITE_ID = @v_ite_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE ITEM SET ITE_X = -1, ITE_Y = -1, ITE_THETA = -1, ITE_VISIBLE = 0 WHERE ITE_ID = @v_ite_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			DELETE ASSOCIATION_SYMBOLE_ITEM WHERE ASI_ITEM = @v_ite_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE ITEM WHERE ITE_ID = @v_ite_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			DELETE ASSOCIATION_SYMBOLE_ITEM WHERE ASI_ITEM = @v_ite_id AND ASI_VALEUR = @v_asi_valeur
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_asi_traduction out
				IF @v_error = 0
					SELECT @v_retour = 0
			END
		END
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

