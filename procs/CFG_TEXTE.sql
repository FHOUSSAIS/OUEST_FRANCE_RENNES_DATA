SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_TEXTE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_txt_x : Position x
--			  @v_txt_y : Position y
--			  @v_txt_theta : Position theta
--			  @v_txt_type : Type
--			  @v_txt_sql : SQL
--			  @v_ast_valeur : Valeur de l'association
--			  @v_ast_traduction : Identifiant de traduction de l'association
--			  @v_ast_libelle : Libellé de l'association
--			  @v_ast_taille : Taille
--			  @v_ast_symbole : Symbole de l'association
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_txt_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des textes
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 26/09/2006
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 10/05/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Suppression du contrôle de l'unicité du libellé
-----------------------------------------------------------------------------------------
-- Date			: 28/11/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Possibilité de mettre à jour une valeur existante d'un
--			  texte dynamique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_TEXTE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_txt_id int out,
	@v_txt_x int,
	@v_txt_y int,
	@v_txt_theta int,
	@v_txt_type bit,
	@v_txt_sql varchar(7500),
	@v_ast_valeur varchar(32),
	@v_ast_traduction int,
	@v_ast_libelle varchar(8000),
	@v_ast_taille int,
	@v_ast_symbole varchar(32),
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
	@v_asttexte int,
	@v_astvaleur varchar(32),
	@v_asttraduction int

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
				INSERT INTO TEXTE (TXT_X, TXT_Y, TXT_THETA, TXT_VISIBLE, TXT_TYPE, TXT_TRADUCTION) VALUES (-1, -1, -1, 0, 1, @v_tra_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_txt_id = SCOPE_IDENTITY()
					SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF @v_txt_sql IS NOT NULL
			BEGIN
				EXEC (@v_txt_sql)
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				IF @v_txt_type = 1
				BEGIN
					DECLARE c_association CURSOR LOCAL FOR SELECT AST_TEXTE, AST_VALEUR, AST_TRADUCTION FROM ASSOCIATION_SYMBOLE_TEXTE WHERE AST_TEXTE = @v_txt_id FOR UPDATE
					OPEN c_association
					FETCH NEXT FROM c_association INTO @v_asttexte, @v_astvaleur, @v_asttraduction
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						DELETE ASSOCIATION_SYMBOLE_TEXTE WHERE CURRENT OF c_association
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_asttraduction out
						FETCH NEXT FROM c_association INTO @v_asttexte, @v_astvaleur, @v_asttraduction
					END
					CLOSE c_association
					DEALLOCATE c_association
				END
				IF @v_error = 0
				BEGIN
					IF @v_ast_valeur IS NOT NULL
					BEGIN
						UPDATE TEXTE SET TXT_TYPE = @v_txt_type, TXT_SQL = @v_txt_sql, TXT_VALEUR = NULL
							WHERE TXT_ID = @v_txt_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_SYMBOLE_TEXTE WHERE AST_TEXTE = @v_txt_id AND AST_VALEUR = @v_ast_valeur)
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_ast_libelle, @v_ast_traduction out
								IF @v_error = 0
								BEGIN
									INSERT INTO ASSOCIATION_SYMBOLE_TEXTE (AST_TEXTE, AST_VALEUR, AST_TRADUCTION, AST_TAILLE, AST_SYMBOLE)
										VALUES (@v_txt_id, @v_ast_valeur, @v_ast_traduction, @v_ast_taille, @v_ast_symbole)
									SELECT @v_error = @@ERROR
									IF @v_error = 0
										SELECT @v_retour = 0
								END
							END
							ELSE
							BEGIN
								SELECT @v_ast_traduction = AST_TRADUCTION FROM ASSOCIATION_SYMBOLE_TEXTE
									WHERE AST_TEXTE = @v_txt_id AND AST_VALEUR = @v_ast_valeur
								EXEC @v_error = dbo.LIB_LIBELLE @v_ast_traduction, @v_lan_id, @v_ast_libelle, @v_retour out
								IF @v_error = 0
								BEGIN
									UPDATE ASSOCIATION_SYMBOLE_TEXTE SET AST_TAILLE = @v_ast_taille, AST_SYMBOLE = @v_ast_symbole
										WHERE AST_TEXTE = @v_txt_id AND AST_VALEUR = @v_ast_valeur
									SELECT @v_error = @@ERROR
									IF @v_error = 0
										SELECT @v_retour = 0
								END
							END
						END
					END
					ELSE
					BEGIN
						UPDATE TEXTE SET TXT_TYPE = @v_txt_type, TXT_TAILLE = @v_ast_taille, TXT_SYMBOLE = @v_ast_symbole, TXT_SQL = @v_txt_sql, TXT_VALEUR = NULL
							WHERE TXT_ID = @v_txt_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							SELECT @v_retour = 0
					END
				END
			END
		END
	END
	IF @v_action = 1
	BEGIN
		IF @v_ssaction = 1 OR @v_ssaction = 2
		BEGIN
			IF ((@v_ssaction = 1) AND NOT EXISTS (SELECT 1 FROM TEXTE WHERE TXT_ID = @v_txt_id AND TXT_VISIBLE = 1)) OR (@v_ssaction = 2)
			BEGIN
				UPDATE TEXTE SET TXT_X = @v_txt_x, TXT_Y = @v_txt_y, TXT_THETA = @v_txt_theta, TXT_VISIBLE = 1 WHERE TXT_ID = @v_txt_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE TEXTE SET TXT_X = -1, TXT_Y = -1, TXT_THETA = -1, TXT_VISIBLE = 0 WHERE TXT_ID = @v_txt_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			DELETE ASSOCIATION_SYMBOLE_TEXTE WHERE AST_TEXTE = @v_txt_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE TEXTE WHERE TXT_ID = @v_txt_id
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
			IF @v_ast_valeur IS NOT NULL
			BEGIN
				DELETE ASSOCIATION_SYMBOLE_TEXTE WHERE AST_TEXTE = @v_txt_id AND AST_VALEUR = @v_ast_valeur
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_ast_traduction out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
			BEGIN
				UPDATE TEXTE SET TXT_TAILLE = NULL, TXT_SYMBOLE = NULL, TXT_VALEUR = NULL WHERE TXT_ID = @v_txt_id
				SELECT @v_error = @@ERROR
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

