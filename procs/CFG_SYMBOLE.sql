SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SYMBOLE
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_sym_id : Identifiant
--			  @v_sym_categorie : Catégorie
--			  @v_lan_id : Identifiant langue
--			  @v_tra_id : Identifiant traduction
--			  @v_lib_libelle : Libellé
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion des symboles
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SYMBOLE]
	@v_action smallint,
	@v_sym_id varchar(32),
	@v_sym_categorie tinyint,
	@v_lan_id varchar(3),
	@v_tra_id int,
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error smallint

-- Déclaration des constantes de catégories
DECLARE
	@CATE_AGV tinyint,
	@CATE_CHARGE tinyint,
	@CATE_ITEM tinyint,
	@CATE_IMAGE tinyint

-- Définition des constantes
	SET @CATE_AGV = 1
	SET @CATE_CHARGE = 5
	SET @CATE_ITEM = 6
	SET @CATE_IMAGE = 7

-- Initialisation des variables
	SET @v_retour = 113
	SET @v_error = 0

	BEGIN TRAN
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM SYMBOLE WHERE SYM_ID = @v_sym_id)
		BEGIN
			EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
			IF @v_error = 0
			BEGIN
				INSERT INTO SYMBOLE (SYM_ID, SYM_TRADUCTION, SYM_SYSTEME) VALUES (@v_sym_id, @v_tra_id, 0)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO ASSOCIATION_CATEGORIE_SYMBOLE (ACM_SYMBOLE, ACM_CATEGORIE, ACM_SYSTEME) VALUES (@v_sym_id, @v_sym_categorie, 0)
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = 0
				END
			END
		END
		ELSE IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_CATEGORIE_SYMBOLE WHERE ACM_SYMBOLE = @v_sym_id AND ACM_CATEGORIE = @v_sym_categorie)
		BEGIN
			INSERT INTO ASSOCIATION_CATEGORIE_SYMBOLE (ACM_SYMBOLE, ACM_CATEGORIE, ACM_SYSTEME) VALUES (@v_sym_id, @v_sym_categorie, 0)
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM TYPE_AGV WHERE TAG_SYMBOLE = @v_sym_id AND @v_sym_categorie = @CATE_AGV)
			UNION (SELECT 1 FROM CHARGE WHERE CHG_SYMBOLE = @v_sym_id AND @v_sym_categorie = @CATE_CHARGE)
			UNION (SELECT 1 FROM IMAGE WHERE IMG_SYMBOLE = @v_sym_id AND @v_sym_categorie = @CATE_IMAGE)
			UNION (SELECT 1 FROM ASSOCIATION_SYMBOLE_IMAGE WHERE ASM_SYMBOLE = @v_sym_id AND @v_sym_categorie = @CATE_IMAGE)
			UNION (SELECT 1 FROM ASSOCIATION_SYMBOLE_ITEM WHERE ASI_SYMBOLE = @v_sym_id AND @v_sym_categorie = @CATE_ITEM))
		BEGIN
			DELETE ASSOCIATION_CATEGORIE_SYMBOLE WHERE ACM_SYMBOLE = @v_sym_id AND ACM_CATEGORIE = @v_sym_categorie
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_CATEGORIE_SYMBOLE WHERE ACM_SYMBOLE = @v_sym_id)
				BEGIN
					DELETE SYMBOLE WHERE SYM_ID = @v_sym_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
				ELSE
					SET @v_retour = 0
			END
		END
		ELSE
			SET @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

