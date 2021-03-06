SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_IMAGE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_img_x : Position x
--			  @v_img_y : Position y
--			  @v_img_theta : Position theta
--			  @v_img_type : Type
--			  @v_img_sql : SQL
--			  @v_asm_valeur : Valeur de l'association
--			  @v_asm_traduction : Identifiant de traduction de l'association
--			  @v_asm_libelle : Libellé de l'association
--			  @v_asm_symbole : Symbole de l'association
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
--			  @v_img_id : Identifiant
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des images
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
-- Libellé			: Possibilité de mettre à jour une valeur existante d'une
--			  image dynamique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_IMAGE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_img_id int out,
	@v_img_x int,
	@v_img_y int,
	@v_img_theta int,
	@v_img_type bit,
	@v_img_sql varchar(7500),
	@v_asm_valeur varchar(32),
	@v_asm_traduction int,
	@v_asm_libelle varchar(8000),
	@v_asm_symbole varchar(32),
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
	@v_asmimage int,
	@v_asmvaleur varchar(32),
	@v_asmtraduction int

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
				INSERT INTO IMAGE (IMG_X, IMG_Y, IMG_THETA, IMG_VISIBLE, IMG_TYPE, IMG_TRADUCTION) VALUES (-1, -1, -1, 0, 1, @v_tra_id)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					SELECT @v_img_id = SCOPE_IDENTITY()
					SELECT @v_retour = 0
				END
			END
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			IF @v_img_sql IS NOT NULL
			BEGIN
				EXEC (@v_img_sql)
				SELECT @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				IF @v_img_type = 1
				BEGIN
					DECLARE c_association CURSOR LOCAL FOR SELECT ASM_IMAGE, ASM_VALEUR, ASM_TRADUCTION FROM ASSOCIATION_SYMBOLE_IMAGE WHERE ASM_IMAGE = @v_img_id FOR UPDATE
					OPEN c_association
					FETCH NEXT FROM c_association INTO @v_asmimage, @v_asmvaleur, @v_asmtraduction
					WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
					BEGIN
						DELETE ASSOCIATION_SYMBOLE_IMAGE WHERE CURRENT OF c_association
						SELECT @v_error = @@ERROR
						IF @v_error = 0
							EXEC @v_error = LIB_TRADUCTION 2, NULL, NULL, @v_asmtraduction out
						FETCH NEXT FROM c_association INTO @v_asmimage, @v_asmvaleur, @v_asmtraduction
					END
					CLOSE c_association
					DEALLOCATE c_association
				END
				IF @v_error = 0
				BEGIN
					IF @v_asm_valeur IS NOT NULL
					BEGIN
						UPDATE IMAGE SET IMG_TYPE = @v_img_type, IMG_SQL = @v_img_sql, IMG_VALEUR = NULL
							WHERE IMG_ID = @v_img_id
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_SYMBOLE_IMAGE WHERE ASM_IMAGE = @v_img_id AND ASM_VALEUR = @v_asm_valeur)
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_asm_libelle, @v_asm_traduction out
								IF @v_error = 0
								BEGIN
									INSERT INTO ASSOCIATION_SYMBOLE_IMAGE (ASM_IMAGE, ASM_VALEUR, ASM_TRADUCTION, ASM_SYMBOLE)
										VALUES (@v_img_id, @v_asm_valeur, @v_asm_traduction, @v_asm_symbole)
									SELECT @v_error = @@ERROR
									IF @v_error = 0
										SELECT @v_retour = 0
								END
							END
							ELSE
							BEGIN
								SELECT @v_asm_traduction = ASM_TRADUCTION FROM ASSOCIATION_SYMBOLE_IMAGE
									WHERE ASM_IMAGE = @v_img_id AND ASM_VALEUR = @v_asm_valeur
								EXEC @v_error = dbo.LIB_LIBELLE @v_asm_traduction, @v_lan_id, @v_asm_libelle, @v_retour out
								IF @v_error = 0
								BEGIN
									UPDATE ASSOCIATION_SYMBOLE_IMAGE SET ASM_SYMBOLE = @v_asm_symbole
										WHERE ASM_IMAGE = @v_img_id AND ASM_VALEUR = @v_asm_valeur
									SELECT @v_error = @@ERROR
									IF @v_error = 0
										SELECT @v_retour = 0
								END
							END
						END
					END
					ELSE
					BEGIN
						UPDATE IMAGE SET IMG_TYPE = @v_img_type, IMG_SYMBOLE = @v_asm_symbole, IMG_SQL = @v_img_sql, IMG_VALEUR = NULL
							WHERE IMG_ID = @v_img_id
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
			IF ((@v_ssaction = 1) AND NOT EXISTS (SELECT 1 FROM IMAGE WHERE IMG_ID = @v_img_id AND IMG_VISIBLE = 1)) OR (@v_ssaction = 2)
			BEGIN
				UPDATE IMAGE SET IMG_X = @v_img_x, IMG_Y = @v_img_y, IMG_THETA = @v_img_theta, IMG_VISIBLE = 1 WHERE IMG_ID = @v_img_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			UPDATE IMAGE SET IMG_X = -1, IMG_Y = -1, IMG_THETA = -1, IMG_VISIBLE = 0 WHERE IMG_ID = @v_img_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			DELETE ASSOCIATION_SYMBOLE_IMAGE WHERE ASM_IMAGE = @v_img_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE IMAGE WHERE IMG_ID = @v_img_id
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
			IF @v_asm_valeur IS NOT NULL
			BEGIN
				DELETE ASSOCIATION_SYMBOLE_IMAGE WHERE ASM_IMAGE = @v_img_id AND ASM_VALEUR = @v_asm_valeur
				SELECT @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_asm_traduction out
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
			ELSE
			BEGIN
				UPDATE IMAGE SET IMG_SYMBOLE = NULL, IMG_VALEUR = NULL WHERE IMG_ID = @v_img_id
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

